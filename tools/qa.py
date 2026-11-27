"""Check the shipped Questynator files and run its Lua 5.1 regression suite."""

import os
from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]


def lua_sources(path):
    """Follow TOC entries and the Script/Include references in Blizzard UI XML."""
    if path.suffix.lower() == ".lua":
        yield path
    elif path.suffix.lower() == ".xml":
        for node in ET.parse(path).getroot().iter():
            if node.tag.rsplit("}", 1)[-1] in {"Include", "Script"} and "file" in node.attrib:
                yield from lua_sources(path.parent / node.attrib["file"].replace("\\", "/"))
    else:
        raise ValueError(f"Unsupported manifest entry: {path}")


def main():
    try:
        from lupa.lua51 import LuaRuntime
    except ImportError:
        raise SystemExit("Full QA needs Python with lupa.lua51. Install with: python -m pip install lupa")

    os.chdir(ROOT)
    runtime = LuaRuntime()
    compile_file = runtime.eval("function(path) assert(loadfile(path)) end")
    count = 0
    for line in Path("Questynator.toc").read_text(encoding="utf-8-sig").splitlines():
        entry = line.strip()
        if entry and not entry.startswith("#"):
            for source in lua_sources(Path(entry.replace("\\", "/"))):
                compile_file(source.as_posix())
                count += 1
    print(f"Manifest OK: {count} shipped Lua files compiled with Lua 5.1", flush=True)
    runtime.eval("dofile")("tests/review.lua")


if __name__ == "__main__":
    main()
