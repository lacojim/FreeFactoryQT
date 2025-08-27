import subprocess
import sqlite3
import re

def get_all_muxers():
    result = subprocess.run(["ffmpeg", "-hide_banner", "-muxers"],
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    lines = result.stdout.splitlines()

    muxers = []
    for line in lines:
        line = line.strip()
        if not line or line.startswith("Muxers:") or line.startswith("------"):
            continue
        # Look for lines that begin with flags and a valid muxer name
        parts = line.split()
        if len(parts) >= 2:
            muxer = parts[1]
            # Avoid broken lines like '='
            if muxer != "=" and muxer.isidentifier():
                muxers.append(muxer)
            else:
                print(f"⚠️ Skipping suspicious muxer name: '{muxer}'")
    return muxers


def parse_muxer_help(muxer):
    import re
    print(f"🔍 Parsing muxer: {muxer}")

    try:
        result = subprocess.run(
            ["ffmpeg", "-hide_banner", "-h", f"muxer={muxer}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=True
        )
    except subprocess.CalledProcessError:
        print(f"⚠ Failed to get help for muxer: {muxer}")
        return []

    output = result.stdout
    lines = output.splitlines()
    options_started = False
    parsed_options = []

    # Regex to match: -option <type> [E-flags] (range?) (default?) description
    option_line = re.compile(r"^\s+-([^\s]+)\s+<(\w+)>.*?E.*?(?:\(.*?\))*\s*(.*)")
    default_pattern = re.compile(r"\(default\s+([^)]+)\)")
    range_pattern = re.compile(r"\(from\s+([^)]+)\)")

    for line in lines:
        if not options_started:
            if "muxer AVOptions:" in line:
                print("✅ Found 'muxer AVOptions:' block")
                options_started = True
            continue

        if options_started:
            if line.strip() == "":
                break  # end of options section

            match = option_line.match(line)
            if not match:
                continue

            name = match.group(1).strip()
            type_ = match.group(2).strip()
            desc = match.group(3).strip()

            default_match = default_pattern.search(desc)
            range_match = range_pattern.search(desc)

            default = default_match.group(1).strip() if default_match else ""
            range_ = range_match.group(1).strip() if range_match else ""

            parsed_options.append({
                "muxer": muxer,
                "name": name,
                "type": type_,
                "default": default,
                "range": range_,
                "description": desc
            })

    return parsed_options




def main():
    conn = sqlite3.connect("ffmpeg_options.db")
    cur = conn.cursor()

    # DROP and recreate table
    cur.execute("DROP TABLE IF EXISTS muxer_options")
    cur.execute("""
        CREATE TABLE muxer_options (
            muxer TEXT,
            name TEXT,
            type TEXT,
            "default" TEXT,
            range TEXT,
            description TEXT
        )
    """)

    muxers = get_all_muxers()
    print(f"Found {len(muxers)} muxers.")

    total_opts = 0
    for muxer in muxers:
        opts = parse_muxer_help(muxer)
        for opt in opts:
            cur.execute('''
                INSERT INTO muxer_options (muxer, name, type, "default", range, description)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                opt["muxer"], opt["name"], opt["type"], opt["default"], opt["range"], opt["description"]
            ))
        if opts:
            print(f"✔ Parsed {len(opts):2} options for muxer: {muxer}")
        total_opts += len(opts)

    conn.commit()
    conn.close()
    print(f"✅ Muxer options populated successfully with {total_opts} total options.")

if __name__ == "__main__":
    main()
