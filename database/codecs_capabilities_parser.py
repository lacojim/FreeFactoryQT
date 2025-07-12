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
import time

def create_tables(conn):
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS encoders (
            name TEXT PRIMARY KEY,
            capabilities TEXT,
            threading TEXT,
            framerates TEXT,
            pixel_formats TEXT
        )
    """)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS encoder_options (
            encoder TEXT,
            option_name TEXT,
            type TEXT,
            "default" TEXT,
            "range" TEXT,
            description TEXT,
            FOREIGN KEY(encoder) REFERENCES encoders(name)
        )
    """)
    conn.commit()

def get_all_encoders(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM codecs WHERE encoder = 1")
    return [row[0] for row in cursor.fetchall()]

def run_encoder_help(name):
    try:
        result = subprocess.run(
            ["ffmpeg", "-hide_banner", "-h", f"encoder={name}"],
            capture_output=True, text=True, check=True
        )
        return result.stdout
    except subprocess.CalledProcessError:
        return ""

def parse_encoder_help(name, output):
    capabilities = ""
    threading = ""
    framerates = []
    pixfmts = []
    options = []

    lines = output.splitlines()
    in_options = False

    for line in lines:
        line = line.strip()
        if line.startswith("General capabilities:"):
            capabilities = line.split(":", 1)[1].strip()
        elif line.startswith("Threading capabilities:"):
            threading = line.split(":", 1)[1].strip()
        elif line.startswith("Supported framerates:"):
            framerates = line.split(":", 1)[1].strip().split()
        elif line.startswith("Supported pixel formats:"):
            pixfmts = line.split(":", 1)[1].strip().split()
        elif re.match(r"^-", line):  # option line
            in_options = True
            parts = re.split(r"\s{2,}", line)
            if len(parts) >= 2:
                option = parts[0].strip()
                desc = parts[1].strip()
                options.append((option, "", "", "", desc))
        elif in_options and options:
            # Handle multiline description continuation
            options[-1] = (*options[-1][:4], options[-1][4] + " " + line.strip())

    return {
        "name": name,
        "capabilities": capabilities,
        "threading": threading,
        "framerates": " ".join(framerates),
        "pixel_formats": " ".join(pixfmts),
        "options": options
    }

def store_encoder_data(data, conn):
    cursor = conn.cursor()
    cursor.execute("DELETE FROM encoders WHERE name = ?", (data["name"],))
    cursor.execute("DELETE FROM encoder_options WHERE encoder = ?", (data["name"],))

    cursor.execute("""
        INSERT INTO encoders (name, capabilities, threading, framerates, pixel_formats)
        VALUES (?, ?, ?, ?, ?)
    """, (
        data["name"], data["capabilities"], data["threading"],
        data["framerates"], data["pixel_formats"]
    ))

    for opt in data["options"]:
        cursor.execute("""
            INSERT INTO encoder_options (encoder, option_name, type, "default", "range", description)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (data["name"], opt[0], opt[1], opt[2], opt[3], opt[4]))

    conn.commit()

def main():
    conn = sqlite3.connect("ffmpeg_options.db")
    create_tables(conn)
    encoders = get_all_encoders(conn)

    print(f"Found {len(encoders)} encoders. Parsing...")

    for i, enc in enumerate(encoders):
        print(f"[{i+1}/{len(encoders)}] {enc}")
        out = run_encoder_help(enc)
        if out.strip():
            data = parse_encoder_help(enc, out)
            store_encoder_data(data, conn)
        else:
            print(f"  ⚠️ Skipped (no output or error)")
        time.sleep(0.1)  # Be nice to the CPU

    conn.close()
    print("✅ All encoder capabilities parsed and stored.")

if __name__ == "__main__":
    main()
