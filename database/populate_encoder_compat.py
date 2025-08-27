#!/usr/bin/env python3

import argparse
import json
import os
import sqlite3
import subprocess
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from queue import Queue

DB_PATH = "ffmpeg_options.db"
OVERRIDES_FILE = "compatibility_overrides.json"
LOG_FILE = "compatibility_probe.log"
BATCH_SIZE = 50

print_lock = threading.Lock()

def log(msg, log_enabled):
    with print_lock:
        print(msg)
        if log_enabled:
            with open(LOG_FILE, "a", encoding="utf-8") as f:
                f.write(msg + "\n")

def get_encoders(cursor, encoder_filter=None, audio_only=False):
    if encoder_filter:
        cursor.execute("SELECT name FROM codecs WHERE encoder=1 AND name = ?", (encoder_filter,))
        return [row[0] for row in cursor.fetchall()]
    elif audio_only:
        cursor.execute("SELECT name FROM codecs WHERE encoder=1 AND type='audio'")
    else:
        cursor.execute("SELECT name FROM codecs WHERE encoder=1 AND type='video'")
    return [row[0] for row in cursor.fetchall()]

def load_overrides():
    if not os.path.exists(OVERRIDES_FILE):
        return set()
    with open(OVERRIDES_FILE, "r", encoding="utf-8") as f:
        try:
            data = json.load(f)
            overrides = set()
            if "force_compatible" in data:
                for video_encoder, audio_list in data["force_compatible"].items():
                    for audio_encoder in audio_list:
                        overrides.add((video_encoder, audio_encoder))
            return overrides
        except Exception as e:
            print(f"⚠ Failed to parse overrides: {e}")
            return set()



def test_compatibility(video_encoder, audio_encoder):
    cmd = [
        "ffmpeg", "-hide_banner", "-y",
        "-f", "lavfi", "-i", "testsrc=size=1280x720:rate=25",
        "-f", "lavfi", "-i", "sine",
        "-t", "1", "-s", "1280x720", "-pix_fmt", "yuv422p",
        "-ar", "48000", "-ac", "2",
        "-c:v", video_encoder, "-c:a", audio_encoder,
        "-f", "nut", "-nostats", "-loglevel", "error", "-"
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10, check=True)
        return True
    except Exception:
        return False

def process_pair(video_encoder, audio_encoder, result_queue, log_enabled, row_id):
    compatible = test_compatibility(video_encoder, audio_encoder)
    msg = f"[{row_id}] {'✅ Compatible' if compatible else '❌ Incompatible'}: {video_encoder} + {audio_encoder}"
    log(msg, log_enabled)
    if compatible:
        result_queue.put((video_encoder, audio_encoder, "probed"))

def insert_compatibilities(cursor, batch):
    cursor.executemany(
        "INSERT OR IGNORE INTO encoder_compatibility (encoder, compatible_encoder, source) VALUES (?, ?, ?)",
        batch
    )

def main():
    parser = argparse.ArgumentParser(description="Populate encoder compatibility matrix.")
    parser.add_argument("--encoder", help="Only test this video encoder")
    parser.add_argument("--audio", action="store_true", help="Only list audio encoders")
    parser.add_argument("--logging", action="store_true", help="Enable logging to compatibility_probe.log")
    args = parser.parse_args()

    if args.logging and os.path.exists(LOG_FILE):
        os.remove(LOG_FILE)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    video_encoders = get_encoders(cursor, encoder_filter=args.encoder, audio_only=args.audio)
    audio_encoders = get_encoders(cursor, audio_only=True)

    log(f"Video encoders: {len(video_encoders)}", args.logging)
    log(f"Audio encoders: {len(audio_encoders)}", args.logging)
    log(f"Testing {len(video_encoders) * len(audio_encoders)} combinations...", args.logging)

    overrides = load_overrides()
    
    if args.encoder:
        for (v, a) in overrides:
            if v == args.encoder:
                log(f"[override] Would manually insert: {v} + {a}", args.logging)
            
            
            if args.encoder:
                manual_inserts = [
                    (v, a, 'manual')
                    for (v, a) in overrides
                    if v == args.encoder
                ]
                if manual_inserts:
                    cursor.executemany(
                        "INSERT OR IGNORE INTO encoder_compatibility (encoder, compatible_encoder, source) VALUES (?, ?, ?)",
                        manual_inserts
                    )
        conn.commit()
        for v, a, _ in manual_inserts:
            log(f"[override] Inserted manually: {v} + {a}", args.logging)
            
            
            

    video_encoders = get_encoders(cursor, encoder_filter=args.encoder, audio_only=args.audio)
    audio_encoders = get_encoders(cursor, audio_only=True)    
    
    result_queue = Queue()

    row_counter = 1
    with ThreadPoolExecutor(max_workers=os.cpu_count()) as executor:
        futures = []
        for v in video_encoders:
            for a in audio_encoders:
                if (v, a) in overrides:
                    cursor.execute("""
                        INSERT OR IGNORE INTO encoder_compatibility (encoder, compatible_encoder, source)
                        VALUES (?, ?, ?)
                    """, (v, a, "manual"))
                    conn.commit()
                    log(f"[{row_counter}] [override] ✅ Compatible: {v} + {a}", args.logging)
                else:
                    futures.append(executor.submit(process_pair, v, a, result_queue, args.logging, row_counter))
                row_counter += 1

        # Collect results and write in batches from main thread
        batch = []
        completed = 0
        total = len(futures)

        for future in as_completed(futures):
            completed += 1
            if completed % 100 == 0:
                log(f"Progress: {completed}/{total}", args.logging)

            while not result_queue.empty():
                batch.append(result_queue.get())
                if len(batch) >= BATCH_SIZE:
                    insert_compatibilities(cursor, batch)
                    conn.commit()
                    batch = []

        while not result_queue.empty():
            batch.append(result_queue.get())
        if batch:
            insert_compatibilities(cursor, batch)
            conn.commit()

    log("🏁 Finished multithreaded compatibility probing.", args.logging)
    conn.close()

if __name__ == "__main__":
    main()
    os.system("reset")  # Reset the terminal display
