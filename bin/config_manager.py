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
            "DefaultFactory": "",
            "AppleDelaySeconds": "30",
            "PathtoFFmpegGlobal": "/usr/bin/",
            "SMTPServerGlobal": "",
            "SMTPPortGlobal": "25",
            "EmailUsernameGlobal": "",
            "EmailPasswordGlobal": "",
            "EmailFromNameGlobal": "",
            "EmailFromAddressGlobal": ""
        }
        self.load()

    def load(self):
        self.config.read(self.config_path)
        if 'global' not in self.config:
            self.config['global'] = self.defaults.copy()

        # Ensure all expected keys exist
        for key, value in self.defaults.items():
            self.config['global'].setdefault(key, value)

    def save(self):
        with self.config_path.open("w") as f:
            self.config.write(f)

    def get(self, key):
        return self.config['global'].get(key, self.defaults.get(key, ""))

    def set(self, key, value):
        self.config['global'][key] = str(value).strip()
