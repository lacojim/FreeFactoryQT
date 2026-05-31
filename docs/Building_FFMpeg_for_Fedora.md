# To build your own version of FFMpeg on Fedora Linux from sourcecode that is very feature rich, just follow these instructions:

## ***Important:*** You may not distribute your own non-free binary builds of FFMpeg.

First, you will need to download the sourcecode for the latest FFMpeg. 

```
cd ~/Downloads
wget https://ffmpeg.org/releases/ffmpeg-8.1.1.tar.gz
```
Then extract the archive in a place you want to build it. 
```
tar -xf ffmpeg-8.1.1.tar.gz
cd ffmpeg-8.1.1
```

Building FFMpeg requires a ton of dependencies in the form of -devel packages. These will need to be installed before attempting to build ffmpeg with the following configure script. 

Install Dependencies:
```
sudo dnf install x264-devel x265-devel frei0r-devel ladspa-devel libaribcaption libaribcaption-devel libbs2b libbs2b-devel codec2-devel gsm gsm-devel ilbc-devel libjxl-devel libklvanc-devel libvpl-devel lame-devel opencore-amr openh264-devel libopenmpt-devel rav1e-devel snappy-devel svt-av1-libs svt-av1-devel tesseract tesseract-devel libv4l-devel vid.stab-devel vo-amrwbenc-devel xvidcore-devel zimg-devel zeromq-devel ocl-icd-devel libcdio-paranoia-devel nv-codec-headers lcms2-devel gnutls-devel libaom-devel lilv-devel libass-devel libbluray-devel libdav1d-devel libmodplug-devel libmysofa-devel amrnb-devel opencore-amr-devel openjpeg2-devel   librsvg2-devel pulseaudio-libs-devel opus-devel rubberband-devel sox-devel soxr-devel librsvg2-devel speex-devel libssh-devel srt-devel libtheora-devel twolame-devel libvpx-devel zvbi-devel openal-soft-devel libglvnd-devel libglvnd-core-devel vapoursynth-devel libgcrypt-devel pipewire-jack-audio-connection-kit-devel libdrm-devel vulkan-headers
```

Once the dependencies are installed it's time to configure ffmpeg for building.

Configure Options for Fedora 43:
```
./configure --extra-version="FreeFactoryQT Edition" --prefix=/usr/local --bindir=/usr/local/bin --datadir=/usr/local/share/ffmpeg --docdir=/usr/local/share/doc/ffmpeg --incdir=/usr/local/include/ffmpeg --libdir=/usr/local/lib64 --mandir=/usr/local/share/man --arch=x86_64 --extra-ldflags="-Wl,-rpath,/usr/local/lib64" --optflags='-O2 -flto=auto -ffat-lto-objects -fexceptions -g -grecord-gcc-switches -pipe -Wall -Wno-complain-wrong-lang -Werror=format-security -Wp,-U_FORTIFY_SOURCE,-D_FORTIFY_SOURCE=3 -Wp,-D_GLIBCXX_ASSERTIONS -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -fstack-protector-strong -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer' --extra-ldflags='-Wl,-z,relro -Wl,--as-needed -Wl,-z,now -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -Wl,--build-id=sha1 ' --extra-cflags=' -I/usr/include/rav1e' --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libvo-amrwbenc --enable-version3 --enable-bzlib --enable-fontconfig --enable-frei0r --enable-gcrypt --enable-gnutls --enable-ladspa --enable-lcms2 --enable-libaom --enable-libdav1d --enable-libass --enable-libbluray --enable-libbs2b --enable-libcodec2 --enable-libcdio --enable-libdrm --enable-libjack --enable-libjxl --enable-libfreetype --enable-libfribidi --enable-libgsm --enable-libharfbuzz --enable-libilbc --enable-libmp3lame --enable-libmysofa --enable-nvenc --enable-openal --enable-opencl --enable-opengl --enable-libopenh264 --enable-libopenjpeg --enable-libopenmpt --enable-libopus --enable-libpulse --enable-librsvg --enable-librav1e --enable-librubberband --enable-libsmbclient --enable-libsnappy --enable-libsoxr --enable-libspeex --enable-libsrt --enable-libssh --enable-libsvtav1 --enable-libtesseract --enable-libtheora --enable-libtwolame --enable-libvorbis --enable-libv4l2 --enable-libvidstab --enable-libvmaf --enable-vapoursynth --enable-libvpx --enable-libshaderc --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxvid --enable-libxml2 --enable-libzimg --enable-libzmq --enable-libzvbi --enable-lv2 --enable-avfilter --enable-libmodplug --enable-pthreads --disable-static --enable-shared --enable-gpl --disable-debug --disable-stripping --shlibdir=/usr/local/lib64 --enable-lto --enable-libvpl --enable-runtime-cpudetect --enable-libklvanc --enable-vulkan --enable-libaribcaption
```

Other Optional configure options:
--enable-libplacebo --enable-whisper --enable-chromaprint

Once configure has completed hopefully without errors, you can then build it.

```
make -jN ; make install
```
The -jN flag is how many CPU threads you want the compiler to use.

Good Luck!
