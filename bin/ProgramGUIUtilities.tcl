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
# Program:ProgramGUIUtilities.tcl
#
###########################
# Below are the file GUIs
#
# .newDirNameReq - Creates new directory
# .fileDialogProperties - Displays for edit file permissions and ownership
# .fileDialogBookmarkTitle - Adds a file path to a browser bookmark file
# .findFileDialog - Finds a File
# .fileRename - Renames a directory or file
# .deleteFileConfirm - File delete confirmation multiple files
# .deleteConfirmSingle - File delete confirmation single item
# .renameFileExistError - When you rename to not overwirte an existing file and the new file
#                        you have selected also exists.
# .pasteFileExistDialog - Warns when a file already exists while pasting a file or directory
#
############################
# Below are the system GUIs
#
# .genericConfirm - Generic confirmation GUI
# .progressBar - Progress Bar GUI
# .genericInfo -  Generic Info GUI
#
################################################################################################
proc vTclWindow.newDirNameReq {base} {
	global PPref screenx screeny
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-265)/2)]
	set yCord [expr int(($screeny-67)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .newDirNameReq}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
    ###################
    # CREATING WIDGETS
    ###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black
	wm withdraw $top
	wm focusmodel $top passive
	wm geometry $top 265x67+509+385; update
	wm maxsize $top 1265 994
	wm minsize $top 1 1
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm title $top "New Directory Name"
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

	bind $top <Escape> {destroy window .newDirNameReq}

	::iwidgets::entryfield $top.entryNewDirName -labeltext "Name" -command {} -textvariable newDirNameName
	vTcl:DefineAlias "$top.entryNewDirName" "EntryNewDirectoryNewDirName" vTcl:WidgetProc "Toplevel1" 1
	pack $top.entryNewDirName -in $top -anchor nw -expand 1 -fill x -side top

	bind $top.entryNewDirName <Key-KP_Enter> {.newDirNameReq.buttonBoxNewDirName invoke 0}
	bind $top.entryNewDirName <Key-Return> {.newDirNameReq.buttonBoxNewDirName invoke 0}

	::iwidgets::buttonbox $top.buttonBoxNewDirName -padx 0 -pady 0
	vTcl:DefineAlias "$top.buttonBoxNewDirName" "ButtonBoxNewDirName" vTcl:WidgetProc "Toplevel1" 1

	bindtags $top.buttonBoxNewDirName "bbox-map bbox-config itk-delete-.newDirNameReq.buttonBoxNewDirName $top.buttonBoxNewDirName Buttonbox $top all"
	$top.buttonBoxNewDirName add but0 -command {
		if {$newDirNameName != "" } {
			set r  [file mkdir "$newDirNameName"]
			redoFileDialogListBox
			destroy window .newDirNameReq
		} else {
			Window show .blankEntryError
			widgetUpdate
		}
	} -text "Create"
	$top.buttonBoxNewDirName add but1 -background #d9d9d9 -command {destroy window .newDirNameReq} -text "Cancel"
	$top.buttonBoxNewDirName add but2 -background #d9d9d9 -command {} -text "Help"
	balloon $top.buttonBoxNewDirName.1.pushbutton "Create New Directory"
	balloon $top.buttonBoxNewDirName.2.pushbutton "Cancel And Close"
	balloon $top.buttonBoxNewDirName.3.pushbutton "Display Help"
	pack propagate $top.buttonBoxNewDirName 0
	grid propagate $top.buttonBoxNewDirName 0
	pack $top.buttonBoxNewDirName -in $top -anchor center -expand 1 -fill x -side bottom

	vTcl:FireEvent $base <<Ready>>
}
#
#
# End Procedure .newDirNameReq
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################

############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start file properties dialog box
#
#
proc vTclWindow.fileDialogProperties {base} {
	global noChangesOwnerGroup
	global PPref screenx screeny
	set xCord [expr int(($screenx-465)/2)]
	set yCord [expr int(($screeny-298)/2)]
	if {$base == ""} {set base .fileDialogProperties}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
    ###################
    # CREATING WIDGETS
    ###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black 
	wm focusmodel $top passive
	wm geometry $top 465x298+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 465 1
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm deiconify $top
	wm title $top "Properties..."
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {destroy window .fileDialogProperties}
	frame $top.filePropertyFrame -borderwidth 1 -height 367 -highlightcolor black -relief groove -width 526
	vTcl:DefineAlias "$top.filePropertyFrame" "FrameMasterFilePropertiesDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.filePropertyFrame

	frame $site_3_0.fileDialogPropertyFrameTop -borderwidth 1 -height 57 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.fileDialogPropertyFrameTop" "FrameTopFilePropertiesDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.fileDialogPropertyFrameTop

	::iwidgets::entryfield $site_4_0.fileDialogPropertyFilePath -highlightthickness 0 -labeltext "Full Dir Path:" -relief flat -selectborderwidth 0
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyFilePath" "EntryFilePathFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.fileDialogPropertyFilePath -in $site_4_0 -anchor w -expand 0 -fill x -side top

	::iwidgets::entryfield $site_4_0.fileDialogPropertyPathType -highlightthickness 0 -labeltext "Path Type:" -relief flat -selectborderwidth 0
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyPathType" "EntryPathTypeFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.fileDialogPropertyPathType -in $site_4_0 -anchor w -expand 0 -fill x -side top

	::iwidgets::entryfield $site_4_0.fileDialogPropertyFileSize -highlightthickness 0 -labeltext "File Size:" -relief flat -selectborderwidth 0
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyFileSize" "EntryFileSizeFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.fileDialogPropertyFileSize -in $site_4_0 -anchor w -expand 0 -fill x -side top

	::iwidgets::entryfield $site_4_0.fileDialogPropertyFileType -highlightthickness 0 -labeltext "File Type:" -relief flat -selectborderwidth 0
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyFileType" "EntryFileTypeFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.fileDialogPropertyFileType -in $site_4_0 -anchor w -expand 0 -fill x -side top

	::iwidgets::entryfield $site_4_0.fileDialogPropertyLastAccessed -highlightthickness 0 -labeltext "Last Accessed:" -relief flat -selectborderwidth 0
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyLastAccessed" "EntryLastAccessedFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.fileDialogPropertyLastAccessed -in $site_4_0 -anchor w -expand 0 -fill x -side top

	::iwidgets::entryfield $site_4_0.fileDialogPropertyLastModified -highlightthickness 0 -labeltext "Last Modified:" -relief flat -selectborderwidth 0
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyLastModified" "EntryLastModifiedFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.fileDialogPropertyLastModified -in $site_4_0 -anchor w -expand 0 -fill x -side top

	::iwidgets::entryfield $site_4_0.fileDialogPropertyNativeFileName -highlightthickness 0 -labeltext "Native Name:" -relief flat -selectborderwidth 0
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyNativeFileName" "EntryFileNameFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.fileDialogPropertyNativeFileName -in $site_4_0 -anchor w -expand 0 -fill x -side top

	frame $site_3_0.fileDialogPropertyFrameBottom -borderwidth 1 -height 89 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.fileDialogPropertyFrameBottom" "FrameBottomFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.fileDialogPropertyFrameBottom

	label $site_4_0.fileDialogPropertyOwnerLabel -text "Owner"
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyOwnerLabel" "LabelOwnerFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyOwnerLabel -x 50 -y 5 -anchor nw -bordermode ignore

	label $site_4_0.fileDialogPropertyOtherLabel -text "Other"
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyOtherLabel" "LabelOtherFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyOtherLabel -x 135 -y 5 -anchor nw -bordermode ignore

	label $site_4_0.fileDialogPropertyWriteLabel -text "Write:" 
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyWriteLabel" "LabelWriteFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyWriteLabel -x 20 -y 45 -anchor nw -bordermode ignore

	label $site_4_0.fileDialogPropertyExecuteLabel -text "Execute:" 
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyExecuteLabel" "LabelExecuteFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyExecuteLabel -x 5 -y 70 -anchor nw -bordermode ignore

	checkbutton $site_4_0.fileDialogPropertyOwnerReadCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -variable filedialogpropertyownerreadcheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyOwnerReadCheckButton" "CheckButtonOwnerReadFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyOwnerReadCheckButton -x 70 -y 20 -width 21 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyOwnerReadCheckButton "Owner Read Permission"


	checkbutton $site_4_0.fileDialogPropertyGroupReadCheckButton -highlightthickness 0 -command {
		 set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -variable filedialogpropertygroupreadcheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyGroupReadCheckButton" "CheckButtonGroupReadFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyGroupReadCheckButton -x 110 -y 20 -width 21 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyGroupReadCheckButton "Group Read Permission"


	checkbutton $site_4_0.fileDialogPropertyOtherReadCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -variable filedialogpropertyotherreadcheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyOtherReadCheckButton" "CheckButtonOtherReadFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyOtherReadCheckButton -x 145 -y 20 -width 21 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyOtherReadCheckButton "Other (Public) Read Permission"

	checkbutton $site_4_0.fileDialogPropertyOwnerWriteCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -variable filedialogpropertyownerwritecheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyOwnerWriteCheckButton" "CheckButtonOwnerWriteFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyOwnerWriteCheckButton -x 70 -y 45 -width 21 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyOwnerWriteCheckButton "Owner Permission"


	checkbutton $site_4_0.fileDialogPropertyGroupWriteCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -variable filedialogpropertygroupwritecheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyGroupWriteCheckButton" "CheckButtonGroupWriteFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyGroupWriteCheckButton -x 110 -y 45 -width 21 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyGroupWriteCheckButton "Group Write Permission"

	checkbutton $site_4_0.fileDialogPropertyOtherWriteCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -variable filedialogpropertyotherwritecheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyOtherWriteCheckButton" "CheckButtonOtherWriteFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyOtherWriteCheckButton -x 145 -y 45 -width 21 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyOtherWriteCheckButton "Other (Public) Write Permission"

	checkbutton $site_4_0.fileDialogPropertyOwnerExecuteCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -variable filedialogpropertyownerexecutecheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyOwnerExecuteCheckButton" "CheckButtonOwnerExecuteFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyOwnerExecuteCheckButton -x 70 -y 70 -width 21 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyOwnerExecuteCheckButton "Owner Execute Permission"

	checkbutton $site_4_0.fileDialogPropertyGroupExecuteCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -variable filedialogpropertygroupexecutecheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyGroupExecuteCheckButton" "CheckButtonGroupExecuteFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyGroupExecuteCheckButton -x 110 -y 70 -width 21 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyGroupExecuteCheckButton "Group Execute Permission"

	checkbutton $site_4_0.fileDialogPropertyOtherExecuteCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -variable filedialogpropertyotherexecutecheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyOtherExecuteCheckButton" "CheckButtonOtherExecuteFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyOtherExecuteCheckButton -x 145 -y 70 -width 21 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyOtherExecuteCheckButton "Other (Public) Execute Permission"

	checkbutton $site_4_0.fileDialogPropertySuidCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -text "Suid" -variable filedialogpropertysuidcheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertySuidCheckButton" "CheckButtonSUIDFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertySuidCheckButton -x 190 -y 20 -width 60 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertySuidCheckButton "SUID Permission"

	checkbutton $site_4_0.fileDialogPropertyGuidCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -text "Guid" -variable filedialogpropertyguidcheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyGuidCheckButton" "CheckButtonGUIDFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyGuidCheckButton -x 190 -y 45 -width 60 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyGuidCheckButton "GUID Permission"

	checkbutton $site_4_0.fileDialogPropertyStickyCheckButton -highlightthickness 0 -command {
		set noChangesPermissions 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
	} -text "Sticky" -variable filedialogpropertystickycheckbutton
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyStickyCheckButton" "CheckButtonStickyFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyStickyCheckButton -x 196 -y 70 -width 60 -height 22 -anchor nw -bordermode ignore
	balloon $site_4_0.fileDialogPropertyStickyCheckButton "Sticky Permission"

	label $site_4_0.fileDialogPropertyGroupLabel -text "Group" 
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyGroupLabel" "LabeGroupFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyGroupLabel -x 95 -y 5 -anchor nw -bordermode ignore

	label $site_4_0.fileDialogPropertyReadLabel -text "Read:" 
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyReadLabel" "LabeReadFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyReadLabel -x 20 -y 20 -anchor nw -bordermode ignore

	::iwidgets::combobox $site_4_0.fileDialogPropertyOwnerComboBox \
        -command {namespace inscope ::iwidgets::Combobox {::.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerComboBox _addToList}}\
        -selectioncommand {
		set noChangesOwnerGroup 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
        } -labelpos n -labeltext "Owner"
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyOwnerComboBox" "ComboBoxOwnerFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyOwnerComboBox -x 310 -y 0 -width 135 -height 52 -anchor nw -bordermode ignore

	::iwidgets::combobox $site_4_0.fileDialogPropertyGroupComboBox \
        -command {namespace inscope ::iwidgets::Combobox {::.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupComboBox _addToList}}\
        -selectioncommand {
		set noChangesOwnerGroup 1
		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state normal
        } -labelpos n -labeltext "Group"
	vTcl:DefineAlias "$site_4_0.fileDialogPropertyGroupComboBox" "ComboBoxGroupFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
	place $site_4_0.fileDialogPropertyGroupComboBox -x 310 -y 45 -width 135 -height 52 -anchor nw -bordermode ignore

	pack $site_3_0.fileDialogPropertyFrameTop -in $site_3_0 -anchor center -expand 1 -fill both -side top
	pack $site_3_0.fileDialogPropertyFrameBottom -in $site_3_0 -anchor center -expand 1 -fill both -side top

	::iwidgets::buttonbox $top.filePropertyButtonBox -padx 0 -pady 0
	vTcl:DefineAlias "$top.filePropertyButtonBox" "ButtonBoxFilePropertyDialog" vTcl:WidgetProc "Toplevel1" 1
######################
# Start Apply Button
	$top.filePropertyButtonBox add but0 -background #d9d9d9 -command {
		if {$noChangesPermissions == 1 || $noChangesOwnerGroup == 1} {
			if {$noChangesPermissions == 1} {
				set ownerPermissionsNumber  [expr ($filedialogpropertyownerreadcheckbutton * 4) + ($filedialogpropertyownerwritecheckbutton * 2) + $filedialogpropertyownerexecutecheckbutton]
				set groupPermissionsNumber  [expr ($filedialogpropertygroupreadcheckbutton * 4) + ($filedialogpropertygroupwritecheckbutton * 2) + $filedialogpropertygroupexecutecheckbutton]
				set otherPermissionsNumber [expr ($filedialogpropertyotherreadcheckbutton * 4) + ($filedialogpropertyotherwritecheckbutton * 2) + $filedialogpropertyotherexecutecheckbutton]
				set filePermissionsNumber {0}
				if {$filedialogpropertysuidcheckbutton == 1} {
					set filePermissionsNumber {04}
				}
				if {$filedialogpropertyguidcheckbutton == 1} {
					set filePermissionsNumber {02}
				}
				if {$filedialogpropertystickycheckbutton == 1} {
					set filePermissionsNumber {01}
				}
				append filePermissionsNumber $ownerPermissionsNumber $groupPermissionsNumber $otherPermissionsNumber
				set r [catch [file attributes  $dirpathPropertyTmp -permissions $filePermissionsNumber]]
				set noChangesPermissions 0
			}
			if {$noChangesOwnerGroup == 1} {
				set fileOwner [.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyOwnerComboBox getcurselection]
				set fileGroup [.fileDialogProperties.filePropertyFrame.fileDialogPropertyFrameBottom.fileDialogPropertyGroupComboBox getcurselection]
				set r [file attributes  $dirpathPropertyTmp -owner $fileOwner ]
				set r [file attributes  $dirpathPropertyTmp  -group $fileGroup]
				set noChangesOwnerGroup 0
			}
	 		.fileDialogProperties.filePropertyButtonBox buttonconfigure 0 -state disable
	       }
	 } -text "Apply"
# End Apply Button
######################
######################
# Start Close Button
	$top.filePropertyButtonBox add but1 -background #d9d9d9 -command {destroy window .fileDialogProperties} -text "Close"
# End Close Button
######################
######################
# Start Help Button
	$top.filePropertyButtonBox add but2 -background #d9d9d9 -command {} -text "Help"
# End Help Button
######################
    ###################
	pack $top.filePropertyFrame -in $top -anchor center -expand 1 -fill both -side top
	pack propagate $top.filePropertyButtonBox 0
	grid propagate $top.filePropertyButtonBox 0
	pack $top.filePropertyButtonBox -in $top -anchor center -expand 1 -fill both -side bottom

	vTcl:FireEvent $base <<Ready>>
}
#
#
# End file properties dialog box
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################


############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start Find File Dialog Box
#
#
proc vTclWindow.findFileDialog {base} {
	global PPref screenx screeny
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-425)/2)]
	set yCord [expr int(($screeny-120)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .findFileDialog}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel
	wm focusmodel $top passive
	wm geometry $top 425x120+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 425 120
	wm overrideredirect $top 0
	wm resizable $top 1 0
	wm deiconify $top
	wm title $top "Find File..."
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {destroy window .findFileDialog}

	::iwidgets::entryfield $top.entryFindFileDialog -background #e6e6e6 -command {findFileDialogSearch}  -labeltext "Search For:"
	vTcl:DefineAlias "$top.entryFindFileDialog" "EntryFindFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $top.entryFindFileDialog -in $top -anchor center -expand 0 -fill x -side top

	::iwidgets::combobox $top.comboboxFindFileDialog \
        -command {namespace inscope ::iwidgets::Combobox {::.findFileDialog.comboboxFindFileDialog _addToList}}\
        -labeltext "Start Directory:" -selectioncommand {}
	vTcl:DefineAlias "$top.comboboxFindFileDialog" "ComboBoxFindFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $top.comboboxFindFileDialog -in $top -anchor center -expand 0 -fill x -side top

	::iwidgets::buttonbox $top.buttonboxFindFileDialog -padx 0 -pady 0
	vTcl:DefineAlias "$top.buttonboxFindFileDialog" "ButtonBoxFindFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack propagate $top.buttonboxFindFileDialog 0
	grid propagate $top.buttonboxFindFileDialog 0
	pack $top.buttonboxFindFileDialog -in $top -anchor center -expand 0 -fill x -side bottom

	$top.buttonboxFindFileDialog add but0 -command {findFileDialogSearch} -text "Search"
	$top.buttonboxFindFileDialog add but1 -command {
#		destroy window .findFileDialog
#		redoFileDialogListBox
	} -text "Stop"
	$top.buttonboxFindFileDialog add but2 -command {
		destroy window .findFileDialog
		redoFileDialogListBox
	} -text "Cancel"
	$top.buttonboxFindFileDialog add but3 -command {} -text "Help"

	frame $top.frameTop -height 20 -highlightcolor black -relief groove -width 400  -border 0
	vTcl:DefineAlias "$top.frameTop" "FrameTopFindFileDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.frameTop

	checkbutton $site_3_0.casesenitiveButtonFindFileDialog -highlightthickness 0 \
	-text "Case Sensitive" -offvalue "No" -onvalue "Case Sensitive" -variable caseSensitiveFind
	vTcl:DefineAlias "$site_3_0.casesenitiveButtonFindFileDialog" "CheckButtonCaseSensitiveFindFileDialog" vTcl:WidgetProc "Toplevel1" 1
	balloon $site_3_0.casesenitiveButtonFindFileDialog "Select whether search is case sensitive or not."
	pack $site_3_0.casesenitiveButtonFindFileDialog -in $site_3_0 -anchor n -expand 1 -fill x -padx 1 -side left

	checkbutton $site_3_0.exactmatchButtonFindFileDialog -highlightthickness 0 \
        -text "Exact Match" -offvalue "No" -onvalue "Exact Match" -variable exactMatchFind
	vTcl:DefineAlias "$site_3_0.exactmatchButtonFindFileDialog" "CheckButtonExactMatchFindFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.exactmatchButtonFindFileDialog -in $site_3_0 -anchor n -expand 1 -fill x -padx 1 -side left
	balloon $site_3_0.exactmatchButtonFindFileDialog "Partial or exact match."

	checkbutton $site_3_0.recursiveButtonFindFileDialog -highlightthickness 0 \
	-text "Recursive" -offvalue "No" -onvalue "Recursive" -variable recursiveFind
	vTcl:DefineAlias "$site_3_0.recursiveButtonFindFileDialog" "CheckButtonRecursiveFindFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_0.recursiveButtonFindFileDialog -in $site_3_0 -anchor n -expand 1 -fill x -padx 1 -side left
	balloon $site_3_0.recursiveButtonFindFileDialog "Recursive"

	pack $top.frameTop -in $top -anchor n -expand 1 -fill x -padx 1 -side top

	frame $top.frameBottom -height 20 -highlightcolor black -relief groove -width 400  -border 0
	vTcl:DefineAlias "$top.frameBottom" "FrameBottonFindFileDialog" vTcl:WidgetProc "Toplevel1" 1

	set site_3_1 $top.frameBottom

	radiobutton $site_3_1.searchForFileileRadioButton \
	-command {
		focus .findFileDialog.frameBottom.searchForFileileRadioButton
		.findFileDialog.frameBottom.searchInsideFileileRadioButton deselect
	} -highlightthickness 0 -text "Search For File" -value "Search For File" -variable searchForFileRadioButton
	vTcl:DefineAlias "$site_3_1.searchForFileileRadioButton" "RadioButtonFileSearchFindFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_1.searchForFileileRadioButton -in $site_3_1 -anchor w -expand 0 -fill none -padx 20 -side left

	radiobutton $site_3_1.searchInsideFileileRadioButton \
	-command {
		focus .findFileDialog.frameBottom.searchInsideFileileRadioButton
		.findFileDialog.frameBottom.searchForFileileRadioButton deselect
	} -highlightthickness 0 -text "Search Inside File" -value {Search Inside File} -variable searchInsideFileRadioButton
	vTcl:DefineAlias "$site_3_1.searchInsideFileileRadioButton" "RadioButtonInFileSearchFindFileDialog" vTcl:WidgetProc "Toplevel1" 1
	pack $site_3_1.searchInsideFileileRadioButton -in $site_3_1 -anchor w -expand 0 -fill none -padx 20 -side right

	pack $top.frameBottom -in $top -anchor s -expand 1 -fill x -padx 1 -side bottom

	vTcl:FireEvent $base <<Ready>>
}
#
#
# End Find File Dialog Box
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################

#############################################################################
## Procedure:  findFileDialogSearch

proc ::findFileDialogSearch {} {
 		global caseSensitiveFind exactMatchFind recursiveFind
		global searchPattern searchDirectory  recursiveSearchPath
		global recursiveStructure recursiveCount
		
		set findList ""
		set searchPattern [.findFileDialog.entryFindFileDialog get]
		set searchDirectory [.findFileDialog.comboboxFindFileDialog get]
 
		if {$caseSensitiveFind == "Case Sensitive"} {}
		if {$exactMatchFind == "Exact Match"} {}
		if {$searchPattern == ""} {set searchPattern "*"}
		set findList [lsort [glob -nocomplain -directory $searchDirectory $searchPattern]]
		if {$findList != ""} {
			ScrolledListBoxFileViewFileDialog clear	
			foreach findListItem $findList {ScrolledListBoxFileViewFileDialog insert end $findListItem}
# Delete what is in there now
			EntryFileNameFileDialog delete 0 end
# Replace with the clicked (selected) file
			EntryFileNameFileDialog insert end [string range [lindex $findList 0] [expr [string last  "/" [lindex $findList 0] ] +1] end]
			ScrolledListBoxFileViewFileDialog selection set 0
		}
		
		if {$recursiveFind == "Recursive"} {
		set recursiveStructure ""
		set recursiveCount 0
			foreach item [lsort [glob -nocomplain -directory $searchDirectory *]] {
				if {[file isdirectory $item]} {
#					set recursiveStructure($recursiveCount) $item
					incr recursiveCount
					
#					set recursiveSearchPath $item
#					append recursiveSearchPath $searchDirectory "/" $item
#					findFileDialogResursiveSearch
				
				}
			}

		}
}
## End findFileDialogSearch
#############################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start File Rename Dialog
#
#
proc vTclWindow.fileRename {base} {
	global fileRename newFileRename fileRenameConfirm fileDisplayType
	global PPref screenx screeny fileRename
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-300)/2)]
	set yCord [expr int(($screeny-75)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .fileRename}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black
	wm withdraw $top
	wm focusmodel $top passive
	wm geometry $top 300x75+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 1 1
	wm overrideredirect $top 0
	wm resizable $top 1 0
	wm title $top "Rename File or Directory..."
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {destroy window .fileRename}

	::iwidgets::entryfield $top.entryNewFileNameFileRenameOldFileName -labeltext "Rename " -highlightthickness 0 \
	-textvariable RenameDisplay -relief flat -command {}
	vTcl:DefineAlias "$top.entryNewFileNameFileRenameOldFileName" "EntryOldFileNameFileRename" vTcl:WidgetProc "Toplevel1" 1

	::iwidgets::entryfield $top.entryNewFileNameFileRename -labeltext "To " -command {
		if {[.fileRename.entryNewFileNameFileRename get] == "" } {
			tk_messageBox -message {File name must not be left blank !}
		} else {
			set newFileRename [.fileRename.entryNewFileNameFileRename get]
			destroy window .fileRename
		}
	}
	vTcl:DefineAlias "$top.entryNewFileNameFileRename" "EntryNewNameFileRename" vTcl:WidgetProc "Toplevel1" 1

#################################################
# Unsure why this bind doesn't work
	bind $top.entryNewFileNameFileRename.lwchildsite.entry <Key-KP_Enter> {
		if {[.fileRename.entryNewFileNameFileRename get] == "" } {
			tk_messageBox -message {File name must not be left blank !}
		} else {
			set newFileRename [.fileRename.entryNewFileNameFileRename get]
			destroy window .fileRename
		}
	}
	bind $top.entryNewFileNameFileRename.lwchildsite.entry <Key-Return> {
		if {[.fileRename.entryNewFileNameFileRename get] == "" } {
			tk_messageBox -message {File name must not be left blank !}
		} else {
			set newFileRename [.fileRename.entryNewFileNameFileRename get]
			destroy window .fileRename
		}
	}

	::iwidgets::buttonbox $top.buttonBoxFileRename -padx 0 -pady 0
	vTcl:DefineAlias "$top.buttonBoxFileRename" "ButtonBoxFileRename" vTcl:WidgetProc "Toplevel1" 1

	bindtags $top.buttonBoxFileRename "bbox-map bbox-config itk-delete-.fileRename.buttonBoxFileRename $top.buttonBoxFileRename Buttonbox $top all"

	$top.buttonBoxFileRename add but0 -command {
		if {[.fileRename.entryNewFileNameFileRename get] == "" } {
			tk_messageBox -message {File name must not be left blank !}
		} else {
			set newFileRename [.fileRename.entryNewFileNameFileRename get]
			destroy window .fileRename
		}
   	} -text "Rename"
	$top.buttonBoxFileRename add but1 -command {
		set newFileRename ""
		destroy window .fileRename
	} -text "Cancel"
	$top.buttonBoxFileRename add but2 -background #d9d9d9 -text "Help"
	balloon $top.buttonBoxFileRename.1.pushbutton "Rename File or Directory"
	balloon $top.buttonBoxFileRename.2.pushbutton "Cancel And Close"
	balloon $top.buttonBoxFileRename.3.pushbutton "Help Display"

	pack $top.entryNewFileNameFileRenameOldFileName -in $top -anchor nw -expand 1 -fill x -side top   
	pack $top.entryNewFileNameFileRename -in $top -anchor nw -expand 1 -fill x -side top
	pack propagate $top.buttonBoxFileRename 0
#	grid propagate $top.buttonBoxFileRename 0
	pack $top.buttonBoxFileRename -in $top -anchor center -expand 0 -fill none -side bottom

	vTcl:FireEvent $base <<Ready>>
}
#
#
# End File Rename Dialog
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################

############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start Delete Confirm Dialog
#
#

proc vTclWindow.deleteFileConfirm {base} {

    global PPref screenx screeny DeleteConfirmFileName fileDeleteConfirm DeleteConfirmFileName

############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-524)/2)]
	set yCord [expr int(($screeny-60)/2)]
############################################################################
############################################################################    
	if {$base == ""} {set base .deleteFileConfirm}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################

	vTcl:toplevel $top -class Toplevel -highlightcolor black

	wm focusmodel $top passive
	wm geometry $top 524x60+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 1 1
	wm overrideredirect $top 0
	wm resizable $top 1 1
	wm deiconify $top
	wm title $top "Delete Confirmation Of File Or Directory"
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1

	bindtags $top "$top Toplevel all _TopLevel"

	vTcl:FireEvent $top <<Create>>

	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

        bind $top <Escape> {destroy window .deleteFileConfirm}

	frame $top.deleteFileConfirmMasterFrame -borderwidth 0 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$top.deleteFileConfirmMasterFrame" "FrameMasterConfirmFileDelete" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.deleteFileConfirmMasterFrame


	frame $site_3_0.topFrame -borderwidth 0 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.topFrame" "FrameTopConfirmFileDelete" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.topFrame

	label $site_4_0.deleteConfirmFileNameLabel -text $DeleteConfirmFileName -textvariable DeleteConfirmFileName
	vTcl:DefineAlias "$site_4_0.deleteConfirmFileNameLabel" "LabelFileNameConfirmFileDelete" vTcl:WidgetProc "Toplevel1" 1

	pack $site_4_0.deleteConfirmFileNameLabel -in $site_4_0 -anchor center -expand 1 -fill x -side top

	pack $site_3_0.topFrame -in $site_3_0 -anchor center -expand 0 -fill x -side top


	frame $site_3_0.footerFrame -borderwidth 0 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.footerFrame" "FrameFooterConfirmFileDelete" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.footerFrame

	button $site_4_0.deleteFileConfirmDeleteButton -command {
		set fileDeleteConfirm 0
		destroy window .deleteFileConfirm
	}   -text "Delete"
	vTcl:DefineAlias "$site_4_0.deleteFileConfirmDeleteButton" "ButtonDeleteEachConfirmFileDelete" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.deleteFileConfirmDeleteButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.deleteFileConfirmDeleteButton "Delete This File or Directory Only"

	button $site_4_0.deleteFileConfirmAllButton -command {
		set fileDeleteConfirm 1
		destroy window .deleteFileConfirm
	}   -text "All"
	vTcl:DefineAlias "$site_4_0.deleteFileConfirmAllButton" "ButtonDeleteAllConfirmFileDelete" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.deleteFileConfirmAllButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.deleteFileConfirmAllButton "Delete All Files and or Directories Selected"

	button $site_4_0.deleteFileConfirmNoButton -command {
		set fileDeleteConfirm 2
		destroy window .deleteFileConfirm
	}   -text "No"
	vTcl:DefineAlias "$site_4_0.deleteFileConfirmNoButton" "ButtonNoDeleteConfirmFileDelete" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.deleteFileConfirmNoButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.deleteFileConfirmNoButton "No, Skip This File or Directory"

	button $site_4_0.deleteFileConfirmCancelButton -command {
		set fileDeleteConfirm 3
		destroy window .deleteFileConfirm
	}   -text Cancel
	vTcl:DefineAlias "$site_4_0.deleteFileConfirmCancelButton" "ButtonCancelConfirmFileDelete" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.deleteFileConfirmCancelButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.deleteFileConfirmCancelButton "Cancel Delete Operation"

	pack $site_3_0.footerFrame -in $site_3_0 -anchor center -expand 0 -fill x -side bottom
	pack $top.deleteFileConfirmMasterFrame -in $top -anchor center -expand 1 -fill both -side top

	vTcl:FireEvent $base <<Ready>>
}
#
#
# End File Delete Confirm Dialog
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################

############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start Rename File Exist Error Dialog
#
#
proc vTclWindow.renameFileExistError {base} {
	global PPref screenx screeny
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
 	set xCord [expr int(($screenx-272)/2)]
	set yCord [expr int(($screeny-59)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .renameFileExistError}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black 
	wm focusmodel $top passive
	wm geometry $top 272x59+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 1 1
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm deiconify $top
	wm title $top "Error File Exists !"
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {destroy window .renameFileExistError}

	frame $top.renameFileExistErrorMasterFrame -borderwidth 2 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$top.renameFileExistErrorMasterFrame" "FrameMasterFileExistError" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.renameFileExistErrorMasterFrame

	frame $site_3_0.topFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.topFrame" "FrameMiddleFileExistError" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.topFrame

	label $site_4_0.errorMessageLabel -borderwidth 0 -text {File or directory already exist !}
	vTcl:DefineAlias "$site_4_0.errorMessageLabel" "LabelFileExistError" vTcl:WidgetProc "Toplevel1" 1

	pack $site_4_0.errorMessageLabel -in $site_4_0 -anchor center -expand 1 -fill x -side top

	frame $site_3_0.footerFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.footerFrame" "FrameFooterFileExistError" vTcl:WidgetProc "Toplevel1" 1
	set site_4_0 $site_3_0.footerFrame
	button $site_4_0.renameFileExistErrorButton -command {destroy window .renameFileExistError} -text "Ok"
	vTcl:DefineAlias "$site_4_0.renameFileExistErrorButton" "ButtonFileExistError" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.renameFileExistErrorButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.renameFileExistErrorButton "Click here to close."

	pack $site_3_0.topFrame -in $site_3_0 -anchor center -expand 0 -fill x -side top
	pack $site_3_0.footerFrame -in $site_3_0 -anchor center -expand 0 -fill x -side bottom
	pack $top.renameFileExistErrorMasterFrame -in $top -anchor center -expand 1 -fill both -side top

	vTcl:FireEvent $base <<Ready>>
}
#
#
# End Rename File Exist Error Dialog
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################

############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start Paste File Exist Dialog
#
#

proc vTclWindow.pasteFileExistDialog {base} {
	global PPref fileOverwriteConfirm fileCopyCutName PasteOverwriteFileName
	global screenx screeny
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-330)/2)]
	set yCord [expr int(($screeny-60)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .pasteFileExistDialog}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black 
	wm focusmodel $top passive
	wm geometry $top 330x60+$xCord+$yCord; update
	wm maxsize $top 1265 60
	wm minsize $top 330 60
	wm overrideredirect $top 0
	wm resizable $top 1 0
	wm deiconify $top
	wm title $top "Paste File Exists"
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {destroy window .pasteFileExistDialog}

	frame $top.pasteFileExistDialogMasterFrame -borderwidth 0 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$top.pasteFileExistDialogMasterFrame" "FrameMasterPasteFileExist" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.pasteFileExistDialogMasterFrame

	frame $site_3_0.topFrame -borderwidth 0 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.topFrame" "FrameTopPasteFileExist" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.topFrame

	label $site_4_0.pasteOverwriteFileNameLabel -text "label" -textvariable PasteOverwriteFileName
	vTcl:DefineAlias "$site_4_0.pasteOverwriteFileNameLabel" "LabelPasteFileExist" vTcl:WidgetProc "Toplevel1" 1

	pack $site_4_0.pasteOverwriteFileNameLabel -in $site_4_0 -anchor center -expand 1 -fill x -side top

	frame $site_3_0.footerFrame -borderwidth 0 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.footerFrame" "FrameFooterPasteFileExist" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.footerFrame

	button $site_4_0.pasteOverwriteButton -command {
		set fileOverwriteConfirm 0
		destroy window .pasteFileExistDialog
	}  -text "Overwrite"
	vTcl:DefineAlias "$site_4_0.pasteOverwriteButton" "ButtonOverwritePasteFileExist" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.pasteOverwriteButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.pasteOverwriteButton "Overwite This File or Directory"

	button $site_4_0.pasteAllButton -command {
		set fileOverwriteConfirm 1
		destroy window .pasteFileExistDialog
	} -text "All"
	vTcl:DefineAlias "$site_4_0.pasteAllButton" "ButtonAllPasteFileExist" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.pasteAllButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.pasteAllButton "Paste and overwite all file(s) and or directory(s)"

	button $site_4_0.pasteRenameButton -command {
		set fileOverwriteConfirm 2    
		destroy window .pasteFileExistDialog
	} -text "Rename"
	vTcl:DefineAlias "$site_4_0.pasteRenameButton" "ButtonRenamePasteFileExist" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.pasteRenameButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.pasteRenameButton "Rename this file or directory"

	button $site_4_0.pasteNoButton -command {
		set fileOverwriteConfirm 3
		destroy window .pasteFileExistDialog
	} -text "No "
	vTcl:DefineAlias "$site_4_0.pasteNoButton" "ButtonNoPasteFileExist" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.pasteNoButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.pasteNoButton "No, skip this file or directory"

	button $site_4_0.pasteCancelButton -command {
		set fileOverwriteConfirm 4
		destroy window .pasteFileExistDialog
	} -text "Cancel"
	vTcl:DefineAlias "$site_4_0.pasteCancelButton" "ButtonCancelPasteFileExist" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.pasteCancelButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.pasteCancelButton "Cancel This Paste Operation"

	pack $site_3_0.topFrame -in $site_3_0 -anchor center -expand 0 -fill x -side top
	pack $site_3_0.footerFrame -in $site_3_0 -anchor center -expand 0 -fill x -side bottom
	pack $top.pasteFileExistDialogMasterFrame -in $top -anchor center -expand 1 -fill both -side top

    vTcl:FireEvent $base <<Ready>>
}
#
#
# End Paste File Exist Dialog
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################

#
#
#   End File Utility GUIs
#
#
######################################################################################################################################################################
######################################################################################################################################################################
######################################################################################################################################################################
######################################################################################################################################################################
######################################################################################################################################################################
######################################################################################################################################################################

######################################################################################################################################################################
######################################################################################################################################################################
######################################################################################################################################################################
######################################################################################################################################################################
######################################################################################################################################################################
######################################################################################################################################################################
#
#
#   Start General System GUIs
#
#

############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start Blank Entry Error
#


proc vTclWindow.blankEntryError {base} {
	global PPref screenx screeny EntryBlankDialog
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-380)/2)]
	set yCord [expr int(($screeny-60)/2)]
############################################################################
############################################################################    
	if {$base == ""} {set base .blankEntryError}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black 
	wm focusmodel $top passive
	wm geometry $top 380x60+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 380 60
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm deiconify $top
	wm title $top "Blank Entry Error "
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {destroy window .blankEntryError}
	frame $top.blankEntryErrorMasterFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$top.blankEntryErrorMasterFrame" "Frame1" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.blankEntryErrorMasterFrame

	frame $site_3_0.topFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.topFrame" "Frame3" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.topFrame

	label $site_4_0.entryBlankDialogLabel -text "Entry must not be left blank !" -textvariable EntryBlankDialog 
	vTcl:DefineAlias "$site_4_0.entryBlankDialogLabel" "Label1" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.entryBlankDialogLabel -in $site_4_0 -anchor center -expand 0 -fill x -side top

	frame $site_3_0.footerFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.footerFrame" "Frame6" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.footerFrame

	button $site_4_0.okButton -command {destroy window .blankEntryError} -text "Ok"
	vTcl:DefineAlias "$site_4_0.okButton" "Button2" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.okButton -in $site_4_0 -anchor center -expand 1 -fill none -side right
	balloon $site_4_0.okButton "Click here to close."

	pack $site_3_0.topFrame -in $site_3_0 -anchor center -expand 0 -fill x -side top
	pack $site_3_0.footerFrame -in $site_3_0 -anchor center -expand 0 -fill x -side bottom
	pack $top.blankEntryErrorMasterFrame -in $top -anchor center -expand 1 -fill both -side top

	vTcl:FireEvent $base <<Ready>>
}
#
#
#  End Blank Entry Error
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################


############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start Delete Confirm Dialog
#
#
proc vTclWindow.deleteConfirm {base} {

	global PPref screenx screeny DeleteConfirmName DeleteConfirm DeleteConfirmFileName fileDeleteConfirm

############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-524)/2)]
	set yCord [expr int(($screeny-60)/2)]
############################################################################
############################################################################    
	if {$base == ""} {set base .deleteConfirm}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black 
	wm focusmodel $top passive
	wm geometry $top 524x60+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 1 1
	wm overrideredirect $top 0
	wm resizable $top 1 1
	wm deiconify $top
	wm title $top "Delete Confirmation"
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
        bind $top <Escape> {destroy window .deleteConfirm}

	frame $top.deleteConfirmMasterFrame -borderwidth 0 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$top.deleteConfirmMasterFrame" "Frame1" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.deleteConfirmMasterFrame

	frame $site_3_0.topFrame -borderwidth 0 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.topFrame" "Frame3" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.topFrame

	label $site_4_0.deleteConfirmNameLabel -text "label" -textvariable DeleteConfirmName 
	vTcl:DefineAlias "$site_4_0.deleteConfirmNameLabel" "Label3" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.deleteConfirmNameLabel -in $site_4_0 -anchor center -expand 1 -fill x -side top

	frame $site_3_0.footerFrame -borderwidth 0 -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.footerFrame" "Frame6" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.footerFrame

	button $site_4_0.deleteConfirmDeleteButton -command {
		set DeleteConfirm 0
		destroy window .deleteConfirm
	}   -text "Delete "
	vTcl:DefineAlias "$site_4_0.deleteConfirmDeleteButton" "Button1" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.deleteConfirmDeleteButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.deleteConfirmDeleteButton "Delete this file or directory only."

	button $site_4_0.deleteConfirmAllButton -command {
		set DeleteConfirm 1
		destroy window .deleteConfirm
	}   -text "All"
	vTcl:DefineAlias "$site_4_0.deleteConfirmAllButton" "Button2" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.deleteConfirmAllButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.deleteConfirmAllButton "Delete all files and or directories selected"

	button $site_4_0.deleteConfirmNoButton -command {
		set DeleteConfirm 2
		destroy window .deleteConfirm
	}   -text "No"
	vTcl:DefineAlias "$site_4_0.deleteConfirmNoButton" "Button3" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.deleteConfirmNoButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.deleteConfirmNoButton "No, skip this file or directory"

	button $site_4_0.deleteConfirmCancelButton -command {
		set DeleteConfirm 3
		destroy window .deleteConfirm
	}   -text "Cancel"
	vTcl:DefineAlias "$site_4_0.deleteConfirmCancelButton" "Button4" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.deleteConfirmCancelButton -in $site_4_0 -anchor center -expand 1 -fill none -side left
	balloon $site_4_0.deleteConfirmCancelButton "Cancel Delete Operation"

	pack $site_3_0.topFrame -in $site_3_0 -anchor center -expand 0 -fill x -side top
	pack $site_3_0.footerFrame -in $site_3_0 -anchor center -expand 0 -fill x -side bottom
	pack $top.deleteConfirmMasterFrame -in $top -anchor center -expand 1 -fill both -side top

	vTcl:FireEvent $base <<Ready>>
}
#
#
# End Delete Confirm Dialog
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
#  Start single delete confirm dialog
#
#
proc vTclWindow.deleteConfirmSingle {base} {

############################################################################
############################################################################
	global PPref screenx screeny DeleteConfirmName DeleteConfirm DeleteConfirmFileName

############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-310)/2)]
	set yCord [expr int(($screeny-60)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .deleteConfirmSingle}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black 
	wm focusmodel $top passive
	wm geometry $top 310x60+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 310 60
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm deiconify $top
	wm title $top "New Toplevel 1"
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {
		set DeleteConfirm 2
		destroy window .deleteConfirmSingle
	}

	frame $top.deleteConfirmSingleMasterFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$top.deleteConfirmSingleMasterFrame" "FrameMasterConfirmSingleFileDelete" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.deleteConfirmSingleMasterFrame

	frame $site_3_0.middleFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.middleFrame" "FrameMiddleConfirmSingleFileDelete" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.middleFrame

	label $site_4_0.deleteSingleLabel -text "label" -textvariable DeleteConfirmName
	vTcl:DefineAlias "$site_4_0.deleteSingleLabel" "LabelConfirmSingleFileDelete" vTcl:WidgetProc "Toplevel1" 1

	pack $site_4_0.deleteSingleLabel -in $site_4_0 -anchor center -expand 0 -fill x -pady 5 -side top

	frame $site_3_0.footerFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.footerFrame" "FrameFooterConfirmSingleFileDelete" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.footerFrame

	button $site_4_0.noButton -borderwidth 2 -command {
		set DeleteConfirm 2
		destroy window .deleteConfirmSingle
	} -highlightcolor Black -highlightthickness 1 -justify center -relief raised -state normal -text "No"
	pack $site_4_0.noButton -in $site_4_0 -anchor center -expand 1 -fill none -padx 3 -side right
	vTcl:DefineAlias "$site_4_0.noButton" "ButtonNoConfirmSingleFileDelete" vTcl:WidgetProc "Toplevel1" 1

	button $site_4_0.yesButton -borderwidth 2 -command {
		set DeleteConfirm 1
		destroy window .deleteConfirmSingle
	} -highlightthickness 1 -justify center -relief raised -state normal -text "Yes"
	pack $site_4_0.yesButton -in $site_4_0 -anchor center -expand 1 -fill none -padx 3 -side right
	vTcl:DefineAlias "$site_4_0.yesButton" "ButtonYesConfirmSingleFileDelete" vTcl:WidgetProc "Toplevel1" 1

	pack $site_3_0.middleFrame -in $site_3_0 -anchor center -expand 1 -fill both -side top
	pack $site_3_0.footerFrame -in $site_3_0 -anchor center -expand 0 -fill none -side bottom
	pack $top.deleteConfirmSingleMasterFrame -in $top -anchor center -expand 1 -fill both -side top

	vTcl:FireEvent $base <<Ready>>
}

#
#
#  End single delete confirm dialog
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################

############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
#  Start generic confirm dialog
#
#

proc vTclWindow.genericConfirm {base} {

############################################################################
############################################################################
	global PPref screenx screeny GenericConfirmName GenericConfirm GenericConfirmObject

############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-310)/2)]
	set yCord [expr int(($screeny-100)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .genericConfirm}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black 
	wm focusmodel $top passive
	wm geometry $top 310x100+$xCord+$yCord; update
	wm maxsize $top 1265 994
	wm minsize $top 310 100
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm deiconify $top
	wm title $top ""
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind .genericConfirm <Escape> {
		set GenericConfirm 2
		destroy window .genericConfirm
	}

	frame $top.genericConfirmMasterFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$top.genericConfirmMasterFrame" "FrameMasterGenericConfirm" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.genericConfirmMasterFrame

	frame $site_3_0.middleFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.middleFrame" "FrameMiddleGenericConfirm" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.middleFrame

	label $site_4_0.deleteSingleLabel -text label -textvariable GenericConfirmName
	vTcl:DefineAlias "$site_4_0.deleteSingleLabel" "LabelGenericConfirm" vTcl:WidgetProc "Toplevel1" 1

	pack $site_4_0.deleteSingleLabel -in $site_4_0 -anchor center -expand 0 -fill x -pady 5 -side top

	frame $site_3_0.footerFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.footerFrame" "FrameFooterGenericConfirm" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.footerFrame

	button $site_4_0.noButton -borderwidth 2 -command {
		set GenericConfirm 2
		wm withdraw .genericConfirm
		destroy window .genericConfirm
	} -highlightthickness 1 -justify center -relief raised -state normal -text "No"
	pack $site_4_0.noButton -in $site_4_0 -anchor center -expand 1 -fill none -padx 3 -side right
	vTcl:DefineAlias "$site_4_0.noButton" "ButtonNoGenericConfirm" vTcl:WidgetProc "Toplevel1" 1

	button $site_4_0.yesButton -borderwidth 2 -command {
		set GenericConfirm 1
		wm withdraw .genericConfirm
		destroy window .genericConfirm
	} -highlightthickness 1 -justify center -relief raised -state normal -text "Yes"
	pack $site_4_0.yesButton -in $site_4_0 -anchor center -expand 1 -fill none -padx 3 -side right
	vTcl:DefineAlias "$site_4_0.yesButton" "ButtonYesGenericConfirm" vTcl:WidgetProc "Toplevel1" 1

	pack $site_3_0.middleFrame -in $site_3_0 -anchor center -expand 1 -fill both -side top
	pack $site_3_0.footerFrame -in $site_3_0 -anchor center -expand 0 -fill none -side bottom
	pack $top.genericConfirmMasterFrame -in $top -anchor center -expand 1 -fill both -side top

	vTcl:FireEvent $base <<Ready>>
}
#
#
#  End generic confirm dialog
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
#
#
# Start Progress Bar
#
#

proc vTclWindow.progressBar {base} {
	global PPref screenx screeny ProgressBarProgress ProcessedRecords TotalRecords
	global ScaleWidth ProgressPercentComplete ProgressActionTitle ProgressDetailCount
############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-500)/2)]
	set yCord [expr int(($screeny-100)/2)]
	set ScaleWidth [expr $screenx - ($xCord*2)]
############################################################################
############################################################################
	if {$base == ""} {set base .progressBar}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black 
	wm focusmodel $top passive
	wm geometry $top 500x100+$xCord+$yCord; update
	wm maxsize $top 500 100
	wm minsize $top 500 100
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm deiconify $top
	wm title $top "Progress"
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

	frame $top.progressBarMasterFrame -borderwidth 0 -height 75 -highlightcolor black -relief groove -width 125
	vTcl:DefineAlias "$top.progressBarMasterFrame" "FrameMasterProgressBarGeneric" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.progressBarMasterFrame

	frame $site_3_0.topFrame -borderwidth 0 -height 75 -highlightcolor black -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.topFrame" "FrameTopProgressBarGeneric" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.topFrame

	frame $site_4_0.imageFrame -borderwidth 0 -height 75 -highlightcolor black -relief groove -width 125
	vTcl:DefineAlias "$site_4_0.imageFrame" "FrameImageProgressBarGeneric" vTcl:WidgetProc "Toplevel1" 1

	set site_5_0 $site_4_0.imageFrame
	entry $site_5_0.actionTitle  -relief flat-borderwidth 0 -textvariable ProgressActionTitle -highlightthickness 0 -width 20 
	vTcl:DefineAlias "$site_5_0.actionTitle" "EntryActionTitleProgressBarGeneric" vTcl:WidgetProc "Toplevel1" 1
	pack $site_5_0.actionTitle -in $site_5_0 -anchor nw -expand 1 -fill x -side left

	entry $site_5_0.progressDetailCount -relief flat -borderwidth 0 -justify right -textvariable ProgressDetailCount -highlightthickness 0 -width 30
	vTcl:DefineAlias "$site_5_0.progressDetailCount" "EntryDetailCountProgressBarGeneric" vTcl:WidgetProc "Toplevel1" 1
	pack $site_5_0.progressDetailCount -in $site_5_0 -anchor ne -expand 0 -fill none -side right

	pack $site_4_0.imageFrame -in $site_4_0 -anchor center -expand 1 -fill x -side top

	entry $site_4_0.progressPercentComplete -relief flat -borderwidth 0 -textvariable ProgressPercentComplete -highlightthickness 0 -width 3
	vTcl:DefineAlias "$site_4_0.progressPercentComplete" "EntryPercentCompleteProgressBarGeneric" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.progressPercentComplete -in $site_4_0 -anchor center -expand 1 -fill none -side top

	scale $site_4_0.progressBar -bigincrement 0.0 -borderwidth 2 -command {} -from 0.0  -showvalue 0 -highlightthickness 0 \
	-label "" -orient horizontal -relief flat -repeatdelay 300 -repeatinterval 100 -resolution 1.0 -sliderlength 10.0 \
        -sliderrelief flat -tickinterval 0.0 -to 100.0 -troughcolor #c3c3c3 -variable ProgressBarProgress -width 15
	vTcl:DefineAlias "$site_4_0.progressBar" "ScaleProgressBarGeneric" vTcl:WidgetProc "Toplevel1" 1
	pack $site_4_0.progressBar -in $site_4_0 -anchor center -expand 0 -fill x -side bottom
	balloon $site_4_0.progressBar "Progress"


	pack $site_3_0.topFrame -in $site_3_0 -anchor center -expand 1 -fill x -side top

	frame $site_3_0.footerFrame -borderwidth 0 -height 75 -highlightcolor black -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.footerFrame" "FrameFooterProgressBarGeneric" vTcl:WidgetProc "Toplevel1" 1
	set site_4_1 $site_3_0.footerFrame
	button $site_4_1.cancelButton -command {destroy window .progressBar} -text "Cancel"
	pack $site_4_1.cancelButton -in $site_4_1 -anchor center -expand 1 -fill none -side right
	vTcl:DefineAlias "$site_4_1.cancelButton" "ButtonCancelProgressBarGeneric" vTcl:WidgetProc "Toplevel1" 1

	pack $site_3_0.footerFrame -in $site_3_0 -anchor center -expand 0 -fill x -side bottom
	pack $top.progressBarMasterFrame -in $top -anchor center -expand 1 -fill both -side top

	vTcl:FireEvent $base <<Ready>>
}
#
#
# End Progress Bar
#
#
############################################################################################################
############################################################################################################

############################################################################################################
############################################################################################################
#
#
#  Start generic info dialog
#
#

proc vTclWindow.genericInfo {base} {
############################################################################
############################################################################
	global PPref screenx screeny GenericConfirmName GenericConfirm GenericConfirmObject

############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
	set xCord [expr int(($screenx-400)/2)]
	set yCord [expr int(($screeny-200)/2)]
############################################################################
############################################################################
	if {$base == ""} {set base .genericInfo}
	if {[winfo exists $base]} {wm deiconify $base; return}
	set top $base
###################
# CREATING WIDGETS
###################
	vTcl:toplevel $top -class Toplevel -highlightcolor black 
	wm focusmodel $top passive
	wm geometry $top 400x200+$xCord+$yCord; update
	wm maxsize $top 400 200
	wm minsize $top 400 200
	wm overrideredirect $top 0
	wm resizable $top 0 0
	wm deiconify $top
	wm title $top ""
	vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {
		set GenericConfirm 2
		destroy window .genericInfo
	}

	frame $top.genericInfoMasterFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$top.genericInfoMasterFrame" "FrameMasterGenericInfo" vTcl:WidgetProc "Toplevel1" 1

	set site_3_0 $top.genericInfoMasterFrame

	frame $site_3_0.middleFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.middleFrame" "FrameMiddleGenericInfo" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.middleFrame

	label $site_4_0.deleteSingleLabel -text label -textvariable GenericConfirmName
	vTcl:DefineAlias "$site_4_0.deleteSingleLabel" "LabelGenericInfo" vTcl:WidgetProc "Toplevel1" 1

	pack $site_4_0.deleteSingleLabel -in $site_4_0 -anchor center -expand 0 -fill x -pady 5 -side top

	frame $site_3_0.footerFrame -height 75 -relief groove -width 125
	vTcl:DefineAlias "$site_3_0.footerFrame" "FrameFooterGenericInfo" vTcl:WidgetProc "Toplevel1" 1

	set site_4_0 $site_3_0.footerFrame

	button $site_4_0.closeButton -borderwidth 2 -command {
		set GenericConfirm 2
		destroy window .genericInfo
	} -justify center -relief raised -state normal -text "Close"
	pack $site_4_0.closeButton -in $site_4_0 -anchor center -expand 1 -fill none -padx 3 -side right
	vTcl:DefineAlias "$site_4_0.closeButton" "ButtonCloseGenericInfo" vTcl:WidgetProc "Toplevel1" 1

	pack $site_3_0.middleFrame -in $site_3_0 -anchor center -expand 1 -fill both -side top
	pack $site_3_0.footerFrame -in $site_3_0 -anchor center -expand 0 -fill none -side bottom
	pack $top.genericInfoMasterFrame -in $top -anchor center -expand 1 -fill both -side top

	vTcl:FireEvent $base <<Ready>>
}


#
#
#  End generic info dialog
#
#
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
