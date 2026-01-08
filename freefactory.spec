Name:           FreeFactoryQT
Version:        1.1.37
Release:        10%{?dist}
Summary:        Professional drag-and-drop FFmpeg conversion system
Provides:       FreeFactoryQT
Provides:       FreeFactory
# Obsoletes:      FreeFactoryQT < %{version}
# Obsoletes:      FreeFactory < %{version}


License:        GPL-3.0-or-later
URL:            https://github.com/lacojim/FreeFactoryQT
Source0:        https://github.com/lacojim/FreeFactoryQT/archive/refs/tags/FreeFactoryQT-1.1.37.tar.gz

BuildArch:      noarch

Requires: python3
Requires: python3-pyqt6-base
Requires: ffmpeg
Requires: libX11
Requires: libxcb

BuildRequires: python3dist(setuptools)

%description
FreeFactoryQT is a professional cost-effective video conversion manager
built around FFmpeg. It provides drag-and-drop conversion factories, metadata
support, caption handling, and queue management. Designed for broadcast
engineers and media professionals who need power without the price tag. Also
extremely useful for A/V hobbists who need FFmpeg but do not want to learn the syntax.
FreeFactory makes it easy without sacrificing the powerful options.

%prep
%autosetup -n FreeFactoryQT-%{version}

%build
# No compilation needed; Python application
echo "Building FreeFactoryQT..."

%install
rm -rf %{buildroot}
install -d %{buildroot}/opt/FreeFactory
cp -r * %{buildroot}/opt/FreeFactory/

install -d %{buildroot}%{_bindir}
echo '#!/bin/bash' > %{buildroot}%{_bindir}/freefactoryqt
echo 'exec python3 /opt/FreeFactory/bin/main.py "$@"' >> %{buildroot}%{_bindir}/freefactoryqt
chmod 755 %{buildroot}%{_bindir}/freefactoryqt

install -d %{buildroot}%{_datadir}/applications
cat > %{buildroot}%{_datadir}/applications/freefactoryqt.desktop <<'EOF'
[Desktop Entry]
Name=FreeFactory
Exec=freefactoryqt
Icon=utilities-terminal
Type=Application
Categories=AudioVideo;Video;Utility;
Comment=Professional FFmpeg-based video conversion tool
EOF

%files
%license license.txt
%doc README.md
/opt/FreeFactory
%{_bindir}/freefactoryqt
%{_datadir}/applications/freefactoryqt.desktop

%changelog
* Tue Dec 16 2025 Jim Hines <lacojim@gmail.com> - 1.1.37-10
- Seventh RPM release for Fedora 41, 42 and 43
- Installs to /opt/FreeFactory
- Added desktop launcher and wrapper script
