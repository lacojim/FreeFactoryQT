FreeFactory is a long time project that went many years without any updates. While it originally supported both ffmpeg and ffmbc it is time to retire ffmbc support as that project has not been updated in many years, as this one had, until now. FFmpeg also now supports most everything (if not all) that FFmbc once did.

FreeFactoryQT has been rewritten completely in Python3 using a QT Frontend to create and maintain conversion Factories. It now also supports direct converstion within the GUI itself, both for single files and batch processing a list of files.

It now uses Systemd and the background notification monitoring is now a service instead of a simple command in rc.local. This is also now optional. The background daemon is still being rewritten at this time but the old tcl daemon still works with the new python fronend.
