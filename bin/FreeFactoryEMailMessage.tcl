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
# Program:FreeFactoryEMailMessage.tcl
#
#
# This displays the GPL license for FreeFactory
################################################################################################
proc vTclWindow.freeFactoryEMailMessage {base} {

##########################
# Free Factory variables
	global FreeFactoryDataDirectoryPath FreeFactoryDataFileName SaveFilePath DeleteSource DeleteConversionLogs EnableFactory
	global FactoryDescription NotifyDirectoryEntry SelectedFactory OutputFileSuffixEntry FFMxProgram OutputDirectoryEntry
	global FTPProgram FTPURLEntry FTPUserNameEntry FTPPasswordEntry FTPRemotePathEntry FTPTransferType FTPDeleteAfter
	global RunFrom FactoryLinks FreeFactoryAction FactoryEnableEMail FactoryEMailNameEntry FactoryEMailAddressEntry FactoryEMailsName
	global FactoryEMailsAddress FactoryEMailMessage GlobalEMailMessage

	global PPref screenx screeny env

	set xCord [expr int(($screenx-575)/2)]
	set yCord [expr int(($screeny-425)/2)]
	if {$base == ""} {set base .freeFactoryEMailMessage}
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
	if {[winfo exists .settings]} {
		wm title $top "Global EMail Message"
	} else {
		wm title $top "EMail Message For $SelectedFactory"
	}
	vTcl:DefineAlias "$top" "Toplevel2" vTcl:Toplevel:WidgetProc "" 1
	bindtags $top "$top Toplevel all _TopLevel"
	vTcl:FireEvent $top <<Create>>
	wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"
	bind $top <Escape> {destroy window .freeFactoryEMailMessage}
#	bind $top <Key-KP_Enter> {destroy window .freeFactoryEMailMessage}
#	bind $top <Key-Return> {destroy window .freeFactoryEMailMessage}

	::iwidgets::scrolledtext $top.freeFactoryEMailMessageText -labelpos n -labeltext "EMail Message" \
	-exportselection 0 -height 5 -hscrollmode dynamic \
	-textbackground #fefefe -vscrollmode dynamic -width 10 -wrap word
	vTcl:DefineAlias "$top.freeFactoryEMailMessageText" "ScrolledTextFactoryEMailMessage" vTcl:WidgetProc "Toplevel2" 1
	pack $top.freeFactoryEMailMessageText -in $top -anchor nw -expand 1 -fill both -side top


	frame $top.factoryEMailMessageFrame -height 31 -relief flat -height 50 -borderwidth 0 -highlightthickness 0 -highlightcolor #e6e6e6
	vTcl:DefineAlias "$top.factoryEMailMessageFrame" "FrameFactoryEMailMessage" vTcl:WidgetProc "Toplevel1" 1

	set site_1_0 $top.factoryEMailMessageFrame

	button $site_1_0.loadFactoryEMailMessageButton \
	-activebackground #e6e6e6 -activeforeground #000000 \
	-background #e6e6e6 -command {

		set WindowName "Load Email Message From File"
		set ToolTip "Select File"
		set fileDialogOk "Cancel"
		set buttonImagePathFileDialog [vTcl:image:get_image [file join / usr local  FreeFactory Pics open.gif]]
		set fullDirPath $env(HOME)
		set FileSelectTypeList {
			{{Text files}  {*.txt}}
		}
		set returnFullPath ""
		source "/opt/FreeFactory/bin/FileDialog.tcl"
		Window show .fileDialog
		Window show .fileDialog
		widgetUpdate
		initFileDialog
		tkwait window .fileDialog
		if {$returnFullPath!=""} {
			set FileHandle [open $returnFullPath r]
			while {![eof $FileHandle]} {
				gets $FileHandle Message
				ScrolledTextFactoryEMailMessage insert end $Message\n
			}
		}
	} \
	-foreground #000000 -highlightbackground #e6e6e6 \
        -highlightcolor #000000 -image [vTcl:image:get_image [file join / opt FreeFactory Pics open32x32.gif]]
	vTcl:DefineAlias "$site_1_0.loadFactoryEMailMessageButton" "ButtonLoadFactoryEMailMessage" vTcl:WidgetProc "Toplevel2" 1
	pack $site_1_0.loadFactoryEMailMessageButton -in $site_1_0 -anchor center -expand 1 -fill none -side left
	balloon $site_1_0.loadFactoryEMailMessageButton "Load text from file."

	button $site_1_0.saveFactoryEMailMessageButton \
	-activebackground #e6e6e6 -activeforeground #000000 \
	-background #e6e6e6 -command {
		if {[winfo exists .settings]} {
			set PPref(GlobalEMailMessage) [ScrolledTextFactoryEMailMessage get 0.0 end]
			CheckForSettingsApplyEnable
		} else {
			set FactoryEMailMessage [ScrolledTextFactoryEMailMessage get 0.0 end]
		}
		destroy window .freeFactoryEMailMessage
	} \
	-foreground #000000 -highlightbackground #e6e6e6 \
	-highlightcolor #000000 -image [vTcl:image:get_image [file join / opt FreeFactory Pics gtk-save32x32.gif]]
	vTcl:DefineAlias "$site_1_0.saveFactoryEMailMessageButton" "ButtonSaveFactoryEMailMessage" vTcl:WidgetProc "Toplevel2" 1
	pack $site_1_0.saveFactoryEMailMessageButton -in $site_1_0 -anchor center -expand 1 -fill none -side left
	balloon $site_1_0.saveFactoryEMailMessageButton "Save Message and exit. But remember to\nactually save the message the factory or\nsettings must be saved."

	button $site_1_0.clearFactoryEMailMessageButton \
	-activebackground #e6e6e6 -activeforeground #000000 \
	-background #e6e6e6 -command {
		ScrolledTextFactoryEMailMessage delete 0.0 end
	} \
	-foreground #000000 -highlightbackground #e6e6e6 \
        -highlightcolor #000000 -image [vTcl:image:get_image [file join / opt FreeFactory Pics remove32x32.gif]]
	vTcl:DefineAlias "$site_1_0.clearFactoryEMailMessageButton" "ButtonClearFactoryEMailMessage" vTcl:WidgetProc "Toplevel2" 1
	pack $site_1_0.clearFactoryEMailMessageButton -in $site_1_0 -anchor center -expand 1 -fill none -side left
	balloon $site_1_0.clearFactoryEMailMessageButton "Clear current message."

	button $site_1_0.closeFactoryEMailMessageButton \
	-activebackground #e6e6e6 -activeforeground #000000 \
	-background #e6e6e6 -command {
		if {[winfo exists .settings]} {
			CheckForSettingsApplyEnable
		}
		destroy window .freeFactoryEMailMessage
	} \
	-foreground #000000 -highlightbackground #e6e6e6 \
	-highlightcolor #000000 -image [vTcl:image:get_image [file join / opt FreeFactory Pics exit32x32.gif]]
	vTcl:DefineAlias "$site_1_0.closeFactoryEMailMessageButton" "ButtonCloseFactoryEMailMessage" vTcl:WidgetProc "Toplevel2" 1
	pack $site_1_0.closeFactoryEMailMessageButton -in $site_1_0 -anchor center -expand 1 -fill none -side left
	balloon $site_1_0.closeFactoryEMailMessageButton "Close Window and discard changes"

	pack $top.factoryEMailMessageFrame -in $top -anchor nw -expand 0 -fill x -side top


	vTcl:FireEvent $base <<Ready>>
}
##########################################################################################
