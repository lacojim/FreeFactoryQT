import configparser
from pathlib import Path

class CaseConfigParser(configparser.ConfigParser):
    def optionxform(self, optionstr):
        return optionstr  # <-- preserves original case

class ConfigManager:
    def __init__(self):
        self.config_path = Path.home() / ".freefactoryrc"
        self.config = CaseConfigParser()
        self.defaults = {
            "CompanyNameGlobal": "ACME Broadcasting",
            "FactoryLocation": "/opt/FreeFactory/Factories",
            "DefaultFactory": "",
            "MaxConcurrentJobsCPU": "1",
            "MaxConcurrentJobsGPU": "1",
            "MaxConcurrentJobs": "0", # 0 = unlimited
            "AppleDelaySeconds": "30",
            "PathtoFFmpegGlobal": "/usr/bin/",
            "NotifyFolders": "/video/dropbox"
        }
        self.load()

    def load(self):
        self.config.read(self.config_path)
        if 'global' not in self.config:
            self.config['global'] = self.defaults.copy()

        # Ensure all expected keys exist
        for key, value in self.defaults.items():
            self.config['global'].setdefault(key, value)

    def save(self) -> None:
        """
        Save the current configuration to the .freefactoryrc file using 'key=value' format.
        Also removes deprecated keys to keep the file clean.
        """
        # Ensure the parent directory exists
        self.config_path.parent.mkdir(parents=True, exist_ok=True)

        # Purge deprecated keys
        deprecated_keys = [
            "SMTPServerGlobal",
            "SMTPPortGlobal",
            "EmailUsernameGlobal",
            "EmailPasswordGlobal",
            "EmailFromNameGlobal",
            "EmailFromAddressGlobal"
        ]
        for key in deprecated_keys:
            self.config["global"].pop(key, None)

        # Ensure required section exists
        if 'global' not in self.config:
            self.config['global'] = {}

        # Set defaults for missing keys (if any)
        for k, v in self.defaults.items():
            self.config['global'].setdefault(k, v)

        # Write config with no spaces around '='
        with self.config_path.open("w", encoding="utf-8") as f:
            self.config.write(f, space_around_delimiters=False)


    def get(self, key, default=""):
        return self.config.get("global", key, fallback=default)

    def set(self, key, value):
        self.config['global'][key] = str(value).strip()
        
    # Handle Notify Folders
    def get_notify_folders(self) -> list[str]:
        raw = (self.get("NotifyFolders", "") or "").strip()
        if not raw:
            return []
        # Allow either ; or newlines as separators
        parts = [p.strip() for p in raw.replace("\n", ";").split(";") if p.strip()]
        return parts

    def set_notify_folders(self, folders: list[str]):
        # store semicolon-separated for simplicity/compat
        self.set("NotifyFolders", ";".join(folders))
