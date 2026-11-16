# So far implemented.
#
# list_factories()
# check_factory_integrity()
# check_notify_duplicates()
# backup_factories()
# export_factory
# import_factory
#

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
    Back up all extensionless factory files into a ZIP archive.

    Returns the number of factories backed up.
    Original factory files are never modified.
    """
    factory_dir = Path(factory_dir).expanduser()
    backup_path = Path(backup_path).expanduser()

    if not factory_dir.is_dir():
        raise NotADirectoryError(
            f"Factory directory not found: {factory_dir}"
        )

    # Factory files have no extension.
    factory_files = sorted(
        path for path in factory_dir.iterdir()
        if path.is_file() and not path.suffix
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





































