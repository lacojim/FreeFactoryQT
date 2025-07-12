# Run in this order:
# ffmpeg_db_builder.py --mode update|rebuild
# codecs_capabilities_parser.py
# update_encoder_options_fields.py
# muxers_capabilities_parser.py
# filters_options_parser.py
#

import sqlite3
import subprocess
import re

DEBUG = True

def run_ffmpeg_help(filter_name):
    try:
        result = subprocess.run(
            ["ffmpeg", "-hide_banner", "-h", f"filter={filter_name}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError:
        return ""

def create_table(conn):
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS filter_options (
            filter TEXT,
            option_name TEXT,
            type TEXT,
            "default" TEXT,
            "range" TEXT,
            description TEXT
        )
    """)
    conn.commit()

def parse_filter_help(filter_name, output):
    options = []
    in_options = False
    matched_any = False

    for line in output.splitlines():
        line = line.strip()

        # Begin AVOptions block
        if line.endswith("AVOptions:"):
            in_options = True
            continue

        # Stop at next empty line or unrelated block
        if in_options and (line == "" or not line.startswith("-") and not re.match(r"^\w", line)):
            in_options = False
            continue

        # Parse AVOption line
        if in_options and not line.startswith("-"):  # avoid noise lines
            # Example: sigma             <float>      ..FV.....T. set sigma (from 0 to 1024) (default 0.5)
            match = re.match(r"^(\S+)\s+<(\w+)>+\s+\S+\s+(.*)", line)
            if match:
                matched_any = True
                option_name, opt_type, desc = match.groups()
                options.append({
                    "filter": filter_name,
                    "option_name": option_name.strip(),
                    "type": opt_type.strip(),
                    "default": "",
                    "range": "",
                    "description": desc.strip()
                })
            else:
                if DEBUG:
                    print(f"⚠️ Unparsed AVOption line in {filter_name}: {line}")

    if DEBUG:
        if matched_any:
            print(f"✅ AVOptions parsed for: {filter_name}")
        else:
            print(f"❌ No AVOptions found for: {filter_name}")

    return options

def main():
    db_path = "/opt/FreeFactory/database/ffmpeg_options.db"
    conn = sqlite3.connect(db_path)
    create_table(conn)

    cursor = conn.cursor()
    cursor.execute("SELECT name FROM filters")
    filters = [row[0] for row in cursor.fetchall()]

    total_options = 0
    filters_with_options = 0

    for filter_name in filters:
        if DEBUG:
            print(f"🔍 Parsing: {filter_name}")
        output = run_ffmpeg_help(filter_name)
        if not output:
            continue

        options = parse_filter_help(filter_name, output)
        if not options:
            continue

        filters_with_options += 1
        total_options += len(options)

        cursor.execute("DELETE FROM filter_options WHERE filter = ?", (filter_name,))
        for opt in options:
            cursor.execute("""
                INSERT INTO filter_options
                (filter, option_name, type, "default", "range", description)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                opt["filter"], opt["option_name"], opt["type"],
                opt["default"], opt["range"], opt["description"]
            ))

    conn.commit()
    conn.close()

    print(f"\n✅ Completed: {filters_with_options} filters with AVOptions")
    print(f"📝 Total AVOptions inserted: {total_options}")

if __name__ == "__main__":
    main()
