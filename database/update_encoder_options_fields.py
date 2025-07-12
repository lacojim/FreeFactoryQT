# Run in this order:
# ffmpeg_db_builder.py --mode update|rebuild
# codecs_capabilities_parser.py
# update_encoder_options_fields.py
# muxers_capabilities_parser.py
# filters_options_parser.py
#

import sqlite3
import re

def extract_option_details(option_line):
    """
    Parses the type, default, and range from a description line.
    Returns (type, default, range)
    """
    type_match = re.search(r'<([^>]+)>', option_line)
    default_match = re.search(r'\(default ([^)]+)\)', option_line)
    range_match = re.search(r'\(from ([^()]+) to ([^)]+)\)', option_line)

    opt_type = type_match.group(1) if type_match else ''
    default = default_match.group(1) if default_match else ''
    opt_range = ''
    if range_match:
        opt_range = f"{range_match.group(1)} to {range_match.group(2)}"

    return opt_type, default, opt_range

def update_options_fields(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT rowid, description FROM encoder_options")
    rows = cursor.fetchall()

    for rowid, description in rows:
        opt_type, default, opt_range = extract_option_details(description or "")
        cursor.execute("""
            UPDATE encoder_options
            SET type = ?, "default" = ?, "range" = ?
            WHERE rowid = ?
        """, (opt_type, default, opt_range, rowid))

    conn.commit()

def main():
    conn = sqlite3.connect("ffmpeg_options.db")
    update_options_fields(conn)
    conn.close()
    print("✅ Encoder options type, default, and range fields updated.")

if __name__ == "__main__":
    main()
