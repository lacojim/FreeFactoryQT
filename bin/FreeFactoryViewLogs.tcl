#############################################################################
#               This code is licensed under the GPLv3
#    The following terms apply to all files associated with the software
#            unless explicitly disclaimed in individual files.
#
#                           Free Factory
#
#                          Copyright 2013
#                               by
#                     Jim Hines and Karl Swisher
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 3 of the License, or
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
# Program:FreeFactoryViewLogs.tcl
#
#
# This displays the GPL license for FreeFactory
################################################################################################
proc vTclWindow.freeFactoryViewLogs {base} {

	global PPref screenx screeny
	global LogList LogListNew LogCount LogCountNew

	set xCord [expr int(($screenx-1000)/2)]
	set yCord [expr int(($screeny-600)/2)]
	if {$base == ""} {set base .freeFactoryViewLogs}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -background #e6e6e6 -highlightbackground #e6e6e6 -highlightcolor #000000
	wm withdraw $top
	wm focusmodel $top passive
	wm geometry $top 1000x600+$xCord+$yCord; update
	wm maxsize $top 1680 1050
	wm minsize $top 80 60
	wm overrideredirect $top 0
	wm resizable $top 1 1
	wm title $top "View Free Factory Logs"
	vTcl:DefineAlias "$top" "Toplevel2" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
# Escape exits the window
	bind $top <Escape> {destroy window .freeFactoryViewLogs}

	::iwidgets::labeledframe $top.viewFreeFactoryLogsLabeledFrame -labelpos nw -labeltext "View Free Factory Logs"
	vTcl:DefineAlias "$top.viewFreeFactoryLogsLabeledFrame" "LabeledFrameViewFreeFactoryLogs" vTcl:WidgetProc "Toplevel1" 1

	set site_1_0 [$top.viewFreeFactoryLogsLabeledFrame childsite]

	frame $site_1_0.listLogsFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_1_0.listLogsFrame" "FrameListLogs" vTcl:WidgetProc "Toplevel1" 1

	set site_1_1 $site_1_0.listLogsFrame

	::iwidgets::scrolledlistbox $site_1_1.logsListBox -activebackground #f9f9f9 -activerelief raised -background #e6e6e6 \
	-borderwidth 2 -disabledforeground #a3a3a3 -foreground #000000 -height 100 -highlightcolor black -highlightthickness 1 \
	-hscrollmode dynamic -selectmode single -jump 0 -labelpos n -labeltext "Free Factory Log List" -relief sunken \
	-sbwidth 10 -selectbackground #c4c4c4 -selectborderwidth 1 -selectforeground black -state normal \
	-textbackground #d9d9d9 -troughcolor #c4c4c4 -vscrollmode dynamic -dblclickcommand {} -selectioncommand {
		set LogListPos [ScrolledListBoxLogs curselection ]
		set LogListName [ScrolledListBoxLogs get [ScrolledListBoxLogs curselection ]]
		ScrolledTextLog delete 0.0 end
# If the file exists than load it.
		if {[file exists "/var/log/FreeFactory/$LogListName"]} {
			set FileHandle [open "/var/log/FreeFactory/$LogListName" r]
			while {![eof $FileHandle]} {
				gets $FileHandle FactoryVar
				ScrolledTextLog insert end $FactoryVar\n
			}
			set ScrollBoxView [ScrolledListBoxLogs yview]
			set ScrollBoxView [lindex $ScrollBoxView 0]
# tk_messageBox -message $ScrollBoxView

		} else {
# If the file does not exist then the conversion program must have deleted it and
# log list box needs refreshed.
			FillLogList
		}
		close $FileHandle
	} -width 250
	vTcl:DefineAlias "$site_1_1.logsListBox" "ScrolledListBoxLogs" vTcl:WidgetProc "Toplevel1" 1
	pack $site_1_1.logsListBox -in $site_1_1 -anchor n -expand 1 -fill y -side top

	frame $site_1_1.listLogsButtonFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_1_1.listLogsButtonFrame" "FrameListLogsButton" vTcl:WidgetProc "Toplevel1" 1

	set site_1_1_1 $site_1_1.listLogsButtonFrame

	button $site_1_1_1.refreshLogButton -borderwidth 1 -highlightthickness 0 -relief raised \
	-command {
		ScrolledTextLog delete 0.0 end
		FillLogList
	} -image [vTcl:image:get_image [file join / opt FreeFactory Pics reload32x32.gif]]
	vTcl:DefineAlias "$site_1_1_1.refreshLogButton" "ButtonRefreshLog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_1_1_1.refreshLogButton -in $site_1_1_1 -anchor center -expand 1 -fill none -side left
	balloon $site_1_1_1.refreshLogButton "Refresh Log"

	button $site_1_1_1.removeLogButton -borderwidth 1 -highlightthickness 0 -relief raised \
	-command {
		if {[file exists "/var/log/FreeFactory/$LogListName"]} {
						file delete -force "/var/log/FreeFactory/$LogListName"
		}
		ScrolledTextLog delete 0.0 end
		FillLogList
	} -image [vTcl:image:get_image [file join / opt FreeFactory Pics remove32x32.gif]]
	vTcl:DefineAlias "$site_1_1_1.removeLogButton" "ButtonRemoveLog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_1_1_1.removeLogButton -in $site_1_1_1 -anchor center -expand 1 -fill none -side right
	balloon $site_1_1_1.removeLogButton "Remove Log"

	pack $site_1_1.listLogsButtonFrame -in $site_1_1 -anchor center -expand 0 -fill x -side top
	pack $site_1_0.listLogsFrame -in $site_1_0 -anchor nw -expand 0 -fill y -side left

	frame $site_1_0.viewLogFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_1_0.viewLogFrame" "FrameViewLog" vTcl:WidgetProc "Toplevel1" 1

	set site_1_2 $site_1_0.viewLogFrame

	::iwidgets::scrolledtext $site_1_2.freeFactoryViewLogsText \
	-exportselection 0 -height 393 -hscrollmode dynamic -labelpos n -labeltext "Free Factory Log Details" \
	-textbackground #fefefe -vscrollmode dynamic -width 553 -wrap word
	vTcl:DefineAlias "$site_1_2.freeFactoryViewLogsText" "ScrolledTextLog" vTcl:WidgetProc "Toplevel2" 1
	pack $site_1_2.freeFactoryViewLogsText -in $site_1_2 -anchor nw -expand 1 -fill both -side top

	pack $site_1_0.viewLogFrame -in $site_1_0 -anchor nw -expand 1 -fill both -side left

	pack $top.viewFreeFactoryLogsLabeledFrame -in $top -anchor nw -expand 1 -fill both -side top

	button $top.closeButton -activebackground #e6e6e6 -activeforeground #000000 \
        -background #e6e6e6 -command {
		destroy window .freeFactoryViewLogs
	} \
	-foreground #000000 -highlightbackground #e6e6e6 \
	-highlightcolor #000000 -image [vTcl:image:get_image [file join / opt FreeFactory Pics exit32x32.gif]]
	vTcl:DefineAlias "$top.closeButton" "ButtonCloseFreeFactoryViewLogs" vTcl:WidgetProc "Toplevel2" 1
	pack $top.closeButton -in $top -anchor center -expand 0 -fill none -side bottom

	vTcl:FireEvent $base <<Ready>>
	set LogList ""
}
##########################################################################################
################################################################################
# Start InitFreeFactoryViewLogs
proc InitFreeFactoryViewLogs {} {

	global LogList

	set LogList ""
	FillLogList
}
##########################################################################################
################################################################################
# Start InitFreeFactoryViewLogs
proc FillLogList {} {

	global LogList LogListNew LogCount LogCountNew


#	if {$LogList == ""} {
#		set LogCount 0
#		set LogCountNew 0
#		foreach item [lsort [glob -nocomplain /var/log/FreeFactory/*]] {
#			lappend LogList [file tail $item]
#			lappend LogListNew [file tail $item]
#			incr LogCount
#			incr LogCountNew
#		}
#		ScrolledListBoxLogs delete 0 end
#		foreach item [lsort [glob -nocomplain /var/log/FreeFactory/*]] {
#			ScrolledListBoxLogs insert end [file tail $item]
#		}
#	} else {
#		set LogListNew ""
#		set LogCountNew 0
#		foreach item [lsort [glob -nocomplain /var/log/FreeFactory/*]] {
#			lappend LogListNew [file tail $item]
#			incr LogCountNew
#		}
#		if {$LogCount == $LogCountNew} {
#			set ListBoxUpdateAction "Same"
#			for {set x 0} {$x < $LogCount} {incr x} {
#				if {[lindex $LogList $x] != [lindex $LogListNew $x]} {
#					set ListBoxUpdateAction "Not Same"
#					break
#				}
#			}
#		} else {
#			for {set x 0} {$x < $LogCount} {incr x} {
#				set LogThere "No"
#				for {set y 0} {$y < $LogCountNew} {incr y} {
#					if {[lindex $LogList $x] == [lindex $LogListNew $y]} {
#						set LogThere "Yes"
#						break
#					}
#				}
#tk_messageBox -message [lindex $LogList $x]
#tk_messageBox -message [lindex $LogListNew $y]
#tk_messageBox -message $LogThere
#				if {$LogThere == "No"} {
#					ScrolledListBoxLogs delete $x $x
#				}
#			}
#			for {set x 0} {$x < $LogCountNew} {incr x} {
#				set LogThere "No"
#				for {set y 0} {$y < $LogCount} {incr y} {
#					if {[lindex $LogListNew $x] == [lindex $LogList $y]} {
#						set LogThere "Yes"
#						break
#					}
#				}
#				if {$LogThere == "No"} {
#					ScrolledListBoxLogs insert end [lindex $LogListNew $x]
#				}
#			}
#			set LogList $LogListNew
#			set LogCount $LogCountNew

#		}
#	}

	ScrolledListBoxLogs delete 0 end
	foreach item [lsort [glob -nocomplain /var/log/FreeFactory/*]] {
		ScrolledListBoxLogs insert end [file tail $item]
	}

#	after 30800 FillLogList

}
##########################################################################################

#pathName yview
#pathName yview moveto fraction





