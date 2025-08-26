#!/usr/bin/env python3
"""
FreeFactory migrator

Add, set (override), or remove key=value pairs across factory files.

CHANGES
- Default pattern now "*" (no extension required).
- Content sniffing ensures we only touch real factory files.
- Backups are now OPT-IN via --backup (no .bak clutter by default).

USAGE
# Preview: add missing keys (won't touch existing values)
python3 migrate_factories.py --add LOWLATENCYINPUT=False,AUTOMAPAV=False,INCLUDETQS=True,TQSSIZE=512 --dry-run

# Apply the same
python3 migrate_factories.py --add LOWLATENCYINPUT=False,AUTOMAPAV=False,INCLUDETQS=True,TQSSIZE=512

# Force reset values everywhere (override), with explicit backup
python3 migrate_factories.py --set LOWLATENCYINPUT=False,AUTOMAPAV=False --backup

# Remove keys
python3 migrate_factories.py --remove VIDEOSIZE,DEPRECATEDFLAG

# Limit to a pattern later (e.g., new '.fact' or '.fcty')
python3 migrate_factories.py --pattern "*.fact" --set LOWLATENCYINPUT=False
"""

from __future__ import annotations
import argparse
import pathlib
import re
import shutil
import sys
from typing import Dict, List, Tuple

DEFAULT_ROOT = "/opt/FreeFactory/Factories"

# Keys we look for to decide if a file is a FreeFactory factory
FACTORY_SIGNATURE_KEYS = (
    "ENABLEFACTORY", "FREEFACTORYACTION", "STREAMINPUTVIDEO", "FORCEFORMATINPUTVIDEO",
    "MANUALOPTIONS", "MANUALOPTIONSINPUT"
)

def parse_pairs(arg: str | None) -> Dict[str, str]:
    out: Dict[str, str] = {}
    if not arg:
        return out
    for item in arg.split(","):
        item = item.strip()
        if not item:
            continue
        if "=" not in item:
            raise ValueError(f"Expected key=value, got: {item}")
        k, v = item.split("=", 1)
        out[k.strip().upper()] = v.strip()
    return out

def parse_keys(arg: str | None) -> List[str]:
    if not arg:
        return []
    return [k.strip().upper() for k in arg.split(",") if k.strip()]

def has_key(text: str, key_uc: str) -> bool:
    return re.search(rf"^\s*{re.escape(key_uc)}\s*=", text, flags=re.M|re.I) is not None

def set_key(text: str, key_uc: str, value: str) -> Tuple[str, bool]:
    pat = re.compile(rf"^\s*{re.escape(key_uc)}\s*=.*$", re.M|re.I)
    replacement = f"{key_uc}={value}"
    if pat.search(text):
        new = pat.sub(replacement, text)
        return new, (new != text)
    if not text.endswith("\n"):
        text += "\n"
    return text + replacement + "\n", True

def add_key_if_missing(text: str, key_uc: str, value: str) -> Tuple[str, bool]:
    if has_key(text, key_uc):
        return text, False
    if not text.endswith("\n"):
        text += "\n"
    return text + f"{key_uc}={value}\n", True

def remove_key(text: str, key_uc: str) -> Tuple[str, bool]:
    pat = re.compile(rf"^\s*{re.escape(key_uc)}\s*=.*\n?", re.M|re.I)
    new = pat.sub("", text)
    return new, (new != text)

def looks_like_factory(text: str) -> bool:
    # Identify FreeFactory files by presence of any signature key at line start
    for k in FACTORY_SIGNATURE_KEYS:
        if re.search(rf"^\s*{re.escape(k)}\s*=", text, flags=re.M|re.I):
            return True
    return False

def process_file(
    path: pathlib.Path,
    add_pairs: Dict[str, str],
    set_pairs: Dict[str, str],
    remove_keys: List[str],
    *,
    dry_run: bool,
    backup: bool,
    quiet: bool,
) -> Tuple[bool, List[str]]:
    try:
        original = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        if not quiet:
            print(f"skip (binary?): {path.name}")
        return False, []
    if not looks_like_factory(original):
        if not quiet:
            print(f"skip (not a factory): {path.name}")
        return False, []

    text = original
    changes: List[str] = []

    # 1) remove requested keys
    for k in remove_keys:
        text2, changed = remove_key(text, k)
        if changed:
            changes.append(f"removed {k}")
            text = text2

    # 2) set/override (also adds if missing)
    for k, v in set_pairs.items():
        text2, changed = set_key(text, k, v)
        if changed:
            changes.append(("set " if has_key(original, k) else "added ") + f"{k}={v}")
            text = text2

    # 3) add if missing
    for k, v in add_pairs.items():
        if has_key(text, k):
            continue
        text2, changed = add_key_if_missing(text, k, v)
        if changed:
            changes.append(f"added {k}={v}")
            text = text2

    if text != original:
        if not dry_run:
            if backup:
                shutil.copy2(path, path.with_suffix(path.suffix + ".bak"))
            path.write_text(text, encoding="utf-8")
        if not quiet:
            print(f"updated: {path.name} -> {', '.join(changes)}")
        return True, changes
    else:
        if not quiet:
            print(f"no change: {path.name}")
        return False, []

def main(argv=None) -> int:
    p = argparse.ArgumentParser(
        description="Migrate FreeFactory factory files (add/set/remove key=value).",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    p.add_argument("--root", default=DEFAULT_ROOT,
                   help=f"Directory containing factory files (default: {DEFAULT_ROOT})")
    p.add_argument("--pattern", default="*",
                   help='Glob pattern to select files (default: "*"). '
                        'Examples: "*.fact", "*.fcty", "*.factory"')
    p.add_argument("--add", help="Add key=value pairs ONLY if missing (comma-separated)")
    p.add_argument("--set", help="Force-set/override key=value pairs (comma-separated)")
    p.add_argument("--remove", help="Remove keys (comma-separated)")
    p.add_argument("--dry-run", action="store_true", help="Show what would change; do not write")
    p.add_argument("--backup", action="store_true", help="Create .bak backups (opt-in)")
    p.add_argument("--quiet", action="store_true", help="Reduce output")
    args = p.parse_args(argv)

    add_pairs   = parse_pairs(args.add)
    set_pairs   = parse_pairs(args.set)
    remove_keys = parse_keys(args.remove)

    if not (add_pairs or set_pairs or remove_keys):
        p.print_help()
        print("\nExamples:")
        print("  python3 migrate_factories.py --add LOWLATENCYINPUT=False,AUTOMAPAV=False --dry-run")
        print("  python3 migrate_factories.py --set LOWLATENCYINPUT=False")
        print("  python3 migrate_factories.py --remove VIDEOSIZE")
        return 0

    root = pathlib.Path(args.root).expanduser()
    if not root.is_dir():
        print(f"error: root not found: {root}", file=sys.stderr)
        return 2

    # Gather candidates; ignore hidden files and *.bak by default
    candidates = []
    for pth in sorted(root.glob(args.pattern)):
        if not pth.is_file():
            continue
        if pth.name.startswith("."):
            continue
        if pth.suffix == ".bak":
            continue
        candidates.append(pth)

    if not candidates:
        print(f"no files match {root}/{args.pattern}")
        return 0

    changed_files = 0
    for f in candidates:
        ch, _ = process_file(
            f,
            add_pairs=add_pairs,
            set_pairs=set_pairs,
            remove_keys=remove_keys,
            dry_run=args.dry_run,
            backup=args.backup,     # backups are opt-in now
            quiet=args.quiet,
        )
        if ch:
            changed_files += 1

    suffix = " (dry-run)" if args.dry_run else ""
    print(f"Done. Files changed: {changed_files}{suffix}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
