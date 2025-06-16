################################################################################################
#               This code is licensed under the GPLv3
#    The following terms apply to all files associated with the software
#            unless explicitly disclaimed in individual files.
#
#                       Copyright 2013, 2024
#                               by
#                     Jim Hines and Karl Swisher
#
#                           About.tcl
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
# Program:About.tcl
#
# This is the about program for Free Factory
################################################################################################
proc vTclWindow.showAbout {base} {
	global progTitle progVersion byText authorText copyrightText FreeFactoryInstalledVERSION
	global PPref screenx screeny
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-250)/2)]
	set yCord [expr int(($screeny-140)/2)]
############################################################################
############################################################################
	if {$base == ""} {
		set base .showAbout
	}
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
	wm geometry $top 250x140+$xCord+$yCord; update
	wm maxsize $top 250 140
	wm minsize $top 250 140
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm title $top "About"
	vTcl:DefineAlias "$top" "Toplevel3" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {
		destroy window .showAbout
	}
	bind $top <Key-KP_Enter> {
		destroy window .showAbout
	}
	bind $top <Key-Return> {
		destroy window .showAbout
	}

	frame $top.frameAbout -borderwidth 3 -height 265 -highlightcolor black -relief sunken -width 235
	vTcl:DefineAlias "$top.frameAbout" "FrameAboutFreeFactory" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.frameAbout

	entry $site_3_0.progTitleEntry -relief flat -justify center -background white -insertbackground black -textvariable progTitle
	vTcl:DefineAlias "$site_3_0.progTitleEntry" "EntryTitleAboutFreeFactory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.progTitleEntry -in $top.frameAbout -anchor center -expand 1 -fill x -side top

	entry $site_3_0.progVersionEntry -relief flat -justify center -background white -insertbackground black -textvariable progVersion
	vTcl:DefineAlias "$site_3_0.progVersionEntry" "EntryVersionAboutFreeFactory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.progVersionEntry -in $top.frameAbout -anchor center -expand 1 -fill x -side top

	entry $site_3_0.byTextEntry -relief flat -justify center -background white -insertbackground black -textvariable byText
	vTcl:DefineAlias "$site_3_0.byTextEntry" "EntryByAboutFreeFactory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.byTextEntry -in $top.frameAbout -anchor center -expand 1 -fill x -side top

	entry $site_3_0.authorTextEntry -relief flat -justify center -background white -insertbackground black -textvariable authorText
	vTcl:DefineAlias "$site_3_0.authorTextEntry" "EntryAuthorAboutFreeFactory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.authorTextEntry -in $top.frameAbout -anchor center -expand 1 -fill x -side top

	entry $site_3_0.copyrightTextEntry -relief flat -justify center -background white -insertbackground black -textvariable copyrightText
	vTcl:DefineAlias "$site_3_0.copyrightTextEntry" "EntryCopyrightAboutFreeFactory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.copyrightTextEntry -in $top.frameAbout -anchor center -expand 1 -fill x -side top

	pack $top.frameAbout -in $top -anchor center -expand 0 -fill both -side top

    button $top.closeButton -activebackground #e6e6e6 -activeforeground #000000 -background #e6e6e6 -command {
		destroy window .showAbout
	} -foreground #000000 -highlightbackground #e6e6e6 -highlightcolor #000000 -text "Close"
	vTcl:DefineAlias "$top.closeButton" "ButtonCloseAboutFreeFactory" vTcl:WidgetProc "Toplevel3" 1
	pack $top.closeButton -in $top -anchor center -expand 0 -fill none -side top

    vTcl:FireEvent $base <<Ready>>
}

#############################################################################
#############################################################################
## Procedure: initAbout

proc ::initAbout {} {
	global progTitle progVersion byText authorText copyrightText FreeFactoryInstalledVERSION

	set progTitle "Free Factory"
	set progVersion "Version "
	append progVersion $FreeFactoryInstalledVERSION
	set byText "by"
	set authorText "Jim Hines and Karl Swisher"
	set copyrightText "Copyright 2013, 2024 GPLv3"
	widgetUpdate
}
# End initAbout
#############################################################################
