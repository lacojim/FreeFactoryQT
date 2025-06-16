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
# Program:Settings.tcl
#
# This is the Settings gui for FreeFactory.
#
#############################################################################
proc vTclWindow.settings {base} {

##########################
# System Variables
	global PPref PPrefTmp screenx screeny PPrefRestore RedSliderValue GreenSliderValue BlueSliderValue
	global DateFormatVar TimeFormatVar ShortLongSeparater TimeSeparater DisplayDayOfWeek
	global currentColorWidget
	global SelectAllText ConfirmFileSaves ConfirmFileDeletions SettingsCancelConfirm ShowToolTips PDFReaderPath
	global env
##########################
# Company Variables
	global TheCompanyName

##########################
# Free Factory variables
	global FreeFactoryDataDirectoryPath FreeFactoryDataFileName SaveFilePath DeleteSource DeleteConversionLogs EnableFactory
	global FactoryDescription NotifyDirectoryEntry SelectedFactory OutputFileSuffixEntry FFMxProgram OutputDirectoryEntry
	global FTPProgram FTPURLEntry FTPUserNameEntry FTPPasswordEntry FTPRemotePathEntry FTPTransferType FTPDeleteAfter
	global RunFrom FactoryLinks FreeFactoryAction FactoryEnableEMail FactoryEMailNameEntry FactoryEMailAddressEntry FactoryEMailsName
	global FactoryEMailsAddress FactoryEMailMessage GlobalEMailMessage

##########################
# Settings Variables
	global settingsRedColorEntryVar settingsGreenColorEntryVar settingsBlueColorEntryVar EntryExampleSettings
	global SysFont TotalElements SysFontFoundry TotalElementsFoundry SysFontFamily TotalElementsFamily SysFontWeight TotalElementsWeight
 	global TotalFoundry TotalFamily
	global tmpFoundry tmpFamily tmpWeight tmpSlant tmpPointSize readline
	global FontsOverstrikeCheckBox FontsUnderlineCheckBox

############################################################################
############################################################################
# This positions the window on the screen.  It uses the screen size information to determine
# placement.
    set xCord [expr int(($screenx-530)/2)]
    set yCord [expr int(($screeny-590)/2)]
############################################################################
############################################################################
    if {$base == ""} {set base .settings}
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel -background #e9e9e9 -highlightbackground #e9e9e9 -highlightcolor #000000
    wm focusmodel $top passive
    wm geometry $top 530x590+$xCord+$yCord; update
    wm maxsize $top 530 590
    wm minsize $top 530 590
    wm overrideredirect $top 0
    wm resizable $top 0 0
    wm title $top "Free Factory Settings for $TheCompanyName"
    vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
    bind $top <Escape> {destroy window .settings}
    bind $top <Control-Right> {.settings.settingsTabNotebook next}
    bind $top <Control-Left> {.settings.settingsTabNotebook prev}
    bind $top <F1> {exec $PPref(PDFReaderPath) "/opt/FreeFactory/Docs/Documentation.pdf" &}

    bind $top <ButtonRelease-3> {
	tk_messageBox -message %W
	}

	::iwidgets::tabnotebook $top.settingsTabNotebook -angle 0 -height 600 -raiseselect 1 -tabborders 1 \
	-tabforeground Black -tabpos n -width 250 -borderwidth 0
	vTcl:DefineAlias "$top.settingsTabNotebook" "TabNoteBookSettings" vTcl:WidgetProc "Toplevel1" 1

	$top.settingsTabNotebook add -command {} -disabledforeground #a3a3a3 -label "Display"
	$top.settingsTabNotebook add -command {} -disabledforeground #a3a3a3 -label "Date/Time"
	$top.settingsTabNotebook add -command {} -disabledforeground #a3a3a3 -label "Notification"
	$top.settingsTabNotebook add -command {} -disabledforeground #a3a3a3 -label "Free Factory"
	$top.settingsTabNotebook add -command {} -disabledforeground #a3a3a3 -label "Misc"

	set site_8_0 [lindex [$top.settingsTabNotebook childsite] 0]

	::iwidgets::labeledframe $site_8_0.settingsColorMonitorDisplayFrame -labelpos nw -labeltext "Sample Display" -relief groove
	vTcl:DefineAlias "$site_8_0.settingsColorMonitorDisplayFrame" "LabeledFrameMonitorDisplaySettings" vTcl:WidgetProc "Toplevel1" 1

	set site_10_0 [$site_8_0.settingsColorMonitorDisplayFrame childsite]

	frame $site_10_0.frameSampleListBox -height 30 -background #ececec -relief flat -width 530  -borderwidth 0
	vTcl:DefineAlias "$site_10_0.frameSampleListBox" "FrameSampleListBox" vTcl:WidgetProc "Toplevel1" 1

	set site_10_0_0 $site_10_0.frameSampleListBox

	::iwidgets::scrolledlistbox $site_10_0_0.settingsColorSampleListBox -selectmode extended \
	-dblclickcommand {} -height 60 -hscrollmode dynamic -selectioncommand {} -vscrollmode dynamic -width 350
	vTcl:DefineAlias "$site_10_0_0.settingsColorSampleListBox" "ScrolledListBoxColorSampleSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_0_0.settingsColorSampleListBox -in $site_10_0_0 -anchor nw -expand 1 -fill both -side left

	button $site_10_0_0.settingsColorButtonSample -highlightthickness 0 -text "Sample"
	vTcl:DefineAlias "$site_10_0_0.settingsColorButtonSample" "ButtonColorSampleSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_0_0.settingsColorButtonSample -in $site_10_0_0 -anchor center -expand 1 -fill none -side right
	balloon $site_10_0_0.settingsColorButtonSample "Sample Tool Tip."

	pack $site_10_0.frameSampleListBox -in $site_10_0 -anchor nw -expand 1 -fill both -side top

	::iwidgets::entryfield $site_10_0.settingsColorSampleLabelEntry -command {} -highlightthickness 0 \
	-labeltext "Sample" -textvariable EntryExampleSettings1
	vTcl:DefineAlias "$site_10_0.settingsColorSampleLabelEntry" "EntrySampleLabelSettings" vTcl:WidgetProc "Toplevel1" 1
	vTcl:DefineAlias "$site_10_0.settingsColorSampleLabelEntry.lwchildsite.entry" "EntrySampleLabelSettingsEntry" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_0.settingsColorSampleLabelEntry -in $site_10_0 -anchor nw -expand 1 -fill both -side top

	pack $site_8_0.settingsColorMonitorDisplayFrame -in $site_8_0 -anchor nw  -expand 1 -fill both -side top

	::iwidgets::labeledframe $site_8_0.settingsColorAdjustFrame -labelpos nw -labeltext "Color Adjustment" -relief groove
	vTcl:DefineAlias "$site_8_0.settingsColorAdjustFrame" "LabeledFrameColorAdjustmentSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_10_1 [$site_8_0.settingsColorAdjustFrame childsite]

	frame $site_10_1.frameColorAdjustMaster -height 30 -relief flat -width 430  -borderwidth 0
	vTcl:DefineAlias "$site_10_1.frameColorAdjustMaster" "FrameColorAdjustMaster" vTcl:WidgetProc "Toplevel1" 1

	set site_10_1_Master $site_10_1.frameColorAdjustMaster

	frame $site_10_1_Master.frameColorAdjustLeft -height 30 -relief flat -width 430  -borderwidth 0
	vTcl:DefineAlias "$site_10_1_Master.frameColorAdjustLeft" "FrameColorAdjustLeft" vTcl:WidgetProc "Toplevel1" 1

	set site_10_1_0 $site_10_1_Master.frameColorAdjustLeft

	frame $site_10_1_0.frameRedSliderBackground -height 30 -relief flat -width 430  -borderwidth 0
	vTcl:DefineAlias "$site_10_1_0.frameRedSliderBackground" "FrameRedSlider" vTcl:WidgetProc "Toplevel1" 1

	set site_10_1_0_1 $site_10_1_0.frameRedSliderBackground

	label $site_10_1_0_1.redBackGroundLabel -text "Red   " -background #ececec
	vTcl:DefineAlias "$site_10_1_0_1.redBackGroundLabel" "LabelRedBackGround" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_0_1.redBackGroundLabel -in $site_10_1_0_1 -anchor w -expand 0 -padx 2 -fill none -side left

	scale $site_10_1_0_1.redBackgroundSlider -activebackground #ececec -background #ececec -bigincrement 0 -troughcolor #ff0000 \
	-borderwidth 1 -command {} -foreground Black -from 0 -highlightbackground #d9d9d9 -highlightcolor Black \
	-highlightthickness 1 -label "" -orient horizontal -relief sunken -resolution 1.0 -showvalue 0 -sliderlength 20 \
	-sliderrelief raised -state normal -tickinterval 0 -to 255 -variable RedSliderValue -width 12
	vTcl:DefineAlias "$site_10_1_0_1.redBackgroundSlider" "RedColorAdjustSlider" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_0_1.redBackgroundSlider -in $site_10_1_0_1 -anchor center -expand 1 -fill x -side left
	bind $site_10_1_0_1.redBackgroundSlider <Motion> {modifyColor}

	entry $site_10_1_0_1.settingsRedColorEntry -textvariable RedSliderValue -width 5 -justify right
	vTcl:DefineAlias "$site_10_1_0_1.settingsRedColorEntry" "EntryRedSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_0_1.settingsRedColorEntry -in $site_10_1_0_1 -anchor center -expand 0 -fill none -side left
	bind $site_10_1_0_1.settingsRedColorEntry <KeyPress> {modifyColor}

	pack $site_10_1_0.frameRedSliderBackground -in $site_10_1_0 -anchor w -expand 0 -fill x -side top

	frame $site_10_1_0.frameGreenSliderBackground -height 30 -background #ececec -relief flat -width 430  -border 1
	vTcl:DefineAlias "$site_10_1_0.frameGreenSliderBackground" "FrameGreenSlider" vTcl:WidgetProc "Toplevel1" 1

	set site_10_1_0_2 $site_10_1_0.frameGreenSliderBackground

	label $site_10_1_0_2.greenBackGroundLabel -text "Green" -background #ececec
	vTcl:DefineAlias "$site_10_1_0_2.greenBackGroundLabel" "LabelGreenBackGround" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_0_2.greenBackGroundLabel -in $site_10_1_0_2 -anchor w -expand 0 -fill none -side left

	scale $site_10_1_0_2.greenBackgroundSlider -activebackground #ececec -background #ececec -bigincrement 0 -troughcolor #00ff00 \
	-borderwidth 1 -command {} -foreground Black -from 0 -highlightbackground #d9d9d9 -highlightcolor Black \
	-highlightthickness 1 -label "" -orient horizontal -relief sunken -resolution 1.0 -showvalue 0 -sliderlength 20 \
	-sliderrelief raised -state normal -tickinterval 0 -to 255 -variable GreenSliderValue -width 12
	vTcl:DefineAlias "$site_10_1_0_2.greenBackgroundSlider" "GreenColorAdjustSlider" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_0_2.greenBackgroundSlider -in $site_10_1_0_2 -anchor center -expand 1 -fill x -side left
	bind $site_10_1_0_2.greenBackgroundSlider <Motion> {modifyColor}

	entry $site_10_1_0_2.settingsGreenColorEntry -textvariable GreenSliderValue -width 5 -justify right
	vTcl:DefineAlias "$site_10_1_0_2.settingsGreenColorEntry" "EntryGreenSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_0_2.settingsGreenColorEntry -in $site_10_1_0_2 -anchor center -expand 0 -fill none -side left
	bind $site_10_1_0_2.settingsGreenColorEntry <KeyPress> {modifyColor}

	pack $site_10_1_0.frameGreenSliderBackground -in $site_10_1_0 -anchor w -expand 0 -fill x -side top

	frame $site_10_1_0.frameBlueSliderBackground -height 30 -background #ececec -relief flat -width 430  -border 1
	vTcl:DefineAlias "$site_10_1_0.frameBlueSliderBackground" "FrameBlueSlider" vTcl:WidgetProc "Toplevel1" 1

	set site_10_1_0_3 $site_10_1_0.frameBlueSliderBackground

	label $site_10_1_0_3.blueBackGroundLabel -text "Blue  " -background #ececec
	vTcl:DefineAlias "$site_10_1_0_3.blueBackGroundLabel" "LabelBlueBackGround" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_0_3.blueBackGroundLabel -in $site_10_1_0_3 -anchor w -expand 0 -padx 1 -fill none -side left

	scale $site_10_1_0_3.blueBackgroundSlider -activebackground #ececec -background #ececec -bigincrement 0 -troughcolor #0000ff \
	-borderwidth 1 -command {} -foreground Black -from 0 -highlightbackground #d9d9d9 -highlightcolor Black \
	-highlightthickness 1 -label "" -orient horizontal -relief sunken -resolution 1.0 -showvalue 0 -sliderlength 20 \
	-sliderrelief raised -state normal -tickinterval 0 -to 255 -variable BlueSliderValue -width 12
	vTcl:DefineAlias "$site_10_1_0_3.blueBackgroundSlider" "BlueColorAdjustSlider" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_0_3.blueBackgroundSlider -in $site_10_1_0_3 -anchor center -expand 1 -fill x -side left
	bind $site_10_1_0_3.blueBackgroundSlider <Motion> {modifyColor}

	entry $site_10_1_0_3.settingsBlueColorEntry -textvariable BlueSliderValue  -width 5 -justify right
	vTcl:DefineAlias "$site_10_1_0_3.settingsBlueColorEntry" "EntryBlueSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_0_3.settingsBlueColorEntry -in $site_10_1_0_3 -anchor center -expand 0 -fill none -side left
	bind $site_10_1_0_3.settingsBlueColorEntry <KeyPress> {modifyColor}

	pack $site_10_1_0.frameBlueSliderBackground -in $site_10_1_0 -anchor w -expand 0 -fill x -side top
	pack $site_10_1_Master.frameColorAdjustLeft -in $site_10_1_Master -anchor w -expand 1 -fill x -side left

	frame $site_10_1_Master.frameColorAdjustRight -height 30 -background #ececec -relief flat -width 430  -border 1
	vTcl:DefineAlias "$site_10_1_Master.frameColorAdjustRight" "FrameColorAdjustRight" vTcl:WidgetProc "Toplevel1" 1

	set site_10_1_1 $site_10_1_Master.frameColorAdjustRight

	entry $site_10_1_1.settingsColorMonitorEntry -highlightthickness 0 -textvariable "$top\::settingscolormonitorentry" -width 1
	vTcl:DefineAlias "$site_10_1_1.settingsColorMonitorEntry" "EntryColorMonitorSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1_1.settingsColorMonitorEntry -in $site_10_1_1 -anchor nw -expand 1 -fill y -side top

	pack $site_10_1_Master.frameColorAdjustRight -in $site_10_1_Master -anchor ne -expand 0 -fill y -side right

	pack $site_10_1.frameColorAdjustMaster -in $site_10_1 -anchor ne -expand 1 -fill both -side top

	::iwidgets::combobox $site_10_1.settingsDisplayParametersComboBox -command {} -width 25 \
	-highlightthickness 0 -labelpos w -labeltext "Display Parameter" -selectioncommand {
		global PPrefTmp
		set currentColorWidget [DisplayParametersComboBoxSettings getcurselection]
		if {$currentColorWidget == "Window Foreground"} {set tmpcolor $PPrefTmp(color,window,fore)}
		if {$currentColorWidget == "Window Background"} {set tmpcolor $PPrefTmp(color,window,back)}
		if {$currentColorWidget == "Active Foreground"} {set tmpcolor $PPrefTmp(color,active,fore)}
		if {$currentColorWidget == "Active Background"} {set tmpcolor $PPrefTmp(color,active,back)}
		if {$currentColorWidget == "Widget Data Foreground"} {set tmpcolor $PPrefTmp(color,widget,fore)}
		if {$currentColorWidget == "Widget Data Background"} {set tmpcolor $PPrefTmp(color,widget,back)}
		if {$currentColorWidget == "Directory Color"} {set tmpcolor $PPrefTmp(color,directory)}
		if {$currentColorWidget == "File Color"} {set tmpcolor $PPrefTmp(color,file)}
		if {$currentColorWidget == "Selection Foreground Color"} {set tmpcolor $PPrefTmp(color,selection,fore)}
		if {$currentColorWidget == "Selection Background Color"} {set tmpcolor $PPrefTmp(color,selection,back)}
		if {$currentColorWidget == "Tool Tip Foreground"} {set tmpcolor $PPrefTmp(color,ToolTipForeground)}
		if {$currentColorWidget == "Tool Tip Background"} {set tmpcolor $PPrefTmp(color,ToolTipBackground)}
		parseColor
		modifyColor
	}
	vTcl:DefineAlias "$site_10_1.settingsDisplayParametersComboBox" "DisplayParametersComboBoxSettings" vTcl:WidgetProc "Toplevel1" 1
	vTcl:DefineAlias "$site_10_1.settingsDisplayParametersComboBox.lwchildsite.entry" "DisplayParametersComboBoxSettingsEntry" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_1.settingsDisplayParametersComboBox -in $site_10_1 -anchor center -expand 0 -fill none -side bottom

	pack $site_8_0.settingsColorAdjustFrame -in $site_8_0 -anchor nw  -expand 0 -fill both -side top

	::iwidgets::labeledframe $site_8_0.settingsFontsLabelFrame -labelpos nw -labeltext "Font Settings" -relief groove
	vTcl:DefineAlias "$site_8_0.settingsFontsLabelFrame" "LabeledFrameFontsSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_10_2 [$site_8_0.settingsFontsLabelFrame childsite]

	frame $site_10_2.frameFontListBox -relief flat -width 430  -borderwidth 0 -height 400
	vTcl:DefineAlias "$site_10_2.frameFontListBox" "FrameFontListBox" vTcl:WidgetProc "Toplevel1" 1

	set site_10_2_1 $site_10_2.frameFontListBox

	::iwidgets::scrolledlistbox $site_10_2_1.settingsFontsFoundryListBox -dblclickcommand {} \
	-hscrollmode dynamic -width 18 -labeltext "Foundry" \
	-selectioncommand {
		ScrolledListBoxFontFamilySettings clear
		ScrolledListBoxFontFoundrySettings itemconfigure $anchorFoundry -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		set anchorFoundry [ScrolledListBoxFontFoundrySettings curselection]

		for {set w 0 } { $w < $TotalFamily($anchorFoundry)} {incr w} {
			set tmpFamily $SysFontFamily($anchorFoundry,$w)
			ScrolledListBoxFontFamilySettings insert end $SysFontFamily($anchorFoundry,$w)
		}
		ScrolledListBoxFontWeightSettings itemconfigure 0 -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		ScrolledListBoxFontWeightSettings itemconfigure 1 -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		ScrolledListBoxFontFoundrySettings itemconfigure $anchorFoundry -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		set anchorFamily 0
		set anchorWeight 0
		set anchorSlant 0
		ScrolledListBoxFontFamilySettings itemconfigure $anchorFamily -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		ScrolledListBoxFontWeightSettings itemconfigure $anchorWeight -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		ScrolledListBoxFontSlantSettings itemconfigure $anchorSlant -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		set fontString "-family [ScrolledListBoxFontFamilySettings get $anchorFamily $anchorFamily] -size [ScrolledListBoxPointSizeSettings get $anchorPointSize $anchorPointSize] -weight [ScrolledListBoxFontWeightSettings get $anchorWeight $anchorWeight] -slant [ScrolledListBoxFontSlantSettings get $anchorSlant $anchorSlant] -underline $FontsUnderlineCheckBox -overstrike $FontsOverstrikeCheckBox"
		modifyColor
	} -selectmode single -textbackground #d9d9d9 -vscrollmode dynamic -height 120
	vTcl:DefineAlias "$site_10_2_1.settingsFontsFoundryListBox" "ScrolledListBoxFontFoundrySettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_2_1.settingsFontsFoundryListBox -in $site_10_2_1 -anchor nw -expand 1 -fill both  -side left

	::iwidgets::scrolledlistbox $site_10_2_1.settingsFontsFamilyListBox -dblclickcommand {} \
	-hscrollmode dynamic -width 5 -labeltext "               Family               " \
	-selectioncommand {
		ScrolledListBoxFontFamilySettings itemconfigure $anchorFamily -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		set anchorFamily [ScrolledListBoxFontFamilySettings curselection]
		ScrolledListBoxFontFamilySettings itemconfigure $anchorFamily -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		set fontString "-family [ScrolledListBoxFontFamilySettings get $anchorFamily $anchorFamily] -size [ScrolledListBoxPointSizeSettings get $anchorPointSize $anchorPointSize] -weight [ScrolledListBoxFontWeightSettings get $anchorWeight $anchorWeight] -slant [ScrolledListBoxFontSlantSettings get $anchorSlant $anchorSlant] -underline $FontsUnderlineCheckBox -overstrike $FontsOverstrikeCheckBox"
		set tmpFamily [ScrolledListBoxFontFamilySettings get $anchorFamily $anchorFamily]
		if {[ComboBoxFontsSettingsEntry get] == "Label Font"} {
			set PPrefTmp(fonts,label) $fontString
			set PPrefTmp(Foundry,label) $tmpFoundry
		 } else {
		 	if {[ComboBoxFontsSettingsEntry get] == "Text Font"} {
				set PPrefTmp(fonts,text) $fontString
				set PPrefTmp(Foundry,text) $tmpFoundry
		 	} else {
				set PPrefTmp(fonts,ToolTip) $fontString
				set PPrefTmp(Foundry,ToolTip) $tmpFoundry
				set PPref(fonts,ToolTip) $fontString
			}
		 }
		modifyColor
	} -selectmode single -vscrollmode dynamic
	vTcl:DefineAlias "$site_10_2_1.settingsFontsFamilyListBox" "ScrolledListBoxFontFamilySettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_2_1.settingsFontsFamilyListBox -in $site_10_2_1 -anchor nw -expand 1 -fill both -side left

	::iwidgets::scrolledlistbox $site_10_2_1.settingsFontsWeightListBox -dblclickcommand {} \
	-hscrollmode dynamic -width 18 -labeltext " Weight " \
        -selectioncommand {
		ScrolledListBoxFontWeightSettings itemconfigure $anchorWeight -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		set anchorWeight [ScrolledListBoxFontWeightSettings curselection]
		ScrolledListBoxFontWeightSettings itemconfigure $anchorWeight -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		set fontString "-family [ScrolledListBoxFontFamilySettings get $anchorFamily $anchorFamily] -size [ScrolledListBoxPointSizeSettings get $anchorPointSize $anchorPointSize] -weight [ScrolledListBoxFontWeightSettings get $anchorWeight $anchorWeight] -slant [ScrolledListBoxFontSlantSettings get $anchorSlant $anchorSlant] -underline $FontsUnderlineCheckBox -overstrike $FontsOverstrikeCheckBox"
		set tmpWeight [ScrolledListBoxFontWeightSettings get $anchorWeight $anchorWeight]
		if {[ComboBoxFontsSettingsEntry get] == "Label Font"} {
			set PPrefTmp(fonts,label) $fontString
		 } else {
		 	if {[ComboBoxFontsSettingsEntry get] == "Text Font"} {
				set PPrefTmp(fonts,text) $fontString
		 	} else {
				set PPrefTmp(fonts,ToolTip) $fontString
				set PPref(fonts,ToolTip) $fontString
			}
		 }
		modifyColor
	} -selectmode single -vscrollmode dynamic
	vTcl:DefineAlias "$site_10_2_1.settingsFontsWeightListBox" "ScrolledListBoxFontWeightSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_2_1.settingsFontsWeightListBox -in $site_10_2_1 -anchor ne -expand 1 -fill both -side left

	::iwidgets::scrolledlistbox $site_10_2_1.settingsFontsSlantListBox -dblclickcommand {} \
	-hscrollmode dynamic -width 18 -labeltext "  Slant  " \
	-selectioncommand {
		ScrolledListBoxFontSlantSettings itemconfigure $anchorSlant -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		set anchorSlant [ScrolledListBoxFontSlantSettings curselection]
		ScrolledListBoxFontSlantSettings itemconfigure $anchorSlant -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		set fontString "-family [ScrolledListBoxFontFamilySettings get $anchorFamily $anchorFamily] -size [ScrolledListBoxPointSizeSettings get $anchorPointSize $anchorPointSize] -weight [ScrolledListBoxFontWeightSettings get $anchorWeight $anchorWeight] -slant [ScrolledListBoxFontSlantSettings get $anchorSlant $anchorSlant] -underline $FontsUnderlineCheckBox -overstrike $FontsOverstrikeCheckBox"
		set tmpSlant [ScrolledListBoxFontSlantSettings get $anchorSlant $anchorSlant]
		 if {[ComboBoxFontsSettingsEntry get] == "Label Font"} {
			set PPrefTmp(fonts,label) $fontString
		 } else {
		 	if {[ComboBoxFontsSettingsEntry get] == "Text Font"} {
				set PPrefTmp(fonts,text) $fontString
		 	} else {
				set PPrefTmp(fonts,ToolTip) $fontString
				set PPref(fonts,ToolTip) $fontString
			}
		 }
		modifyColor
	}  -selectmode single -vscrollmode dynamic
	vTcl:DefineAlias "$site_10_2_1.settingsFontsSlantListBox" "ScrolledListBoxFontSlantSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_2_1.settingsFontsSlantListBox -in $site_10_2_1 -anchor ne -expand 1 -fill both -side left

	::iwidgets::scrolledlistbox $site_10_2_1.settingsFontsPointSizeListBox -dblclickcommand {} \
	-hscrollmode dynamic -labeltext "Point   " -width 5 \
        -selectioncommand {
		ScrolledListBoxPointSizeSettings itemconfigure $anchorPointSize -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		set anchorPointSize [ScrolledListBoxPointSizeSettings curselection]
		ScrolledListBoxPointSizeSettings itemconfigure $anchorPointSize -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)	
		set fontString "-family [ScrolledListBoxFontFamilySettings get $anchorFamily $anchorFamily] -size [ScrolledListBoxPointSizeSettings get $anchorPointSize $anchorPointSize] -weight [ScrolledListBoxFontWeightSettings get $anchorWeight $anchorWeight] -slant [ScrolledListBoxFontSlantSettings get $anchorSlant $anchorSlant] -underline $FontsUnderlineCheckBox -overstrike $FontsOverstrikeCheckBox"
		set tmpPointSize [ScrolledListBoxPointSizeSettings get $anchorPointSize $anchorPointSize]
		if {[ComboBoxFontsSettingsEntry get] == "Label Font"} {
			set PPrefTmp(fonts,label) $fontString
		 } else {
		 	if {[ComboBoxFontsSettingsEntry get] == "Text Font"} {
			set PPrefTmp(fonts,text) $fontString
		 	} else {
				set PPrefTmp(fonts,ToolTip) $fontString
				set PPref(fonts,ToolTip) $fontString
			}
		 }
		modifyColor
	} -selectmode single -textbackground #d9d9d9 -vscrollmode dynamic
	vTcl:DefineAlias "$site_10_2_1.settingsFontsPointSizeListBox" "ScrolledListBoxPointSizeSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_2_1.settingsFontsPointSizeListBox -in $site_10_2_1 -anchor ne -expand 0 -fill y -side left

	pack $site_10_2.frameFontListBox -in $site_10_2 -anchor nw -expand 1 -fill both -side top

	frame $site_10_2.frameFontComboBox -height 30 -background #ececec -relief flat -width 430  -borderwidth 0 -height 225
	vTcl:DefineAlias "$site_10_2.frameFontComboBox" "FrameFontComboBox" vTcl:WidgetProc "Toplevel1" 1

	set site_10_2_2 $site_10_2.frameFontComboBox

	checkbutton $site_10_2_2.settingsFontsUnderlineCheckBox -command {
		set fontString "-family [ScrolledListBoxFontFamilySettings get $anchorFamily $anchorFamily] -size [ScrolledListBoxPointSizeSettings get $anchorPointSize $anchorPointSize] -weight [ScrolledListBoxFontWeightSettings get $anchorWeight $anchorWeight] -slant [ScrolledListBoxFontSlantSettings get $anchorSlant $anchorSlant] -underline $FontsUnderlineCheckBox -overstrike $FontsOverstrikeCheckBox"
		if {[ComboBoxFontsSettingsEntry get] == "Label Font"} {
			set PPrefTmp(fonts,label) $fontString
		 } else {
		 	if {[ComboBoxFontsSettingsEntry get] == "Text Font"} {
			set PPrefTmp(fonts,text) $fontString
		 	} else {
				set PPrefTmp(fonts,ToolTip) $fontString
				set PPref(fonts,ToolTip) $fontString
			}
		 }
		modifyColor
	} -offvalue 0 -onvalue 1  -text Underline -variable FontsUnderlineCheckBox
	vTcl:DefineAlias "$site_10_2_2.settingsFontsUnderlineCheckBox" "CheckButtonFontUnderlineSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_2_2.settingsFontsUnderlineCheckBox -in $site_10_2_2 -anchor nw -expand 0 -fill none -side left

	checkbutton $site_10_2_2.settingsFontsOverstrikeCheckBox -command {
		set fontString "-family [ScrolledListBoxFontFamilySettings get $anchorFamily $anchorFamily] -size [ScrolledListBoxPointSizeSettings get $anchorPointSize $anchorPointSize] -weight [ScrolledListBoxFontWeightSettings get $anchorWeight $anchorWeight] -slant [ScrolledListBoxFontSlantSettings get $anchorSlant $anchorSlant] -underline $FontsUnderlineCheckBox -overstrike $FontsOverstrikeCheckBox"
		if {[ComboBoxFontsSettingsEntry get] == "Label Font"} {
			set PPrefTmp(fonts,label) $fontString
		 } else {
		 	if {[ComboBoxFontsSettingsEntry get] == "Text Font"} {
			set PPrefTmp(fonts,text) $fontString
		 	} else {
				set PPrefTmp(fonts,ToolTip) $fontString
				set PPref(fonts,ToolTip) $fontString
			}
		 }
		modifyColor
	} -offvalue 0 -onvalue 1 -text Overstrike -variable FontsOverstrikeCheckBox
	vTcl:DefineAlias "$site_10_2_2.settingsFontsOverstrikeCheckBox" "CheckButtonFontOverstrikeSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_2_2.settingsFontsOverstrikeCheckBox -in $site_10_2_2 -anchor nw -expand 0 -fill none -side left

	::iwidgets::combobox $site_10_2_2.settingsFontsComboBox -command {} -listheight 60 -labeltext "Font Parameter" \
	-selectioncommand {
		if {[ComboBoxFontsSettingsEntry get] == "Label Font"} {
			set readline $PPrefTmp(fonts,label)
			set tmpFoundry $PPrefTmp(Foundry,label)
		} else {
			if {[ComboBoxFontsSettingsEntry get] == "Text Font"} {
				set readline $PPrefTmp(fonts,text)
				set tmpFoundry $PPrefTmp(Foundry,text)
			} else {
				set PPref(fonts,ToolTip) $fontString
				set readline $PPrefTmp(fonts,ToolTip)
				set tmpFoundry $PPrefTmp(Foundry,ToolTip)
			}
		}
		parseFontSettingsLine
		ScrolledListBoxFontFoundrySettings clear
		for {set v 0 } { $v < $TotalFoundry} {incr v} {
			ScrolledListBoxFontFoundrySettings insert end $SysFontFoundry($v)
			if {$tmpFoundry==$SysFontFoundry($v)} {set anchorFoundry $v}
		}
		ScrolledListBoxFontFoundrySettings itemconfigure $anchorFoundry -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		ScrolledListBoxFontFamilySettings clear
		for {set w 0 } { $w < $TotalFamily($anchorFoundry)} {incr w} {
			ScrolledListBoxFontFamilySettings insert end $SysFontFamily($anchorFoundry,$w)
			if {$tmpFamily==$SysFontFamily($anchorFoundry,$w)} {set anchorFamily $w}
		}
		ScrolledListBoxFontFamilySettings itemconfigure $anchorFamily -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		ScrolledListBoxFontWeightSettings itemconfigure $anchorWeight -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		if {$tmpWeight=="normal"} {
			set anchorWeight 0
		} else {
			set anchorWeight 1
		}
		ScrolledListBoxFontWeightSettings itemconfigure $anchorWeight -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		ScrolledListBoxFontSlantSettings itemconfigure $anchorSlant -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		if {$tmpSlant=="roman"} {
			set anchorSlant 0
		} else {
			set anchorSlant 1
		}
		ScrolledListBoxFontSlantSettings itemconfigure $anchorSlant -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
		ScrolledListBoxPointSizeSettings itemconfigure $anchorPointSize -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back)
		set newPointSizeOffset 0
		for {set pointSize 4 } { $pointSize < 97} {incr pointSize} {

			if {$tmpPointSize == $pointSize} {break}
			incr newPointSizeOffset
		}
		set anchorPointSize $newPointSizeOffset
		ScrolledListBoxPointSizeSettings itemconfigure $anchorPointSize  -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
	}
	vTcl:DefineAlias "$site_10_2_2.settingsFontsComboBox" "ComboBoxFontsSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_10_2_2.settingsFontsComboBox -in $site_10_2_2 -anchor ne -expand 0 -fill none -side right
	vTcl:DefineAlias "$site_10_2_2.settingsFontsComboBox.lwchildsite.entry" "ComboBoxFontsSettingsEntry" vTcl:WidgetProc "Toplevel1" 1

	pack $site_10_2.frameFontComboBox -in $site_10_2 -anchor se -expand 1 -fill x -side top
	pack $site_8_0.settingsFontsLabelFrame -in $site_8_0 -anchor nw -expand 1 -fill both -side top

#############################################################################
#############################################################################
# Date Format Tab

	set site_8_5 [lindex [$top.settingsTabNotebook childsite] 1]

	::iwidgets::labeledframe $site_8_5.dateLabeledFrame -labelpos nw -labeltext "Date Format"
	vTcl:DefineAlias "$site_8_5.dateLabeledFrame" "LabeledFrameDateSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5_1 [$site_8_5.dateLabeledFrame childsite]

	radiobutton $site_8_5_1.dateNoneRadioButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text None -value "None" -variable DateFormatVar
	vTcl:DefineAlias "$site_8_5_1.dateNoneRadioButton" "RadioButtonDateNoneSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_1.dateNoneRadioButton -in $site_8_5_1 -anchor nw -expand 0 -fill none -side top

	frame $site_8_5_1.frameShort -borderwidth 0 -height 175 -relief flat -width 515
	vTcl:DefineAlias "$site_8_5_1.frameShort" "FrameShortDateSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5_1_1 $site_8_5_1.frameShort

        radiobutton $site_8_5_1_1.dateShortDatemmddyyRadioButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "Short Date mmddyy" -value "Shortmmddyy" -variable DateFormatVar
	vTcl:DefineAlias "$site_8_5_1_1.dateShortDatemmddyyRadioButton" "RadioButtonShortDate1Settings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_1_1.dateShortDatemmddyyRadioButton -in $site_8_5_1_1 -anchor nw -expand 1 -fill none -side left

        radiobutton $site_8_5_1_1.dateShortDateyymmddRadioButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "Short Date yymmdd" -value "Shortyymmdd" -variable DateFormatVar
	vTcl:DefineAlias "$site_8_5_1_1.dateShortDateyymmddRadioButton" "RadioButtonShortDate2Settings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_1_1.dateShortDateyymmddRadioButton -in $site_8_5_1_1 -anchor nw -expand 1 -fill none -side right

	pack $site_8_5_1.frameShort -in $site_8_5_1 -anchor nw -expand 0 -fill x -side top

        frame $site_8_5_1.frameLong -relief flat -width 515
	vTcl:DefineAlias "$site_8_5_1.frameLong" "FrameLongDateSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5_1_2 $site_8_5_1.frameLong

        radiobutton $site_8_5_1_2.dateLongDatemmddyyRadioButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "Long Date mmddyyyy" -value "Longmmddyy" -variable DateFormatVar
	vTcl:DefineAlias "$site_8_5_1_2.dateLongDatemmddyyRadioButton" "RadioButtondLongDate1Settings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_1_2.dateLongDatemmddyyRadioButton -in $site_8_5_1_2 -anchor nw -expand 1 -fill none -side left

        radiobutton $site_8_5_1_2.dateLongDateyymmddRadioButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "Long Date yyyymmdd" -value "Longyymmdd" -variable DateFormatVar
	vTcl:DefineAlias "$site_8_5_1_2.dateLongDateyymmddRadioButton" "RadioButtondLongDate2Settings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_1_2.dateLongDateyymmddRadioButton -in $site_8_5_1_2 -anchor nw -expand 1 -fill none -side right

	pack $site_8_5_1.frameLong -in $site_8_5_1 -anchor nw -expand 0 -fill x -side top
	
        frame $site_8_5_1.frameFull -borderwidth 0 -height 175 -relief flat -width 515
	vTcl:DefineAlias "$site_8_5_1.frameFull" "FrameFullDateSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5_1_3 $site_8_5_1.frameFull

        radiobutton $site_8_5_1_3.dateFullDateShortRadioButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "Full Short Date" -value "FullShort" -variable DateFormatVar
	vTcl:DefineAlias "$site_8_5_1_3.dateFullDateShortRadioButton" "RadioButtonFullShortSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_1_3.dateFullDateShortRadioButton -in $site_8_5_1_3 -anchor nw -expand 1 -fill none -side left

        radiobutton $site_8_5_1_3.dateFullDateLongRadioButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "Full Long Date" -value "FullLong" -variable DateFormatVar
	vTcl:DefineAlias "$site_8_5_1_3.dateFullDateLongRadioButton" "RadioButtonFullLongSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_1_3.dateFullDateLongRadioButton -in $site_8_5_1_3 -anchor nw -expand 1 -fill none -side right

	pack $site_8_5_1.frameFull -in $site_8_5_1 -anchor nw -expand 0 -fill x -side top

        frame $site_8_5_1.frameFullAbrev -borderwidth 0 -height 17 -relief flat -width 515
	vTcl:DefineAlias "$site_8_5_1.frameFullAbrev" "FrameFullAbrevDateSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5_1_3 $site_8_5_1.frameFullAbrev

        radiobutton $site_8_5_1_3.dateFullAbrevDateShortRadioButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "Full Abrev Month Short Date" -value "FullAbrevShort" -variable DateFormatVar
	vTcl:DefineAlias "$site_8_5_1_3.dateFullAbrevDateShortRadioButton" "RadioButtonFullAbrevShortSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_1_3.dateFullAbrevDateShortRadioButton -in $site_8_5_1_3 -anchor nw -expand 1 -fill none -side left

        radiobutton $site_8_5_1_3.dateFullAbrevDateLongRadioButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "Full  Abrev Month Long Date" -value "FullAbrevLong" -variable DateFormatVar
	vTcl:DefineAlias "$site_8_5_1_3.dateFullAbrevDateLongRadioButton" "RadioButtonFullAbrevLongSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_1_3.dateFullAbrevDateLongRadioButton -in $site_8_5_1_3 -anchor nw -expand 1 -fill none -side right

	pack $site_8_5_1.frameFullAbrev -in $site_8_5_1 -anchor nw -expand 0 -fill x -side top

	::iwidgets::entryfield $site_8_5_1.dateSeparater -width 1 -labelpos e -labeltext "Short/Long Date Separater" -textvariable ShortLongSeparater
	vTcl:DefineAlias "$site_8_5_1.dateSeparater" "EntryDateSeparaterSettings" vTcl:WidgetProc "Toplevel1" 1
	bind .settings.settingsTabNotebook.canvas.notebook.cs.page2.cs.dateLabeledFrame.childsite.dateSeparater.lwchildsite.entry <Key-Return> {
		set PPrefTmp(DateSeparater) $ShortLongSeparater
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	}
	bind .settings.settingsTabNotebook.canvas.notebook.cs.page2.cs.dateLabeledFrame.childsite.dateSeparater.lwchildsite.entry <Key-KP_Enter> {
		set PPrefTmp(DateSeparater) $ShortLongSeparater
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	}
	
	pack $site_8_5_1.dateSeparater -in $site_8_5_1 -anchor nw -expand 0 -fill none -side top

	::iwidgets::labeledframe $site_8_5.timeLabeledFrame -labelpos nw -labeltext "Time Format"
	vTcl:DefineAlias "$site_8_5.timeLabeledFrame" "LabeledFrameTimeSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5_2 [$site_8_5.timeLabeledFrame childsite]

	radiobutton $site_8_5_2.timeNoneRadioButton \
	-command {
		set PPrefTmp(DisplayTimeFormat) $TimeFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "None" -value "None" -variable TimeFormatVar
	vTcl:DefineAlias "$site_8_5_2.timeNoneRadioButton" "RadioButtonTimeNoneSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_2.timeNoneRadioButton -in $site_8_5_2 -anchor nw -expand 0 -fill none -side top

	frame $site_8_5_2.frameLong -borderwidth 0 -height 175 -relief flat -width 515
	vTcl:DefineAlias "$site_8_5_2.frameLong" "FrameLongTimeSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5_2_1 $site_8_5_2.frameLong

	radiobutton $site_8_5_2_1.timehhmmss12HRadioButton \
	-command {
		set PPrefTmp(DisplayTimeFormat) $TimeFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "hhmmss 12 Hour Format" -value "hhmmss12Hour" -variable TimeFormatVar
	vTcl:DefineAlias "$site_8_5_2_1.timehhmmss12HRadioButton" "RadioButtonTimeLong12HrSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_2_1.timehhmmss12HRadioButton -in $site_8_5_2_1 -anchor nw -expand 1 -fill none -side left

            radiobutton $site_8_5_2_1.timehhmmss24HRadioButton \
        -activebackground #f9f9f9 -activeforeground black \
	-command {
		set PPrefTmp(DisplayTimeFormat) $TimeFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "hhmmss 24 Hour Format" -value "hhmmss24Hour" -variable TimeFormatVar
	vTcl:DefineAlias "$site_8_5_2_1.timehhmmss24HRadioButton" "RadioButtonTimeLong24HrSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_2_1.timehhmmss24HRadioButton -in $site_8_5_2_1 -anchor nw -expand 1 -fill none -side right
	
	pack $site_8_5_2.frameLong -in $site_8_5_2 -anchor nw -expand 0 -fill x -side top

	frame $site_8_5_2.frameShort -relief flat -width 515
	vTcl:DefineAlias "$site_8_5_2.frameShort" "FrameShortTimeSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5_2_2 $site_8_5_2.frameShort

	radiobutton $site_8_5_2_2.timehhmm12HRadioButton \
	-command {
		set PPrefTmp(DisplayTimeFormat) $TimeFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "hhmm 12 Hour Format" -value "hhmm12Hour" -variable TimeFormatVar
	vTcl:DefineAlias "$site_8_5_2_2.timehhmm12HRadioButton" "RadioButtonTimeShort12HrSettings" vTcl:WidgetProc "Toplevel1" 1
 	pack $site_8_5_2_2.timehhmm12HRadioButton -in $site_8_5_2_2 -anchor nw -expand 1 -fill none -side left

	radiobutton $site_8_5_2_2.timehhmm24HRadioButton \
	-command {
		set PPrefTmp(DisplayTimeFormat) $TimeFormatVar
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "hhmm 24 Hour Format" -value "hhmm24Hour" -variable TimeFormatVar
	vTcl:DefineAlias "$site_8_5_2_2.timehhmm24HRadioButton" "RadioButtonTimeShort24HrSettings" vTcl:WidgetProc "Toplevel1" 1
 	pack $site_8_5_2_2.timehhmm24HRadioButton -in $site_8_5_2_2 -anchor nw -expand 1 -fill none -side right

	pack $site_8_5_2.frameShort -in $site_8_5_2 -anchor nw -expand 0 -fill x -side top

	::iwidgets::entryfield $site_8_5_2.timeSeparater -width 1 -command {
		set PPrefTmp(TimeSeparater) $TimeSeparater
		CheckForSettingsApplyEnable
		getSystemTimeSettings

	}  -labelpos e -labeltext {Time Separater} -textvariable TimeSeparater
	vTcl:DefineAlias "$site_8_5_2.timeSeparater" "EntryTimeSeparaterSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5_2.timeSeparater -in $site_8_5_2 -anchor nw -expand 0 -fill none -side top
	bind .settings.settingsTabNotebook.canvas.notebook.cs.page2.cs.timeLabeledFrame.childsite.timeSeparater.lwchildsite.entry <Key-Return> {
		set PPrefTmp(TimeSeparater) $TimeSeparater
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	}
	bind .settings.settingsTabNotebook.canvas.notebook.cs.page2.cs.timeLabeledFrame.childsite.timeSeparater.lwchildsite.entry <Key-KP_Enter> {
		set PPrefTmp(TimeSeparater) $TimeSeparater
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	}

	::iwidgets::labeledframe $site_8_5.weekLabeledFrame -labelpos nw -labeltext {Week Format}
	vTcl:DefineAlias "$site_8_5.weekLabeledFrame" "LabeledFrameWeekSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5_3 [$site_8_5.weekLabeledFrame childsite]

	checkbutton $site_8_5_3.displayDayOfWeekCheckButton \
	 -command {
		set PPrefTmp(DisplayDayOfWeek) $DisplayDayOfWeek
		CheckForSettingsApplyEnable
		getSystemTimeSettings
	} -text "Display day of week"  -onvalue "Yes" -offvalue "No" -variable DisplayDayOfWeek -wrap 0
	vTcl:DefineAlias "$site_8_5_3.displayDayOfWeekCheckButton" "CheckButtonDayOfTheWeekSettings" vTcl:WidgetProc "Toplevel1" 1
       pack $site_8_5_3.displayDayOfWeekCheckButton -in $site_8_5_3 -anchor nw -expand 0 -fill none -side top
	
	
	pack $site_8_5.dateLabeledFrame -in $site_8_5 -anchor nw -expand 1 -fill x -side top
	pack $site_8_5.timeLabeledFrame -in $site_8_5 -anchor nw -expand 1 -fill x -side top
        pack $site_8_5.weekLabeledFrame -in $site_8_5 -anchor nw -expand 1 -fill x -side top
	

	::iwidgets::entryfield $site_8_5.systemTimeEntry -borderwidth 2  -relief sunken -labelpos w \
	-labeltext "Example" -textvariable SystemTimeSettings -width 35 -justify center
	vTcl:DefineAlias "$site_8_5.systemTimeEntry" "EntryTimeSystemSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5.systemTimeEntry -in $site_8_5 -anchor center -expand 0 -fill none -side bottom


#############################################################################
#############################################################################

	set site_8_6 [lindex [$top.settingsTabNotebook childsite] 2]

	::iwidgets::labeledframe $site_8_6.freeFactoryNotifyDirectoriesFrame -labelpos nw -labeltext "Free Factory Notify Directories"
	vTcl:DefineAlias "$site_8_6.freeFactoryNotifyDirectoriesFrame" "LabeledFrameFreeFactoryNotifyDirectoriesSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_6_0 [$site_8_6.freeFactoryNotifyDirectoriesFrame childsite]

	::iwidgets::scrolledlistbox $site_8_6_0.factoryNotifyDirectoriesListBox -activebackground #f9f9f9 -activerelief raised -background #e6e6e6 \
	-borderwidth 2 -disabledforeground #a3a3a3 -foreground #000000 -height 100 -highlightcolor black -highlightthickness 1 \
	-hscrollmode dynamic -selectmode single -jump 0 -labelpos n -labeltext "" -relief sunken \
	-sbwidth 10 -selectbackground #c4c4c4 -selectborderwidth 1 -selectforeground black -state normal \
	-textbackground #d9d9d9 -troughcolor #c4c4c4 -vscrollmode dynamic -dblclickcommand {} -selectioncommand {
		set ScrollBoxItemPos [ScrolledListBoxFactoryNotifyDirectories curselection ]
		set SelectedDirectoryPath [ScrolledListBoxFactoryNotifyDirectories get $ScrollBoxItemPos]
		set SelectedDirectoryPathOrg $SelectedDirectoryPath
		set NotifyRuntimeUser [lindex $NotifyDirectoryList($ScrollBoxItemPos) 1]
		ButtonUpdateDirectory configure -state normal
		ButtonSaveDirectory configure -state disable

	} -width 254
	vTcl:DefineAlias "$site_8_6_0.factoryNotifyDirectoriesListBox" "ScrolledListBoxFactoryNotifyDirectories" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_0.factoryNotifyDirectoriesListBox -in $site_8_6_0 -anchor n -expand 1 -fill both -side top


	frame $site_8_6_0.nofifyDirectoryEntryFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_8_6_0.nofifyDirectoryEntryFrame" "FrameDirectoryEntry" vTcl:WidgetProc "Toplevel1" 1

	set site_8_6_1 $site_8_6_0.nofifyDirectoryEntryFrame

	::iwidgets::entryfield $site_8_6_1.selectedDirectoryEntry -labelpos w -labeltext "Directory Path" -textvariable SelectedDirectoryPath
	vTcl:DefineAlias "$site_8_6_1.selectedDirectoryEntry" "SelectedDirectoryEntry" vTcl:WidgetProc "Toplevel1" 1
	set BindWidgetEntry "$site_8_6_1.selectedDirectoryEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidgetEntry" "EntrySelectedDirectoryChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_1.selectedDirectoryEntry -in $site_8_6_1 -anchor w -expand 1 -fill x -side left
	bind $BindWidgetEntry <FocusOut> {
# If notify directory path does not end in a slash then append it.
		if {[expr [string last "/" $SelectedDirectoryPath] + 1] < [string length $SelectedDirectoryPath]} {
			append SelectedDirectoryPath "/"
		}
	}
        bind $BindWidgetEntry <Key-Return> {}
        bind $BindWidgetEntry <Key-KP_Enter> {}

	button $site_8_6_1.getNotifyDirectoryButton \
	-activebackground #f9f9f9 -activeforeground black \
	-command {
		source "/opt/FreeFactory/bin/DirectoryDialog.tcl"
		set windowName "Browse Notify Path Directory"
		set toolTip "Select Directory"
		Window show .directoryDialog
		Window show .directoryDialog
		if {$SelectedDirectoryPath !=""} {
			set fullDirPath [file dirname $SelectedDirectoryPath]
		} else {
			set fullDirPath "/"
		}
		set buttonImagePathFileDialog [vTcl:image:get_image [file join / opt FreeFactory Pics Open-32x32.gif]]
		widgetUpdate
		initDirectoryDialog
		tkwait window .directoryDialog
		if {$returnFilePath != ""} {
			set SelectedDirectoryPath $returnFilePath
			if {[string range $SelectedDirectoryPath end end] != "/" && $SelectedDirectoryPath !=""} {
				append SelectedDirectoryPath "/"
			}
		}	

	} -foreground black -highlightcolor black -image [vTcl:image:get_image [file join / opt FreeFactory Pics Open-32x32.gif]] -text ""
	vTcl:DefineAlias "$site_8_6_1.getNotifyDirectoryButton" "ButtonGetNotifyDirectory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_1.getNotifyDirectoryButton -in $site_8_6_1 -anchor ne -expand 0 -fill none -side right
	balloon $site_8_6_1.getNotifyDirectoryButton "Browse"

 	pack $site_8_6_0.nofifyDirectoryEntryFrame -in $site_8_6_0 -anchor w -expand 0 -fill x -side top

	::iwidgets::combobox $site_8_6_0.notifyRuntimeUserComboBoxFactorySettings -labeltext "Notify Runtime User" -labelpos w \
        -textvariable NotifyRuntimeUser -justify left -width 15 -listheight 150 -highlightthickness 0 -command {}  -selectioncommand {}
	vTcl:DefineAlias "$site_8_6_0.notifyRuntimeUserComboBoxFactorySettings" "ComboBoxNotifyRuntimeUserSettings" vTcl:WidgetProc "Toplevel1" 1
	set BindWidgetEntry "$site_8_6_0.notifyRuntimeUserComboBoxFactorySettings.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidgetEntry" "EntryComboBoxNotifyRuntimeUserSettingsChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_0.notifyRuntimeUserComboBoxFactorySettings -in $site_8_6_0 -anchor w -expand 1 -fill none -side top
	bind $BindWidgetEntry <FocusOut> {}

	frame $site_8_6_0.nofifyDirectoryButtonFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_8_6_0.nofifyDirectoryButtonFrame" "FrameNotifyDirectoryButton" vTcl:WidgetProc "Toplevel1" 1

	set site_8_6_2 $site_8_6_0.nofifyDirectoryButtonFrame

	button $site_8_6_2.newDirectoryButton \
	-activebackground #f9f9f9 -activeforeground black \
	-command {
		set SelectedDirectoryPath ""
		set NotifyRuntimeUser ""
		ButtonUpdateDirectory configure -state disable
		ButtonSaveDirectory configure -state normal
		focus .settings.settingsTabNotebook.canvas.notebook.cs.page3.cs.freeFactoryNotifyDirectoriesFrame.childsite.nofifyDirectoryEntryFrame.selectedDirectoryEntry.lwchildsite.entry
	} -foreground black -highlightcolor black -text "New"
	vTcl:DefineAlias "$site_8_6_2.newDirectoryButton" "ButtonNewDirectory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_2.newDirectoryButton -in $site_8_6_2 -anchor nw -expand 0 -fill none -side left
	balloon $site_8_6_2.newDirectoryButton "Clears the directory path entry and\nplaces the cursor in the entry."

	button $site_8_6_2.saveDirectoryButton \
	-activebackground #f9f9f9 -activeforeground black \
	-command {
			if {$PPref(ConfirmFileSaves) == "Yes"} {
				set GenericConfirm 2
				Window show .genericConfirm
				widgetUpdate
				set GenericConfirmName "Save $SelectedDirectoryPath notify directory ?"
				wm title .genericConfirm "Save Directory Confirmation"
				tkwait window .genericConfirm
				if {$GenericConfirm == 1} {SaveDirectoryList}
			} else {
				SaveDirectoryList
			}

	} -foreground black -highlightcolor black -text "Save"
	vTcl:DefineAlias "$site_8_6_2.saveDirectoryButton" "ButtonSaveDirectory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_2.saveDirectoryButton -in $site_8_6_2 -anchor center -expand 1 -fill none -side left
	balloon $site_8_6_2.saveDirectoryButton "This saves the notify directory list. It is\nnot saved with the other settings data\nand this save only saves this notify\ndirectory list."

	button $site_8_6_2.updateDirectoryButton \
	-activebackground #f9f9f9 -activeforeground black \
	-command {
# First check to make sure SelectedDirectoryPath variable
# is not a null string or a string with only spaces.
		if {[string trim $SelectedDirectoryPath] != ""} {
# If notify directory path does not end in a slash then append it.
			if {$PPref(ConfirmFileSaves) == "Yes"} {
				set GenericConfirm 2
				Window show .genericConfirm
				widgetUpdate
				set GenericConfirmName "Update $SelectedDirectoryPath notify directory ?"
				wm title .genericConfirm "Update Directory Confirmation"
				tkwait window .genericConfirm
				if {$GenericConfirm == 1} {UpdateDirectoryList}
			} else {
				UpdateDirectoryList
			}
		}
	} -foreground black -highlightcolor black -text "Update"
	vTcl:DefineAlias "$site_8_6_2.updateDirectoryButton" "ButtonUpdateDirectory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_2.updateDirectoryButton -in $site_8_6_2 -anchor center -expand 1 -fill none -side left
	balloon $site_8_6_2.updateDirectoryButton "This updates the notify directory list. It is\nnot updated with the other settings data\nand this update only updates this notify\ndirectory list."

	button $site_8_6_2.deleteDirectoryButton \
	-activebackground #f9f9f9 -activeforeground black -command {DeleteNotifyDirectory} -foreground black -highlightcolor black -text "Delete"
	vTcl:DefineAlias "$site_8_6_2.deleteDirectoryButton" "ButtonDeleteDirectory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_2.deleteDirectoryButton -in $site_8_6_2 -anchor w -expand 1 -fill none -side left
	balloon $site_8_6_2.deleteDirectoryButton "This deletes the directory path\nfrom the notify directory list."

	button $site_8_6_2.rewriteInotifyStartupButton \
	-activebackground #f9f9f9 -activeforeground black \
	-command {
		set FileHandle [open "/opt/FreeFactory/bin/InotifyStartupUser.sh" w]
		puts $FileHandle "#!/bin/bash"
		puts $FileHandle "#############################################################################"
		puts $FileHandle "#               This code is licensed under the GPLv3"
		puts $FileHandle "#    The following terms apply to all files associated with the software"
		puts $FileHandle "#    unless explicitly disclaimed in individual files or parts of files."
		puts $FileHandle "#"
		puts $FileHandle "#                           Free Factory"
		puts $FileHandle "#"
		puts $FileHandle "#                          Copyright 2013"
		puts $FileHandle "#                               by"
		puts $FileHandle "#                     Jim Hines and Karl Swisher"
		puts $FileHandle "#"
		puts $FileHandle "#    This program is free software; you can redistribute it and/or modify"
		puts $FileHandle "#    it under the terms of the GNU General Public License as published by"
		puts $FileHandle "#    the Free Software Foundation; either version 3 of the License, or"
		puts $FileHandle "#    (at your option) any later version."
		puts $FileHandle "#"
		puts $FileHandle "#    This program is distributed in the hope that it will be useful,"
		puts $FileHandle "#    but WITHOUT ANY WARRANTY; without even the implied warranty of"
		puts $FileHandle "#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
		puts $FileHandle "#    GNU General Public License for more details."
		puts $FileHandle "#"
		puts $FileHandle "#    You should have received a copy of the GNU General Public License"
		puts $FileHandle "#    along with this program; if not, write to the Free Software"
		puts $FileHandle "#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA"
		puts $FileHandle "#"
		puts $FileHandle "# Script Name: InotifyStartupUser.sh"
		puts $FileHandle "# This script is created from the FreeFactory gui."
		puts $FileHandle "#"
		puts $FileHandle "# Startup for Free Factory runtime video conversion software.  This script"
		puts $FileHandle "# starts inotifywait. This script can be run from a command line or "
		puts $FileHandle "# started, stopped and restarted from The Free Factory gui.  It will run"
		puts $FileHandle "# user the user that owns the shell or the Free Factory gui."
		puts $FileHandle "#"
		puts $FileHandle "# Usage:/opt/FreeFactory/bin/InotifyStartupUser.sh"
		puts $FileHandle "#"
		puts $FileHandle "# Any manual edit changes may be over written by the Free Factory gui."
		puts $FileHandle "#"
		puts $FileHandle "#"
		puts $FileHandle "#############################################################################"
		for {set x 0} {$x < $NumberOfDirectories} {incr x} {
# Extract directory path from list variable
			set NotifyDirPath [lindex $NotifyDirectoryList($x) 0]
# Must remove the last slash for command line use.
			set LastSlash [string last "/" [string trim $NotifyDirPath]]
			set NotifyDirectoryTmp [string range $NotifyDirPath 0 [expr $LastSlash -1]]
			puts $FileHandle "inotifywait -rme close_write $NotifyDirectoryTmp | /opt/FreeFactory/bin/FreeFactoryNotify.sh 2>> /var/log/FreeFactory/InotifyStartupUser.log&"
		}
		puts $FileHandle "exit"
		close $FileHandle
		set FileHandle [open "/opt/FreeFactory/bin/InotifyStartupRoot.sh" w]
		puts $FileHandle "#!/bin/bash"
		puts $FileHandle "#############################################################################"
		puts $FileHandle "#               This code is licensed under the GPLv3"
		puts $FileHandle "#    The following terms apply to all files associated with the software"
		puts $FileHandle "#    unless explicitly disclaimed in individual files or parts of files."
		puts $FileHandle "#"
		puts $FileHandle "#                           Free Factory"
		puts $FileHandle "#"
		puts $FileHandle "#                          Copyright 2013"
		puts $FileHandle "#                               by"
		puts $FileHandle "#                     Jim Hines and Karl Swisher"
		puts $FileHandle "#"
		puts $FileHandle "#    This program is free software; you can redistribute it and/or modify"
		puts $FileHandle "#    it under the terms of the GNU General Public License as published by"
		puts $FileHandle "#    the Free Software Foundation; either version 3 of the License, or"
		puts $FileHandle "#    (at your option) any later version."
		puts $FileHandle "#"
		puts $FileHandle "#    This program is distributed in the hope that it will be useful,"
		puts $FileHandle "#    but WITHOUT ANY WARRANTY; without even the implied warranty of"
		puts $FileHandle "#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
		puts $FileHandle "#    GNU General Public License for more details."
		puts $FileHandle "#"
		puts $FileHandle "#    You should have received a copy of the GNU General Public License"
		puts $FileHandle "#    along with this program; if not, write to the Free Software"
		puts $FileHandle "#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA"
		puts $FileHandle "#"
		puts $FileHandle "# Script Name: InotifyStartupRoot.sh"
		puts $FileHandle "# This script is created from the FreeFactory gui."
		puts $FileHandle "#"
		puts $FileHandle "# Startup for Free Factory runtime video conversion software.  This script"
		puts $FileHandle "# starts inotifywait. This script meant to be run as root from rc.local.  The"
		puts $FileHandle "# individual process will run under the user contained in the command line."
		puts $FileHandle "#"
		puts $FileHandle "# Usage:/opt/FreeFactory/bin/InotifyStartupRoot.sh"
		puts $FileHandle "#"
		puts $FileHandle "# Any manual edit changes may be over written by the Free Factory gui."
		puts $FileHandle "#"
		puts $FileHandle "#"
		puts $FileHandle "#############################################################################"
		for {set x 0} {$x < $NumberOfDirectories} {incr x} {
# Extract directory path from list variable
			set NotifyDirPath [lindex $NotifyDirectoryList($x) 0]
# Extract user from list variable
			set NotifyDirUser [lindex $NotifyDirectoryList($x) 1]
# Only add notify directory if user is not blank.
			if {[string trim $NotifyDirUser] != ""} {
# Must remove the last slash for command line use.
				set LastSlash [string last "/" [string trim $NotifyDirPath]]
				set NotifyDirectoryTmp [string range $NotifyDirPath 0 [expr $LastSlash -1]]
				puts $FileHandle "su -c \"inotifywait -rme close_write $NotifyDirectoryTmp | /opt/FreeFactory/bin/FreeFactoryNotify.sh 2>> /var/log/FreeFactory/InotifyStartupUser.log\" $NotifyDirUserr &"
			}
		}
		puts $FileHandle "exit"
		close $FileHandle
	} -foreground black -highlightcolor black -text "Rewrite Startup"
	vTcl:DefineAlias "$site_8_6_2.rewriteInotifyStartupButton" "ButtonRewriteInotifyStartupDirectory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_2.rewriteInotifyStartupButton -in $site_8_6_2 -anchor e -expand 1 -fill none -side right
	balloon $site_8_6_2.rewriteInotifyStartupButton "This rewrites the InotifyStartupUser.sh\nand InotifyStartupRoot.sh files. The\nscripts may be started or restarted\nto reflect any changes."

	pack $site_8_6_0.nofifyDirectoryButtonFrame -in $site_8_6_0 -anchor w -expand 0 -fill x -side top

	::iwidgets::labeledframe $site_8_6_0.freeFactoryRunningProcessesFrame -labelpos nw -labeltext "Free Factory Running Processes"
	vTcl:DefineAlias "$site_8_6_0.freeFactoryRunningProcessesFrame" "LabeledFrameFreeFactoryRunningProcessesSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_6_3 [$site_8_6_0.freeFactoryRunningProcessesFrame childsite]

	pack $site_8_6_0.freeFactoryRunningProcessesFrame -in $site_8_6_0 -anchor center -expand 1 -fill both -side top

	::iwidgets::scrolledlistbox $site_8_6_3.factoryRunningProcessesListBox -activebackground #f9f9f9 -activerelief raised -background #e6e6e6 \
	-borderwidth 2 -disabledforeground #a3a3a3 -foreground #000000 -height 100 -highlightcolor black -highlightthickness 1 \
	-hscrollmode dynamic -selectmode single -jump 0 -labelpos n -labeltext "" -relief sunken \
	-sbwidth 10 -selectbackground #c4c4c4 -selectborderwidth 1 -selectforeground black -state normal \
	-textbackground #d9d9d9 -troughcolor #c4c4c4 -vscrollmode dynamic -dblclickcommand {} -selectioncommand {
		set SelectedProcess [ScrolledListBoxFactoryRunningProcesses curselection ]
	} -width 254
	vTcl:DefineAlias "$site_8_6_3.factoryRunningProcessesListBox" "ScrolledListBoxFactoryRunningProcesses" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_3.factoryRunningProcessesListBox -in $site_8_6_3 -anchor n -expand 1 -fill both -side top

	::iwidgets::entryfield $site_8_6_3.numberOfNotifyProcessesEntry -width 5 -labelpos w -justify right -relief flat \
	-labeltext "Number of Free Factory processes:" -textvariable NumberOfFFProcesses
	vTcl:DefineAlias "$site_8_6_3.numberOfNotifyProcessesEntry" "NumberOfFFProcessesEntry" vTcl:WidgetProc "Toplevel1" 1
	set BindWidgetEntry "$site_8_6_3.numberOfNotifyProcessesEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidgetEntry" "EntryNumberOfFFProcessesChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_3.numberOfNotifyProcessesEntry -in $site_8_6_3 -anchor w -expand 1 -fill none -side top
        bind $BindWidgetEntry <Key-Return> {}
        bind $BindWidgetEntry <Key-KP_Enter> {}

	frame $site_8_6_3.runningFFProcessesFrameRadioButton -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_8_6_3.runningFFProcessesFrameRadioButton" "FrameRadioButtonRunningFFProcesses" vTcl:WidgetProc "Toplevel1" 1

	set site_8_6_3_0 $site_8_6_3.runningFFProcessesFrameRadioButton

	radiobutton $site_8_6_3_0.userProcessesRadioButton \
	-command {
		GetNumberOfFFProcesses
	} -text User -value "User" -variable ShowProcess
	vTcl:DefineAlias "$site_8_6_3_0.userProcessesRadioButton" "RadioButtonUserProcessSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_3_0.userProcessesRadioButton -in $site_8_6_3_0 -anchor nw -expand 0 -fill none -side left

	radiobutton $site_8_6_3_0.allProcessesRadioButton \
	-command {
		GetNumberOfFFProcesses
	} -text All -value "All" -variable ShowProcess
	vTcl:DefineAlias "$site_8_6_3_0.allProcessesRadioButton" "RadioButtonAllProcessSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_3_0.allProcessesRadioButton -in $site_8_6_3_0 -anchor nw -expand 0 -fill none -side left

	pack $site_8_6_3.runningFFProcessesFrameRadioButton -in $site_8_6_3 -anchor w -expand 1 -fill x -side top

	frame $site_8_6_3.runningFFProcessesButtonFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_8_6_3.runningFFProcessesButtonFrame" "ButtonFrameRunningFFProcesses" vTcl:WidgetProc "Toplevel1" 1

	set site_8_6_3_0 $site_8_6_3.runningFFProcessesButtonFrame

	button $site_8_6_3_0.startFreeFactoryButton \
	-activebackground #f9f9f9 -activeforeground black \
	-command {
		exec /opt/FreeFactory/bin/InotifyStartupUser.sh &
		after 90 GetNumberOfFFProcesses
	} -foreground black -highlightcolor black -text "Start"
	vTcl:DefineAlias "$site_8_6_3_0.startFreeFactoryButton" "ButtonStartNotifyFreeFactory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_3_0.startFreeFactoryButton -in $site_8_6_3_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_8_6_3_0.startFreeFactoryButton "This starts Free Factory."

	button $site_8_6_3_0.restartFreeFactoryButton \
	-activebackground #f9f9f9 -activeforeground black \
	-command {
		for {set x 1} {$x <= $NumberOfFFProcesses} {incr x} {
			exec kill [expr $FFProcessList($x,FFInotifyStartupID) +1]
			exec kill $FFProcessList($x,FFInotifyStartupID)
		}
		GetNumberOfFFProcesses
		exec /opt/FreeFactory/bin/InotifyStartupUser.sh &
		after 90 GetNumberOfFFProcesses
	} -foreground black -highlightcolor black -text "Restart"
	vTcl:DefineAlias "$site_8_6_3_0.restartFreeFactoryButton" "ButtonRestartNotifyFreeFactory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_3_0.restartFreeFactoryButton -in $site_8_6_3_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_8_6_3_0.restartFreeFactoryButton "This restarts Free Factory."

	button $site_8_6_3_0.stopFreeFactoryButton \
	-activebackground #f9f9f9 -activeforeground black \
	-command {
		for {set x 1} {$x <= $NumberOfFFProcesses} {incr x} {
			exec kill [expr $FFProcessList($x,FFInotifyStartupID) +1]
			exec kill $FFProcessList($x,FFInotifyStartupID)
		}
		GetNumberOfFFProcesses
	} -foreground black -highlightcolor black -text "Stop"
	vTcl:DefineAlias "$site_8_6_3_0.stopFreeFactoryButton" "ButtonStopNotifyFreeFactory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_3_0.stopFreeFactoryButton -in $site_8_6_3_0 -anchor nw -expand 1 -fill none -side left
	balloon $site_8_6_3_0.stopFreeFactoryButton "This stops Free Factory\nby killing all processes."

	button $site_8_6_3_0.killFreeFactoryButton \
	-activebackground #f9f9f9 -activeforeground black \
	-command {
		exec kill [expr $FFProcessList([expr $SelectedProcess +1],FFInotifyStartupID) +1]
		exec kill [expr $FFProcessList([expr $SelectedProcess +1],FFInotifyStartupID) +0]
		GetNumberOfFFProcesses
	} -foreground black -highlightcolor black -text "Kill"
	vTcl:DefineAlias "$site_8_6_3_0.killFreeFactoryButton" "ButtonKillNotifyFreeFactory" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_6_3_0.killFreeFactoryButton -in $site_8_6_3_0 -anchor nw -expand 1 -fill none -side right
	balloon $site_8_6_3_0.killFreeFactoryButton "This kills the selected\nFree Factory process."

	pack $site_8_6_3.runningFFProcessesButtonFrame -in $site_8_6_3 -anchor w -expand 1 -fill x -side top

 	pack $site_8_6.freeFactoryNotifyDirectoriesFrame -in $site_8_6 -anchor center -expand 1 -fill both -side top

#############################################################################
#############################################################################
	set site_8_7 [lindex [$top.settingsTabNotebook childsite] 3]

	::iwidgets::labeledframe $site_8_7.selectionCompanyInfoFrame -labelpos nw -labeltext "Company Information"
	vTcl:DefineAlias "$site_8_7.selectionCompanyInfoFrame" "LabeledFrameSelectionCompanyInfoSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_7_0 [$site_8_7.selectionCompanyInfoFrame childsite]

	::iwidgets::entryfield $site_8_7_0.nameCompanyEntry -borderwidth 2  -relief sunken -labelpos w \
	-labeltext "Company Name" -textvariable PPref(TheCompanyName) -width 35
	set BindWidget "$site_8_7_0.nameCompanyEntry"
	set BindWidgetEntry "$site_8_7_0.nameCompanyEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidget" "CompanyNameSettingsEntry" vTcl:WidgetProc "Toplevel1" 1
	vTcl:DefineAlias "$BindWidgetEntry" "EntryCompanyNameSettingsChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_0.nameCompanyEntry -in $site_8_7_0 -anchor nw -expand 0 -fill none -side top
	bind $BindWidgetEntry <FocusIn> {
		if {$PPref(SelectAllText) == "Yes"} {EntryCompanyNameSettingsChild select range 0 end}
			CompanyNameSettingsEntry icursor end
	}
	bind $BindWidgetEntry <FocusOut> {CheckForSettingsApplyEnable}
	bind $BindWidgetEntry <Key-Return> {}
	bind $BindWidgetEntry <Key-KP_Enter> {}
	bind $BindWidgetEntry <Control-Down> {}
	bind $BindWidgetEntry <Control-Up> {}
	bind $BindWidgetEntry <Control-Left> {}
	bind $BindWidgetEntry <Control-Right> {}

 	pack $site_8_7.selectionCompanyInfoFrame -in $site_8_7 -anchor center -expand 1 -fill x -side top

	::iwidgets::labeledframe $site_8_7.freeFactoryOptionsFrame -labelpos nw -labeltext "Free Factory Options"
	vTcl:DefineAlias "$site_8_7.freeFactoryOptionsFrame" "LabeledFrameFreeFactoryOptionsSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_7_0 [$site_8_7.freeFactoryOptionsFrame childsite]

	::iwidgets::entryfield $site_8_7_0.appleDelayEntry -borderwidth 2  -relief sunken -labelpos w \
	-labeltext "Apple Delay" -justify right -textvariable PPref(AppleDelay) -width 5
	set BindWidget "$site_8_7_0.appleDelayEntry"
	set BindWidgetEntry "$site_8_7_0.appleDelayEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidget" "AppleDelaySettingsEntry" vTcl:WidgetProc "Toplevel1" 1
	vTcl:DefineAlias "$BindWidgetEntry" "EntryAppleDelaySettingsChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_0.appleDelayEntry -in $site_8_7_0 -anchor nw -expand 0 -fill none -side top
	bind $BindWidgetEntry <FocusIn> {
		if {$PPref(SelectAllText) == "Yes"} {EntryAppleDelaySettingsChild select range 0 end}
			AppleDelaySettingsEntry icursor end
	}
	bind $BindWidgetEntry <FocusOut> {CheckForSettingsApplyEnable}
	bind $BindWidgetEntry <Key-Return> {}
	bind $BindWidgetEntry <Key-KP_Enter> {}
	bind $BindWidgetEntry <Control-Down> {}
	bind $BindWidgetEntry <Control-Up> {}
	bind $BindWidgetEntry <Control-Left> {}
	bind $BindWidgetEntry <Control-Right> {}

	::iwidgets::labeledframe $site_8_7_0.userDefaultsFrame -labelpos nw -labeltext "User Defaults"
	vTcl:DefineAlias "$site_8_7_0.userDefaultsFrame" "LabeledFrameUserDefaultsSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_7_1 [$site_8_7_0.userDefaultsFrame childsite]

	frame $site_8_7_1.userDefault1ButtonFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_8_7_1.userDefault1ButtonFrame" "FrameRadioButtonUserDefault1" vTcl:WidgetProc "Toplevel1" 1

	set site_8_7_2 $site_8_7_1.userDefault1ButtonFrame

	label $site_8_7_2.fFMxProgramLabelSettings -text "FFMx Program" -background #ececec
	vTcl:DefineAlias "$site_8_7_2.fFMxProgramLabelSettings" "LabelFFMxProgramSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.fFMxProgramLabelSettings -in $site_8_7_2 -anchor e -expand 0 -padx 2 -fill none -side left

	radiobutton $site_8_7_2.fFMxProgramFFMPEGRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text ffmpeg -value "ffmpeg" -variable PPref(FFMxProgram)
	vTcl:DefineAlias "$site_8_7_2.fFMxProgramFFMPEGRadioButtonSettings" "RadioButtonFFMxProgramFFMPEGSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.fFMxProgramFFMPEGRadioButtonSettings -in $site_8_7_2 -anchor e -expand 0 -fill none -side left

	radiobutton $site_8_7_2.fFMxProgramFFMBCRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text ffmbc -value "ffmbc" -variable PPref(FFMxProgram)
	vTcl:DefineAlias "$site_8_7_2.fFMxProgramFFMBCRadioButtonSettings" "RadioButtonFFMxProgramFFMBCSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.fFMxProgramFFMBCRadioButtonSettings -in $site_8_7_2 -anchor e -expand 0 -fill none -side left

	pack $site_8_7_1.userDefault1ButtonFrame -in $site_8_7_1 -anchor nw -expand 0 -fill none -side top

	frame $site_8_7_1.userDefault2ButtonFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_8_7_1.userDefault2ButtonFrame" "FrameRadioButtonUserDefault2" vTcl:WidgetProc "Toplevel1" 1

	set site_8_7_2 $site_8_7_1.userDefault2ButtonFrame

	label $site_8_7_2.runFromLabelSettings -text "Run From" -background #ececec
	vTcl:DefineAlias "$site_8_7_2.runFromLabelSettings" "LabelRunFromSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.runFromLabelSettings -in $site_8_7_2 -anchor e -expand 0 -padx 2 -fill none -side left

	radiobutton $site_8_7_2.runFromUSRRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text "/usr/bin/" -value "usr" -variable PPref(RunFrom)
	vTcl:DefineAlias "$site_8_7_2.runFromUSRRadioButtonSettings" "RadioButtonRunFromUSRSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.runFromUSRRadioButtonSettings -in $site_8_7_2 -anchor e -expand 0 -fill none -side left

	radiobutton $site_8_7_2.runFromOptRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text "/opt/FreeFactory/bin/" -value "opt" -variable PPref(RunFrom)
	vTcl:DefineAlias "$site_8_7_2.runFromOptRadioButtonSettings" "RadioButtonRunFromOptSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.runFromOptRadioButtonSettings -in $site_8_7_2 -anchor e -expand 0 -fill none -side left

	pack $site_8_7_1.userDefault2ButtonFrame -in $site_8_7_1 -anchor nw -expand 0 -fill none -side top

	checkbutton $site_8_7_1.enableFactoryCheckBoxSettings -command {CheckForSettingsApplyEnable} -offvalue 0 -onvalue 1  -text "Enable Factory" -variable PPref(EnableFactory)
	vTcl:DefineAlias "$site_8_7_1.enableFactoryCheckBoxSettings" "CheckButtonEnableFactorySettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_1.enableFactoryCheckBoxSettings -in $site_8_7_1 -anchor nw -expand 0 -padx 0 -fill none -side top

	checkbutton $site_8_7_1.removeSourceCheckBoxSettings -command {CheckForSettingsApplyEnable} -offvalue "No" -onvalue "Yes"  -text "Remove Source" -variable PPref(DeleteSource)
	vTcl:DefineAlias "$site_8_7_1.removeSourceCheckBoxSettings" "CheckButtonRemoveSourceSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_1.removeSourceCheckBoxSettings -in $site_8_7_1 -anchor nw -expand 0 -padx 0 -fill none -side top

	checkbutton $site_8_7_1.removeLogsCheckBoxSettings -command {CheckForSettingsApplyEnable} -offvalue "No" -onvalue "Yes"  -text "Remove Logs" -variable PPref(DeleteLogs)
	vTcl:DefineAlias "$site_8_7_1.removeLogsCheckBoxSettings" "CheckButtonRemoveLogsSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_1.removeLogsCheckBoxSettings -in $site_8_7_1 -anchor nw -expand 0 -padx 0 -fill none -side top

	frame $site_8_7_1.userDefault8ButtonFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_8_7_1.userDefault8ButtonFrame" "FrameRadioButtonUserDefault8" vTcl:WidgetProc "Toplevel1" 1

	set site_8_7_2 $site_8_7_1.userDefault8ButtonFrame

	label $site_8_7_2.freeFactoryActionSettingsLabelSettings -text "Action" -background #ececec
	vTcl:DefineAlias "$site_8_7_2.freeFactoryActionSettingsLabelSettings" "LabelFreeFactoryActionSettingsSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.freeFactoryActionSettingsLabelSettings -in $site_8_7_2 -anchor e -expand 0 -padx 2 -fill none -side left

	radiobutton $site_8_7_2.freeFactoryActionSettingsEncodeRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text "Encode" -value "Encode" -variable PPref(FreeFactoryAction)
	vTcl:DefineAlias "$site_8_7_2.freeFactoryActionSettingsEncodeRadioButtonSettings" "RadioButtonFreeFactoryActionSettingsEncodeSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.freeFactoryActionSettingsEncodeRadioButtonSettings -in $site_8_7_2 -anchor e -expand 0 -fill none -side left

	radiobutton $site_8_7_2.freeFactoryActionSettingsCopyRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text "Copy" -value "Copy" -variable PPref(FreeFactoryAction)
	vTcl:DefineAlias "$site_8_7_2.freeFactoryActionSettingsCopyRadioButtonSettings" "RadioButtonFreeFactoryActionSettingsCopySettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.freeFactoryActionSettingsCopyRadioButtonSettings -in $site_8_7_2 -anchor e -expand 0 -fill none -side left

	pack $site_8_7_1.userDefault8ButtonFrame -in $site_8_7_1 -anchor nw -expand 0 -fill none -side top

	frame $site_8_7_1.userDefault3ButtonFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_8_7_1.userDefault3ButtonFrame" "FrameRadioButtonUserDefault3" vTcl:WidgetProc "Toplevel1" 1

	set site_8_7_2 $site_8_7_1.userDefault3ButtonFrame

	label $site_8_7_2.ftpTransferTypeLabelSettings -text "FTP Transfer Type" -background #ececec
	vTcl:DefineAlias "$site_8_7_2.ftpTransferTypeLabelSettings" "LabelFTPTransferTypeSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.ftpTransferTypeLabelSettings -in $site_8_7_2 -anchor e -expand 0 -padx 2 -fill none -side left

	radiobutton $site_8_7_2.ftpTransferTypeASCRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text "ASCII" -value "asc" -variable PPref(FTPTransferType)
	vTcl:DefineAlias "$site_8_7_2.ftpTransferTypeASCRadioButtonSettings" "RadioButtonFTPTransferTypeASCSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.ftpTransferTypeASCRadioButtonSettings -in $site_8_7_2 -anchor e -expand 0 -fill none -side left

	radiobutton $site_8_7_2.ftpTransferTypeBINRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text "Binary" -value "bin" -variable PPref(FTPTransferType)
	vTcl:DefineAlias "$site_8_7_2.ftpTransferTypeBINRadioButtonSettings" "RadioButtonFTPTransferTypeBINSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_2.ftpTransferTypeBINRadioButtonSettings -in $site_8_7_2 -anchor e -expand 0 -fill none -side left

	pack $site_8_7_1.userDefault3ButtonFrame -in $site_8_7_1 -anchor nw -expand 0 -fill none -side top

	checkbutton $site_8_7_1.ftpDeleteAfterCheckBoxSettings -command {CheckForSettingsApplyEnable} -offvalue "No" -onvalue "Yes"  -text "Remove Output File After FTP" -variable PPref(FTPDeleteAfter)
	vTcl:DefineAlias "$site_8_7_1.ftpDeleteAfterCheckBoxSettings" "CheckButtonFTPDeleteAfterSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_1.ftpDeleteAfterCheckBoxSettings -in $site_8_7_1 -anchor nw -expand 0 -padx 0 -fill none -side top

	checkbutton $site_8_7_1.enableEMailCheckBoxSettings -command {CheckForSettingsApplyEnable} -offvalue "No" -onvalue "Yes"  -text "Enable EMail" -variable PPref(EnableEMail)
	vTcl:DefineAlias "$site_8_7_1.enableEMailCheckBoxSettings" "CheckButtonEnableEMailSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_1.enableEMailCheckBoxSettings -in $site_8_7_1 -anchor nw -expand 0 -padx 0 -fill none -side top

	checkbutton $site_8_7_1.enableFactoryLinkingCheckBoxSettings -command {CheckForSettingsApplyEnable} -offvalue "No" -onvalue "Yes"  -text "Enable Factory Linking" -variable PPref(EnableFactoryLinking)
	vTcl:DefineAlias "$site_8_7_1.enableFactoryLinkingCheckBoxSettings" "CheckButtonEnableFactoryLinkingSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_1.enableFactoryLinkingCheckBoxSettings -in $site_8_7_1 -anchor nw -expand 0 -padx 0 -fill none -side top

	pack $site_8_7_0.userDefaultsFrame -in $site_8_7_0 -anchor nw -expand 0 -fill x -side top
 	pack $site_8_7.freeFactoryOptionsFrame -in $site_8_7 -anchor center -expand 1 -fill x -side top

	::iwidgets::labeledframe $site_8_7.freeFactoryEmailFrame -labelpos nw -labeltext "EMail Settings"
	vTcl:DefineAlias "$site_8_7.freeFactoryEmailFrame" "LabeledFrameEmailSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_7_3 [$site_8_7.freeFactoryEmailFrame childsite]

	::iwidgets::entryfield $site_8_7_3.sMTPEMailServerEntry -width 30 -labeltext "SMTP EMail Server" \
	-textvariable PPref(SMTPEMailServer) -relief sunken -justify left -command {CheckForSettingsApplyEnable}
	vTcl:DefineAlias "$site_8_7_3.sMTPEMailServerEntry" "SMTPEMailServerEntry" vTcl:WidgetProc "Toplevel1" 1
	set BindWidget "$site_8_7_3.sMTPEMailServerEntry"
	set BindWidgetEntry "$site_8_7_3.sMTPEMailServerEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidgetEntry" "EntrySMTPEMailServerChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_3.sMTPEMailServerEntry -in $site_8_7_3 -anchor nw -expand 0 -fill none -side top
	bind $BindWidgetEntry <FocusOut> {CheckForSettingsApplyEnable}
	bind $BindWidgetEntry <FocusIn> {
		if {$PPref(SelectAllText) == "Yes"} {EntrySMTPEMailServerChild select range 0 end}
		EntrySMTPEMailServerChild icursor end
	}
	bind $BindWidgetEntry <Key-Return> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.portEMailServerEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Key-KP_Enter> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.portEMailServerEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Down> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.portEMailServerEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Up> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailFromAddressEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Left> {}
	bind $BindWidgetEntry <Control-Right> {}

	::iwidgets::entryfield $site_8_7_3.portEMailServerEntry -width 5 -labeltext "EMail Port" \
	-textvariable PPref(SMTPEMailPort) -relief sunken -justify right -command {CheckForSettingsApplyEnable}
	vTcl:DefineAlias "$site_8_7_3.portEMailServerEntry" "EMailPortEntry" vTcl:WidgetProc "Toplevel1" 1
	set BindWidget "$site_8_7_3.portEMailServerEntry"
	set BindWidgetEntry "$site_8_7_3.portEMailServerEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidgetEntry" "EntryEMailPortChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_3.portEMailServerEntry -in $site_8_7_3 -anchor nw -expand 0 -fill none -side top
	bind $BindWidgetEntry <FocusOut> {CheckForSettingsApplyEnable}
	bind $BindWidgetEntry <FocusIn> {
		if {$PPref(SelectAllText) == "Yes"} {EntryEMailPortChild select range 0 end}
		EntryEMailPortChild icursor end
	}
	bind $BindWidgetEntry <Key-Return> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailUserNameEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Key-KP_Enter> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailUserNameEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Down> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailUserNameEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Up> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.sMTPEMailServerEntry.lwchildsite.entry}

	::iwidgets::entryfield $site_8_7_3.eMailUserNameEntry -width 30 -labeltext "User Name" \
	-textvariable PPref(SMTPEMailUserName) -relief sunken -justify left -command {CheckForSettingsApplyEnable}
	vTcl:DefineAlias "$site_8_7_3.eMailUserNameEntry" "EMailUserNameEntry" vTcl:WidgetProc "Toplevel1" 1
	set BindWidget "$site_8_7_3.eMailUserNameEntry"
	set BindWidgetEntry "$site_8_7_3.eMailUserNameEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidgetEntry" "EntryEMailUserNameChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_3.eMailUserNameEntry -in $site_8_7_3 -anchor nw -expand 0 -fill none -side top
	bind $BindWidgetEntry <FocusOut> {CheckForSettingsApplyEnable}
	bind $BindWidgetEntry <FocusIn> {
		if {$PPref(SelectAllText) == "Yes"} {EntryEMailUserNameChild select range 0 end}
		EntryEMailUserNameChild icursor end
	}
	bind $BindWidgetEntry <Key-Return> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailPasswordEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Key-KP_Enter> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailPasswordEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Down> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailPasswordEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Up> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.portEMailServerEntry.lwchildsite.entry}

	::iwidgets::entryfield $site_8_7_3.eMailPasswordEntry -width 20 -labeltext "Password" \
	-textvariable PPref(SMTPEMailPassword) -relief sunken -justify left -show "*" -command {CheckForSettingsApplyEnable}
	vTcl:DefineAlias "$site_8_7_3.eMailPasswordEntry" "EMailPasswordEntry" vTcl:WidgetProc "Toplevel1" 1
	set BindWidget "$site_8_7_3.eMailPasswordEntry"
	set BindWidgetEntry "$site_8_7_3.eMailPasswordEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidgetEntry" "EntryEMailPasswordChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_3.eMailPasswordEntry -in $site_8_7_3 -anchor nw -expand 0 -fill none -side top
	bind $BindWidgetEntry <FocusOut> {CheckForSettingsApplyEnable}
	bind $BindWidgetEntry <FocusIn> {
		if {$PPref(SelectAllText) == "Yes"} {EntryEMailPasswordChild select range 0 end}
		EntryEMailPasswordChild icursor end
	}
	bind $BindWidgetEntry <Key-Return> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailFromNameEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Key-KP_Enter> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailFromNameEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Down> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailFromNameEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Up> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailUserNameEntry.lwchildsite.entry}

	::iwidgets::entryfield $site_8_7_3.eMailFromNameEntry -width 30 -labeltext "FromName" \
	-textvariable PPref(SMTPEMailFromName) -relief sunken -justify left -command {CheckForSettingsApplyEnable}
	vTcl:DefineAlias "$site_8_7_3.eMailFromNameEntry" "EMailFromNameEntry" vTcl:WidgetProc "Toplevel1" 1
	set BindWidget "$site_8_7_3.eMailFromNameEntry"
	set BindWidgetEntry "$site_8_7_3.eMailFromNameEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidgetEntry" "EntryEMailFromNameChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_3.eMailFromNameEntry -in $site_8_7_3 -anchor nw -expand 0 -fill none -side top
	bind $BindWidgetEntry <FocusOut> {CheckForSettingsApplyEnable}
	bind $BindWidgetEntry <FocusIn> {
		if {$PPref(SelectAllText) == "Yes"} {EntryEMailFromNameChild select range 0 end}
		EntryEMailFromNameChild icursor end
	}
	bind $BindWidgetEntry <Key-Return> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailFromAddressEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Key-KP_Enter> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailFromAddressEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Down> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailFromAddressEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Up> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailPasswordEntry.lwchildsite.entry}

	::iwidgets::entryfield $site_8_7_3.eMailFromAddressEntry -width 30 -labeltext "FromAddress" \
	-textvariable PPref(SMTPEMailFromAddress) -relief sunken -justify left -command {CheckForSettingsApplyEnable}
	vTcl:DefineAlias "$site_8_7_3.eMailFromAddressEntry" "EMailFromAddressEntry" vTcl:WidgetProc "Toplevel1" 1
	set BindWidget "$site_8_7_3.eMailFromAddressEntry"
	set BindWidgetEntry "$site_8_7_3.eMailFromAddressEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidgetEntry" "EntryEMailFromAddressChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_3.eMailFromAddressEntry -in $site_8_7_3 -anchor nw -expand 0 -fill none -side top
	bind $BindWidgetEntry <FocusOut> {CheckForSettingsApplyEnable}
	bind $BindWidgetEntry <FocusIn> {
		if {$PPref(SelectAllText) == "Yes"} {EntryEMailFromAddressChild select range 0 end}
		EntryEMailFromAddressChild icursor end
	}
	bind $BindWidgetEntry <Key-Return> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.sMTPEMailServerEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Key-KP_Enter> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.sMTPEMailServerEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Down> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.sMTPEMailServerEntry.lwchildsite.entry}
	bind $BindWidgetEntry <Control-Up> {focus .settings.settingsTabNotebook.canvas.notebook.cs.page4.cs.freeFactoryEmailFrame.childsite.eMailFromNameEntry.lwchildsite.entry}

	frame $site_8_7_3.tlsFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$site_8_7_3.tlsFrame" "FrameEMailTLS" vTcl:WidgetProc "Toplevel1" 1

	set site_8_7_4 $site_8_7_3.tlsFrame

	label $site_8_7_4.eMailTLSSettingsLabelSettings -text "TLS" -background #ececec
	vTcl:DefineAlias "$site_8_7_4.eMailTLSSettingsLabelSettings" "LabelEMailTLSSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_4.eMailTLSSettingsLabelSettings -in $site_8_7_4 -anchor e -expand 0 -padx 2 -fill none -side left

	radiobutton $site_8_7_4.eMailTLSSettingsYesRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text "Yes" -value 1 -variable PPref(SMTPEMailTLS)
	vTcl:DefineAlias "$site_8_7_4.eMailTLSSettingsYesRadioButtonSettings" "RadioButtonEMailTLSYesSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_4.eMailTLSSettingsYesRadioButtonSettings -in $site_8_7_4 -anchor e -expand 0 -fill none -side left

	radiobutton $site_8_7_4.eMailTLSSettingsNoRadioButtonSettings \
	-command {CheckForSettingsApplyEnable} -text "No" -value 0 -variable PPref(SMTPEMailTLS)
	vTcl:DefineAlias "$site_8_7_4.eMailTLSSettingsNoRadioButtonSettings" "RadioButtonEMailTLSNoSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_4.eMailTLSSettingsNoRadioButtonSettings -in $site_8_7_4 -anchor e -expand 0 -fill none -side left

	button $site_8_7_4.addGlobalEMailMessageButton -borderwidth 1 -highlightthickness 0 -relief raised \
	-command {
		source "/opt/FreeFactory/bin/FreeFactoryEMailMessage.tcl"
		Window show .freeFactoryEMailMessage
		Window show .freeFactoryEMailMessage
		widgetUpdate
		ScrolledTextFactoryEMailMessage clear
		ScrolledTextFactoryEMailMessage insert end $PPref(GlobalEMailMessage)

	} -image [vTcl:image:get_image [file join / opt FreeGlobal Pics Message-32x32.gif]]
	vTcl:DefineAlias "$site_8_7_4.addGlobalEMailMessageButton" "ButtonAddGlobalEMailMessage" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_7_4.addGlobalEMailMessageButton -in $site_8_7_4 -anchor center -expand 1 -fill none -side right
	balloon $site_8_7_4.addGlobalEMailMessageButton "Add Message"

	pack $site_8_7_3.tlsFrame -in $site_8_7_3 -anchor nw -expand 0 -fill x -side top
 	pack $site_8_7.freeFactoryEmailFrame -in $site_8_7 -anchor center -expand 1 -fill x -side top

#############################################################################
	set site_8_8 [lindex [$top.settingsTabNotebook childsite] 4]

	::iwidgets::labeledframe $site_8_8.filePathFrame -labelpos nw -labeltext "File Paths"
	vTcl:DefineAlias "$site_8_8.filePathFrame" "LabeledFrameFilePathSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_8_0 [$site_8_8.filePathFrame childsite]

	frame $site_8_8_0.framePDFReaderPath -height 2 -highlightcolor black -relief flat -width 12  -border 0
	vTcl:DefineAlias "$site_8_8_0.framePDFReaderPath" "FramePDFReaderPath" vTcl:WidgetProc "Toplevel1" 1

	set site_8_8_0_1 $site_8_8_0.framePDFReaderPath

	::iwidgets::entryfield $site_8_8_0_1.pdfReaderPathEntry -borderwidth 2  -relief sunken -labelpos w \
	-labeltext "PDF Reader Path" -textvariable PDFReaderPath -width 35
	set BindWidget "$site_8_8_0_1.pdfReaderPathEntry"
	set BindWidgetEntry "$site_8_8_0_1.pdfReaderPathEntry.lwchildsite.entry"
	vTcl:DefineAlias "$BindWidget" "PDFReaderPathSettingsEntry" vTcl:WidgetProc "Toplevel1" 1
	vTcl:DefineAlias "$BindWidgetEntry" "EntryPDFReaderPathSettingsChild" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_8_0_1.pdfReaderPathEntry -in $site_8_8_0_1 -anchor nw -expand 1 -fill x -side left
	bind $BindWidgetEntry <FocusIn> {
		if {$PPref(SelectAllText) == "Yes"} {EntryPDFReaderPathSettingsChild select range 0 end}
		PDFReaderPathSettingsEntry icursor end
	}

	button $site_8_8_0_1.browsePDFReaderPathButton -relief raise -borderwidth 1 \
	-command {
		source "/usr/local/FreeFactory/FileDialog.tcl"
		set WindowName "Browse PDF Reader Path"
		set ToolTip "Select File"
		set fileDialogOk "Cancel"
		set buttonImagePathFileDialog [vTcl:image:get_image [file join / usr local  FreeFactory Pics Open-32x32.gif]]
		set fullDirPath "/"
		set FileSelectTypeList {
			{{All files}  {*}}
		}
		set returnFullPath ""
		Window show .fileDialog
		Window show .fileDialog
		widgetUpdate
		initFileDialog
		tkwait window .fileDialog
		if {$returnFullPath!=""} {
			set PDFReaderPath $returnFullPath
			set PPrefTmp(PDFReaderPath) $PDFReaderPath
			CheckForSettingsApplyEnable
		}
	} -image [vTcl:image:get_image [file join / usr local  FreeFactory Pics Open-32x32.gif]]
	vTcl:DefineAlias "$site_8_8_0_1.browsePDFReaderPathButton" "ButtonPDFReaderPathSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_8_0_1.browsePDFReaderPathButton -in $site_8_8_0_1 -anchor nw -expand 0 -fill none -side right
	balloon $site_8_8_0_1.browsePDFReaderPathButton "Browse"

	pack $site_8_8_0.framePDFReaderPath -in $site_8_8_0 -anchor center -expand 1 -fill x -side top
	pack $site_8_8.filePathFrame -in $site_8_8 -anchor center -expand 1 -fill x -side top

	::iwidgets::labeledframe $site_8_8.selectionOptionsFrame -labelpos nw -labeltext "Text Selection Options"
	vTcl:DefineAlias "$site_8_8.selectionOptionsFrame" "LabeledFrameSelectionOptionsSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_8_0 [$site_8_8.selectionOptionsFrame childsite]

	checkbutton $site_8_8_0.textSelectCheckButton \
	 -command {
		set PPrefTmp(SelectAllText) $SelectAllText
		CheckForSettingsApplyEnable
	} -text "Select all text on widget entry" -onvalue "Yes" -offvalue "No" -variable SelectAllText -wrap 0
	vTcl:DefineAlias "$site_8_8_0.textSelectCheckButton" "CheckButtonSelectAllTextSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_8_0.textSelectCheckButton -in $site_8_8_0 -anchor nw -expand 0 -fill none -side top

	pack $site_8_8.selectionOptionsFrame -in $site_8_8 -anchor center -expand 1 -fill x -side top

	::iwidgets::labeledframe $site_8_8.selectionConfirmationsFrame -labelpos nw -labeltext "Confirmation Options"
	vTcl:DefineAlias "$site_8_8.selectionConfirmationsFrame" "LabeledFrameSelectionConfirmationsSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_8_1 [$site_8_8.selectionConfirmationsFrame childsite]

	checkbutton $site_8_8_1.confirmFileSavesCheckButton \
	-command {
		set PPrefTmp(ConfirmFileSaves) $ConfirmFileSaves
		CheckForSettingsApplyEnable
	} -text "Confirm File Saves" -onvalue "Yes" -offvalue "No" -variable ConfirmFileSaves -wrap 0
	vTcl:DefineAlias "$site_8_8_1.confirmFileSavesCheckButton" "CheckButtonConfirmFileSavesSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_8_1.confirmFileSavesCheckButton -in $site_8_8_1 -anchor nw -expand 0 -fill none -side top

	checkbutton $site_8_8_1.confirmFileDeletionsCheckButton \
	 -command {
		set PPrefTmp(ConfirmFileDeletions) $ConfirmFileDeletions
		CheckForSettingsApplyEnable
	} -text "Confirm File Deletions" -onvalue "Yes" -offvalue "No" -variable ConfirmFileDeletions -wrap 0
	vTcl:DefineAlias "$site_8_8_1.confirmFileDeletionsCheckButton" "CheckButtonConfirmFileDeletionSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_8_1.confirmFileDeletionsCheckButton -in $site_8_8_1 -anchor nw -expand 0 -fill none -side top


	pack $site_8_8.selectionConfirmationsFrame -in $site_8_8 -anchor center -expand 1 -fill x -side top

	::iwidgets::labeledframe $site_8_8.selectionIconBarFrame -labelpos nw -labeltext "Icon Button Bar & Tool Tip Options"
	vTcl:DefineAlias "$site_8_8.selectionIconBarFrame" "LabeledFrameSelectionIconBarSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_8_2 [$site_8_8.selectionIconBarFrame childsite]

	checkbutton $site_8_8_2.showToolTipsCheckButton -activebackground #f9f9f9 -activeforeground black \
	 -command {
		set PPrefTmp(ShowToolTips) $ShowToolTips
		CheckForSettingsApplyEnable
	} -text "Show Tool Tips" -onvalue "Yes" -offvalue "No" -variable ShowToolTips -wrap 0
	vTcl:DefineAlias "$site_8_8_2.showToolTipsCheckButton" "CheckButtonShowToolTipsSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_8_2.showToolTipsCheckButton -in $site_8_8_2 -anchor nw -expand 0 -fill none -side top

	pack $site_8_8.selectionIconBarFrame -in $site_8_8 -anchor center -expand 1 -fill x -side top
#############################################################################
#############################################################################
    $top.settingsTabNotebook select 0
#############################################################################
#Bottom Buuttons Here
	frame $top.footerFrame -height 25 -relief flat -width 430  -borderwidth 0
	vTcl:DefineAlias "$top.footerFrame" "FrameFooterSettings" vTcl:WidgetProc "Toplevel1" 1

	set site_8_5 $top.footerFrame

	button $site_8_5.settingsOkButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		set PPrefTmp(DateSeparater) $ShortLongSeparater
		set PPrefTmp(DisplayTimeFormat) $TimeFormatVar
		set PPrefTmp(TimeSeparater) $TimeSeparater
		set PPrefTmp(DisplayDayOfWeek) $DisplayDayOfWeek
		set PPrefTmp(SelectAllText) $SelectAllText
		set PPrefTmp(ConfirmFileSaves) $ConfirmFileSaves
		set PPrefTmp(ConfirmFileDeletions) $ConfirmFileDeletions
		set PPrefTmp(PDFReaderPath) $PDFReaderPath
		set PPrefTmp(ShowToolTips) $ShowToolTips
		set PPref(color,window,fore) $PPrefTmp(color,window,fore)
		set PPref(color,window,back) $PPrefTmp(color,window,back)
		set PPref(color,widget,fore) $PPrefTmp(color,widget,fore)
		set PPref(color,widget,back) $PPrefTmp(color,widget,back)
		set PPref(color,active,fore) $PPrefTmp(color,active,fore)
		set PPref(color,active,back) $PPrefTmp(color,active,back)
		set PPref(color,directory) $PPrefTmp(color,directory)
		set PPref(color,file) $PPrefTmp(color,file)
		set PPref(color,selection,fore) $PPrefTmp(color,selection,fore)
		set PPref(color,selection,back) $PPrefTmp(color,selection,back)
		set PPref(color,ToolTipForeground) $PPrefTmp(color,ToolTipForeground)
		set PPref(color,ToolTipBackground) $PPrefTmp(color,ToolTipBackground)
		set PPref(Foundry,label) $PPrefTmp(Foundry,label)
		set PPref(fonts,label) $PPrefTmp(fonts,label)
		set PPref(Foundry,text) $PPrefTmp(Foundry,text)
		set PPref(fonts,text) $PPrefTmp(fonts,text)
		set PPref(Foundry,ToolTip) $PPrefTmp(Foundry,ToolTip)
		set PPref(fonts,ToolTip) $PPrefTmp(fonts,ToolTip)
		set PPref(DisplayDateFormat) $PPrefTmp(DisplayDateFormat)
		set PPref(DateSeparater) $PPrefTmp(DateSeparater)
		set PPref(DisplayTimeFormat) $PPrefTmp(DisplayTimeFormat)
		set PPref(TimeSeparater) $PPrefTmp(TimeSeparater)
		set PPref(DisplayDayOfWeek)  $PPrefTmp(DisplayDayOfWeek)
		set PPref(SelectAllText) $PPrefTmp(SelectAllText)
		set PPref(ConfirmFileSaves) $PPrefTmp(ConfirmFileSaves)
		set PPref(ConfirmFileDeletions) $PPrefTmp(ConfirmFileDeletions)
		set PPref(PDFReaderPath) $PPrefTmp(PDFReaderPath)
		set PPref(ShowToolTips) $PPrefTmp(ShowToolTips)
		set PPref(TheCompanyName) $PPrefTmp(TheCompanyName)
		set PPref(AppleDelay) $PPrefTmp(AppleDelay)
		set PPref(FFMxProgram) $PPrefTmp(FFMxProgram)
		set PPref(RunFrom) $PPrefTmp(RunFrom)
		set PPref(EnableEMail) $PPrefTmp(EnableEMail)
		set PPref(EnableFactoryLinking) $PPrefTmp(EnableFactoryLinking)
		set PPref(FTPTransferType) $PPrefTmp(FTPTransferType)
		set PPref(FTPDeleteAfter) $PPrefTmp(FTPDeleteAfter)
		set PPref(EnableFactory) $PPrefTmp(EnableFactory)
		set PPref(DeleteSource) $PPrefTmp(DeleteSource)
		set PPref(DeleteLogs) $PPrefTmp(DeleteLogs)
		set PPref(FreeFactoryAction) $PPrefTmp(FreeFactoryAction)
		set PPref(SMTPEMailServer) $PPrefTmp(SMTPEMailServer)
		set PPref(SMTPEMailPort) $PPrefTmp(SMTPEMailPort)
		set PPref(SMTPEMailUserName) $PPrefTmp(SMTPEMailUserName)
		set PPref(SMTPEMailPassword) $PPrefTmp(SMTPEMailPassword)
		set PPref(SMTPEMailFromName) $PPrefTmp(SMTPEMailFromName)
		set PPref(SMTPEMailFromAddress) $PPrefTmp(SMTPEMailFromAddress)
		set PPref(SMTPEMailTLS) $PPrefTmp(SMTPEMailTLS)
		set PPref(GlobalEMailMessage) $PPrefTmp(GlobalEMailMessage)
		widgetUpdate

# If CreateUpdateFile is checked then set the file
#		if {$PPref(CreateUpdateFile)=="Yes"} {set UpdateFileName "UpdateFile-$TheCompanySiteLocationName-[clock format [clock seconds] -format %Y]-[clock format [clock seconds] -format %m]-[clock format [clock seconds] -format %d].ssql"}
# Run sub routine to display the icon button frames if selected
		destroy window .settings
	} -text "Ok"
	vTcl:DefineAlias "$site_8_5.settingsOkButton" "ButtonOkSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5.settingsOkButton -in $site_8_5 -anchor center -expand 1 -fill none -side left
	balloon .settings.footerFrame.settingsOkButton "Ok - Close And Accept Changes"

	button $site_8_5.settingsApplyButton \
	-command {
		set PPrefTmp(DisplayDateFormat) $DateFormatVar
		set PPrefTmp(DateSeparater) $ShortLongSeparater
		set PPrefTmp(DisplayTimeFormat) $TimeFormatVar
		set PPrefTmp(TimeSeparater) $TimeSeparater
		set PPrefTmp(DisplayDayOfWeek) $DisplayDayOfWeek
		set PPrefTmp(SelectAllText) $SelectAllText
		set PPrefTmp(ConfirmFileSaves) $ConfirmFileSaves
		set PPrefTmp(ConfirmFileDeletions) $ConfirmFileDeletions
		set PPrefTmp(PDFReaderPath) $PDFReaderPath
		set PPrefTmp(ShowToolTips) $ShowToolTips
		set PPrefTmp(TheCompanyName) $PPref(TheCompanyName)
		set PPrefTmp(AppleDelay) $PPref(AppleDelay)
		set PPrefTmp(FFMxProgram) $PPref(FFMxProgram)
		set PPrefTmp(RunFrom) $PPref(RunFrom)
		set PPrefTmp(EnableEMail) $PPref(EnableEMail)
		set PPrefTmp(EnableFactoryLinking) $PPref(EnableFactoryLinking)
		set PPrefTmp(FTPTransferType) $PPref(FTPTransferType)
		set PPrefTmp(FTPDeleteAfter) $PPref(FTPDeleteAfter)
		set PPrefTmp(EnableFactory) $PPref(EnableFactory)
		set PPrefTmp(DeleteSource) $PPref(DeleteSource)
		set PPrefTmp(DeleteLogs) $PPref(DeleteLogs)
		set PPrefTmp(FreeFactoryAction) $PPref(FreeFactoryAction)
		set PPrefTmp(SMTPEMailServer) $PPref(SMTPEMailServer)
		set PPrefTmp(SMTPEMailPort) $PPref(SMTPEMailPort)
		set PPrefTmp(SMTPEMailUserName) $PPref(SMTPEMailUserName)
		set PPrefTmp(SMTPEMailPassword) $PPref(SMTPEMailPassword)
		set PPrefTmp(SMTPEMailFromName) $PPref(SMTPEMailFromName)
		set PPrefTmp(SMTPEMailFromAddress) $PPref(SMTPEMailFromAddress)
		set PPrefTmp(SMTPEMailTLS) $PPref(SMTPEMailTLS)
		set PPrefTmp(GlobalEMailMessage) $PPref(GlobalEMailMessage)
		set PPref(color,window,fore) $PPrefTmp(color,window,fore)
		set PPref(color,window,back) $PPrefTmp(color,window,back)
		set PPref(color,widget,fore) $PPrefTmp(color,widget,fore)
		set PPref(color,widget,back) $PPrefTmp(color,widget,back)
		set PPref(color,active,fore) $PPrefTmp(color,active,fore)
		set PPref(color,active,back) $PPrefTmp(color,active,back)
		set PPref(color,directory) $PPrefTmp(color,directory)
		set PPref(color,file) $PPrefTmp(color,file)
		set PPref(color,selection,fore) $PPrefTmp(color,selection,fore)
		set PPref(color,selection,back) $PPrefTmp(color,selection,back)
		set PPref(color,ToolTipForeground) $PPrefTmp(color,ToolTipForeground)
		set PPref(color,ToolTipBackground) $PPrefTmp(color,ToolTipBackground)
		set PPref(Foundry,label) $PPrefTmp(Foundry,label)
		set PPref(fonts,label) $PPrefTmp(fonts,label)
		set PPref(Foundry,text) $PPrefTmp(Foundry,text)
		set PPref(fonts,text) $PPrefTmp(fonts,text)
		set PPref(Foundry,ToolTip) $PPrefTmp(Foundry,ToolTip)
		set PPref(fonts,ToolTip) $PPrefTmp(fonts,ToolTip)
		set PPref(DisplayDateFormat) $PPrefTmp(DisplayDateFormat) 
		set PPref(DateSeparater) $PPrefTmp(DateSeparater)
		set PPref(DisplayTimeFormat) $PPrefTmp(DisplayTimeFormat)
		set PPref(TimeSeparater) $PPrefTmp(TimeSeparater)
		set PPref(DisplayDayOfWeek) $PPrefTmp(DisplayDayOfWeek)
		set PPref(SelectAllText) $PPrefTmp(SelectAllText)
		set PPref(ConfirmFileSaves) $PPrefTmp(ConfirmFileSaves)
		set PPref(ConfirmFileDeletions) $PPrefTmp(ConfirmFileDeletions)
		set PPref(PDFReaderPath) $PPrefTmp(PDFReaderPath)
		set PPref(ShowToolTips) $PPrefTmp(ShowToolTips)
		set PPrefRestore(color,window,fore) $PPrefTmp(color,window,fore)
		set PPrefRestore(color,window,back) $PPrefTmp(color,window,back)
		set PPrefRestore(color,widget,fore) $PPrefTmp(color,widget,fore)
		set PPrefRestore(color,widget,back) $PPrefTmp(color,widget,back)
		set PPrefRestore(color,active,fore) $PPrefTmp(color,active,fore)
		set PPrefRestore(color,active,back) $PPrefTmp(color,active,back)
		set PPrefRestore(color,directory) $PPrefTmp(color,directory)
		set PPrefRestore(color,file) $PPrefTmp(color,file)
		set PPrefRestore(color,selection,fore) $PPrefTmp(color,selection,fore)
		set PPrefRestore(color,selection,back) $PPrefTmp(color,selection,back)
		set PPrefRestore(color,ToolTipForeground) $PPrefTmp(color,ToolTipForeground)
		set PPrefRestore(color,ToolTipBackground) $PPrefTmp(color,ToolTipBackground)
		set PPrefRestore(Foundry,label) $PPrefTmp(Foundry,label)
		set PPrefRestore(fonts,label) $PPrefTmp(fonts,label)
		set PPrefRestore(Foundry,text) $PPrefTmp(Foundry,text)
		set PPrefRestore(fonts,text) $PPrefTmp(fonts,text)
		set PPrefRestore(Foundry,ToolTip) $PPrefTmp(Foundry,ToolTip)
		set PPrefRestore(fonts,ToolTip) $PPrefTmp(fonts,ToolTip)
		set PPrefRestore(DisplayDateFormat) $PPrefTmp(DisplayDateFormat)
		set PPrefRestore(DateSeparater) $PPrefTmp(DateSeparater)
		set PPrefRestore(DisplayTimeFormat) $PPrefTmp(DisplayTimeFormat)
		set PPrefRestore(TimeSeparater) $PPrefTmp(TimeSeparater)
		set PPrefRestore(DisplayDayOfWeek) $PPrefTmp(DisplayDayOfWeek)
		set PPrefRestore(SelectAllText) $PPrefTmp(SelectAllText)
		set PPrefRestore(ConfirmFileSaves) $PPrefTmp(ConfirmFileSaves)
		set PPrefRestore(ConfirmFileDeletions) $PPrefTmp(ConfirmFileDeletions)
		set PPrefRestore(PDFReaderPath) $PPrefTmp(PDFReaderPath)
		set PPrefRestore(ShowToolTips) $PPrefTmp(ShowToolTips)
		set PPrefRestore(TheCompanyName) $PPrefTmp(TheCompanyName)
		set PPrefRestore(AppleDelay) $PPrefTmp(AppleDelay)
		set PPrefRestore(FFMxProgram) $PPrefTmp(FFMxProgram)
		set PPrefRestore(RunFrom) $PPrefTmp(RunFrom)
		set PPrefRestore(FTPTransferType) $PPrefTmp(FTPTransferType)
		set PPrefRestore(FTPDeleteAfter) $PPrefTmp(FTPDeleteAfter)
		set PPrefRestore(EnableFactory) $PPrefTmp(EnableFactory)
		set PPrefRestore(DeleteSource) $PPrefTmp(DeleteSource)
		set PPrefRestore(DeleteLogs) $PPrefTmp(DeleteLogs)
		set PPrefRestore(FreeFactoryAction) $PPrefTmp(FreeFactoryAction)
		set PPrefRestore(SMTPEMailServer) $PPrefTmp(SMTPEMailServer)
		set PPrefRestore(SMTPEMailPort) $PPrefTmp(SMTPEMailPort)
		set PPrefRestore(SMTPEMailUserName) $PPrefTmp(SMTPEMailUserName)
		set PPrefRestore(SMTPEMailPassword) $PPrefTmp(SMTPEMailPassword)
		set PPrefRestore(SMTPEMailFromName) $PPrefTmp(SMTPEMailFromName)
		set PPrefRestore(SMTPEMailFromAddress) $PPrefTmp(SMTPEMailFromAddress)
		set PPrefRestore(SMTPEMailTLS) $PPrefTmp(SMTPEMailTLS)
		set PPrefRestore(GlobalEMailMessage) $PPrefTmp(GlobalEMailMessage)
		widgetUpdate
		CheckForSettingsApplyEnable

		if {[winfo exists .fileDialog]} {redoFileDialogListBox}
	} -text "Apply"
	vTcl:DefineAlias "$site_8_5.settingsApplyButton" "ButtonApplySettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5.settingsApplyButton -in $site_8_5 -anchor center -expand 1 -fill none -side left
	balloon $site_8_5.settingsApplyButton "Apply changes but don't close"
 
	button $site_8_5.settingsRestoreButton \
	-command {
		set PPrefTmp(color,window,fore) $PPrefRestore(color,window,fore)
		set PPrefTmp(color,window,back) $PPrefRestore(color,window,back)
		set PPrefTmp(color,widget,fore) $PPrefRestore(color,widget,fore)
		set PPrefTmp(color,widget,back) $PPrefRestore(color,widget,back)
		set PPrefTmp(color,active,fore) $PPrefRestore(color,active,fore)
		set PPrefTmp(color,active,back) $PPrefRestore(color,active,back)
		set PPrefTmp(color,directory) $PPrefRestore(color,directory)
		set PPrefTmp(color,file) $PPrefRestore(color,file)
		set PPrefTmp(color,selection,fore) $PPrefRestore(color,selection,fore)
		set PPrefTmp(color,selection,back) $PPrefRestore(color,selection,back)
		set PPrefTmp(color,ToolTipForeground) $PPrefRestore(color,ToolTipForeground)
		set PPrefTmp(color,ToolTipBackground) $PPrefRestore(color,ToolTipBackground)
		set PPref(color,ToolTipForeground) $PPrefRestore(color,ToolTipForeground)
		set PPref(color,ToolTipBackground) $PPrefRestore(color,ToolTipBackground)
		set PPrefTmp(Foundry,label) $PPrefRestore(Foundry,label)
		set PPrefTmp(fonts,label) $PPrefRestore(fonts,label)
		set PPrefTmp(Foundry,text) $PPrefRestore(Foundry,text)
		set PPrefTmp(fonts,text) $PPrefRestore(fonts,text)
		set PPrefTmp(Foundry,ToolTip) $PPrefRestore(Foundry,ToolTip)
		set PPrefTmp(fonts,ToolTip) $PPrefRestore(fonts,ToolTip)
		set PPrefTmp(DisplayDateFormat) $PPrefRestore(DisplayDateFormat)
		set PPrefTmp(DateSeparater) $PPrefRestore(DateSeparater)
		set PPrefTmp(DisplayTimeFormat) $PPrefRestore(DisplayTimeFormat)
		set PPrefTmp(TimeSeparater) $PPrefRestore(TimeSeparater)
		set PPrefTmp(DisplayDayOfWeek) $PPrefRestore(DisplayDayOfWeek)
		set PPrefTmp(SelectAllText) $PPrefRestore(SelectAllText)
		set PPrefTmp(ConfirmFileSaves) $PPrefRestore(ConfirmFileSaves)
		set PPrefTmp(ConfirmFileDeletions) $PPrefRestore(ConfirmFileDeletions)
		set PPrefTmp(PDFReaderPath) $PPrefRestore(PDFReaderPath)
		set PPrefTmp(ShowToolTips) $PPrefRestore(ShowToolTips)
		set PPrefRestore(TheCompanyName) $PPrefTmp(TheCompanyName)
		set PPrefRestore(AppleDelay) $PPrefTmp(AppleDelay)
		set PPrefRestore(FFMxProgram) $PPrefTmp(FFMxProgram)
		set PPrefRestore(RunFrom) $PPrefTmp(RunFrom)
		set PPrefRestore(FTPTransferType) $PPrefTmp(FTPTransferType)
		set PPrefRestore(FTPDeleteAfter) $PPrefTmp(FTPDeleteAfter)
		set PPrefRestore(EnableFactory) $PPrefTmp(EnableFactory)
		set PPrefRestore(DeleteSource) $PPrefTmp(DeleteSource)
		set PPrefRestore(DeleteLogs) $PPrefTmp(DeleteLogs)
		set PPrefRestore(FreeFactoryAction) $PPrefTmp(FreeFactoryAction)
		set PPrefRestore(SMTPEMailServer) $PPrefTmp(SMTPEMailServer)
		set PPrefRestore(SMTPEMailPort) $PPrefTmp(SMTPEMailPort)
		set PPrefRestore(SMTPEMailUserName) $PPrefTmp(SMTPEMailUserName)
		set PPrefRestore(SMTPEMailPassword) $PPrefTmp(SMTPEMailPassword)
		set PPrefRestore(SMTPEMailFromName) $PPrefTmp(SMTPEMailFromName)
		set PPrefRestore(SMTPEMailFromAddress) $PPrefTmp(SMTPEMailFromAddress)
		set PPrefRestore(SMTPEMailTLS) $PPrefTmp(SMTPEMailTLS)
		set PPrefRestore(GlobalEMailMessage) $PPrefTmp(GlobalEMailMessage)
		if {$currentColorWidget == "Window Foreground"} {set tmpcolor $PPrefTmp(color,window,fore)}
		if {$currentColorWidget == "Window Background"} {set tmpcolor $PPrefTmp(color,window,back)}
		if {$currentColorWidget == "Active Foreground"} {set tmpcolor $PPrefTmp(color,active,fore)}
		if {$currentColorWidget == "Active Background"} {set tmpcolor $PPrefTmp(color,active,back)}
		if {$currentColorWidget == "Widget Data Foreground"} {set tmpcolor $PPrefTmp(color,widget,fore)}
		if {$currentColorWidget == "Widget Data Background"} {set tmpcolor $PPrefTmp(color,widget,back)}
		if {$currentColorWidget == "Directory Color"} {set tmpcolor $PPrefTmp(color,directory)}
		if {$currentColorWidget == "File Color"} {set tmpcolor $PPrefTmp(color,file)}
		if {$currentColorWidget == "Selection Foreground Color"} {set tmpcolor $PPrefTmp(color,selection,fore)}
		if {$currentColorWidget == "Selection Background Color"} {set tmpcolor $PPrefTmp(color,selection,back)}
		if {$currentColorWidget == "Tool Tip Foreground"} {set tmpcolor $PPrefTmp(color,ToolTipForeground)}
		if {$currentColorWidget == "Tool Tip Background"} {set tmpcolor $PPrefTmp(color,ToolTipBackground)}
		parseColor
		modifyColor
		widgetUpdate
		if {[winfo exists .fileDialog]} {redoFileDialogListBox}
# Run sub routine to display the icon button frames if selected
	} -text "Restore"
	vTcl:DefineAlias "$site_8_5.settingsRestoreButton" "ButtonRestoreSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5.settingsRestoreButton -in $site_8_5 -anchor center -expand 1 -fill none -side left
	balloon .settings.footerFrame.settingsRestoreButton "Restore Prior To Editing"

	button $site_8_5.settingsResetButton \
	-command {
######
# Reset to default  colors
		set PPrefTmp(color,window,fore) "#000000"
		set PPrefTmp(color,window,back) "#ececec"
		set PPrefTmp(color,widget,fore) "#000000"
		set PPrefTmp(color,widget,back) "#fefefe"
		set PPrefTmp(color,active,fore) "#000000"
		set PPrefTmp(color,active,back) "#fefefe"
		set PPrefTmp(color,directory) "#0000ff"
		set PPrefTmp(color,file) "#000000"
		set PPrefTmp(color,selection,fore) "#000000"
		set PPrefTmp(color,selection,back) "#c4c4c4"
		set PPrefTmp(color,ToolTipForeground) "#000000"
		set PPrefTmp(color,ToolTipBackground) "#ffffaa"
		set PPrefTmp(color,ToolTipForeground) "#000000"
		set PPrefTmp(color,ToolTipBackground) "#ffffaa"
		set PPref(color,ToolTipForeground) "#000000"
		set PPref(color,ToolTipBackground) "#ffffaa"
		set PPrefTmp(Foundry,label) "adobe"
		set PPrefTmp(fonts,label) "-family utopia -size 12 -weight bold -slant roman"
		set PPrefTmp(Foundry,text) "adobe"
		set PPrefTmp(fonts,text)  "-family utopia -size 12 -weight bold -slant roman"
		set PPrefTmp(Foundry,ToolTip) "adobe"
		set PPrefTmp(fonts,ToolTip)  "-family utopia -size 12 -weight bold -slant roman"
		set PPref(Foundry,ToolTip) "adobe"
		set PPref(fonts,ToolTip)  "-family utopia -size 12 -weight bold -slant roman"
		if {$currentColorWidget == "Window Foreground"} {set tmpcolor $PPrefTmp(color,window,fore)}
		if {$currentColorWidget == "Window Background"} {set tmpcolor $PPrefTmp(color,window,back)}
		if {$currentColorWidget == "Active Foreground"} {set tmpcolor $PPrefTmp(color,active,fore)}
		if {$currentColorWidget == "Active Background"} {set tmpcolor $PPrefTmp(color,active,back)}
		if {$currentColorWidget == "Widget Data Foreground"} {set tmpcolor $PPrefTmp(color,widget,fore)}
		if {$currentColorWidget == "Widget Data Background"} {set tmpcolor $PPrefTmp(color,widget,back)}
		if {$currentColorWidget == "Directory Color"} {set tmpcolor $PPrefTmp(color,directory)}
		if {$currentColorWidget == "File Color"} {set tmpcolor $PPrefTmp(color,file)}
		if {$currentColorWidget == "Selection Foreground Color"} {set tmpcolor $PPrefTmp(color,selection,fore)}
		if {$currentColorWidget == "Selection Background Color"} {set tmpcolor $PPrefTmp(color,selection,back)}
		if {$currentColorWidget == "Tool Tip Foreground"} {set tmpcolor $PPrefTmp(color,ToolTipForeground)}
		if {$currentColorWidget == "Tool Tip Background"} {set tmpcolor $PPrefTmp(color,ToolTipBackground)}
		initSettings
		parseColor
		modifyColor
		widgetUpdate
		if {[winfo exists .fileDialog]} {redoFileDialogListBox}
# Run sub routine to display the icon button frames if selected
	} -text "Reset"
	vTcl:DefineAlias "$site_8_5.settingsResetButton" "ButtonResetSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5.settingsResetButton -in $site_8_5 -anchor center -expand 1 -fill none -side left
	balloon .settings.footerFrame.settingsResetButton "Reset Colors And Fonts To Defaults"

	button $site_8_5.settingsCancelButton \
	-command {
		set SettingsCancelConfirm "Cancel"
		set PPrefTmp(color,window,fore) $PPrefRestore(color,window,fore)
		set PPrefTmp(color,window,back) $PPrefRestore(color,window,back)
		set PPrefTmp(color,widget,fore) $PPrefRestore(color,widget,fore)
		set PPrefTmp(color,widget,back) $PPrefRestore(color,widget,back)
		set PPrefTmp(color,active,fore) $PPrefRestore(color,active,fore)
		set PPrefTmp(color,active,back) $PPrefRestore(color,active,back)
		set PPrefTmp(color,directory) $PPrefRestore(color,directory)
		set PPrefTmp(color,file) $PPrefRestore(color,file)
		set PPrefTmp(color,selection,fore) $PPrefRestore(color,selection,fore)
		set PPrefTmp(color,selection,back) $PPrefRestore(color,selection,back)
		set PPrefTmp(color,ToolTipForeground) $PPrefRestore(color,ToolTipForeground)
		set PPrefTmp(color,ToolTipBackground) $PPrefRestore(color,ToolTipBackground)
		set PPref(color,ToolTipForeground) $PPrefRestore(color,ToolTipForeground)
		set PPref(color,ToolTipBackground) $PPrefRestore(color,ToolTipBackground)
		set PPrefTmp(Foundry,label) $PPrefRestore(Foundry,label)
		set PPrefTmp(fonts,label) $PPrefRestore(fonts,label)
		set PPrefTmp(Foundry,text) $PPrefRestore(Foundry,text)
		set PPrefTmp(fonts,text) $PPrefRestore(fonts,text)
		set PPref(Foundry,ToolTip) $PPrefRestore(Foundry,ToolTip)
		set PPref(fonts,ToolTip) $PPrefRestore(fonts,ToolTip)
		set PPrefTmp(Foundry,ToolTip) $PPrefRestore(Foundry,ToolTip)
		set PPrefTmp(fonts,ToolTip) $PPrefRestore(fonts,ToolTip)
		set PPrefTmp(DisplayDateFormat) $PPrefRestore(DisplayDateFormat)
		set PPrefTmp(DateSeparater) $PPrefRestore(DateSeparater)
		set PPrefTmp(DisplayTimeFormat) $PPrefRestore(DisplayTimeFormat)
		set PPrefTmp(TimeSeparater) $PPrefRestore(TimeSeparater)
		set PPrefTmp(DisplayDayOfWeek) $PPrefRestore(DisplayDayOfWeek)
		set PPrefTmp(SelectAllText) $PPrefRestore(SelectAllText)
		set PPrefTmp(ConfirmFileSaves) $PPrefRestore(ConfirmFileSaves)
		set PPrefTmp(ConfirmFileDeletions) $PPrefRestore(ConfirmFileDeletions)
		set PPrefTmp(PDFReaderPath) $PPrefRestore(PDFReaderPath)
		set PPrefTmp(ShowToolTips) $PPrefRestore(ShowToolTips)
		set DateFormatVar $PPrefRestore(DisplayDateFormat)
		set ShortLongSeparater $PPrefRestore(DateSeparater)
		set TimeFormatVar $PPrefRestore(DisplayTimeFormat)
		set TimeSeparater $PPrefRestore(TimeSeparater)
		set DisplayDayOfWeek $PPrefRestore(DisplayDayOfWeek)
		set SelectAllText $PPrefRestore(SelectAllText) 
		set ConfirmFileSaves $PPrefRestore(ConfirmFileSaves)
		set ConfirmFileDeletions $PPrefRestore(ConfirmFileDeletions)
		set PDFReaderPath $PPrefRestore(PDFReaderPath)
		set ShowToolTips $PPrefRestore(ShowToolTips)
		set PPrefTmp(TheCompanyName) $PPrefRestore(TheCompanyName)
		set PPrefTmp(AppleDelay) $PPrefRestore(AppleDelay)
		set PPrefTmp(FFMxProgram) $PPrefRestore(FFMxProgram)
		set PPrefTmp(RunFrom) $PPrefRestore(RunFrom)
		set PPrefTmp(FTPTransferType) $PPrefRestore(FTPTransferType)
		set PPrefTmp(FTPDeleteAfter) $PPrefRestore(FTPDeleteAfter)
		set PPrefTmp(EnableFactory) $PPrefRestore(EnableFactory)
		set PPrefTmp(DeleteSource) $PPrefRestore(DeleteSource)
		set PPrefTmp(DeleteLogs) $PPrefRestore(DeleteLogs)
		set PPrefTmp(FreeFactoryAction) $PPrefRestore(FreeFactoryAction)
		set PPrefTmp(SMTPEMailServer) $PPrefRestore(SMTPEMailServer)
		set PPrefTmp(SMTPEMailPort) $PPrefRestore(SMTPEMailPort)
		set PPrefTmp(SMTPEMailUserName) $PPrefRestore(SMTPEMailUserName)
		set PPrefTmp(SMTPEMailPassword) $PPrefRestore(SMTPEMailPassword)
		set PPrefTmp(SMTPEMailFromName) $PPrefRestore(SMTPEMailFromName)
		set PPrefTmp(SMTPEMailFromAddress) $PPrefRestore(SMTPEMailFromAddress)
		set PPrefTmp(SMTPEMailTLS) $PPrefRestore(SMTPEMailTLS)
		set PPrefTmp(GlobalEMailMessage) $PPrefRestore(GlobalEMailMessage)
		widgetUpdate
# Run sub routine to display the icon button frames if selected
		destroy window .settings
	} -text "Cancel"
	vTcl:DefineAlias "$site_8_5.settingsCancelButton" "ButtonCancelSettings" vTcl:WidgetProc "Toplevel1" 1
	pack $site_8_5.settingsCancelButton -in $site_8_5 -anchor center -expand 1 -fill none -side left
	balloon .settings.footerFrame.settingsCancelButton "Cancel And Close"

	pack $top.footerFrame -in $top -anchor sw -expand 1 -fill x -side bottom

	pack $top.settingsTabNotebook -in $top -anchor nw -expand 1 -fill both -side top

    vTcl:FireEvent $base <<Ready>>
}

#
#  End of Main Setting GUI
#
#############################################################################
#############################################################################

proc ::getSystemTimeSettings {} {
	global PPrefTmp SystemTimeSettings

	set SystemTimeSettings ""
# Full Week Day Name
	if {$PPrefTmp(DisplayDayOfWeek) == "Yes" } {append SystemTimeSettings [clock format [clock seconds] -format %A] " "}
	if {$PPrefTmp(DisplayDateFormat) == "Shortmmddyy" } {
# Short Date
		append SystemTimeSettings [clock format [clock seconds] -format %m]
		append SystemTimeSettings $PPrefTmp(DateSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %d]
		append SystemTimeSettings $PPrefTmp(DateSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %y]  "  "
	 }
	if {$PPrefTmp(DisplayDateFormat) == "Shortyymmdd" } {
	
		append SystemTimeSettings [clock format [clock seconds] -format %y]
		append SystemTimeSettings $PPrefTmp(DateSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %m]
		append SystemTimeSettings $PPrefTmp(DateSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %d]  "  "
	 }
	 if {$PPrefTmp(DisplayDateFormat) == "Longmmddyy" } {
# Long Date
		append SystemTimeSettings [clock format [clock seconds] -format %m]
		append SystemTimeSettings $PPrefTmp(DateSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %d]
		append SystemTimeSettings $PPrefTmp(DateSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %Y] "  "
	}
	if {$PPrefTmp(DisplayDateFormat) == "Longyymmdd" } {
		append SystemTimeSettings [clock format [clock seconds] -format %Y]
		append SystemTimeSettings $PPrefTmp(DateSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %m]
		append SystemTimeSettings $PPrefTmp(DateSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %d] "  "
	}
	if {$PPrefTmp(DisplayDateFormat) == "FullShort" } {
		append SystemTimeSettings [clock format [clock seconds] -format %B] " "
# Day of month
		append SystemTimeSettings [clock format [clock seconds] -format %d] ", "
# 2 digit year
		append SystemTimeSettings [clock format [clock seconds] -format %y]
	}

	if {$PPrefTmp(DisplayDateFormat) == "FullLong" } {
# Full Month Name
		append SystemTimeSettings [clock format [clock seconds] -format %B] " "
# Day of month
		append SystemTimeSettings [clock format [clock seconds] -format %d] ", "
# 4 digit year
		append SystemTimeSettings [clock format [clock seconds] -format %Y] "   "
 
	}
	if {$PPrefTmp(DisplayDateFormat) == "FullAbrevShort" } {
# Full Month Name
		append SystemTimeSettings [clock format [clock seconds] -format %b] " "
# Day of month
		append SystemTimeSettings [clock format [clock seconds] -format %d] ", "
# 2 digit year
		append SystemTimeSettings [clock format [clock seconds] -format %y] "   "
	}
	 if {$PPrefTmp(DisplayDateFormat) == "FullAbrevLong" } {
# Full Month Name
		append SystemTimeSettings [clock format [clock seconds] -format %b] " "
# Day of month
		append SystemTimeSettings [clock format [clock seconds] -format %d] ", "
# 4 digit year
		append SystemTimeSettings [clock format [clock seconds] -format %Y] "   "
	}
	append SystemTimeSettings "  "
	if {$PPrefTmp(DisplayTimeFormat) == "hhmmss12Hour" } {
		append SystemTimeSettings [clock format [clock seconds] -format %I] 
		append SystemTimeSettings $PPrefTmp(TimeSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %M] 
		append SystemTimeSettings $PPrefTmp(TimeSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %S] " " 
		append SystemTimeSettings [clock format [clock seconds] -format %p]
	}
	if {$PPrefTmp(DisplayTimeFormat) == "hhmmss24Hour" } {
		append SystemTimeSettings [clock format [clock seconds] -format %H] 
		append SystemTimeSettings $PPrefTmp(TimeSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %M] 
		append SystemTimeSettings $PPrefTmp(TimeSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %S] 
	}
	if {$PPrefTmp(DisplayTimeFormat) == "hhmm12Hour" } {
		append SystemTimeSettings [clock format [clock seconds] -format %I] 
		append SystemTimeSettings $PPrefTmp(TimeSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %M] " " 
		append SystemTimeSettings [clock format [clock seconds] -format %p]  
	}
	if {$PPrefTmp(DisplayTimeFormat) == "hhmm24Hour" } {
		append SystemTimeSettings [clock format [clock seconds] -format %H] 
		append SystemTimeSettings $PPrefTmp(TimeSeparater)
		append SystemTimeSettings [clock format [clock seconds] -format %M] 
	}
       after 1000 getSystemTimeSettings
}
## End Procedure:  getSystemTimeSettings
#############################################################################
#############################################################################

#############################################################################
#############################################################################
## Procedure:  initSettings

proc ::initSettings {} {
	global PPref PPrefTmp PPrefRestore
	global tmpFoundry tmpFamily tmpWeight tmpSlant tmpPointSize readline
	global anchorFoundry anchorFamily anchorWeight anchorSlant anchorSetWidth anchorPointSize
	global fontString setwidthEnd currentColorWidget
	global SysFont TotalElements SysFontFoundry TotalElementsFoundry SysFontFamily TotalElementsFamily SysFontWeight TotalElementsWeight
 	global TotalFoundry TotalFamily
	
	set currentColorWidget [DisplayParametersComboBoxSettings getcurselection]
	if {$currentColorWidget == "Window Foreground"} {set tmpcolor $PPrefTmp(color,window,fore)}
	if {$currentColorWidget == "Window Background"} {set tmpcolor $PPrefTmp(color,window,back)}
	if {$currentColorWidget == "Active Foreground"} {set tmpcolor $PPrefTmp(color,active,fore)}
	if {$currentColorWidget == "Active Background"} {set tmpcolor $PPrefTmp(color,active,back)}
	if {$currentColorWidget == "Widget Data Foreground"} {set tmpcolor $PPrefTmp(color,widget,fore)}
	if {$currentColorWidget == "Widget Data Background"} {set tmpcolor $PPrefTmp(color,widget,back)}
	if {$currentColorWidget == "Directory Color"} {set tmpcolor $PPrefTmp(color,directory)}
	if {$currentColorWidget == "File Color"} {set tmpcolor $PPrefTmp(color,file)}
	if {$currentColorWidget == "Selection Foreground Color"} {set tmpcolor $PPrefTmp(color,selection,fore)}
	if {$currentColorWidget == "Selection Background Color"} {set tmpcolor $PPrefTmp(color,selection,back)}
	if {$currentColorWidget == "Tool Tip Foreground"} {set tmpcolor $PPrefTmp(color,ToolTipForeground)}
	if {$currentColorWidget == "Tool Tip Background"} {set tmpcolor $PPrefTmp(color,ToolTipBackground)}

#########################################################################
#########################################################################
# Start Font Settings
	set v 0
	set w 0
	set x 0
	set y 0
	set z 0
	set tmpWeight "normal"
	set tmpSlant "roman"
	set fontPath {}
	lappend fontPath {/usr/X11R6/lib/X11/fonts/Type1/fonts.dir}
	lappend fontPath {/usr/X11R6/lib/X11/fonts/Speedo/fonts.dir}
	lappend fontPath {/usr/share/fonts/default/TrueType/fonts.dir}
	lappend fontPath {/usr/share/fonts/default/Type1/fonts.dir}
	lappend fontPath {/usr/share/X11/fonts/75dpi/fonts.dir}
	lappend fontPath {/usr/share/X11/fonts/100dpi/fonts.dir}
	lappend fontPath {/usr/share/X11/fonts/Type1/fonts.dir}
	lappend fontPath {/usr/share/X11/fonts/TTF/fonts.dir}
	set TotalFoundry 0
	foreach fontDirFile $fontPath {
		if {[file exist $fontDirFile]} {
			set FileHandleFont [open $fontDirFile r]
			while {![eof $FileHandleFont]} {
				gets $FileHandleFont readline
				if {[string first "-" $readline] >-1} {
					parseFontFileLine
					set FoundryDup "No"
					for {set v 0} {$v < $TotalFoundry} {incr v} {
						if {[string toupper $SysFontFoundry($v)] == [string toupper $tmpFoundry]} {
							set FoundryDup "Yes"
							break
						}
					}

					if {$FoundryDup=="No"} {
						set SysFontFoundry($v) $tmpFoundry									
						set TotalFamily($v) 0
						incr TotalFoundry	

					}
					set FamilyDup "No"
					for {set w 0} {$w < $TotalFamily($v)} {incr w} {
						if {[string toupper $SysFontFamily($v,$w)] == [string toupper $tmpFamily]} {
							set FamilyDup "Yes"
							break
						}
					}
					if {$FamilyDup=="No"} {
						set SysFontFamily($v,$w) $tmpFamily
						incr TotalFamily($v) 						
					}
				}
			}
			close $FileHandleFont
		}
	}
################################################################
	ScrolledListBoxFontFoundrySettings clear
	ScrolledListBoxFontFamilySettings clear
	ScrolledListBoxFontWeightSettings clear
	ScrolledListBoxFontSlantSettings clear
	ScrolledListBoxPointSizeSettings clear
	ScrolledListBoxFontWeightSettings insert end "normal"
	ScrolledListBoxFontWeightSettings insert end "bold"
	ScrolledListBoxFontSlantSettings insert end "roman"
	ScrolledListBoxFontSlantSettings insert end "italic"

	for {set v 0 } { $v < $TotalFoundry} {incr v} {
		ScrolledListBoxFontFoundrySettings insert end $SysFontFoundry($v)
	}
	for {set pointSize 4 } { $pointSize < 97} {incr pointSize} {ScrolledListBoxPointSizeSettings insert end $pointSize}

	set readline $PPrefTmp(fonts,label)
	set tmpFoundry $PPrefTmp(Foundry,label)
	parseFontSettingsLine

	for {set v 0 } { $v < $TotalFoundry} {incr v} {
		if {$tmpFoundry==$SysFontFoundry($v)} {break}
	}
	set anchorFoundry $v
	ScrolledListBoxFontFoundrySettings itemconfigure $anchorFoundry -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
	for {set w 0 } { $w < $TotalFamily($anchorFoundry)} {incr w} {
		ScrolledListBoxFontFamilySettings insert end $SysFontFamily($anchorFoundry,$w)
		if {$tmpFamily==$SysFontFamily($anchorFoundry,$w)} {set anchorFamily $w}
	}

	ScrolledListBoxFontFamilySettings itemconfigure $anchorFamily -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
	if {$tmpWeight=="normal"} {
		set anchorWeight 0
	} else {
		set anchorWeight 1
	}
	ScrolledListBoxFontWeightSettings itemconfigure $anchorWeight -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)

	if {$tmpSlant=="roman"} {
		set anchorSlant 0
	} else {
		set anchorSlant 1
	}
	ScrolledListBoxFontSlantSettings itemconfigure $anchorSlant -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)
	set newPointSizeOffset 0
	for {set pointSize 4 } { $pointSize < 97} {incr pointSize} {

		if {$tmpPointSize == $pointSize} {break}
		incr newPointSizeOffset
	}
	set anchorPointSize $newPointSizeOffset
	ScrolledListBoxPointSizeSettings itemconfigure $anchorPointSize  -foreground $PPref(color,selection,fore) -background $PPref(color,selection,back)

## End Settings Font
#############################################################################
# Start Initialize Free Factory variables
	set SelectedDirectoryPath ""
	set NotifyRuntimeUser ""
# Fill user name combo box.
	set FileHandle [open "/etc/passwd" r]
	ComboBoxNotifyRuntimeUserSettings delete list 0 end
	ComboBoxNotifyRuntimeUserSettings insert list end ""
	while {![eof $FileHandle]} {
		gets $FileHandle userName
		set userName [string range $userName 0 [expr [string first ":" $userName] -1]]
		ComboBoxNotifyRuntimeUserSettings insert list end $userName
	}
	close $FileHandle
# Select User as the default process filter.
	RadioButtonUserProcessSettings select
# Get Directory list and fill scroll box
	GetNotifyDirectoryList
# Get Free Factory inotifywait processes and fill scroll box
	GetNumberOfFFProcesses
# End Initialize Free Factory variables
#############################################################################
#############################################################################
	ButtonUpdateDirectory configure -state disable
	ButtonSaveDirectory configure -state disable

	getSystemTimeSettings

}
# End initSettings
#############################################################################
#############################################################################
## Procedure:  initEditSettings

proc ::initEditSettings {} {
##########################
# Company Variables
	global TheCompanyName

	global PPref PPrefTmp PPrefRestore tmpcolor RedSliderValue GreenSliderValue BlueSliderValue
	global currentColorWidget fontString
	global tmpFoundry tmpFamily tmpWeight tmpSlant tmpSetWidth readline SysFont
	global DateFormatVar TimeFormatVar ShortLongSeparater TimeSeparater DisplayDayOfWeek
	global SelectAllText ConfirmFileSaves ConfirmFileDeletions ShowIconBar1 ShowIconBar2 ShowIconBar3 ShowIconBar4 ShowToolTips PDFReaderPath

##########################
# Free Factory Variables
	global AppleDelay NumberOfFFProcesses FFProcessList SelectedDirectoryPath NotifyDirectoryList NumberOfDirectories NotifyRuntimeUser ScrollBoxItemPos ShowProcess

	set PPrefTmp(color,window,fore) $PPref(color,window,fore)
	set PPrefTmp(color,window,back) $PPref(color,window,back)
	set PPrefTmp(color,widget,fore) $PPref(color,widget,fore)
	set PPrefTmp(color,widget,back) $PPref(color,widget,back)
	set PPrefTmp(color,active,fore) $PPref(color,active,fore)
	set PPrefTmp(color,active,back) $PPref(color,active,back)
	set PPrefTmp(color,widget,fore) $PPref(color,widget,fore)
	set PPrefTmp(color,widget,back) $PPref(color,widget,back)
	set PPrefTmp(color,directory) $PPref(color,directory)
	set PPrefTmp(color,file) $PPref(color,file)
	set PPrefTmp(color,selection,fore) $PPref(color,selection,fore)
	set PPrefTmp(color,selection,back) $PPref(color,selection,back)
	set PPrefTmp(color,ToolTipForeground) $PPref(color,ToolTipForeground)
	set PPrefTmp(color,ToolTipBackground) $PPref(color,ToolTipBackground)
	set PPrefTmp(Foundry,label) $PPref(Foundry,label)
	set PPrefTmp(fonts,label) $PPref(fonts,label)
	set PPrefTmp(Foundry,text) $PPref(Foundry,text)
	set PPrefTmp(fonts,text) $PPref(fonts,text)
	set PPrefTmp(Foundry,ToolTip) $PPref(Foundry,ToolTip)
	set PPrefTmp(fonts,ToolTip) $PPref(fonts,ToolTip)
	set PPrefTmp(DisplayDateFormat) $PPref(DisplayDateFormat)
	set PPrefTmp(DateSeparater) $PPref(DateSeparater)
	set PPrefTmp(DisplayTimeFormat) $PPref(DisplayTimeFormat)
	set PPrefTmp(TimeSeparater) $PPref(TimeSeparater)
	set PPrefTmp(DisplayDayOfWeek) $PPref(DisplayDayOfWeek)
	set PPrefTmp(SelectAllText) $PPref(SelectAllText)
	set PPrefTmp(ConfirmFileSaves) $PPref(ConfirmFileSaves)
	set PPrefTmp(ConfirmFileDeletions) $PPref(ConfirmFileDeletions)
	set PPrefTmp(PDFReaderPath) $PPref(PDFReaderPath)
	set PPrefTmp(ShowToolTips) $PPref(ShowToolTips)
	set PPrefTmp(TheCompanyName) $PPref(TheCompanyName)
	set PPrefTmp(AppleDelay) $PPref(AppleDelay)
	set PPrefTmp(FFMxProgram) $PPref(FFMxProgram)
	set PPrefTmp(RunFrom) $PPref(RunFrom)
	set PPrefTmp(EnableEMail) $PPref(EnableEMail)
	set PPrefTmp(EnableFactoryLinking) $PPref(EnableFactoryLinking)
	set PPrefTmp(FTPTransferType) $PPref(FTPTransferType)
	set PPrefTmp(FTPDeleteAfter) $PPref(FTPDeleteAfter)
	set PPrefTmp(EnableFactory) $PPref(EnableFactory)
	set PPrefTmp(DeleteSource) $PPref(DeleteSource)
	set PPrefTmp(DeleteLogs) $PPref(DeleteLogs)
	set PPrefTmp(FreeFactoryAction) $PPref(FreeFactoryAction)
	set PPrefTmp(SMTPEMailServer) $PPref(SMTPEMailServer)
	set PPrefTmp(SMTPEMailPort) $PPref(SMTPEMailPort)
	set PPrefTmp(SMTPEMailUserName) $PPref(SMTPEMailUserName)
	set PPrefTmp(SMTPEMailPassword) $PPref(SMTPEMailPassword)
	set PPrefTmp(SMTPEMailFromName) $PPref(SMTPEMailFromName)
	set PPrefTmp(SMTPEMailFromAddress) $PPref(SMTPEMailFromAddress)
	set PPrefTmp(SMTPEMailTLS) $PPref(SMTPEMailTLS)
	set PPrefTmp(GlobalEMailMessage) $PPref(GlobalEMailMessage)
	set PPrefRestore(color,window,fore) $PPref(color,window,fore)
	set PPrefRestore(color,window,back) $PPref(color,window,back)
	set PPrefRestore(color,active,fore) $PPref(color,active,fore)
	set PPrefRestore(color,active,back) $PPref(color,active,back)
	set PPrefRestore(color,selection,fore) $PPref(color,selection,fore)
	set PPrefRestore(color,selection,back) $PPref(color,selection,back)
	set PPrefRestore(color,ToolTipForeground) $PPref(color,ToolTipForeground)
	set PPrefRestore(color,ToolTipBackground) $PPref(color,ToolTipBackground)
	set PPrefRestore(color,widget,fore) $PPref(color,widget,fore)
	set PPrefRestore(color,widget,back) $PPref(color,widget,back)
	set PPrefRestore(color,directory) $PPref(color,directory)
	set PPrefRestore(color,file) $PPref(color,file)
	set PPrefRestore(color,sidewindow,back) {#999999}
	set PPrefRestore(Foundry,label) $PPref(Foundry,label)
	set PPrefRestore(fonts,label) $PPref(fonts,label)
	set PPrefRestore(Foundry,text) $PPref(Foundry,text)
	set PPrefRestore(fonts,text) $PPref(fonts,text)
	set PPrefRestore(Foundry,ToolTip) $PPref(Foundry,ToolTip)
	set PPrefRestore(fonts,ToolTip) $PPref(fonts,ToolTip)
	set PPrefRestore(DisplayDateFormat) $PPref(DisplayDateFormat)
	set PPrefRestore(DateSeparater) $PPref(DateSeparater)
	set PPrefRestore(DisplayTimeFormat) $PPref(DisplayTimeFormat)
	set PPrefRestore(TimeSeparater) $PPref(TimeSeparater)
	set PPrefRestore(DisplayDayOfWeek) $PPref(DisplayDayOfWeek)
	set PPrefRestore(SelectAllText) $PPref(SelectAllText)
	set PPrefRestore(ConfirmFileSaves) $PPref(ConfirmFileSaves)
	set PPrefRestore(ConfirmFileDeletions) $PPref(ConfirmFileDeletions)
	set PPrefRestore(PDFReaderPath) $PPref(PDFReaderPath)
	set PPrefRestore(ShowToolTips) $PPref(ShowToolTips)
	set PPrefRestore(TheCompanyName) $PPref(TheCompanyName)
	set PPrefRestore(AppleDelay) $PPref(AppleDelay)
	set PPrefRestore(FFMxProgram) $PPref(FFMxProgram)
	set PPrefRestore(RunFrom) $PPref(RunFrom)
	set PPrefRestore(EnableEMail) $PPref(EnableEMail)
	set PPrefRestore(EnableFactoryLinking) $PPref(EnableFactoryLinking)
	set PPrefRestore(FTPTransferType) $PPref(FTPTransferType)
	set PPrefRestore(FTPDeleteAfter) $PPref(FTPDeleteAfter)
	set PPrefRestore(EnableFactory) $PPref(EnableFactory)
	set PPrefRestore(DeleteSource) $PPref(DeleteSource)
	set PPrefRestore(DeleteLogs) $PPref(DeleteLogs)
	set PPrefRestore(FreeFactoryAction) $PPref(FreeFactoryAction)
	set PPrefRestore(SMTPEMailServer) $PPref(SMTPEMailServer)
	set PPrefRestore(SMTPEMailPort) $PPref(SMTPEMailPort)
	set PPrefRestore(SMTPEMailUserName) $PPref(SMTPEMailUserName)
	set PPrefRestore(SMTPEMailPassword) $PPref(SMTPEMailPassword)
	set PPrefRestore(SMTPEMailFromName) $PPref(SMTPEMailFromName)
	set PPrefRestore(SMTPEMailFromAddress) $PPref(SMTPEMailFromAddress)
	set PPrefRestore(SMTPEMailTLS) $PPref(SMTPEMailTLS)
	set PPrefRestore(GlobalEMailMessage) $PPref(GlobalEMailMessage)
	set DateFormatVar $PPref(DisplayDateFormat)
	set ShortLongSeparater $PPref(DateSeparater)
	set TimeFormatVar $PPref(DisplayTimeFormat)
	set TimeSeparater $PPref(TimeSeparater)
	set DisplayDayOfWeek $PPref(DisplayDayOfWeek)
	set SelectAllText $PPref(SelectAllText)
	set ConfirmFileSaves $PPref(ConfirmFileSaves)
	set ConfirmFileDeletions $PPref(ConfirmFileDeletions)
	set PDFReaderPath $PPref(PDFReaderPath)
	set ShowToolTips $PPref(ShowToolTips)
	set fontString  "-family utopia -size 12 -weight bold -slant roman -underline 0 -overstrike 0"
	Window show .settings
	DisplayParametersComboBoxSettings delete entry 0 end
	DisplayParametersComboBoxSettings clear
########################
# Load up the combo box
	DisplayParametersComboBoxSettings insert list end "Window Foreground" "Window Background" "Active Foreground" \
	"Active Background" "Widget Data Foreground" "Widget Data Background" "Directory Color" "File Color" \
	"Selection Foreground Color" "Selection Background Color" "Tool Tip Foreground" "Tool Tip Background"
	
	DisplayParametersComboBoxSettings selection set 0 0
#	DisplayParametersComboBoxSettings insert entry "Window Foreground"

	set currentColorWidget "Window Foreground"
	DisplayParametersComboBoxSettings configure -editable 0
	EntrySampleLabelSettings delete 0 end
	EntrySampleLabelSettings insert 0 "This is an example of inside widget."
	
	.settings.footerFrame.settingsApplyButton configure -state disable

	initSettings
#########################################
# These will be reset to the color needed

	set tmpcolor $PPref(color,window,fore)

	if {([string length $tmpcolor] ==7 && [string first "#" $tmpcolor] == 0) || [string length $tmpcolor] ==6} {
        	if {[string length $tmpcolor] ==7} {set tmpcolor [string range $tmpcolor 1 6]}
		set redColor {#}
		set redColorNumber {}
		append redColorNumber  [string range $tmpcolor 0 1]
		if {[string length $redColorNumber] ==1} {
			set twoWide {0}
			append twoWide  $redColorNumber
			set redColorNumber $twoWide
		}
		append redColor $redColorNumber {0000}
		set greenColor {#00}
		set greenColorNumber {}
		append  greenColorNumber [string range $tmpcolor 2 3]

		if {[string length $greenColorNumber] ==1} {
			set twoWide {0}
			append twoWide  $greenColorNumber
			set greenColorNumber $twoWide
		}
		append  greenColor $greenColorNumber {00}
		set blueColor {#0000}
		set blueColorNumber {}
		append blueColorNumber [string range $tmpcolor 4 5]
		if {[string length $blueColorNumber] ==1} {
			set twoWide {0}
			append twoWide  $blueColorNumber
			set blueColorNumber $twoWide
		}
		append blueColor $blueColorNumber
	}
	set tmpcolor1 {#}
	append tmpcolor1 $tmpcolor
	set tmpcolor $tmpcolor1
###############################################################
# In order to set the spinint value in the entry box we must change the hex value to
# a decimal
	set tmpcolortmp "0x"
	append tmpcolortmp $redColorNumber
	set redColorNumber $tmpcolortmp
	EntryColorMonitorSettings configure -foreground $tmpcolor -background $tmpcolor
	set RedSliderValue [format "%d"  $redColorNumber]
	set tmpcolortmp "0x"
	append tmpcolortmp $greenColorNumber
	set greenColorNumber $tmpcolortmp
	set GreenSliderValue [format "%d" $greenColorNumber]
	set tmpcolortmp "0x"
	append tmpcolortmp $blueColorNumber
	set blueColorNumber $tmpcolortmp
	set BlueSliderValue [format "%d" $blueColorNumber]
#############################################################################
# Start Settings Path
	set PPrefTmp(SelectAllText) $PPref(SelectAllText)
	set PPrefTmp(ConfirmFileSaves) $PPref(ConfirmFileSaves)
	set PPrefTmp(ConfirmFileDeletions) $PPref(ConfirmFileDeletions)
	set PPrefTmp(ShowToolTips) $PPref(ShowToolTips)
	set PPrefTmp(DisplayDateFormat) $PPref(DisplayDateFormat)
	set PPrefTmp(DateSeparater) $PPref(DateSeparater)
	set PPrefTmp(DisplayTimeFormat) $PPref(DisplayTimeFormat)
	set PPrefTmp(TimeSeparater) $PPref(TimeSeparater)
	set PPrefTmp(DisplayDayOfWeek) $PPref(DisplayDayOfWeek)
	set SelectAllText $PPref(SelectAllText)
	set ConfirmFileSaves $PPref(ConfirmFileSaves)
	set ConfirmFileDeletions $PPref(ConfirmFileDeletions)
	set PDFReaderPath $PPref(PDFReaderPath)
	set ShowToolTips $PPref(ShowToolTips)
}

# End initEditSettings
#############################################################################

#############################################################################
## Procedure:  CheckForSettingsApplyEnable
proc ::CheckForSettingsApplyEnable {} {
	global PPref PPrefTmp
	
	if {$PPrefTmp(color,widget,fore) != $PPref(color,widget,fore) || $PPrefTmp(color,widget,back) != $PPref(color,widget,back) \
	|| $PPrefTmp(color,active,fore) != $PPref(color,active,fore) || $PPrefTmp(color,active,back) != $PPref(color,active,back) \
	|| $PPrefTmp(color,window,back) != $PPref(color,window,back) || $PPrefTmp(color,directory) != $PPref(color,directory) \
	|| $PPrefTmp(color,file) != $PPref(color,file) || $PPrefTmp(color,window,fore) != $PPref(color,window,fore) \
	|| $PPrefTmp(color,selection,fore) != $PPref(color,selection,fore) || $PPrefTmp(color,selection,back) != $PPref(color,selection,back) \
	|| $PPrefTmp(color,ToolTipForeground) != $PPref(color,ToolTipForeground) || $PPrefTmp(color,ToolTipBackground) != $PPref(color,ToolTipBackground) \
	|| $PPrefTmp(Foundry,label) != $PPref(Foundry,label) || $PPrefTmp(Foundry,text) != $PPref(Foundry,text) || $PPrefTmp(Foundry,ToolTip) != $PPref(Foundry,ToolTip) \
	|| $PPrefTmp(fonts,label) != $PPref(fonts,label) || $PPrefTmp(fonts,text) != $PPref(fonts,text) || $PPrefTmp(fonts,ToolTip) != $PPref(fonts,ToolTip) \
	|| $PPrefTmp(SelectAllText) != $PPref(SelectAllText) || $PPrefTmp(ConfirmFileSaves) != $PPref(ConfirmFileSaves) || $PPrefTmp(ConfirmFileDeletions) != $PPref(ConfirmFileDeletions) \
	|| $PPrefTmp(ShowToolTips) != $PPref(ShowToolTips)  || $PPref(DisplayDateFormat) != $PPrefTmp(DisplayDateFormat) || $PPref(DateSeparater) != $PPrefTmp(DateSeparater) \
	|| $PPref(DisplayTimeFormat) != $PPrefTmp(DisplayTimeFormat) || $PPref(TimeSeparater) != $PPrefTmp(TimeSeparater) \
	|| $PPref(TheCompanyName) != $PPrefTmp(TheCompanyName) || $PPref(AppleDelay) != $PPrefTmp(AppleDelay) || $PPref(FFMxProgram) != $PPrefTmp(FFMxProgram) \
	|| $PPref(RunFrom) != $PPrefTmp(RunFrom) || $PPref(EnableEMail) != $PPrefTmp(EnableEMail) || $PPref(EnableFactoryLinking) != $PPrefTmp(EnableFactoryLinking)  \
	|| $PPref(FTPTransferType) != $PPrefTmp(FTPTransferType) || $PPref(FTPDeleteAfter) != $PPrefTmp(FTPDeleteAfter) \
	|| $PPref(EnableFactory) != $PPrefTmp(EnableFactory) || $PPref(DeleteSource) != $PPrefTmp(DeleteSource) || $PPref(DeleteLogs) != $PPrefTmp(DeleteLogs) \
	|| $PPref(FreeFactoryAction) != $PPrefTmp(FreeFactoryAction) || $PPref(SMTPEMailServer) != $PPrefTmp(SMTPEMailServer) \
	|| $PPref(SMTPEMailPort) != $PPrefTmp(SMTPEMailPort) || $PPref(SMTPEMailUserName) != $PPrefTmp(SMTPEMailUserName) \
	|| $PPref(SMTPEMailPassword) != $PPrefTmp(SMTPEMailPassword) || $PPref(SMTPEMailFromName) != $PPrefTmp(SMTPEMailFromName) \
	|| $PPref(SMTPEMailFromAddress) != $PPrefTmp(SMTPEMailFromAddress) || $PPref(SMTPEMailTLS) != $PPrefTmp(SMTPEMailTLS) \
	|| $PPref(GlobalEMailMessage) != $PPrefTmp(GlobalEMailMessage) \
	|| $PPref(DisplayDayOfWeek) != $PPrefTmp(DisplayDayOfWeek) || $PPref(PDFReaderPath) != $PPrefTmp(PDFReaderPath)} {
		.settings.footerFrame.settingsApplyButton configure -state normal
	} else {
		.settings.footerFrame.settingsApplyButton configure -state disable
	}
}
## End CheckForSettingsApplyEnable
#############################################################################
#############################################################################
## Procedure:  parseColor
proc ::parseColor {} {
	global progPref PPrefTmp RedSliderValue GreenSliderValue BlueSliderValue
	global tmpcolor

##########################
# Settings Variables
	global settingsRedColorEntryVar settingsGreenColorEntryVar settingsBlueColorEntryVar

	if {([string length $tmpcolor] ==7 && [string first "#" $tmpcolor] == 0) || [string length $tmpcolor] ==6} {
	if {[string length $tmpcolor] ==7} {set tmpcolor [string range $tmpcolor 1 6]}
		set redColor {#}
		set redColorNumber {}
		append redColorNumber  [string range $tmpcolor 0 1]
		if {[string length $redColorNumber] ==1} {
			set twoWide {0}
			append twoWide  $redColorNumber
			set redColorNumber $twoWide
		}
		append redColor $redColorNumber {0000}
		set greenColor {#00}
		set greenColorNumber {}
		append  greenColorNumber [string range $tmpcolor 2 3]
		if {[string length $greenColorNumber] ==1} {
			set twoWide {0}
			append twoWide  $greenColorNumber
			set greenColorNumber $twoWide
		}
		append  greenColor $greenColorNumber {00}
		set blueColor {#0000}
		set blueColorNumber {}
		append blueColorNumber [string range $tmpcolor 4 5]
		if {[string length $blueColorNumber] ==1} {
			set twoWide {0}
			append twoWide  $blueColorNumber
			set blueColorNumber $twoWide
		}

		append blueColor $blueColorNumber
	}
	set tmpcolor1 {#}
	append tmpcolor1 $tmpcolor
	set tmpcolor $tmpcolor1
###############################################################
# In order to set the spinint value in the entry box we must change the hex value to
# a decimal
	set tmpcolortmp "0x"
	append tmpcolortmp $redColorNumber
	set redColorNumber $tmpcolortmp
	EntryColorMonitorSettings configure -foreground $tmpcolor -background $tmpcolor
	set RedSliderValue [format "%d"  $redColorNumber]
	set tmpcolortmp "0x"
	append tmpcolortmp $greenColorNumber
	set greenColorNumber $tmpcolortmp
	set GreenSliderValue [format "%d" $greenColorNumber]
	set tmpcolortmp "0x"
	append tmpcolortmp $blueColorNumber
	set blueColorNumber $tmpcolortmp
	set BlueSliderValue [format "%d" $blueColorNumber]
}
## End parseColor
#############################################################################
#############################################################################
## Procedure:  modifyColor

proc ::modifyColor {} {
	global PPref PPrefTmp RedSliderValue GreenSliderValue BlueSliderValue
	global currentColorWidget fontString
	set redColor [format "%x" $RedSliderValue]
	if {[string length $redColor] ==1} {
	set twoWide {0}
		append twoWide  $redColor
		set redColor $twoWide
	}
	set greenColor [format "%x" $GreenSliderValue]
	if {[string length $greenColor] ==1} {
		set twoWide {0}
		append twoWide  $greenColor
		set greenColor $twoWide
	}
	set blueColor [format "%x" $BlueSliderValue]
	if {[string length $blueColor] ==1} {
		set twoWide {0}
		append twoWide  $blueColor
		set blueColor $twoWide
	}
	set tmpcolor {#}
	append tmpcolor $redColor $greenColor $blueColor
	EntryColorMonitorSettings configure -foreground $tmpcolor -background $tmpcolor
		if {$currentColorWidget == "Window Foreground"} {
		set PPrefTmp(color,window,fore) $tmpcolor
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection clear
	}
	if {$currentColorWidget == "Window Background"} {
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection clear
		set PPrefTmp(color,window,back) $tmpcolor
	}
	if {$currentColorWidget == "Active Foreground"} {
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection clear
		set PPrefTmp(color,active,fore) $tmpcolor
	}
	if {$currentColorWidget == "Active Background"} {
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection clear
		set PPrefTmp(color,active,back) $tmpcolor
	}
	if {$currentColorWidget == "Widget Data Foreground"} {
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection clear
		set PPrefTmp(color,widget,fore) $tmpcolor
	}
	if {$currentColorWidget == "Widget Data Background"} {
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection clear
		set PPrefTmp(color,widget,back) $tmpcolor
	}
	if {$currentColorWidget == "Directory Color"} {
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection clear
		set PPrefTmp(color,directory) $tmpcolor
	}
	if {$currentColorWidget == "File Color"} {
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection clear
		set PPrefTmp(color,file) $tmpcolor
	}
	if {$currentColorWidget == "Selection Foreground Color"} {
		set PPrefTmp(color,selection,fore) $tmpcolor
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection range 0 end
	}
	if {$currentColorWidget == "Selection Background Color"} {
		set PPrefTmp(color,selection,back) $tmpcolor
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection range 0 end
	}
	if {$currentColorWidget == "Tool Tip Foreground"} {
		set PPrefTmp(color,ToolTipForeground) $tmpcolor
		set PPref(color,ToolTipForeground) $tmpcolor
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection range 0 end
	}
	if {$currentColorWidget == "Tool Tip Background"} {
		set PPrefTmp(color,ToolTipBackground) $tmpcolor
		set PPref(color,ToolTipBackground) $tmpcolor
		.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry selection range 0 end
	}

	LabeledFrameMonitorDisplaySettings {configure  -foreground $PPrefTmp(color,window,fore) -background $PPrefTmp(color,window,back)  -labelfont $PPrefTmp(fonts,label)}
	ScrolledListBoxColorSampleSettings configure -background $PPrefTmp(color,window,back)  -textbackground $PPrefTmp(color,widget,back) -selectforeground $PPrefTmp(color,selection,fore) -selectbackground $PPrefTmp(color,selection,back) -textfont $PPrefTmp(fonts,text)
	ButtonColorSampleSettings configure -foreground $PPrefTmp(color,window,fore) -background $PPrefTmp(color,window,back) -font $PPrefTmp(fonts,text) -activeforeground $PPrefTmp(color,active,fore) -activebackground $PPrefTmp(color,active,back) -font $PPrefTmp(fonts,label)
	EntrySampleLabelSettings configure -foreground $PPrefTmp(color,window,fore) -background $PPrefTmp(color,window,back)  -labelfont $PPrefTmp(fonts,label) -textfont $PPrefTmp(fonts,text)

	.settings.settingsTabNotebook.canvas.notebook.cs.page1.cs.settingsColorMonitorDisplayFrame.childsite.settingsColorSampleLabelEntry.lwchildsite.entry configure -foreground $PPrefTmp(color,widget,fore) -background $PPrefTmp(color,widget,back) -selectbackground $PPrefTmp(color,selection,back)  -selectforeground $PPrefTmp(color,selection,fore)
	ScrolledListBoxColorSampleSettings configure -textfont $PPrefTmp(fonts,text)
	ScrolledListBoxColorSampleSettings clear
	ScrolledListBoxColorSampleSettings insert end "First Directory Entry"
	ScrolledListBoxColorSampleSettings insert end "Second Directory Entry"
	ScrolledListBoxColorSampleSettings itemconfigure 0 -foreground $PPrefTmp(color,directory)
	ScrolledListBoxColorSampleSettings itemconfigure 1 -foreground $PPrefTmp(color,directory)
	ScrolledListBoxColorSampleSettings insert end "First File Entry"
	ScrolledListBoxColorSampleSettings insert end "Second File Entry"
	ScrolledListBoxColorSampleSettings itemconfigure 2 -foreground $PPrefTmp(color,file)
	ScrolledListBoxColorSampleSettings itemconfigure 3 -foreground $PPrefTmp(color,file)
	set tmpcolor {#}
	append tmpcolor $redColor {0000}
	set tmpcolor {#00}
	append tmpcolor $greenColor {00}
	set tmpcolor {#0000}
	append tmpcolor $blueColor
	CheckForSettingsApplyEnable
}
## End modifyColor
#############################################################################

#############################################################################
## Procedure: parseFontFileLine
proc parseFontFileLine {} {
	global tmpFoundry tmpFamily tmpWeight tmpSlant tmpSetWidth readline tmpPointSize setwidthEnd addstyleStart

	set foundryStart [expr [string first " -" $readline] +2]
	set foundryEnd [expr [string first "-" $readline $foundryStart] -1]
	set tmpFoundry [string range $readline $foundryStart $foundryEnd]
	set familyStart [expr [string first "-" $readline $foundryEnd] +1]
	set familyEnd [expr [string first "-" $readline $familyStart] -1]
	set tmpFamily [string range $readline $familyStart $familyEnd]
}
## End parseFontFileLine
#############################################################################
#############################################################################
## Procedure: parseFontSettingsLine
proc parseFontSettingsLine {} {
	global tmpFamily tmpWeight tmpSlant tmpPointSize readline
	global FontsOverstrikeCheckBox FontsUnderlineCheckBox

#  "-family utopia -size 12 -weight bold -slant roman"

	set familyStart [expr [string first " " $readline] +1]
	set familyEnd [expr [string first " " $readline $familyStart] -1]
	set tmpFamily [string range $readline $familyStart $familyEnd]
	set sizeStart [expr [string first "-size" $readline $familyEnd] +6]
	set sizeEnd [expr [string first " " $readline $sizeStart] -1]
	set tmpPointSize [string range $readline $sizeStart $sizeEnd]
	set weightStart [expr [string first "-weight" $readline $sizeEnd] +8]
	set weightEnd [expr [string first " " $readline $weightStart] -1]
	set tmpWeight [string range $readline $weightStart $weightEnd]
	set slantStart [expr [string first "-slant" $readline $weightEnd] +7]
	set slantEnd [expr [string first " " $readline $slantStart] -1]
	set tmpSlant [string range $readline $slantStart $slantEnd]
	set underlineStart [expr [string first "-underline" $readline $weightEnd] +11]
	set underlineEnd [expr [string first " " $readline $underlineStart] -1]
	set FontsUnderlineCheckBox [string range $readline $underlineStart $underlineEnd]
	set overstrikeStart [expr [string first "-overstrike" $readline $weightEnd] +12]
#	set overstrikeEnd [expr [string first " " $readline $overstrikeStart] -1]
	set FontsOverstrikeCheckBox [string range $readline $overstrikeStart end]


#tk_messageBox -message $FontsOverstrikeCheckBox

}
## End parseFontSettingsLine
#############################################################################
#############################################################################
## Procedure: GetNumberOfFFProcesses
proc GetNumberOfFFProcesses {} {
##########################
# Free Factory Variables
	global AppleDelay NumberOfFFProcesses FFProcessList SelectedDirectoryPath NotifyDirectoryList NumberOfDirectories NotifyRuntimeUser ScrollBoxItemPos ShowProcess
	global env

# 1834 pts/2    00:00:00 inotifywait
# 1835 pts/2    00:00:00 FreeFactoryNoti
# 1836 pts/2    00:00:00 inotifywait
# 1837 pts/2    00:00:00 FreeFactoryNoti
	ScrolledListBoxFactoryRunningProcesses delete 0 end
	if {$ShowProcess == "User"} {
		set HomeDir $env(HOME)
		set LastSlash [string last "/" $HomeDir]
		set UserName [string range $HomeDir [expr $LastSlash +1] end]
		exec bash -c "ps -U $UserName > /opt/FreeFactory/FFProcessScratch"
	} else {
		exec bash -c "ps -ea > /opt/FreeFactory/FFProcessScratch"
	}
	set FileHandle [open "/opt/FreeFactory/FFProcessScratch" r]
	set NumberOfFFProcesses 0
	while {![eof $FileHandle]} {
		gets $FileHandle Process
		if {[string first "inotifywait" $Process]>-1} {
			incr NumberOfFFProcesses
			set Process [string trim $Process]
			set FirstSpace [string first " " $Process]
			set FFInotifyStartupID [string trim [string range $Process 0 $FirstSpace]]
			set FFProcessList($NumberOfFFProcesses,FFInotifyStartupID) $FFInotifyStartupID
			set FFProcessList($NumberOfFFProcesses,ProcessLine) $Process
			ScrolledListBoxFactoryRunningProcesses insert end $FFProcessList($NumberOfFFProcesses,ProcessLine)
		}
	}
	if {[file exists "/opt/FreeFactory/FFProcessScratch"]} {
		file delete -force "/opt/FreeFactory/FFProcessScratch"
	}
#############################################################################
#
# This is an attempt to receive the output of the ps command on the fly and
# not from redirecting to and reading from a file.
#
#	set NumberOfFFProcesses 0
#	if {$ShowProcess == "User"} {
#		set HomeDir $env(HOME)
#		set LastSlash [string last "/" $HomeDir]
#		set UserName [string range $HomeDir [expr $LastSlash +1] end]
#		foreach Process {<<[exec ps -U $UserName]} {
#			if {[string first "inotifywait" $Process]>-1} {
#				incr NumberOfFFProcesses
#				set Process [string trim $Process]
#				set FirstSpace [string first " " $Process]
#				set FFInotifyStartupID [string trim [string range $Process 0 $FirstSpace]]
#				set FFProcessList($NumberOfFFProcesses,FFInotifyStartupID) $FFInotifyStartupID
#				set FFProcessList($NumberOfFFProcesses,ProcessLine) $Process
#				ScrolledListBoxFactoryRunningProcesses insert end $FFProcessList($NumberOfFFProcesses,ProcessLine)
#			}
#		}

#	} else {

#		foreach Process {<<[exec ps -ea]} {
#			if {[string first "inotifywait" $Process]>-1} {
#				incr NumberOfFFProcesses
#				set Process [string trim $Process]
#				set FirstSpace [string first " " $Process]
#				set FFInotifyStartupID [string trim [string range $Process 0 $FirstSpace]]
#				set FFProcessList($NumberOfFFProcesses,FFInotifyStartupID) $FFInotifyStartupID
#				set FFProcessList($NumberOfFFProcesses,ProcessLine) $Process
#				ScrolledListBoxFactoryRunningProcesses insert end $FFProcessList($NumberOfFFProcesses,ProcessLine)
#			}
#		}
#	}
#
#############################################################################
}
## End GetNumberOfFFProcesses
#############################################################################
#############################################################################
## Procedure: GetNotifyDirectoryList
proc GetNotifyDirectoryList {} {

##########################
# Free Factory Variables
	global AppleDelay NumberOfFFProcesses FFProcessList SelectedDirectoryPath NotifyDirectoryList NumberOfDirectories NotifyRuntimeUser ScrollBoxItemPos ShowProcess
	global env

	ScrolledListBoxFactoryNotifyDirectories delete 0 end
	if {![file exists "/opt/FreeFactory/FreeFactoryNotifyDirectoryList"]} {
		set FileHandle [open "/opt/FreeFactory/FreeFactoryNotifyDirectoryList" w]
		puts $FileHandle "/opt/FreeFactory/NotifyVideo/ {}"
		puts $FileHandle "/opt/FreeFactory/NotifyVideo2/ {}"
		close $FileHandle
	}
	set FileHandle [open "/opt/FreeFactory/FreeFactoryNotifyDirectoryList" r]
	set NumberOfDirectories 0
	while {![eof $FileHandle]} {
		gets $FileHandle NotifyDirectory
		if {[string trim $NotifyDirectory] !=""} {
			set NotifyDirectoryList($NumberOfDirectories) $NotifyDirectory
			ScrolledListBoxFactoryNotifyDirectories insert end [lindex $NotifyDirectory 0]
			incr NumberOfDirectories
		}
	}
	close $FileHandle
}
## End GetNotifyDirectoryList
#############################################################################
#############################################################################
## Procedure: SaveDirectoryList
proc SaveDirectoryList {} {
	global SelectedDirectoryPath ScrollBoxItemPos NumberOfDirectories NotifyRuntimeUser NotifyDirectoryList
# First check to make sure SelectedDirectoryPath variable
# is not a null string or a string with only spaces.
		if {[string trim $SelectedDirectoryPath] != ""} {
# If notify directory path does not end in a slash then append it.
			if {[expr [string last "/" [string trim $SelectedDirectoryPath]] + 1] < [string length [string trim $SelectedDirectoryPath]]} {
				append SelectedDirectoryPath "/"
			}
			set FileHandle [open "/opt/FreeFactory/FreeFactoryNotifyDirectoryList" w]
			set NotifyDirectoryList($NumberOfDirectories) [list [string trim $SelectedDirectoryPath] [string trim $NotifyRuntimeUser]]
			incr NumberOfDirectories
			for {set x 0} {$x < $NumberOfDirectories} {incr x} {
# Then we over write
				puts $FileHandle $NotifyDirectoryList($x)
			}
			close $FileHandle
			set SelectedDirectoryPath ""
			set NotifyRuntimeUser ""
			ButtonSaveDirectory configure -state disable
			GetNotifyDirectoryList
		}
}
## End SaveDirectoryList
#############################################################################
#############################################################################
## Procedure: UpdateDirectoryList
proc UpdateDirectoryList {} {
	global SelectedDirectoryPath ScrollBoxItemPos NumberOfDirectories NotifyRuntimeUser NotifyDirectoryList

			if {[expr [string last "/" [string trim $SelectedDirectoryPath]] + 1] < [string length [string trim $SelectedDirectoryPath]]} {
				append SelectedDirectoryPath "/"
			}
			set FileHandle [open "/opt/FreeFactory/FreeFactoryNotifyDirectoryList" w]
			set NotifyDirectoryList($ScrollBoxItemPos) [list [string trim $SelectedDirectoryPath] [string trim $NotifyRuntimeUser]]
			for {set x 0} {$x < $NumberOfDirectories} {incr x} {
				puts $FileHandle $NotifyDirectoryList($x)
			}
			close $FileHandle
			set SelectedDirectoryPath ""
			set NotifyRuntimeUser ""
			ButtonUpdateDirectory configure -state disable
			GetNotifyDirectoryList
}
## End UpdateDirectoryList
#############################################################################
################################################################################
################################################################################
proc DeleteNotifyDirectory {} {
	global PPref GenericConfirmName GenericConfirm NotifyDirectoryList ScrollBoxItemPos NumberOfDirectories SelectedDirectoryPath
# First check to make sure SelectedDirectoryPath variable
# is not a null string or a string with only spaces.
	if {[string trim $SelectedDirectoryPath] != ""} {
		if {$PPref(ConfirmFileDeletions) == "Yes"} {
			set GenericConfirm 2
			Window show .genericConfirm
			widgetUpdate
			set GenericConfirmName "Delete notify directory"
			append GenericConfirmName "  $SelectedDirectoryPath  ?"
			wm title .genericConfirm "Delete Directory Confirmation"
			tkwait window .genericConfirm
			if {$GenericConfirm == 1} {
# Set selected directory variable to null
				set NotifyDirectoryList($ScrollBoxItemPos) ""
				set FileHandle [open "/opt/FreeFactory/FreeFactoryNotifyDirectoryList" w]
				for {set x 0} {$x < $NumberOfDirectories} {incr x} {
# Only write to the file if directory path not set to null
					if {$NotifyDirectoryList($x) != ""} {
						puts $FileHandle $NotifyDirectoryList($x)
						set NotifyDirectoryList($x) ""
					}
				}
				close $FileHandle
				set SelectedDirectoryPath ""
				set NotifyRuntimeUser ""
				ButtonUpdateDirectory configure -state disable
				GetNotifyDirectoryList
			}
		} else {

# First check to make sure SelectedDirectoryPath variable
# is not a null string or a string with only spaces.
# Set selected directory variable to null
			set NotifyDirectoryList($ScrollBoxItemPos) ""
			set FileHandle [open "/opt/FreeFactory/FreeFactoryNotifyDirectoryList" w]
			for {set x 0} {$x < $NumberOfDirectories} {incr x} {
# Only write to the file if directory path not set to null
				if {$NotifyDirectoryList($x) != ""} {
					puts $FileHandle $NotifyDirectoryList($x)
					set NotifyDirectoryList($x) ""
				}
			}
			close $FileHandle
			set SelectedDirectoryPath ""
			set NotifyRuntimeUser ""
			ButtonUpdateDirectory configure -state disable
			GetNotifyDirectoryList
		}
	}
}
# End DeleteFactoryFile
################################################################################
################################################################################
