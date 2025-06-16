################################################################################################
#               This code is licensed under the GPLv2
#              Copyright 2005-2007 Tux Technology, LLC
#                               by
#                          Karl Swisher
#
#                        FileDialog.tcl
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
# Program:FileDialog.tcl
#
# User Variables:
#
#   Input to dialog:
#	MNS::FileSelectTypeList = This is for the file type filter
#	MNS::ButtonImagePathFileDialog = Path to image for open/save button
#	MNS::WindowName = Window Title
#	MNS::ToolTip = Changes the tool tip depending on operation options are Open, Save, Import, Export.  Curently
#                 does not function.
#	MNS::FullDirPath = The full directory path that the dialog will start in.  Does not end with /
#
#   Output from dialog:
#       MNS::ReturnFilePath = The Full path including the selected file
#       MNS::ReturnFileName = The file name returned
#       MNS::ReturnFullPath = The full path including the file name.
#       MNS:FileDialogOk   = Variable indicating the file dialog action was or was not cancelled.
#
################################################################################################
proc vTclWindow.fileDialog {base} {

############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(([winfo screenwidth .]-494)/2)]
	set yCord [expr int(([winfo screenheight .]-313)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .fileDialog}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -height 539 -highlightcolor black -width 794 
	wm withdraw $top
	wm focusmodel $top passive
	wm geometry $top 494x313+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 494 313
	wm overrideredirect $top 0
	wm resizable $top 1 1
	wm title $top "Open File..."
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
#################################################################################
# This is the right click release popup menu code.  This is bound to the top level of
# file dialog box.  Have tried to bind this to the listbox widget without success.
# If were able to bind to specific widgets then custom popups could be created.  If
# bound to the left side frame then a popup could be created to add additional buttons 
# of favorites. 
	bind $top <ButtonRelease-3> {
# Keep an extra line here commented out.  vTCL puts a %W in place of the path name of
# where ever the mouse is when the button is released.  This causes an error
#	set openReqPopUp [tk_popup .fileDialog.fileDialogPopUp [winfo pointerx .fileDialog] [winfo pointery .fileDialog] 0]
#
#  This popup will be displayed relative to mouse location.
	.fileDialog.fileDialogPopUp configure -foreground $MNS::PPref(PPref,color,window,fore) -background $MNS::PPref(PPref,color,window,back) -font $MNS::PPref(PPref,fonts,label) -activeforeground $MNS::PPref(PPref,color,active,fore) -activebackground $MNS::PPref(PPref,color,active,back) 
	
	set openReqPopUp [tk_popup .fileDialog.fileDialogPopUp [winfo pointerx .fileDialog] [winfo pointery .fileDialog] 0]
	}
	bind $top <Escape> {
		set MNS::ReturnFilePath ""
		if {[winfo exist .fileDialogProperties]} {
			destroy window .fileDialogProperties
		}
		if {[winfo exist .newDirNameReq]} {
			destroy window .newDirNameReq
		}
		if {[winfo exist .MNS::FileRename]} {
			destroy window .MNS::FileRename
		}
		destroy window .fileDialog
  }
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

	frame $top.frameTop -height 35 -highlightcolor black -relief raised -width 495 -border 0
	vTcl:DefineAlias "$top.frameTop" "FrameTopFileDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.frameTop

	label $site_3_0.lookInLabel -activebackground #f9f9f9 -activeforeground black -foreground black -highlightcolor black -text {Look In:}
	vTcl:DefineAlias "$site_3_0.lookInLabel" "LabelLookInFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.lookInLabel -in $site_3_0 -anchor w -expand 1 -fill none -side left

	menubutton $site_3_0.toolButton -borderwidth 0 -relief flat -highlightthickness 0 -activebackground #f9f9f9 -activeforeground black -foreground black \
	-height 23 -highlightcolor black -image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics tool.gif]] \
	-indicatoron 1 -menu "$site_3_0.toolButton.m" -padx 5 -pady 5 -relief raised -width 24
	vTcl:DefineAlias "$site_3_0.toolButton" "MenuButtonToolFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.toolButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.toolButton "Tools"

#####################################################
# This is the far right menu button that has the wrench (Tools) icon.
	menu $site_3_0.toolButton.m -activebackground #f9f9f9 -activeforeground black -foreground black -tearoff 0
	vTcl:DefineAlias "$site_3_0.toolButton.m" "MenuButtonMenu1ToolFileDialog" vTcl:WidgetProc "Toplevel1" 1

	$site_3_0.toolButton.m add command -command {
# TODO: Your menu handler here
		global MNS::PPref
		Window show .findFileDialog
		Window show .findFileDialog
		widgetUpdate
###########
#  Initialize the data for the widgets
		.findFileDialog.comboboxFindFileDialog clear
		.findFileDialog.comboboxFindFileDialog delete entry 0 end
		.findFileDialog.comboboxFindFileDialog insert entry end [ComboBoxUpLevelFileDialog getcurselection]
#####################
# Use the existing cache of paths already in the top combox look in
		foreach boxinsert $MNS::UpLevelComboBoxListVar {
			.findFileDialog.comboboxFindFileDialog insert list end $boxinsert
		}
		focus .findFileDialog.entryFindFileDialog
		focus .findFileDialog.entryFindFileDialog
	} -label Find
##############################################
# Start Delete menu item
	$site_3_0.toolButton.m add command -command {
		deleteFileDialog
	} -label Delete
# End Delete menu item
##############################################
##############################################
# Start Rename menu item
	$site_3_0.toolButton.m add command -command {
		renameFileDialog
	} -label Rename
# End Rename menu item
##############################################
##############################################
# Start Print menu item
	$site_3_0.toolButton.m add command -command {
		source "/usr/local/PgTCLScales/bin/WidgetUpdate.tcl"
		initPrinterDialog
	} -label Print
# End Print menu item
##############################################
##############################################
# Start Add To Bookmarks menu item
	$site_3_0.toolButton.m add cascade -menu "$site_3_0.toolButton.m.men67" -command {} -label {Add To Bookmarks}
###############################################
# Start submenus for each browser.  It would be nice if Linux users had a single bookmark file
# that all browsers could access.  This would eliminate a lot of code here
#
# The actual writing to the file is done in the file dialog box.  All browser variables are
# nulled in each command because each var in the di
#
##############################################
# Start Konqueror submenu item
	set site_5_0 $site_3_0.toolButton.m

	menu $site_5_0.men67 -tearoff 0
	vTcl:DefineAlias "$site_3_0.toolButton.m.men67" "MenuButtonMenu2ToolFileDialog" vTcl:WidgetProc "Toplevel1" 1

	$site_5_0.men67 add command -command {
		set MNS::BookMarkBrowserName {Konqueror}
		set MNS::BookMarkBrowserPath "/home/[exec whoami]"
		append MNS::BookMarkBrowserPath {/.kde/share/apps/konqueror/bookmarks.xml}
		if {[file exist $MNS::BookMarkBrowserPath]} {
			initBookmarksTitle
		}
	} -label Konqueror
# End Konqueror submenu item
##############################################
##############################################
# Start Netscape submenu item
	$site_5_0.men67 add command -command {
		set MNS::BookMarkBrowserName {Netscape}
		set MNS::BookMarkBrowserPath "/home/[exec whoami]"
		append MNS::BookMarkBrowserPath {/.netscape/bookmarks.html}
		if {[file exist $MNS::BookMarkBrowserPath]} {
			initBookmarksTitle
 		}
	} -label Netscape
# End Netscape submenu item
##############################################
##############################################
# Start Mozilla submenu item
	$site_5_0.men67 add command -command {
		set MNS::BookMarkBrowserName {Mozilla}
		set MNS::BookMarkBrowserPath "/home/[exec whoami]"
		set mozillabookmarkdefault  "/home/[exec whoami]"
		set mozillabookmarkuser  "/home/[exec whoami]"
		append mozillabookmarkdefault {/.mozilla/default/}
		append mozillabookmarkuser {/.mozilla/} [string range "/home/[exec whoami]" [expr [string last {/} "/home/[exec whoami]"] +1] end] {/}
		append mozillabookmarkdefault  [file tail [glob -nocomplain -directory $mozillabookmarkdefault *.slt]] {/bookmarks.html}
		append mozillabookmarkuser   [file tail [glob -nocomplain -directory $mozillabookmarkuser *.slt]] {/bookmarks.html}
		if {[file exist $mozillabookmarkuser]} {
			set MNS::BookMarkBrowserPath $mozillabookmarkuser
			initBookmarksTitle
		} else {
			if {[file exist $mozillabookmarkdefault]} {

				set MNS::BookMarkBrowserPath $mozillabookmarkdefault
				initBookmarksTitle
			}
		}
	} -label Mozilla
# End Mozilla submenu item
##############################################
##############################################
# Start Nautilus submenu item
	$site_5_0.men67 add command -command {
		set MNS::BookMarkBrowserName {Nautilus}
		set MNS::BookMarkBrowserPath "/home/[exec whoami]"
		append MNS::BookMarkBrowserPath {/.nautilus/bookmarks.xml}
		if {[file exist $MNS::BookMarkBrowserPath]} {initBookmarksTitle}
	} -label Nautilus
# End Nautilus submenu item
##############################################
##############################################
# Start Galeon submenu item
	$site_5_0.men67 add command -command {
		set MNS::BookMarkBrowserName {Galeon}
		set MNS::BookMarkBrowserPath "/home/[exec whoami]"
		append MNS::BookMarkBrowserPath {/.galeon/bookmarks.xbel}
		if {[file exist $MNS::BookMarkBrowserPath]} {initBookmarksTitle}
	} -label Galeon
# End Galeon submenu item
##############################################
##############################################
# Start Opera submenu item
	$site_5_0.men67 add command -command {
		set MNS::BookMarkBrowserName {Opera}
		set MNS::BookMarkBrowserPath "/home/[exec whoami]"
		append MNS::BookMarkBrowserPath {/.opera/opera6.adr}
		if {[file exist $MNS::BookMarkBrowserPath]} {initBookmarksTitle}
	} -label Opera
# End Opera submenu item
##############################################
# End Submenu for Add To Bookmarks
##############################################################    
#######################################
# Start Mount menu item
#
#  This code in the command for now only takes the path to /mnt.  It doesn't actualy
# mount a drive partion or share.  It is the desire eventually have mounting code
# in place of this code.
	$site_3_0.toolButton.m add command -command {
		set backLevelName $MNS::FullDirPath
		set MNS::FullDirPath {/mnt}
# cd to the directory
		cd $MNS::FullDirPath
# Unable to get the unique property working.  This code
# prevents duplicates
		set duplicateTrigger 0
		foreach tmpvar $MNS::UpLevelComboBoxListVar {
                        	if {$MNS::FullDirPath == $tmpvar} {
				set duplicateTrigger 1
				break
			}
		}
		if {$duplicateTrigger == 0} {
# If not a duplicate then add the path to the combobox and sort it.
# Then clear the combobox and refresh it.
			set MNS::UpLevelComboBoxListVar [lsort [lappend MNS::UpLevelComboBoxListVar $MNS::FullDirPath]]
			ComboBoxUpLevelFileDialog clear
			foreach tmpvar $MNS::UpLevelComboBoxListVar {
				ComboBoxUpLevelFileDialog insert list end $tmpvar
               		}
		}
# Replace the current with the new selected path
		ComboBoxUpLevelFileDialog delete entry 0 end
		ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
# This one clears the listbox for the new directory
		redoFileDialogListBox
		if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initFileDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label {Mount Drive}
# End Mount menu item
#######################################
#######################################
# Start Properties menu item
	$site_3_0.toolButton.m add separator

	$site_3_0.toolButton.m add command -command {
		set MNS::FileDisplayType {Properties}
		if {![winfo exist .fileDialogProperties]} {
			Window show .fileDialogProperties
			Window show .fileDialogProperties
			initFileDialogProperties
		}
		redoFileDialogListBox
		if {$MNS::FileNameList !=""} {
		    	set MNS::DirPathProperty [ScrolledListBoxFileViewFileDialog get [ScrolledListBoxFileViewFileDialog curselection] [ScrolledListBoxFileViewFileDialog curselection]]
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label Properties 
# End Properties menu item
#######################################
# End Tool Button
#################################################################
#################################################################
# Start View Type Butto
	menubutton $site_3_0.viewTypeButton -borderwidth 0 -relief flat -highlightthickness 0 \
	-activebackground #f9f9f9 -activeforeground black -foreground black -height 23 -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics show.gif]] \
	-indicatoron 1 -menu "$site_3_0.viewTypeButton.m" -padx 5 -pady 5 -relief raised -width 24
	vTcl:DefineAlias "$site_3_0.viewTypeButton" "MenuButtonViewFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.viewTypeButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.viewTypeButton "View Type"

	menu $site_3_0.viewTypeButton.m -activebackground #f9f9f9 -activeforeground black -foreground black -tearoff 0
	vTcl:DefineAlias "$site_3_0.viewTypeButton.m" "MenuButtonMenu1ViewFileDialog" vTcl:WidgetProc "Toplevel1" 1

####################################
# Start List menu item
	$site_3_0.viewTypeButton.m add command -command {
#		global MNS::FileDisplayType
		set MNS::FileDisplayType "List"
# If previous view type was properties then get rid of that dialog box
		if {[winfo exist .fileDialogProperties]} {destroy window .fileDialogProperties}
# This one clears the listbox for the new directory
		redoFileDialogListBox
	} -label List
# End List menu item
####################################
####################################
# Start Details menu item
	$site_3_0.viewTypeButton.m add command -command {
#		global MNS::FileDisplayType
		set MNS::FileDisplayType "Details"
		if {[winfo exist .fileDialogProperties]} {destroy window .fileDialogProperties}
# This one clears the listbox for the new directory
		redoFileDialogListBox
	} -label Details
# End Details menu item
####################################
####################################
# Start Properties menu item
	$site_3_0.viewTypeButton.m add command -command {
		set MNS::FileDisplayType {Properties}
		if {![winfo exist .fileDialogProperties]} {
			Window show .fileDialogProperties
			initFileDialogProperties
		}
		redoFileDialogListBox
		if {$MNS::FileNameList !=""} {
		    	set MNS::DirPathProperty [ScrolledListBoxFileViewFileDialog get [ScrolledListBoxFileViewFileDialog curselection] [ScrolledListBoxFileViewFileDialog curselection]]
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label Properties 
# End Properties menu item
####################################
####################################
# Start Preview menu item
    $site_3_0.viewTypeButton.m add command -command {
		set MNS::FileDisplayType "Preview"
	} -label Preview 
# End Preview menu item
####################################
#####################################################
# Start Arrange submenu item
# No code here yet
    $site_3_0.viewTypeButton.m add separator 

    $site_3_0.viewTypeButton.m add cascade -menu "$site_3_0.viewTypeButton.m.men59" -label {Arrange Icons}
    vTcl:DefineAlias "$site_3_0.viewTypeButton.m.men59" "MenuButtonMenu2ViewFileDialog" vTcl:WidgetProc "Toplevel1" 1

    set site_5_0 $site_3_0.viewTypeButton.m

    menu $site_5_0.men59 -activebackground #f9f9f9 -activeforeground black -foreground black -tearoff 0
	$site_5_0.men59 add radiobutton -value 1 -variable arrangeIconsButton -command {# TODO: Your menu handler here} -label Name -state active
	$site_5_0.men59 add radiobutton -value 2 -variable arrangeIconsButton -command {# TODO: Your menu handler here} -label Type
	$site_5_0.men59 add radiobutton -value 3 -variable arrangeIconsButton -command {# TODO: Your menu handler here} -label Size 
	$site_5_0.men59 add radiobutton -value 4 -variable arrangeIconsButton -command {# TODO: Your menu handler here} -label Date 

# End Arrange submenu
#########################################

# End View Type Menu Button
#########################################################################    
#########################################################################
# Start Delete Button
# This code is the same as above.  Could maybe put into a single proc call in the future.
	button $site_3_0.deleteButton -borderwidth 0 -relief flat -highlightthickness 0 \
	-activebackground #f9f9f9 -activeforeground black -command {
		deleteFileDialog
	} -foreground black -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics remove.gif]] 
	vTcl:DefineAlias "$site_3_0.deleteButton" "ButtonDeleteFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.deleteButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.deleteButton "Delete"
# End Delete Button
#########################################################################
#########################################################################
# Start Paste Button
    button $site_3_0.pasteButton -borderwidth 0 -relief flat -highlightthickness 0 \
        -activebackground #f9f9f9 -activeforeground black -command {
		pasteFileDialog
	} -foreground black -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics editpaste.gif]]
	vTcl:DefineAlias "$site_3_0.pasteButton" "ButtonPasteFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.pasteButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.pasteButton "Paste"
# End Paste Button
#########################################################################
#########################################################################
# Start Cut Button
    button $site_3_0.cutButton -borderwidth 0 -relief flat -highlightthickness 0 \
        -activebackground #f9f9f9 -activeforeground black -command {
		.fileDialog.frameTop.pasteButton configure -state normal
		.fileDialog.fileDialogPopUp entryconfigure 5 -state  normal
		cutFileDialog
	} -foreground black -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics cut.gif]]
	vTcl:DefineAlias "$site_3_0.cutButton" "ButtonCutFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.cutButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.cutButton "Cut"
# End Cut Button
#########################################################################
#########################################################################
# Start Copy Button
    button $site_3_0.copyButton -borderwidth 0 -relief flat -highlightthickness 0 \
        -activebackground #f9f9f9 -activeforeground black -command {
		.fileDialog.frameTop.pasteButton configure -state normal
		.fileDialog.fileDialogPopUp entryconfigure 5 -state  normal
		copyFileDialog
	} -foreground black -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics editcopy.gif]]
	vTcl:DefineAlias "$site_3_0.copyButton" "ButtonCopyFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.copyButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.copyButton "Copy"
# End Copy Button
#########################################################################
#########################################################################
# Start New Directory Button
    button $site_3_0.newDirButton -activebackground #f9f9f9 -activeforeground black \
        -borderwidth 0 -relief flat -highlightthickness 0 -command {
	set newDirNameName {}
	Window show .newDirNameReq
	Window show .newDirNameReq
	widgetUpdate
	focus .newDirNameReq.entryNewDirName.lwchildsite.entry
	} -foreground black -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics folder_new.gif]]
	vTcl:DefineAlias "$site_3_0.newDirButton" "ButtonNewDirFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.newDirButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.newDirButton "New Directory"
# End New Directory Button
#########################################################################
#########################################################################
# Start Up Level Button
	button $site_3_0.upLevelButton -activebackground #f9f9f9 -activeforeground black \
	-borderwidth 0 -relief flat -highlightthickness 0 -command {
		set backLevelName $MNS::FullDirPath
		if {[expr [string last "/" $MNS::FullDirPath]] > 0} {
			set MNS::FullDirPath [string range $MNS::FullDirPath 0 [expr [string last "/" $MNS::FullDirPath] -1]]
		} else {
			set MNS::FullDirPath {/}
		}
# Replace the current with the new selected path
		ComboBoxUpLevelFileDialog delete entry 0 end
		ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
###################
# Run system cd command to go up a level
		cd $MNS::FullDirPath
###################################
# Redo the file list box
		redoFileDialogListBox
		if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initFileDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	 } -foreground black -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics pgaccess uplevel.gif]]
	vTcl:DefineAlias "$site_3_0.upLevelButton" "ButtonUpLevelFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.upLevelButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.upLevelButton "Up Level"
# End Up Level Button
#########################################################################
#########################################################################
# Start Back Level Button
	button $site_3_0.backLevelButton -activebackground #f9f9f9 -activeforeground black \
	-borderwidth 0 -relief flat -highlightthickness 0 -command {
		set backLevelNameTmp $MNS::FullDirPath
		set MNS::FullDirPath $backLevelName
		set backLevelName $backLevelNameTmp

###################
# Run system cd command to go up a level
		cd $MNS::FullDirPath
# Replace the current with the new selected path
		ComboBoxUpLevelFileDialog delete entry 0 end
		ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath

###################################
# Redo the file list box
		redoFileDialogListBox
		if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				initFileDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	 } -foreground black -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics back.gif]]
	vTcl:DefineAlias "$site_3_0.backLevelButton" "ButtonBackLevelFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.backLevelButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.backLevelButton "Back"
# End Back Level Button
#########################################################################
#########################################################################
# Start Up Level Combo Box

	::iwidgets::combobox $site_3_0.upLevelComboBox -command {namespace inscope ::iwidgets::Combobox {::.fileDialog.frameTop.upLevelComboBox _addToList}} \
	-selectioncommand {
		set backLevelName $MNS::FullDirPath
		set MNS::FullDirPath [ComboBoxUpLevelFileDialog getcurselection]
		if {[string length $MNS::FullDirPath] > 1} {append MNS::FullDirPath {/}}
		cd $MNS::FullDirPath
# Redo the listbox for the new directory
		redoFileDialogListBox
		if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				initFileDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	} -textbackground #fefefe -width 350
	vTcl:DefineAlias "$site_3_0.upLevelComboBox" "ComboBoxUpLevelFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.upLevelComboBox -in $site_3_0 -anchor w -expand 1 -fill none -side left
# End Up Level Combo Box Button
#########################################################################

	frame $top.frameTopMaster -height 280 -highlightcolor black -relief groove -width 400  -border 0
	vTcl:DefineAlias "$top.frameTopMaster" "FrameTopMasterFileDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.frameTopMaster

	::iwidgets::scrolledframe $site_3_0.frameLeft -background #999999 -height 599 -hscrollmode none \
	-vscrollmode dynamic -width 86
	vTcl:DefineAlias "$site_3_0.frameLeft" "ScrolledFrameLeftFileDialog" vTcl:WidgetProc "Toplevel1" 1
	set site_8_0 [$site_3_0.frameLeft childsite]
############################################################################3
# Buttons on the left frame side

	button $site_8_0.homeDirButton -activebackground #f9f9f9 -activeforeground black \
	-borderwidth 0 -relief flat -highlightthickness 0 -command {
		set backLevelName $MNS::FullDirPath
		set MNS::FullDirPath "/home/[exec whoami]"
# cd to the directory
		cd $MNS::FullDirPath
# Replace the current with the new selected path
		ComboBoxUpLevelFileDialog delete entry 0 end
		ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
# This one clears the listbox for the new directory
		redoFileDialogListBox
	} -foreground black -height 56 -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics folder_home.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.homeDirButton" "ButtonHomeDirFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.homeDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.homeDirButton "Home"

	button $site_8_0.desktopDirButton -activebackground #f9f9f9 -activeforeground black \
        -borderwidth 0 -relief flat -highlightthickness 0 -command {
		set backLevelName $MNS::FullDirPath
		set MNS::FullDirPath "/home/[exec whoami]"
		append MNS::FullDirPath {/Desktop}
# cd to the directory
		cd $MNS::FullDirPath
# Unable to get the unique property working.  This code
# prevents duplicates
		set duplicateTrigger 0
		foreach tmpvar $MNS::UpLevelComboBoxListVar {
                        	if {$MNS::FullDirPath == $tmpvar} {
				set duplicateTrigger 1
				break
			}
		}
		if {$duplicateTrigger == 0} {
# If not a duplicate then add the path to the combobox and sort it.
# Then clear the combobox and refresh it.
			set MNS::UpLevelComboBoxListVar [lsort [lappend MNS::UpLevelComboBoxListVar $MNS::FullDirPath]]
			ComboBoxUpLevelFileDialog clear
			foreach tmpvar $MNS::UpLevelComboBoxListVar {
				ComboBoxUpLevelFileDialog insert list end $tmpvar
			}
		}
# Replace the current with the new selected path
		ComboBoxUpLevelFileDialog delete entry 0 end
		ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
# This one clears the listbox for the new directory
		redoFileDialogListBox
		if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initFileDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	} -foreground black -height 56 -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics screen_green.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.desktopDirButton" "ButtonDesktopDirFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.desktopDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.desktopDirButton "Desktop"

	button $site_8_0.documentsDirButton -activebackground #f9f9f9 -activeforeground black \
	-borderwidth 0 -relief flat -highlightthickness 0 -command {
		set backLevelName $MNS::FullDirPath
		if {[file exist "\"/home/[exec whoami]\"/Documents"]} {
			set MNS::FullDirPath ""/home/[exec whoami]"/Documents"
		} else {
			set MNS::FullDirPath "/home/[exec whoami]"
		}
# cd to the directory
		cd $MNS::FullDirPath
# Unable to get the unique property working.  This code
# prevents duplicates
		set duplicateTrigger 0
		foreach tmpvar $MNS::UpLevelComboBoxListVar {
                        	if {$MNS::FullDirPath == $tmpvar} {
				set duplicateTrigger 1
				break
			}
		}
			if {$duplicateTrigger == 0} {
# If not a duplicate then add the path to the combobox and sort it.
# Then clear the combobox and refresh it.
			set MNS::UpLevelComboBoxListVar [lsort [lappend MNS::UpLevelComboBoxListVar $MNS::FullDirPath]]
			ComboBoxUpLevelFileDialog clear
			foreach tmpvar $MNS::UpLevelComboBoxListVar {
				ComboBoxUpLevelFileDialog insert list end $tmpvar
               		}
		}
# Replace the current with the new selected path
		ComboBoxUpLevelFileDialog delete entry 0 end
		ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
# This one clears the listbox for the new directory
		redoFileDialogListBox
		if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initFileDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	} -foreground black -height 56 -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics document.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.documentsDirButton" "ButtonDocumentsDirFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.documentsDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.documentsDirButton "Documents"

	button $site_8_0.floppyDirButton -borderwidth 0 -relief flat -command {
		set backLevelName $MNS::FullDirPath
		if {[file exists "/mnt/floppy"]} {
			set MNS::FullDirPath "/mnt/floppy"
# cd to the directory
			cd $MNS::FullDirPath
# Unable to get the unique property working.  This code
# prevents duplicates
			set duplicateTrigger 0
			foreach tmpvar $MNS::UpLevelComboBoxListVar {
					if {$MNS::FullDirPath == $tmpvar} {
					set duplicateTrigger 1
					break
				}
			}
			if {$duplicateTrigger == 0} {
# If not a duplicate then add the path to the combobox and sort it.
# Then clear the combobox and refresh it.
				set MNS::UpLevelComboBoxListVar [lsort [lappend MNS::UpLevelComboBoxListVar $MNS::FullDirPath]]
				ComboBoxUpLevelFileDialog clear
				foreach tmpvar $MNS::UpLevelComboBoxListVar {
					ComboBoxUpLevelFileDialog insert list end $tmpvar
				}
			}

# Replace the current with the new selected path
			ComboBoxUpLevelFileDialog delete entry 0 end
			ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
# This one clears the listbox for the new directory
			redoFileDialogListBox
			if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
				if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
					Window show .fileDialogProperties
					Window show .fileDialogProperties
					initFileDialogProperties
				}
				set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
				redoFileDialogProperties
				ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
			}
		} else {
			tk_messageBox -message "/mnt/floppy does not exist"
		}
	} -foreground black -height 56 -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics 3floppy_unmount.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.floppyDirButton" "ButtonFloppyDirFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.floppyDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.floppyDirButton "Floppy"

	button $site_8_0.cdromDirButton -borderwidth 0 -relief flat -highlightthickness 0 -command {
		set backLevelName $MNS::FullDirPath
		set MNS::FullDirPath "/media/cdrom"
		if {![file exist $MNS::FullDirPath]} {
			set MNS::FullDirPath "/mnt/cdrom"
		}
		if {[file exist $MNS::FullDirPath]} {
# cd to the directory
			cd $MNS::FullDirPath
# Unable to get the unique property working.  This code
# prevents duplicates
			set duplicateTrigger 0
			foreach tmpvar $MNS::UpLevelComboBoxListVar {
                	        	if {$MNS::FullDirPath == $tmpvar} {
					set duplicateTrigger 1
					break
				}
			}
			if {$duplicateTrigger == 0} {
# If not a duplicate then add the path to the combobox and sort it.
# Then clear the combobox and refresh it.
				set MNS::UpLevelComboBoxListVar [lsort [lappend MNS::UpLevelComboBoxListVar $MNS::FullDirPath]]
				ComboBoxUpLevelFileDialog clear
				foreach tmpvar $MNS::UpLevelComboBoxListVar {
					ComboBoxUpLevelFileDialog insert list end $tmpvar
        			}
			}
# Replace the current with the new selected path
			ComboBoxUpLevelFileDialog delete entry 0 end
			ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
# This one clears the listbox for the new directory
			redoFileDialogListBox
			if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
	       			if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
					Window show .fileDialogProperties
					Window show .fileDialogProperties
					initFileDialogProperties
				}
				set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
				redoFileDialogProperties
				ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
			}
		} else {
			set MNS::FullDirPath $backLevelName
		}
	} -foreground black -height 56 -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics cdrom_mount.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.cdromDirButton" "ButtonCDROMDirFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.cdromDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.cdromDirButton "CDROM"

	button $site_8_0.networkDirButton -activebackground #f9f9f9 -activeforeground black \
	-borderwidth 0 -relief flat -highlightthickness 0 -command {
		set backLevelName $MNS::FullDirPath
# Set to slash now but in future will point to a newtwork path
		set MNS::FullDirPath "lan://localhost/"
		if {[file exist $MNS::FullDirPath]} {
# cd to the directory
			cd $MNS::FullDirPath
# Unable to get the unique property working.  This code
# prevents duplicates
			set duplicateTrigger 0
			foreach tmpvar $MNS::UpLevelComboBoxListVar {
	                        	if {$MNS::FullDirPath == $tmpvar} {
					set duplicateTrigger 1
					break
				}
			}
			if {$duplicateTrigger == 0} {
# If not a duplicate then add the path to the combobox and sort it.
# Then clear the combobox and refresh it.
				set MNS::UpLevelComboBoxListVar [lsort [lappend MNS::UpLevelComboBoxListVar $MNS::FullDirPath]]
				ComboBoxUpLevelFileDialog clear
				foreach tmpvar $MNS::UpLevelComboBoxListVar {
					ComboBoxUpLevelFileDialog insert list end $tmpvar
				}
			}
# Replace the current with the new selected path
			ComboBoxUpLevelFileDialog delete entry 0 end
			ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
# This one clears the listbox for the new directory
			redoFileDialogListBox
			if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
				if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
					Window show .fileDialogProperties
					Window show .fileDialogProperties
					initFileDialogProperties
				}
				set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
				redoFileDialogProperties
				ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
			}
		} else {
			set MNS::FullDirPath $backLevelName
		}
	} -foreground black -height 56 -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics nfs_mount.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.networkDirButton" "ButtonNetworkDirFileDialog" vTcl:WidgetProc "Toplevel1" 1
	balloon $site_8_0.networkDirButton "Network"

	pack $site_8_0.networkDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	pack $site_3_0.frameLeft -in $site_3_0 -anchor nw -expand 1 -fill y -side left

# End Left Side Frame Buttons
##########################################################################################    

	frame $site_3_0.frameBottomMaster -height 24 -highlightcolor black -relief groove -width 430  -border 0
	vTcl:DefineAlias "$site_3_0.frameBottomMaster" "FrameBottomMasterFileDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.frameBottomMaster

	frame $site_4_0.frameBottomSub2 -height 40 -highlightcolor black -relief groove -width 430  -border 0
	vTcl:DefineAlias "$site_4_0.frameBottomSub2" "FrameBottomSub2FileDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_5_0 $site_4_0.frameBottomSub2

	label $site_5_0.fileTypeLabel -activebackground #f9f9f9 -activeforeground black -foreground black \
	-highlightcolor black -text {File Type:} 
	vTcl:DefineAlias "$site_5_0.fileTypeLabel" "LabelFileTypeFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_5_0.fileTypeLabel -in $site_5_0 -anchor nw -expand 1 -fill none -side left

	button $site_5_0.cancelButton -activebackground #f9f9f9 -activeforeground black -command {
# Window destroy .fileDialog
		set MNS::ReturnFileName ""
		set MNS::ReturnFilePath ""
		set MNS::ReturnFullPath ""
		set MNS:FileDialogOk "Cancel"
		if {[winfo exist .fileDialogProperties]} {destroy .fileDialogProperties}
		if {[winfo exist .newDirNameReq]} {destroy .newDirNameReq}
		if {[winfo exist .MNS::FileRename]} {destroy .MNS::FileRename}
		destroy window .fileDialog
	} -foreground black -highlightcolor black -text Cancel -width 10 
	vTcl:DefineAlias "$site_5_0.cancelButton" "ButtonCancelFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_5_0.cancelButton -in $site_5_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_5_0.cancelButton "Cancel"

    ::iwidgets::combobox $site_5_0.fileTypeComboBox \
	-command {namespace inscope ::iwidgets::Combobox {::.fileDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox _addToList}} \
        -selectioncommand {
########################################################################################
# File type filter selection	
		set fileSelectType [.fileDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox get]
		if {[string last "*" $fileSelectType] == [expr [string length $fileSelectType] -1]} {
			set MNS::SelectFileType {*}
		} else {
			set MNS::SelectFileType [string range $fileSelectType [expr [string length $fileSelectType] - 4] [expr [string length $fileSelectType] - 1]]
		}
		redoFileDialogListBox
	} -textbackground #fefefe -width 217
	vTcl:DefineAlias "$site_5_0.fileTypeComboBox" "ComboBoxFileTypeFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_5_0.fileTypeComboBox -in $site_5_0 -anchor nw -expand 1 -fill none -side left


	frame $site_4_0.frameBottomSub1 -height 40 -highlightcolor black -relief groove -width 430  -border 0
	vTcl:DefineAlias "$site_4_0.frameBottomSub1" "FrameBottomSub1FileDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_5_0 $site_4_0.frameBottomSub1

	label $site_5_0.fileNameLabel -activebackground #f9f9f9 -activeforeground black -foreground black \
	-highlightcolor black -text {File Name:} 
	pack $site_5_0.fileNameLabel -in $site_5_0 -anchor nw -expand 1 -fill none -side left
	vTcl:DefineAlias "$site_5_0.fileNameLabel" "LabelFileNameFileDialog" vTcl:WidgetProc "Toplevel1" 1
###############################################################
# Start Open Button
# This would need customized for a return of the filename to the calling procedure    
	button $site_5_0.openButton -activebackground #f9f9f9 -activeforeground black -command {
		global MNS::ReturnFileName MNS::ReturnFilePath
		if {[EntryFileNameFileDialog get] != ""} {
			
			set MNS::ReturnFileName [EntryFileNameFileDialog get]
			set MNS::ReturnFilePath [ComboBoxUpLevelFileDialog get]
#			set returnPath [ComboBoxUpLevelFileDialog get]
			set MNS::ReturnFullPath $MNS::ReturnFilePath
			append MNS::ReturnFullPath "/" $MNS::ReturnFileName
			set MNS:FileDialogOk "Ok"
			destroy window .fileDialog
		}
	} -foreground black -height 26 -highlightcolor black \
	-image [vTcl:image:get_image [file join / usr local  PgTCLScales Pics open.gif]] -width 92
	vTcl:DefineAlias "$site_5_0.openButton" "ButtonOpenFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_5_0.openButton -in $site_5_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_5_0.openButton $MNS::ToolTip
# End Open Button
###############################################################
###############################################################
# Start File Name Entry
	entry $site_5_0.fileNameEntry -background white -foreground black -highlightcolor black -insertbackground black \
	 -selectbackground #c4c4c4 -selectforeground black -textvariable "$top\::filenameentry" -width 233 
	vTcl:DefineAlias "$site_5_0.fileNameEntry" "EntryFileNameFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_5_0.fileNameEntry -in $site_5_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_5_0.fileNameEntry "File Entry Box"
	bind $site_5_0.fileNameEntry <Key-Return> {
		if {[EntryFileNameFileDialog get] != ""} {
			set MNS::ReturnFileName [EntryFileNameFileDialog get]
			set MNS::ReturnFilePath [ComboBoxUpLevelFileDialog get]
			set MNS::ReturnFullPath $MNS::ReturnFilePath
			append MNS::ReturnFullPath "/" $MNS::ReturnFileName
			set MNS:FileDialogOk "Ok"
			destroy window .fileDialog
		}
	}
	bind $site_5_0.fileNameEntry <Key-KP_Enter> {
		if {[EntryFileNameFileDialog get] != ""} {
			set MNS::ReturnFileName [EntryFileNameFileDialog get]
			set MNS::ReturnFilePath [ComboBoxUpLevelFileDialog get]
#			set returnPath [ComboBoxUpLevelFileDialog get]
			set MNS::ReturnFullPath $MNS::ReturnFilePath
			append MNS::ReturnFullPath "/" $MNS::ReturnFileName
			set MNS:FileDialogOk "Ok"
			destroy window .fileDialog
		}
	}
# End File Name Entry Box
###############################################################
	pack $site_4_0.frameBottomSub2 -in $site_4_0 -anchor nw -expand 0 -fill both -side bottom 
	pack $site_4_0.frameBottomSub1 -in $site_4_0 -anchor nw -expand 0 -fill both -side bottom 

	frame $site_3_0.frameFileView -height 205 -highlightcolor black -relief groove -width 413  -border 0
	vTcl:DefineAlias "$site_3_0.frameFileView" "FrameFileViewFileDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.frameFileView

#################################################################
#################################################################
#################################################################
# Start List Box

	::iwidgets::scrolledlistbox $site_4_0.fileViewListBox -selectmode extended -dblclickcommand {
		set MNS::SelectionIndexList [ScrolledListBoxFileViewFileDialog curselection]
		set MNS::DirPath [ScrolledListBoxFileViewFileDialog get $MNS::SelectionIndexList] 
# If file display type is details the strip of the beginning and ending curly brace if present
		if {$MNS::FileDisplayType=="Details" || $MNS::FileDisplayType=="Properties"} {
			if {[string index $MNS::DirPath 0] == "\{"} {
				set MNS::DirPath [string trim [string range $MNS::DirPath 1 54]]
			} else {
				set MNS::DirPath [string trim [string range $MNS::DirPath 0 53]]
			}
		}
		if {[file isdirectory $MNS::DirPath]} {
			set backLevelName $MNS::FullDirPath
#################################
# This next "if" statement is a hack work around for a problem of somehow getting double slashes
# in the path.  this strips and trims them out.
			if {[string last "//" $MNS::FullDirPath] >0} {set MNS::FullDirPath [string range $MNS::FullDirPath 0 [expr [string last "//" $MNS::FullDirPath]] -1]}
			if {[string length $MNS::FullDirPath] > 1} {
				append MNS::FullDirPath {/}
			}
#################################
# This next "if" statement is a hack work around for a problem of somehow getting double slashes
# in the path.  this strips and trims them out.
			if {[string last "//" $MNS::FullDirPath] >0} {set MNS::FullDirPath [string range $MNS::FullDirPath 0 [string last "//" $MNS::FullDirPath]]}
			append MNS::FullDirPath $MNS::DirPath
			cd $MNS::FullDirPath
# Add the directory to the list
# Unable to get the unique property working.  This code
# prevents duplicates
			set duplicateTrigger 0
			foreach tmpvar $MNS::UpLevelComboBoxListVar {
                         	if {$MNS::FullDirPath == $tmpvar} {
					set duplicateTrigger 1
					break
				}
			}
			if {$duplicateTrigger == 0} {
# If not a duplicate then add the path to the combobox and sort it.
# Then clear the combobox and refresh it.
				set MNS::UpLevelComboBoxListVar [lsort [lappend MNS::UpLevelComboBoxListVar $MNS::FullDirPath]]
				ComboBoxUpLevelFileDialog clear
				foreach tmpvar $MNS::UpLevelComboBoxListVar {ComboBoxUpLevelFileDialog insert list end $tmpvar}
			}
# Replace the current with the new selected path
			ComboBoxUpLevelFileDialog delete entry 0 end
			ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath

# This one clears the listbox for the new directory
			redoFileDialogListBox
			if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
		       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
					Window show .fileDialogProperties
					Window show .fileDialogProperties
					initFileDialogProperties
				}
				set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
				redoFileDialogProperties
				ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
			}
		}
# Doouble Click on a file. This selects that file and closes the file dialog.
		if {[file isfile "$MNS::DirPath"]} {
			set MNS::ReturnFileName [EntryFileNameFileDialog get]
			set MNS::ReturnFilePath [ComboBoxUpLevelFileDialog get]
#			set returnPath [ComboBoxUpLevelFileDialog get]
			set MNS::ReturnFullPath $MNS::ReturnFilePath
			append MNS::ReturnFullPath "/" $MNS::ReturnFileName
			set MNS:FileDialogOk "Ok"
			destroy window .fileDialog
		}
	} -height 215 -hscrollmode dynamic -selectioncommand {
# Place clicked (selected)  file in entry box 
		set MNS::DirPath [ScrolledListBoxFileViewFileDialog getcurselection]
		if {$MNS::FileDisplayType=="Details"} {
			if {[string index $MNS::DirPath 0] == "\{"} {
				set MNS::DirPath [string trim [string range $MNS::DirPath 1 54]]
			} else {
				set MNS::DirPath [string trim [string range $MNS::DirPath 0 53]]
			}
		}
# The extra condition of checking for a null MNS::DirPath is needed to prevent an error when double clicked
		if {[file isfile $MNS::DirPath]} {
# Delete what is in there now
			EntryFileNameFileDialog delete 0 end
# Replace with the clicked (selected) file
			EntryFileNameFileDialog insert end [string range $MNS::DirPath [expr [string last  "/" $MNS::DirPath ] +1] end]
#			EntryFileNameFileDialog insert end $MNS::DirPath
		}
		if {$MNS::FileDisplayType=="Properties"} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initFileDialogProperties
			}
			set MNS::DirPathProperty $MNS::DirPath
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			foreach reFocusSelectionTmp $reFocusSelection {
				redoFileDialogProperties
				ScrolledListBoxFileViewFileDialog selection set [lindex $reFocusSelection 0] $reFocusSelectionTmp
			}
		}
	} -textbackground #fefefe -vscrollmode dynamic -width 530 
	vTcl:DefineAlias "$site_4_0.fileViewListBox" "ScrolledListBoxFileViewFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.fileViewListBox -in $site_4_0 -anchor nw -expand 1 -fill both -side bottom 
# End List Box
#################################################################
#################################################################
#################################################################
	pack $site_3_0.frameBottomMaster -in $site_3_0 -anchor nw -expand 0 -fill y -side bottom 
	pack $site_3_0.frameFileView -in $site_3_0 -anchor nw -expand 1 -fill both -side bottom 
#################################################################
#################################################################
#################################################################
# Start Pop Up Menu
#
# This code is also above and in the future maybe consolidated in a single proc for
# each command

	menu $top.fileDialogPopUp -activebackground #f9f9f9 -activeforeground black -background #d9d9d9 \
	-borderwidth 2 -cursor arrow -disabledforeground #a3a3a3 -foreground black -relief raised -selectcolor #b03060 -tearoff 0

	$top.fileDialogPopUp add command -command {
		set backLevelNameTmp $MNS::FullDirPath
		set MNS::FullDirPath $backLevelName
		set backLevelName $backLevelNameTmp
###################
# Run system cd command to go up a level
		cd $MNS::FullDirPath
# Replace the current with the new selected path
		ComboBoxUpLevelFileDialog delete entry 0 end
		ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
###################################
# Redo the file list box
		redoFileDialogListBox
		if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				initFileDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label Back

	$top.fileDialogPopUp add command -command {
		set backLevelName $MNS::FullDirPath
		if {[expr [string last "/" $MNS::FullDirPath]] > 0} {
			set MNS::FullDirPath [string range $MNS::FullDirPath 0 [expr [string last "/" $MNS::FullDirPath] -1]]
		} else {
			set MNS::FullDirPath {/}
		}
# Replace the current with the new selected path
		ComboBoxUpLevelFileDialog delete entry 0 end
		ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
###################
# Run system cd command to go up a level
		cd $MNS::FullDirPath
###################################
# Redo the file list box
		redoFileDialogListBox
		if {$MNS::FileDisplayType=="Properties" && $MNS::FileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				initFileDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label {Up Level}

	$top.fileDialogPopUp add command -command {
		global MNS::PPref
		global newDirNameName
		set newDirNameName {}
		Window show .newDirNameReq
		widgetUpdate
		focus .newDirNameReq.entryNewDirName.lwchildsite.entry
	} -label {New Directory}

	$top.fileDialogPopUp add command -command {
		.fileDialog.frameTop.pasteButton configure -state normal
		.fileDialog.fileDialogPopUp entryconfigure 5 -state  normal
		copyFileDialog
	} -label Copy

	$top.fileDialogPopUp add command -command {
		.fileDialog.frameTop.pasteButton configure -state normal
		.fileDialog.fileDialogPopUp entryconfigure 5 -state  normal
		cutFileDialog
	} -label Cut

	$top.fileDialogPopUp add command -command {
		pasteFileDialog
	} -label Paste


	$top.fileDialogPopUp add command -command {
		renameFileDialog
	} -label Rename

	$top.fileDialogPopUp add command -command {
		deleteFileDialog
	} -label Delete

	$top.fileDialogPopUp add command \
        -command {
		set MNS::FileDisplayType {Properties}
		if {![winfo exist .fileDialogProperties]} {
			Window show .fileDialogProperties
			Window show .fileDialogProperties
			initFileDialogProperties
		}
		redoFileDialogListBox
		if {$MNS::FileNameList !=""} {
		    	set MNS::DirPathProperty [ScrolledListBoxFileViewFileDialog get [ScrolledListBoxFileViewFileDialog curselection] [ScrolledListBoxFileViewFileDialog curselection]]
			set reFocusSelection [ScrolledListBoxFileViewFileDialog curselection]
			redoFileDialogProperties
			ScrolledListBoxFileViewFileDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label Properties
# End Pop Up Menu
#################################################################
#################################################################
#################################################################

    ###################
    # SETTING GEOMETRY
    ###################
    pack $top.frameTop -in $top -anchor nw -expand 0 -fill none -side top
    pack $top.frameTopMaster -in $top -anchor nw -expand 1 -fill both -side top

    vTcl:FireEvent $base <<Ready>>
}

##########################################################################################
##########################################################################################
# Start Bookmark Dialog Box

proc vTclWindow.fileDialogBookmarkTitle {base} {
	if {$base == ""} {set base .fileDialogBookmarkTitle}
	if {[winfo exists $base]} {
		wm deiconify $base; return
	}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel
	wm focusmodel $top passive
	wm geometry $top 387x101+481+416; update
	wm maxsize $top 1265 994
	wm minsize $top 1 1
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm deiconify $top
	wm title $top "Edit Bookmark..."
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {destroy window .fileDialogBookmarkTitle}

	::iwidgets::entryfield $top.fileDialogBookmarkTitleEntry -command {
		saveBookmark
	} -labeltext "Bookmark Title" -textbackground #fefefe
	vTcl:DefineAlias "$top.fileDialogBookmarkTitleEntry" "EntryBookmarkTitleFileDialog" vTcl:WidgetProc "Toplevel1" 1
	bind $top.fileDialogBookmarkTitleEntry <Key-KP_Enter> {saveBookmark}
	bind $top.fileDialogBookmarkTitleEntry <Key-Return> {saveBookmark}

	::iwidgets::entryfield $top.fileDialogBookmarkPathEntry -command {
		saveBookmark
	} -labeltext "Bookmark Path" -textbackground #fefefe
	vTcl:DefineAlias "$top.fileDialogBookmarkPathEntry" "EntryBookmarkPathFileDialog" vTcl:WidgetProc "Toplevel1" 1
	bind $top.fileDialogBookmarkPathEntry <Key-KP_Enter> {saveBookmark}
	bind $top.fileDialogBookmarkPathEntry <Key-Return> {saveBookmark}

	::iwidgets::buttonbox $top.fileDialogBookmarkButtonBox -padx 0 -pady 0
	vTcl:DefineAlias "$top.fileDialogBookmarkButtonBox" "ButtonBoxBookmarksFileDialog" vTcl:WidgetProc "Toplevel1" 1

	$top.fileDialogBookmarkButtonBox add but0 -command {saveBookmark} -text Save

	$top.fileDialogBookmarkButtonBox add but1 -command {destroy window .fileDialogBookmarkTitle} -text "Cancel"

	$top.fileDialogBookmarkButtonBox add but2 -command {} -text Help
###################
# SETTING GEOMETRY
###################
    place $top.fileDialogBookmarkTitleEntry -x 15 -y 5 -width 365 -height 22 -anchor nw -bordermode ignore
    place $top.fileDialogBookmarkPathEntry -x 15 -y 30 -width 358 -height 22 -anchor nw -bordermode ignore
    place $top.fileDialogBookmarkButtonBox -x 5 -y 55 -width 378 -height 38 -anchor nw -bordermode ignore

    vTcl:FireEvent $base <<Ready>>
}
# End Bookmark Dialog Box
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
##########################################################################################
## Start Procedure:  initFileDialog

proc ::initFileDialog {} {
# This code initializes the file dialog box.  There are variables for adjust the background,
# foreground, textbackground, textforeground directory name and file name.  Setting the cut and copy
# triggers to 0 prohibit a past action unless there are selected files and cut or copy has been
# selected.

#####################
# Initalize Defaults
	set fileCopy {}
	set fileCut {}
	set filePaste {}
	set MNS::FileDisplayType "List"
	set MNS::FileCutTrigger 0
	set MNS::FileCopyTrigger 0
#tk_messageBox -message "Init Filedialog $MNS::FullDirPath"
	set backLevelName $MNS::FullDirPath
	set MNS::SelectFileType {*}
	set MNS::DirPath {}
#	set MNS::FileSelectTypeList [list "/" "/usr/local" "/mnt" "/opt/FreeFactory" "/home" "/home/[exec whoami]"]
#tk_messageBox -message "Init Filedialog $MNS::FileSelectTypeList"

####################################################################
# This is not a mistake !!!  There is a problem somewhere in this code or TCL/TK
# causes an error during widget reconfigure on the file dialog when it is
# revisited after the window has been previously "x" out of.  Also there is
# a focus problem that this also clears up.  Repeated openings/closings resulted
# in the window not allways getting the focus.  This increases that.
#
#####################################################################
###################
# Configure widgets to user preferences
	set MNS::PassConfig "FileDialog"
	widgetUpdate
	
######
# Try to make it smart enough to disable the menu option if not supported
# on the computer.
# Checking for Konqueror
	set konquerorbookmark "/home/[exec whoami]"
	append konquerorbookmark {/.kde/share/apps/konqueror/bookmarks.xml}
	if {![file exist $konquerorbookmark]} {
		MenuButtonMenu2ToolFileDialog entryconfigure 0 -state  disable
	}
 # Checking for Mozilla
	set mozillabookmarkdefault  "/home/[exec whoami]"
	set mozillabookmarkuser  "/home/[exec whoami]"
	append mozillabookmarkdefault {/.mozilla/default/}
	append mozillabookmarkuser {/.mozilla/} [string range "/home/[exec whoami]" [expr [string last {/} "/home/[exec whoami]"] +1] end] {/}
	append mozillabookmarkdefault  [file tail [glob -nocomplain -directory $mozillabookmarkdefault *.slt]] {/bookmarks.html}
	append mozillabookmarkuser [file tail [glob -nocomplain -directory $mozillabookmarkuser *.slt]] {/bookmarks.html}
	if {![file exist $mozillabookmarkdefault] && ![file exist $mozillabookmarkuser]} {
		MenuButtonMenu2ToolFileDialog entryconfigure 2 -state  disable
	}
###########
# Disable Nautilus for now.  Not able to keep bookmarks
# Nautilus unable to read its own saved bookmarks on program restart
#
# Checking for Nautilus
#	set nautilusbookmark "/home/[exec whoami]"
#	append nautilusbookmark {/.nautilus/bookmarks.xml}
#	if {![file exist $nautilusbookmark]} {
 		MenuButtonMenu2ToolFileDialog entryconfigure 3 -state  disable
#	}
#############
# Checking for Galeon
	set galeonbookmark "/home/[exec whoami]"
	append galeonbookmark {/.galeon/bookmarks.xbel}
	if {![file exist $galeonbookmark]} {MenuButtonMenu2ToolFileDialog entryconfigure 4 -state  disable}

#############
# Checking for Netscape
	set netscapebookmark "/home/[exec whoami]"
	append netscapebookmark {/.netscape/bookmarks.html}
	if {![file exist $netscapebookmark]} {MenuButtonMenu2ToolFileDialog entryconfigure 1 -state  disable}

#############
# Checking for Opera
	set operabookmark "/home/[exec whoami]"
	append operabookmark {/.opera/opera6.adr}
	if {![file exist $netscapebookmark]} {MenuButtonMenu2ToolFileDialog entryconfigure 5 -state  disable}
#############################
# Attempting to redo the tool tip to fit the type of dialog action, open, save, import or export.
# it seems once it is set it won't change.  Also code in the before the call the this
# routine.  The code there is commented out. The MNS::ToolTip variable is set there for each action.
	balloon .fileDialog.frameTopMaster.frameBottomMaster.frameBottomSub1.openButton  $MNS::ToolTip
	.fileDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.cancelButton configure -foreground $MNS::PPref(PPref,color,window,fore) -background $MNS::PPref(PPref,color,window,back) -font $MNS::PPref(PPref,fonts,label)  -activeforeground $MNS::PPref(PPref,color,active,fore) -activebackground $MNS::PPref(PPref,color,active,back) 
	wm title .fileDialog $MNS::WindowName

# cd to the directory
# tk_messageBox -message $MNS::FullDirPath

	cd $MNS::FullDirPath
	
	.fileDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox clear


	foreach selectTypeList $MNS::FileSelectTypeList {
		set selectTypeList2 [lindex $selectTypeList 0]
		append selectTypeList2 { } [lindex $selectTypeList 1]
		set selectTypeList $selectTypeList2
		.fileDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox  insert list end $selectTypeList
	}
# Here is where we load up the top combobox with the initial paths
	set MNS::UpLevelComboBoxListVar {}
	lappend MNS::UpLevelComboBoxListVar {/} {/home} "/home/[exec whoami]" $MNS::FullDirPath {/mnt}
	ComboBoxUpLevelFileDialog clear
	 foreach tmpvar $MNS::UpLevelComboBoxListVar {ComboBoxUpLevelFileDialog insert list end $tmpvar}
	ComboBoxUpLevelFileDialog delete entry 0 end
	ComboBoxUpLevelFileDialog insert entry end $MNS::FullDirPath
	.fileDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox delete entry 0 end
	.fileDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox insert entry end {All files *}

# Disable paste function until something is selected to paste
	.fileDialog.frameTop.pasteButton configure -state disable
	.fileDialog.fileDialogPopUp entryconfigure 5 -state disable

#######################################################################################
# Display the dialog
# The following code doesn't seem to work.  No errors but it doesn't seem to always
# receive focus.
	redoFileDialogListBox
	focus .fileDialog.frameTopMaster.frameBottomMaster.frameBottomSub1.fileNameEntry
	if {$MNS::PPref(PPref,SelectAllText) == "Yes"} {EntryFileNameFileDialog select range 0 end}
	EntryFileNameFileDialog icursor end
}
## End Procedure:  initFileDialog
########################################################################################
#############################################################################
## Procedure:  redoFileDialogListBox

proc ::redoFileDialogListBox {} {
#This clears and refills the listbox for all actions

	set directoryNameList {}
	set MNS::FileNameList {}
# Get everything once and filter in the loop	Previous method looped twice once for the dirs and then
# the files.  Had to do this for the filter of file types.  You always want to display the dirs and only
# filter the files.  The filter in "glob" also eliminated dirs without .ext in the name matching the filter.
# Trading a few extra cpu cycles for disk access time which I believe speeds things up.  What we are doing
# is looping through a glob list and running the file command with different options on the dir or file name.
	foreach item [lsort [glob -nocomplain *]] {
		if {$MNS::SelectFileType == "*" || [file extension $item] == $MNS::SelectFileType || [file isdirectory $item]} {
			if {$MNS::FileDisplayType == "Details"} {
				set fileSize [string trim [file size $item]]
				set MNS::ItemFileName $item
				set fileSizeLength [string length $fileSize]
				set x [expr $fileSizeLength-1]
				set MNS::FileLinkPath {}
##########################################
# Start section - Insert the "," in as a thousand separator in file size
				if {$fileSizeLength>3} {
					set outstring {,}
					set loopCount 0
				} else {
					set outstring $fileSize
				}
				while {$x>2}  {
					set outstring1 [string range $fileSize [expr $x-2] $x]
					if {$loopCount == 0} {
						set loopCount 1
						append outstring $outstring1
					} else {
						set outstring2 {,}
						append  outstring2 $outstring1 $outstring
						set outstring $outstring2
					}
					incr x -3
				}
				if {$fileSizeLength>3} {
					set outstring1 [string range $fileSize 0 $x]
					append outstring1 $outstring
					set fileSize $outstring1
				} else {
					set fileSize $outstring
				}
# End section - Insert the "," in as a thousand separator in file size
#######################################################
#######################################################
# Start permissions conversion from number to letters
# Most of the variable name should be self explanatory
				if {[file type $item] == "link"} {
					set filePermissions [string replace $filePermissions 0 0 "l"]
					set MNS::FileLinkPath [file readlink $item]
				}
				set filePermissionsNumber [file attributes  $item -permissions]
 				set preFileAttributes [string range $filePermissionsNumber 0 [expr [string length $filePermissionsNumber] -4] ]
 				set filePermissions {-}
				if {$preFileAttributes == "040"} {
					set filePermissions [string replace $filePermissions 0 0 "d"]
				}
				set filePermissionsNumber [string range $filePermissionsNumber [expr [string length $filePermissionsNumber] -3]  end]
				foreach filePermissionsNumber2 [split $filePermissionsNumber {}] {
					switch $filePermissionsNumber2 {
						7 {append filePermissions {rwx}}
						6 {append filePermissions {rw-}}
						5 {append filePermissions {r-x}}
						4 {append filePermissions {r--}}
						3 {append filePermissions {-wx}}
						2 {append filePermissions {-w-}}
						1 {append filePermissions {--x}}
						0 {append filePermissions {---}}
					}
				}
# Check for Suid
				if {$preFileAttributes == "04"} {set filePermissions [string replace $filePermissions 3 3 "S"]}
# Check For Guid				
				if {$preFileAttributes == "02"} {set filePermissions [string replace $filePermissions 6 6 "S"]}
# Check For Sticky
				if {$preFileAttributes == "01"} {set filePermissions [string replace $filePermissions 9 9 "T"]}

# End permissions conversion from number to letters
#######################################################
				set fileTimeModified [clock format [file mtime $item]]
				set fileGroup [file attributes $item -group]
				set fileOwner [file attributes $item -owner]
############################################################################
# Start assembling the line to display in the listbox for details type list

				set MNS::ItemFileName [format "%-55s %s   %s   %s     %s%s%s   %s" $MNS::ItemFileName $fileSize $filePermissions $fileTimeModified $fileGroup ":"  $fileOwner $MNS::FileLinkPath]
# End assembling the line to display in the listbox for details type lis
#############################################################################
			}
###########################################
###########################################
# Display in list format
			if {$MNS::FileDisplayType == "List" || $MNS::FileDisplayType=="Properties" || $MNS::FileDisplayType=="Preview"} {set MNS::ItemFileName $item}
			if {[file isdirectory $item]} {
				lappend directoryNameList $MNS::ItemFileName
			} else {
				lappend MNS::FileNameList $MNS::ItemFileName
			}
		}
	}
	ScrolledListBoxFileViewFileDialog clear
# Count the directories and use that number for the first file selection in the listbox.  Since
# the listbox uses zero offset for elements The number of directories will point to the first
# file in the file list
	set MNS::DirectoryCount 0
#	ScrolledListBoxFileViewFileDialog configure -foreground $MNS::PPref(PPref,color,directory)
	foreach MNS::ItemFileName $directoryNameList {
#Put the display item in the correct list variable - directory or file
# Fill the list box with directories first
		ScrolledListBoxFileViewFileDialog insert end $MNS::ItemFileName
		incr MNS::DirectoryCount
	}
#####################################
# Fill the list box with files next
	foreach MNS::ItemFileName $MNS::FileNameList {
		ScrolledListBoxFileViewFileDialog insert end $MNS::ItemFileName
	}
# This condition statement provides automatic selection of the first file in a directory on display	
	if {$MNS::FileNameList !=""} {
		ScrolledListBoxFileViewFileDialog selection set $MNS::DirectoryCount $MNS::DirectoryCount
# Delete what is in there now			
		EntryFileNameFileDialog delete 0 end
# Replace with the clicked (selected) file			
		set displayFile [ScrolledListBoxFileViewFileDialog get $MNS::DirectoryCount $MNS::DirectoryCount]
		if {$MNS::FileDisplayType=="Details" || $MNS::FileDisplayType=="Properties"} {
			if {[string index $displayFile 0] == "\{"} {
				set displayFile [string trim [string range $displayFile 1 54]]
			} else {
				set displayFile [string trim [string range $displayFile 0 53]]
			}
		}
		
			EntryFileNameFileDialog insert end [string range $displayFile [expr [string last  "/" $displayFile ] +1] end]
#		EntryFileNameFileDialog insert end $displayFile
		if {$MNS::FileDisplayType=="Properties"} {
		    set MNS::DirPathProperty [ScrolledListBoxFileViewFileDialog get $MNS::DirectoryCount $MNS::DirectoryCount]
		}
	}
# Set color for files in the listbox.
	ScrolledListBoxFileViewFileDialog configure -foreground $MNS::PPref(PPref,color,file)
# Change the color to blue for direcories
	if {$MNS::DirectoryCount > 0} {
		for {set x 0} {$x < $MNS::DirectoryCount} {incr x} {
			ScrolledListBoxFileViewFileDialog itemconfigure $x -foreground $MNS::PPref(PPref,color,directory)
		}
	}
}
## End redoFileDialogListBox
#############################################################################
#############################################################################
## Procedure:  redoFileDialogProperties

proc ::redoFileDialogProperties {} {
# This allows editing of directory or file permissions, file owner and group.  The
# apply button is ghosted until something is changed.

	foreach MNS::DirPathPropertyTmp $MNS::DirPathProperty {
# if there are any list separators left in the name strip them out
		if {[string first "\{" $MNS::DirPathPropertyTmp] == 0 && [string first "\}" $MNS::DirPathPropertyTmp] == -1  } {set MNS::DirPathPropertyTmp [string range $MNS::DirPathPropertyTmp 1 end]}
# Get file size
		set fileSize [string trim [file size $MNS::DirPathPropertyTmp]]
		set fileSizeLength [string length $fileSize]
		set x [expr $fileSizeLength-1]
##########################################
# Start section - Insert the "," in as a thousand separator in file size
		if {$fileSizeLength>3} {
			set outstring {,}
			set loopCount 0
		} else {
			set outstring $fileSize
		}
		while {$x>2}  {
			set outstring1 [string range $fileSize [expr $x-2] $x]
			if {$loopCount == 0} {
				set loopCount 1
				append outstring $outstring1
			} else {
				set outstring2 {,}
				append  outstring2 $outstring1 $outstring
				set outstring $outstring2
			}
			incr x -3
		}
		if {$fileSizeLength>3} {
			set outstring1 [string range $fileSize 0 $x]
			append outstring1 $outstring
			set fileSize $outstring1
		} else {
			set fileSize $outstring
		}
# End section - Insert the "," in as a thousand separator in file size
#######################################################
#######################################################
# Start permissions conversion from number to letters
# Most of the variable name should be self explanatory
		set fileTypeProperty [file type $MNS::DirPathPropertyTmp]
		set fileTimeModified [clock format [file mtime $MNS::DirPathPropertyTmp]]
		set fileTimeAccessed [clock format [file atime $MNS::DirPathPropertyTmp]]
		set fileGroup [file attributes $MNS::DirPathPropertyTmp -group]
		set fileOwner [file attributes $MNS::DirPathPropertyTmp -owner]
		set filePathType [file pathtype $MNS::DirPathPropertyTmp]
		if {$fileTypeProperty == "link"} {append fileTypeProperty " to: " [file readlink $MNS::DirPathPropertyTmp]}
		append filePathType { to: } $MNS::FullDirPath
		set fileNativeName [file nativename $MNS::DirPathPropertyTmp]
		set fullFilePath $MNS::FullDirPath
		if {$MNS::FullDirPath == "/"} {
			append fullFilePath $MNS::DirPathPropertyTmp
		} else {
			append fullFilePath {/} $MNS::DirPathPropertyTmp
		}
		set filePermissionsNumber {}
		set filePermissions {}
		set MNS::NoChangesPermissions 0
		set MNS::NoChangesOwnerGroup 0
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state disable
		set fileAttributes [file attributes  $MNS::DirPathPropertyTmp -permissions]
		set preFileAttributes [string range $fileAttributes 0 [expr [string length $fileAttributes] -4] ]
# Check for Suid
		if {$preFileAttributes == "04"} {
			.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertySuidCheckButton select
		} else {
			.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertySuidCheckButton deselect
		}
# Check For Guid
		if {$preFileAttributes == "02"} {
			.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGuidCheckButton select
		} else {
			.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGuidCheckButton deselect
		}
# Check For Sticky
		if {$preFileAttributes == "01"} {
			.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyStickyCheckButton select
		} else {
			.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyStickyCheckButton deselect
		}
		set fileAttributes [string range $fileAttributes [expr [string length $fileAttributes] -3]  end]
		set ownerPermissions [string range $fileAttributes  0 0]
		set groupPermissions [string range $fileAttributes  1 1]
		set otherPermissions [string range $fileAttributes  2 2]
		lappend filePermissionsNumber $ownerPermissions $groupPermissions $otherPermissions
		set whichPermissions 0
		foreach filePermissionsNumber2 $filePermissionsNumber {
# This code sets the buttons
			switch $whichPermissions {
				2 {
					switch $filePermissionsNumber2 {
						7 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherExecuteCheckButton select
						}
						6 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherExecuteCheckButton deselect
						}
						5 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherExecuteCheckButton select
						}
						4 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherExecuteCheckButton deselect
						}
						3 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherExecuteCheckButton select
						}
						2 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherExecuteCheckButton deselect
						}
						1 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherExecuteCheckButton select
						}
						0 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOtherExecuteCheckButton deselect
						}
        				}
				}
				1 {
					switch $filePermissionsNumber2 {
				
						7 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupExecuteCheckButton select
						}
						6 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupExecuteCheckButton deselect
						}
						5 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupExecuteCheckButton select
						}
						4 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupExecuteCheckButton deselect
				
						}
						3 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupExecuteCheckButton select
						}
						2 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupExecuteCheckButton deselect
						}
						1 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupExecuteCheckButton select
						}
						0 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupExecuteCheckButton deselect
						}
					}
				}
				0 {
					switch $filePermissionsNumber2 {
						7 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerExecuteCheckButton select
						}
						6 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerExecuteCheckButton deselect
						}
						5 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerExecuteCheckButton select
						}
						4 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerReadCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerExecuteCheckButton deselect
						}
						3 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerExecuteCheckButton select
						}
						2 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerWriteCheckButton select
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerExecuteCheckButton deselect
						}
						1 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerExecuteCheckButton select
						}
						0 {
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerReadCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerWriteCheckButton deselect
							.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerExecuteCheckButton deselect
						}
					}
				}
			}
			incr whichPermissions
		}
# End permissions
#######################################################
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyFilePath delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyPathType delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyFileSize delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyFileType delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyLastAccessed delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyLastModified delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerComboBox delete entry  0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupComboBox delete entry 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyNativeFileName delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyFilePath insert 0 $fullFilePath
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyPathType insert 0 $filePathType
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyFileSize insert 0 $fileSize
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyFileType insert 0 $fileTypeProperty
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyLastAccessed insert 0 $fileTimeModified
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyLastModified insert 0 $fileTimeAccessed
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyNativeFileName insert 0 $fileNativeName
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerComboBox insert entry  0 $fileOwner
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupComboBox insert entry  0 $fileGroup
	}

}
## End redoFileDialogProperties
########################################################################################
########################################################################################
## Start Procedure:  initFileDialogProperties

proc ::initFileDialogProperties {} {
# This initializes the dialog box for file properties

		widgetUpdate

# Clear out values
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyFilePath delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyPathType delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyFileSize delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyFileType delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyLastAccessed delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameTop.fileDialogPropertyLastModified delete 0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerComboBox delete entry  0 end
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupComboBox delete entry 0 end

# load the comboboxes with the owner and group names from /etc/passwd and group.
		set ownerid [open "/etc/passwd" r]
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerComboBox delete list 0 end
		while {![eof $ownerid]} {
			gets $ownerid ownerName
			set ownerName [string range $ownerName 0 [expr [string first ":" $ownerName] -1]]

		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerComboBox insert list end $ownerName
		}
		close $ownerid
		set groupid [open "/etc/group" r]
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupComboBox delete list 0 end
		while {![eof $groupid]} {
			gets $groupid groupName
			set groupName [string range $groupName 0 [expr [string first ":" $groupName] -1]]
		.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupComboBox insert list end $groupName
		}
		close $groupid
	}
## End initFileDialogProperties
#############################################################################
#############################################################################
## Procedure:  initBookmarksTitle

proc ::initBookmarksTitle {} {
# This initializes the bookmarks title
	Window show .fileDialogBookmarkTitle
	Window show .fileDialogBookmarkTitle
	set MNS::PassConfig "FileDialog"
	widgetUpdate
	.fileDialogBookmarkTitle.fileDialogBookmarkTitleEntry  delete 0 end
	.fileDialogBookmarkTitle.fileDialogBookmarkPathEntry  delete 0 end
	.fileDialogBookmarkTitle.fileDialogBookmarkPathEntry insert 0 [ComboBoxUpLevelFileDialog getcurselection]
	.fileDialogBookmarkTitle.fileDialogBookmarkTitleEntry insert 0 [ComboBoxUpLevelFileDialog getcurselection]
#	.fileDialogBookmarkTitle.fileDialogBookmarkTitleEntry configure -selectbackground $MNS::PPref(PPref,color,selection,back)
#	.fileDialogBookmarkTitle.fileDialogBookmarkTitleEntry selection range 0 end
#	.fileDialogBookmarkTitle.fileDialogBookmarkTitleEntry icursor end
	focus .fileDialogBookmarkTitle.fileDialogBookmarkTitleEntry.lwchildsite.entry
	if {$MNS::PPref(PPref,SelectAllText) == "Yes"} {.fileDialogBookmarkTitle.fileDialogBookmarkTitleEntry.lwchildsite.entry select range 0 end}
	.fileDialogBookmarkTitle.fileDialogBookmarkTitleEntry.lwchildsite.entry icursor end

}
## End initBookmarksTitle
#############################################################################
#############################################################################
## Procedure:  pasteFileDialog
proc ::pasteFileDialog {} {

	set MNS::NewFileRename ""
	set MNS::FileOverwriteConfirm 3
	foreach  MNS::FileCopyCutName $MNS::FileCopyCutList {
		if {$MNS::FileCopyTrigger == 1 || $MNS::FileCutTrigger == 1} {
			set fileSource $MNS::FileCopyCutDir
			append fileSource {/} $MNS::FileCopyCutName
			if {$MNS::FileCopyTrigger == 1 } {
				set filePaste $MNS::FullDirPath
				append filePaste  {/} $MNS::FileCopyCutName
				if {[file exist $filePaste] && $MNS::FileOverwriteConfirm != 1} {
					set MNS::PasteOverwriteFileName "The file or directory "
					append MNS::PasteOverwriteFileName $MNS::FileCopyCutName " already exists !"
					execPasteFileExistDialog
					if {$MNS::FileOverwriteConfirm == 0 || $MNS::FileOverwriteConfirm == 1} {
						set r [file copy -force $fileSource $filePaste]
						if {$MNS::FileOverwriteConfirm == 0} {set MNS::FileOverwriteConfirm 3}
					}
					if {$MNS::FileOverwriteConfirm == 2} {
						set MNS::FileRename $filePaste
						execFileRename
						if {$MNS::NewFileRename !=""} {
							if {[file exist $MNS::NewFileRename]} {
								Window show .renameFileExistError
								Window show .renameFileExistError
								widgetUpdate
								tkwait visibility .renameFileExistError
								tkwait window .renameFileExistError
								execFileRename
							} else {
								set filePaste $MNS::NewFileRename
								set r [file copy -force $fileSource $filePaste]
							}
						}
					}
					if {$MNS::FileOverwriteConfirm == 4} {
						break
					}
				} else {
					set r [file copy -force $fileSource $filePaste]
				}
			} else {
				if {$MNS::FileCutTrigger == 1 } {
					set fileSource $MNS::FileCopyCutDir
					append fileSource {/} $MNS::FileCopyCutName
					set filePaste $MNS::FullDirPath
					append filePaste  {/} $MNS::FileCopyCutName
					if {[file exist $filePaste] && $MNS::FileOverwriteConfirm != 1} {
						set MNS::PasteOverwriteFileName "The file or directory "
						append MNS::PasteOverwriteFileName $MNS::FileCopyCutName " already exists !"
						execPasteFileExistDialog
						if {$MNS::FileOverwriteConfirm == 0} {
							set r [file copy -force $fileSource $filePaste]
							set r [file delete -force $fileSource]
						}
						if {$MNS::FileOverwriteConfirm == 2} {
							set MNS::FileRename $filePaste
							execFileRename
							if {$MNS::NewFileRename !=""} {
								if {[file exist $MNS::NewFileRename]} {
								Window show .renameFileExistError
								widgetUpdate
								tkwait visibility .renameFileExistError
								tkwait window .renameFileExistError
									execFileRename
								} else {
									set filePaste $MNS::NewFileRename
									set r [file copy -force $fileSource $filePaste]
								}
							}
						}
						if {$MNS::FileOverwriteConfirm == 4} {break}
					} else {
						set r [file copy -force $fileSource $filePaste]
						set r [file delete -force $fileSource]
					}
# Disable past function until something is selected to paste
					.fileDialog.frameTop.pasteButton configure -state disable
					.fileDialog.fileDialogPopUp entryconfigure 5 -state disable
				}
			}
		}
	}
	if {$MNS::FileCutTrigger == 1 } {
		set MNS::FileCutTrigger 0
		set MNS::FileCopyCutList {}
	}
	EntryFileNameFileDialog delete 0 end
	redoFileDialogListBox
}

## End pasteFileDialog
#############################################################################

#############################################################################
## Procedure:  copyFileDialog

proc ::copyFileDialog {} {

	set MNS::FileCopyTrigger 1
	set MNS::FileCutTrigger 0
	set MNS::FileCopyCutDir $MNS::FullDirPath
	set MNS::FileCopyCutList {}
	set MNS::SelectionIndexList [ScrolledListBoxFileViewFileDialog curselection]
	foreach  selectionIndex [split $MNS::SelectionIndexList { }]  {
		set MNS::FileCopyCutName [ScrolledListBoxFileViewFileDialog get $selectionIndex]
		if {$MNS::FileDisplayType=="Details"} {
			if {[string index $MNS::FileCopyCutName 0] == "\{"} {
				set MNS::FileCopyCutName [string trim [string range $MNS::FileCopyCutName 1 53]]
			} else {
				set MNS::FileCopyCutName [string trim [string range $MNS::FileCopyCutName 0 54]]
			}
		}
		lappend MNS::FileCopyCutList $MNS::FileCopyCutName
	}
}
## End copyFileDialog
#############################################################################

#############################################################################
## Procedure:  cutFileDialog

proc ::cutFileDialog {} {

	set MNS::FileCutTrigger 1
	set MNS::FileCopyTrigger 0
	set MNS::FileCopyCutDir $MNS::FullDirPath
	set MNS::FileCopyCutList {}
	set MNS::SelectionIndexList [ScrolledListBoxFileViewFileDialog curselection]
	foreach  selectionIndex [split $MNS::SelectionIndexList { }]  {
		set MNS::FileCopyCutName [ScrolledListBoxFileViewFileDialog get $selectionIndex]
		if {$MNS::FileDisplayType=="Details"} {
			if {[string index $MNS::FileCopyCutName 0] == "\{"} {
				set MNS::FileCopyCutName [string trim [string range $MNS::FileCopyCutName 1 53]]
			} else {
				set MNS::FileCopyCutName [string trim [string range $MNS::FileCopyCutName 0 54]]
			}
		}
		lappend MNS::FileCopyCutList $MNS::FileCopyCutName
	}
}
## End cutFileDialog
#############################################################################

#############################################################################
## Procedure:  renameFileDialog

proc ::renameFileDialog {} {

	set MNS::SelectionIndexList [ScrolledListBoxFileViewFileDialog curselection]
	foreach  selectionIndex [split $MNS::SelectionIndexList { }]  {
		set MNS::FileRename [ScrolledListBoxFileViewFileDialog get $selectionIndex]
		if {$MNS::FileDisplayType=="Details"} {
			if {[string index $MNS::FileRename 0] == "\{"} {
				set MNS::FileRename [string trim [string range $MNS::FileRename 1 53]]
			} else {
				set MNS::FileRename [string trim [string range $MNS::FileRename 0 54]]
			}
		}
		execFileRename
# A double check to make sure the filename you typed in doesn't already exist.  If so
# run the rename dialog again.
		if {$MNS::NewFileRename !=""} {
			if {[file exist $MNS::NewFileRename]} {
				Window show .renameFileExistError
				widgetUpdate
				tkwait window .renameFileExistError
				execFileRename
			} else {
				set r [file rename $MNS::FileRename $MNS::NewFileRename]
			}
		}
	}
	redoFileDialogListBox
}
## End renameFileDialog
#############################################################################
#############################################################################
## Procedure:  deleteFileDialog

proc ::deleteFileDialog {} {

	set MNS::SelectionIndexList [ScrolledListBoxFileViewFileDialog curselection]
#######################
#
# Check Pregram Pref for Delete confirmations.  If Yes then run the confirm dialog box.
# If set to No then set the var to 1 to automatically delete.
	if {$MNS::PPref(PPref,ConfirmFileDeletions) == "Yes"} {
		set fileDeleteConfirm 2
	} else {
		set fileDeleteConfirm 1
	}
	foreach  selectionIndex [split $MNS::SelectionIndexList { }]  {
		set fileDelete [ScrolledListBoxFileViewFileDialog get $selectionIndex]
		set DeleteConfirmFileName "Delete file or directory "
		append DeleteConfirmFileName " " $fileDelete " ?"
# If view type is details then we must strip out the file name only.
		if {$MNS::FileDisplayType=="Details"} {
# If any list separators still remain in the filename then stip them out
			if {[string index $fileDelete 0] == "\{"} {
				set fileDelete [string trim [string range $fileDelete 1 53]]
			} else {
				set fileDelete [string trim [string range $fileDelete 0 54]]
			}
		}
# This is when delete all is selected
		if {$fileDeleteConfirm == 1} {
			set r [file delete -force "$fileDelete"]
		} else {
#Here is where we confirm the delete
         		Window show .deleteFileConfirm
			Window show .deleteFileConfirm
			widgetUpdate
			tkwait window .deleteFileConfirm
			if {$fileDeleteConfirm == 0 || $fileDeleteConfirm == 1} {set r [file delete -force "$fileDelete"]}
# This is where we cancel
			if {$fileDeleteConfirm == 3} {break}
		}
	}
	EntryFileNameFileDialog delete 0 end
	redoFileDialogListBox
}
## End deleteFileDialog
#############################################################################
#############################################################################
## Procedure:  saveBookmark

proc ::saveBookmark {} {
################################
# If we make it here then there is a bookmark file for the browser.  That has already
# been check. The file is opened for read write and the file must be existing.  The data
# is put together first then the file pointer is moved just proir to the last line which contains
# the closing code for the browser bookmark file.  The beginning of this line is start of the
# writting for the new bookmark.  After the new bookmark is written the last line is written back
# and the file closed.
	global MNS::BookMarkTitle MNS::BookMarkBrowserPath MNS::BookMarkBrowserName MNS::TmpPath
	set MNS::BookMarkTitle {}
	set MNS::BookMarkTitle [.fileDialogBookmarkTitle.fileDialogBookmarkTitleEntry get]
	if {$MNS::BookMarkTitle == ""} {
		tk_messageBox -message {Don't leave title blank !}
	} else {
		set bookmarkPath [.fileDialogBookmarkTitle.fileDialogBookmarkPathEntry get]
		set firstbookmarkline {}
		set secondbookmarkline {}
		set thirdbookmarkline {}
		set fourthbookmarkline {}
		set fifthbookmarkline {}
		set sixthbookmarkline {}
		set bookmarkid [open $MNS::BookMarkBrowserPath r+]
		if {$MNS::BookMarkBrowserName == "Konqueror"} {
			append firstbookmarkline {<bookmark icon="html" href="file:} $bookmarkPath {" >}
			append secondbookmarkline {<title>} $MNS::BookMarkTitle {</title>}
			set thirdbookmarkline {</bookmark>}
			seek $bookmarkid  -8 end
			puts $bookmarkid $firstbookmarkline
			puts $bookmarkid $secondbookmarkline
			puts $bookmarkid $thirdbookmarkline
			puts $bookmarkid {</xbel>}
			close $bookmarkid
		}
		if {$MNS::BookMarkBrowserName == "Mozilla"} {
			append firstbookmarkline {  <DT><A HREF="file://} $bookmarkPath {" ADD_DATE="} [clock seconds] {" LAST_CHARSET="UTF-8">} $MNS::BookMarkTitle {</A>}
			seek $bookmarkid  -9 end
			puts $bookmarkid $firstbookmarkline
			puts $bookmarkid {</DL><p>}
			close $bookmarkid
		}
		if {$MNS::BookMarkBrowserName == "Nautilus"} {
			append firstbookmarkline {<bookmarks><bookmark name="} $MNS::BookMarkTitle {" uri="file://} $bookmarkPath {" icon_name="gnome-fs-bookmark"/></bookmarks>}
			seek $bookmarkid  -1 end
			puts -nonewline $bookmarkid $firstbookmarkline
			close $bookmarkid
		}
		if {$MNS::BookMarkBrowserName == "Galeon"} {
			append firstbookmarkline {<bookmark icon="html" href="file:} $bookmarkPath {" >}
			append secondbookmarkline {<title>} $MNS::BookMarkTitle {</title>}
			set thirdbookmarkline {</bookmark>}
			seek $bookmarkid  -8 end
			puts $bookmarkid $firstbookmarkline
			puts $bookmarkid $secondbookmarkline
			puts $bookmarkid $thirdbookmarkline
			puts $bookmarkid {</xbel>}
			close $bookmarkid
		}
		if {$MNS::BookMarkBrowserName == "Netscape"} {
			append firstbookmarkline {  <DT><A HREF="file://} $bookmarkPath {" ADD_DATE="} [clock seconds] {" LAST_VISIT="} [clock seconds] {" LAST_MODIFIED="} [clock seconds] {">} $MNS::BookMarkTitle {</A>}
			seek $bookmarkid  -9 end
			puts $bookmarkid $firstbookmarkline
			puts $bookmarkid {</DL><p>}
			close $bookmarkid
		}
		if {$MNS::BookMarkBrowserName == "Opera"} {
# This is for Opera 6.  The order does not need set.  This puts the link in root for the
# bookmarks.  The next time the user is in Opera and clicks on the bookmark Opera will
# rewritten it's bookmark file with the correct order.
			set firstbookmarkline {#URL}
			append secondbookmarkline {NAME=} $MNS::BookMarkTitle
			append thirdbookmarkline {URL=file:/} $bookmarkPath
			append fourthbookmarkline {CREATED=} [clock seconds]
			set fifthbookmarkline {ORDER=}
			set MNS::TmpPath {}
			append  MNS::TmpPath [string range $MNS::BookMarkBrowserPath 0 [string last {/} $MNS::BookMarkBrowserPath]] "FileDialogTmpFile"
			set bookmarkidtmp [open $MNS::TmpPath w+]
			gets $bookmarkid operaLine
			puts $bookmarkidtmp $operaLine
			gets $bookmarkid operaLine
			puts $bookmarkidtmp $operaLine
			puts $bookmarkidtmp {}
			puts $bookmarkidtmp {}
			puts $bookmarkidtmp $firstbookmarkline
			puts $bookmarkidtmp $secondbookmarkline
			puts $bookmarkidtmp $thirdbookmarkline
			puts $bookmarkidtmp $fourthbookmarkline
			puts $bookmarkidtmp $fifthbookmarkline
			while {![eof $bookmarkid]} {
				gets $bookmarkid operaLine
				puts $bookmarkidtmp $operaLine
			}
			close $bookmarkidtmp
			close $bookmarkid
			set r [file delete -force $MNS::BookMarkBrowserPath]
			set r [file rename $MNS::TmpPath $MNS::BookMarkBrowserPath]
		}
		destroy window .fileDialogBookmarkTitle
	}
}

## End saveBookmark
#############################################################################

#############################################################################
## Procedure:  findFileDialogSearch

proc ::findFileDialogSearch {} {
		
		set findList {}
		set MNS::SearchPattern [.findFileDialog.entryFindFileDialog get]
		set MNS::SearchDirectory [.findFileDialog.comboboxFindFileDialog get]
 
		if {$MNS::CaseSensitiveFind == "Case Sensitive"} {

		}
		if {$MNS::ExactMatchFind == "Exact Match"} {
		
		}
		if {$MNS::SearchPattern == ""} {set MNS::SearchPattern "*"}
		set findList [lsort [glob -nocomplain -directory $MNS::SearchDirectory $MNS::SearchPattern]]
		if {$findList != ""} {
			ScrolledListBoxFileViewFileDialog clear	
			foreach findListItem $findList {
				ScrolledListBoxFileViewFileDialog insert end $findListItem
			}
# Delete what is in there now
			EntryFileNameFileDialog delete 0 end
# Replace with the clicked (selected) file
			EntryFileNameFileDialog insert end [string range [lindex $findList 0] [expr [string last  "/" [lindex $findList 0] ] +1] end]
			ScrolledListBoxFileViewFileDialog selection set 0
		}
		
		if {$MNS::RecursiveFind == "Recursive"} {
		set MNS::RecursiveStructure {}
		set MNS::RecursiveCount 0
			foreach item [lsort [glob -nocomplain -directory $MNS::SearchDirectory *]] {
				if {[file isdirectory $item]} {
#					set MNS::RecursiveStructure($MNS::RecursiveCount) $item
					incr MNS::RecursiveCount
					
#					set MNS::RecursiveSearchPath $item
#					append MNS::RecursiveSearchPath $MNS::SearchDirectory "/" $item
#					findFileDialogResursiveSearch
				
				}
			}

		}
}
## End findFileDialogSearch
#############################################################################
#############################################################################
# Procedure execFileRename
proc ::execFileRename {} {

	set MNS::RenameDisplay $MNS::FileRename
# If window doesn't exist then show it.  If it does exist just raist it.
	if {![winfo exist .MNS::FileRename]} {	
############################################################################
############################################################################
#
# This allows the window to expand to show long path names
#
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set strlength [string length $MNS::FileRename]
	if {$strlength>30} {
		set newXvalue [expr 300+(($strlength-30)*6)]
	} else {
		set newXvalue 300
	}
	set xCord [expr int(([winfo screenwidth .]-$newXvalue)/2)]
	set yCord [expr int(([winfo screenheight .]-75)/2)]
	Window show .MNS::FileRename
	Window show .MNS::FileRename
	set NewGeom $newXvalue
	append NewGeom "x75+" $xCord "+" $yCord
	wm geometry .MNS::FileRename $NewGeom
############################################################################
	widgetUpdate
	} else {
	        raise .MNS::FileRename
	}
	EntryNewNameFileRename delete 0 end
	EntryNewNameFileRename insert end $MNS::FileRename
	focus .MNS::FileRename.entryNewFileNameFileRename.lwchildsite.entry
	if {$MNS::PPref(PPref,SelectAllText) == "Yes"} {.MNS::FileRename.entryNewFileNameFileRename.lwchildsite.entry select range 0 end}
	.MNS::FileRename.entryNewFileNameFileRename.lwchildsite.entry icursor end
	tkwait window .MNS::FileRename
}
# End Procedure execFileRename
#############################################################################

#############################################################################
# Procedure execPasteFileExistDialog
proc ::execPasteFileExistDialog {} {

############################################################################
#
# This allows the window to expand to show long path names
#
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set strlength [string length $MNS::PasteOverwriteFileName]
	if {$strlength>30} {
		set newXvalue [expr 300+(($strlength-30)*6)]
	} else {
		set newXvalue 300
	}
	set xCord [expr int(([winfo screenwidth .]-$newXvalue)/2)]
	set yCord [expr int(([winfo screenheight .]-60)/2)]
	Window show .pasteFileExistDialog
	Window show .pasteFileExistDialog
#	tkwait visibility .pasteFileExistDialog	
	set NewGeom $newXvalue
	append NewGeom "x60+" $xCord "+" $yCord
	wm geometry .pasteFileExistDialog $NewGeom
	widgetUpdate
	tkwait window .pasteFileExistDialog
}

# End Procedure execPasteFileExistDialog
#############################################################################
#############################################################################
## Procedure:  findFileDialogResursiveSearch

proc ::findFileDialogResursiveSearch {} {
	
	set findList [lsort [glob -nocomplain -directory $MNS::RecursiveSearchPath $MNS::SearchPattern]]
	if {$findList != ""} {foreach findListItem $findList {ScrolledListBoxFileViewFileDialog insert end $findListItem}}
	foreach item [lsort [glob -nocomplain -directory $MNS::RecursiveSearchPath *]] {
		if {[file isdirectory $item]} {
			set MNS::RecursiveSearchPath $item
			findFileDialogResursiveSearch
		}
	}
}
## End findFileDialogResursiveSearch
#############################################################################

