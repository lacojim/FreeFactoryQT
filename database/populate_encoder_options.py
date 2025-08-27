"""
populate_encoder_options.py

This script queries FFmpeg for all available encoders, then runs
`ffmpeg -h encoder=NAME` to extract AVOptions in a structured way.
It stores clean encoder option data into the `encoder_options` table
with proper columns: name, type, description, default, and range.
"""

import sqlite3
import subprocess
import re
from pathlib import Path

DB_PATH = "ffmpeg_options.db"

def get_all_encoders():
    result = subprocess.run(["ffmpeg", "-hide_banner", "-encoders"], capture_output=True, text=True)
    lines = result.stdout.splitlines()
    encoders = []
    for line in lines:
        if line.startswith(" "):
            parts = line.strip().split()
            if len(parts) >= 2:
                encoder_name = parts[1]
                encoders.append(encoder_name)
    return encoders

def parse_encoder_help(name):
    result = subprocess.run(["ffmpeg", "-hide_banner", "-h", f"encoder={name}"], capture_output=True, text=True)
    lines = result.stdout.splitlines()
    options_started = False
    options = []

    for line in lines:
        if "AVOptions:" in line:
            options_started = True
            continue
        if options_started:
            if not line.strip():
                break
            match = re.match(r"\s*-([\w\d_]+)\s+<(\w+)>?\s+(.*)", line)
            if match:
                opt_name, opt_type, desc = match.groups()
                default = None
                range_ = None

                # Try to extract default and range
                default_match = re.search(r"\(default ([^)]+)\)", desc)
                range_match = re.search(r"\(from ([^)]+)\)", desc)
                if default_match:
                    default = default_match.group(1).strip()
                    desc = desc.replace(default_match.group(1), "").strip()
                if range_match:
                    range_ = range_match.group(1).strip()
                    desc = desc.replace(range_match.group(1), "").strip()

                desc = re.sub(r"\s{2,}", " ", desc).strip(" -")

                options.append({
                    "encoder": name,
                    "name": opt_name,
                    "type": opt_type,
                    "default": default,
                    "range": range_,
                    "description": desc,
                })
    return options

def main():
    db = sqlite3.connect(DB_PATH)
    cur = db.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS encoder_options (
            encoder TEXT,
            name TEXT,
            type TEXT,
            "default" TEXT,
            range TEXT,
            description TEXT
        )
    """)


    encoders = get_all_encoders()
    print(f"Found {len(encoders)} encoders.")

    inserted = 0
    for enc in encoders:
        opts = parse_encoder_help(enc)
        for opt in opts:
            print(f"Inserting: encoder={opt['encoder']}, name={opt['name']}, type={opt['type']}, default={opt['default']}, range={opt['range']}, description={opt['description'][:60]}...")

            cur.execute('''
                INSERT INTO encoder_options (encoder, name, type, description, "default", range)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                opt["encoder"], opt["name"], opt["type"], opt["description"], opt["default"], opt["range"]
            ))

            inserted += 1

    db.commit()
    db.close()
    print(f"✅ Inserted {inserted} encoder option rows.")

if __name__ == "__main__":
    main()
