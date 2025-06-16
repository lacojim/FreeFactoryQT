FreeFactory is a long time project that went many years without any updates. While it originally supported both ffmpeg and ffmbc it is time to retire ffmbc support as that project has not been updated in many years, as this one had, until now. FFmpeg also now supports most everything (if not all) that FFmbc once did.

FreeFactoryQT has been rewritten completely in Python3 using a QT Frontend to create and maintain conversion Factories. It now also supports direct converstion within the GUI itself, both for single files and batch processing a list of files.

It now uses Systemd and the background notification monitoring is now a service instead of a simple command in rc.local. This is also now optional. The background daemon is still being rewritten at this time but the old tcl daemon still works with the new python fronend.

As a stand-alone conversion program, you only need some of the contents o the /bin folder:
freefactory-notify.service
droptextedit.py
core.py
config_manager.py
LICENSE.txt
main.py
FreeFactory-tabs.ui

Create a folder in /opt called FreeFactory and create a /bin folder inside that. Copy all these files into it.

You need to have ffmpeg installed in /usr/bin/

For now, start it using python3 main.py. This will change soon.

![image](https://github.com/user-attachments/assets/d3b490a0-f5b9-47ec-930c-caa274dfe101)

![image](https://github.com/user-attachments/assets/a1866f6b-c9ac-4064-bb48-d623b3cf3474)
