from pathlib import Path
import sqlite3
import subprocess
import re

DB_PATH = Path("/opt/FreeFactory/database/ffmpeg_options.db")
DEBUG_LOG = Path("populate_filter_options_debug.txt")

def log(msg):
    with DEBUG_LOG.open("a", encoding="utf-8") as f:
        f.write(msg + "\n")

def reset_log():
    DEBUG_LOG.write_text("=== FFmpeg Filter Options Debug Log ===\n\n")

def get_filters():
    result = subprocess.run(["ffmpeg", "-hide_banner", "-filters"], capture_output=True, text=True)
    lines = result.stdout.splitlines()
    filters = []
    for line in lines:
        match = re.match(r'^\s*[\.A-Z]+\s+([a-z0-9_]+)\s+', line)
        if match:
            filters.append(match.group(1))
    log(f"[INFO] Found {len(filters)} filters")
    return filters

def parse_filter_help(filter_name):
    result = subprocess.run(["ffmpeg", "-hide_banner", "-h", f"filter={filter_name}"],
                            capture_output=True, text=True)
    help_text = result.stdout
    options = []
    current_option = None
    for line in help_text.splitlines():
        if not line.strip():
            continue
        if m := re.match(r"^\s*(\S+)\s+<(\S+)>\s+(.*?)\s+(.*)", line):
            name, opt_type, flags, desc = m.groups()
            current_option = {
                "name": name,
                "type": opt_type,
                "flags": flags,
                "desc": desc.strip()
            }
            options.append(current_option)
        elif current_option:
            current_option["desc"] += " " + line.strip()
    return options

def extract_default_and_range(desc):
    default = ""
    range_ = ""
    if m := re.search(r"\(default ([^)]+)\)", desc):
        default = m.group(1)
    if m := re.search(r"\(from ([^)]+)\)", desc):
        range_ = "from " + m.group(1)
    if m := re.search(r"\(from [^)]+ to [^)]+\)", desc):
        range_ = m.group(0)[1:-1]
    return default, range_

def clean_description(desc):
    # Remove flag groups like ..FV..... or ..F.A......
    return re.sub(r"\s*[\.A-Z]{6,}\s*", " ", desc).strip()

def rebuild_filter_options_table(cursor):
    cursor.execute("DROP TABLE IF EXISTS filter_options")
    cursor.execute("VACUUM")
    cursor.execute("""
        CREATE TABLE filter_options (
            filter TEXT,
            name TEXT,
            type TEXT,
            "default" TEXT,
            range TEXT,
            description TEXT
        )
    """)

def populate_database():
    reset_log()
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    rebuild_filter_options_table(cur)

    filters = get_filters()
    rows = []
    skipped = 0

    for filt in filters:
        try:
            options = parse_filter_help(filt)
        except Exception as e:
            log(f"[ERROR] Failed to parse help for filter '{filt}': {e}")
            skipped += 1
            continue

        for opt in options:
            default, range_ = extract_default_and_range(opt["desc"])
            description = clean_description(opt["desc"])
            row = (filt, opt["name"], opt["type"], default, range_, description)
            rows.append(row)
            log(f"[ROW] {row[:3]}... Desc: {description[:60]}")

    cur.executemany("""
        INSERT INTO filter_options (filter, name, type, "default", range, description)
        VALUES (?, ?, ?, ?, ?, ?)
    """, rows)

    conn.commit()
    conn.close()

    log(f"\n[SUMMARY] Inserted {len(rows)} rows. Skipped {skipped} filters.")

if __name__ == "__main__":
    populate_database()
