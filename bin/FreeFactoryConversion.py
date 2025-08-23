#!/usr/bin/env python3
#############################################################################
#               This code is licensed under the GPLv3
#    The following terms apply to all files associated with the software
#    unless explicitly disclaimed in individual files or parts of files.
#
#                           Free Factory
#
#                      Copyright 2013 - 2025
#                               by
#                     Jim Hines and Karl Swisher
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Script Name:Conversion.py
#
#  This script converts the file passed in the SoureFileName variable
#  to a output file in a output directory with the audio and video
#  options specified in the factory. This script calls FFmpeg to do the 
#  conversion(s).
########################################################################################
#
#FreeFactoryConversion.py — Python rewrite (watch service)
#
#Enhancements in this build:
# - Robust reprocess detection using (st_dev, st_ino, st_mtime_ns, st_size).
# - Prevents FFmpeg from reading your TTY (adds -nostdin and uses stdin=DEVNULL).
# - Prints a clear concurrency banner (CPU/GPU) and encoder in use.


from __future__ import annotations

import argparse
import sys
import time
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, NamedTuple

from config_manager import ConfigManager  # type: ignore
from core import FreeFactoryCore  # type: ignore

# Ensure local project modules are importable when running this script standalone.
PROJECT_ROOT = Path(__file__).resolve().parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


def _as_bool(val: Optional[str]) -> bool:
    s = (val or "").strip().lower()
    return s in ("true", "yes", "1", "on")


def is_settled(path: Path, min_age_sec: float = 2.0) -> bool:
    """
    Returns True if the file's mtime is at least min_age_sec old.
    Protects against grabbing files that are still being written.
    """
    try:
        st = path.stat()
        return (time.time() - st.st_mtime) >= min_age_sec
    except FileNotFoundError:
        return False




def read_factory(factory_path: Path) -> Dict[str, str]:
    data: Dict[str, str] = {}
    if not factory_path.exists():
        raise FileNotFoundError(f"Factory not found: {factory_path}")
    for raw in factory_path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        data[k.strip().upper()] = v.strip()
    return data


def ensure_log_dir() -> Path:
    candidates = [
        Path("/var/log/FreeFactory"),
        Path.home() / ".freefactory" / "logs",
        PROJECT_ROOT / "logs",
    ]
    for p in candidates:
        try:
            p.mkdir(parents=True, exist_ok=True)
            test = p / ".write_test"
            test.write_text("ok", encoding="utf-8")
            test.unlink(missing_ok=True)
            return p
        except Exception:
            continue
    return PROJECT_ROOT
    

def build_log_path(log_dir: Path, input_file: Path) -> Path:
    safe_parent = "_".join(input_file.parent.parts[-2:]) if len(input_file.parent.parts) >= 2 else input_file.parent.name
    return log_dir / f"{safe_parent}__{input_file.name}.log"



def _which_accel(factory: Dict[str, str]) -> str:
    """Return a short name for the hardware encoder inferred from VIDEOCODECS, or '' for CPU."""
    vc = (factory.get("VIDEOCODECS") or "").strip().lower()
    if any(x in vc for x in ("h264_nvenc", "hevc_nvenc", "nvenc")):
        return "NVENC"
    if any(x in vc for x in ("h264_qsv", "hevc_qsv", "qsv")):
        return "Intel QSV"
    if any(x in vc for x in ("h264_vaapi", "hevc_vaapi", "vaapi")):
        return "VAAPI"
    if any(x in vc for x in ("h264_amf", "hevc_amf", "amf")):
        return "AMD AMF"
    if "cuda" in vc:
        return "CUDA"
    return ""


def run_ffmpeg(core: FreeFactoryCore, input_file: Path, factory_data: Dict[str, str], preview: bool=False) -> int:
    cmd = core.build_ffmpeg_command(input_file, factory_data, preview=preview)
    cmd = [str(x) for x in cmd]

    # Make sure ffmpeg won't read from stdin (prevents shell lockups)
    try:
        idx = cmd.index("ffmpeg")
        if "-nostdin" not in cmd:
            cmd.insert(idx + 1, "-nostdin")
    except ValueError:
        if "-nostdin" not in cmd:
            cmd.insert(0, "-nostdin")

    log_dir = ensure_log_dir()
    log_path = build_log_path(log_dir, input_file)

    with log_path.open("a", encoding="utf-8") as lf:
        lf.write(f"\n==== {datetime.now().isoformat()} ====\n")
        lf.write("CMD: " + " ".join(cmd) + "\n\n")
        lf.flush()
        proc = subprocess.Popen(
            cmd,
            stdin=subprocess.DEVNULL,           # key: don't let ffmpeg read our TTY
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )
        try:
            assert proc.stdout is not None
            for line in proc.stdout:
                lf.write(line)
        finally:
            proc.wait()
            lf.write(f"\n[exit_code] {proc.returncode}\n")
            lf.flush()
    return proc.returncode


def process_file(core: FreeFactoryCore, input_file: Path, factory_data: Dict[str, str]):
    rc = run_ffmpeg(core, input_file, factory_data, preview=False)

    # Delete conversion logs on success if requested
    if rc == 0 and _as_bool(factory_data.get("DELETECONVERSIONLOGS")):
        try:
            log_dir = ensure_log_dir()
            build_log_path(log_dir, input_file).unlink(missing_ok=True)
        except Exception:
            pass

    # Delete source on success if requested
    if rc == 0 and _as_bool(factory_data.get("DELETESOURCE")):
        try:
            input_file.unlink(missing_ok=True)
        except Exception:
            pass

    # --- add these status lines ---
    if rc == 0:
        print(f"[OK]   {input_file.name}")
    else:
        log_dir = ensure_log_dir()
        log_path = build_log_path(log_dir, input_file)
        print(f"[FAIL {rc}] {input_file.name}  (see {log_path})")

    return input_file, rc




def scan_candidates(notify_dir: Path) -> List[Path]:
    if not notify_dir.exists():
        return []
    return [p for p in notify_dir.iterdir() if p.is_file()]


class Sig(NamedTuple):
    dev: int
    ino: int
    mtime_ns: int
    size: int


def file_sig(p: Path) -> Sig:
    st = p.stat()
    return Sig(st.st_dev, st.st_ino, st.st_mtime_ns, st.st_size)


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="FreeFactory Conversion Service (Python)")
    parser.add_argument("--factory", help="Factory filename (e.g., MyFactory)")

    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--once", action="store_true", help="Process current files and exit")
    mode.add_argument("--watch", action="store_true", help="Watch the notify directory and process continuously")
    mode.add_argument("--daemon", action="store_true", help="Run in event-triggered mode (one file, one conversion)")

    parser.add_argument("--sourcepath", help="Path to directory containing the input file (for daemon mode)")
    parser.add_argument("--filename", help="Name of the file to process (for daemon mode)")
    parser.add_argument("--notify-event", help="Inotify event type (optional)")

    parser.add_argument("--max-workers", type=int, default=None, help="Override global concurrency limit")
    parser.add_argument("--poll-interval", type=float, default=2.0, help="Seconds between scans in watch mode")
    args = parser.parse_args(argv)

    cfg = ConfigManager()

    if args.daemon:
        # --- Daemon Mode ---
        if not args.sourcepath or not args.filename:
            print("ERROR: --sourcepath and --filename are required in --daemon mode", file=sys.stderr)
            return 2

        input_file = Path(args.sourcepath) / args.filename

        if not input_file.exists():
            print(f"ERROR: Input file does not exist: {input_file}", file=sys.stderr)
            return 2

        factory_dir = Path(cfg.get("FactoryLocation") or "/opt/FreeFactory/Factories")
        source_dir = Path(args.sourcepath).resolve()

        # Determine which factory to use
        if args.factory:
            factory_path = factory_dir / args.factory
            factory_data = read_factory(factory_path)
        else:
            # Try to auto-discover factory by matching NOTIFYDIRECTORY
            matches: List[Path] = []
            for fpath in factory_dir.iterdir():
                if not fpath.is_file():
                    continue
                try:
                    fdata = read_factory(fpath)
                    notify = fdata.get("NOTIFYDIRECTORY", "").strip()
                    if notify:
                        npath = Path(notify).expanduser().resolve()
                        print(f"[debug] Checking {fpath.name} -> NOTIFYDIRECTORY={npath} vs source={source_dir}")
                        if npath.as_posix() == source_dir.as_posix():
                            matches.append(fpath)
                except Exception:
                    continue

            if len(matches) == 0:
                print(f"ERROR: No factory matches notify path: {source_dir}", file=sys.stderr)
                return 2
            elif len(matches) > 1:
                print(f"ERROR: Multiple factories match notify path: {source_dir}", file=sys.stderr)
                for m in matches:
                    print(f" - {m.name}", file=sys.stderr)
                return 2
            else:
                factory_path = matches[0]
                factory_data = read_factory(factory_path)
                print(f"[daemon] Matched factory: {factory_path.name}")

        if not _as_bool(factory_data.get("ENABLEFACTORY")):
            print(f"[FreeFactoryConversion.py] Factory is DISABLED: {factory_path.name}")
            return 0

        core = FreeFactoryCore(cfg)
        process_file(core, input_file, factory_data)
        return 0


    notify_raw = (factory_data.get("NOTIFYDIRECTORY") or "").strip()
    if not notify_raw:
        print("This factory has no NOTIFYDIRECTORY set.", file=sys.stderr)
        return 2
    notify_dir = Path(notify_raw).expanduser()

    # Determine encoder/accel and pick concurrency
    accel = _which_accel(factory_data)

    if args.max_workers is not None:
        max_workers = args.max_workers
        override_note = " (override via --max-workers)"
    else:
        cfg_cpu = cfg.get("MaxConcurrentJobsCPU")
        cfg_gpu = cfg.get("MaxConcurrentJobsGPU")
        cfg_legacy = cfg.get("MaxConcurrentJobs")

        if accel:  # GPU path
            chosen = cfg_gpu or cfg_legacy
        else:      # CPU path
            chosen = cfg_cpu or cfg_legacy

        try:
            max_workers = int(chosen) if chosen else 1
        except Exception:
            max_workers = 1
        override_note = ""

    # Friendly banner lines
    if accel:
        print(f"[FreeFactoryConversion.py] Concurrency mode: GPU {max_workers} worker(s) [{accel}]{override_note}")
    else:
        print(f"[FreeFactoryConversion.py] Concurrency mode: CPU {max_workers} worker(s){override_note}")

    print(f"[FreeFactoryConversion.py] Factory: {factory_path.name}")
    print(f"[FreeFactoryConversion.py] Notify dir: {notify_dir}")
    print(f"[FreeFactoryConversion.py] Max workers: {max_workers}")

    processed: Dict[Path, Sig] = {}

    def cycle_once() -> int:
        nonlocal processed

        # Drop stale entries
        for old in list(processed.keys()):
            if not old.exists():
                processed.pop(old, None)

        # Build batch for changed/new files
        batch = []
        for p in scan_candidates(notify_dir):
            try:
                sig = file_sig(p)
            except FileNotFoundError:
                continue
            if processed.get(p) != sig:
                batch.append((p, sig))

        # Filter out files that might still be "hot" (mtime too recent)
        batch = [(p, sig) for (p, sig) in batch if is_settled(p)]

        if not batch:
            return 0


        mode_hint = accel if accel else "CPU"
        print(f"Discovered {len(batch)} file(s). Starting conversions... [{mode_hint}]")
        with ThreadPoolExecutor(max_workers=max_workers) as pool:
            futures = {pool.submit(process_file, core, f, factory_data): (f, sig) for f, sig in batch}
            for fut in as_completed(futures):
                f, sig = futures[fut]
                try:
                    in_file, rc = fut.result()
                except Exception as e:
                    print(f"[EXC] {f.name}: {e}")
        return len(batch)

    if args.once:
        cycle_once()
        return 0

    try:
        while True:
            cycle_once()
            time.sleep(args.poll_interval)
    except KeyboardInterrupt:
        print("Shutting down...")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
