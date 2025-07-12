import argparse
import sqlite3
import subprocess
import re
from pathlib import Path

DB_NAME = "ffmpeg_options.db"

def run_ffmpeg_command(args):
    if "-hide_banner" not in args:
        args.insert(1, "-hide_banner")
    result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    return result.stdout


def create_tables(conn):
    cursor = conn.cursor()
    cursor.execute("DROP TABLE IF EXISTS codecs")
    cursor.execute("DROP TABLE IF EXISTS filters")
    cursor.execute("DROP TABLE IF EXISTS muxers")
    cursor.execute("DROP TABLE IF EXISTS bitstream_filters")
    cursor.execute("DROP TABLE IF EXISTS pixel_formats")

    cursor.execute("""
        CREATE TABLE codecs (
            name TEXT PRIMARY KEY,
            type TEXT,
            encoder BOOLEAN,
            decoder BOOLEAN,
            description TEXT
        )
    """)
    cursor.execute("""
        CREATE TABLE filters (
            name TEXT PRIMARY KEY,
            type TEXT,
            description TEXT
        )
    """)
    cursor.execute("""
        CREATE TABLE muxers (
            name TEXT PRIMARY KEY,
            description TEXT
        )
    """)
    cursor.execute("""
        CREATE TABLE bitstream_filters (
            name TEXT PRIMARY KEY,
            description TEXT
        )
    """)
    cursor.execute("""
        CREATE TABLE pixel_formats (
            name TEXT PRIMARY KEY,
            nb_components INTEGER,
            bits_per_pixel INTEGER,
            flags TEXT,
            description TEXT
        )
    """)
    conn.commit()

def parse_codecs(output, conn, update_only=False):
    cursor = conn.cursor()
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith('=') or line.lower().startswith('codecs'):
            continue
        if len(line) < 10:
            continue
        flags = line[:7].strip()
        rest = line[7:].strip()
        parts = rest.split(None, 1)
        if len(parts) != 2:
            continue
        name, desc = parts
        if name == '=':
            continue
        codec_type = 'video' if 'V' in flags else 'audio' if 'A' in flags else 'subtitle' if 'S' in flags else 'data' if 'D' in flags else 'other'
        decoder = 'D' in flags
        encoder = 'E' in flags
        try:
            if update_only:
                cursor.execute("INSERT OR IGNORE INTO codecs VALUES (?, ?, ?, ?, ?)", (name, codec_type, encoder, decoder, desc))
            else:
                cursor.execute("INSERT INTO codecs VALUES (?, ?, ?, ?, ?)", (name, codec_type, encoder, decoder, desc))
        except sqlite3.IntegrityError:
            continue
    conn.commit()



def parse_filters(output, conn, update_only=False):
    cursor = conn.cursor()
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith('=') or line.lower().startswith('filters'):
            continue
        if re.match(r'^[ TSCAVN\.\|]{3}\s+\S', line):
            parts = line.strip().split(None, 2)
            if len(parts) < 3:
                continue
            flags, name, desc = parts
            if name == '=':
                continue
            filter_type = 'video' if 'V' in flags else 'audio' if 'A' in flags else 'other'
            try:
                if update_only:
                    cursor.execute("INSERT OR IGNORE INTO filters VALUES (?, ?, ?)", (name, filter_type, desc))
                else:
                    cursor.execute("INSERT INTO filters VALUES (?, ?, ?)", (name, filter_type, desc))
            except sqlite3.IntegrityError:
                continue
    conn.commit()


def parse_muxers(output, conn, update_only=False):
    cursor = conn.cursor()
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith('=') or 'Formats:' in line or line.startswith('--'):
            continue
        if len(line) < 4:
            continue
        rest = line[4:].strip()
        parts = rest.split(None, 1)
        if len(parts) != 2:
            continue
        name, desc = parts
        if name == '=':
            continue
        try:
            if update_only:
                cursor.execute("INSERT OR IGNORE INTO muxers VALUES (?, ?)", (name, desc))
            else:
                cursor.execute("INSERT INTO muxers VALUES (?, ?)", (name, desc))
        except sqlite3.IntegrityError:
            continue
    conn.commit()



def parse_bsfs(output, conn, update_only=False):
    cursor = conn.cursor()
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith('Bitstream filters') or line.startswith('='):
            continue
        parts = line.split(None, 1)
        name = parts[0]
        desc = parts[1] if len(parts) > 1 else ''
        try:
            if update_only:
                cursor.execute("INSERT OR IGNORE INTO bitstream_filters VALUES (?, ?)", (name, desc))
            else:
                cursor.execute("INSERT INTO bitstream_filters VALUES (?, ?)", (name, desc))
        except sqlite3.IntegrityError:
            continue
    conn.commit()


def parse_pix_fmts(output, conn, update_only=False):
    cursor = conn.cursor()
    parsing = False
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith("Pixel formats") or line.startswith("FLAGS") or line.startswith("-----"):
            continue
        match = re.match(r"^(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+([\d\-]+)$", line)
        if not match:
            continue
        flags, name, nb_components, bpp, bit_depths = match.groups()
        description = f"bit_depths={bit_depths}"  # Fake desc for compatibility
        try:
            if update_only:
                cursor.execute("INSERT OR IGNORE INTO pixel_formats VALUES (?, ?, ?, ?, ?)",
                               (name, int(nb_components), int(bpp), flags, description))
            else:
                cursor.execute("INSERT INTO pixel_formats VALUES (?, ?, ?, ?, ?)",
                               (name, int(nb_components), int(bpp), flags, description))
        except (sqlite3.IntegrityError, ValueError):
            continue
    conn.commit()


def main():
    parser = argparse.ArgumentParser(description="Populate FFmpeg options into SQLite database.")
    parser.add_argument("--mode", choices=["rebuild", "update"], required=True, help="Database mode: rebuild or update")
    args = parser.parse_args()

    db_path = Path(DB_NAME)
    conn = sqlite3.connect(DB_NAME)

    if args.mode == "rebuild":
        create_tables(conn)

    # Pull and parse data
    parse_codecs(run_ffmpeg_command(["ffmpeg", "-codecs"]), conn, update_only=(args.mode == "update"))
    parse_filters(run_ffmpeg_command(["ffmpeg", "-filters"]), conn, update_only=(args.mode == "update"))
    parse_muxers(run_ffmpeg_command(["ffmpeg", "-muxers"]), conn, update_only=(args.mode == "update"))
    parse_bsfs(run_ffmpeg_command(["ffmpeg", "-bsfs"]), conn, update_only=(args.mode == "update"))
    parse_pix_fmts(run_ffmpeg_command(["ffmpeg", "-pix_fmts"]), conn, update_only=(args.mode == "update"))

    conn.close()
    print(f"FFmpeg option database updated in {DB_NAME} (mode: {args.mode}).")

if __name__ == "__main__":
    main()
