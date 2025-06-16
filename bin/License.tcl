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
# Program:License.tcl
#
#
# This displays the GPL license for FreeFactory
################################################################################################
proc vTclWindow.showLicense {base} {
    global PPref screenx screeny
    set xCord [expr int(($screenx-575)/2)]
    set yCord [expr int(($screeny-425)/2)]
    if {$base == ""} {set base .showLicense}
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel \
        -background #e6e6e6 -highlightbackground #e6e6e6 \
        -highlightcolor #000000
    wm withdraw $top
    wm focusmodel $top passive
    wm geometry $top 575x425+$xCord+$yCord; update
    wm maxsize $top 575 994
    wm minsize $top 575 425
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm title $top "License"
    vTcl:DefineAlias "$top" "Toplevel2" vTcl:Toplevel:WidgetProc "" 1
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
    bind $top <Escape> {destroy window .showLicense}
    bind $top <Key-KP_Enter> {destroy window .showLicense}
    bind $top <Key-Return> {destroy window .showLicense}

    ::iwidgets::scrolledtext $top.showLicenseText \
        -exportselection 0 -height 393 -hscrollmode dynamic \
        -textbackground #fefefe -vscrollmode dynamic -width 553 -wrap word
    vTcl:DefineAlias "$top.showLicenseText" "ScrolledTextLicense" vTcl:WidgetProc "Toplevel2" 1

    button $top.closeButton \
        -activebackground #e6e6e6 -activeforeground #000000 \
        -background #e6e6e6 -command {
		destroy window .showLicense
	} \
        -foreground #000000 -highlightbackground #e6e6e6 \
        -highlightcolor #000000 -text "Close"
    vTcl:DefineAlias "$top.closeButton" "ButtonCloseLicense" vTcl:WidgetProc "Toplevel2" 1
    ###################
    # SETTING GEOMETRY
    ###################
    pack $top.showLicenseText -in $top -anchor nw -expand 1 -fill both -side top
    pack $top.closeButton -in $top -anchor center -expand 0 -fill none -side top

    vTcl:FireEvent $base <<Ready>>
}
##########################################################################################
