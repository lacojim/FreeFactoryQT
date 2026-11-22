# factory_operations.py
# 
#############################################################################
#               This code is licensed under the GPLv3
#    The following terms apply to all files associated with the software
#    unless explicitly disclaimed in individual files or parts of files.
#
#                          Free Factory
#
#                       Copyright 2013-2026
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
#############################################################################
#
# This file has been created to allow creating a new freefactory cli command. This will operate on already existing factories and does not allow the creation of new factorys.
# You still need to use FreeFactoryQt for building factories.
#
#
# So far implemented.
#
# list_factories()
# check_factory_integrity()
# check_notify_duplicates()
# backup_factories()
# export_factory
# import_factory
# run_factory

# Shared, GUI-independent operations for FreeFactory factory files.


import hashlib
import re
import shutil
import tempfile
import zipfile

from datetime import datetime
from pathlib import Path


def list_factories(factory_dir: str | Path) -> list[str]:
    """Return alphabetically sorted names of regular files in *factory_dir*.

    This mirrors FactoryTools.refresh_factory_list(): files are not filtered
    by extension. A missing or non-directory path raises NotADirectoryError.
    """
    directory = Path(factory_dir).expanduser()
    if not directory.is_dir():
        raise NotADirectoryError(f"Factory directory not found: {directory}")

    return [path.name for path in sorted(directory.iterdir()) if path.is_file()]


def _factory_type_entries(factory_dir: str | Path) -> list[tuple[str, str]]:
    """Read (filename, FACTORYTYPE) without modifying factory files."""
    directory = Path(factory_dir).expanduser()
    entries = []
    for name in list_factories(directory):
        kind = ""
        with (directory / name).open("r", encoding="utf-8", errors="ignore") as stream:
            for line in stream:
                stripped = line.strip()
                if not stripped or stripped.startswith("#"):
                    continue
                key, separator, value = line.partition("=")
                if separator and key.strip().upper() == "FACTORYTYPE":
                    kind = value.strip()
                    break
        entries.append((name, kind))
    return entries


def list_factory_types(factory_dir: str | Path) -> list[tuple[str, int]]:
    """Return discovered (type, count) pairs; empty type means undefined.

    Group type spellings case-insensitively, preserving the first spelling found.
    """
    counts = {}
    for _, kind in _factory_type_entries(factory_dir):
        folded = kind.casefold()
        if folded not in counts:
            counts[folded] = [kind, 0]
        counts[folded][1] += 1
    return sorted(((kind, count) for kind, count in counts.values()),
                  key=lambda item: (item[0] == "", item[0].casefold()))


def list_factories_by_type(
    factory_dir: str | Path,
    factory_type: str | None = None,
    sort_by: str = "name",
    include_type: bool = False,
) -> list[str] | list[tuple[str, str]]:
    """Filter/sort factory files by user-defined FACTORYTYPE.

    Default returns filenames as before; include_type returns (name, type) pairs.
    Type comparisons are case-insensitive. Missing types are empty strings.
    """
    if sort_by not in ("name", "type"):
        raise ValueError(f"Unsupported sort order: {sort_by}")
    if factory_type is None and sort_by == "name" and not include_type:
        return list_factories(factory_dir)

    entries = _factory_type_entries(factory_dir)
    if factory_type is not None:
        entries = [
            (name, kind) for name, kind in entries
            if kind.casefold() == factory_type.casefold()
            or (factory_type.casefold() == "undefined" and not kind)
        ]
    if sort_by == "type":
        entries.sort(key=lambda item: (item[1] == "", item[1].casefold(), item[0].casefold()))
    return entries if include_type else [name for name, _ in entries]


def check_factory_integrity(factory_dir: str | Path) -> list[str]:
    """
    Check factory files for basic formatting problems.

    Returns a list of human-readable issues.
    An empty list means no problems were detected.
    """
    factory_dir = Path(factory_dir).expanduser()

    if not factory_dir.is_dir():
        raise NotADirectoryError(
            f"Factory directory not found: {factory_dir}"
        )

    issues = []

    for factory_path in sorted(factory_dir.iterdir()):
        if not factory_path.is_file():
            continue

        with factory_path.open(
            "r", encoding="utf-8", errors="ignore"
        ) as f:
            for lineno, line in enumerate(f, start=1):
                stripped = line.strip()

                if not stripped or stripped.startswith("#"):
                    continue

                if "=" not in stripped:
                    issues.append(
                        f"{factory_path.name}, Line {lineno}: "
                        f"Missing '=' -> {stripped}"
                    )
                    continue

                key, value = map(
                    str.strip, stripped.split("=", 1)
                )

                if not key:
                    issues.append(
                        f"{factory_path.name}, Line {lineno}: "
                        f"Empty key before '=' -> {stripped}"
                    )
                elif " " in key:
                    issues.append(
                        f"{factory_path.name}, Line {lineno}: "
                        f"Key contains space -> {key}"
                    )

                if (
                    value.startswith('"')
                    and value.endswith('"')
                    and len(value) > 2
                ):
                    issues.append(
                        f"{factory_path.name}, Line {lineno}: "
                        f"Value appears to be quoted -> {value}"
                    )

    return issues



def check_notify_duplicates(factory_dir: str | Path) -> dict[str, list[str]]:
    """
    Find factories sharing the same NOTIFYDIRECTORY.

    Returns a dictionary:
        {directory: [factory_name, ...]}

    Only directories used by multiple factories are returned.
    """
    factory_dir = Path(factory_dir).expanduser()

    if not factory_dir.is_dir():
        raise NotADirectoryError(
            f"Factory directory not found: {factory_dir}"
        )

    notify_map = {}

    for factory_path in sorted(factory_dir.iterdir()):
        if not factory_path.is_file():
            continue

        with factory_path.open("r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("NOTIFYDIRECTORY="):
                    directory = line.strip().split("=", 1)[1]

                    if directory:
                        notify_map.setdefault(
                            directory, []
                        ).append(factory_path.name)

                    break

    return {
        directory: factories
        for directory, factories in notify_map.items()
        if len(factories) > 1
    }



def backup_factories(factory_dir: str | Path, backup_path: str | Path) -> int:
    """
    Back up all regular factory files into a ZIP archive.

    Returns the number of factories backed up.
    Original factory files are never modified.
    """
    factory_dir = Path(factory_dir).expanduser()
    backup_path = Path(backup_path).expanduser()

    if not factory_dir.is_dir():
        raise NotADirectoryError(
            f"Factory directory not found: {factory_dir}"
        )

    # Match list_factories(): periods in factory names are valid.
    factory_files = sorted(
        path for path in factory_dir.iterdir()
        if path.is_file()
    )

    if not factory_files:
        raise ValueError(
            f"No factory files found in: {factory_dir}"
        )

    # Do not silently overwrite an existing backup.
    if backup_path.exists():
        raise FileExistsError(
            f"Backup already exists: {backup_path}"
        )

    # Create the ZIP archive.
    with zipfile.ZipFile(
        backup_path, "x", compression=zipfile.ZIP_DEFLATED
    ) as archive:
        for factory_path in factory_files:
            archive.write(
                factory_path,
                arcname=factory_path.name
            )

    return len(factory_files)


def export_factory(
    factory_path: str | Path | list[str | Path],
    export_dir: str | Path,
    as_zip: bool = False
) -> list[Path]:
    
    """Export one or more sanitized factories, optionally as ZIP."""
    export_dir = Path(export_dir).expanduser()

    if not export_dir.is_dir():
        raise NotADirectoryError(export_dir)

    if isinstance(factory_path, (str, Path)):
        factory_paths = [Path(factory_path).expanduser()]
    else:
        factory_paths = [
            Path(p).expanduser() for p in factory_path
        ]

    if not factory_paths:
        raise ValueError("No factories selected for export")

    for path in factory_paths:
        if not path.is_file():
            raise FileNotFoundError(path)

    always_blank = {
        "NOTIFYDIRECTORY", "OUTPUTDIRECTORY",
        "STREAMRTMPURL", "STREAMKEY",
        "FACTORYEMAILMESSAGESTART", "FACTORYEMAILMESSAGEEND",
        "FACTORYLINKS", "FTPPROGRAM", "FTPURL",
        "FTPUSERNAME", "FTPPASSWORD", "FTPREMOTEPATH",
        "FTPTRANSFERTYPE", "FTPDELETEAFTER",
        "PIX_FMT", "VIDEOTAGS", "AUDIOTAG",
    }

    pathish_keys = {
        "STREAMINPUTVIDEO", "STREAMINPUTAUDIO",
        "FORCEFORMATINPUTVIDEO", "FORCEFORMATINPUTAUDIO",
        "INPUTFILE", "INPUTVIDEOFILE", "INPUTAUDIOFILE",
        "VIDEOPATH", "AUDIOPATH",
    }

    def is_pathlike(value):
        s = value.strip()
        if not s or s.startswith(":"):
            return False
        if s in {"default", "pulse", "alsa", "jack"}:
            return False
        if s.startswith(("hw:", "jack:")):
            return False
        if "=" in s and s.split("=", 1)[0].isalnum():
            return False
        if s.lower().startswith((
            "rtsp://", "srt://", "udp://", "tcp://",
            "http://", "https://"
        )):
            return False
        return (
            s.startswith(("/", "./", "../", "~/"))
            or s.lower().startswith("file:")
            or bool(re.match(r"^[A-Za-z]:[\\/]", s))
            or "/" in s or "\\" in s
            or bool(re.search(r"\.[A-Za-z0-9]{2,4}$", s))
        )

    
    def clean_factory(factory_path):
        raw = factory_path.read_text(
            encoding="utf-8", errors="ignore"
        )
        lines = []

        for line in raw.splitlines(keepends=True):
            stripped = line.strip()

            if not stripped or stripped.startswith("#") or "=" not in stripped:
                lines.append(line)
                continue

            key, value = stripped.split("=", 1)
            key, value = key.strip(), value.strip()

            if key in always_blank:
                lines.append(f"{key}=\n")
            elif key in pathish_keys and is_pathlike(value):
                lines.append(f"{key}=/add/path/filename/here\n")
            else:
                lines.append(line)

        return "".join(lines)

    def unique_destination(path):
        if not path.exists():
            return path

        base = path.stem if path.suffix else path.name
        ext = path.suffix
        counter = 1

        while True:
            candidate = path.with_name(
                f"{base}-export-{counter}{ext}"
            )
            if not candidate.exists():
                return candidate
            counter += 1

    exported = []

    if as_zip:

        timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
        zip_path = unique_destination(
            export_dir / f"Factories-Export-{timestamp}.zip"
        )

        names_used = set()

        with zipfile.ZipFile(
            zip_path, "x", compression=zipfile.ZIP_DEFLATED
        ) as archive:
            for factory_path in factory_paths:
                name = factory_path.name
                counter = 1

                while name in names_used:
                    name = f"{factory_path.name}-export-{counter}"
                    counter += 1

                names_used.add(name)
                archive.writestr(
                    name, clean_factory(factory_path)
                )

        exported.append(zip_path)

    else:
        for factory_path in factory_paths:
            destination = unique_destination(
                export_dir / factory_path.name
            )

            with destination.open("x", encoding="utf-8") as f:
                f.write(clean_factory(factory_path))

            exported.append(destination)

    return exported



def _import_single_factory(
    source_path: str | Path,
    factory_dir: str | Path
) -> Path | None:
    """Import one factory, without overwriting an existing file."""

    source = Path(source_path).expanduser()
    factory_dir = Path(factory_dir).expanduser()

    if not source.is_file():
        raise FileNotFoundError(source)
    if not factory_dir.is_dir():
        raise NotADirectoryError(factory_dir)

    destination = factory_dir / source.name

    if destination.exists():

        def sha256(path):
            digest = hashlib.sha256()
            with path.open("rb") as f:
                for chunk in iter(lambda: f.read(1024 * 1024), b""):
                    digest.update(chunk)
            return digest.digest()

        if destination.is_file():
            if (source.stat().st_size == destination.stat().st_size
                    and sha256(source) == sha256(destination)):
                return None

        base = destination.stem if destination.suffix else destination.name
        extension = destination.suffix

        candidate = factory_dir / f"{base}-import{extension}"
        counter = 2

        while candidate.exists():
            if candidate.is_file():
                if (source.stat().st_size == candidate.stat().st_size
                        and sha256(source) == sha256(candidate)):
                    return None

            candidate = factory_dir / f"{base}-import-{counter}{extension}"
            counter += 1

        destination = candidate

    shutil.copy2(source, destination)
    return destination



def import_factory(
    source_paths: str | Path | list[str | Path],
    factory_dir: str | Path
) -> list[Path]:
    """Import factories from individual files or ZIP archives."""

    if isinstance(source_paths, (str, Path)):
        source_paths = [source_paths]

    imported = []

    for source in source_paths:
        source = Path(source).expanduser()

        if not source.is_file():
            raise FileNotFoundError(source)

        if not zipfile.is_zipfile(source):
            result = _import_single_factory(source, factory_dir)
            if result is not None:
                imported.append(result)
            continue

        with zipfile.ZipFile(source, "r") as archive:

            # Validate all member names before importing anything.
            for member in archive.infolist():
                if member.is_dir():
                    continue

                name = member.filename

                if (
                    not name
                    or name in (".", "..")
                    or "/" in name
                    or "\\" in name
                    or ":" in name
                ):
                    raise ValueError(
                        f"Unsafe ZIP member name: {name!r}"
                    )

            # All filenames passed validation.
            for member in archive.infolist():
                if member.is_dir():
                    continue

                name = member.filename

                with tempfile.TemporaryDirectory() as temp_dir:
                    temp_path = Path(temp_dir) / name

                    with archive.open(member) as src:
                        with temp_path.open("xb") as dst:
                            shutil.copyfileobj(src, dst)

                    result = _import_single_factory(
                        temp_path, factory_dir
                    )

                    if result is not None:
                        imported.append(result)

    return imported






































# ---------------------------------------------------------------------------
# Run an existing factory (CLI / FFTools shared operation)
# ---------------------------------------------------------------------------

def get_factory_directory() -> Path:
    """Resolve FactoryLocation using FreeFactory's existing configuration."""
    from config_manager import ConfigManager

    configured = ConfigManager().get("FactoryLocation") or "/opt/FreeFactory/Factories"
    directory = Path(configured).expanduser()
    if not directory.is_dir():
        raise NotADirectoryError(f"Factory directory not found: {directory}")
    return directory


def _numbered_output(path: Path) -> Path:
    """Find the first available name, preserving multi-dot stems."""
    if not path.exists():
        return path
    index = 1
    while True:
        candidate = path.with_name(f"{path.stem}-{index}{path.suffix}")
        if not candidate.exists():
            return candidate
        index += 1


def run_factory(
    factory_name: str,
    input_file: str | Path,
    output_dir: str | Path | None = None,
    *,
    overwrite: bool = False,
    ask: bool = False,
    no_overwrite: bool = False,
    factory_dir: str | Path | None = None,
    dry_run: bool = False,
) -> int | list[str]:
    """Run an existing single-output factory; return exit code or dry-run command.

    Default collision behavior: append -1, -2, etc. to the output stem.
    `overwrite` corresponds to CLI -y, `no_overwrite` to -n.
    `ask` requires an interactive terminal if the output exists.
    No factory file is changed. Multi-output and analysis-only jobs are
    deliberately rejected until their destinations can be handled safely.
    """
    import sys
    from config_manager import ConfigManager
    from core import FreeFactoryCore
    from FreeFactoryConversion import read_factory, acquire_concurrency_slot, _which_accel

    if sum(bool(x) for x in (overwrite, ask, no_overwrite)) > 1:
        raise ValueError("Choose only one of overwrite, ask, or no_overwrite")

    directory = Path(factory_dir).expanduser() if factory_dir is not None else get_factory_directory()
    if not directory.is_dir():
        raise NotADirectoryError(f"Factory directory not found: {directory}")
    if not factory_name or Path(factory_name).name != factory_name or factory_name in (".", ".."):
        raise ValueError("Factory must be a filename, not a path")
    factory_path = directory / factory_name
    if not factory_path.is_file():
        raise FileNotFoundError(f"Factory not found: {factory_path}")

    source = Path(input_file).expanduser().resolve()
    if not source.is_file():
        raise FileNotFoundError(f"Input file not found: {source}")

    factory_data = read_factory(factory_path)
    if str(factory_data.get("MULTIOUTPUT", "")).lower() in ("true", "yes", "1", "on"):
        raise NotImplementedError("run_factory does not yet support MULTIOUTPUT factories")
    if any(str(factory_data.get(k, "")).lower() in ("true", "yes", "1", "on")
           for k in ("SHOWAUDIOANALYSISREPORT", "SHOWVIDEOANALYSISREPORT")):
        raise NotImplementedError("run_factory does not yet support analysis report destinations")

    data = factory_data.copy()
    if output_dir is not None:
        target_dir = Path(output_dir).expanduser().resolve()
        if not target_dir.is_dir():
            raise NotADirectoryError(f"Output directory not found: {target_dir}")
        data["OUTPUTDIRECTORY"] = str(target_dir)
    else:
        target_dir = Path(data.get("OUTPUTDIRECTORY") or ".").expanduser().resolve()
        if not target_dir.is_dir():
            raise NotADirectoryError(f"Output directory not found: {target_dir}")
        data["OUTPUTDIRECTORY"] = str(target_dir)

    cfg = ConfigManager()
    core = FreeFactoryCore(cfg)
    cmd = [str(part) for part in core.build_ffmpeg_command(source, data)]
    if not cmd or cmd[-1] == "-" or cmd[-1].startswith("-"):
        raise ValueError("Factory did not produce a supported file destination")
    original = Path(cmd[-1])
    if original.parent.resolve() != target_dir:
        raise ValueError("Factory output destination does not match configured output directory")
    if original.resolve() == source:
        raise ValueError("Refusing to overwrite the input file")

    destination = original
    if destination.exists():
        if overwrite:
            pass
        elif no_overwrite:
            raise FileExistsError(f"Output already exists: {destination}")
        elif ask:
            if not sys.stdin.isatty():
                raise RuntimeError("--ask requires an interactive terminal")
            choice = input(f"Output exists: {destination}\nOverwrite? [y/N] ").strip().lower()
            if choice not in ("y", "yes"):
                destination = _numbered_output(destination)
        else:
            destination = _numbered_output(destination)

    cmd[-1] = str(destination)
    # core.py currently supplies -y by default; -n protects against races
    # and accidental overwrites unless the user explicitly requested -y.
    cmd = [part for part in cmd if part not in ("-y", "-n")]
    cmd.insert(1, "-y" if overwrite or (ask and destination == original) else "-n")
    if "-nostdin" not in cmd:
        cmd.insert(2, "-nostdin")

    if dry_run:
        return cmd

    # Use the existing service's execution/logging path, but avoid rebuilding
    # the command (which would lose the collision-safe destination).
    import subprocess
    from FreeFactoryConversion import ensure_log_dir, build_log_path, factory_provenance
    from datetime import datetime as _datetime
    from shlex import join as shell_join

    with acquire_concurrency_slot(bool(_which_accel(data)), cfg):
        log_path = build_log_path(ensure_log_dir(), source)
        with log_path.open("a", encoding="utf-8") as log:
            log.write(f"\n==== {_datetime.now().isoformat()} ====\n")
            log.writelines(factory_provenance(factory_path))
            log.write("CMD: " + shell_join(cmd) + "\n\n")
            log.flush()
            with subprocess.Popen(cmd, stdin=subprocess.DEVNULL,
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                  text=True, bufsize=1) as process:
                for line in process.stdout:
                    log.write(line)
                rc = process.wait()
            log.write(f"\n[exit_code] {rc}\n")
        return rc
