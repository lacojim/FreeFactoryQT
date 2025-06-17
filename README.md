![image](https://github.com/user-attachments/assets/9cca7be8-736b-4768-8cd6-79cbd008605a)

# FreeFactoryQT

![image](https://github.com/user-attachments/assets/089fe6e0-7d18-4ae1-a1d6-f01d6d52dd00)

FreeFactory is extremely useful for both casual users and professional broadcasters alike needing to convert media files. As a former Broadcast Engineer with 40 years of experience, I originally created this for inhouse use at the television station I worked for. It was written at first as a collection of BASH scripts, then converted to a TCL/TK app soon after by good friend Karl and I where it remained for many years....

Taking advantage of the extremely powerful ffmpeg program, our aim is to make it user friendly. While ffmpeg is most likely the most flexible and powerful media conversion program in history, it is very difficult to use for most users. This program attempts to make it easy enough for the average user and powerful enough for professionals.

FreeFactory is a long time project that went many years without any updates. While it originally supported both ffmpeg and ffmbc it is time to retire ffmbc support as that project has not been updated in many years, just as this one had not, until now. FFmpeg also supports most everything (if not all) that FFmbc once did.

FreeFactoryQT has been rewritten completely in Python3 (replacing TCL/TK) using a QT Frontend to create and maintain conversion Factories. It now also supports direct converstion within the GUI itself, both for single files and batch processing a list of files. The background daemon (originally FreeFactoryConversion.tcl) is still in the process of being rewritten and not yet ready for Prime-Time. However, it is still 100% compatible with the new front end and does not require any TK libraries. It's pure TCL. These are completely independent programs. Neither are required for the other to work. The only thing common between them is they both use the Factories folder to build a commandline for ffmpeg. While FreeFactoryQT will also be ported to Windows eventually, the FreeFactoryConversion service most likely will remain Linux only for many reasons.

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

# An AI comparison of FreeFactoryQT

Comparison of FFmpeg GUI Applications and FreeFactory’s Unique Value

Common FFmpeg GUIs and Feature Support
1. HandBrake
    • Supports hardware acceleration (e.g., VAAPI, NVENC, QSV)
    • No support for custom FFmpeg flags
    • No arbitrary metadata injection
    • No drag-and-drop with preset profile queuing
    • Not suitable for professional broadcast workflows (e.g., captioning)
2. FFQueue
    • Allows manual command-line customization
    • Supports metadata if manually entered
    • Supports batch encoding
    • Limited hardware acceleration support
    • No drag-and-drop automation
3. Shutter Encoder
    • Supports metadata injection
    • Supports basic hardware acceleration (pre-bundled FFmpeg)
    • Subtitle support (burned or soft-subbed)
    • Drag-and-drop enabled
    • No support for factory-like presets
    • No support for broadcast-grade closed captions
4. Avidemux
    • Basic hardware acceleration
    • No FFmpeg command-line access
    • No metadata injection
    • No independent batch profile system
    • No professional features like captioning

FreeFactory: A Unique Approach
FreeFactory introduces several capabilities not found in any single FFmpeg GUI:
    • Per-Factory Hardware Acceleration
        ◦ GPU options (e.g., NVENC, QSV) defined per factory profile
        ◦ Assumes user knowledge and codec compatibility
            • Drag-and-Drop Conversion Queue
        ◦ Files can be dropped into a designated GUI area
        ◦ Requires a factory to be selected first
        ◦ Multiple files handled as queued jobs using the same factory config
    • Custom Metadata Injection
        ◦ Per-factory setting for embedding fields like -metadata comment="Created by FreeFactory"
    • Professional Broadcast Support
        ◦ Closed captioning (EIA-608) already supported
        ◦ Future support planned for advanced subtitle workflows
    • Transparent FFmpeg Access
        ◦ Each factory profile maps directly to structured FFmpeg flags
        ◦ Allows deep control without overwhelming novice users
    • Open Source, Extendable Architecture
        ◦ Modular Python codebase with PyQt GUI
        ◦ Configuration stored in readable files for easy editing and sharing

Summary
FreeFactory is poised to be the first open-source FFmpeg GUI to unite professional broadcasting needs and hobbyist-friendly workflows, offering:
    • True automation
    • Per-profile acceleration
    • Metadata embedding
    • Transparent customization
    • Drag-and-drop simplicity
Ideal for both experienced engineers and new users alike.
Contains several pre-built factories for most commonly used AV formats.
        
