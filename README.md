# FreeFactoryQT

![image](https://github.com/user-attachments/assets/d3b490a0-f5b9-47ec-930c-caa274dfe101)

FreeFactory is a long time project that went many years without any updates. While it originally supported both ffmpeg and ffmbc it is time to retire ffmbc support as that project has not been updated in many years, jsut as this one had not, until now. FFmpeg also now supports most everything (if not all) that FFmbc once did.

FreeFactoryQT has been rewritten completely in Python3 using a QT Frontend to create and maintain conversion Factories. It now also supports direct converstion within the GUI itself, both for single files and batch processing a list of files.

Now using Systemd, the background notification monitoring is a service instead of a simple script in rc.local. This is also now optional. The background daemon is still being rewritten at this time but the old tcl daemon still works with the new python fronend. The Freefactory-Notify.service requires inotifywait to be installed on your system.

As a stand-alone conversion program, you only need some of the contents o the /bin folder:
freefactory-notify.service
droptextedit.py
core.py
config_manager.py
LICENSE.txt
main.py
FreeFactory-tabs.ui

Create a folder in /opt called FreeFactory and create a /bin folder inside that. Copy all these files into it. You also need the Pics folder in the root of /opt/FreeFactory.

You need to have ffmpeg installed in /usr/bin/

For now, start it using:
```
python3 main.py
```



![image](https://github.com/user-attachments/assets/a1866f6b-c9ac-4064-bb48-d623b3cf3474)

![455338057-88e3e969-e527-43d4-bfa2-853e34817864](https://github.com/user-attachments/assets/f53171b2-3698-4b90-9612-33b637fba7b6)

