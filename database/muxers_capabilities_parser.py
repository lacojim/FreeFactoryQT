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

def run_ffmpeg_help(muxer_name):
    try:
        result = subprocess.run(
            ["ffmpeg", "-hide_banner", "-h", f"muxer={muxer_name}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError:
        return ""

def create_tables(conn):
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS muxers_info (
            name TEXT PRIMARY KEY,
            description TEXT,
            extensions TEXT,
            mime_type TEXT,
            default_vcodec TEXT,
            default_acodec TEXT
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS muxer_options (
            muxer TEXT,
            option_name TEXT,
            type TEXT,
            "default" TEXT,
            "range" TEXT,
            description TEXT
        )
    """)
    conn.commit()

def parse_muxer_help(muxer_name, output):
    info = {
        "name": muxer_name,
        "description": "",
        "extensions": "",
        "mime_type": "",
        "default_vcodec": "",
        "default_acodec": ""
    }

    options = []

    in_options = False
    for line in output.splitlines():
        line = line.strip()

        if line.startswith("Muxer") and "[" in line:
            # Muxer mxf [MXF (Material eXchange Format)]:
            match = re.search(r'\[(.*?)\]', line)
            if match:
                info["description"] = match.group(1)

        elif line.startswith("Common extensions:"):
            info["extensions"] = line.split(":", 1)[-1].strip().rstrip(".")

        elif line.startswith("Mime type:"):
            info["mime_type"] = line.split(":", 1)[-1].strip().rstrip(".")

        elif line.startswith("Default video codec:"):
            info["default_vcodec"] = line.split(":", 1)[-1].strip().rstrip(".")

        elif line.startswith("Default audio codec:"):
            info["default_acodec"] = line.split(":", 1)[-1].strip().rstrip(".")

        elif "muxer AVOptions" in line:
            in_options = True
            continue

        elif in_options and line.startswith("-"):
            parts = re.split(r'\s{2,}', line)
            if len(parts) >= 3:
                option_name = parts[0].strip()
                opt_type_match = re.search(r'<(.*?)>', parts[1])
                opt_type = opt_type_match.group(1) if opt_type_match else ""
                description = parts[2]
                options.append({
                    "muxer": muxer_name,
                    "option_name": option_name,
                    "type": opt_type,
                    "default": "",
                    "range": "",
                    "description": description
                })

    return info, options

def main():
    conn = sqlite3.connect("/opt/FreeFactory/database/ffmpeg_options.db")
    create_tables(conn)

    cursor = conn.cursor()
    cursor.execute("SELECT name FROM muxers")
    muxers = [row[0] for row in cursor.fetchall()]

    for muxer in muxers:
        print(f"Parsing: {muxer}")
        output = run_ffmpeg_help(muxer)
        if not output:
            continue
        info, options = parse_muxer_help(muxer, output)

        # Insert muxer info
        cursor.execute("""
            INSERT OR REPLACE INTO muxers_info
            (name, description, extensions, mime_type, default_vcodec, default_acodec)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            info["name"], info["description"], info["extensions"],
            info["mime_type"], info["default_vcodec"], info["default_acodec"]
        ))

        # Clear previous options for this muxer
        cursor.execute("DELETE FROM muxer_options WHERE muxer = ?", (muxer,))
        for opt in options:
            cursor.execute("""
                INSERT INTO muxer_options
                (muxer, option_name, type, "default", "range", description)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                opt["muxer"], opt["option_name"], opt["type"],
                opt["default"], opt["range"], opt["description"]
            ))

    conn.commit()
    conn.close()
    print("✅ Muxer info and options parsed and stored.")

if __name__ == "__main__":
    main()
