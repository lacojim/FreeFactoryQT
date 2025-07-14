![image](https://github.com/user-attachments/assets/9cca7be8-736b-4768-8cd6-79cbd008605a)

# FreeFactoryQT

<img width="1097" height="727" alt="image" src="https://github.com/user-attachments/assets/9b74883c-003e-4602-98d9-b483c5313336" />


### New - 2025-07-14
- Added Video Profile and Video Profile Level support to UI and FreeFactoryConversion.tcl. Be aware if using pix_fmt with these options can be very tricky. So turn it off first to verify Video Profile is working, then start figuring out the compatible pix_fmts that work if still needed.
- Bugfix. Video bitrate (-b:v) was not being included in the Direct Conversion Dropzone, Batch File encoding and Commandline Preview. This has been fixed. It was not broken in the FreeFactory service however as the Factories were both written and read correctly. This took a while for me to find because I use the FF service more than I do direct encoding. RC1 is broken, but fixed in RC2 if downloading. The new Profiles (baseline, main, etc) are not in RC2. Considered experimental for now but working if all settings (pix_fmt, profile, profile level) are agreeable with FFmpeg. If you experience failures, test by copying the Preview commandline into a shell. You need to change the GENERIC input and output files names as these are completely generic.
- Added buttons for Import, Export and Backup Factories. Not yet functional but soon.

### New - 2025-06-26 
- Added support for live Streaming via the Stream Manager tab and freefactory-notify.service control within the UI.

FreeFactory is extremely useful for both casual users and professional broadcasters alike needing to convert media files. As a former Broadcast Engineer with 40 years of experience, I originally created this for inhouse use at the television station I worked for. It was written at first as a collection of BASH scripts, then converted to a TCL/TK app soon after by good friend Karl and it remained in that form for many years.

Taking advantage of the extremely powerful ffmpeg program, our aim is to make it user friendly. While ffmpeg is most likely the most flexible and powerful media conversion program in history, it is very difficult to use for most users. This program attempts to make it easy enough for the average user and powerful enough for professionals.

FreeFactory makes it extremely easy for users to share complex "Factories" with only minor modifications needed for general users. Usually only the Output Directory (and Notify Directory if using the freefactory-notify service) needs to be changed for the imported Factory to work as intended. 

FreeFactory is a long time project which went many years without any updates. While it originally supported both ffmpeg and ffmbc it is time to retire ffmbc support as that project has not been updated in many years, just as this one had not, until now. FFmpeg also supports most everything (if not all) that FFmbc once did.

FreeFactoryQT has been rewritten completely in Python3 (replacing TCL/TK) using a QT Frontend to create and maintain conversion Factories. It now also supports direct conversion within the GUI itself, both for single files and batch processing a list of files. The background daemon, FreeFactoryConversion.tcl is still in the process of being rewritten to Python3 and not yet ready. However, it is still 100% compatible with the new front end (with a few needed upgrades) and does not require any TK libraries. It's pure TCL. These are completely independent programs. Neither are required for the other to work. The only thing common between them is they both use the Factories folder to build a commandline for FFmpeg. While FreeFactoryQT will also be ported to Windows eventually, the FreeFactoryConversion service most likely will remain Linux only for many reasons. 

The power of the FreeFactory service is unprecedented in its ability to allow production houses and broadcasters alike to quickly and simply convert media files and deliver them simply by dropping the original files into a watched folder that has a "Factory" assigned to it. Everything happens completely in the background. The Freefactory-Notify.service requires inotifywait to be installed on your system.

### Installation:
Requirements:
- Python3
- PyQT6
- inotifywait (if using the FreeFactory-Notify service)
- TCL (if using the FreeFactory-Notify service)

1. Create a folder in /opt called FreeFactory (it is case sensitive)
2. Decompress the contents of the .zip file into /opt/FreeFactory/
3. To launch: cd to /opt/FreeFactory/bin and then run python3 main.py
4. Optionally create a desktop icon

The modular design of FreeFactoryQT can easily allow integration of external programs such as demucs for audio stem separation and/or vocal removal for Karaoke fans. Also incorporating sox-dsd would allow for transcoding audio files to DSD, for audiophiles. 

While extremely complicated encoding command lines can far exceed default UI options, the great thing, you can enter those unique options in the "Manual Options" and save that as a factory, so you only need to set it once, and use it forever. 
Here is an example of a very complex "Manual Options" command:
```
-c:v mpeg2video -pix_fmt yuv422p -aspect 16:9 -intra_vlc 1 -b:v 50000000 -minrate 50000000 -maxrate 50000000 -bufsize 17825792 -rc_init_occupancy 17825792 -bf 2 -non_linear_quant 1 -color_primaries bt709 -color_trc bt709 -colorspace bt709 -seq_disp_ext 1 -video_format component -color_range 1 -chroma_sample_location topleft -signal_standard 4 -dc 8 -qmin 5 -qmax 23 -g 12 -field_order tt -top 1 -flags +ildct+ilme -alternate_scan 1 -c:a pcm_s24le -ar:a 48000
```
The "Manual Options" would most likely never be used for home or general use, but only an example for a professional broadcast playback system. This may be expanded in the future by adding Manual Options for both Input and Output as we are starting to possibly see a need for this.

![image](https://github.com/user-attachments/assets/67483fc7-79f5-4d83-a304-c558422ec186)


![image](https://github.com/user-attachments/assets/890e97ae-b5d3-4050-93a2-8c4c16d7d3dd)



![image](https://github.com/user-attachments/assets/f0b33da3-b1b8-42eb-857f-4ee838b8ae18)

### Setting up FreeFactory service:

This requires TCL be installed on your system until this gets ported to Python3.

Simply run the script setup-notifyservice.sh.

```
$ ./setup-notifyservice.sh 
🔧 FreeFactory Notify Service Setup
----------------------------------
🔍 Checking if the service is currently running...
✅ Service is not currently running.

📂 Installed in USER mode

Choose an action:
1) Install/enable in USER mode
2) Install/enable in SYSTEM-WIDE mode (requires sudo)
3) Uninstall from USER mode
4) Uninstall from SYSTEM-WIDE mode
5) Quit
Selection:
```

Unless you are running the FreeFactory service for a company environment, you will want to select USER mode.

Once setup, you can run:
```
systemctl --user start freefactory-notify
```
and
```
systemctl --user enable freefactory-notify
```
to start whenever the user logs in.

You can also start and stop the service from within the FreeFactoryQT user interface.


### To-Do list:
- Dynamic UI: Presets, audio options, pix_fmt, etc will only show items that are compatible with the selected video or audio codec completely eliminating impossible options. 

- Batch processing with different factories. This would allow dropping a file with a factory selected, switching the factory then adding more files. The factory gets attached to each job. Then all files could convert using a different factory.

- Rewrite FreeFactoryConversion.tcl in Python3 (in progress, but the TCL program does work fine for now).

- Port FreeFactoryQT to Windows. I do not own a Windows PC nor have I ever so this may be difficult. 

