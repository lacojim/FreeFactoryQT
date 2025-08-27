#!/usr/bin/env python3

import subprocess
import sqlite3
import re

DB_PATH = "ffmpeg_options.db"  # Adjust path as needed

def get_all_bsf_names():
    result = subprocess.run(["ffmpeg", "-hide_banner", "-bsfs"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    return [line.strip().split()[0] for line in result.stdout.splitlines() if line.strip() and not line.startswith("Bitstream filters:")]

import re
import subprocess

import subprocess
import re

def parse_bsf_help(bsf):
    print(f"🔍 Parsing bitstream filter: {bsf}")

    result = subprocess.run(
        ["ffmpeg", "-hide_banner", "-h", f"bsf={bsf}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    output = result.stdout
    lines = output.splitlines()
    parsed_options = []
    options_started = False

    option_line = re.compile(
        r'^\s*-(?P<name>[a-zA-Z0-9_]+)\s+<(?P<type>[^>]+)>\s+.*?\.\.\..*?\s*(?P<desc>.*)'
    )
    default_pattern = re.compile(r'\(default\s+([^)]+)\)')
    range_pattern = re.compile(r'\(from\s+([^)]+)\)')

    for line in lines:
        if not options_started:
            if "AVOptions:" in line:
                options_started = True
            continue

        if options_started:
            match = option_line.match(line)
            if not match:
                continue

            name = match.group("name")
            typ = match.group("type")
            desc = match.group("desc")

            default_match = default_pattern.search(desc)
            range_match = range_pattern.search(desc)

            default = default_match.group(1).strip() if default_match else ""
            range_ = range_match.group(1).strip() if range_match else ""

            parsed_options.append({
                "bsf": bsf,
                "name": name,
                "type": typ,
                "default": default,
                "range": range_,
                "description": desc.strip()
            })

    if not parsed_options:
        print(f"⚠ No options found for BSF: {bsf}")

    return parsed_options




def main():
    import sqlite3

    conn = sqlite3.connect("ffmpeg_options.db")
    cur = conn.cursor()

    # Drop and recreate the table if needed
    cur.execute("DROP TABLE IF EXISTS bitstream_filter_options")
    cur.execute("""
        CREATE TABLE bitstream_filter_options (
            bsf TEXT,
            name TEXT,
            type TEXT,
            "default" TEXT,
            range TEXT,
            description TEXT
        )
    """)

    bsfs = get_all_bsf_names()
    print(f"Found {len(bsfs)} bitstream filters.")

    for bsf in bsfs:
        opts = parse_bsf_help(bsf)

        # ✅ SAFETY CHECK GOES HERE
        if not opts:
            print(f"⚠ No options found for {bsf}")
            continue

        for opt in opts:
            cur.execute("""
                INSERT INTO bitstream_filter_options (bsf, name, type, "default", range, description)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                opt["bsf"], opt["name"], opt["type"], opt["default"], opt["range"], opt["description"]
            ))

    conn.commit()
    conn.close()
    print("✅ Bitstream filter options populated successfully.")






if __name__ == "__main__":
    main()
