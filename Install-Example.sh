#!/bin/sh
################################################################################################
#               This code is licensed under the GPLv2
#              Copyright 2005-2007 Tux Technology, LLC
#                               by
#                          Karl Swisher
#
#                          Install.sh
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# Program:Install.sh
#
# The first installer script for PgTCLScales.  This is a sh shell script
# and calls a tcl/tk gui install script at the end of this one called
# Install.tcl
#
################################################################################################

############################################################################################################################
############################################################################################################################
############################################################################################################################
############################################################################################################################
############################################################################################################################
############################################################################################################################
#
# What might be used in an install script to install tcl, tk and the Iwidgets packages.
#

# Check for TCL If it doesn't exist then get it
echo "Start Of Install Log For Free Factory v1.00.00" > Install.log
echo "Will you use [(1)] apt-get or (2) yum ?"; read PackageInstaller
if [ "$PackageInstaller" != "2" ]; then
	PackageInstaller=1
fi
echo "Checking for TCL" >> Install.log
echo "Checking for TCL"
if [ -f /usr/bin/tcl ] || [ -f /usr/bin/tclsh ]; then
	echo "Found TCL..."
	echo "Found TCL" >> Install.log
else
# If not installed then get it with yum
	echo "Downloading and intalling TCL and development..." >> Install.log
	echo "Downloading and intalling TCL and development..."
	if [ $PackageInstaller = 2 ]; then
		yum install tcl tcl-devel >> Install.log
	fi
	if [ $PackageInstaller = 1 ]; then
		apt-get install tcl tcl-devel >> Install.log
	fi
	if [ -f /usr/bin/tcl ] || [ -f /usr/bin/tclsh ]; then
		echo "Sucessful install of TCL..."
		echo "Sucessful install of TCL" >> Install.log
	else
		echo "TCL was not downloaded and/or installed must exit install"
		echo "TCL was not downloaded and/or installed must exit install..." >> Install.log
		exit
        fi
fi
# Check for TK If it doesn't exist then get it
echo ""
echo "Checking for TK" >> Install.log
echo "Checking for TK"
if [ -f /usr/bin/wish ]; then
	echo "Found TK" >> Install.log
	echo "Found TK..."
else
# If not installed then get it with yum
	echo "Downloading and intalling TK and development" >> Install.log
	echo "Downloading and intalling TK and development ..."
# If RH/Fedora distro
	if [ $PackageInstaller = 2 ]; then
		yum install tk tk-devel >> Install.log
	fi
# If Ubuntu distro
	if [ $PackageInstaller = 1 ]; then
		apt-get install tk tk-devel >> Install.log
	fi

	if [ -f /usr/bin/wish ]; then
		echo "Successful install of TK" >> Install.log
		echo "Successful install of TK..."
	else
		echo "TK was not downloaded and/or installed must exit install" >> Install.log
		echo "TK was not downloaded and/or installed must exit install..."
		exit
	fi
fi
# Check for Itcl If it doesn't exist then get it
echo ""
echo "Checking for Itcl" >> Install.log
echo "Checking for Itcl"
if [ -n "$(find /usr/lib -name itcl*)" ] || [ -n "$(find /usr/lib64 -name itcl*)" ]; then
	echo "Found Itcl" >> Install.log
	echo "Found Itcl..."
else
# If not installed then get it with yum or apt-get
	echo "Downloading and intalling Itcl" >> Install.log
	echo "Downloading and intalling Itcl ..."
	if [ $PackageInstaller = 2 ]; then
		yum install itcl
	fi
	if [ $PackageInstaller = 1 ]; then
		apt-get install itcl
	fi
	if [ -n "$(find /usr/lib -name itcl*)" ] || [ -n "$(find /usr/lib64 -name itcl*)" ]; then
		echo "Successful install of Itcl" >> Install.log
		echo "Successful install of Itcl..."
	else
		echo "Itcl was not downloaded and/or installed must exit install" >> Install.log
		echo "Itcl was not downloaded and/or installed must exit install..."
		exit
	fi
fi
# Check for tcllib If it doesn't exist then get it
echo ""
echo "Checking for tcllib" >> Install.log
echo "Checking for tcllib"
if [ -n "$(find /usr/lib -name tcllib*)" ] || [ -n "$(find /usr/lib64 -name tcllib*)" ]; then
	echo "Found tcllib" >> Install.log
	echo "Found tcllib..."
else
# If not installed then get it with yum or apt-get
	echo "Downloading and intalling tcllib" >> Install.log
	echo "Downloading and intalling tcllib ..."
	if [ $PackageInstaller = 2 ]; then
		yum install tcllib
	fi
	if [ $PackageInstaller = 1 ]; then
		apt-get install tcllib
	fi
	if [ -n "$(find /usr/lib -name tcllib*)" ] || [ -n "$(find /usr/lib64 -name tcllib*)" ]; then
		echo "Successful install of tcllib" >> Install.log
		echo "Successful install of tcllib..."
	else
		echo "tcllib was not downloaded and/or installed must exit install" >> Install.log
		echo "tcllib was not downloaded and/or installed must exit install..."
		exit
	fi
fi
# Check for Itk If it doesn't exist then get it
echo ""
echo "Checking for Itk" >> Install.log
echo "Checking for Itk"
if [ -n "$(find /usr/lib -name itk*)" ] || [ -n "$(find /usr/lib64 -name itk*)" ]; then
	echo "Found Itk" >> Install.log
	echo "Found Itk..."
else
# If not installed then get it with yum or apt-get
	echo "Downloading and intalling Itk" >> Install.log
	echo "Downloading and intalling Itk ..."
	if [ $PackageInstaller = 2 ]; then
		yum install itk
	fi
	if [ $PackageInstaller = 1 ]; then
		apt-get install itk
	fi
	if [ -n "$(find /usr/lib -name itk*)" ] || [ -n "$(find /usr/lib64 -name itk*)" ]; then
		echo "Successful install of Itk" >> Install.log
		echo "Successful install of Itk..."
	else
		echo "Itk was not downloaded and/or installed must exit install" >> Install.log
		echo "Itk was not downloaded and/or installed must exit install..."
		exit
	fi
fi
# Check for IWidgets If it doesn't exist then get it
echo ""
echo "Checking for IWidgets" >> Install.log
echo "Checking for IWidgets"
if [ -n "$(find /usr/share -name iwidgets*)" ]; then
	echo "Found IWidgets" >> Install.log
	echo "Found IWidgets..."
else
# If not installed then get it with yum or apt-get
	echo "Downloading and intalling IWidgets" >> Install.log
	echo "Downloading and intalling IWidgets ..."
	if [ $PackageInstaller = 2 ]; then
		yum install iwidgets
	fi
	if [ $PackageInstaller = 1 ]; then
		apt-get install iwidgets
	fi
	if [ -n "$(find /usr/share -name iwidgets*)" ]; then
		echo "Successful install of IWidgets" >> Install.log
		echo "Successful install of IWidgets..."
	else
		echo "IWidgets was not downloaded and/or installed must exit install" >> Install.log
		echo "IWidgets was not downloaded and/or installed must exit install..."
		exit
	fi
fi

#
# For right now we would not use below here
#
############################################################################################################################
############################################################################################################################
############################################################################################################################
############################################################################################################################
############################################################################################################################
############################################################################################################################
#
# Other Examples
#
echo ""
echo "Checking for Postgresql" >> Install.log
echo "Checking for Postgresql"
# Check to see if Postgresql is installed
if [ -f /var/lib/pgsql/data/PG_VERSION ]; then
	echo "Found Postgresql" >> Install.log
	echo "Found Postgresql...  Don't forget to configure Postgresql according to the INSTALL file"
else
# If not installed then get it with yum
	echo "Downloading and installing Postgresql" >> Install.log
	echo "Downloading and installing Postgresql...."
# If RH/Fedora distro
	if [ $PackageInstaller = 2 ]; then
		yum install postgresql >> Install.log
	fi
# If Ubuntu distro
	if [ $PackageInstaller = 1 ]; then
		apt-get install postgresql >> Install.log
	fi
	if [ -f /var/lib/pgsql/data/PG_VERSION ]; then
		echo "Successful install of Postgresql" >> Install.log
		echo "Successful install of Postgresql...  Don't forget to configure Postgresql according to the INSTALL file"
	else
		echo "Postgresql was not downloaded and/or installed must exit install" >> Install.log
		echo "Postgresql was not downloaded and/or installed must exit install..."
		exit
	fi
fi
echo ""
echo "Checking for Postgresql/TCL library" >> Install.log
echo "Checking for Postgresql/TCL library"
# Check for libpgtcl if not there then get it
if [ -n "$(find /usr/lib -name Pgtcl*)" ] || [ -n "$(find /usr/lib64 -name Pgtcl*)" ]; then
	echo "Found Postgresql/TCL library" >> Install.log
	echo "Found Postgresql/TCL library..."
else
# If not installed then get it with yum
	echo "Downloading and installing Postgresql/TCL library" >> Install.log
	echo "Downloading and installing Postgresql/TCL library...."
# If RH/Fedora distro
	if [ $PackageInstaller = 2 ]; then
		yum install postgresql-tcl >> Install.log
	fi
# If Ubuntu distro
	if [ $PackageInstaller = 1 ]; then
		apt-get install postgresql-tcl >> Install.log
	fi
	if [ -n "$(find /usr/lib -name Pgtcl*)" ] || [ -n "$(find /usr/lib64 -name Pgtcl*)" ]; then
		echo "Successful install of Postgresql/TCL library" >> Install.log
		echo "Successful install of Postgresql/TCL library..."
	else
		echo "Postgresql/TCL library was not downloaded and/or installed must exit install" >> Install.log
		echo "Postgresql/TCL library was not downloaded and/or installed must exit install..."
		exit		
	fi
fi
# Check for Expect If it doesn't exist then get it
echo ""
echo "Checking for Expect" >> Install.log
echo "Checking for Expect"
if [ -n "$(find /usr/lib -name libexpect*)" ] || [ -n "$(find /usr/lib64 -name libexpect*)" ]; then
	echo "Found Expect" >> Install.log
	echo "Found Expect..."
else
# If not installed then get it with yum or apt-get
	echo "Downloading and intalling Expect" >> Install.log
	echo "Downloading and intalling Expect ..."
	if [ $PackageInstaller = 2 ]; then
		yum install expect
	fi
	if [ $PackageInstaller = 1 ]; then
		apt-get install expect
	fi
	if [ -n "$(find /usr/lib -name libexpect*)" ] || [ -n "$(find /usr/lib64 -name libexpect*)" ]; then
		echo "Successful install of Expect" >> Install.log
		echo "Successful install of Expect..."
	else
		echo "Expect was not downloaded and/or installed must exit install" >> Install.log
		echo "Expect was not downloaded and/or installed must exit install..."
		exit
	fi
fi
# Check for TclX If it doesn't exist then get it
echo ""
echo "Checking for TclX" >> Install.log
echo "Checking for TclX"

if [ -n "$(find /usr/lib -name tclx*)" ] || [ -n "$(find /usr/lib64 -name tclx*)" ]; then
	echo "Found TclX" >> Install.log
	echo "Found TclX..."
else
# If not installed then get it with yum or apt-get
	echo "Downloading and intalling TclX" >> Install.log
	echo "Downloading and intalling TclX ..."
	if [ $PackageInstaller = 2 ]; then
		yum install tclx
	fi
	if [ $PackageInstaller = 1 ]; then
		apt-get install tclx
	fi
	if [ -n "$(find /usr/lib -name tclx*)" ] || [ -n "$(find /usr/lib64 -name tclx*)" ]; then
		echo "Successful install of TclX" >> Install.log
		echo "Successful install of TclX..."
	else
		echo "TclX was not downloaded and/or installed must exit install" >> Install.log
		echo "TclX was not downloaded and/or installed must exit install..."
		exit
	fi
fi

# Check for VUWidgets If it doesn't exist then get it
echo ""
echo "Checking for VUWidgets" >> Install.log
echo "Checking for VUWidgets"
if [ -n "$(find /usr/lib -name vu2*)" ] || [ -n "$(find /usr/lib64 -name vu2*)" ]; then
	echo "Found VUWidgets" >> Install.log
	echo "Found VUWidgets..."
else
# If not installed then get it with yum or apt-get
	echo "Downloading and intalling VUWidgets" >> Install.log
	echo "Downloading and intalling VUWidgets ..."
	if [ $PackageInstaller = 2 ]; then
		yum install vuwidgets
	fi
	if [ $PackageInstaller = 1 ]; then
		apt-get install vuwidgets
	fi
	if [ -n "$(find /usr/lib -name vu2*)" ] || [ -n "$(find /usr/lib64 -name vu2*)" ]; then
		echo "Successful install of VUWidgets" >> Install.log
		echo "Successful install of VUWidgets..."
	else
		echo "VUWidgets was not downloaded and/or installed, the install will still continue" >> Install.log
		echo "VUWidgets was not downloaded and/or installed, the install will still continue..."
	fi
fi
# Checking for wget
echo ""
echo "Checking for wget..." >> Install.log
echo "Checking for wget..."
if [ -f /usr/bin/wget ]; then
	echo ""
	echo "Found wget" >> Install.log
	echo "Found wget..."
else
# If not installed then get it with yum or apt-get
	echo "Downloading and intalling wget" >> Install.log
	echo "Downloading and intalling wget..."
	if [ $PackageInstaller = 2 ]; then
		yum install wget >> Install.log
	fi
	if [ $PackageInstaller = 1 ]; then
		apt-get install wget >> Install.log
	fi
	if [ -f /usr/bin/wget ]; then
		echo "Successful install of wget" >> Install.log
		echo "Successful install of wget..."
	else
		echo "wget was not downloaded and/or installed, the install will still continue" >> Install.log
		echo "wget was not downloaded and/or installed, the install will still continue..."
	fi
fi
echo ""
echo "Please wait, starting graphical installation...." >> Install.log
echo "Please wait, starting graphical installation...."

#Run TCL GUI Install
./Install.tcl