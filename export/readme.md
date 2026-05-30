# FreeFactory Export Folder

This folder contains documentation related to FreeFactory export operations.

## Source Installations

When FreeFactory is installed from a ZIP archive or GitHub checkout, users may choose to export files into this directory if desired.

## RPM / Package Installations

When FreeFactory is installed from an RPM package, Flatpak, or other system package manager, this directory is installed under:

```
/opt/FreeFactory/export
```

and is owned by the system package. It should be considered read-only.

Users should not save exported files into this location.

Instead, exports should be written to a user-owned directory such as:

```
~/Documents/FreeFactory
~/Videos
~/.local/share/FreeFactory/export
```

or another location of their choosing.

## Why?

Modern Linux packaging standards separate:

* Application files (installed by the package manager)
* User configuration files
* User-generated data

This allows FreeFactory to be safely updated without overwriting user files and ensures proper operation on multi-user systems.

