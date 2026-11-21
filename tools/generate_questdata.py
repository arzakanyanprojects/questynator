"""Regenerate Data/QuestData.lua from the installed QuestieDB (Forever).

    python tools/generate_questdata.py              # write Data/QuestData.lua
    python tools/generate_questdata.py --compare    # only report what would change
    python tools/generate_questdata.py --questiedb <path to AddOns\\QuestieDB>

Sections written (the formats Questynator.lua reads):
  q  quest   "start/finish/mobs/objects/items/rep/next"   refs n<npc> o<object> i<item>
  h  the same row for the Horde, only where its giver or ender differs
  n  npc     "zone,x,y,elite,levels,name"                  the spawn nearest the middle of its spawns
  o  object  "zone,x,y,,,name"
  i  item    "n1,o2;name"                                  where it drops or lies
  t  title   "level;races;classes;name"                   quests other quests lead to
  m  area -> uiMap
  a  pickup  "req;lvl;races;classes;preAll;preAny;excl;chain;elite;faction;name"
  z  zone level ranges (kept from the current file: QuestieDB has none)
  x  quest base XP
Quests that start from an item lying on the ground point their start at that object, so they show
as pickups (e.g. Attack on Camp Narache). Data: QuestieDB (GPLv3).
"""
import argparse
import io
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ADDON = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import questiedb  # noqa: E402

ALLIANCE, HORDE = 4294967373, 8589934770
SECTIONS = ("q", "h", "n", "o", "i", "t", "m", "a", "z", "x")   # QuestieDB's faction race masks (with the Forever races)


def num(v):
    """1.0 -> '1', 22.25 -> '22.25' (two decimals: about a yard on a big zone map); no coordinate -> ''."""
    if v is None: return ""
    v = round(float(v), 2)
    return str(int(v)) if v == int(v) else ("%.2f" % v).rstrip("0")


def as_groups(v):
    """startedBy / finishedBy / objectives come as a list or a {1: .., 2: .., 3: ..} dict."""
    if isinstance(v, dict):
        return [v.get(i) or v.get(str(i)) for i in range(1, 7)]
    return list(v or []) + [None] * 6


def ids(group):
    out = []
    for x in group or []:
        if isinstance(x, list): x = x[0]
        elif isinstance(x, dict): x = x.get(1)
        if x is not None: out.append(int(x))
    return out


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


class Generator:
    def __init__(self, folder):
        self.ally = questiedb.load(folder, "Alliance")
        self.horde = questiedb.load(folder, "Horde")
        self.db = self.ally
        self.cache = {}

    def get(self, kind, ident, faction=None):
        key = (kind, ident, faction)
        if key not in self.cache:
            db = self.horde if faction == "H" else self.ally
            self.cache[key] = db.get(kind, ident)
        return self.cache[key]

    # -- places --------------------------------------------------------------------------------
    def place(self, kind, ident):
        rec = self.get(kind, ident)
        if not rec or not rec.get("spawns"): return None
        raw = rec["spawns"]
        if isinstance(raw, list): raw = {i: v for i, v in enumerate(raw, 1)}   # zone 1, 2.. came back as a list
        spawns = {int(z): [p for p in (pts or []) if isinstance(p, list) and len(p) >= 2 and p[0] is not None and p[0] >= 0]
                  for z, pts in raw.items() if pts}
        if not spawns: return None
        mapped = {z: pts for z, pts in spawns.items() if pts}
        if not mapped:
            # inside an instance: no map coordinates, but the zone still tells us it's a dungeon
            zone = rec.get("zoneID") if rec.get("zoneID") in spawns else next(iter(spawns))
            return zone, (None, None), rec
        spawns = mapped
        zone = rec.get("zoneID") if rec.get("zoneID") in spawns else max(spawns, key=lambda z: len(spawns[z]))
        pts = spawns[zone]
        cx, cy = sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
        best = min(pts, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
        return zone, best, rec

    # -- build ---------------------------------------------------------------------------------
    def build(self, keep_z):
        Q, N, O, I, T, A, X = {}, {}, {}, {}, {}, {}, {}
        quests = {}
        for qid in self.ally.ids("Quest"):
            rec = self.get("Quest", qid)
            races = rec.get("requiredRaces") or 0
            if races and races & HORDE and not races & ALLIANCE:
                rec = self.get("Quest", qid, "H") or rec
            quests[qid] = rec

        # follow-ups: the next quest in the chain, then quests that need this one
        nxt = {}
        for qid, r in quests.items():
            if r.get("nextQuestInChain"): nxt.setdefault(qid, []).append(int(r["nextQuestInChain"]))
        for qid, r in sorted(quests.items()):
            for pre in (r.get("preQuestSingle") or []) + (r.get("preQuestGroup") or []):
                lst = nxt.setdefault(int(pre), [])
                if qid not in lst: lst.append(qid)

        npcs, objects, items = set(), set(), set()

        def row(qid, r):
            start, finish, obj = as_groups(r.get("startedBy")), as_groups(r.get("finishedBy")), as_groups(r.get("objectives"))
            s = ""
            if ids(start[0]): s = "n%d" % ids(start[0])[0]; npcs.add(ids(start[0])[0])
            elif ids(start[1]): s = "o%d" % ids(start[1])[0]; objects.add(ids(start[1])[0])
            elif ids(start[2]):
                item = ids(start[2])[0]
                drops = self.get("Item", item)
                ground = ids((drops or {}).get("objectDrops"))
                if ground and not ids((drops or {}).get("npcDrops")):
                    s = "o%d" % ground[0]; objects.add(ground[0])   # picked up off the ground
                else:
                    s = "i%d" % item; items.add(item)
            f = ""
            if ids(finish[0]): f = "n%d" % ids(finish[0])[0]; npcs.add(ids(finish[0])[0])
            elif ids(finish[1]): f = "o%d" % ids(finish[1])[0]; objects.add(ids(finish[1])[0])
            mobs, objs, its = ids(obj[0]), ids(obj[1]), ids(obj[2])
            npcs.update(mobs); objects.update(objs); items.update(its)
            rep = ",".join("%d:%d" % (int(a), int(b)) for a, b in (r.get("reputationReward") or []))
            follow = ",".join(str(x) for x in nxt.get(qid, []))
            return "/".join([s, f, ",".join(map(str, mobs)), ",".join("o%d" % o for o in objs),
                             ",".join(map(str, its)), rep, follow]).rstrip("/"), s

        H = {}
        for qid, r in sorted(quests.items()):
            Q[qid], quests[qid]["_start"] = row(qid, r)
            # both factions can take it, but the Horde gets it from someone else: keep the Horde row too
            races = r.get("requiredRaces") or 0
            if not races or races & HORDE:
                horde = self.get("Quest", qid, "H")
                if horde and horde is not r:
                    text = row(qid, horde)[0]
                    if text != Q[qid]: H[qid] = text

        for item in sorted(items):
            rec = self.get("Item", item)
            if not rec: continue
            srcs = []
            for n in ids(rec.get("npcDrops")):
                if self.place("Npc", n): srcs.append("n%d" % n); npcs.add(n)
            for o in ids(rec.get("objectDrops")):
                if self.place("Object", o): srcs.append("o%d" % o); objects.add(o)
            I[item] = "%s;%s" % (",".join(srcs[:12]), rec.get("name") or "")

        for n in sorted(npcs):
            p = self.place("Npc", n)
            if not p: continue
            zone, (x, y), rec = p
            lo, hi = rec.get("minLevel") or 0, rec.get("maxLevel") or 0
            lv = "" if not lo else (str(lo) if lo == hi or not hi else "%d-%d" % (lo, hi))
            elite = str(rec.get("rank")) if (rec.get("rank") or 0) > 0 else ""    # 1 elite, 2 rare elite, 3 boss, 4 rare
            N[n] = "%d,%s,%s,%s,%s,%s" % (zone, num(x), num(y), elite, lv, rec.get("name") or "")
        for o in sorted(objects):
            p = self.place("Object", o)
            if not p: continue
            zone, (x, y), rec = p
            O[o] = "%d,%s,%s,,,%s" % (zone, num(x), num(y), rec.get("name") or "")

        memo = {}

        def chain_length(qid, seen=()):
            # this quest plus the longest run of follow-ups after it (Zones tab: "Chain · N quests")
            if qid in memo: return memo[qid]
            best = 0
            for nq in nxt.get(qid, []):
                if nq in quests and nq not in seen and len(seen) < 25:
                    best = max(best, chain_length(nq, seen + (qid,)))
            memo[qid] = best + 1
            return best + 1

        targets = {int(x) for lst in nxt.values() for x in lst}
        for qid, r in sorted(quests.items()):
            races, classes = r.get("requiredRaces") or 0, r.get("requiredClasses") or 0
            name = r.get("name") or ""
            if qid in targets:
                T[qid] = "%d;%d;%d;%s" % (r.get("questLevel") or 0, races, classes, name)
            start = r["_start"]
            if not start or start[0] not in "no": continue
            if (start[0] == "n" and int(start[1:]) not in N) or (start[0] == "o" and int(start[1:]) not in O): continue
            if (r.get("specialFlags") or 0) & 1: continue              # repeatable
            if r.get("requiredSkill") or (r.get("requiredSpell") or 0) or (r.get("requiredSpecialization") or 0): continue
            zone = r.get("zoneOrSort") or 0
            if zone < 0 and zone in self.event_sorts(): continue
            goals = as_groups(r.get("objectives"))
            sources = list(ids(goals[0]))
            for it in ids(goals[2]):
                sources += [int(ref[1:]) for ref in I.get(it, ";").split(";")[0].split(",") if ref.startswith("n")]
            elite = "1" if any(N.get(m, ",,,,").split(",")[3] in ("1", "2", "3") for m in sources) else ""
            faction = "A" if races and not races & HORDE else ("H" if races and not races & ALLIANCE else "")
            chain = chain_length(qid)
            A[qid] = ";".join([str(r.get("requiredLevel") or 0), str(r.get("questLevel") or 0), str(races), str(classes),
                               ",".join(map(str, r.get("preQuestGroup") or [])),
                               ",".join(map(str, r.get("preQuestSingle") or [])),
                               ",".join(map(str, r.get("exclusiveTo") or [])),
                               str(chain) if chain > 1 else "", elite, faction, name])

        xp = self.xp_table()
        for qid in quests:
            if xp.get(qid): X[qid] = str(int(xp[qid]))
        M = self.area_maps()
        return {"q": Q, "h": H, "n": N, "o": O, "i": I, "t": T, "m": M, "a": A, "z": keep_z, "x": X}

    def event_sorts(self):
        return {-22, -284, -366, -369, -370, -374, -375, -376, -1002, -1003, -1005}   # holiday / seasonal sorts

    def support(self, module):
        get = self.ally.lib[b"Support"][b"Get"]
        return get(module.encode())

    def xp_table(self):
        db = self.support("QuestXP")[b"db"]
        out = {}
        for qid, row in questiedb._py(db).items():
            if isinstance(row, list) and len(row) >= 2 and row[1]:
                out[int(qid)] = row[1]
        return out

    def area_maps(self):
        private = self.support("ZoneDB")[b"private"]
        rt = self.ally.rt
        out = {}
        for key in (b"areaIdToUiMapId", b"areaIdToUiMapIdOverride"):    # the override wins
            value = private[key]
            if isinstance(value, bytes):
                value = rt.execute(value)
            for area, ui in questiedb._py(value).items() if value is not None else []:
                if ui: out[int(area)] = str(int(ui))
                elif int(area) in out: del out[int(area)]
        return out


def read_current(path):
    from lupa import luajit21 as l
    rt = l.LuaRuntime(unpack_returned_tuples=True)
    src = open(path, encoding="utf-8").read().replace("local _, ns = ...", "local ns = {}")
    cur = rt.execute(src + "\nreturn ns.QDATA")
    return {s: {int(k): v for k, v in (cur[s] or {}).items()} for s in SECTIONS}


def write(path, data, meta):
    out = io.StringIO()
    out.write("-- Questynator bundled quest locations.\n")
    out.write("-- Data derived from QuestieDB (https://github.com/Questie/Questie), licensed GPLv3.\n")
    out.write("-- Generated file - do not edit by hand. Run tools/generate_questdata.py.\n")
    out.write("-- Source: QuestieDB %s (Forever), build %s, %s\n" % meta)
    out.write("local _, ns = ...\nns.QDATA = {\n")
    for s in SECTIONS:
        out.write("%s={\n" % s)
        for k in sorted(data[s]):
            out.write("[%d]=%s,\n" % (k, lua_str(data[s][k])))
        out.write("},\n")
    out.write("}\n")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(out.getvalue())


def compare(old, new):
    lines = []
    for s in SECTIONS:
        o, n = old.get(s, {}), new[s]
        added = sorted(set(n) - set(o)); removed = sorted(set(o) - set(n))
        changed = sorted(k for k in set(o) & set(n) if o[k] != n[k])
        lines.append("%s: %d now (%d before), +%d new, -%d gone, %d changed" % (s, len(n), len(o), len(added), len(removed), len(changed)))
        for k in changed[:3]:
            lines.append("    ~%d  %s  ->  %s" % (k, o[k], n[k]))
        for k in added[:3]:
            lines.append("    +%d  %s" % (k, n[k]))
        for k in removed[:3]:
            lines.append("    -%d  %s" % (k, o[k]))
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--questiedb", default=os.path.join(os.path.dirname(ADDON), "QuestieDB"))
    ap.add_argument("--compare", action="store_true")
    args = ap.parse_args()
    target = os.path.join(ADDON, "Data", "QuestData.lua")
    old = read_current(target)
    gen = Generator(args.questiedb)
    new = gen.build(old["z"])
    print("QuestieDB %s, build %s, %s" % (gen.ally.version, gen.ally.commit, gen.ally.built))
    print(compare(old, new))
    if not args.compare:
        write(target, new, (gen.ally.version, gen.ally.commit, gen.ally.built))
        print("wrote", target)


if __name__ == "__main__":
    main()
