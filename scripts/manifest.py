"""Write build/manifest.json: every Luau source with the Roblox instance it becomes, so the code loads into Studio
over HTTP through the Studio MCP, without Rojo (CLAUDE.md, "Studio"). Reads game.project.json; any field it doesn't
understand stops the script. Taken from Roll an Anomaly (itself from Break a Gem).

    py scripts/manifest.py
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KNOWN_TOP = {"name", "tree"}
SCRIPT_CLASS = {"": "ModuleScript", ".server": "Script", ".client": "LocalScript"}

entries = []
roots = []


def fail(msg):
    sys.exit(f"manifest.py: {msg}")


def script_kind(filename):
    """'Main.server.luau' -> ('Main', 'Script'). None when it isn't Luau."""
    if not filename.endswith(".luau"):
        return None
    stem = filename[: -len(".luau")]
    for suffix in (".server", ".client"):
        if stem.endswith(suffix):
            return stem[: -len(suffix)], SCRIPT_CLASS[suffix]
    return stem, SCRIPT_CLASS[""]


def walk(folder, path, entry):
    for name in sorted(os.listdir(os.path.join(ROOT, folder))):
        full = f"{folder}/{name}"
        if os.path.isdir(os.path.join(ROOT, full)):
            child = {"path": path + [name], "class": "Folder", "source": None}
            entries.append(child)
            walk(full, path + [name], child)
            continue
        if name.endswith(".md"):
            continue
        kind = script_kind(name)
        if kind is None:
            fail(f"unsupported file: {full}")
        stem, cls = kind
        if stem == "init":
            # the folder becomes the script itself (Rojo's init convention)
            entry["class"] = cls
            entry["source"] = full
        else:
            entries.append({"path": path + [stem], "class": cls, "source": full})


def node(tree, path, is_root):
    for key, value in tree.items():
        if key == "$className":
            if not is_root:
                fail(f"$className only at the root ({'.'.join(path)})")
        elif key == "$path":
            if is_root or len(path) < 2:
                fail("$path not allowed on the root or a service")
            if len(tree) > 1:
                fail(f"$path with children or siblings: {'.'.join(path)}")
            if not os.path.isdir(os.path.join(ROOT, value)):
                fail(f"folder not found: {value}")
            entry = {"path": path, "class": "Folder", "source": None}
            entries.append(entry)
            roots.append(path)
            walk(value, path, entry)
        elif key.startswith("$"):
            fail(f"unknown field {key} under {'.'.join(path) or 'tree'}")
        else:
            if not isinstance(value, dict):
                fail(f"bad node: {key}")
            child_path = path + [key]
            if len(child_path) > 1 and "$path" not in value:
                entries.append({"path": child_path, "class": "Folder", "source": None})
            node(value, child_path, False)


def main():
    with open(os.path.join(ROOT, "game.project.json"), encoding="utf-8") as f:
        data = json.load(f)
    extra = set(data) - KNOWN_TOP
    if extra:
        fail(f"unknown project fields: {sorted(extra)}")
    tree = data["tree"]
    if tree.get("$className") != "DataModel":
        fail("the root must be DataModel")
    node(tree, [], True)
    os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
    out = os.path.join(ROOT, "build", "manifest.json")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        json.dump({"roots": roots, "entries": entries}, f, indent=1)
    print(f"{len(entries)} entries, {len(roots)} roots -> build/manifest.json")


main()
