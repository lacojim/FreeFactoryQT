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
#
# Program:WidgetUpdate.tcl
#
# This procedure updates all the colors and fonts for all of the windows and widgets of the
# program.  If the window is already open (exists) then the widget is set according to the
# PPref variable.  The PPref variable means Program Preferences.  When a window or widget
# is added, corresponding configuration code needs to be added here.  This allows the window
# and widgets to be automatically updated if the settings are changed on the fly. 
################################################################################################
proc {widgetUpdate} {} {

	global PPref PPrefTmp tmpcolor FontSizeLabel FontSizeText
	global ButtonConfig1 ComboBoxConfig1 ComboBoxConfigIWidgets ComboBoxLabelConfig2
	global MenuConfig FrameConfig EntryConfig1 EntryConfigIWidgets EntryConfigLabelIWidgets LabelConfig1 LabeledFrameConfig EntryConfig3
	global TabConfig RadioButtonConfig1 SpinIntConfigIWidgets CheckButtonConfig1 ScrolledListBoxConfigIWidgets
	global MenuButtonConfig1 MenuButtonMenuConfig1 ScrolledFrameSideConfigIWidgets LabelConfigTitle EntryConfigRecordNumbers
	global ScrolledCanvasConfigIWidgets ScaleProgressBarConfig SliderScaleConfig EntryProgressBarConfig HierarchyConfigIWidgets
	global ScrolledFrameConfigIWidgets CanvasConfig1
	global ProgressBarProgress ProcessedRecords TotalRecords
	global ScaleWidth ProgressPercentComplete ProgressActionTitle ProgressDetailCount

	set ButtonConfig1 {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back)  -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back) -font $PPref(fonts,label)}
	set ButtonConfigHide {configure -foreground $PPref(color,window,back) -background $PPref(color,window,back)  -activeforeground $PPref(color,window,back) -activebackground $PPref(color,window,back) -highlightthickness 0 -relief flat -borderwidth 0 -font $PPref(fonts,label)}
	set CanvasConfig1 "configure  -background $PPref(color,window,back)"
	set CheckButtonConfig1 {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back) -highlightthickness 0 -font $PPref(fonts,label)}
	set ComboBoxConfig1 {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -textbackground $PPref(color,widget,back) -textfont $PPref(fonts,text) -labelfont $PPref(fonts,label)}
	set ComboBoxConfigIWidgets {configure -foreground $PPref(color,window,fore) -textbackground $PPref(color,widget,back) -background $PPref(color,window,back) -labelfont $PPref(fonts,label) -textfont $PPref(fonts,text)}
	set ComboBoxLabelConfig2 {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label)}
	set EntryConfig1 "configure -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back) -selectbackground $PPref(color,selection,back)"
	set EntryConfigIWidgets {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -textbackground $PPref(color,widget,back) -selectbackground $PPref(color,selection,back) -labelfont $PPref(fonts,label) -textfont $PPref(fonts,text)}
	set EntryConfigRecordNumbers {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -labelfont $PPref(fonts,label) -textfont $PPref(fonts,text)}
	set EntryConfigLabel {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -relief flat -borderwidth 0 -highlightthickness 0 -font $PPref(fonts,label)}
	set EntryConfigLabelIWidgets {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -textbackground $PPref(color,window,back) -selectbackground $PPref(color,selection,back) -labelfont $PPref(fonts,label) -textfont $PPref(fonts,text)}
	set EntryProgressBarConfig {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -selectforeground $PPref(color,window,fore) -selectbackground $PPref(color,window,back) -font $PPref(fonts,label)}
	set EntryConfigLabelIWidgetsDisabled "configure -disabledbackground $PPref(color,window,back) -disabledforeground $PPref(color,window,fore)"
	set FrameConfig "configure -background $PPref(color,window,back)"
	set LabelConfigTitle "configure -foreground $PPref(color,directory) -background $PPref(color,window,back)"
	set LabelConfig1  {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label)}
	set LabeledFrameConfig {configure -background $PPref(color,window,back) -labelfont $PPref(fonts,label)}
	set MenuButtonConfig1 {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back) -font $PPref(fonts,label)}
	set MenuButtonMenuConfig1 {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back) -font $PPref(fonts,label)}
	set MenuConfig {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back) -font $PPref(fonts,label)}
	set RadioButtonConfig1 {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back) -highlightthickness 0 -font $PPref(fonts,label)}
	set ScaleProgressBarConfig "configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -troughcolor $PPref(color,widget,back) -activebackground $PPref(color,directory) -sliderlength [expr int(( 1 ) * 100)]"
	set SliderScaleConfig "configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -activebackground $PPref(color,widget,back)"
	set ScrolledCanvasConfigIWidgets "configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -textbackground $PPref(color,window,back)"
	set ScrolledFrameConfigIWidgets "configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -activebackground $PPref(color,active,back)"
	set ScrolledFrameSideConfigIWidgets "configure -foreground $PPref(color,window,fore) -background $PPref(color,sidewindow,back) -activebackground $PPref(color,active,back)"
	set ScrolledListBoxConfigIWidgets {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -textbackground $PPref(color,widget,back) -selectforeground $PPref(color,selection,fore) -selectbackground $PPref(color,selection,back) -labelfont $PPref(fonts,label) -textfont $PPref(fonts,text)}
	set ScrolledTextBoxConfig {configure -foreground $PPref(color,widget,fore) -background $PPref(color,window,back) -textbackground $PPref(color,widget,back) -textfont $PPref(fonts,text)}
	set SpinIntConfigIWidgets {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -textbackground $PPref(color,widget,back) -selectbackground $PPref(color,selection,back) -textfont $PPref(fonts,text)}
	set TabConfig {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -selectforeground $PPref(color,active,fore) -selectbackground $PPref(color,active,back) -font $PPref(fonts,label)}
	set TabConfig2 {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label)}

	set StartPos [string trim [expr [string first "-size " $PPref(fonts,label)] + 6]]
	set EndPos   [expr [string trim [string first " " $PPref(fonts,label) [expr $StartPos +1]]] -1]
	set FontSizeLabel [string range $PPref(fonts,label) $StartPos $EndPos]
	set FirstHalfPos [expr [string first "-size " $PPref(fonts,label)] -1]
	set SecondHalfPos   [expr [string first " " $PPref(fonts,label) [expr $FirstHalfPos +7]] -0]
	set FirstHalf [string range $PPref(fonts,label) 0 $FirstHalfPos]
	set SecondHalf [string range $PPref(fonts,label) $SecondHalfPos end]
	set TabFont "$FirstHalf -size [expr $FontSizeLabel + 2] $SecondHalf"
	set TabConfig3 {configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $TabFont}

	set HierarchyConfigIWidgets "configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -textbackground $PPref(color,widget,back) -labelfont $PPref(fonts,label) -textfont $PPref(fonts,text)"

	if {[winfo exists .programFrontEnd] && ![winfo exists .fileDialog] && ![winfo exists .genericConfirm] && ![winfo exist .settings] && ![winfo exist .showAbout] && ![winfo exist .showLicense]} {
		.programFrontEnd configure -background $PPref(color,window,back)
		MenuMasterProgramFrontEnd $MenuConfig
		Menu1ProgramFrontEnd $MenuConfig
		Menu3ProgramFrontEnd $MenuConfig
		Menu7ProgramFrontEnd $MenuConfig
		Menu9ProgramFrontEnd $MenuConfig
		FrameTopMaster $FrameConfig
		FrameButtonGroup1 $FrameConfig
		ButtonNew $ButtonConfig1
		ButtonSave $ButtonConfig1
		ButtonDelete $ButtonConfig1
		ButtonExitProgram $ButtonConfig1
		FrameButtonGroup5 $FrameConfig
		ButtonEditSettings $ButtonConfig1
		ButtonSaveSettings $ButtonConfig1
		FrameButtonGroup7 $FrameConfig
		ButtonHelp $ButtonConfig1
		ButtonLicense $ButtonConfig1
		ButtonAbout $ButtonConfig1
		FrameMiddle $FrameConfig
		LabeledFrameFactorySelection $LabeledFrameConfig
		FrameListBoxLedgendFactorySelection $FrameConfig
		ScrolledListBoxFactoryFilesFactorySelection $ScrolledListBoxConfigIWidgets
		SelectFactoryFileNameSelectionEntry $EntryConfigIWidgets
		FrameReadOnlyFactorySelection $FrameConfig
		ButtonReadOnlyFactorySelection $ButtonConfig1
		FrameRight $FrameConfig
		LabeledFrameFactoryOptions $LabeledFrameConfig
		FactoryDescriptionEntry $EntryConfigIWidgets
		FrameNotifyDirectory $FrameConfig
		ComboBoxNotifyDirectoryFactorySelection $ComboBoxConfigIWidgets
		ButtonGetNotifyDirectorySelection $ButtonConfig1
		FrameOutputDirectory $FrameConfig
		OutputDirectoryEntry $EntryConfigIWidgets
		ButtonGetOutputDirectory $ButtonConfig1
		FrameOutputFileSuffix $FrameConfig
		OutputFileSuffixEntry $EntryConfigIWidgets
		ComboBoxFFMxProgramFactorySelection $ComboBoxConfigIWidgets
		LabelRunFrom $LabelConfig1
		RadioButtonRunFromOpt $RadioButtonConfig1
		RadioButtonRunFromUSR $RadioButtonConfig1
		FrameEnableFactory $FrameConfig
		CheckButtonEnableFactory $CheckButtonConfig1
		CheckButtonRemoveLogs $CheckButtonConfig1
		CheckButtonRemoveSource $CheckButtonConfig1
		LabelFreeFactoryAction $LabelConfig1
		RadioButtonFreeFactoryActionCopy $RadioButtonConfig1
		RadioButtonFreeFactoryActionEncode $RadioButtonConfig1
		LabeledFrameFTPOptions $LabeledFrameConfig
		FrameFTPProgram $FrameConfig
		ComboBoxFTPProgramFactorySelection $ComboBoxConfigIWidgets
		FTPURLEntry $EntryConfigIWidgets
		FTPUserNameEntry $EntryConfigIWidgets
		FTPPasswordEntry $EntryConfigIWidgets
		FTPRemotePathEntry $EntryConfigIWidgets
		FrameFTPRemotePath $FrameConfig
		LabelFTPTransferType $LabelConfig1
		RadioButtonFTPTransferTypeASC $RadioButtonConfig1
		RadioButtonFTPTransferTypeBIN $RadioButtonConfig1
		CheckButtonFTPDeleteAfter $RadioButtonConfig1
		FrameFTPTransferType $FrameConfig
		LabeledFrameVideoOptions $LabeledFrameConfig
		FrameVideoCodecsWrapper $FrameConfig
		ComboBoxVideoCodecsFactorySelection $ComboBoxConfigIWidgets
		ComboBoxVideoWrapperFactorySelection $ComboBoxConfigIWidgets
		ComboBoxFrameRateFactorySelection $ComboBoxConfigIWidgets
		FrameRateSize $FrameConfig
		ComboBoxSizeFactorySelection $ComboBoxConfigIWidgets
		ComboBoxVideoBitRateFactorySelection $ComboBoxConfigIWidgets
		ComboBoxAspectFactorySelection $ComboBoxConfigIWidgets
		FrameTargetTagsThreads $FrameConfig
		ComboBoxTargetFactorySelection $ComboBoxConfigIWidgets
		ComboBoxTagsFactorySelection $ComboBoxConfigIWidgets
		ComboBoxThreadsFactorySelection $ComboBoxConfigIWidgets
		FrameStreamIDBFrames $FrameConfig
		EntryVideoStreamIDFactorySelection $EntryConfigIWidgets
		EntryBFramesFactorySelection $EntryConfigIWidgets
		EntryFrameESrategyFactorySelection $EntryConfigIWidgets
		FrameGroupPicSize $FrameConfig
		EntryGroupPicSizeFactorySelection $EntryConfigIWidgets
		EntryStartTimeOffsetFactorySelection $EntryConfigIWidgets
		ComboBoxForceFormatFactorySelection $ComboBoxConfigIWidgets
		ComboBoxVideoPresetFactorySelection $ComboBoxConfigIWidgets
		LabeledFrameAudioOptions $LabeledFrameConfig
		FrameAudioCodecsBitRateSampleRate $FrameConfig
		ComboBoxAudioCodecsFactorySelection $ComboBoxConfigIWidgets
		ComboBoxAudioBitRateFactorySelection $ComboBoxConfigIWidgets
		ComboBoxAudioSampleRateFactorySelection $ComboBoxConfigIWidgets
		FrameAudioFileExtensionTagChannels $FrameConfig
		ComboBoxAudioFileExtensionFactorySelection $ComboBoxConfigIWidgets
		ComboBoxAudioTagFactorySelection $ComboBoxConfigIWidgets
		ComboBoxAudioChannelsFactorySelection $ComboBoxConfigIWidgets
		EntryAudioStreamIDFactorySelection $EntryConfigIWidgets
		EntryManualOptions $EntryConfigIWidgets
		FrameEMailAndLink $FrameConfig
		LabeledFrameFactoryEmail $LabeledFrameConfig
		FrameEMailEnable $FrameConfig
		CheckButtonEnableFactoryEMail $CheckButtonConfig1
		ButtonAddFactoryEMailMessage $ButtonConfig1
		EntryFactoryEMailName $EntryConfigIWidgets
		EntryFactoryEMailAddress $EntryConfigIWidgets
		ScrolledListBoxFactoryEMail $ScrolledListBoxConfigIWidgets
		FrameFactoryEMailButton $FrameConfig
		ButtonNewEMail $ButtonConfig1
		ButtonAddEMail $ButtonConfig1
		ButtonUpdateEMail $ButtonConfig1
		ButtonRemoveEMail $ButtonConfig1
		LabeledFrameFactoryLinking $LabeledFrameConfig
		CheckButtonEnableFactoryLinking $CheckButtonConfig1
		ComboBoxLinkedFactory $ComboBoxConfigIWidgets
		EntryLabelLinkedFactories $EntryConfigLabelIWidgets
		ScrolledListBoxFactoryLinking $ScrolledListBoxConfigIWidgets
		FrameFactoryLinkingButton $FrameConfig
		ButtonAddLink $ButtonConfig1
		ButtonRemoveLink $ButtonConfig1
		FrameFooterMaster $FrameConfig
		FrameFooterTime $FrameConfig
		EntrySolutionStatusProgramFrontEnd $EntryConfigLabel
		ScaleProgressBarProgramFrontEnd $ScaleProgressBarConfig
		EntryProgressPercentCompleteProgramFrontEnd $EntryConfigLabel
		EntrySystemTimeProgramFrontEnd $EntryConfigLabel
	}

	if {[winfo exists .freeFactoryViewLogs]} {
		.freeFactoryViewLogs configure -background $PPref(color,window,back)
		LabeledFrameViewFreeFactoryLogs $LabeledFrameConfig
		FrameListLogs $FrameConfig
		ScrolledListBoxLogs $ScrolledListBoxConfigIWidgets
		FrameListLogsButton $FrameConfig
		ButtonRefreshLog $ButtonConfig1
		ButtonRemoveLog $ButtonConfig1
		ScrolledTextLog $ScrolledTextBoxConfig
		ButtonCloseFreeFactoryViewLogs $ButtonConfig1
	}
	if {[winfo exists .fileDialog]} {
		FrameTopFileDialog $FrameConfig
		LabelLookInFileDialog $LabelConfig1
		ComboBoxUpLevelFileDialog $ComboBoxConfigIWidgets
		MenuButtonToolFileDialog $MenuButtonConfig1
		MenuButtonMenu1ToolFileDialog $MenuButtonMenuConfig1
		MenuButtonMenu2ToolFileDialog $MenuButtonMenuConfig1
		MenuButtonViewFileDialog $MenuButtonConfig1
		MenuButtonMenu1ViewFileDialog $MenuButtonMenuConfig1
#		MenuButtonMenu2ViewFileDialog $MenuButtonMenuConfig1
		ButtonDeleteFileDialog $ButtonConfig1
		ButtonPasteFileDialog $ButtonConfig1
		ButtonCutFileDialog $ButtonConfig1
		ButtonCopyFileDialog $ButtonConfig1
		ButtonNewDirFileDialog $ButtonConfig1
		ButtonUpLevelFileDialog $ButtonConfig1
		ButtonBackLevelFileDialog $ButtonConfig1
		FrameTopMasterFileDialog $FrameConfig
		ScrolledFrameLeftFileDialog $ScrolledFrameSideConfigIWidgets
		ButtonHomeDirFileDialog $ButtonConfig1
		ButtonDesktopDirFileDialog $ButtonConfig1
		ButtonDocumentsDirFileDialog $ButtonConfig1
		ButtonFloppyDirFileDialog $ButtonConfig1
		ButtonCDROMDirFileDialog $ButtonConfig1
		ButtonMntDirFileDialog $ButtonConfig1
		ButtonMediaDirFileDialog $ButtonConfig1
#		ButtonNetworkDirFileDialog $ButtonConfig1
		ScrolledListBoxFileViewFileDialog $ScrolledListBoxConfigIWidgets
		FrameBottomMasterFileDialog $FrameConfig
		FrameBottomSub1FileDialog $FrameConfig
		FrameBottomSub2FileDialog $FrameConfig
		ComboBoxFileTypeFileDialog $ComboBoxConfigIWidgets
		LabelFileTypeFileDialog $LabelConfig1
		EntryFileNameFileDialog $EntryConfig1
		LabelFileNameFileDialog $LabelConfig1
		ButtonOpenFileDialog $ButtonConfig1
		ButtonCancelFileDialog $ButtonConfig1
	}

	if {[winfo exists .directoryDialog]} {
		.directoryDialog configure -background $PPref(color,window,back)
		FrameTopDirectoryDialog $FrameConfig
		LabelLookInDirectoryDialog $LabelConfig1
		ComboBoxUpLevelDirectoryDialog $ComboBoxConfigIWidgets
		MenuButtonToolDirectoryDialog $MenuButtonConfig1
		MenuButtonMenu1ToolDirectoryDialog $MenuButtonMenuConfig1
		MenuButtonMenu2ToolDirectoryDialog $MenuButtonMenuConfig1
		MenuButtonViewDirectoryDialog $MenuButtonConfig1
		MenuButtonMenu1ViewDirectoryDialog $MenuButtonMenuConfig1
		MenuButtonMenu2ViewDirectoryDialog $MenuButtonMenuConfig1
		ButtonDeleteDirectoryDialog $ButtonConfig1
		ButtonPasteDirectoryDialog $ButtonConfig1
		ButtonCutDirectoryDialog $ButtonConfig1
		ButtonCopyDirectoryDialog $ButtonConfig1
		ButtonNewDirDirectoryDialog $ButtonConfig1
		ButtonUpLevelDirectoryDialog $ButtonConfig1
		ButtonBackLevelDirectoryDialog $ButtonConfig1
		FrameTopMasterDirectoryDialog $FrameConfig
		ScrolledFrameLeftDirectoryDialog $ScrolledFrameSideConfigIWidgets
		ButtonHomeDirDirectoryDialog $ButtonConfig1
		ButtonDesktopDirDirectoryDialog $ButtonConfig1
		ButtonDocumentsDirDirectoryDialog $ButtonConfig1
		ButtonFloppyDirDirectoryDialog $ButtonConfig1
		ButtonCDROMDirDirectoryDialog $ButtonConfig1
#		ButtonNetworkDirDirectoryDialog $ButtonConfig1
		ScrolledListBoxFileViewDirectoryDialog $ScrolledListBoxConfigIWidgets
		FrameBottomMasterDirectoryDialog $FrameConfig
		FrameBottomSub1DirectoryDialog $FrameConfig
		FrameBottomSub2DirectoryDialog $FrameConfig
		EntryFileNameDirectoryDialog $EntryConfig1
		LabelFileNameDirectoryDialog $LabelConfig1
		ButtonOpenDirectoryDialog $ButtonConfig1
		ButtonCancelDirectoryDialog $ButtonConfig1
	}
	if {[winfo exist .findFileDialog]} {
		.findFileDialog configure -background $PPref(color,window,back)
		EntryFindFileDialog $EntryConfigIWidgets
		ComboBoxFindFileDialog $ComboBoxConfigIWidgets
		.findFileDialog.comboboxFindFileDialog.lwchildsite.entry configure -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back) -font $PPref(fonts,text)
		FrameTopFindFileDialog $FrameConfig
		CheckButtonCaseSensitiveFindFileDialog $CheckButtonConfig1
		CheckButtonExactMatchFindFileDialog $CheckButtonConfig1
		CheckButtonRecursiveFindFileDialog $CheckButtonConfig1
		FrameBottonFindFileDialog $FrameConfig
		RadioButtonFileSearchFindFileDialog $RadioButtonConfig1
		RadioButtonInFileSearchFindFileDialog $RadioButtonConfig1
		ButtonBoxFindFileDialog $ButtonConfig1
		.findFileDialog.buttonboxFindFileDialog buttonconfigure 0 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)  -background $PPref(color,window,back) -font $PPref(fonts,label)
		.findFileDialog.buttonboxFindFileDialog buttonconfigure 1 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)  -background $PPref(color,window,back) -font $PPref(fonts,label)
		.findFileDialog.buttonboxFindFileDialog buttonconfigure 2 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)  -background $PPref(color,window,back) -font $PPref(fonts,label)
		.findFileDialog.buttonboxFindFileDialog buttonconfigure 3 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)  -background $PPref(color,window,back) -font $PPref(fonts,label)
	}
	if {[winfo exist .fileDialogBookmarkTitle]} {
		.fileDialogBookmarkTitle configure -background $PPref(color,window,back)
		EntryBookmarkTitleFileDialog $EntryConfigIWidgets
		EntryBookmarkPathFileDialog $EntryConfigIWidgets
		ButtonBoxBookmarksFileDialog $ButtonConfig1
		.fileDialogBookmarkTitle.fileDialogBookmarkButtonBox  buttonconfigure 0 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
		.fileDialogBookmarkTitle.fileDialogBookmarkButtonBox  buttonconfigure 1 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
		.fileDialogBookmarkTitle.fileDialogBookmarkButtonBox  buttonconfigure 2 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
	}
	if {[winfo exist .directoryDialogBookmarkTitle]} {
		.directoryDialogBookmarkTitle configure -background $PPref(color,window,back)
		EntryBookmarkTitleDirectoryDialog $EntryConfigIWidgets
		EntryBookmarkPathDirectoryDialog $EntryConfigIWidgets
		ButtonBoxBookmarksDirectoryDialog $ButtonConfig1
		.directoryDialogBookmarkTitle.directoryDialogBookmarkButtonBox  buttonconfigure 0 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
		.directoryDialogBookmarkTitle.directoryDialogBookmarkButtonBox  buttonconfigure 1 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
		.directoryDialogBookmarkTitle.directoryDialogBookmarkButtonBox  buttonconfigure 2 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
	}
	if {[winfo exist .newDirNameReq]} {
		.newDirNameReq configure -background $PPref(color,window,back)
		EntryNewDirectoryNewDirName $EntryConfigIWidgets
		.newDirNameReq.entryNewDirName.lwchildsite.entry configure -foreground $PPref(color,widget,fore) -background $PPref(color,widget,back) -font $PPref(fonts,text)
		ButtonBoxNewDirName $ButtonConfig1
		.newDirNameReq.buttonBoxNewDirName buttonconfigure 0 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
		.newDirNameReq.buttonBoxNewDirName buttonconfigure 1 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
		.newDirNameReq.buttonBoxNewDirName buttonconfigure 2 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
	}

	if {[winfo exist .fileRename]} {
		.fileRename configure -background $PPref(color,window,back)
		EntryOldFileNameFileRename $EntryConfigIWidgets
		EntryNewNameFileRename $EntryConfigIWidgets
		ButtonBoxFileRename $ButtonConfig1
		.fileRename.buttonBoxFileRename buttonconfigure 0 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label)  -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
		.fileRename.buttonBoxFileRename buttonconfigure 1 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label)  -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
		.fileRename.buttonBoxFileRename buttonconfigure 2 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label)  -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
	}
	if {[winfo exist .deleteFileConfirm]} {
		.deleteFileConfirm configure -background $PPref(color,window,back)
		FrameMasterConfirmFileDelete $FrameConfig
		FrameTopConfirmFileDelete $FrameConfig
		LabelFileNameConfirmFileDelete $LabelConfig1
		FrameFooterConfirmFileDelete $FrameConfig
		ButtonDeleteEachConfirmFileDelete $ButtonConfig1
		ButtonDeleteAllConfirmFileDelete $ButtonConfig1
		ButtonNoDeleteConfirmFileDelete $ButtonConfig1
		ButtonCancelConfirmFileDelete $ButtonConfig1
	}

	if {[winfo exist .deleteConfirmSingle]} {
		.deleteConfirmSingle configure -background $PPref(color,window,back)
		FrameMasterConfirmSingleFileDelete $FrameConfig
		FrameMiddleConfirmSingleFileDelete $FrameConfig
		LabelConfirmSingleFileDelete $LabelConfig1
		FrameFooterConfirmSingleFileDelete $FrameConfig
		ButtonNoConfirmSingleFileDelete $ButtonConfig1
		ButtonYesConfirmSingleFileDelete $ButtonConfig1
	}

	if {[winfo exists .fileDialogProperties]} {
		.fileDialogProperties configure -background $PPref(color,window,back)
		FrameMasterFilePropertiesDialog $FrameConfig
		FrameTopFilePropertiesDialog $FrameConfig
		EntryFilePathFilePropertyDialog $EntryConfigLabelIWidgets
		EntryPathTypeFilePropertyDialog $EntryConfigLabelIWidgets
		EntryFileSizeFilePropertyDialog $EntryConfigLabelIWidgets
		EntryFileTypeFilePropertyDialog $EntryConfigLabelIWidgets
		EntryLastAccessedFilePropertyDialog $EntryConfigLabelIWidgets
		EntryLastModifiedFilePropertyDialog $EntryConfigLabelIWidgets
		EntryFileNameFilePropertyDialog  $EntryConfigLabelIWidgets
		ComboBoxOwnerFilePropertyDialog $ComboBoxConfigIWidgets
		ComboBoxGroupFilePropertyDialog $ComboBoxConfigIWidgets
		FrameBottomFilePropertyDialog $FrameConfig
		LabelOwnerFilePropertyDialog $LabelConfig1
		LabelOtherFilePropertyDialog $LabelConfig1
		LabelWriteFilePropertyDialog $LabelConfig1
		LabelExecuteFilePropertyDialog $LabelConfig1
		CheckButtonOwnerReadFilePropertyDialog $CheckButtonConfig1
		CheckButtonGroupReadFilePropertyDialog $CheckButtonConfig1
		CheckButtonOtherReadFilePropertyDialog $CheckButtonConfig1
		CheckButtonOwnerWriteFilePropertyDialog $CheckButtonConfig1
		CheckButtonGroupWriteFilePropertyDialog $CheckButtonConfig1
		CheckButtonOtherWriteFilePropertyDialog $CheckButtonConfig1
		CheckButtonOwnerExecuteFilePropertyDialog $CheckButtonConfig1
		CheckButtonGroupExecuteFilePropertyDialog $CheckButtonConfig1
		CheckButtonOtherExecuteFilePropertyDialog $CheckButtonConfig1
		CheckButtonSUIDFilePropertyDialog $CheckButtonConfig1
		CheckButtonGUIDFilePropertyDialog $CheckButtonConfig1
		CheckButtonStickyFilePropertyDialog $CheckButtonConfig1
		LabeGroupFilePropertyDialog $LabelConfig1
		LabeReadFilePropertyDialog $LabelConfig1
		ComboBoxOwnerFilePropertyDialog $ComboBoxConfigIWidgets
		ComboBoxGroupFilePropertyDialog $ComboBoxConfigIWidgets
		ButtonBoxFilePropertyDialog $ButtonConfig1
		
#		.fileDialogProperties.filePropertyButtonBox configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
#		.fileDialogProperties.footerFrame configure -background $PPref(color,window,back)
#		.fileDialogProperties.footerFrame.filePropertyButtonBox configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -activeforeground $PPref(color,active,fore) -activebackground $PPref(color,active,back)
	}

	if {[winfo exist .settings]} {
		.settings configure -background $PPref(color,window,back)
		.settings.settingsTabNotebook.canvas.tabset.canvas configure -background $PPref(color,window,back)
		.settings.settingsTabNotebook.canvas.tabset configure -foreground $PPref(color,window,fore) -background $PPref(color,window,back)
		.settings.settingsTabNotebook.canvas.tabset tabconfigure 0 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -selectforeground $PPref(color,active,fore) -selectbackground $PPref(color,active,back)
		.settings.settingsTabNotebook.canvas.tabset tabconfigure 1 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -selectforeground $PPref(color,active,fore) -selectbackground $PPref(color,active,back)
		.settings.settingsTabNotebook.canvas.tabset tabconfigure 2 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -selectforeground $PPref(color,active,fore) -selectbackground $PPref(color,active,back)
		.settings.settingsTabNotebook.canvas.tabset tabconfigure 3 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -selectforeground $PPref(color,active,fore) -selectbackground $PPref(color,active,back)
		.settings.settingsTabNotebook.canvas.tabset tabconfigure 4 -foreground $PPref(color,window,fore) -background $PPref(color,window,back) -font $PPref(fonts,label) -selectforeground $PPref(color,active,fore) -selectbackground $PPref(color,active,back)
		.settings.settingsTabNotebook.canvas.notebook.cs.page1 configure -background $PPref(color,window,back)
		.settings.settingsTabNotebook.canvas.notebook.cs.page2 configure -background $PPref(color,window,back)
		.settings.settingsTabNotebook.canvas.notebook.cs.page3 configure -background $PPref(color,window,back)
		.settings.settingsTabNotebook.canvas.notebook.cs.page4 configure -background $PPref(color,window,back)
		.settings.settingsTabNotebook.canvas.notebook.cs.page5 configure -background $PPref(color,window,back)

		LabeledFrameMonitorDisplaySettings  configure -foreground $PPrefTmp(color,window,fore) -background $PPrefTmp(color,window,back) -labelfont $PPrefTmp(fonts,label)

		ScrolledListBoxColorSampleSettings configure -background $PPrefTmp(color,window,back)  -textbackground $PPrefTmp(color,widget,back) -selectforeground $PPrefTmp(color,selection,fore) -selectbackground $PPrefTmp(color,selection,back) -textfont $PPrefTmp(fonts,text)
		ButtonColorSampleSettings configure -background $PPrefTmp(color,window,back) -activeforeground $PPrefTmp(color,active,fore) -activebackground $PPrefTmp(color,active,back) -font $PPrefTmp(fonts,label)
		EntrySampleLabelSettings configure -foreground $PPrefTmp(color,window,fore) -background $PPrefTmp(color,window,back) -labelfont $PPrefTmp(fonts,label)
		EntrySampleLabelSettingsEntry configure -foreground $PPrefTmp(color,widget,fore) -background $PPrefTmp(color,widget,back)
		ScrolledListBoxColorSampleSettings clear
		ScrolledListBoxColorSampleSettings insert end "First Directory Entry"
		ScrolledListBoxColorSampleSettings insert end "Second Directory Entry"
		ScrolledListBoxColorSampleSettings itemconfigure 0 -foreground $PPrefTmp(color,directory)
		ScrolledListBoxColorSampleSettings itemconfigure 1 -foreground $PPrefTmp(color,directory)
		ScrolledListBoxColorSampleSettings insert end "First File Entry"
		ScrolledListBoxColorSampleSettings insert end "Second File Entry"
		ScrolledListBoxColorSampleSettings itemconfigure 2 -foreground $PPrefTmp(color,file)
		ScrolledListBoxColorSampleSettings itemconfigure 3 -foreground $PPrefTmp(color,file)
		LabeledFrameColorAdjustmentSettings $LabeledFrameConfig
		FrameColorAdjustMaster $FrameConfig
		FrameColorAdjustLeft $FrameConfig
		FrameRedSlider $FrameConfig
		LabelRedBackGround $LabelConfig1
		RedColorAdjustSlider $SliderScaleConfig
		EntryRedSettings $EntryConfig1
		FrameGreenSlider $FrameConfig
		LabelGreenBackGround $LabelConfig1
		GreenColorAdjustSlider $SliderScaleConfig
		EntryGreenSettings $EntryConfig1
		FrameBlueSlider $FrameConfig
		LabelBlueBackGround $LabelConfig1
		BlueColorAdjustSlider $SliderScaleConfig
		EntryBlueSettings $EntryConfig1
		DisplayParametersComboBoxSettings $ComboBoxConfigIWidgets
		LabeledFrameFontsSettings $LabeledFrameConfig
		EntryColorMonitorSettings configure -foreground $tmpcolor -background $tmpcolor -font $PPref(fonts,text)
		ScrolledListBoxFontFoundrySettings $ScrolledListBoxConfigIWidgets
		ScrolledListBoxFontFamilySettings $ScrolledListBoxConfigIWidgets
		ScrolledListBoxFontWeightSettings $ScrolledListBoxConfigIWidgets
		ScrolledListBoxFontSlantSettings $ScrolledListBoxConfigIWidgets
		ScrolledListBoxPointSizeSettings $ScrolledListBoxConfigIWidgets
		CheckButtonFontUnderlineSettings $CheckButtonConfig1
		CheckButtonFontOverstrikeSettings $CheckButtonConfig1
		ComboBoxFontsSettings $ComboBoxConfigIWidgets
		EntrySampleLabelSettings configure -foreground $PPrefTmp(color,window,fore) -background $PPrefTmp(color,window,back) -labelfont $PPrefTmp(fonts,label)
		EntrySampleLabelSettingsEntry configure -foreground $PPrefTmp(color,widget,fore) -background $PPrefTmp(color,widget,back) -font $PPrefTmp(fonts,text)
		EntrySampleLabelSettingsEntry delete 0 end
		EntrySampleLabelSettingsEntry insert end "The quick brown fox jumped over the lazy dog."
		ComboBoxFontsSettings clear list
		ComboBoxFontsSettings insert list end {Label Font} {Text Font} {Tool Tip Font}
		ComboBoxFontsSettingsEntry delete 0 end
		ComboBoxFontsSettingsEntry insert end "Label Font"
		LabeledFrameDateSettings $LabeledFrameConfig
		RadioButtonDateNoneSettings $RadioButtonConfig1
		FrameShortDateSettings $FrameConfig
		RadioButtonShortDate1Settings $RadioButtonConfig1
		RadioButtonShortDate2Settings $RadioButtonConfig1
		FrameLongDateSettings $FrameConfig
		RadioButtondLongDate1Settings $RadioButtonConfig1
		RadioButtondLongDate2Settings $RadioButtonConfig1
		FrameFullDateSettings $FrameConfig
		RadioButtonFullShortSettings $RadioButtonConfig1
		RadioButtonFullLongSettings $RadioButtonConfig1
		FrameFullAbrevDateSettings $FrameConfig
		RadioButtonFullAbrevShortSettings $RadioButtonConfig1
		RadioButtonFullAbrevLongSettings $RadioButtonConfig1
		EntryDateSeparaterSettings $EntryConfigIWidgets
		LabeledFrameTimeSettings $LabeledFrameConfig
		RadioButtonTimeNoneSettings $RadioButtonConfig1
		FrameLongTimeSettings $FrameConfig
		RadioButtonTimeLong12HrSettings $RadioButtonConfig1
		RadioButtonTimeLong24HrSettings $RadioButtonConfig1
		FrameShortTimeSettings $FrameConfig
		RadioButtonTimeShort12HrSettings $RadioButtonConfig1
		RadioButtonTimeShort24HrSettings $RadioButtonConfig1
		EntryTimeSeparaterSettings $EntryConfigIWidgets
		LabeledFrameWeekSettings $LabeledFrameConfig
		CheckButtonDayOfTheWeekSettings $CheckButtonConfig1
		EntryTimeSystemSettings $EntryConfigIWidgets
		ComboBoxNotifyRuntimeUserSettings $ComboBoxConfigIWidgets
		LabeledFrameFreeFactoryNotifyDirectoriesSettings $LabeledFrameConfig
		ScrolledListBoxFactoryNotifyDirectories $ScrolledListBoxConfigIWidgets
		FrameDirectoryEntry $FrameConfig
		SelectedDirectoryEntry $EntryConfigIWidgets
		ButtonGetNotifyDirectory $ButtonConfig1
		FrameNotifyDirectoryButton $FrameConfig
		ButtonNewDirectory $ButtonConfig1
		ButtonSaveDirectory $ButtonConfig1
		ButtonUpdateDirectory $ButtonConfig1
		ButtonRewriteInotifyStartupDirectory $ButtonConfig1
		ButtonDeleteDirectory $ButtonConfig1
		LabeledFrameFreeFactoryRunningProcessesSettings $LabeledFrameConfig
		ScrolledListBoxFactoryRunningProcesses $ScrolledListBoxConfigIWidgets
		NumberOfFFProcessesEntry $EntryConfigLabelIWidgets
		FrameRadioButtonRunningFFProcesses $FrameConfig
		RadioButtonUserProcessSettings $ButtonConfig1
		RadioButtonAllProcessSettings $ButtonConfig1
		ButtonFrameRunningFFProcesses $FrameConfig
		ButtonStartNotifyFreeFactory $ButtonConfig1
		ButtonRestartNotifyFreeFactory $ButtonConfig1
		ButtonStopNotifyFreeFactory $ButtonConfig1
		ButtonKillNotifyFreeFactory $ButtonConfig1
		LabeledFrameSelectionCompanyInfoSettings $LabeledFrameConfig
		CompanyNameSettingsEntry $EntryConfigIWidgets
		LabeledFrameFreeFactoryOptionsSettings $LabeledFrameConfig
		AppleDelaySettingsEntry $EntryConfigIWidgets
		LabeledFrameUserDefaultsSettings $LabeledFrameConfig
		FrameRadioButtonUserDefault1 $FrameConfig
		LabelFFMxProgramSettings $LabelConfig1
		RadioButtonFFMxProgramFFMPEGSettings $RadioButtonConfig1
		RadioButtonFFMxProgramFFMBCSettings $RadioButtonConfig1
		FrameRadioButtonUserDefault2 $FrameConfig
		LabelRunFromSettings $LabelConfig1
		RadioButtonRunFromUSRSettings $RadioButtonConfig1
		RadioButtonRunFromOptSettings $RadioButtonConfig1
		CheckButtonEnableFactorySettings $CheckButtonConfig1
		CheckButtonRemoveSourceSettings $CheckButtonConfig1
		CheckButtonRemoveLogsSettings $CheckButtonConfig1
		FrameRadioButtonUserDefault3 $FrameConfig
		LabelFTPTransferTypeSettings $LabelConfig1
		RadioButtonFTPTransferTypeASCSettings $RadioButtonConfig1
		RadioButtonFTPTransferTypeBINSettings $RadioButtonConfig1
		CheckButtonFTPDeleteAfterSettings $RadioButtonConfig1
		CheckButtonEnableEMailSettings $CheckButtonConfig1
		CheckButtonEnableFactoryLinkingSettings $CheckButtonConfig1
		FrameRadioButtonUserDefault8 $FrameConfig
		LabelFreeFactoryActionSettingsSettings $LabelConfig1
		RadioButtonFreeFactoryActionSettingsCopySettings $RadioButtonConfig1
		RadioButtonFreeFactoryActionSettingsEncodeSettings $RadioButtonConfig1
		LabeledFrameEmailSettings $LabeledFrameConfig
		SMTPEMailServerEntry $EntryConfigIWidgets
		EMailPortEntry $EntryConfigIWidgets
		EMailUserNameEntry $EntryConfigIWidgets
		EMailPasswordEntry $EntryConfigIWidgets
		FrameEMailTLS $FrameConfig
		LabelEMailTLSSettings $LabelConfig1
		RadioButtonEMailTLSYesSettings $RadioButtonConfig1
		RadioButtonEMailTLSNoSettings $RadioButtonConfig1
		EMailFromNameEntry $EntryConfigIWidgets
		EMailFromAddressEntry $EntryConfigIWidgets
		LabeledFrameFilePathSettings $LabeledFrameConfig
		FramePDFReaderPath $FrameConfig
		PDFReaderPathSettingsEntry $EntryConfigIWidgets
		ButtonPDFReaderPathSettings $ButtonConfig1
		LabeledFrameSelectionOptionsSettings $LabeledFrameConfig
		CheckButtonSelectAllTextSettings $CheckButtonConfig1
		LabeledFrameSelectionConfirmationsSettings $LabeledFrameConfig
		CheckButtonConfirmFileSavesSettings $CheckButtonConfig1
		CheckButtonConfirmFileDeletionSettings $CheckButtonConfig1
		LabeledFrameSelectionIconBarSettings $LabeledFrameConfig
		CheckButtonShowToolTipsSettings $CheckButtonConfig1
		FrameFooterSettings $FrameConfig
		ButtonOkSettings $ButtonConfig1
		ButtonApplySettings $ButtonConfig1
		ButtonRestoreSettings $ButtonConfig1
		ButtonResetSettings $ButtonConfig1
		ButtonCancelSettings $ButtonConfig1
	}

	if {[winfo exist .showLicense]} {
		.showLicense configure -background $PPref(color,window,back)
		ScrolledTextLicense $ScrolledTextBoxConfig
		ButtonCloseLicense $ButtonConfig1
	}
	if {[winfo exist .showAbout]} {
		.showAbout configure -background $PPref(color,window,back)
		FrameAboutFreeFactory $FrameConfig
		EntryTitleAboutFreeFactory $EntryConfig1
		EntryVersionAboutFreeFactory $EntryConfig1
		EntryByAboutFreeFactory $EntryConfig1
		EntryAuthorAboutFreeFactory $EntryConfig1
		EntryCopyrightAboutFreeFactory $EntryConfig1
		ButtonCloseAboutFreeFactory $ButtonConfig1
	}


}
#   End widgetUpdate                                                                                                  #
#######################################################################################################################

