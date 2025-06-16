#!/bin/sh
# the next line restarts using wish\
 exec wish "$0" "$@"
#############################################################################
#               This code is licensed under the GPLv3
#    The following terms apply to all files associated with the software
#    unless explicitly disclaimed in individual files or parts of files.
#
#                           Free Factory
#
#                          Copyright 2013
#                               by
#                     Jim Hines and Karl Swisher
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Program:FreeFactory.tcl
#
# This is the executable program that starts Free Fractory
#############################################################################
if {![info exists vTcl(sourcing)]} {

# Provoke name search
    catch {package require bogus-package-name}
    set packageNames [package names]
# Needs Tk
    package require Tk
# Needs Itcl
    package require Itcl
# Needs Itk
    package require Itk
# Needs Iwidgets
    package require Iwidgets

    switch $tcl_platform(platform) {
	windows {
            option add *Button.padY 0
	}
	default {
            option add *Scrollbar.width 10
            option add *Scrollbar.highlightThickness 0
            option add *fScrollbar.elementBorderWidth 2
            option add *Scrollbar.borderWidth 2
	}
    }

    switch $tcl_platform(platform) {
	windows {
            option add *Pushbutton.padY         0
	}
	default {
	    option add *Scrolledhtml.sbWidth    10
	    option add *Scrolledtext.sbWidth    10
	    option add *Scrolledlistbox.sbWidth 10
	    option add *Scrolledframe.sbWidth   10
	    option add *Hierarchy.sbWidth       10
            option add *Pushbutton.padY         2
        }
    }

}

#############################################################################
## vTcl Code to Load Stock Images


if {![info exist vTcl(sourcing)]} {
#############################################################################
## Procedure:  vTcl:rename

	proc ::vTcl:rename {name} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their 7 agreements for details.
		regsub -all "\\." $name "_" ret
		regsub -all "\\-" $ret "_" ret
		regsub -all " " $ret "_" ret
		regsub -all "/" $ret "__" ret
		regsub -all "::" $ret "__" ret
		return [string tolower $ret]
	}
}
#############################################################################
## Procedure:  vTcl:image:create_new_image

proc ::vTcl:image:create_new_image {filename {description {no description}} {type {}} {data {}}} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.

# Does the image already exist?
    	if {[info exists ::vTcl(images,files)]} {
        	if {[lsearch -exact $::vTcl(images,files) $filename] > -1} { return }
	}

	if {![info exists ::vTcl(sourcing)] && [string length $data] > 0} {
		set object [image create  [vTcl:image:get_creation_type $filename]  -data $data]
	} else {
# Wait a minute... Does the file actually exist?
		if {! [file exists $filename] } {
# Try current directory
			set script [file dirname [info script]]
			set filename [file join $script [file tail $filename] ]
		}
		if {![file exists $filename]} {
			set description "file not found!"
## will add 'broken image' again when img is fixed, for now create empty
			set object [image create photo -width 1 -height 1]
		} else {
			set object [image create  [vTcl:image:get_creation_type $filename]  -file $filename]
		}
	}
	set reference [vTcl:rename $filename]
	set ::vTcl(images,$reference,image)       $object
	set ::vTcl(images,$reference,description) $description
	set ::vTcl(images,$reference,type)        $type
	set ::vTcl(images,filename,$object)       $filename
	lappend ::vTcl(images,files) $filename
	lappend ::vTcl(images,$type) $object

# return image name in case caller might want it
    	return $object
}
#############################################################################
## Procedure:  vTcl:image:get_image
proc ::vTcl:image:get_image {filename} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.

    set reference [vTcl:rename $filename]

# Let's do some checking first
    if {![info exists ::vTcl(images,$reference,image)]} {
# Well, the path may be wrong; in that case check
# only the filename instead, without the path.

        set imageTail [file tail $filename]

        foreach oneFile $::vTcl(images,files) {
            if {[file tail $oneFile] == $imageTail} {
                set reference [vTcl:rename $oneFile]
                break
            }
        }
    }
    return $::vTcl(images,$reference,image)
}
#############################################################################
## Procedure:  vTcl:image:get_creation_type

proc ::vTcl:image:get_creation_type {filename} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.

	switch [string tolower [file extension $filename]] {
		.ppm -
		.jpg -
		.bmp -
		.gif    {return photo}
		.xbm    {return bitmap}
		default {return photo}
	}
}

foreach img {} {
	eval set _file [lindex $img 0]
	vTcl:image:create_new_image $_file [lindex $img 1] [lindex $img 2] [lindex $img 3]
}
#############################################################################
## vTcl Code to Load User Images

catch {package require Img}
####################
# New Images
####################
####################

foreach img {
# Replace with your icon file names

	{{[file join / opt FreeFactory Pics Ksysguard-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics License32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics icon-printer32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics HPLaserJet32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Gtk_Save-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Log4-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics AddFactoryLink-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics AddEMailUser-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics RemoveFactoryLink-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics RemoveEMailUser-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Message-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics reload32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Exit-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Exit-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Document32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Help_Index3-2x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Gtk-stop32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics New-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics New.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Open-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Open-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics SaveAs-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics 3Floppy_Unmount-48x48.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics NFS_Mount-48x48.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics NFS_Mount_kde-48x48.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Gnome_Dev_Harddisk-48x48.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Remove-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Remove-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Show-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics show.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Cut-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics save.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Document-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Document-48x48.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Screen_Green-48x48.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Back-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics UpLevel-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Folder_Home-48x48.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Folder_New20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics folderButton.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics folder2.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics EditCopy-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Edit-Paste-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Tool-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Tool2-20x20.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics CDROM_Mount-48x48.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics Update-32x32.gif]} {user image} user {}}
	{{[file join / opt FreeFactory Pics PicNotAvailable.gif]} {user image} user {}}
	    } {
	eval set _file [lindex $img 0]
	vTcl:image:create_new_image $_file [lindex $img 1] [lindex $img 2] [lindex $img 3]
}
#################################
# VTCL LIBRARY PROCEDURES
#

if {![info exists vTcl(sourcing)]} {
#############################################################################
## Library Procedure:  Window

proc ::Window {args} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.
    global PPref
    global vTcl
    foreach {cmd name newname} [lrange $args 0 2] {}
    set rest    [lrange $args 3 end]
    if {$name == "" || $cmd == ""} { return }
    if {$newname == ""} { set newname $name }
    if {$name == "."} { wm withdraw $name; return }
    set exists [winfo exists $newname]
    switch $cmd {
        show {
            if {$exists} {
                wm deiconify $newname
            } elseif {[info procs vTclWindow$name] != ""} {
                eval "vTclWindow$name $newname $rest"
            }
            if {[winfo exists $newname] && [wm state $newname] == "normal"} {
                vTcl:FireEvent $newname <<Show>>
            }
        }
        hide    {
            if {$exists} {
                wm withdraw $newname
                vTcl:FireEvent $newname <<Hide>>
                return}
        }
        iconify { if $exists {wm iconify $newname; return} }
        destroy { if $exists {destroy $newname; return} }
    }
}
#############################################################################
## Library Procedure:  vTcl:DefineAlias

proc ::vTcl:DefineAlias {target alias widgetProc top_or_alias cmdalias} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.

    global widget
    set widget($alias) $target
    set widget(rev,$target) $alias
    if {$cmdalias} {
        interp alias {} $alias {} $widgetProc $target
    }
    if {$top_or_alias != ""} {
        set widget($top_or_alias,$alias) $target
        if {$cmdalias} {
            interp alias {} $top_or_alias.$alias {} $widgetProc $target
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:DoCmdOption

proc ::vTcl:DoCmdOption {target cmd} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.

## menus are considered toplevel windows
    set parent $target
    while {[winfo class $parent] == "Menu"} {
        set parent [winfo parent $parent]
    }

    regsub -all {\%widget} $cmd $target cmd
    regsub -all {\%top} $cmd [winfo toplevel $parent] cmd

    uplevel #0 [list eval $cmd]
}
#############################################################################
## Library Procedure:  vTcl:FireEvent

proc ::vTcl:FireEvent {target event {params {}}} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.

## The window may have disappeared
    if {![winfo exists $target]} return
## Process each binding tag, looking for the event
    foreach bindtag [bindtags $target] {
        set tag_events [bind $bindtag]
        set stop_processing 0
        foreach tag_event $tag_events {
            if {$tag_event == $event} {
                set bind_code [bind $bindtag $tag_event]
                foreach rep "\{%W $target\} $params" {
                    regsub -all [lindex $rep 0] $bind_code [lindex $rep 1] bind_code
                }
                set result [catch {uplevel #0 $bind_code} errortext]
                if {$result == 3} {
## break exception, stop processing
                    set stop_processing 1
                } elseif {$result != 0} {
                    bgerror $errortext
                }
                break
            }
        }
        if {$stop_processing} {break}
    }
}
#############################################################################
## Library Procedure:  vTcl:Toplevel:WidgetProc

proc ::vTcl:Toplevel:WidgetProc {w args} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.

    if {[llength $args] == 0} {
## If no arguments, returns the path the alias points to
        return $w
    }
    set command [lindex $args 0]
    set args [lrange $args 1 end]
    switch -- [string tolower $command] {
        "setvar" {
            foreach {varname value} $args {}
            if {$value == ""} {
                return [set ::${w}::${varname}]
            } else {
                return [set ::${w}::${varname} $value]
            }
        }
        "hide" - "show" {
            Window [string tolower $command] $w
        }
        "showmodal" {
## modal dialog ends when window is destroyed
            Window show $w; raise $w
            grab $w; tkwait window $w; grab release $w
        }
        "startmodal" {
## ends when endmodal called
            Window show $w; raise $w
            set ::${w}::_modal 1
            grab $w; tkwait variable ::${w}::_modal; grab release $w
        }
        "endmodal" {
## ends modal dialog started with startmodal, argument is var name
            set ::${w}::_modal 0
            Window hide $w
        }
        default {
            uplevel $w $command $args
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:WidgetProc

proc ::vTcl:WidgetProc {w args} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.

    if {[llength $args] == 0} {
## If no arguments, returns the path the alias points to
        return $w
    }
## The first argument is a switch, they must be doing a configure.
    if {[string index $args 0] == "-"} {
        set command configure
## There's only one argument, must be a cget.
        if {[llength $args] == 1} {
            set command cget
        }
    } else {
        set command [lindex $args 0]
        set args [lrange $args 1 end]
    }
    uplevel $w $command $args
}
#############################################################################
## Library Procedure:  vTcl:toplevel

proc ::vTcl:toplevel {args} {
## This procedure may be used free of restrictions.
##    Exception added by Christian Gavin on 08/08/02.
## Other packages and widget toolkits have different licensing requirements.
##    Please read their license agreements for details.

    uplevel #0 eval toplevel $args
    set target [lindex $args 0]
    namespace eval ::$target {set _modal 0}
}
}

#############################################################################
# Start Balloon Code
#
# Following code copied and pasted from http://wiki.tcl.tk/3060
# The commented out IF statement causes errors on RH9

proc balloon {w help} {
    bind $w <Any-Enter> "after 1000 [list balloon:show %W [list $help]]"
    bind $w <Any-Leave> "destroy %W.balloon"
}
proc balloon:show {w arg} {
    if {[eval winfo containing  [winfo pointerxy .]]!=$w} {return}
    set top $w.balloon
    catch {destroy $top}
    toplevel $top -bd 1 -bg black
    wm overrideredirect $top 1
    pack [message $top.txt -aspect 10000 -bg #ffffaa \
            -font variable -text $arg]
    set wmx [winfo rootx $w]
    set wmy [expr [winfo rooty $w]+[winfo height $w]]
    wm geometry $top \
      [winfo reqwidth $top.txt]x[winfo reqheight $top.txt]+$wmx+$wmy
    raise $top
}
# End Balloon Code
#############################################################################
################################
# USER DEFINED PROCEDURES
#

#############################################################################
## Procedure:  main

proc ::main {argc argv} {
wm protocol .programFrontEnd WM_DELETE_WINDOW {exit}

}

#############################################################################
#############################################################################
#############################################################################
#
#  Utility Command Procedures
#
#
#
#############################################################################
## Procedure:  writeSettingsFile
proc ::writeSettingsFile {} {

##########################
# System Variables
	global PPref

	set PrefFileHandle [open /opt/FreeFactory/etc/FreeFactory.config w]
	puts $PrefFileHandle "# FreeFactory Configuration File"
	puts $PrefFileHandle ""
	puts $PrefFileHandle "WINDOWFOREGROUND=$PPref(color,window,fore)"
	puts $PrefFileHandle "WINDOWBACKGROUND=$PPref(color,window,back)"
	puts $PrefFileHandle "ACTIVEFOREGROUND=$PPref(color,active,fore)"
	puts $PrefFileHandle "ACTIVEBACKGROUND=$PPref(color,active,back)"
	puts $PrefFileHandle "SELECTIONFOREGROUND=$PPref(color,selection,fore)"
	puts $PrefFileHandle "SELECTIONBACKGROUND=$PPref(color,selection,back)"
	puts $PrefFileHandle "WIDGETFOREGROUND=$PPref(color,widget,fore)"
	puts $PrefFileHandle "WIDGETBACKGROUND=$PPref(color,widget,back)"
	puts $PrefFileHandle "DIRECTORYFOREGROUND=$PPref(color,directory)"
	puts $PrefFileHandle "FILEFOREGROUND=$PPref(color,file)"
	puts $PrefFileHandle "SIDEWINDOWBACKGROUND=$PPref(color,sidewindow,back)"
	puts $PrefFileHandle "TOOLTIPFOREGROUND=$PPref(color,ToolTipForeground)"
	puts $PrefFileHandle "TOOLTIPBACKGROUND=$PPref(color,ToolTipBackground)"
	puts $PrefFileHandle "FOUNDRYLABEL=$PPref(Foundry,label)"
	puts $PrefFileHandle "FONTLABEL=$PPref(fonts,label)"
	puts $PrefFileHandle "FOUNDRYTEXT=$PPref(Foundry,text)"
	puts $PrefFileHandle "FONTTEXT=$PPref(fonts,text)"
	puts $PrefFileHandle "THECOMPANYNAME=$PPref(TheCompanyName)"
	puts $PrefFileHandle "APPLEDELAY=$PPref(AppleDelay)"
	puts $PrefFileHandle "FFMXPROGRAM=$PPref(FFMxProgram)"
	puts $PrefFileHandle "RUNFROM=$PPref(RunFrom)"
	puts $PrefFileHandle "ENABLEEMAIL=$PPref(EnableEMail)"
	puts $PrefFileHandle "ENABLEFACTORYLINKING=$PPref(EnableFactoryLinking)"
	puts $PrefFileHandle "RUNFROM=$PPref(RunFrom)"
	puts $PrefFileHandle "FTPTRANSFERTYPE=$PPref(FTPTransferType)"
	puts $PrefFileHandle "FTPDELETEAFTER=$PPref(FTPDeleteAfter)"
	puts $PrefFileHandle "ENABLEFACTORY=$PPref(EnableFactory)"
	puts $PrefFileHandle "DELETESOURCE=$PPref(DeleteSource)"
	puts $PrefFileHandle "DELETELOGS=$PPref(DeleteLogs)"
	puts $PrefFileHandle "FREEFACTORYACTION=$PPref(FreeFactoryAction)"
	puts $PrefFileHandle "SMTPEMAILSERVER=$PPref(SMTPEMailServer)"
	puts $PrefFileHandle "SMTPEMAILPORT=$PPref(SMTPEMailPort)"
	puts $PrefFileHandle "SMTPEMAILUSERNAME=$PPref(SMTPEMailUserName)"
# Code to encode password
	set PasswordChars [string length $PPref(SMTPEMailPassword)]
	set EncodedPassword ""
	for {set x 0} {$x < $PasswordChars} {incr x} {
		set EncodedChar  [format %c [expr [scan [string index $PPref(SMTPEMailPassword) $x] %c] + 128]]
		append EncodedPassword $EncodedChar
	}
	puts $PrefFileHandle "SMTPEMAILPASSWORD=$EncodedPassword"
	puts $PrefFileHandle "SMTPEMAILFROMNAME=$PPref(SMTPEMailFromName)"
	puts $PrefFileHandle "SMTPEMAILFROMADDRESS=$PPref(SMTPEMailFromAddress)"
	puts $PrefFileHandle "SMTPEMAILTLS=$PPref(SMTPEMailTLS)"
	puts $PrefFileHandle "GLOBALEMAILMESSAGESTART="
	if {[string trim $PPref(GlobalEMailMessage)] != ""} {
		puts $PrefFileHandle $PPref(GlobalEMailMessage)
	}
	puts $PrefFileHandle "GLOBALEMAILMESSAGEEND"
	puts $PrefFileHandle "PDFREADERPATH=$PPref(PDFReaderPath)"
	puts $PrefFileHandle "FOUNDRYTOOLTIP=$PPref(Foundry,ToolTip)"
	puts $PrefFileHandle "TOOLTIPFONTS=$PPref(fonts,ToolTip)"
	puts $PrefFileHandle "SELECTALLTEXT=$PPref(SelectAllText)"
	puts $PrefFileHandle "CONFIRMFILESAVES=$PPref(ConfirmFileSaves)"
	puts $PrefFileHandle "CONFIRMFILEDELETIONS=$PPref(ConfirmFileDeletions)"
	puts $PrefFileHandle "SHOWTOOLTIPS=$PPref(ShowToolTips)"
	puts $PrefFileHandle "DISPLAYDATEFORMAT=$PPref(DisplayDateFormat)"
	puts $PrefFileHandle "DATESEPARATER=$PPref(DateSeparater)"
	puts $PrefFileHandle "DISPLAYTIMEFORMAT=$PPref(DisplayTimeFormat)"
	puts $PrefFileHandle "DISPLAYTIMESEPARATER=$PPref(TimeSeparater)"
	puts $PrefFileHandle "DISPLAYDAYOFWEEK=$PPref(DisplayDayOfWeek)"
	close $PrefFileHandle
}
## End writeSettingsFile
#############################################################################
#############################################################################
#############################################################################
## Procedure:  getSystemTime

proc ::getSystemTime {} {
    global PPref SystemTime

        set SystemTime ""
# Full Week Day Name    
	if {$PPref(DisplayDayOfWeek) == "Yes" } {append SystemTime [clock format [clock seconds] -format %A] " "}
	if {$PPref(DisplayDateFormat) == "Shortmmddyy" } {
# Short Date
		append SystemTime [clock format [clock seconds] -format %m]
		append SystemTime $PPref(DateSeparater)
		append SystemTime "/"
		append SystemTime [clock format [clock seconds] -format %d]
		append SystemTime $PPref(DateSeparater)
		append SystemTime "/"
		append SystemTime [clock format [clock seconds] -format %y]  "  "
	 }
 	if {$PPref(DisplayDateFormat) == "Shortyymmdd" } {
		append SystemTime [clock format [clock seconds] -format %y]
		append SystemTime $PPref(DateSeparater)
		append SystemTime [clock format [clock seconds] -format %m]
		append SystemTime $PPref(DateSeparater)
		append SystemTime [clock format [clock seconds] -format %d]  "  "
	 }
	 if {$PPref(DisplayDateFormat) == "Longmmddyy" } {
# Long Date
		append SystemTime [clock format [clock seconds] -format %m]
		append SystemTime $PPref(DateSeparater)
		append SystemTime [clock format [clock seconds] -format %d]
		append SystemTime $PPref(DateSeparater)
		append SystemTime [clock format [clock seconds] -format %Y] "  "
	}
	if {$PPref(DisplayDateFormat) == "Longyymmdd" } {
		append SystemTime [clock format [clock seconds] -format %Y]
		append SystemTime $PPref(DateSeparater)
		append SystemTime [clock format [clock seconds] -format %m]
		append SystemTime $PPref(DateSeparater)
		append SystemTime [clock format [clock seconds] -format %d] "  "
	}
	if {$PPref(DisplayDateFormat) == "FullShort" } {
		append SystemTime [clock format [clock seconds] -format %B] " "
# Day of month
		append SystemTime [clock format [clock seconds] -format %d] ", "
# 2 digit year
		append SystemTime [clock format [clock seconds] -format %y]
	}

	if {$PPref(DisplayDateFormat) == "FullLong" } {
# Full Month Name
		append SystemTime [clock format [clock seconds] -format %B] " "
# Day of month
		append SystemTime [clock format [clock seconds] -format %d] ", "
# 4 digit year
		append SystemTime [clock format [clock seconds] -format %Y] "   "
 
	}
	if {$PPref(DisplayDateFormat) == "FullAbrevShort" } {
# Full Month Name
		append SystemTime [clock format [clock seconds] -format %b] " "
# Day of month
		append SystemTime [clock format [clock seconds] -format %d] ", "
# 2 digit year
		append SystemTime [clock format [clock seconds] -format %y] "   "
	}
	 if {$PPref(DisplayDateFormat) == "FullAbrevLong" } {
# Full Month Name
		append SystemTime [clock format [clock seconds] -format %b] " "
# Day of month
		append SystemTime [clock format [clock seconds] -format %d] ", "
# 4 digit year.
		append SystemTime [clock format [clock seconds] -format %Y] "   "
	}
	append SystemTime "  "
	if {$PPref(DisplayTimeFormat) == "hhmmss12Hour" } {
		append SystemTime [clock format [clock seconds] -format %I]
 		append SystemTime $PPref(TimeSeparater)
		append SystemTime [clock format [clock seconds] -format %M]
		append SystemTime $PPref(TimeSeparater)
		append SystemTime [clock format [clock seconds] -format %S] " "
		append SystemTime [clock format [clock seconds] -format %p]
	}
	if {$PPref(DisplayTimeFormat) == "hhmmss24Hour" } {
		append SystemTime [clock format [clock seconds] -format %H]
		append SystemTime $PPref(TimeSeparater)
		append SystemTime [clock format [clock seconds] -format %M]
		append SystemTime $PPref(TimeSeparater)
		append SystemTime [clock format [clock seconds] -format %S]
	}
	if {$PPref(DisplayTimeFormat) == "hhmm12Hour" } {
	 	append SystemTime [clock format [clock seconds] -format %I]
 		append SystemTime $PPref(TimeSeparater)
		append SystemTime [clock format [clock seconds] -format %M] " "
		append SystemTime [clock format [clock seconds] -format %p]
	}
	if {$PPref(DisplayTimeFormat) == "hhmm24Hour" } {
		append SystemTime [clock format [clock seconds] -format %H]
		append SystemTime $PPref(TimeSeparater)
		append SystemTime [clock format [clock seconds] -format %M]
	}
       after 1000 getSystemTime
}
## End Procedure:  getSystemTime
#############################################################################
#############################################################################
## Procedure:  updateProgressBarMain
proc ::updateProgressBarMain {} {
	global ProgressBarProgressMain ScaleWidthMain ProgressPercentCompleteMain
	global ProgressDetailCountMain ProcessedRecords TotalRecords

	.programFrontEnd.frameBottom1.frameInfo.progressBarMain configure -sliderlength [expr int(( "$ProcessedRecords.0" / "$TotalRecords" ) * $ScaleWidthMain)]  -state active
	set tmp  [expr int(( "$ProcessedRecords.0" / "$TotalRecords" ) * 100)]
	set ProgressPercentCompleteMain "$tmp%"
	set ProgressDetailCountMain "Record or file size bytes "
	append ProgressDetailCountMain $ProcessedRecords " of " $TotalRecords
	update idletasks
}
## End Procedure:  updateProgressBarMain
#############################################################################
#############################################################################
#
#
#  End Utility Command Procedures
#
#############################################################################
#############################################################################
#
#  Program Specific Procedures
#
#############################################################################
#############################################################################
## Initialization Procedure:  init

proc ::init {argc argv} {}
init $argc $argv

#################################
# VTCL GENERATED GUI PROCEDURES
#

proc vTclWindow. {base} {
    if {$base == ""} {set base .}
    ###################
    # CREATING WIDGETS
    ###################
    wm focusModelDrivers $top passive
    wm geometry $top 1x1+0+0; update
    wm maxsize $top 1265 994
    wm minsize $top 1 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm withdraw $top
    wm title $top "vtcl.tcl"
    bindtags $top "$top Vtcl.tcl all"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    ###################
    # SETTING GEOMETRY
    ###################

    vTcl:FireEvent $base <<Ready>>
}

#############################################################################
## Binding tag:  _TopLevel

	bind "_TopLevel" <<Create>> {if {![info exists _topcount]} {set _topcount 0}; incr _topcount}
	bind "_TopLevel" <<DeleteWindow>> {
		if {[set ::%W::_modal]} {
			vTcl:Toplevel:WidgetProc %W endmodal
		} else {
			destroy %W; if {$_topcount == 0} {exit}
		}
	}
	bind "_TopLevel" <Destroy> {if {[winfo toplevel %W] == "%W"} {incr _topcount -1}}

##############################################################################
##########################
# Company Variables
	global TheCompanyName AppleDelay

##########################
# Apple Delay Variables


##########################
# System Variables
	global PPref PPrefTmp screenx screeny PPrefRestore FreeFactoryInstalledVERSION FreeFactoryInstallType WindowSizeX WindowSizeY FontSizeLabel FontSizeText
	global DateFormatVar TimeFormatVar ShortLongSeparater TimeSeparater DisplayDayOfWeek
	global currentColorWidget fileRename
	global ProgressBarProgress ProcessedRecords TotalRecords ScaleWidth ProgressPercentComplete ProgressActionTitle
	global ImportDirVar ExportDirVar PicDirVar ReportManagerDirVar BlankPath5DirVar UpdateFilesToRemoteSiteDirVar UpdateFilesFromRemoteSiteDirVar BlankPath8DirVar	
	global SelectAllText ConfirmFileSaves ConfirmRecordSaves ConfirmRecordUpdates ConfirmFileDeletions ConfirmRecordDeletions ShowIconBar1 ShowIconBar2 ShowIconBar3
	global DateFormatVar ShortLongSeparater TimeFormatVar TimeSeparater DisplayDayOfWeek
	global GenericConfirmName GenericConfirm GenericConfirmObject
	global TotalOverAllFileSize ProgramFileList
	global SettingsFontsOverstrikeCheckbox SettingsFontsUnderlineCheckbox
	global progTitle progVersion byText authorText copyrightText FreeFactoryInstalledVERSION

##########################
# Widget Config Variables

	global ButtonConfig1 ComboBoxConfig1 ComboBoxConfigIWidgets ComboBoxLabelConfig2
	global MenuConfig FrameConfig EntryConfig1 EntryConfigIWidgets EntryConfigLabelIWidgets LabelConfig1 LabeledFrameConfig EntryConfig3
	global TabConfig RadioButtonConfig1 SpinIntConfigIWidgets CheckButtonConfig1 ScrolledListBoxConfigIWidgets
	global MenuButtonConfig1 MenuButtonMenuConfig1 ScrolledFrameSideConfigIWidgets LabelConfigTitle EntryConfigRecordNumbers
	global ScrolledCanvasConfigIWidgets ScaleProgressBarConfig EntryProgressBarConfig HierarchyConfigIWidgets
	global ScrolledFrameConfigIWidgets CanvasConfig1

##########################
# Filedialog globals
	global returnFilePath returnFileName returnFullPath fileDialogOk fullDirPath dirpath toolTip windowName buttonImagePathFileDialog
#############################################################################

#	set TheCompanyName "Company Name"
#	set AppleDelay 0

	if {[file exist /opt/FreeFactory/etc/FreeFactory.config]} {
		set PrefFileHandle [open /opt/FreeFactory/etc/FreeFactory.config r]
		while {![eof $PrefFileHandle]} {
			gets $PrefFileHandle PrefVar
			set EqualDelimiter [string first "=" $PrefVar]
			if {$EqualDelimiter>0 && [string first "#" [string trim $PrefVar]]!=0} {
				set PrefField [string trim [string range $PrefVar 0 [expr $EqualDelimiter - 1]]]
				set PrefValue [string trim [string range $PrefVar [expr $EqualDelimiter + 1] end]]
				switch $PrefField {
					"WINDOWFOREGROUND" {set PPref(color,window,fore) $PrefValue}
					"WINDOWBACKGROUND" {set PPref(color,window,back) $PrefValue}
					"ACTIVEFOREGROUND" {set PPref(color,active,fore) $PrefValue}
					"ACTIVEBACKGROUND" {set PPref(color,active,back) $PrefValue}
					"SELECTIONFOREGROUND" {set PPref(color,selection,fore) $PrefValue}
					"SELECTIONBACKGROUND" {set PPref(color,selection,back) $PrefValue}
					"WIDGETFOREGROUND" {set PPref(color,widget,fore) $PrefValue}
					"WIDGETBACKGROUND" {set PPref(color,widget,back) $PrefValue}
					"DIRECTORYFOREGROUND" {set PPref(color,directory) $PrefValue}
					"FILEFOREGROUND" {set PPref(color,file) $PrefValue}
					"SIDEWINDOWBACKGROUND" {set PPref(color,sidewindow,back) $PrefValue}
					"TOOLTIPFOREGROUND" {set PPref(color,ToolTipForeground) $PrefValue}
					"TOOLTIPBACKGROUND" {set PPref(color,ToolTipBackground) $PrefValue}
					"FOUNDRYLABEL" {set PPref(Foundry,label) $PrefValue}
					"FONTLABEL" {set PPref(fonts,label) $PrefValue}
					"FOUNDRYTEXT" {set PPref(Foundry,text) $PrefValue}
					"FONTTEXT" {set PPref(fonts,text) $PrefValue}
					"THECOMPANYNAME" {set PPref(TheCompanyName) $PrefValue}
					"APPLEDELAY" {set PPref(AppleDelay) $PrefValue}
					"FFMXPROGRAM" {set PPref(FFMxProgram) $PrefValue}
					"RUNFROM" {set PPref(RunFrom) $PrefValue}
					"ENABLEEMAIL" {set PPref(EnableEMail) $PrefValue}
					"ENABLEFACTORYLINKING" {set PPref(EnableFactoryLinking) $PrefValue}
					"FTPTRANSFERTYPE" {set PPref(FTPTransferType) $PrefValue}
					"FTPDELETEAFTER" {set PPref(FTPDeleteAfter) $PrefValue}
					"ENABLEFACTORY" {set PPref(EnableFactory) $PrefValue}
					"DELETESOURCE" {set PPref(DeleteSource) $PrefValue}
					"DELETELOGS" {set PPref(DeleteLogs) $PrefValue}
					"FREEFACTORYACTION" {set PPref(FreeFactoryAction) $PrefValue}
					"SMTPEMAILSERVER" {set PPref(SMTPEMailServer) $PrefValue}
					"SMTPEMAILPORT" {set PPref(SMTPEMailPort) $PrefValue}
					"SMTPEMAILUSERNAME" {set PPref(SMTPEMailUserName) $PrefValue}
					"SMTPEMAILPASSWORD" {
# This will decode the Email password variable
						set PasswordChars [string length $PrefValue]
						set DecodedPassword ""
						for {set x 0} {$x < $PasswordChars} {incr x} {
							set DecodedChar  [format %c [expr [scan [string index $PrefValue $x] %c] - 128]]
							append DecodedPassword $DecodedChar
						}
						set PPref(SMTPEMailPassword) $DecodedPassword
					}
					"SMTPEMAILFROMNAME" {set PPref(SMTPEMailFromName) $PrefValue}
					"SMTPEMAILFROMADDRESS" {set PPref(SMTPEMailFromAddress) $PrefValue}
					"SMTPEMAILTLS" {set PPref(SMTPEMailTLS) $PrefValue}
					"GLOBALEMAILMESSAGESTART" {
						set PPref(GlobalEMailMessage) ""
						set FactoryValue ""
						while {![eof $PrefFileHandle] && $FactoryValue !="GLOBALEMAILMESSAGEEND"} {
							gets $PrefFileHandle FactoryValue
							if {$FactoryValue != "GLOBALEMAILMESSAGEEND"} {
								append PPref(GlobalEMailMessage) $FactoryValue\n
							}
						}
					}
					"PDFREADERPATH" {set PPref(PDFReaderPath) $PrefValue}
					"FOUNDRYTOOLTIP" {set PPref(Foundry,ToolTip) $PrefValue}
					"TOOLTIPFONTS" {set PPref(fonts,ToolTip) $PrefValue}
					"SELECTALLTEXT" {set PPref(SelectAllText) $PrefValue}
					"CONFIRMFILESAVES" {set PPref(ConfirmFileSaves) $PrefValue}
					"CONFIRMFILEDELETIONS" {set PPref(ConfirmFileDeletions) $PrefValue}
					"SHOWTOOLTIPS" {set PPref(ShowToolTips) $PrefValue}
					"DISPLAYDATEFORMAT" {set PPref(DisplayDateFormat) $PrefValue}
					"DATESEPARATER" {set PPref(DateSeparater) $PrefValue}
					"DISPLAYTIMEFORMAT" {set PPref(DisplayTimeFormat) $PrefValue}
					"DISPLAYTIMESEPARATER" {set PPref(TimeSeparater) $PrefValue}
					"DISPLAYDAYOFWEEK" {set PPref(DisplayDayOfWeek) $PrefValue}
				}
			}
		}
		close $PrefFileHandle
		set TheCompanyName $PPref(TheCompanyName)
		set AppleDelay $PPref(AppleDelay)
	}
	set FileHandle [open "/opt/FreeFactory/VERSION" r]
	gets $FileHandle FreeFactoryInstalledVERSION
	close $FileHandle
#
#
#############################################################################
	Window show .
	source "/opt/FreeFactory/bin/WidgetUpdate.tcl"
	source "/opt/FreeFactory/bin/ProgramGUIUtilities.tcl"
	source "/opt/FreeFactory/bin/ProgramFrontEnd.tcl"
#############################################################################
#############################################################################
## Set the window title
	set WindowTitle "Free Factory - Video Conversion Configuation for $TheCompanyName"
## Determine the screen size
	set screenx [winfo screenwidth .]
	set screeny [winfo screenheight .]
# Display the FreeFactory front end gui
	Window show .programFrontEnd
	wm title .programFrontEnd $WindowTitle

#############################################################################
# Update widgets on main GUI.
	widgetUpdate
#############################################################################
#############################################################################
#
#  This command is run last.  It starts the loop that updates the time display
#  in FreeFactory by the second
#
	getSystemTime
#
#############################################################################
#############################################################################
#
	main $argc $argv
#
#############################################################################
#############################################################################
