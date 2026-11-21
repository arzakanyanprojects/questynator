"""Load the installed QuestieDB (Forever, baked mode) outside the game.

QuestieDB keeps its data as base64 CBOR rows in its .toc metadata. This module runs QuestieDB's own
Lua code in LuaJIT (lupa) with stand-ins for the few game functions it calls:
C_AddOns.GetAddOnMetadata, C_EncodingUtil.DecodeBase64 / DecompressString / DeserializeCBOR.

    db = load(r"...\\Interface\\AddOns\\QuestieDB")
    db.quest(781)["startedBy"]   # plain Python values
"""
import base64
import os
import re
import struct
import zlib

from lupa import luajit21 as lupa_mod

TOC = "QuestieDB_Forever.toc"


# --- CBOR (RFC 8949), the subset QuestieDB writes -------------------------------------------
class _Reader:
    def __init__(self, data):
        self.data, self.pos = data, 0

    def take(self, n):
        chunk = self.data[self.pos:self.pos + n]
        self.pos += n
        return chunk

    def arg(self, info):
        if info < 24:
            return info
        size = {24: 1, 25: 2, 26: 4, 27: 8}.get(info)
        if size is None:
            return None  # indefinite length
        return int.from_bytes(self.take(size), "big")

    def item(self):
        head = self.take(1)[0]
        major, info = head >> 5, head & 31
        if major == 7:
            if info == 20: return False
            if info == 21: return True
            if info in (22, 23): return None
            if info == 25: return _half(self.take(2))
            if info == 26: return struct.unpack(">f", self.take(4))[0]
            if info == 27: return struct.unpack(">d", self.take(8))[0]
            if info == 31: return _BREAK
            return None
        n = self.arg(info)
        if major == 0: return n
        if major == 1: return -1 - n
        if major in (2, 3):
            if n is None:
                parts = []
                while True:
                    part = self.item()
                    if part is _BREAK: break
                    parts.append(part)
                return b"".join(parts)
            return self.take(n)
        if major == 4:
            out = []
            if n is None:
                while True:
                    value = self.item()
                    if value is _BREAK: break
                    out.append(value)
            else:
                out = [self.item() for _ in range(n)]
            return out
        if major == 5:
            out = {}
            count = 0
            while n is None or count < n:
                key = self.item()
                if key is _BREAK: break
                out[key] = self.item()
                count += 1
            return out
        if major == 6:
            return self.item()  # tags carry no meaning for us
        raise ValueError("bad CBOR major type %d" % major)


_BREAK = object()


def _half(two):
    h = int.from_bytes(two, "big")
    sign, exp, frac = h >> 15, (h >> 10) & 31, h & 1023
    if exp == 0: val = frac * 2.0 ** -24
    elif exp == 31: val = float("inf") if frac == 0 else float("nan")
    else: val = (1 + frac / 1024.0) * 2.0 ** (exp - 15)
    return -val if sign else val


def cbor_decode(data):
    return _Reader(data).item()


# --- the Lua side ------------------------------------------------------------------------------
class QuestieDB:
    def __init__(self, folder, faction="Alliance"):
        self.folder, self.faction = folder, faction
        meta, files = {}, []
        with open(os.path.join(folder, TOC), encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\r\n")
                m = re.match(r"^## ([^:]+):\s?(.*)$", line)
                if m:
                    meta[m.group(1)] = m.group(2)
                elif line and not line.startswith("#"):
                    files.append(line.replace("\\", os.sep))
        self.meta, self.files = meta, files
        self.version = meta.get("Version")
        self.commit = meta.get("X-BUILD-COMMIT")
        self.built = meta.get("X-BUILD-TIME")

        rt = lupa_mod.LuaRuntime(encoding=None, unpack_returned_tuples=True)
        self.rt = rt
        lua_table = rt.eval("function(...) return {...} end")

        def to_lua(value):
            if isinstance(value, list):
                t = rt.table()
                for i, v in enumerate(value, 1):
                    t[i] = to_lua(v)
                return t
            if isinstance(value, dict):
                t = rt.table()
                for k, v in value.items():
                    t[to_lua(k)] = to_lua(v)
                return t
            if isinstance(value, str):
                return value.encode("utf-8")
            return value

        def metadata(_addon, key):
            value = meta.get(key.decode() if isinstance(key, bytes) else key)
            return value.encode("utf-8") if value is not None else None

        def decode_base64(s):
            return base64.b64decode(s)

        def decompress(s, method=None):
            try:
                return zlib.decompress(s)
            except zlib.error:
                return zlib.decompress(s, -15)

        def deserialize(s):
            return to_lua(cbor_decode(bytes(s)))

        g = rt.globals()
        g.C_AddOns = rt.table_from({b"GetAddOnMetadata": metadata})
        g.GetAddOnMetadata = metadata
        g.C_EncodingUtil = rt.table_from({b"DecodeBase64": decode_base64, b"DecompressString": decompress,
                                          b"DeserializeCBOR": deserialize})
        g.GetLocale = lambda: b"enUS"
        # A few corrections differ by faction or class: load once per faction and merge.
        g.UnitFactionGroup = lambda *_: faction.encode()
        g.UnitClassBase = lambda *_: b"WARRIOR"
        g.Enum = rt.eval("{ CompressionMethod = { Deflate = 0, Zlib = 1 } }")
        ns = rt.table()
        self.ns = ns
        run = rt.eval("""function(code, name, addon, ns)
            local fn, err = loadstring(code, '@' .. name)
            if not fn then error(err) end
            return fn(addon, ns)
        end""")
        for rel in self.files:
            path = os.path.join(folder, rel)
            if not rel.endswith(".lua") or not os.path.exists(path):
                continue
            with open(path, "rb") as f:
                run(f.read(), rel.encode(), b"QuestieDB", ns)
        self.lib = rt.globals().LibQuestieDB or ns
        self._py = rt.eval("""function(v)
            local seen = {}
            local function conv(x)
                if type(x) ~= 'table' then return x end
                return x
            end
            return conv(v)
        end""")

    def _entity(self, name):
        return self.lib[name.encode()]

    def ids(self, entity):
        ids = self._entity(entity).GetAllIds()
        return sorted(int(v) for v in ids.values())

    def get(self, entity, ident):
        """All fields of one entity as a {fieldName: python value} dict, or None."""
        ent = self._entity(entity)
        if not ent.Exists(ident):
            return None
        keys = self.lib[b"Meta"][entity.encode()][b"keys"]
        out = {}
        for name, index in keys.items():
            out[name.decode()] = _py(ent.GetByIndex(ident, index))
        return out

    def quest(self, ident): return self.get("Quest", ident)
    def npc(self, ident): return self.get("Npc", ident)
    def object(self, ident): return self.get("Object", ident)
    def item(self, ident): return self.get("Item", ident)

    def support(self, name):
        """A support table (e.g. 'areaIdToUiMapId') as Python data, if QuestieDB exposes it."""
        return _py(self.lib[name.encode()]) if self.lib[name.encode()] is not None else None


def _py(value):
    """Lua values to plain Python: tables become lists (1..n with nothing else) or dicts."""
    if hasattr(value, "items"):
        items = list(value.items())
        keys = [k for k, _ in items]
        if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
            return [_py(v) for _, v in sorted(items)]
        return {(k.decode() if isinstance(k, bytes) else k): _py(v) for k, v in items}
    if isinstance(value, bytes):
        return value.decode("utf-8", "replace")
    return value


def load(folder, faction="Alliance"):
    return QuestieDB(folder, faction)


if __name__ == "__main__":
    import json, sys
    db = load(sys.argv[1])
    print("QuestieDB", db.version, db.commit, db.built)
    for entity in ("Quest", "Npc", "Object", "Item"):
        print(entity, len(db.ids(entity)))
    print(json.dumps(db.quest(781), indent=1, default=str)[:1500])
