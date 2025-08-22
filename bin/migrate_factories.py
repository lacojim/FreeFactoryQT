#!/usr/bin/env python3
import argparse
import os
from pathlib import Path
import glob
import shutil
import sys

def parse_key_value_pairs(pairs_string):
    pairs = {}
    for pair in pairs_string.split(','):
        if '=' in pair:
            key, value = pair.split('=', 1)
            pairs[key.strip()] = value.strip()
    return pairs

def backup_file(file_path):
    backup_path = f"{file_path}.bak"
    shutil.copyfile(file_path, backup_path)
    print(f"🔁 Backup created: {backup_path}")

def migrate_factories(root, pattern, add, set_, remove, rename, dry_run, do_backup, quiet):
    root_path = Path(root).expanduser().resolve()
    files = list(root_path.glob(pattern))

    if not files:
        print(f"❌ No matching factory files found in: {root_path}")
        return

    modified_count = 0

    for file in files:
        with open(file, 'r') as f:
            lines = f.readlines()

        original_lines = lines[:]
        updated_lines = []
        keys_seen = set()

        # Parse renaming if specified
        rename_map = {}
        if rename:
            for pair in rename.split(','):
                if '=' in pair:
                    old, new = pair.split('=', 1)
                    rename_map[old.strip()] = new.strip()

        for line in lines:
            stripped = line.strip()
            if '=' not in stripped:
                updated_lines.append(line)
                continue

            key, value = stripped.split('=', 1)
            key = key.strip()

            # Rename keys if matched
            if key in rename_map:
                new_key = rename_map[key]
                updated_lines.append(f"{new_key}={value.strip()}\n")
                keys_seen.add(new_key)
            elif key in set_:
                updated_lines.append(f"{key}={set_[key]}\n")
                keys_seen.add(key)
            elif key in remove:
                continue  # omit this key
            else:
                updated_lines.append(line)
                keys_seen.add(key)

        # Add any missing keys (only if not already present)
        for key, value in add.items():
            if key not in keys_seen:
                updated_lines.append(f"{key}={value}\n")
                keys_seen.add(key)

        # Add or overwrite keys for --set
        for key, value in set_.items():
            if key not in keys_seen:
                updated_lines.append(f"{key}={value}\n")

        if updated_lines != original_lines:
            modified_count += 1
            if not dry_run:
                if do_backup:
                    backup_file(file)
                with open(file, 'w') as f:
                    f.writelines(updated_lines)

    if dry_run:
        print(f"[DRY-RUN] {modified_count} factory file(s) would be modified.")
    else:
        print(f"✅ {modified_count} factory file(s) modified.")

def main():
    parser = argparse.ArgumentParser(
        description="Migrate FreeFactory factory files (add/set/remove key=value).",
        epilog="""
Examples:
  python3 migrate_factories.py --add LOWLATENCYINPUT=False,AUTOMAPAV=False --dry-run
  python3 migrate_factories.py --set LOWLATENCYINPUT=False
  python3 migrate_factories.py --remove VIDEOSIZE
  python3 migrate_factories.py --rename MANUALOPTIONS=MANUALOPTIONSOUTPUT
""",
        formatter_class=argparse.RawTextHelpFormatter
    )

    # Default root path fallback logic
    default_root = (
        str(Path("~/.freefactory/factories").expanduser())
        if Path("~/.freefactory/factories").expanduser().exists()
        else "/opt/FreeFactory/Factories"
    )

    parser.add_argument('--root', default=default_root, help=f'Directory containing factory files (default: {default_root})')
    parser.add_argument('--pattern', default="*", help='Glob pattern to select files (default: "*"). Examples: "*.fact", "*.fcty", "*.factory"')
    parser.add_argument('--add', help='Add key=value pairs ONLY if missing (comma-separated)')
    parser.add_argument('--set', dest='set_', help='Force-set/override key=value pairs (comma-separated)')
    parser.add_argument('--remove', help='Remove keys (comma-separated)')
    parser.add_argument('--rename', help='Rename keys (comma-separated OLD=NEW pairs)')
    parser.add_argument('--dry-run', action='store_true', help='Show what would change; do not write')
    parser.add_argument('--backup', action='store_true', help='Create .bak backups (opt-in)')
    parser.add_argument('--quiet', action='store_true', help='Reduce output')

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()

    add_pairs = parse_key_value_pairs(args.add) if args.add else {}
    set_pairs = parse_key_value_pairs(args.set_) if args.set_ else {}
    remove_keys = args.remove.split(',') if args.remove else []

    migrate_factories(
        root=args.root,
        pattern=args.pattern,
        add=add_pairs,
        set_=set_pairs,
        remove=remove_keys,
        rename=args.rename,
        dry_run=args.dry_run,
        do_backup=args.backup,
        quiet=args.quiet
    )

if __name__ == "__main__":
    main()
