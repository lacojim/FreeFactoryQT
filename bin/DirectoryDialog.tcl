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
# Program:DirectoryDialog.tcl
#
# User Variables:
#
#   Input to dialog:
#	selectFileType = This is for the file type filter
#	buttonImagePathDirectoryDialog = Path to image for open/save button
#	windowName = Window Title
#	toolTip = Changes the tool tip depending on operation options are Open, Save, Import, Export.  Curently
#                 does not function.
#	fullDirPath = The full directory path that the dialog will start in.  Does not end with /
#
#   Output from dialog:
#       returnFilePath = The Full path including the selected file
#
################################################################################################
proc vTclWindow.directoryDialog {base} {

	global newDirNameName backLevelName upLevelComboBoxListVar
	global returnFilePath returnFileName returnFullPath directoryDialogOk fullDirPath dirpath toolTip windowName buttonImagePathDirectoryDialog
	global screenx screeny PPref
	global RenameDisplay fileRename PasteOverwriteFileName fileOverwriteConfirm
   	global SelectAllText ConfirmSaves ConfirmDeletions ShowIconBar1 ShowIconBar2 ShowIconBar3
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-494)/2)]
	set yCord [expr int(($screeny-313)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .directoryDialog}
	if {[winfo exists $base]} {wm deiconify $base; return}
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
		set openReqPopUp [tk_popup .directoryDialog.directoryDialogPopUp [winfo pointerx .directoryDialog] [winfo pointery .directoryDialog] 0]
#
#  This popup will be displayed relative to mouse location.
		.directoryDialog.directoryDialogPopUp configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back) 
		set openReqPopUp [tk_popup .directoryDialog.directoryDialogPopUp [winfo pointerx .directoryDialog] [winfo pointery .directoryDialog] 0]
	}
	bind $top <Escape> {
		set returnFilePath ""
		if {[winfo exist .fileDialogProperties]} {
			destroy window .fileDialogProperties
		}
		if {[winfo exist .newDirNameReq]} {
			destroy window .newDirNameReq
		}
		if {[winfo exist .fileRename]} {
			destroy window .fileRename
		}
		destroy window .directoryDialog
	}

	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

	frame $top.frameTop -height 35 -highlightcolor black -relief raised -width 495 -border 0
	vTcl:DefineAlias "$top.frameTop" "FrameTopDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.frameTop

	label $site_3_0.lookInLabel -activebackground #f9f9f9 -activeforeground black -foreground black -highlightcolor black -text "Look In:"
	vTcl:DefineAlias "$site_3_0.lookInLabel" "LabelLookInDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.lookInLabel -in $site_3_0 -anchor w -expand 1 -fill none -side left

#########################################################################
# Start Up Level Combo Box
	::iwidgets::combobox $site_3_0.upLevelComboBox \
        -command {namespace inscope ::iwidgets::ComboBox {::.directoryDialog.frameTop.upLevelComboBox _addToList}} \
	-selectioncommand {
		set backLevelName $fullDirPath
		set fullDirPath [ComboBoxUpLevelDirectoryDialog getcurselection]
		EntryFileNameDirectoryDialog delete 0 end 
		EntryFileNameDirectoryDialog insert end $fullDirPath
		
		if {[string length $fullDirPath] > 1} {
			append fullDirPath {/}
		}
		set r [cd $fullDirPath]

# Redo the listbox for the new directory
		redoDirectoryDialogListBox
		if {$fileDisplayType=="Properties" && $fileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initDirectoryDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
			redoDirectoryDialogProperties
			ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
		}
	} -textbackground #fefefe -width 20
	vTcl:DefineAlias "$site_3_0.upLevelComboBox" "ComboBoxUpLevelDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.upLevelComboBox -in $site_3_0 -anchor w -expand 1 -fill x -side left
# End Up Level Combo Box Button
#########################################################################
#########################################################################
# Start Back Level Button
    button $site_3_0.backLevelButton -borderwidth 0 -relief flat -highlightthickness 0 -command {
		set backLevelNameTmp $fullDirPath
		set fullDirPath $backLevelName
		set backLevelName $backLevelNameTmp
###################
# Run system cd command to go up a level
		set r [cd $fullDirPath]
# Replace the current with the new selected path
		ComboBoxUpLevelDirectoryDialog delete entry 0 end
		ComboBoxUpLevelDirectoryDialog insert entry end $fullDirPath
		EntryFileNameDirectoryDialog delete 0 end 
		EntryFileNameDirectoryDialog insert end $fullDirPath

###################################
# Redo the file list box
		redoDirectoryDialogListBox
		if {$fileDisplayType=="Properties" && $fileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initDirectoryDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
			redoDirectoryDialogProperties
			ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
		}
	 } -image [vTcl:image:get_image [file join / opt FreeFactory Pics Back-20x20.gif]]
	vTcl:DefineAlias "$site_3_0.backLevelButton" "ButtonBackLevelDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.backLevelButton -in $site_3_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_3_0.backLevelButton "Back"

# End Back Level Button
#########################################################################
#########################################################################
# Start Up Level Button
	button $site_3_0.upLevelButton -borderwidth 0 -relief flat -highlightthickness 0 -command {
		set backLevelName $fullDirPath
		if {[expr [string last "/" $fullDirPath]] > 0} {
			set fullDirPath [string range $fullDirPath 0 [expr [string last "/" $fullDirPath] -1]]
		} else {
			set fullDirPath {/}
		}
# Replace the current with the new selected path
		ComboBoxUpLevelDirectoryDialog delete entry 0 end
		ComboBoxUpLevelDirectoryDialog insert entry end $fullDirPath
#		set fullDirPath [ComboBoxUpLevelDirectoryDialog getcurselection]
		EntryFileNameDirectoryDialog delete 0 end 
		EntryFileNameDirectoryDialog insert end $fullDirPath
###################
# Run system cd command to go up a level
		set r [cd $fullDirPath]
###################################
# Redo the file list box
		redoDirectoryDialogListBox
		if {$fileDisplayType=="Properties" && $fileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initDirectoryDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
			redoDirectoryDialogProperties
			ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
		}
	 } -image [vTcl:image:get_image [file join / opt FreeFactory Pics pgaccess UpLevel-20x20.gif]]
	vTcl:DefineAlias "$site_3_0.upLevelButton" "ButtonUpLevelDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.upLevelButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_3_0.upLevelButton "Up Level"

# End Up Level Button
#########################################################################
#########################################################################
# Start New Directory Button
	button $site_3_0.newDirButton -borderwidth 0 -relief flat -highlightthickness 0 -command {
		set newDirNameName {}
		Window show .newDirNameReq
		Window show .newDirNameReq
		widgetUpdate
		focus .newDirNameReq.entryNewDirName.lwchildsite.entry
	} -image [vTcl:image:get_image [file join / opt FreeFactory Pics Folder_New20x20.gif]]
	vTcl:DefineAlias "$site_3_0.newDirButton" "ButtonNewDirDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.newDirButton -in $site_3_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_3_0.newDirButton "New Directory"
# End New Directory Button
#########################################################################
#########################################################################
# Start Copy Button
	button $site_3_0.copyButton -borderwidth 0 -relief flat -highlightthickness 0 -command {
		.directoryDialog.frameTop.pasteButton configure -state normal
		.directoryDialog.directoryDialogPopUp entryconfigure 5 -state  normal
		copyDirectoryDialog
	} -image [vTcl:image:get_image [file join / opt FreeFactory Pics EditCopy-20x20.gif]]
	vTcl:DefineAlias "$site_3_0.copyButton" "ButtonCopyDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.copyButton -in $site_3_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_3_0.copyButton "Copy"

# End Copy Button
#########################################################################
#########################################################################
# Start Cut Button
	button $site_3_0.cutButton -borderwidth 0 -relief flat -highlightthickness 0 -command {
		.directoryDialog.frameTop.pasteButton configure -state normal
		.directoryDialog.directoryDialogPopUp entryconfigure 5 -state  normal
		cutDirectoryDialog
	} -image [vTcl:image:get_image [file join / opt FreeFactory Pics Cut-20x20.gif]]
	vTcl:DefineAlias "$site_3_0.cutButton" "ButtonCutDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.cutButton -in $site_3_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_3_0.cutButton "Cut"

# End Cut Button
#########################################################################
#########################################################################
# Start Paste Button
	button $site_3_0.pasteButton -borderwidth 0 -relief flat -highlightthickness 0 -command {pasteDirectoryDialog} \
        -image [vTcl:image:get_image [file join / opt FreeFactory Pics Edit-Paste-20x20.gif]]
	vTcl:DefineAlias "$site_3_0.pasteButton" "ButtonPasteDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.pasteButton -in $site_3_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_3_0.pasteButton "Paste"

# End Paste Button
#########################################################################
#########################################################################
# Start Delete Button
# This code is the same as above.  Could maybe put into a single proc call in the future.
	button $site_3_0.deleteButton -borderwidth 0 -relief flat -highlightthickness 0 -command {deleteDirectoryDialog} \
        -image [vTcl:image:get_image [file join / opt FreeFactory Pics Remove-20x20.gif]] 
	vTcl:DefineAlias "$site_3_0.deleteButton" "ButtonDeleteDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.deleteButton -in $site_3_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_3_0.deleteButton "Delete"

# End Delete Button
#########################################################################
#################################################################
# Start View Type Button    
	menubutton $site_3_0.viewTypeButton -borderwidth 0 -relief flat -highlightthickness 0 \
        -height 23 -highlightcolor black -image [vTcl:image:get_image [file join / opt FreeFactory Pics Show-20x20.gif]] \
        -indicatoron 1 -menu "$site_3_0.viewTypeButton.m" -padx 5 -pady 5 \
        -relief raised -width 24 
	vTcl:DefineAlias "$site_3_0.viewTypeButton" "MenuButtonViewDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	balloon $site_3_0.viewTypeButton "View Type"

	menu $site_3_0.viewTypeButton.m -tearoff 0 
####################################
# Start List menu item    
	$site_3_0.viewTypeButton.m add command -command {
		set fileDisplayType "List"
# If previous view type was properties then get rid of that dialog box
		if {[winfo exist .fileDialogProperties]} {destroy window .fileDialogProperties}
# This one clears the listbox for the new directory
		redoDirectoryDialogListBox
	} -label "List"
# End List menu item
####################################
####################################
# Start Details menu item
    $site_3_0.viewTypeButton.m add command -command {
		set fileDisplayType "Details"
		if {[winfo exist .fileDialogProperties]} {
			destroy window .fileDialogProperties
		}
# This one clears the listbox for the new directory
		redoDirectoryDialogListBox
	} -label "Details"
# End Details menu item
####################################
####################################
# Start Properties menu item
	$site_3_0.viewTypeButton.m add command -command {
		set fileDisplayType {Properties}
       		if {![winfo exist .fileDialogProperties]} {
			Window show .fileDialogProperties
			Window show .fileDialogProperties
			initDirectoryDialogProperties
		}
		redoDirectoryDialogListBox
		if {$fileNameList !=""} {
		    	set dirpathProperty [ScrolledListBoxFileViewDirectoryDialog get [ScrolledListBoxFileViewDirectoryDialog curselection] [ScrolledListBoxFileViewDirectoryDialog curselection]]
			set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
			redoDirectoryDialogProperties
			ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label "Properties"
# End Properties menu item
####################################
####################################
# Start Preview menu item
	$site_3_0.viewTypeButton.m add command -command {set fileDisplayType "Preview"} -label "Preview"

# End Preview menu item
####################################
#####################################################
# Start Arrange submenu item    
# No code here yet
	$site_3_0.viewTypeButton.m add separator \

	$site_3_0.viewTypeButton.m add cascade -menu "$site_3_0.viewTypeButton.m.men59" -label "Arrange Icons"
	set site_5_0 $site_3_0.viewTypeButton.m

	vTcl:DefineAlias "$site_3_0.viewTypeButton.m" "MenuButtonMenu1ViewDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	menu $site_5_0.men59 -activebackground #f9f9f9 -activeforeground black -foreground black -tearoff 0
	$site_5_0.men59 add radiobutton -value 1 -variable arrangeIconsButton -command {} -label "Name" -state active
	$site_5_0.men59 add radiobutton -value 2 -variable arrangeIconsButton -command {} -label "Type"
	$site_5_0.men59 add radiobutton -value 3 -variable arrangeIconsButton -command {} -label "Size"
	$site_5_0.men59 add radiobutton -value 4 -variable arrangeIconsButton -command {} -label "Date"

# End Arrange submenu
#########################################
	vTcl:DefineAlias "$site_3_0.viewTypeButton.m.men59" "MenuButtonMenu2ViewDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.viewTypeButton -in $site_3_0 -anchor nw -expand 1 -fill none -side left

# End View Type Menu Button
#########################################################################    
#########################################################################    
# Start Tools Type Menu Button
	menubutton $site_3_0.toolButton -borderwidth 0 -relief flat -highlightthickness 0 \
        -height 23 -image [vTcl:image:get_image [file join / opt FreeFactory Pics Tool-20x20.gif]] \
        -indicatoron 1 -menu "$site_3_0.toolButton.m" -padx 5 -pady 5 -relief raised -width 24
	vTcl:DefineAlias "$site_3_0.toolButton" "MenuButtonToolDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	balloon $site_3_0.toolButton "Tools"
	pack $site_3_0.toolButton -in $site_3_0 -anchor nw -expand 1 -fill none -side right
#####################################################
# This is the far right menu button that has the wrench (Tools) icon.
	menu $site_3_0.toolButton.m -activebackground #f9f9f9 -activeforeground black -foreground black -tearoff 0
	vTcl:DefineAlias "$site_3_0.toolButton.m" "MenuButtonMenu1ToolDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	$site_3_0.toolButton.m add command -command {
		Window show .findFileDialog
		Window show .findFileDialog
		widgetUpdate
###########
#  Initialize the data for the widgets
		ComboBoxFindFileDialog clear
		ComboBoxFindFileDialog delete entry 0 end
		ComboBoxFindFileDialog insert entry end [ComboBoxUpLevelDirectoryDialog getcurselection]
#####################
# Use the existing cache of paths already in the top combox look in
		foreach boxinsert $upLevelComboBoxListVar {
			ComboBoxFindFileDialog insert list end $boxinsert
		}
		focus .findFileDialog.entryFindFileDialog
		focus .findFileDialog.entryFindFileDialog
	} -label "Find"

##############################################
# Start Delete menu item
	$site_3_0.toolButton.m add command -command {deleteDirectoryDialog} -label "Delete"
# End Delete menu item
##############################################
##############################################
# Start Rename menu item
	$site_3_0.toolButton.m add command -command {renameDirectoryDialog} -label "Rename"
# End Rename menu item
##############################################
##############################################
# Start Print menu item
	$site_3_0.toolButton.m add command -command {
		source "/usr/local/PgTCLScales/bin/WidgetUpdate.tcl"
		initPrinterDialog
	} -label "Print"
# End Print menu item
##############################################
##############################################
# Start Add To Bookmarks menu item
	$site_3_0.toolButton.m add cascade -menu "$site_3_0.toolButton.m.men67" -command {} -label "Add To Bookmarks"
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

        $site_5_0.men67 add command -command {
		set bookmarkBrowserName "Konqueror"
		set bookmarkBrowserPath $env(HOME)
		append bookmarkBrowserPath "/.kde/share/apps/konqueror/bookmarks.xml"
		if {[file exist $bookmarkBrowserPath]} {initBookmarksTitle}
	} -label "Konqueror"
# End Konqueror submenu item
##############################################
##############################################
# Start Netscape submenu item
         $site_5_0.men67 add command -command {
		set bookmarkBrowserName "Netscape"
		set bookmarkBrowserPath $env(HOME)
		append bookmarkBrowserPath "/.netscape/bookmarks.html"
		if {[file exist $bookmarkBrowserPath]} {initBookmarksTitle}
	} -label "Netscape"
# End Netscape submenu item
##############################################
##############################################
# Start Mozilla submenu item
	$site_5_0.men67 add command -command {
		set bookmarkBrowserName "Mozilla"
		set bookmarkBrowserPath $env(HOME)
		set mozillabookmarkdefault  $env(HOME)
		set mozillabookmarkuser  $env(HOME)
		append mozillabookmarkdefault "/.mozilla/default/"
		append mozillabookmarkuser {/.mozilla/} [string range $env(HOME) [expr [string last {/} $env(HOME)] +1] end] {/}
		append mozillabookmarkdefault  [file tail [glob -nocomplain -directory $mozillabookmarkdefault *.slt]] {/bookmarks.html}
		append mozillabookmarkuser   [file tail [glob -nocomplain -directory $mozillabookmarkuser *.slt]] {/bookmarks.html}
		if {[file exist $mozillabookmarkuser]} {
			set bookmarkBrowserPath $mozillabookmarkuser
			initBookmarksTitle
		} else {
			if {[file exist $mozillabookmarkdefault]} {
				set bookmarkBrowserPath $mozillabookmarkdefault
				initBookmarksTitle
			}
		}
	} -label "Mozilla"
# End Mozilla submenu item
##############################################
##############################################
# Start Nautilus submenu item
        $site_5_0.men67 add command -command {
		set bookmarkBrowserName "Nautilus"
		set bookmarkBrowserPath $env(HOME)
		append bookmarkBrowserPath {/.nautilus/bookmarks.xml}
		if {[file exist $bookmarkBrowserPath]} {initBookmarksTitle}
	} -label "Nautilus"
# End Nautilus submenu item
##############################################
##############################################
# Start Galeon submenu item
        $site_5_0.men67 add command -command {
		set bookmarkBrowserName {Galeon}
		set bookmarkBrowserPath $env(HOME)
		append bookmarkBrowserPath {/.galeon/bookmarks.xbel}
		if {[file exist $bookmarkBrowserPath]} {initBookmarksTitle}
	} -label "Galeon"
# End Galeon submenu item
##############################################
##############################################
# Start Opera submenu item
   $site_5_0.men67 add command -command {
		set bookmarkBrowserName {Opera}
		set bookmarkBrowserPath $env(HOME)
		append bookmarkBrowserPath {/.opera/opera6.adr}
		if {[file exist $bookmarkBrowserPath]} {
			initBookmarksTitle
		}
		
	} -label "Opera"
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
		set backLevelName $fullDirPath
		set fullDirPath "/mnt"
		RefreshBoxes
	} -label "Mount Drive"
# End Mount menu item
#######################################
#######################################
# Start Properties menu item

	$site_3_0.toolButton.m add separator \

	$site_3_0.toolButton.m add command -command {
		set fileDisplayType "Properties"
		if {![winfo exist .fileDialogProperties]} {
			Window show .fileDialogProperties
			Window show .fileDialogProperties
			initDirectoryDialogProperties
		}
		redoDirectoryDialogListBox
		if {$fileNameList !=""} {
			set dirpathProperty [ScrolledListBoxFileViewDirectoryDialog get [ScrolledListBoxFileViewDirectoryDialog curselection] [ScrolledListBoxFileViewDirectoryDialog curselection]]
			set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
			redoDirectoryDialogProperties
			ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label "Properties"
# End Properties menu item
#######################################
	vTcl:DefineAlias "$site_3_0.toolButton.m.men67" "MenuButtonMenu2ToolDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
# End Tool Button
#################################################################

	frame $top.frameTopMaster -height 280 -highlightcolor black -relief groove -width 400  -border 0
	vTcl:DefineAlias "$top.frameTopMaster" "FrameTopMasterDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.frameTopMaster

############################################################################3
# Buttons on the left frame side
	::iwidgets::scrolledframe $site_3_0.frameLeft -background #999999 -height 599 -hscrollmode none -vscrollmode dynamic -width 86
	vTcl:DefineAlias "$site_3_0.frameLeft" "ScrolledFrameLeftDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	set site_8_0 [$site_3_0.frameLeft childsite]

	button $site_8_0.homeDirButton -activebackground #f9f9f9 -activeforeground black \
        -borderwidth 0 -relief flat -highlightthickness 0 \
        -command {
		set backLevelName $fullDirPath
		set fullDirPath $env(HOME)
		RefreshBoxes
# cd to the directory
#		set r [cd $fullDirPath]
# Replace the current with the new selected path
#		ComboBoxUpLevelDirectoryDialog delete entry 0 end
#		ComboBoxUpLevelDirectoryDialog insert entry end $fullDirPath
# This one clears the listbox for the new directory
#		redoDirectoryDialogListBox
	} -foreground black -height 56 -highlightcolor black \
        -image [vTcl:image:get_image [file join / usr local  OpenBlend Pics Folder_Home-48x48.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.homeDirButton" "ButtonHomeDirDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.homeDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.homeDirButton "Home"

	button $site_8_0.desktopDirButton -activebackground #f9f9f9 -activeforeground black \
        -borderwidth 0 -relief flat -highlightthickness 0 \
        -command {
		set backLevelName $fullDirPath
		set fullDirPath $env(HOME)
		append fullDirPath {/Desktop}
		RefreshBoxes
	} -foreground black -height 56 -highlightcolor black \
        -image [vTcl:image:get_image [file join / usr local  OpenBlend Pics Screen_Green-48x48.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.desktopDirButton" "ButtonDesktopDirDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.desktopDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.desktopDirButton "Desktop"

	button $site_8_0.documentsDirButton -activebackground #f9f9f9 -activeforeground black \
        -borderwidth 0 -relief flat -highlightthickness 0 \
        -command {
		set backLevelName $fullDirPath
		set fullDirPath $env(HOME)
# Check to see if kde is used.  If so check for the default data path.
		if {[file exist $env(HOME)/.kde/share/config/kdeglobals]} {
			set FileHandle [open $env(HOME)/.kde/share/config/kdeglobals r]
			while {![eof $FileHandle]} {
				gets $FileHandle ReadLine
				if {[string trim $ReadLine]=={[Paths]}} {
					gets $FileHandle ReadLine
					set fullDirPath "$env(HOME)[string trim [string range $ReadLine [expr [string first {$HOME} $ReadLine] + 5] end]]"
					close $FileHandle
					break
				}
			}
		}
		RefreshBoxes
	} -foreground black -height 56 -highlightcolor black \
        -image [vTcl:image:get_image [file join / usr local  OpenBlend Pics Document-48x48.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.documentsDirButton" "ButtonDocumentsDirDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.documentsDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.documentsDirButton "Documents"

	button $site_8_0.floppyDirButton -borderwidth 0 -relief flat \
        -command {
		set backLevelName $fullDirPath
		set fullDirPath "/media/floppy"
		if {![file exist $fullDirPath]} {
			set fullDirPath "/mnt/floppy"
		}
		if {![file exist $fullDirPath]} {
			set fullDirPath "/mnt"
		}
		RefreshBoxes
	} -foreground black -height 56 -highlightcolor black \
        -image [vTcl:image:get_image [file join / usr local  OpenBlend Pics 3Floppy_Unmount-48x48.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.floppyDirButton" "ButtonFloppyDirDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.floppyDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.floppyDirButton "Floppy"

	button $site_8_0.cdromDirButton -borderwidth 0 -relief flat -highlightthickness 0 \
        -command {
		set backLevelName $fullDirPath
		set fullDirPath "/media/cdrom"
		if {![file exist $fullDirPath]} {
			set fullDirPath "/mnt/cdrom"
		}
		if {![file exist $fullDirPath]} {
			set fullDirPath "/media"
		}
		if {[file exist $fullDirPath]} {
			RefreshBoxes
		} else {
			set fullDirPath $backLevelName
		}
	} -foreground black -height 56 -highlightcolor black \
        -image [vTcl:image:get_image [file join / usr local  OpenBlend Pics CDROM_Mount-48x48.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.cdromDirButton" "ButtonCDROMDirDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.cdromDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.cdromDirButton "CDROM"

	button $site_8_0.mntDirButton -activebackground #f9f9f9 -activeforeground black \
        -borderwidth 0 -relief flat -highlightthickness 0 \
        -command {
		set backLevelName $fullDirPath
# Set to slash now but in future will point to a newtwork path
		set fullDirPath "/mnt"
		if {[file exist $fullDirPath]} {
			RefreshBoxes
		} else {
#			set fullDirPath $backLevelName
		}
	} -foreground black -height 56 -highlightcolor black \
        -image [vTcl:image:get_image [file join / usr local  OpenBlend Pics Gnome_Dev_Harddisk-48x48.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.mntDirButton" "ButtonMntDirDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.mntDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.mntDirButton "Mount Directory"

	button $site_8_0.mediaDirButton -activebackground #f9f9f9 -activeforeground black \
        -borderwidth 0 -relief flat -highlightthickness 0 \
        -command {
		set backLevelName $fullDirPath
# Set to slash now but in future will point to a newtwork path
		set fullDirPath "/media"
		if {[file exist $fullDirPath]} {
			RefreshBoxes
		} else {
			set fullDirPath $backLevelName
		}
	} -foreground black -height 56 -highlightcolor black \
        -image [vTcl:image:get_image [file join / usr local  OpenBlend Pics NFS_Mount_kde-48x48.gif]] -width 56 
	vTcl:DefineAlias "$site_8_0.mediaDirButton" "ButtonMediaDirDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_0.mediaDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
	balloon $site_8_0.mediaDirButton "Media Directory"

#	button $site_8_0.networkDirButton -activebackground #f9f9f9 -activeforeground black \
#        -borderwidth 0 -relief flat -highlightthickness 0 \
#        -command {
#		set backLevelName $fullDirPath
# Set to slash now but in future will point to a newtwork path
#		set fullDirPath "smb:/"
#		if {[file exist $fullDirPath]} {
#			RefreshBoxes
#		} else {
#			set fullDirPath $backLevelName
#		}
#	} -foreground black -height 56 -highlightcolor black \
#        -image [vTcl:image:get_image [file join / usr local  OpenBlend Pics nfs_mount.gif]] -width 56 
#	vTcl:DefineAlias "$site_8_0.networkDirButton" "ButtonNetworkDirDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
#	pack $site_8_0.networkDirButton -in $site_8_0 -anchor center -expand 1 -fill none -side top
#	balloon $site_8_0.networkDirButton "Network"

	pack $site_3_0.frameLeft -in $site_3_0 -anchor nw -expand 1 -fill y -side left

# End Left Side Frame Buttons
##########################################################################################    

	frame $site_3_0.frameBottomMaster -height 24 -highlightcolor black -relief groove -width 430  -border 0
	vTcl:DefineAlias "$site_3_0.frameBottomMaster" "FrameBottomMasterDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.frameBottomMaster

	frame $site_4_0.frameBottomSub2 -height 40 -highlightcolor black -relief groove -width 430  -border 0
	vTcl:DefineAlias "$site_4_0.frameBottomSub2" "FrameBottomSub2DirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_5_0 $site_4_0.frameBottomSub2

#    label $site_5_0.fileTypeLabel \
#        -activebackground #f9f9f9 -activeforeground black -foreground black \
#        -highlightcolor black -text {File Type:} 
#    vTcl:DefineAlias "$site_5_0.fileTypeLabel" "Label3" vTcl:WidgetProc "Toplevel1" 1
###############################################################
# Start Open Button
# This would need customized for a return of the filename to the calling procedure    

	button $site_5_0.openButton \
        -command {
		if {[EntryFileNameDirectoryDialog get] != ""} {
			set tmp [EntryFileNameDirectoryDialog get]
			if {[string last "/" $tmp] == [expr [string length $tmp] -1]} {
				set tmp [string range $tmp 0 [expr [string length $tmp] -2]]
			}
			set returnFileName $tmp
			set returnFilePath $tmp
			set returnFullPath $tmp
			set directoryDialogOk "Ok"
			destroy window .directoryDialog
		}
	} -width 57 -image [vTcl:image:get_image [file join / opt FreeFactory Pics Open-20x20.gif]]
	pack $site_5_0.openButton -in $site_5_0 -anchor nw -expand 1 -fill x -side top
	vTcl:DefineAlias "$site_5_0.openButton" "ButtonOpenDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	balloon $site_5_0.openButton "Open"

# End Open Button
###############################################################

	button $site_5_0.cancelButton \
        -command {
# Window destroy .directoryDialog
		set returnFileName {}
		set returnFilePath {}
		set directoryDialogOk "Cancel"
		if {[winfo exist .fileDialogProperties]} {
			destroy .fileDialogProperties
		}
		if {[winfo exist .newDirNameReq]} {
			destroy .newDirNameReq
		}
		if {[winfo exist .fileRename]} {
			destroy .fileRename
		}
		destroy window .directoryDialog
	} -width 5 -foreground black -highlightcolor black \
	-image [vTcl:image:get_image [file join / opt FreeFactory Pics Exit-20x20.gif]]
	pack $site_5_0.cancelButton -in $site_5_0 -anchor nw -expand 1 -fill x -side bottom
	vTcl:DefineAlias "$site_5_0.cancelButton" "ButtonCancelDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	balloon $site_5_0.cancelButton "Cancel"

#    ::iwidgets::combobox $site_5_0.fileTypeComboBox \
#        \
#        -command {namespace inscope ::iwidgets::ComboBox {::.directoryDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox _addToList}} \
#        -selectioncommand {
########################################################################################
# File type filter selection	
#		set fileSelectType [.directoryDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox get]
#		if {[string last "*" $fileSelectType] == [expr [string length $fileSelectType] -1]} {
#			set selectFileType {*}
#		} else {
#			set selectFileType [string range $fileSelectType [expr [string length $fileSelectType] - 4] [expr [string length $fileSelectType] - 1]]
#		}
#		redoDirectoryDialogListBox
#	} \
#        -textbackground #fefefe -width 217 
#    vTcl:DefineAlias "$site_5_0.fileTypeComboBox" "ComboBox2" vTcl:WidgetProc "Toplevel1" 1

#    pack $site_5_0.fileTypeLabel \
#        -in $site_5_0 -anchor nw -expand 1 -fill none -side left




#    pack $site_5_0.fileTypeComboBox \
#        -in $site_5_0 -anchor nw -expand 1 -fill none -side left

	pack $site_4_0.frameBottomSub2 -in $site_4_0 -anchor nw -expand 1 -fill none -side right

	frame $site_4_0.frameBottomSub1 -height 40 -highlightcolor black -relief groove -width 430  -border 0
	vTcl:DefineAlias "$site_4_0.frameBottomSub1" "FrameBottomSub1DirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_5_0 $site_4_0.frameBottomSub1

	label $site_5_0.fileNameLabel -text "Directory Name:"
	vTcl:DefineAlias "$site_5_0.fileNameLabel" "LabelFileNameDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

###############################################################
# Start File Name Entry
	entry $site_5_0.fileNameEntry -textvariable returnFilePath -width 233
#	pack $site_3_0.lookInLabel -in $site_3_0 -anchor w -expand 1 -fill none -side left
    	vTcl:DefineAlias "$site_5_0.fileNameEntry" "EntryFileNameDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
	balloon $site_5_0.fileNameEntry "File Entry Box"

	bind $site_5_0.fileNameEntry <Key-Return> {
		if {[EntryFileNameDirectoryDialog get] != ""} {
			set tmp [EntryFileNameDirectoryDialog get]
			if {[string last "/" $tmp] == [expr [string length $tmp] -1]} {
				set tmp [string range $tmp 0 [expr [string length $tmp] -2]]
			}
			set returnFileName $tmp
			set returnFilePath $tmp
			set returnFullPath $tmp
			set directoryDialogOk "Ok"
			destroy window .directoryDialog
		}
	}
	bind $site_5_0.fileNameEntry <Key-Return> {
		if {[EntryFileNameDirectoryDialog get] != ""} {
			set tmp [EntryFileNameDirectoryDialog get]
			if {[string last "/" $tmp] == [expr [string length $tmp] -1]} {
				set tmp [string range $tmp 0 [expr [string length $tmp] -2]]
			}
			set returnFileName $tmp
			set returnFilePath $tmp
			set returnFullPath $tmp
			set directoryDialogOk "Ok"
			destroy window .directoryDialog
		}
	}

# End File Name Entry Box
###############################################################
	pack $site_5_0.fileNameLabel -in $site_5_0 -anchor center -expand 0 -fill none -side left
	pack $site_5_0.fileNameEntry -in $site_5_0 -anchor center -expand 0 -fill none -side left

	pack $site_4_0.frameBottomSub1 -in $site_4_0 -anchor nw -expand 1 -fill y -side left
	pack $site_3_0.frameBottomMaster -in $site_3_0 -anchor nw -expand 0 -fill none -side bottom


	frame $site_3_0.frameFileView -height 205 -highlightcolor black -relief groove -width 413  -border 1
	vTcl:DefineAlias "$site_3_0.frameFileView" "FrameFileViewDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
#################################################################
#################################################################
#################################################################
# Start List Box

	set site_4_0 $site_3_0.frameFileView

	::iwidgets::scrolledlistbox $site_4_0.fileViewListBox -selectmode extended \
        -dblclickcommand {
		set selectionIndexList [ScrolledListBoxFileViewDirectoryDialog curselection]
		set dirpath [ScrolledListBoxFileViewDirectoryDialog get $selectionIndexList] 
# If file display type is details the strip of the beginning and ending curly brace if present
		if {$fileDisplayType=="Details" || $fileDisplayType=="Properties"} {
			if {[string index $dirpath 0] == "\{"} {
				set dirpath [string trim [string range $dirpath 1 54]]
			} else {
				set dirpath [string trim [string range $dirpath 0 53]]
			}
		}
		if {[file isdirectory $dirpath]} {
			set backLevelName $fullDirPath
#################################
# This next "if" statement is a hack work around for a problem of somehow getting double slashes
# in the path.  this strips and trims them out.
			if {[string last "//" $fullDirPath] >0} {
			 	set fullDirPath [string range $fullDirPath 0 [expr [string last "//" $fullDirPath]] -1]
			}
			if {[string length $fullDirPath] > 1} {
				append fullDirPath {/}
			}
#################################
# This next "if" statement is a hack work around for a problem of somehow getting double slashes
# in the path.  this strips and trims them out.
			if {[string last "//" $fullDirPath] >0} {
			 	set fullDirPath [string range $fullDirPath 0 [string last "//" $fullDirPath]]
			}
			append fullDirPath $dirpath
			set r [cd $fullDirPath]
# Add the directory to the list
# Unable to get the unique property working.  This code
# prevents duplicates
			set duplicateTrigger 0
			foreach tmpvar $upLevelComboBoxListVar {
                     	if {$fullDirPath == $tmpvar} {
					set duplicateTrigger 1
					break
				}
			}
			if {$duplicateTrigger == 0} {
# If not a duplicate then add the path to the combobox and sort it.
# Then clear the combobox and refresh it.
				set upLevelComboBoxListVar [lsort [lappend upLevelComboBoxListVar $fullDirPath]]
				ComboBoxUpLevelDirectoryDialog clear
				foreach tmpvar $upLevelComboBoxListVar {
					ComboBoxUpLevelDirectoryDialog insert list end $tmpvar
                		}
			}
# Replace the current with the new selected path
			ComboBoxUpLevelDirectoryDialog delete entry 0 end
			ComboBoxUpLevelDirectoryDialog insert entry end $fullDirPath

# This one clears the listbox for the new directory
			redoDirectoryDialogListBox
			if {$fileDisplayType=="Properties" && $fileNameList !=""} {
		       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
					Window show .fileDialogProperties
					Window show .fileDialogProperties
					initDirectoryDialogProperties
				}
				set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
				redoDirectoryDialogProperties
				ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
			}
		}
############################
# Double Click on 
#		if {[file isfile "$dirpath"]} {
#			if {[EntryFileNameDirectoryDialog get] != ""} {
#				set tmp [EntryFileNameDirectoryDialog get]
#				if {[string last "/" $tmp] == [expr [string length $tmp] -1]} {
#					set tmp [string range $tmp 0 [expr [string length $tmp] -2]]
#				}
#				set returnFileName $tmp
#				set returnFilePath $tmp
#				set returnFullPath $tmp
#				set directoryDialogOk "Ok"
#				destroy window .directoryDialog
#			}
#		}
	} -height 215 -hscrollmode dynamic -selectioncommand {
# Place clicked (selected)  file in entry box.
		set dirpath [ScrolledListBoxFileViewDirectoryDialog getcurselection]
		if {$fileDisplayType=="Details"} {
			if {[string index $dirpath 0] == "\{"} {
				set dirpath [string trim [string range $dirpath 1 54]]
			} else {
				set dirpath [string trim [string range $dirpath 0 53]]
			}
		}
# The extra condition of checking for a null dirpath is needed to prevent an error when double clicked
		if {[file isfile $dirpath]} {
# Delete what is in there now
			EntryFileNameDirectoryDialog delete 0 end
# Replace with the clicked (selected) file
			EntryFileNameDirectoryDialog insert end [string range $dirpath [expr [string last  "/" $dirpath ] +1] end]
#			EntryFileNameDirectoryDialog insert end $dirpath
		}
		if {$fileDisplayType=="Properties"} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initDirectoryDialogProperties
			}
			set dirpathProperty $dirpath
			set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
			foreach reFocusSelectionTmp $reFocusSelection {
				redoDirectoryDialogProperties
				ScrolledListBoxFileViewDirectoryDialog selection set [lindex $reFocusSelection 0] $reFocusSelectionTmp
			}
		}
		EntryFileNameDirectoryDialog delete 0 end
		set tmp {}
		
#tk_messageBox -message [string length $fullDirPath]
#tk_messageBox -message [string last "/" $fullDirPath]


		if {[string last "/" $fullDirPath] == [expr [string length $fullDirPath] -1]} {
			EntryFileNameDirectoryDialog insert end [append tmp $fullDirPath $dirpath]
		} else {
			EntryFileNameDirectoryDialog insert end [append tmp $fullDirPath {/} $dirpath]
		}
	} -vscrollmode dynamic -width 530
	vTcl:DefineAlias "$site_4_0.fileViewListBox" "ScrolledListBoxFileViewDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1
# End List Box
#################################################################
#################################################################
#################################################################

	pack $site_4_0.fileViewListBox -in $site_4_0 -anchor nw -expand 1 -fill both -side bottom
	pack $site_3_0.frameFileView -in $site_3_0 -anchor nw -expand 1 -fill both -side bottom
#################################################################
#################################################################
#################################################################
# Start Pop Up Menu
#
# This code is also above and in the future maybe consolidated in a single proc for
# each command.

    menu $top.directoryDialogPopUp -borderwidth 2 -cursor arrow -disabledforeground #a3a3a3 -relief raised  -tearoff 0

	$top.directoryDialogPopUp add command -command {
		set backLevelNameTmp $fullDirPath
		set fullDirPath $backLevelName
		set backLevelName $backLevelNameTmp
###################
# Run system cd command to go up a level
		set r [cd $fullDirPath]
# Replace the current with the new selected path
		ComboBoxUpLevelDirectoryDialog delete entry 0 end
		ComboBoxUpLevelDirectoryDialog insert entry end $fullDirPath
###################################
# Redo the file list box
		redoDirectoryDialogListBox
		if {$fileDisplayType=="Properties" && $fileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initDirectoryDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
			redoDirectoryDialogProperties
			ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label "Back"

	$top.directoryDialogPopUp add command -command {
		set backLevelName $fullDirPath
		if {[expr [string last "/" $fullDirPath]] > 0} {
			set fullDirPath [string range $fullDirPath 0 [expr [string last "/" $fullDirPath] -1]]
		} else {
			set fullDirPath {/}
		}
# Replace the current with the new selected path
		ComboBoxUpLevelDirectoryDialog delete entry 0 end
		ComboBoxUpLevelDirectoryDialog insert entry end $fullDirPath
###################
# Run system cd command to go up a level
		set r [cd $fullDirPath]
###################################
# Redo the file list box
		redoDirectoryDialogListBox
		if {$fileDisplayType=="Properties" && $fileNameList !=""} {
	       		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
				Window show .fileDialogProperties
				Window show .fileDialogProperties
				initDirectoryDialogProperties
			}
			set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
			redoDirectoryDialogProperties
			ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label "Up Level"

	$top.directoryDialogPopUp add command -command {
		global PPref
		global newDirNameName
		set newDirNameName {}
		Window show .newDirNameReq
		Window show .newDirNameReq
		widgetUpdate
		focus .newDirNameReq.entryNewDirName.lwchildsite.entry
	} -label "New Directory"

	$top.directoryDialogPopUp add command -command {
		.directoryDialog.frameTop.pasteButton configure -state normal
		.directoryDialog.directoryDialogPopUp entryconfigure 5 -state  normal
		copyDirectoryDialog
	} -label "Copy"

	$top.directoryDialogPopUp add command -command {
		.directoryDialog.frameTop.pasteButton configure -state normal
		.directoryDialog.directoryDialogPopUp entryconfigure 5 -state  normal
		cutDirectoryDialog
	} -label "Cut"

	$top.directoryDialogPopUp add command -command {pasteDirectoryDialog} -label "Paste"
	$top.directoryDialogPopUp add command -command {renameDirectoryDialog} -label "Rename"
	$top.directoryDialogPopUp add command -command {deleteDirectoryDialog} -label "Delete"
	$top.directoryDialogPopUp add command -command {
		set fileDisplayType {Properties}
       		if {![winfo exist .fileDialogProperties]} {
			Window show .fileDialogProperties
			Window show .fileDialogProperties
			initDirectoryDialogProperties
		}
		redoDirectoryDialogListBox
		if {$fileNameList !=""} {
		    	set dirpathProperty [ScrolledListBoxFileViewDirectoryDialog get [ScrolledListBoxFileViewDirectoryDialog curselection] [ScrolledListBoxFileViewDirectoryDialog curselection]]
			set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
			redoDirectoryDialogProperties
			ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
		}
	} -label "Properties"

# End Pop Up Menu
#################################################################
#################################################################
#################################################################

	pack $top.frameTop -in $top -anchor nw -expand 0 -fill x -side top
	pack $top.frameTopMaster -in $top -anchor nw -expand 1 -fill both -side top

	vTcl:FireEvent $base <<Ready>>
}
###################################################################################
###################################################################################
###################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start Bookmark Dialog Box
#
#
proc vTclWindow.directoryDialogBookmarkTitle {base} {
	global PPref screenx screeny
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-387)/2)]
	set yCord [expr int(($screeny-101)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .directoryDialogBookmarkTitle}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel
	wm focusmodel $top passive
	wm geometry $top 387x101+$xCord+$yCord; update
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
	bind $top <Escape> {destroy window .directoryDialogBookmarkTitle}

	::iwidgets::entryfield $top.directoryDialogBookmarkTitleEntry -command {
#		saveBookmark
	} -labeltext "Bookmark Title"
	vTcl:DefineAlias "$top.directoryDialogBookmarkTitleEntry" "EntryBookmarkTitleDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	bind .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry <Key-Return> {
		focus .directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry
		if {$PPref(SelectAllText) == "Yes"} {
			.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry select range 0 end
		}
		.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry icursor end
	}
	bind .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry <Key-KP_Enter> {
		focus .directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry
		if {$PPref(SelectAllText) == "Yes"} {
			.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry select range 0 end
		}
		.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lw.childsite.entry icursor end
	}
	bind .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry <Control-Down> {
		focus .directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry
		if {$PPref(SelectAllText) == "Yes"} {
			.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry select range 0 end
		}
		.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry icursor end
	}
	bind .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry <Control-Up> {
		focus .directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry
		if {$PPref(SelectAllText) == "Yes"} {
			.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry select range 0 end
		}
		.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry icursor end
	}

	::iwidgets::entryfield $top.directoryDialogBookmarkPathEntry \
        -command {
#		saveBookmark
	} -labeltext "Bookmark Path"
	vTcl:DefineAlias "$top.directoryDialogBookmarkPathEntry" "EntryBookmarkPathDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	bind .directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry <Key-Return> {
		focus .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry
		if {$PPref(SelectAllText) == "Yes"} {
			.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry select range 0 end
		}
		.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry icursor end
	}
	bind .directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry <Key-KP_Enter> {
		focus .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry
		if {$PPref(SelectAllText) == "Yes"} {
			.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry select range 0 end
		}
		focus .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry icursor end
	}
	bind .directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry <Control-Down> {
		focus .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry
		if {$PPref(SelectAllText) == "Yes"} {
			.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry select range 0 end
		}
		.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry icursor end
	}
	bind .directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry.lwchildsite.entry <Control-Up> {
		focus .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry
		if {$PPref(SelectAllText) == "Yes"} {
			.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry select range 0 end
		}
		.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry icursor end
	}
	bind $top.directoryDialogBookmarkPathEntry <Key-KP_Enter> {saveBookmark}
	bind $top.directoryDialogBookmarkPathEntry <Key-Return> {saveBookmark}

	::iwidgets::buttonbox $top.directoryDialogBookmarkButtonBox -padx 0 -pady 0
	vTcl:DefineAlias "$top.directoryDialogBookmarkButtonBox" "ButtonBoxBookmarksDirectoryDialog" vTcl:WidgetProc "Toplevel1" 1

	$top.directoryDialogBookmarkButtonBox add but0 -command {saveBookmark} -text "Save"

	$top.directoryDialogBookmarkButtonBox add but1 -command {destroy window .directoryDialogBookmarkTitle} -text "Cancel"
	$top.directoryDialogBookmarkButtonBox add but2 -command {} -text "Help"

	place $top.directoryDialogBookmarkTitleEntry -x 15 -y 5 -width 365 -height 22 -anchor nw -bordermode ignore
	place $top.directoryDialogBookmarkPathEntry -x 15 -y 30 -width 358 -height 22 -anchor nw -bordermode ignore
	place $top.directoryDialogBookmarkButtonBox -x 5 -y 55 -width 378 -height 38 -anchor nw -bordermode ignore

	vTcl:FireEvent $base <<Ready>>
}
#
#
# End Bookmark Dialog Box
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
##########################################################################################################################
## Start Procedure:  initDirectoryDialog

proc ::initDirectoryDialog {} {
# This code initializes the directory dialog box.  There are variables for adjust the background,
# foreground, textbackground, textforeground directory name and file name.  Setting the cut and copy
# triggers to 0 prohibit a past action unless there are selected files and cut or copy has been
# selected.

####################
# Declare globals
	global env
	global fullDirPath fileSelectType  fileSelectTypeList
	global fileCopyTrigger fileCutTrigger fileDisplayType itemFileName item fileCopy fileCut
	global filePaste confirmDeleteVar newDirNameName newFileName selectFileType
	global PPref
	global windowName buttonImagePathDirectoryDialog toolTip upLevelComboBoxListVar dirpath
	global dirpathProperty directoryCount backLevelName
	global noChangesPermissions noChangesOwnerGroup fileLinkPath
	global bookmarkBrowserName bookmarkBrowserPath
	global caseSensitiveFind exactMatchFind recursiveFind
	global screenx screeny
	global PPref passconfig
#####################
# Initalize Defaults
	set fileCopy ""
	set fileCut ""
	set filePaste ""
	set fileDisplayType "List"
	set fileCutTrigger 0
	set fileCopyTrigger 0
	set backLevelName $fullDirPath
	set selectFileType {*}
	set dirpath ""

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
	set passconfig "DirectoryDialog"
	widgetUpdate
	
######
# Try to make it smart enough to disable the menu option if not supported
# on the computer.
# Checking for Konqueror
	set konquerorbookmark $env(HOME)
	append konquerorbookmark {/.kde/share/apps/konqueror/bookmarks.xml}
	if {![file exist $konquerorbookmark]} {
		.directoryDialog.frameTop.toolButton.m.men67 entryconfigure 0 -state  disable
	}
 # Checking for Mozilla
	set mozillabookmarkdefault  $env(HOME)
	set mozillabookmarkuser  $env(HOME)
	append mozillabookmarkdefault {/.mozilla/default/}
	append mozillabookmarkuser {/.mozilla/} [string range $env(HOME) [expr [string last {/} $env(HOME)] +1] end] {/}
	append mozillabookmarkdefault  [file tail [glob -nocomplain -directory $mozillabookmarkdefault *.slt]] {/bookmarks.html}
	append mozillabookmarkuser [file tail [glob -nocomplain -directory $mozillabookmarkuser *.slt]] {/bookmarks.html}
	if {![file exist $mozillabookmarkdefault] && ![file exist $mozillabookmarkuser]} {
		.directoryDialog.frameTop.toolButton.m.men67 entryconfigure 2 -state  disable
	}
###########
# Disable Nautilus for now.  Not able to keep bookmarks
# Nautilus unable to read its own saved bookmarks on program restart
#
# Checking for Nautilus
#	set nautilusbookmark $env(HOME)
#	append nautilusbookmark {/.nautilus/bookmarks.xml}
#	if {![file exist $nautilusbookmark]} {
 		.directoryDialog.frameTop.toolButton.m.men67 entryconfigure 3 -state  disable
#	}
#############
# Checking for Galeon
	set galeonbookmark $env(HOME)
	append galeonbookmark {/.galeon/bookmarks.xbel}
	if {![file exist $galeonbookmark]} {
		.directoryDialog.frameTop.toolButton.m.men67 entryconfigure 4 -state  disable
	}

#############
# Checking for Netscape
	set netscapebookmark $env(HOME)
	append netscapebookmark {/.netscape/bookmarks.html}
	if {![file exist $netscapebookmark]} {
		.directoryDialog.frameTop.toolButton.m.men67 entryconfigure 1 -state  disable
	}

#############
# Checking for Opera
	set operabookmark $env(HOME)
	append operabookmark {/.opera/opera6.adr}
	if {![file exist $netscapebookmark]} {
		.directoryDialog.frameTop.toolButton.m.men67 entryconfigure 5 -state  disable
	}
#############################
# Attempting to redo the tool tip to fit the type of dialog action, open, save, import or export.
# it seems once it is set it won't change.  Also code in the before the call the this
# routine.  The code there is commented out. The toolTip variable is set there for each action.
	balloon .directoryDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.openButton $toolTip

	.directoryDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.cancelButton configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label)  -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back) 
	wm title .directoryDialog $windowName

# cd to the directory
	set r [cd $fullDirPath]
################################################
# Initalize the file type (extension) to be listed
# These are from OpenOffice and can be edited to suit needs of the program
# Here is where we load up the top combobox with the initial paths
	set upLevelComboBoxListVar {}
	lappend upLevelComboBoxListVar {/} {/home} $env(HOME) $fullDirPath {/mnt}
	ComboBoxUpLevelDirectoryDialog clear
	 foreach tmpvar $upLevelComboBoxListVar {
		ComboBoxUpLevelDirectoryDialog insert list end $tmpvar
	}
	ComboBoxUpLevelDirectoryDialog delete entry 0 end
	ComboBoxUpLevelDirectoryDialog insert entry end $fullDirPath
#	.directoryDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox delete entry 0 end
#	.directoryDialog.frameTopMaster.frameBottomMaster.frameBottomSub2.fileTypeComboBox insert entry end {All files *}

# Disable paste function until something is selected to paste
	.directoryDialog.frameTop.pasteButton configure -state disable
	.directoryDialog.directoryDialogPopUp entryconfigure 5 -state disable

#######################################################################################
# Display the dialog
# The following code doesn't seem to work.  No errors but it doesn't seem to always
# receive focus.
	redoDirectoryDialogListBox
	set returnFilePath $fullDirPath
	
	EntryFileNameDirectoryDialog delete 0 end
	EntryFileNameDirectoryDialog insert end $fullDirPath
	focus .directoryDialog.frameTopMaster.frameBottomMaster.frameBottomSub1.fileNameEntry
#	focus EntryFileNameDirectoryDialog
	if {$PPref(SelectAllText) == "Yes"} {
		EntryFileNameDirectoryDialog select range 0 end
	}
	EntryFileNameDirectoryDialog icursor end
}
## End Procedure:  initDirectoryDialog
########################################################################################
#############################################################################
## Procedure:  redoDirectoryDialogListBox

proc ::redoDirectoryDialogListBox {} {
	global PPref selectFileType fileDisplayType
#This clears and refills the listbox for all actions
	set directoryNameList {}
	set fileNameList {}
# Get everything once and filter in the loop	Previous method looped twice once for the dirs and then
# the files.  Had to do this for the filter of file types.  You always want to display the dirs and only
# filter the files.  The filter in "glob" also eliminated dirs without .ext in the name matching the filter.
# Trading a few extra cpu cycles for disk access time which I believe speeds things up.  What we are doing
# is looping through a glob list and running the file command with different options on the dir or file name.
	foreach item [lsort [glob -nocomplain *]] {
		if {$selectFileType == "*" || [file extension $item] == $selectFileType || [file isdirectory $item]} {
			if {$fileDisplayType == "Details"} {
				set fileSize [string trim [file size $item]]
				set itemFileName $item
				set fileSizeLength [string length $fileSize]
				set x [expr $fileSizeLength-1]
				set fileLinkPath {}
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
					set fileLinkPath [file readlink $item]
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
				if {$preFileAttributes == "04"} {
					set filePermissions [string replace $filePermissions 3 3 "S"]
				}
# Check For Guid				
				if {$preFileAttributes == "02"} {
					set filePermissions [string replace $filePermissions 6 6 "S"]
				}
# Check For Sticky
				if {$preFileAttributes == "01"} {
					set filePermissions [string replace $filePermissions 9 9 "T"]
				}

# End permissions conversion from number to letters
#######################################################
				set fileTimeModified [clock format [file mtime $item]]
				set fileGroup [file attributes $item -group]
				set fileOwner [file attributes $item -owner]
############################################################################
# Start assembling the line to display in the listbox for details type list

				set itemFileName [format "%-55s %s   %s   %s     %s%s%s   %s" $itemFileName $fileSize $filePermissions $fileTimeModified $fileGroup ":"  $fileOwner $fileLinkPath]
# End assembling the line to display in the listbox for details type lis
#############################################################################
			}
###########################################
###########################################
# Display in list format
			if {$fileDisplayType == "List" || $fileDisplayType=="Properties" || $fileDisplayType=="Preview"} {
				set itemFileName $item
			}
 		
			if {[file isdirectory $item]} {
				lappend directoryNameList $itemFileName
			} else {
				set fileNameList {}
			}
		}
	}
	ScrolledListBoxFileViewDirectoryDialog clear
# Count the directories and use that number for the first file selection in the listbox.  Since
# the listbox uses zero offset for elements The number of directories will point to the first
# file in the file list
	set directoryCount 0
#	ScrolledListBoxFileViewDirectoryDialog configure -foreground $PPref(color,directory)
	foreach itemFileName $directoryNameList {
#Put the display item in the correct list variable - directory or file
# Fill the list box with directories first
		ScrolledListBoxFileViewDirectoryDialog insert end $itemFileName

		incr directoryCount
	}
#####################################
# Fill the list box with files next
#	foreach itemFileName $fileNameList {
#		ScrolledListBoxFileViewDirectoryDialog insert end $itemFileName
#	}
# This condition statement provides automatic selection of the first file in a directory on display	
	if {$fileNameList !=""} {
#		ScrolledListBoxFileViewDirectoryDialog selection set $directoryCount $directoryCount
# Delete what is in there now			
#		EntryFileNameDirectoryDialog delete 0 end
# Replace with the clicked (selected) file			
#		set displayFile [ScrolledListBoxFileViewDirectoryDialog get $directoryCount $directoryCount]
#		if {$fileDisplayType=="Details" || $fileDisplayType=="Properties"} {
#			if {[string index $displayFile 0] == "\{"} {
#				set displayFile [string trim [string range $displayFile 1 54]]
#			} else {
#				set displayFile [string trim [string range $displayFile 0 53]]
#			}
#		}
		
#			EntryFileNameDirectoryDialog insert end [string range $displayFile [expr [string last  "/" $displayFile ] +1] end]
#			EntryFileNameDirectoryDialog insert end 

#		EntryFileNameDirectoryDialog insert end $displayFile
		if {$fileDisplayType=="Properties"} {
		    set dirpathProperty [ScrolledListBoxFileViewDirectoryDialog get $directoryCount $directoryCount]
		}
	}
# Set color for files in the listbox.
	ScrolledListBoxFileViewDirectoryDialog configure -foreground $PPref(color,file)
# Change the color to blue for direcories
	if {$directoryCount > 0} {
		for {set x 0} {$x < $directoryCount} {incr x} {
			ScrolledListBoxFileViewDirectoryDialog itemconfigure $x -foreground $PPref(color,directory)
		}
	}
}
## End redoDirectoryDialogListBox
#############################################################################

#############################################################################
## Procedure:  redoDirectoryDialogProperties

proc ::redoDirectoryDialogProperties {} {
# This allows editing of directory or file permissions, file owner and group.  The
# apply button is ghosted until something is changed.
	global itemFileName fullDirPath dirpathProperty dirpathPropertyTmp
	global noChangesOwnerGroup noChangesPermissions
####################################################################################

	foreach dirpathPropertyTmp $dirpathProperty {
# if there are any list separators left in the name strip them out
		if {[string first "\{" $dirpathPropertyTmp] == 0 && [string first "\}" $dirpathPropertyTmp] == -1  } {
			set dirpathPropertyTmp [string range $dirpathPropertyTmp 1 end]
		}
# Get file size
		set fileSize [string trim [file size $dirpathPropertyTmp]]
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
		set fileTypeProperty [file type $dirpathPropertyTmp]
		set fileTimeModified [clock format [file mtime $dirpathPropertyTmp]]
		set fileTimeAccessed [clock format [file atime $dirpathPropertyTmp]]
		set fileGroup [file attributes $dirpathPropertyTmp -group]
		set fileOwner [file attributes $dirpathPropertyTmp -owner]
		set filePathType [file pathtype $dirpathPropertyTmp]
		if {$fileTypeProperty == "link"} {
			append fileTypeProperty { to: } [file readlink $dirpathPropertyTmp]
		}
		append filePathType { to: } $fullDirPath
		set fileNativeName [file nativename $dirpathPropertyTmp]
		set fullFilePath $fullDirPath
		if {$fullDirPath == "/"} {
			append fullFilePath $dirpathPropertyTmp
		} else {
			append fullFilePath {/} $dirpathPropertyTmp
		}               
		set filePermissionsNumber {}
		set filePermissions {}
		set noChangesPermissions 0
		set noChangesOwnerGroup 0
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state disable
		set fileAttributes [file attributes  $dirpathPropertyTmp -permissions]
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
## End redoDirectoryDialogProperties
########################################################################################
########################################################################################
## Start Procedure:  initDirectoryDialogProperties

proc ::initDirectoryDialogProperties {} {
# This initializes the dialog box for file properties
# Declare globals
		global fullDirPath
		global fileSelectType
		global fileSelectTypeList
		global fileDisplayType
		global itemFileName
		global item
		global selectFileType
		global PPref
		global toolTip
		global dirpath
		global dirpathProperty
		global directoryCount
		global passconfig
		set passconfig ""
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
## End initDirectoryDialogProperties
#############################################################################
#############################################################################
## Procedure:  initBookmarksTitle

proc ::initBookmarksTitle {} {
# This initializes the bookmarks title
# Declare globals
	global bookmarkTitle bookmarkBrowserPath bookmarkBrowserName tmppath
	global PPref passconfig
	Window show .directoryDialogBookmarkTitle
	Window show .directoryDialogBookmarkTitle
	set passconfig "DirectoryDialog"
	widgetUpdate
	.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry  delete 0 end
	.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry  delete 0 end
	.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry insert 0 [ComboBoxUpLevelDirectoryDialog getcurselection]
	.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry insert 0 [ComboBoxUpLevelDirectoryDialog getcurselection]
#	.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry configure -selectbackground $PPref(color,selection,back)
#	.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry selection range 0 end
#	.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry icursor end
	focus .directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry
	if {$PPref(SelectAllText) == "Yes"} {
		.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry select range 0 end
	}
	.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry.lwchildsite.entry icursor end

}
## End initBookmarksTitle
#############################################################################

#############################################################################
## Procedure:  pasteDirectoryDialog
proc ::pasteDirectoryDialog {} {
	global fullDirPath fileCopyTrigger fileCutTrigger fileCopyCutDir fileCopyCutList fileDisplayType  newFileRename
	global PPref fileRename fileCopyCutName PasteOverwriteFileName fileOverwriteConfirm
	set newFileRename ""
	set fileOverwriteConfirm 3
	foreach  fileCopyCutName $fileCopyCutList {
# tk_messageBox -message $fileCopyCutName
		if {$fileCopyTrigger == 1 || $fileCutTrigger == 1} {
			set fileSource $fileCopyCutDir
			append fileSource {/} $fileCopyCutName
			if {$fileCopyTrigger == 1 } {
				set filePaste $fullDirPath
				append filePaste  {/} $fileCopyCutName
				if {[file exist $filePaste] && $fileOverwriteConfirm != 1} {
					set PasteOverwriteFileName "The file or directory "
					append PasteOverwriteFileName $fileCopyCutName " already exists !"
					execPasteFileExistDialog
					if {$fileOverwriteConfirm == 0 || $fileOverwriteConfirm == 1} {
						set r [file copy -force $fileSource $filePaste]
						if {$fileOverwriteConfirm == 0} {set fileOverwriteConfirm 3}
					}
					if {$fileOverwriteConfirm == 2} {
						set fileRename $filePaste
						execFileRename
						if {$newFileRename !=""} {
							if {[file exist $newFileRename]} {
								Window show .renameFileExistError
								Window show .renameFileExistError
								widgetUpdate
								tkwait visibility .renameFileExistError
								tkwait window .renameFileExistError
								execFileRename
							} else {
								set filePaste $newFileRename
								set r [file copy -force $fileSource $filePaste]
							}
						}
					}
					if {$fileOverwriteConfirm == 4} {
						break
					}
				} else {
					set r [file copy -force $fileSource $filePaste]
				}
			} else {
				if {$fileCutTrigger == 1 } {
					set fileSource $fileCopyCutDir
					append fileSource {/} $fileCopyCutName
					set filePaste $fullDirPath
					append filePaste  {/} $fileCopyCutName
					if {[file exist $filePaste] && $fileOverwriteConfirm != 1} {
						set PasteOverwriteFileName "The file or directory "
						append PasteOverwriteFileName $fileCopyCutName " already exists !"
						execPasteFileExistDialog
						if {$fileOverwriteConfirm == 0} {
							set r [file copy -force $fileSource $filePaste]
							set r [file delete -force $fileSource]
						}
						if {$fileOverwriteConfirm == 2} {
							set fileRename $filePaste
							execFileRename
							if {$newFileRename !=""} {
								if {[file exist $newFileRename]} {
								Window show .renameFileExistError
								widgetUpdate
								tkwait visibility .renameFileExistError
								tkwait window .renameFileExistError
									execFileRename
								} else {
									set filePaste $newFileRename
									set r [file copy -force $fileSource $filePaste]
								}
							}
						}
						if {$fileOverwriteConfirm == 4} {
							break
						}
					} else {
						set r [file copy -force $fileSource $filePaste]
						set r [file delete -force $fileSource]
					}
# Disable past function until something is selected to paste
					.directoryDialog.frameTop.pasteButton configure -state disable
					.directoryDialog.directoryDialogPopUp entryconfigure 5 -state disable
				}
			}
		}
	}
	if {$fileCutTrigger == 1 } {
		set fileCutTrigger 0
		set fileCopyCutList {}
	}
	EntryFileNameDirectoryDialog delete 0 end
	redoDirectoryDialogListBox
}

## End pasteDirectoryDialog
#############################################################################

#############################################################################
## Procedure:  copyDirectoryDialog

proc ::copyDirectoryDialog {} {
	global fullDirPath fileCopyTrigger fileCutTrigger fileCopyCutDir fileCopyCutList fileDisplayType fileRename
	set fileCopyTrigger 1
	set fileCutTrigger 0
	set fileCopyCutDir $fullDirPath
	set fileCopyCutList {}
	set selectionIndexList [ScrolledListBoxFileViewDirectoryDialog curselection]
	foreach  selectionIndex [split $selectionIndexList { }]  {
		set fileCopyCutName [ScrolledListBoxFileViewDirectoryDialog get $selectionIndex]
		if {$fileDisplayType=="Details"} {
			if {[string index $fileCopyCutName 0] == "\{"} {
				set fileCopyCutName [string trim [string range $fileCopyCutName 1 53]]
			} else {
				set fileCopyCutName [string trim [string range $fileCopyCutName 0 54]]
			}
		}
		lappend fileCopyCutList $fileCopyCutName
	}
}
## End copyDirectoryDialog
#############################################################################

#############################################################################
## Procedure:  cutDirectoryDialog

proc ::cutDirectoryDialog {} {
	global fullDirPath fileCopyTrigger fileCutTrigger fileCopyCutDir fileCopyCutList fileDisplayType
	set fileCutTrigger 1
	set fileCopyTrigger 0
	set fileCopyCutDir $fullDirPath
	set fileCopyCutList {}
	set selectionIndexList [ScrolledListBoxFileViewDirectoryDialog curselection]
	foreach  selectionIndex [split $selectionIndexList { }]  {
		set fileCopyCutName [ScrolledListBoxFileViewDirectoryDialog get $selectionIndex]
		if {$fileDisplayType=="Details"} {
			if {[string index $fileCopyCutName 0] == "\{"} {
				set fileCopyCutName [string trim [string range $fileCopyCutName 1 53]]
			} else {
				set fileCopyCutName [string trim [string range $fileCopyCutName 0 54]]
			}
		}
		lappend fileCopyCutList $fileCopyCutName
	}
}
## End cutDirectoryDialog
#############################################################################

#############################################################################
## Procedure:  renameDirectoryDialog

proc ::renameDirectoryDialog {} {
	global fileDisplayType newFileRename fileRename
	global fullDirPath fileCopyTrigger fileCutTrigger fileCopyCutDir fileCopyCutList fileDisplayType  
	global PPref

	set selectionIndexList [ScrolledListBoxFileViewDirectoryDialog curselection]
	foreach  selectionIndex [split $selectionIndexList { }]  {
		set fileRename [ScrolledListBoxFileViewDirectoryDialog get $selectionIndex]
		if {$fileDisplayType=="Details"} {
			if {[string index $fileRename 0] == "\{"} {
				set fileRename [string trim [string range $fileRename 1 53]]
			} else {
				set fileRename [string trim [string range $fileRename 0 54]]
			}
		}
		execFileRename
# A double check to make sure the filename you typed in doesn't already exist.  If so
# run the rename dialog again.
		if {$newFileRename !=""} {
			if {[file exist $newFileRename]} {
				Window show .renameFileExistError
				widgetUpdate
				tkwait window .renameFileExistError
				execFileRename
			} else {
				set r [file rename $fileRename $newFileRename]
			}
		}
	}
	redoDirectoryDialogListBox
}
## End renameDirectoryDialog
#############################################################################

#############################################################################
## Procedure:  deleteDirectoryDialog

proc ::deleteDirectoryDialog {} {

	global fileDisplayType DeleteConfirmFileName fileDeleteConfirm DeleteConfirmFileName
	global PPref
	set selectionIndexList [ScrolledListBoxFileViewDirectoryDialog curselection]
#######################
#
# Check Pregram Pref for Delete confirmations.  If Yes then run the confirm dialog box. 
# If set to No then set the var to 1 to automatically delete.
	
	if {$PPref(ConfirmFileDeletions) == "Yes"} {
		set fileDeleteConfirm 2
	} else {
		set fileDeleteConfirm 1
	}
	
	foreach  selectionIndex [split $selectionIndexList { }]  {
		set fileDelete [ScrolledListBoxFileViewDirectoryDialog get $selectionIndex]
		set DeleteConfirmFileName "Delete file or directory "
		append DeleteConfirmFileName " " $fileDelete " ?"
# If view type is details then we must strip out the file name only.
		if {$fileDisplayType=="Details"} {
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
			if {$fileDeleteConfirm == 0 || $fileDeleteConfirm == 1} {
				set r [file delete -force "$fileDelete"]
			}

# This is where we cancel
			if {$fileDeleteConfirm == 3} {
				break
			}
		}
	}
	EntryFileNameDirectoryDialog delete 0 end
	redoDirectoryDialogListBox
}
## End deleteDirectoryDialog
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
	global bookmarkTitle bookmarkBrowserPath bookmarkBrowserName tmppath
	set bookmarkTitle {}
	set bookmarkTitle [.directoryDialogBookmarkTitle.directoryDialogBookmarkTitleEntry get]
	if {$bookmarkTitle == ""} {
		tk_messageBox -message {Don't leave title blank !}
	} else {
		set bookmarkPath [.directoryDialogBookmarkTitle.directoryDialogBookmarkPathEntry get]
		set firstbookmarkline {}
		set secondbookmarkline {}
		set thirdbookmarkline {}
		set fourthbookmarkline {}
		set fifthbookmarkline {}
		set sixthbookmarkline {}
		set bookmarkid [open $bookmarkBrowserPath r+]
		if {$bookmarkBrowserName == "Konqueror"} {
			append firstbookmarkline {<bookmark icon="html" href="file:} $bookmarkPath {" >}
			append secondbookmarkline {<title>} $bookmarkTitle {</title>}
			set thirdbookmarkline {</bookmark>}
			seek $bookmarkid  -8 end
			puts $bookmarkid $firstbookmarkline
			puts $bookmarkid $secondbookmarkline
			puts $bookmarkid $thirdbookmarkline
			puts $bookmarkid {</xbel>}
			close $bookmarkid
		}
		if {$bookmarkBrowserName == "Mozilla"} {
			append firstbookmarkline {  <DT><A HREF="file://} $bookmarkPath {" ADD_DATE="} [clock seconds] {" LAST_CHARSET="UTF-8">} $bookmarkTitle {</A>}
			seek $bookmarkid  -9 end
			puts $bookmarkid $firstbookmarkline
			puts $bookmarkid {</DL><p>}
			close $bookmarkid
		}
		if {$bookmarkBrowserName == "Nautilus"} {
			append firstbookmarkline {<bookmarks><bookmark name="} $bookmarkTitle {" uri="file://} $bookmarkPath {" icon_name="gnome-fs-bookmark"/></bookmarks>}
			seek $bookmarkid  -1 end
			puts -nonewline $bookmarkid $firstbookmarkline
			close $bookmarkid
		}
		if {$bookmarkBrowserName == "Galeon"} {
			append firstbookmarkline {<bookmark icon="html" href="file:} $bookmarkPath {" >}
			append secondbookmarkline {<title>} $bookmarkTitle {</title>}
			set thirdbookmarkline {</bookmark>}
			seek $bookmarkid  -8 end
			puts $bookmarkid $firstbookmarkline
			puts $bookmarkid $secondbookmarkline
			puts $bookmarkid $thirdbookmarkline
			puts $bookmarkid {</xbel>}
			close $bookmarkid
		}
		if {$bookmarkBrowserName == "Netscape"} {
			append firstbookmarkline {  <DT><A HREF="file://} $bookmarkPath {" ADD_DATE="} [clock seconds] {" LAST_VISIT="} [clock seconds] {" LAST_MODIFIED="} [clock seconds] {">} $bookmarkTitle {</A>}
			seek $bookmarkid  -9 end
			puts $bookmarkid $firstbookmarkline
			puts $bookmarkid {</DL><p>}
			close $bookmarkid
		}
		if {$bookmarkBrowserName == "Opera"} {
# This is for Opera 6.  The order does not need set.  This puts the link in root for the
# bookmarks.  The next time the user is in Opera and clicks on the bookmark Opera will
# rewritten it's bookmark file with the correct order.
			set firstbookmarkline {#URL}
			append secondbookmarkline {NAME=} $bookmarkTitle
			append thirdbookmarkline {URL=file:/} $bookmarkPath
			append fourthbookmarkline {CREATED=} [clock seconds]
			set fifthbookmarkline {ORDER=}
			set tmppath {}
			append  tmppath [string range $bookmarkBrowserPath 0 [string last {/} $bookmarkBrowserPath]] "DirectoryDialogTmpFile"
			set bookmarkidtmp [open $tmppath w+]
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
			set r [file delete -force $bookmarkBrowserPath]
			set r [file rename $tmppath $bookmarkBrowserPath]
		}
		destroy window .directoryDialogBookmarkTitle
	}
}

## End saveBookmark
#############################################################################

#############################################################################
## Procedure:  findDirectoryDialogSearch

proc ::findDirectoryDialogSearch {} {
 		global caseSensitiveFind exactMatchFind recursiveFind
		global searchPattern searchDirectory  recursiveSearchPath
		global recursiveStructure recursiveCount
		
		set findList {}
		set searchPattern [.findDirectoryDialog.entryFindDirectoryDialog get]
		set searchDirectory [ComboBoxFindFileDialog get]
 
		if {$caseSensitiveFind == "Case Sensitive"} {

		}
		if {$exactMatchFind == "Exact Match"} {
		
		}
		if {$searchPattern == ""} {
			set searchPattern "*"
		}
		set findList [lsort [glob -nocomplain -directory $searchDirectory $searchPattern]]
		if {$findList != ""} {
			ScrolledListBoxFileViewDirectoryDialog clear	
			foreach findListItem $findList {
				ScrolledListBoxFileViewDirectoryDialog insert end $findListItem
			}
# Delete what is in there now
			EntryFileNameDirectoryDialog delete 0 end
# Replace with the clicked (selected) file
			EntryFileNameDirectoryDialog insert end [string range [lindex $findList 0] [expr [string last  "/" [lindex $findList 0] ] +1] end]
			ScrolledListBoxFileViewDirectoryDialog selection set 0
		}
		
		if {$recursiveFind == "Recursive"} {
		set recursiveStructure {}
		set recursiveCount 0
			foreach item [lsort [glob -nocomplain -directory $searchDirectory *]] {
				if {[file isdirectory $item]} {
#					set recursiveStructure($recursiveCount) $item
					incr recursiveCount
					
#					set recursiveSearchPath $item
#					append recursiveSearchPath $searchDirectory "/" $item
#					findDirectoryDialogResursiveSearch
				
				}
			}

		}
}
## End findDirectoryDialogSearch
#############################################################################
#############################################################################
# Procedure execFileRename
proc ::execFileRename {} {
	global PPref fileRename RenameDisplay screenx screeny
	set RenameDisplay $fileRename
# If window doesn't exist then show it.  If it does exist just raist it.
	if {![winfo exist .fileRename]} {	
############################################################################
############################################################################
#
# This allows the window to expand to show long path names
#
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set strlength [string length $fileRename]
	if {$strlength>30} {
		set newXvalue [expr 300+(($strlength-30)*6)]
	} else {
		set newXvalue 300
	}
	set xCord [expr int(($screenx-$newXvalue)/2)]
	set yCord [expr int(($screeny-75)/2)]
	Window show .fileRename
	Window show .fileRename
	set NewGeom $newXvalue
	append NewGeom "x75+" $xCord "+" $yCord
	wm geometry .fileRename $NewGeom
############################################################################
	widgetUpdate
	} else {
	        raise .fileRename
	}
	.fileRename.entryFileRename delete 0 end
	.fileRename.entryFileRename insert end $fileRename
	focus .fileRename.entryFileRename.lwchildsite.entry
	if {$PPref(SelectAllText) == "Yes"} {
		.fileRename.entryFileRename.lwchildsite.entry select range 0 end
	}
	.fileRename.entryFileRename.lwchildsite.entry icursor end
	tkwait window .fileRename
}
# End Procedure execFileRename
#############################################################################

#############################################################################
# Procedure execPasteFileExistDialog
proc ::execPasteFileExistDialog {} {
	global PPref fileRename RenameDisplay screenx screeny PasteOverwriteFileName
############################################################################
#
# This allows the window to expand to show long path names
#
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set strlength [string length $PasteOverwriteFileName]
	if {$strlength>30} {
		set newXvalue [expr 300+(($strlength-30)*6)]
	} else {
		set newXvalue 300
	}
	set xCord [expr int(($screenx-$newXvalue)/2)]
	set yCord [expr int(($screeny-60)/2)]
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
## Procedure:  findDirectoryDialogResursiveSearch

proc ::findDirectoryDialogResursiveSearch {} {
	global caseSensitiveFind exactMatchFind recursiveFind
	global searchPattern searchDirectory  recursiveSearchPath
	global recursiveStructure recursiveCount
	
	set findList [lsort [glob -nocomplain -directory $recursiveSearchPath $searchPattern]]
	if {$findList != ""} {
		foreach findListItem $findList {
			ScrolledListBoxFileViewDirectoryDialog insert end $findListItem
		}
	}
	foreach item [lsort [glob -nocomplain -directory $recursiveSearchPath *]] {
		if {[file isdirectory $item]} {
			set recursiveSearchPath $item
#			append recursiveSearchPath $searchDirectory "/" $item
			findDirectoryDialogResursiveSearch
		}
	}
}
## End findDirectoryDialogResursiveSearch
#############################################################################
#############################################################################
## Procedure:  RefreshBoxes
proc ::RefreshBoxes {} {
	global fileDisplayType fileNameList
	global itemFileName fullDirPath dirpathProperty dirpathPropertyTmp
	global noChangesPermissions noChangesOwnerGroup fileLinkPath
	global PPref selectFileType directoryCount upLevelComboBoxListVar
# cd to the directory
	set r [cd $fullDirPath]
# Unable to get the unique property working.  This code
# prevents duplicates
	set duplicateTrigger 0
	foreach tmpvar $upLevelComboBoxListVar {
		if {$fullDirPath == $tmpvar} {
			set duplicateTrigger 1
			break
		}
	}
	if {$duplicateTrigger == 0} {
# If not a duplicate then add the path to the combobox and sort it.
# Then clear the combobox and refresh it.
		set upLevelComboBoxListVar [lsort [lappend upLevelComboBoxListVar $fullDirPath]]
		ComboBoxUpLevelDirectoryDialog clear
		foreach tmpvar $upLevelComboBoxListVar {
			ComboBoxUpLevelDirectoryDialog insert list end $tmpvar
		}
	}
# Replace the current with the new selected path
	ComboBoxUpLevelDirectoryDialog delete entry 0 end
	ComboBoxUpLevelDirectoryDialog insert entry end $fullDirPath
# This one clears the listbox for the new directory
	redoDirectoryDialogListBox
	if {$fileDisplayType=="Properties" && $fileNameList !=""} {
		if {![winfo exist .fileDialogProperties]} {
#Need to put show in twice if the window was previously destroyed
			Window show .fileDialogProperties
			Window show .fileDialogProperties
			initDirectoryDialogProperties
		}
		set reFocusSelection [ScrolledListBoxFileViewDirectoryDialog curselection]
		redoDirectoryDialogProperties
		ScrolledListBoxFileViewDirectoryDialog selection set $reFocusSelection $reFocusSelection
	}
}
## End RefreshBoxes
#############################################################################








