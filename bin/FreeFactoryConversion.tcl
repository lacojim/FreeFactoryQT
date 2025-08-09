#!/bin/sh
# the next line restarts using tclsh\
exec tclsh "$0" "$@"
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
# Script Name:Conversion.tcl
#
#  This script converts the file passed in the SoureFileName variable
#  to a output file in a output directory with the audio and video
#  options specified in the factory. This script calls ffmpeg or
#  ffmbc to do the conversion.
########################################################################################
########################################################################################
########################################################################################
# 2025-07-13 Added options for 
# ForceFormat -f
# VideoProfile -profile:v
# VideoProfileLevel -level:v

proc ::main {argc argv} {
# Get notify variables passed from inotify passed from FreeFactoryNotify.sh
	set PassedVariables $argv
	global FactoryArray TotalFactories FactoryCounter FactoryCounter2 FactoryCounterUsed ConversionLog FFMxScript FFMxString FTPScript SourcePath SourceFileNameRoot SourceFileName OutputFileName FFMx_AVOptions SystemTime

	package require mime
	package require smtp

	set FFMxScript ""
	set FFMxString ""
	set FTPScript ""
	set ConversionLog ""
########################################################################################
# Write factory description, notification directory, file to be processed and
# the processed file name to standard out ie screen
	puts "*****************************************************************************************"
	puts "********************************* Report From *******************************************"
	puts "*************************** FreeFactoryConversion.tcl ***********************************"
# Parse out fields. Done in a manner that preserves directories or file names with spaces.
	puts "Checking for last / to parse out source directory path"
	set LastSlash [string last "/" $PassedVariables]
# Parse out Directory path, the first variable
	puts "Extracting source directory path"
	set SourcePath [string trim [string range $PassedVariables 0 $LastSlash]]
	puts "Extracted source directory path"
# Parse the file name
	puts "Extracting source file name"
	set SourceFileName [string trim [string range $PassedVariables [expr $LastSlash + 1] end]]
	puts "Extracted source file name"
	puts "============ Encoding: $SourcePath$SourceFileName"
# Get system time for logs
	GetLogTime
########################################################################################
#
# Start execute only if source file exists
	puts "============ Checking to see if source file name actually exists"
	if {[file exists "$SourcePath$SourceFileName"]} {
		puts "============ Yes source file name $SourcePath$SourceFileName actually exists"
# Strip file extension from file name
		puts "============ Stripping file extension from source file name"
		set ExtensionDelimiter [string last "." $SourceFileName]
		set SourceFileNameRoot [string range $SourceFileName 0 [expr $ExtensionDelimiter - 1]]
########################################################################################
# Set log file for this script
		set ConversionLog "/var/log/FreeFactory/$SourceFileName.log"
########################################################################################
		exec echo "*****************************************************************************************" >> $ConversionLog
		exec echo "********************************* Report From *******************************************" >> $ConversionLog
		exec echo "*************************** FreeFactoryConversion.tcl ***********************************" >> $ConversionLog
########################################################################################
		set FactoryCounter 0
########################################################################################
#
# Start Loading Factories into array
#
		puts "============ Loading in factory names"
		exec echo "============ Loading in factory names" >> $ConversionLog
# Load factories into array
		foreach item [lsort [glob -nocomplain /opt/FreeFactory/Factories/*]] {
			puts "============ Loading in factory $item"
			exec echo "============ Loading in factory $item" >> $ConversionLog
			incr FactoryCounter
			set FileHandle [open $item r]
			set FactoryArray($FactoryCounter,FactoryFileName) [file tail $item]
########################################################################################
#
# Start file open and while loop of reading each line
			while {![eof $FileHandle]} {
				gets $FileHandle FactoryVar
				set EqualDelimiter [string first "=" $FactoryVar]
				if {$EqualDelimiter>0 && [string first "#" [string trim $FactoryVar]]!=0} {
					set FactoryField [string trim [string range $FactoryVar 0 [expr $EqualDelimiter - 1]]]
					set FactoryValue [string trim [string range $FactoryVar [expr $EqualDelimiter + 1] end]]
					switch $FactoryField {
						"FACTORYDESCRIPTION" {set FactoryArray($FactoryCounter,FactoryDescription) $FactoryValue}
						"NOTIFYDIRECTORY" {set FactoryArray($FactoryCounter,NotifyDirectory) $FactoryValue}
						"OUTPUTDIRECTORY" {set FactoryArray($FactoryCounter,OutputDirectory) $FactoryValue}
						"OUTPUTFILESUFFIX" {set FactoryArray($FactoryCounter,OutputFileSuffix) $FactoryValue}
						"FFMXPROGRAM" {set FactoryArray($FactoryCounter,FFMxProgram) $FactoryValue}
						"RUNFROM" {set FactoryArray($FactoryCounter,RunFrom) $FactoryValue}
						"FTPPROGRAM" {set FactoryArray($FactoryCounter,FTPProgram) $FactoryValue}
						"FTPURL" {set FactoryArray($FactoryCounter,FTPURL) $FactoryValue}
						"FTPUSERNAME" {set FactoryArray($FactoryCounter,FTPUserName) $FactoryValue}
						"FTPPASSWORD" {
							set FactoryArray($FactoryCounter,FTPPassword) $FactoryValue
# This will decode the FTP password variable
#							set PasswordChars [string length $FactoryValue]
#							set DecodedPassword ""
#							for {set x 0} {$x < $PasswordChars} {incr x} {
#								set DecodedChar  [format %c [expr [scan [string index $FactoryValue $x] %c] - 128]]
#								append DecodedPassword $DecodedChar
#							}
#							set FactoryArray($FactoryCounter,FTPPassword) $DecodedPassword
						}
						"FTPREMOTEPATH" {set FactoryArray($FactoryCounter,FTPRemotePath) $FactoryValue}
						"FTPTRANSFERTYPE" {set FactoryArray($FactoryCounter,FTPTransferType) $FactoryValue}
						"FTPDELETEAFTER" {set FactoryArray($FactoryCounter,FTPDeleteAfter) $FactoryValue}
						"VIDEOCODECS" {set FactoryArray($FactoryCounter,VideoCodecs) $FactoryValue}
						"VIDEOWRAPPER" {set FactoryArray($FactoryCounter,VideoWrapper) $FactoryValue}
						"VIDEOFRAMERATE" {set FactoryArray($FactoryCounter,VideoFrameRate) $FactoryValue}
						"VIDEOPROFILE" {set FactoryArray($FactoryCounter,VideoProfile) $FactoryValue}
						"VIDEOPROFILELEVEL" {set FactoryArray($FactoryCounter,VideoProfileLevel) $FactoryValue}
						"VIDEOSIZE" {set FactoryArray($FactoryCounter,VideoSize) $FactoryValue}
						"VIDEOTARGET" {set FactoryArray($FactoryCounter,VideoTarget) $FactoryValue}
						"VIDEOTAGS" {set FactoryArray($FactoryCounter,VideoTags) $FactoryValue}
						"THREADS" {set FactoryArray($FactoryCounter,Threads) $FactoryValue}
						"ASPECT" {set FactoryArray($FactoryCounter,Aspect) $FactoryValue}
						"VIDEOBITRATE" {set FactoryArray($FactoryCounter,VideoBitRate) $FactoryValue}
						"VIDEOPRESET" {set FactoryArray($FactoryCounter,VideoPreset) $FactoryValue}
						"VIDEOSTREAMID" {set FactoryArray($FactoryCounter,VideoStreamID) $FactoryValue}
						"GROUPPICSIZE" {set FactoryArray($FactoryCounter,GroupPicSize) $FactoryValue}
						"BFRAMES" {set FactoryArray($FactoryCounter,BFrames) $FactoryValue}
						"FRAMESTRATEGY" {set FactoryArray($FactoryCounter,FrameStrategy) $FactoryValue}
						"FORCEFORMAT" {set FactoryArray($FactoryCounter,ForceFormat) $FactoryValue}
						"ENCODELENGTH" {set FactoryArray($FactoryCounter,EncodeLength) $FactoryValue}
						"STARTTIMEOFFSET" {set FactoryArray($FactoryCounter,StartTimeOffset) $FactoryValue}
						"AUDIOCODECS" {set FactoryArray($FactoryCounter,AudioCodecs) $FactoryValue}
						"AUDIOBITRATE" {set FactoryArray($FactoryCounter,AudioBitRate) $FactoryValue}
						"AUDIOSAMPLERATE" {set FactoryArray($FactoryCounter,AudioSampleRate) $FactoryValue}
						"AUDIOFILEEXTENSION" {set FactoryArray($FactoryCounter,AudioFileExtension) $FactoryValue}
						"AUDIOTAG" {set FactoryArray($FactoryCounter,AudioTag) $FactoryValue}
						"AUDIOCHANNELS" {set FactoryArray($FactoryCounter,AudioChannels) $FactoryValue}
						"AUDIOSTREAMID" {set FactoryArray($FactoryCounter,AudioStreamID) $FactoryValue}
						"MANUALOPTIONS" {set FactoryArray($FactoryCounter,ManualOptions) $FactoryValue}
						"MANUALOPTIONSINPUT" {set FactoryArray($FactoryCounter,ManualOptionsInput) $FactoryValue}
						"DELETESOURCE" {set FactoryArray($FactoryCounter,DeleteSource) $FactoryValue}
						"DELETECONVERSIONLOGS" {set FactoryArray($FactoryCounter,DeleteConversionLogs) $FactoryValue}
						"ENABLEFACTORY" {set FactoryArray($FactoryCounter,EnableFactory) $FactoryValue}
						"FREEFACTORYACTION" {set FactoryArray($FactoryCounter,FreeFactoryAction) $FactoryValue}
						"ENABLEFACTORYLINKING" {set FactoryArray($FactoryCounter,EnableFactoryLinking) $FactoryValue}
						"FACTORYLINKS" {set FactoryArray($FactoryCounter,FactoryLinks) $FactoryValue}
						"FACTORYENABLEEMAIL" {set FactoryArray($FactoryCounter,FactoryEnableEMail) $FactoryValue}
						"FACTORYEMAILNAME" {set FactoryArray($FactoryCounter,FactoryEMailsName) $FactoryValue}
						"FACTORYEMAILADDRESS" {set FactoryArray($FactoryCounter,FactoryEMailsAddress) $FactoryValue}
						"FACTORYEMAILMESSAGESTART" {
							set FactoryArray($FactoryCounter,FactoryEMailMessage) ""
							while {![eof $FileHandle] && $FactoryValue !="FACTORYEMAILMESSAGEEND"} {
								gets $FileHandle FactoryValue
								if {$FactoryValue != "FACTORYEMAILMESSAGEEND"} {
									append FactoryArray($FactoryCounter,FactoryEMailMessage) $FactoryValue
								}
							}
						}
					}
				}
			}
			close $FileHandle
#
# End file open and while loop of reading each line
########################################################################################
		}
		puts "============ Completed the loading of factories"
		exec echo "============ Completed the loading of factories" >> $ConversionLog
#
# End Loading Factories into array
########################################################################################

# Now scroll through the factories to see if the notify directory passed matches
# the directory stored in the factory.
		set FFMx_AVOptions ""
		set TotalFactories $FactoryCounter
########################################################################################
#
# Start for loop to search array
		puts "============ Searching for a notify directory match"
		exec echo "============ Searching for a notify directory match" >> $ConversionLog
		for {set FactoryCounter 1} {$FactoryCounter <= $TotalFactories} {incr FactoryCounter} {
########################################################################################
#
# Start notify directory match made
# Only check for match if factory is enabled.
			if {$FactoryArray($FactoryCounter,EnableFactory) == "Yes"} {
# If match occurs then assemble the AV options from the factory.
				if {$SourcePath == $FactoryArray($FactoryCounter,NotifyDirectory)} {
# A match of the notify directory has occurred 
# Check if the action is to be conversion or copy.
########################################################################################
# Make sure the copy of source file is complete.
					puts "============ Waiting for copy of source file to be completed"
					exec echo "============ Waiting for copy of source file to be completed" >> $ConversionLog
					after 5000
					set LastFileSize 0
					set FileSize [file size "$SourcePath$SourceFileName"]
					while {$FileSize != $LastFileSize} {
						after 3000
						set LastFileSize $FileSize
						set FileSize [file size "$SourcePath$SourceFileName"]
						after 2000
					}
					puts "============ Copy of source completed"
					exec echo "============ Copy of source completed" >> $ConversionLog
########################################################################################
					if {$FactoryArray($FactoryCounter,FreeFactoryAction) == "Encode"} {
						puts "============ Match found for $FactoryArray($FactoryCounter,NotifyDirectory)"
						exec echo "============ Match found for $FactoryArray($FactoryCounter,NotifyDirectory)" >> $ConversionLog
########################################################################################
# Start Parse traffic variables
# Example cm18000_3000_Jacks-Friendly-Vacation-Sale.mpg
# Spot Code
# cm commercial code
# id Ids
# pr Promos
# ps PSA
# pi Per Inquiries
# 18000 is a serial code assigned by the traffic system.
						puts "============ Initializing traffic variables"
						exec echo "============ Initializing traffic variables" >> $ConversionLog
						set TrafficSpotCode ""
						set TrafficSpotID ""
						set TrafficSpotRunTime ""
						puts "============ Checking if file is a traffic file"
						exec echo "============ Checking if file is a traffic file" >> $ConversionLog
# Find the first underscore
						set FirstUnderscorePos [string first "_" $SourceFileName]
# Check to see if there is an underscore. If there is not an underscore then 
# This is not a traffic file and we dont parse out anything.
						if {$FirstUnderscorePos > 0} {
# There is an underscore. Now lets look for the second.
							set SecondUnderscorePos [string first "_" $SourceFileName [expr $FirstUnderscorePos + 1]]
							if {$SecondUnderscorePos > 0} {
# Check to see if file starts with a traffic two letter prefix
								if {[string first "cm" $SourceFileName] == 0 || [string first "id" $SourceFileName] == 0 \
								|| [string first "pr" $SourceFileName] == 0 || [string first "ps" $SourceFileName] == 0 \
								|| [string first "pi" $SourceFileName] == 0} {
									puts "============ File is a traffic file"
									exec echo "============ File is a traffic file" >> $ConversionLog
# Extract two letter prefix
									set TrafficSpotCode [string range $SourceFileName 0 1]
									puts "============ Extracted Spot Code $TrafficSpotCode"
									exec echo "============ Extracted Spot Code $TrafficSpotCode" >> $ConversionLog
# Extract the Spot ID           	
									set TrafficSpotID [string range $SourceFileName 2 [expr $FirstUnderscorePos -1]]
									puts "============ Extracted Spot ID $TrafficSpotID"
									exec echo "============ Extracted Spot ID $TrafficSpotID" >> $ConversionLog
# Extract the Spot run time
									set TrafficSpotRunTime [string range $SourceFileName [expr $FirstUnderscorePos + 1] [expr $SecondUnderscorePos -1]]
									puts "============ Extracted Spot Run Time $TrafficSpotRunTime"
									exec echo "============ Extracted Spot Run Time $TrafficSpotRunTime" >> $ConversionLog
								} else {
									puts "============ File is not a traffic file"
									exec echo "============ File is not a traffic file" >> $ConversionLog
								}
							} else {
								puts "============ File is not a traffic file"
								exec echo "============ File is not a traffic file" >> $ConversionLog
							}
						} else {
							puts "============ File is not a traffic file"
							exec echo "============ File is not a traffic file" >> $ConversionLog
						}
# End Parse traffic variables
########################################################################################
# Set counter to the current one used here
						set FactoryCounterUsed $FactoryCounter
# Make sure the proper FFMx program is used
						FFMxProgramVariableErrorCheck
# Run the sub procedure to fill in A/V options, do the conversion and any FTP.
						FFMXOptionsFFMxConversionFTP
# End execution section
########################################################################################
# Start Factory Linking
						FactoryLinking
# End Factory Linking
########################################################################################
					} else {
# Do not convert but copy
						puts "============ Starting file copy of $SourcePath$SourceFileName to $FactoryArray($FactoryCounter,OutputDirectory)"
						exec echo "============ Starting file copy of $SourcePath$SourceFileName to $FactoryArray($FactoryCounter,OutputDirectory)" >> $ConversionLog
						file copy -force $SourcePath$SourceFileName $FactoryArray($FactoryCounter,OutputDirectory)
						puts "============ Finished copy of $SourcePath$SourceFileName to $FactoryArray($FactoryCounter,OutputDirectory)"
						exec echo "============ Finished copy of $SourcePath$SourceFileName to $FactoryArray($FactoryCounter,OutputDirectory)" >> $ConversionLog
########################################################################################
# Start Factory Linking
						FactoryLinking
# End Factory Linking
########################################################################################

					}
#
# End Free Factory Action condition statement
########################################################################################
########################################################################################
#
# Start clean up section
#
# If deletion of source file is yes then delete it.
					if {$FactoryArray($FactoryCounter,DeleteSource) == "Yes"} {
						if {[file exists "$SourcePath$SourceFileName"]} {
							puts "============ Removing source file $SourcePath$SourceFileName"
							exec echo "============ Removing source file $SourcePath$SourceFileName" >> $ConversionLog
# Remove the source file when done.
							file delete -force "$SourcePath$SourceFileName"
							puts "============ Source file $SourcePath$SourceFileName removed"
							exec echo "============ Source file $SourcePath$SourceFileName removed" >> $ConversionLog
# Checking to see if there is an Apple dot file.  If so then delete.
							if {[file exists "$SourcePath._$SourceFileName"]} {
								puts "============ A dot file exist removing $SourcePath._$SourceFileName"
								exec echo "============ A dot file exist removing $SourcePath._$SourceFileName" >> $ConversionLog
								file delete -force "$SourcePath._$SourceFileName"
								puts "============ Dot file $SourcePath._$SourceFileName removed"
								exec echo "============ Dot file $SourcePath._$SourceFileName removed" >> $ConversionLog
							}
						} else {
							puts "============ Source file $SourcePath$SourceFileName does not exits for removing"
							exec echo "============ Source file $SourcePath$SourceFileName does not exits for removing" >> $ConversionLog
						}
# Remove hidden, ".", dot files associated with the source file when done. Apple Computer written files.
					} else {
						puts "============ Leaving source file $SourcePath$SourceFileName"
						exec echo "============ Leaving source file $SourcePath$SourceFileName" >> $ConversionLog
					}
# Other Housekeeping
# If there was a FTP script created delete it.
					if {[file exists $FTPScript]} {
						puts "============ Removing FTP script file $FTPScript"
						exec echo "============ Removing FTP script file $FTPScript" >> $ConversionLog
						file delete -force $FTPScript
						puts "============ FTP script file $FTPScript removed"
						exec echo "============ FTP script file $FTPScript removed" >> $ConversionLog
					}
# Remove FFMx execution bash file
					if {[file exists $FFMxScript]} {
						puts "============ Removing FFMx script file $FFMxScript"
						exec echo "============ Removing FFMx script file $FFMxScript" >> $ConversionLog
						file delete -force $FFMxScript
						puts "============ FFMx script file $FFMxScript removed"
						exec echo "============ FFMx script file $FFMxScript removed" >> $ConversionLog
					}
					exec echo "Finished!!!!!!!!!!!" >> $ConversionLog
					exec echo "Screen output may contain more for log removal" >> $ConversionLog
					exec echo "If logs are deleted you won't be reading this" >> $ConversionLog
					exec echo "*****************************************************************************************" >> $ConversionLog
					exec echo "*****************************************************************************************" >> $ConversionLog
########################################################################################
# Start EMail Section

# Check to see if email is enabled and both list variables have list
# variable data in them
					if {$FactoryArray($FactoryCounter,FactoryEnableEMail) == "Yes" && $FactoryArray($FactoryCounter,FactoryEMailsName) != "" && $FactoryArray($FactoryCounter,FactoryEMailsAddress) != ""} {
# Load in email connection data from Free Factory config file
						set PrefFileHandle [open /opt/FreeFactory/FreeFactory.config r]
						while {![eof $PrefFileHandle]} {
							gets $PrefFileHandle PrefVar
							set EqualDelimiter [string first "=" $PrefVar]
							if {$EqualDelimiter>0 && [string first "#" [string trim $PrefVar]]!=0} {
								set PrefField [string trim [string range $PrefVar 0 [expr $EqualDelimiter - 1]]]
								set PrefValue [string trim [string range $PrefVar [expr $EqualDelimiter + 1] end]]
								switch $PrefField {
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
										set PrefVar ""
										while {![eof $PrefFileHandle] && $PrefVar !="GLOBALEMAILMESSAGEEND"} {
											gets $PrefFileHandle PrefVar
											if {$PrefVar != "GLOBALEMAILMESSAGEEND"} {
												append PPref(GlobalEMailMessage) $PrefVar
											}
										}
									}
								}
							}
						}
						close $PrefFileHandle
						set FROM "\"$PPref(SMTPEMailFromName)\" <$PPref(SMTPEMailFromAddress)>"
						set ListLength [llength $FactoryArray($FactoryCounter,FactoryEMailsName)]
						set TO ""
						for {set x 0} {$x < $ListLength} {incr x} {
							append TO "\"[lindex $FactoryArray($FactoryCounter,FactoryEMailsName) $x]\" <[lindex $FactoryArray($FactoryCounter,FactoryEMailsAddress) $x]>"
							if {$x < [expr $ListLength - 1]} {append TO ", "}
						}
						set SUBJECT "Free Factory Result"
						set Body "Hello:
	Free Factory is reporting a successful completion of $FactoryArray($FactoryCounter,FactoryFileName) processing $FactoryArray($FactoryCounter,FactoryDescription) and any factories linked to it.\n
Notify Directory: $SourcePath
Source File Name: $SourceFileName
Output Directory: $FactoryArray($FactoryCounter,OutputDirectory)
Output File: $OutputFileName\n
$FactoryArray($FactoryCounter,FactoryEMailMessage)\n
$PPref(GlobalEMailMessage)\n\n
********************************************
Thank you for using Free Fractory!!!!
Open Source on Linux
********************************************"
						 set EmailHandle [mime::initialize -canonical text/plain -string $Body]
						 smtp::sendmessage $EmailHandle \
						-servers [list $PPref(SMTPEMailServer)] -ports [list $PPref(SMTPEMailPort)] \
						-usetls $PPref(SMTPEMailTLS) \
						-username $PPref(SMTPEMailUserName) \
						-password $PPref(SMTPEMailPassword) \
						-header [list From "$FROM"] \
						-header [list To "$TO"] \
						-header [list Subject "$SUBJECT"] \
						-header [list Date "[clock format [clock seconds]]"]
						 mime::finalize $EmailHandle
					}
# End EMail Section
########################################################################################
# If deletion of logs is yes then delete FFMx log, ftp and Conversion logs if they exist.
					if {$FactoryArray($FactoryCounter,DeleteConversionLogs) == "Yes"} {
						puts "============ Remove Logs Is set to Yes"
# Remove conversion file if it exists.
						if {[file exists "$ConversionLog"]} {
							puts "============ Removing $ConversionLog"
							file delete -force "$ConversionLog"
							puts "============ $ConversionLog removed"
						}
					} else {
						puts "============ Log files not removed"
						puts "============ Look in /var/log/FreeFactory for log"
					}
					puts "============ Finished!!!!!!!!!!!"
					puts "*****************************************************************************************"
					puts "*****************************************************************************************"
#
# End clean up section
########################################################################################
				}
#
# End notify directory match made
########################################################################################
			}
#
# End conditional if factory is enabled
########################################################################################

		}
#
# End for loop to search array
########################################################################################
	} else {
		puts "============ No source file name $SourcePath$SourceFileName actually exists"
		puts "Exiting with error"
		puts "*****************************************************************************************"
		puts "*****************************************************************************************"
		exec echo "============ No source file name $SourcePath$SourceFileName actually exists" >> $ConversionLog
		exec echo "Exiting with error" >> $ConversionLog
		exec echo "*****************************************************************************************" >> $ConversionLog
		exec echo "*****************************************************************************************" >> $ConversionLog
		exit
	}
#
# End execute only if source file exists
########################################################################################
}
#
# End proc
########################################################################################
########################################################################################
########################################################################################
########################################################################################
# Start GetLogTime
#
########################################################################################
proc GetLogTime {} {
	global SystemTime
# This sets the End Date/Time Stamp for the log file
					set SystemTime ""
# Get month
					append SystemTime [clock format [clock seconds] -format %m]
					append SystemTime "-"
# Get day
					append SystemTime [clock format [clock seconds] -format %d]
					append SystemTime "-"
# Get year
					append SystemTime [clock format [clock seconds] -format %y]  "  "
# Get hour
					append SystemTime [clock format [clock seconds] -format %I]
					append SystemTime ":"
# Get minutes
					append SystemTime [clock format [clock seconds] -format %M]
					append SystemTime ":"
# Get seconds
					append SystemTime [clock format [clock seconds] -format %S] " "
# Append AM PM
					append SystemTime [clock format [clock seconds] -format %p]
}
#
# End GetLogTime
########################################################################################
########################################################################################
########################################################################################
#
# Start FFMXOptionsFFMxConversionFTP
#
proc FFMXOptionsFFMxConversionFTP {} {
	global FactoryArray TotalFactories FactoryCounter FactoryCounter2 FactoryCounterUsed ConversionLog FFMxScript FFMxString FTPScript SourcePath SourceFileNameRoot SourceFileName OutputFileName FFMx_AVOptions SystemTime

########################################################################################
########################################################################################
#
# Start Assemble A/V options
#
# FFMx means either ffmpeg or ffmbc
#
# This code section assembles the A/V options for FFMx in two ways.
# One way is appending to the FFMx_AVOptions string variable.  The
# other way is to create a variable for each parameter and it's value.
#
########################################################################################
# If variable is not null then add to options. Extra checking is done by trimming the string during
# condition checking to compare against single or  multiple spaces only instead of a null variable
	puts "============ Assembling A/V Options"
	exec echo "============ Assembling A/V Options" >> $ConversionLog
	set FFMx_AVOptions ""
	set OutputFileName $SourceFileNameRoot
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoCodecs)] != ""} {
		append FFMx_AVOptions "-c:v "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoCodecs) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoProfile)] != ""} {
		append FFMx_AVOptions "-profile:v "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoProfile) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoProfileLevel)] != ""} {
		append FFMx_AVOptions "-level:v "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoProfileLevel) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,OutputFileSuffix)] != ""} {
		append OutputFileName $FactoryArray($FactoryCounterUsed,OutputFileSuffix)
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoWrapper)] != ""} {
		append OutputFileName $FactoryArray($FactoryCounterUsed,VideoWrapper)
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoFrameRate)] != ""} {
		append FFMx_AVOptions "-r "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoFrameRate) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoSize)] != ""} {
		append FFMx_AVOptions "-s "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoSize) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoTarget)] != ""} {
		append FFMx_AVOptions "-target "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoTarget) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoTags)] != ""} {
		append FFMx_AVOptions "-vtag "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoTags) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,Threads)] != ""} {
		append FFMx_AVOptions "-threads "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,Threads) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,Aspect)] != ""} {
		append FFMx_AVOptions "-aspect "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,Aspect) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoBitRate)] != ""} {
		append FFMx_AVOptions "-b:v "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoBitRate) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoPreset)] != ""} {
		append FFMx_AVOptions "-vpre "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoPreset) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,VideoStreamID)] != ""} {
		append FFMx_AVOptions "-map "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,VideoStreamID) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,GroupPicSize)] != ""} {
		append FFMx_AVOptions "-g "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,GroupPicSize) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,BFrames)] != ""} {
		append FFMx_AVOptions "-bf "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,BFrames) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,FrameStrategy)] != ""} {
		append FFMx_AVOptions "-b_strategy "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,FrameStrategy) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,EncodeLength)] != ""} {
		append FFMx_AVOptions "-t "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,EncodeLength) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,StartTimeOffset)] != ""} {
		append FFMx_AVOptions "-ss "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,StartTimeOffset) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,AudioCodecs)] != ""} {
		append FFMx_AVOptions "-c:a "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,AudioCodecs) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,AudioBitRate)] != ""} {
		append FFMx_AVOptions "-b:a "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,AudioBitRate) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,AudioSampleRate)] != ""} {
		append FFMx_AVOptions "-ar "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,AudioSampleRate) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,AudioFileExtension)] != ""} {
		append OutputFileName $FactoryArray($FactoryCounterUsed,AudioFileExtension)
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,AudioTag)] != ""} {
		append FFMx_AVOptions "-atag "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,AudioTag) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,AudioChannels)] != ""} {
		append FFMx_AVOptions "-ac "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,AudioChannels) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,AudioStreamID)] != ""} {
		append FFMx_AVOptions "-map "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,AudioStreamID) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,ManualOptions)] != ""} {
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,ManualOptions) "
	}
	if {[string trim $FactoryArray($FactoryCounterUsed,ForceFormat)] != ""} {
		append FFMx_AVOptions "-f "
		append FFMx_AVOptions "$FactoryArray($FactoryCounterUsed,ForceFormat) "
	}	
#
# End Assemble A/V options
#
########################################################################################
########################################################################################
# Write factory description, notification directory, file to be processed and
# the processed file name to standard out ie screen
	puts "============ Start time:$SystemTime $FactoryArray($FactoryCounterUsed,FactoryDescription)"
# Write Date/Time Stamp, factory description, notify directory, source file and output file
# to log file.
	puts "============ $FactoryArray($FactoryCounterUsed,FactoryDescription) Initialized"
	puts "============ To: $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName"
	exec echo "============ $FactoryArray($FactoryCounterUsed,FactoryDescription) Initialized" >> $ConversionLog
	exec echo "============ Encoding: Encoding: $SourcePath$SourceFileName" >> $ConversionLog
	exec echo "============ To: $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName" >> $ConversionLog
	exec echo "============ Start time:$SystemTime $FactoryArray($FactoryCounterUsed,FactoryDescription)" >> $ConversionLog
########################################################################################
# Start execution section  Factory Linking
#
# This section executes the chosen FFMx program to do the conversion.
#
# FFMx means either ffmpeg or ffmbc
#
# Set FFMxScript file
	set FFMxScript /opt/FreeFactory/bin/FFMxScript-$SourceFileName.sh
# Determine where to run the FFMx program from.  Either /usr/bin or /opt/FreeFactory/bin.
	if {$FactoryArray($FactoryCounterUsed,RunFrom) == "usr"} {
		if {[string trim $FactoryArray($FactoryCounterUsed,ManualOptionsInput)] ne ""} {
		    set inputFlags "$FactoryArray($FactoryCounterUsed,ManualOptionsInput) "
		} else {
		    set inputFlags ""
		}
		set FFMxString "$FactoryArray($FactoryCounterUsed,FFMxProgram) -hide_banner -y $inputFlags-i \"$SourcePath$SourceFileName\" $FFMx_AVOptions \"$FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName\" 2>> \"$ConversionLog\""
	} else {
		if {[string trim $FactoryArray($FactoryCounterUsed,ManualOptionsInput)] ne ""} {
		    set inputFlags "$FactoryArray($FactoryCounterUsed,ManualOptionsInput) "
		} else {
		    set inputFlags ""
		}
		set FFMxString "$FactoryArray($FactoryCounterUsed,FFMxProgram) -hide_banner -y $inputFlags-i \"$SourcePath$SourceFileName\" $FFMx_AVOptions \"$FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName\" 2>> \"$ConversionLog\""
	}
# Write FFMx command to log
	exec echo  "########################################################################################################" >> $ConversionLog
	exec echo  "FFMx Command String:" >> $ConversionLog
	exec echo $FFMxString >> $ConversionLog
	exec echo  "########################################################################################################" >> $ConversionLog
########################################################################################
# Write the bash execution line to a file.
	set FileHandle [open "/opt/FreeFactory/bin/FFMxScript-$SourceFileName.sh" w]
# Write header
	puts "============ Writing FFMx bash script FFMxScript-$SourceFileName.sh"
	exec echo "============ Writing FFMx bash script FFMxScript-$SourceFileName.sh" >> $ConversionLog
	puts $FileHandle "#!/bin/bash"
	puts $FileHandle "# Temporary FFMx Program"
	puts $FileHandle "#"
	puts $FileHandle $FFMxString
	puts "============ Close file FFMxScript-$SourceFileName.sh"
	exec echo "============ Close file FFMxScript-$SourceFileName.sh" >> $ConversionLog
	close $FileHandle
	puts "============ Change permissions to execute FFMxScript-$SourceFileName.sh"
	exec echo "============ Change permissions to execute FFMxScript-$SourceFileName.sh" >> $ConversionLog
# Set permissions on file to execute
	exec chmod 00777 "/opt/FreeFactory/bin/FFMxScript-$SourceFileName.sh"
# Execute the FFMx script
	puts "============ Executing script FFMxScript-$SourceFileName.sh"
	exec echo "============ Executing script FFMxScript-$SourceFileName.sh" >> $ConversionLog
########################################################################################
# Execute the FFMx conversion program.
	exec $FFMxScript 2>> $ConversionLog
# End execution section  Factory Linking
########################################################################################
# Get system time for logs
	GetLogTime
########################################################################################
# Write Date/Time Stamp, factory description, notify directory, source file and output file
# to screen and log file.
# Write success and the converted file name and output path to standard out ie screen
	puts "============ Conversion successful of: $SourceFileName to $OutputFileName"
	puts "============ To the directory: $FactoryArray($FactoryCounterUsed,OutputDirectory)"
	puts "============ From the source: $FactoryArray($FactoryCounterUsed,NotifyDirectory)$SourceFileName"
	puts "============ End time on conversion:$SystemTime $FactoryArray($FactoryCounterUsed,FactoryDescription)"
# Write success and the converted file name and output path to conversion log file
	exec echo "============ Conversion successful of:$SourceFileName to $OutputFileName" >> $ConversionLog
	exec echo "============ To the directory: $FactoryArray($FactoryCounterUsed,OutputDirectory)" >> $ConversionLog
	exec echo "============ From the source: $FactoryArray($FactoryCounterUsed,NotifyDirectory)$SourceFileName" >> $ConversionLog
	exec echo "============ End time on conversion:$SystemTime $FactoryArray($FactoryCounterUsed,FactoryDescription)" >> $ConversionLog
########################################################################################
#
# This section if for FTP. An attempt is being made to find one
# FTP program that will work in all three FTP protocols currently
# used at WDTV.  Jim is doing a search for this.
#
# Set FTPScript to null. Will not try to delete below if set
# to null.
	set FTPScript ""
# Only execute this code for FTP if the URL and the FTP program name variables are not blank.
	if {[string trim $FactoryArray($FactoryCounterUsed,FTPProgram)] != "" && [string trim $FactoryArray($FactoryCounterUsed,FTPURL)] != ""} {
		puts "============ Starting FTP"
		exec echo "============ Starting FTP" >> $ConversionLog
# Set FTP script path
		set FTPScript "/opt/FreeFactory/bin/FTPScript-$OutputFileName.sh"
# This part only writes the variables out to the log file.
# and could be removed in the future
		set tmpstring "This is from Conversion.tcl before exec - $OutputFileName"
		exec bash -c "echo $tmpstring $OutputFileName" >> $ConversionLog
		set tmpstring "OutputDirectory="
		exec bash -c "echo $tmpstring $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName" >> $ConversionLog
		set tmpstring "User Name="
		exec bash -c "echo $tmpstring $FactoryArray($FactoryCounterUsed,FTPUserName)" >> $ConversionLog
		set tmpstring "Password= You are not suppose to see this"
		set tmpstring "URL="
		exec bash -c "echo $tmpstring $FactoryArray($FactoryCounterUsed,FTPURL)" >> $ConversionLog
		set tmpstring "User Description="
		exec bash -c "echo $tmpstring $FactoryArray($FactoryCounterUsed,FactoryDescription)" >> $ConversionLog
		set tmpstring "User Remote Path="
		exec bash -c "echo $tmpstring $FactoryArray($FactoryCounterUsed,FTPRemotePath)" >> $ConversionLog
		puts "============ Writing to FTP script $FTPScript"
		exec echo "============ Writing to FTP script $FTPScript" >> $ConversionLog
# Open path to it bash FTP script
		set FTPBashHandle [open $FTPScript w]
# Write header
		puts $FTPBashHandle "#!/bin/bash"
		puts $FTPBashHandle "# Temporary FTP Program"
		puts $FTPBashHandle "#"
# Write to depending on which FTP program is chosen
		if {[string trim $FactoryArray($FactoryCounterUsed,FTPProgram)] == "ftp"} {
			puts $FTPBashHandle "ftp -n $FactoryArray($FactoryCounterUsed,FTPURL) <<END_SCRIPT"
			puts $FTPBashHandle "quote USER $FactoryArray($FactoryCounterUsed,FTPUserName)"
			puts $FTPBashHandle "quote PASS $FactoryArray($FactoryCounterUsed,FTPPassword)"
			if {$FactoryArray($FactoryCounterUsed,FTPTransferType) == "bin"} {
				puts $FTPBashHandle "binary"
			}
			if {$FactoryArray($FactoryCounterUsed,FTPTransferType) == "asc"} {
				puts $FTPBashHandle "ascii"
			}
			if {[string trim $FactoryArray($FactoryCounterUsed,FTPRemotePath)] !=""} {
				puts $FTPBashHandle "cd $FactoryArray($FactoryCounterUsed,FTPRemotePath)"
			}
			puts $FTPBashHandle "put $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName"
			puts $FTPBashHandle "quit"
			puts $FTPBashHandle "END_SCRIPT"
		}
		if {[string trim $FactoryArray($FactoryCounterUsed,FTPProgram)] == "lftp"} {
			puts $FTPBashHandle "lftp -u $FactoryArray($FactoryCounterUsed,FTPUserName),$FactoryArray($FactoryCounterUsed,FTPPassword) $FactoryArray($FactoryCounterUsed,FTPURL) <<EOF"
			if {[string trim $FactoryArray($FactoryCounterUsed,FTPRemotePath)] !=""} {
				puts $FTPBashHandle "cd $FactoryArray($FactoryCounterUsed,FTPRemotePath)"
			}
			puts $FTPBashHandle "if_error 'FTPing to Host Failed'"
			puts $FTPBashHandle "mput $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName"
			puts $FTPBashHandle "quit 0"
			puts $FTPBashHandle "EOF"
			puts $FTPBashHandle "rm -f $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName"
		}
		if {[string trim $FactoryArray($FactoryCounterUsed,FTPProgram)] == "ncftp" && [string trim $FactoryArray($FactoryCounterUsed,FTPURL)] != ""} {
			puts $FTPBashHandle "ncftp -u $FactoryArray($FactoryCounterUsed,FTPUserName) -p $FactoryArray($FactoryCounterUsed,FTPPassword) $FactoryArray($FactoryCounterUsed,FTPURL) <<EOF"
			if {$FactoryArray($FactoryCounterUsed,FTPTransferType) == "bin"} {
				puts $FTPBashHandle "binary"
			}
			if {$FactoryArray($FactoryCounterUsed,FTPTransferType) == "asc"} {
				puts $FTPBashHandle "ascii"
			}
#			if {$FactoryArray($FactoryCounterUsed,FTPTransferType) == "bin"} {
#				puts $FTPBashHandle "bin"
#			}
			if {[string trim $FactoryArray($FactoryCounterUsed,FTPRemotePath)] !=""} {
				puts $FTPBashHandle "cd $FactoryArray($FactoryCounterUsed,FTPRemotePath)"
			}
			puts $FTPBashHandle "rm $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName"
			puts $FTPBashHandle "put $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName"
# Manual for ncftp uses close instead of bye.
			puts $FTPBashHandle "bye"
			puts $FTPBashHandle "EOF"
		}
		puts "============ Closing FTP script $FTPScript"
		exec echo "============ Closing FTP script $FTPScript" >> $ConversionLog
# Done writing close file handle
		close $FTPBashHandle
		puts "============ Setting permissions to execute on FTP script $FTPScript"
		exec echo "============ Setting permissions to execute on FTP script $FTPScript" >> $ConversionLog
# Set the permissions so it can be executed
		exec chmod 00777 $FTPScript
		puts "============ Executing FTP script $FTPScript"
		exec echo "============ Executing FTP script $FTPScript" >> $ConversionLog
# Execute the FTP script
		exec $FTPScript 2>> $ConversionLog
# After FTP delete output destination file if set to do so. 
		if {$FactoryArray($FactoryCounterUsed,FTPDeleteAfter) == "Yes"} {
			if {[file exists "$FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName"]} {
				puts "============ Removing output file $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName after FTP"
				exec echo "============ Removing output file $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName after FTP" >> $ConversionLog
				file delete -force "$FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName"
				puts "============ Output file $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName after FTP removed"
				exec echo "============ Output file $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName after FTP removed" >> $ConversionLog
			} else {
				exec echo "============ Tried to remove output file $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName after FTP but file was not found." >> $ConversionLog
			}
		} else {
			puts "============ Output file $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName remains after FTP"
			exec echo "============ Output file $FactoryArray($FactoryCounterUsed,OutputDirectory)$OutputFileName remains after FTP" >> $ConversionLog
		}
	} else {
		puts "============ FTP Not Selected"
		exec echo "============ FTP Not Selected" >> $ConversionLog
	}


#
# End FTP Section
########################################################################################
}
# End FFMXOptionsFFMxConversionFTP
########################################################################################
########################################################################################
########################################################################################
#
# Start FFMxProgramVariableErrorCheck
#
proc FFMxProgramVariableErrorCheck {} {
	global FactoryArray TotalFactories FactoryCounter FactoryCounter2 FactoryCounterUsed ConversionLog
					
########################################################################################
#  Report error to the screen and log then exit when conversion program is not set unless action is set to copy instead of convert.
	if {$FactoryArray($FactoryCounterUsed,FFMxProgram) == "" || ($FactoryArray($FactoryCounterUsed,FFMxProgram) !="ffmpeg" \
	&& $FactoryArray($FactoryCounterUsed,FFMxProgram) !="ffmbc" && $FactoryArray($FactoryCounterUsed,FreeFactoryAction) == "Encode")} {
		puts "*****************************************************************************************"
		puts "****************************** ERROR Report From ****************************************"
		puts "*************************** Conversion.tcl ***********************************"
		puts "============ ERROR - No Conversion was started on $SourceFileName"
		puts "============ Ending Conversion.tcl early because FFMx program is"
		puts "============ not set correctly in factory $FactoryArray($FactoryCounterUsed,FactoryDescription).  This variable"
		puts "============ must be set to either ffmpeg or ffmbc.  Run FreeFactory.tcl"
		puts "============ and save this factory with the Conversion Program variable"
		puts "============ set."
		puts "*****************************************************************************************"
		puts "*****************************************************************************************"
		exec echo "*****************************************************************************************" >> $ConversionLog
		exec echo "****************************** ERROR Report From ****************************************" >> $ConversionLog
		exec echo "*************************** Conversion.tcl ***********************************" >> $ConversionLog
		exec echo "============ ERROR - No Conversion was started on $SourceFileName" >> $ConversionLog
		exec echo "============ Ending Conversion.tcl early because FFMx program is" >> $ConversionLog
		exec echo "============ not set correctly in factory $FactoryArray($FactoryCounterUsed,FactoryDescription).  This variable" >> $ConversionLog
		exec echo "============ must be set to either ffmpeg or ffmbc.  Run FreeFactory.tcl" >> $ConversionLog
		exec echo "============ and save this factory with the Conversion Program variable" >> $ConversionLog
		exec echo "============ set." >> $ConversionLog
		exec echo "*****************************************************************************************" >> $ConversionLog
		exec echo "*****************************************************************************************" >> $ConversionLog
		exit
	}
}
# End FFMxProgramVariableErrorCheck
########################################################################################
########################################################################################
########################################################################################
# Start FactoryLinking
proc FactoryLinking {} {
	global FactoryArray TotalFactories FactoryCounter FactoryCounter2 FactoryCounterUsed ConversionLog FFMxScript FFMxString FTPScript SourcePath SourceFileNameRoot SourceFileName OutputFileName FFMx_AVOptions SystemTime

	puts "============ Checking for factory linking"
	exec echo "============ Checking for factory linking" >> $ConversionLog
	if {$FactoryArray($FactoryCounter,EnableFactoryLinking) == "Yes"} {
		set FactoryLinksList $FactoryArray($FactoryCounter,FactoryLinks)
		set ListLength [llength $FactoryLinksList]
		if {$ListLength > 0} {
			puts "============ Factory has links"
			exec echo "============ Factory has links" >> $ConversionLog
########################################################################################
# Start of For loop for list variable $FactoryArray($FactoryCounter,FactoryLinks)
			for {set x 0} {$x < $ListLength} {incr x} {
				for {set FactoryCounter2 1} {$FactoryCounter2 <= $TotalFactories} {incr FactoryCounter2} {
					if {$FactoryArray($FactoryCounter2,FactoryFileName) == [lindex $FactoryLinksList $x]} {
						break
					}
				}
# Get system time for logs
				GetLogTime
				puts "*****************************************************************************************"
				puts "********************************* Report From *******************************************"
				puts "*************************** FreeFactoryConversion.tcl ***********************************"
				puts "******************************** Factory Linking ****************************************"
				puts "============ Linking from $FactoryArray($FactoryCounter,FactoryDescription)"
				puts "============ Start time:$SystemTime $FactoryArray($FactoryCounter2,FactoryDescription)"
				exec echo "*****************************************************************************************" >> $ConversionLog
				exec echo "********************************* Report From *******************************************" >> $ConversionLog
				exec echo "*************************** FreeFactoryConversion.tcl ***********************************" >> $ConversionLog
				exec echo "******************************** Factory Linking ****************************************" >> $ConversionLog
				exec echo "============ Linking from $FactoryArray($FactoryCounter,FactoryDescription)" >> $ConversionLog
				exec echo "============ Start time:$SystemTime $FactoryArray($FactoryCounter2,FactoryDescription)" >> $ConversionLog
# Check to see if we convert or copy
				if {$FactoryArray($FactoryCounter2,FreeFactoryAction) == "Encode"} {
# Yes we convert
########################################################################################
# Set counter to the current one used here
					set FactoryCounterUsed $FactoryCounter2
# Make sure the proper FFMx program is used
					FFMxProgramVariableErrorCheck
# Run the sub procedure to fill in A/V options, do the conversion and any FTP.
					FFMXOptionsFFMxConversionFTP
#
# End FFMx and FTP Factory Linking Section
########################################################################################
				} else {
# Do not convert but copy
					puts "============ Starting file copy of $SourcePath$SourceFileName to $FactoryArray($FactoryCounter2,OutputDirectory)"
					exec echo "============ Starting file copy of $SourcePath$SourceFileName to $FactoryArray($FactoryCounter2,OutputDirectory)" >> $ConversionLog
					file copy -force $SourcePath$SourceFileName $FactoryArray($FactoryCounter2,OutputDirectory)
					puts "============ Finished copy of $SourcePath$SourceFileName to $FactoryArray($FactoryCounter2,OutputDirectory)"
					exec echo "============ Finished copy of $SourcePath$SourceFileName to $FactoryArray($FactoryCounter2,OutputDirectory)" >> $ConversionLog
				}
			}
			puts "*****************************************************************************************"
			puts "**************************** Finished Factory Linking ***********************************"
			puts "*****************************************************************************************"
			puts "*****************************************************************************************"
			exec echo "*****************************************************************************************" >> $ConversionLog
			exec echo "**************************** Finished Factory Linking ***********************************" >> $ConversionLog
			exec echo "*****************************************************************************************" >> $ConversionLog
			exec echo "*****************************************************************************************" >> $ConversionLog
# End of For loop for list variable $FactoryArray($FactoryCounter,FactoryLinks)
########################################################################################
		} else {
			puts "============ Factory has no links"
			exec echo "============ Factory has no links" >> $ConversionLog
		}
	} else {
		puts "============ Factory Linking not enabled"
		exec echo "============ Factory Linking not enabled" >> $ConversionLog
	}
}
# End Factory Linking
#
########################################################################################
########################################################################################
########################################################################################
########################################################################################
# Run procedure main above and pass the variables received from FreeFastoryNotify.sh
main $argc $argv
exit


