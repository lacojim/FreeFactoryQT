![image](https://github.com/user-attachments/assets/9cca7be8-736b-4768-8cd6-79cbd008605a)

# FreeFactoryQT

![image](https://github.com/user-attachments/assets/bb583240-d3d9-4dc1-885b-aa1119428fde)


FreeFactory is extremely useful for both casual users and professional broadcasters alike needing to convert media files. As a former Broadcast Engineer with 40 years of experience, I originally created this for inhouse use at the television station I worked for. It was written at first as a collection of BASH scripts, then converted to a TCL/TK app soon after by good friend Karl and it remained in that form for many years....

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

The modular design of FreeFactoryQT can easily allow integration of external programs such as demucs for audio stem separation and/or vocal removal for Karaoke fans. Also incorporating sox-dsd would allow for transcoding audio files to DSD, for audiophiles. 

![image](https://github.com/user-attachments/assets/1d00dd88-7b60-48a7-9519-2e3ef100ddac)


![image](https://github.com/user-attachments/assets/56e8962a-9877-4658-94bc-874de6afdc4f)


![image](https://github.com/user-attachments/assets/529ee922-abc4-4549-a521-3d1913625f9e)

 
      
