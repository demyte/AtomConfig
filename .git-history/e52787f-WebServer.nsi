!define prodname "CALUMO 11 Web Server"
Name "${prodname}"

# Common parameters across installers
!define CalumoSoftware "CALUMO 11"
!define CalumoComponent "Webserver"
!define DefaultInstallationDirectory "c:\inetpub\wwwroot\calumo11\"

# Specific for this installer
!define SERVICE_NAME "CALUMO Remoting Service"
!define SERVICE_DESCRIPTION "CALUMO Remoting Service"
!define LegacyWebserverRegKey "SOFTWARE\Calumo Labs Pty Ltd\Settings"

!define MUI_WELCOMEPAGE_TITLE "CALUMO Web Server Setup"
!define MUI_UNCONFIRMPAGE_TEXT_TOP "WARNING: All files will be removed.$\r$\nIf you intend to reinstall on this machine please backup your published reports folder before you uninstall."

# Page objects
Var objInstallationDirectory
Var objInstallationDirectoryBrowse
Var objWebSiteName
Var objDBServer
Var objSSASServer
Var objLDAPserver
Var objLDAPconnection
Var objLDAPlogin
Var objLDAPpassword
Var objSupportEmail
Var objCreateFirewallException

# Page object return variables
Var WebSiteName
Var DBServer
Var SSASServer
Var LDAPserver
Var LDAPconnection
Var LDAPlogin
Var LDAPpassword
Var SupportEmail
Var CreateFirewallException

# Commandline install options
Var option_InstallPath
Var option_WebsiteName
Var option_SQLServer
Var option_SSASServer
Var option_LDAPServer
Var option_LDAPConnection
Var option_LDAPLoginName
Var option_LDAPPassword
Var option_SupportEmail

# Local Variables
Var mvcMapping
Var PreviousSiteName
Var CurrentSiteName
Var iisRootFolder
Var strMvcMappingScript
Var NewInstallation
Var InstalledVersion
Var fieldIndent
Var fieldWidth
Var fieldHeight
Var fieldTop
Var labelTop
Var IISVersion
Var Dialog
Var Image
Var ImageHandle
Var DialogTitle
Var TitleFont
Var iisInstalledLabel

!include CalumoCore.nsi
!include ServiceFunctions.nsi

##############################################################
##
##                 PRE-INSTALLATION PAGES
##
##############################################################
Page Custom ShowPrerequisites LeavePrerequisites
!insertmacro CalumoPrePages
Page Custom ShowDirectoryChooser LeaveDirectoryChooser
Page Custom ShowWebSiteInfo LeaveWebSiteInfo

#### 
# No longer required, but left here for when/if we do need it later on.
# Page Custom ShowOptionalInstallationTasks LeaveOptionalInstallationTasks
####

!insertmacro CalumoPostPages
!insertmacro CalumoCommonInit

#prerequisites

Function InitPrerequisites
	Call ConfigureInstallation
	Call CheckForVersionPriorTo119FlatAndQuitIfDiscovered
	Call IISVersion
	Call CheckDotNetVersion
	!insertmacro ExtractInstallerRequiredFiles
FunctionEnd

Function ShowPrerequisites

	Call InitPrerequisites

	nsDialogs::Create 1044
	Pop $Dialog
	SetCtlColors $Dialog "" "${MUI_BGCOLOR}"

	## left-hand CALUMO graphic
	${NSD_CreateBitmap} 0u 0u 109u 193u ""
	Pop $Image
	${NSD_SetImage} $Image $PLUGINSDIR\spltmp.bmp $ImageHandle

	## Title
	${NSD_CreateLabel} 120u 12u 195u 15u "Installation Prerequisites"
	Pop $DialogTitle
	SetCtlColors $DialogTitle "" "${MUI_BGCOLOR}"
	CreateFont $TitleFont "Tahoma" "14" "300"
	SendMessage $DialogTitle ${WM_SETFONT} $TitleFont 0

	## Version
	${NSD_CreateLabel} 120u 32u 195u 8u "Version ${VERSION}"
	Pop $mui.WelcomePage.Version
	SetCtlColors $mui.WelcomePage.Version 0x1D58B1 "${MUI_BGCOLOR}"
	CreateFont $mui.WelcomePage.Version.Font "Tahoma" "8" "300"
	SendMessage $mui.WelcomePage.Version ${WM_SETFONT} $mui.WelcomePage.Version.Font 0

	#-----start webserver specific ui
	${NSD_CreateLabel} 120u 55u 150u 8u "IIS (Web Server)"
	Pop $0
	SetCtlColors $0 "" "${MUI_BGCOLOR}"

	${if} $IISVersion == ""
		${NSD_CreateLabel} 280u 55u 42u 16u "not installed"
		Pop $iisInstalledLabel
		SetCtlColors $iisInstalledLabel "" "${MUI_BGCOLOR}"
	${else}
	   ${NSD_CreateLabel} 280u 55u 32u 16u "installed"
		Pop $iisInstalledLabel
		SetCtlColors $iisInstalledLabel "" "${MUI_BGCOLOR}"
	${endif}
	#-----end webserver specific ui

	# net4 label
	${NSD_CreateLabel} 120u 71u 150u 8u ".NET 4.5 Framework"
	Pop $0
	SetCtlColors $0 "" "${MUI_BGCOLOR}"

	${if} $DotNetInstalled != ""
		${NSD_CreateLabel} 280u 71u 32u 16u "installed"
		Pop $1
		SetCtlColors $1 "" "${MUI_BGCOLOR}"
	${else}
		${NSD_CreateLabel} 280u 71u 42u 16u "not installed"
		Pop $1
		SetCtlColors $1 "" "${MUI_BGCOLOR}"
	${endif}

	nsDialogs::Show

FunctionEnd

Function LeavePrerequisites
	Call IISVersion
	${if} $IISVersion == ""
		MessageBox MB_OK "IIS is not installed. Please install IIS now"
		abort
	${else}
		SendMessage $iisInstalledLabel ${WM_SETTEXT} 0 "STR:installed"
	${endif}

	Call InstallDotNetIfRequired
FunctionEnd



##############################################################
##
##                      PAGES FUNCTIONS
##
##############################################################

!macro NextLine
	IntOp $fieldTop $fieldTop + $fieldHeight
	IntOp $fieldTop $fieldTop + 2
	IntOp $labelTop $fieldTop + 3
!macroend

!macro NewSection
	IntOp $fieldTop $fieldTop + $fieldHeight
	IntOp $fieldTop $fieldTop + 8
	IntOp $labelTop $fieldTop + 3
!macroend

Function SetupPageControlStartLocation
	strcpy $fieldIndent 118
	strcpy $fieldWidth 330
	strcpy $fieldHeight 21
	strcpy $fieldTop 0
	IntOp $labelTop $fieldTop + 3
FunctionEnd


### Webserver Installation location Setup page
Function ShowDirectoryChooser

	Call SetupPageControlStartLocation

	nsDialogs::Create 1018

		${if} $CurrentSiteName != ""
			!insertmacro MUI_HEADER_TEXT "Upgrade Web Server" "Click 'Next' to continue"
		${else}
			!insertmacro MUI_HEADER_TEXT "Web Server Files Installation Location" "Please complete the following information"
		${endif}

		${NSD_CreateLabel} 0 $labelTop 200 19 "Select the installation directory:"

		!insertmacro NextLine

		# Create the input and browse button using a custom function
		${CalumoCreateDirRequest} $fieldTop "Title" "$INSTDIR" ""
		Pop $objInstallationDirectoryBrowse
		Pop $objInstallationDirectory

		${if} $CurrentSiteName != ""
			EnableWindow $objInstallationDirectoryBrowse 0
			EnableWindow $objInstallationDirectory 0
		${endif}

	nsDialogs::Show
FunctionEnd

Function LeaveDirectoryChooser
	${NSD_GetText} $objInstallationDirectory $INSTDIR
FunctionEnd


### Webserver Config Setup Page
Function ShowWebSiteInfo

	Call SetupPageControlStartLocation

	nsDialogs::Create 1018

	${if} $CurrentSiteName != ""
		!insertmacro MUI_HEADER_TEXT "Upgrade Web Server" "Click 'Install' to continue"
		${NSD_CreateLabel} 0 $labelTop $fieldIndent 16 "Website to upgrade"
		${NSD_CreateText} $fieldIndent $fieldTop $fieldWidth $fieldHeight $CurrentSiteName
		Pop $objWebSiteName
		EnableWindow $objWebSiteName 0
	${else}
		!insertmacro MUI_HEADER_TEXT "Configuration Settings" "Please complete the following information"

		${NSD_CreateLabel} 0 $labelTop $fieldIndent 16 "Web site name"
		${NSD_CreateText} $fieldIndent $fieldTop $fieldWidth $fieldHeight "Calumo11"
		Pop $objWebSiteName

		!insertmacro NewSection
		${NSD_CreateLabel} 0 $labelTop $fieldIndent 16 "SQL server name"
		${NSD_CreateText} $fieldIndent $fieldTop $fieldWidth $fieldHeight "localhost"
		Pop $objDBServer

		!insertmacro NextLine
		${NSD_CreateLabel} 0 $labelTop $fieldIndent 16 "SSAS server name"
		${NSD_CreateText} $fieldIndent $fieldTop $fieldWidth $fieldHeight "localhost"
		Pop $objSSASServer

		!insertmacro NewSection
		${NSD_CreateLabel} 0 $labelTop $fieldIndent 16 "LDAP server name"
		${NSD_CreateText} $fieldIndent $fieldTop $fieldWidth $fieldHeight "server.local"
		Pop $objLDAPserver

		!insertmacro NextLine
		${NSD_CreateLabel} 0 $labelTop $fieldIndent 16 "LDAP connection string"
		${NSD_CreateText} $fieldIndent $fieldTop $fieldWidth $fieldHeight "LDAP://server.local"
		Pop $objLDAPconnection

		!insertmacro NextLine
		${NSD_CreateLabel} 0 $labelTop $fieldIndent 16 "LDAP login ID"
		${NSD_CreateText} $fieldIndent $fieldTop 140 $fieldHeight ""
		Pop $objLDAPlogin

		!insertmacro NextLine
		${NSD_CreateLabel} 0 $labelTop $fieldIndent 16 "LDAP password"
		${NSD_CreatePassword} $fieldIndent $fieldTop 140 $fieldHeight ""
		Pop $objLDAPpassword

		!insertmacro NewSection
		${NSD_CreateLabel} 0 $labelTop $fieldIndent 16 "Support email"
		${NSD_CreateText} $fieldIndent $fieldTop 140 $fieldHeight "support@calumo.com"
		Pop $objSupportEmail

		${NSD_SetFocus} $objWebSiteName
	${endif}

	nsDialogs::Show
FunctionEnd

Function LeaveWebSiteInfo

	${NSD_GetText} $objWebSiteName $WebSiteName
	${if} $CurrentSiteName == ""
		${NSD_GetText} $objDBServer $DBServer
		${NSD_GetText} $objSSASServer $SSASServer
		${NSD_GetText} $objLDAPserver $LDAPserver
		${NSD_GetText} $objLDAPconnection $LDAPconnection
		${NSD_GetText} $objLDAPlogin $LDAPlogin
		${NSD_GetText} $objLDAPpassword $LDAPpassword
		${NSD_GetText} $objSupportEmail $SupportEmail
	${endif}
FunctionEnd

### Optional Installation Tasks Page
Function ShowOptionalInstallationTasks

	Call SetupPageControlStartLocation

	nsDialogs::Create 1018

	!insertmacro MUI_HEADER_TEXT "Optional Installation Tasks" "Please select which tasks you want the installer to perform."

#	${NSD_CreateLabel} 0 $labelTop 400 16 "Create Windows Firewall Exceptions:"
#	${NSD_CreateCheckbox} 415 $labelTop 20 $fieldHeight ""
#	Pop $objCreateFirewallException

#	${NSD_SetState} $objCreateFirewallException ${BST_CHECKED}

	nsDialogs::Show
FunctionEnd

Function LeaveOptionalInstallationTasks
#	${NSD_GetState} $objCreateFirewallException $CreateFirewallException
FunctionEnd

##############################################################
##
##					SHARED FUNCTIONS & MACROS
##
##############################################################

Function PrintInstallVariables
	LogEx::Write true  "INSTALLER VARIABLES:"
	LogEx::Write true  "        Website Name: $WebSiteName"
	LogEx::Write true  "        SQL Database Server: $DBServer"
	LogEx::Write true  "        SSAS Database Server: $SSASServer"
	LogEx::Write true  "        LDAP Server: $LDAPserver"
	LogEx::Write true  "        LDAP Connection String: $LDAPconnection"
	LogEx::Write true  "        LDAP Login: $LDAPlogin"
	LogEx::Write true  "        LDAP Password: $LDAPpassword"
	LogEx::Write true  "        Support Email: $SupportEmail"
FunctionEnd

Function InitialiseVariables
	# Following values will be empty on a silent install, so make sure they have some defaults
	# this is only for the case where a silent install is run without having the product already
	# installed

	${if} $WebSiteName == ""
		ReadRegStr $CurrentSiteName HKLM "${RegKey}" SiteName

		${if} $CurrentSiteName == ""
			${if} $option_WebsiteName == ""
				StrCpy $WebSiteName "Calumo11"
			${else}
				StrCpy $WebSiteName $option_WebsiteName
			${endif}
		${else}
			StrCpy $WebSiteName $CurrentSiteName
		${endif}
	${endif}

	${if} $DBServer == ""
		${if} $option_SQLServer == ""
			StrCpy $DBServer "localhost"
		${else}
			StrCpy $DBServer $option_SQLServer
		${endif}
	${endif}

	${if} $SSASServer == ""
		${if} $option_SSASServer == ""
			StrCpy $SSASServer "localhost"
		${else}
			StrCpy $SSASServer $option_SSASServer
		${endif}
	${endif}

	${if} $LDAPserver == ""
		${if} $option_LDAPserver == ""
			StrCpy $LDAPserver "server.local"
		${else}
			StrCpy $LDAPserver $option_LDAPserver
		${endif}
	${endif}

	${if} $LDAPconnection == ""
		${if} $option_LDAPconnection == ""
			StrCpy $LDAPconnection "LDAP://server.local"
		${else}
			StrCpy $LDAPconnection $option_LDAPconnection
		${endif}
	${endif}

	${if} $LDAPlogin == ""
		${if} $option_LDAPLoginName == ""
			StrCpy $LDAPlogin "needusername"
		${else}
			StrCpy $LDAPlogin $option_LDAPLoginName
		${endif}
	${endif}

	${if} $LDAPpassword == ""
		${if} $option_LDAPPassword == ""
			StrCpy $LDAPpassword "needuserpassword"
		${else}
			StrCpy $LDAPpassword $option_LDAPPassword
		${endif}
	${endif}

	${if} $SupportEmail == ""
		${if} $option_SupportEmail == ""
			StrCpy $SupportEmail "support@calumo.com"
		${else}
			StrCpy $SupportEmail $option_SupportEmail
		${endif}
	${endif}

	## Find the version of IIS
	Call IISVersion
FunctionEnd

## This function is called from either the first page in a manual install or from the install section in
## a silent install so that all the defaults are setup correctly
Function ConfigureInstallation

   ## Check to see if the INSTDIR has been set, if it hasn't we configure the installation defaults
   ${if} $INSTDIR == ""
	   LogEx::Write false "Checking for legacy registry entry at: ${LegacyWebserverRegKey}"
	   ReadRegStr $PreviousSiteName HKLM "${LegacyWebserverRegKey}" Calumo11SiteName

	   LogEx::Write false "Checking for current registry entry at: ${REGKEY}"
	   ReadRegStr $CurrentSiteName HKLM "${REGKEY}" SiteName

	   # Check to see if an older incompatible version was installed (These would be pre 11.4)
	   ${if} $PreviousSiteName != ""
		   ${if} $CurrentSiteName == ""
			   MessageBox MB_OK|MB_ICONSTOP "An older CALUMO 11 Web Server has already been installed on this machine.  It must be uninstalled before running this installer."
			   Quit
		   ${endif}
	   ${endif}

	   # Get the current installation path if one is available
	   ReadRegStr $INSTDIR HKLM "${REGKEY}" "InstallationPath"

	   ${if} $INSTDIR == ""
		   # New install
						${if} $option_InstallPath == ""
								StrCpy $INSTDIR "${DefaultInstallationDirectory}"
						${else}
								StrCpy $INSTDIR "$option_InstallPath"
						${endif}

						StrCpy $NewInstallation "true"
	   ${else}
		   # Upgrade
		   ReadRegStr $InstalledVersion HKLM "${RegKey}" "Version"

		   StrCpy $NewInstallation "false"
	   ${endif}
   ${endif}
FunctionEnd

Function MaintenanceTasks
	## Perform any general tasks that all installers will perform
	Call GeneralMaintenanceTasks
FunctionEnd

!macro CreateIISVDirScript
	LogEx::Write true  "Creating $INSTDIR\createIISVDir.vbs";

	FileOpen $0 "$INSTDIR\createIISVDir.vbs" w

	FileWrite $0 "On Error Resume Next$\n$\n"
	FileWrite $0 "Set Root = GetObject($\"IIS://LocalHost/W3SVC/1/ROOT$\")$\n"
	FileWrite $0 "Set Dir = Root.Create($\"IIsWebVirtualDir$\", $\"$WebSiteName$\")$\n$\n"
	FileWrite $0 "If (Err.Number <> 0) Then$\n"
	FileWrite $0 " Wscript.Quit (Err.Number)$\n"
	FileWrite $0 "End If$\n$\n"
	FileWrite $0 "Dir.Path = $\"$INSTDIR$\"$\n"
	FileWrite $0 "Dir.AccessRead = True$\n"
	FileWrite $0 "Dir.AccessWrite = False$\n"
	FileWrite $0 "Dir.AccessScript = True$\n"
	FileWrite $0 "Dir.AppFriendlyName = $\"$WebSiteName$\"$\n"
	FileWrite $0 "Dir.AuthFlags = 4$\n"
	FileWrite $0 "Dir.EnableDirBrowsing = False$\n"
	FileWrite $0 "Dir.ContentIndexed = False$\n"
	FileWrite $0 "Dir.DontLog = True$\n"
	FileWrite $0 "Dir.EnableDefaultDoc = True$\n"
	FileWrite $0 "Dir.DefaultDoc = $\"container.aspx$\"$\n"
	FileWrite $0 "Dir.AspBufferingOn = True$\n"
	FileWrite $0 "Dir.AspAllowSessionState = True$\n"
	FileWrite $0 "Dir.AspSessionTimeout = 30$\n"
	FileWrite $0 "Dir.AspScriptTimeout = 900$\n"
	FileWrite $0 "Dir.SetInfo$\n$\n"

	FileWrite $0 "Set IISObject = GetObject($\"IIS://LocalHost/W3SVC/1/ROOT/$WebSiteName$\")$\n$\n"
	FileWrite $0 "IISObject.AppCreate2(1) 'Create an out-of-process web application$\n"
	FileWrite $0 "If (Err.Number <> 0) Then$\n"
	FileWrite $0 " MsgBox $\"Error trying to create the application at 'IIS://LocalHost/W3SVC/1/ROOT/$WebSiteName'$\"$\n"
	FileWrite $0 " WScript.Quit (Err.Number)$\n"
	FileWrite $0 "End If$\n"
	FileClose $0
!macroend

!macro DeleteIISVDirScript
	LogEx::Write true  "Creating $INSTDIR\deleteIISVDir.vbs";

	FileOpen $0 "$INSTDIR\deleteIISVDir.vbs" w
	FileWrite $0 'Set IISVirtualDir = GetObject("IIS://LocalHost/W3SVC/1/ROOT/$WebSiteName" )$\n'
	FileWrite $0 "Set parent = GetObject(IISVirtualDir.Parent)$\n"
	FileWrite $0 "parent.Delete IISVirtualDir.Class, IISVirtualDir.Name$\n"
	FileWrite $0 "parent.SetInfo$\n"
	FileClose $0

!macroend

!macro CreateSetMvcMappingScript
	FileOpen $0 "$INSTDIR\setMvcMapping.vbs" w
	FileWrite $0 'Set objFSO = CreateObject("Scripting.FileSystemObject")$\n'
	FileWrite $0 'Set objShell = CreateObject("WScript.Shell")$\n'
	FileWrite $0 'osType = objShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE")$\n'
	FileWrite $0 'If (osType <> "x86") Then$\n'
	FileWrite $0 'bits = "64"$\n'
	FileWrite $0 'End If$\n'
	StrCpy $mvcMapping 'strcommandline = "$INSTDIR\chglist.vbs W3SVC/1/root/$WebSiteName/ScriptMaps """" "".mvc,C:\windows\Microsoft.NET\Framework" + bits + "\v4.0.30319\aspnet_isapi.dll,1"" /INSERT /COMMIT"$\n'
	FileWrite $0 $mvcMapping
	FileWrite $0 'objShell.Run(strcommandline)$\n'
	FileClose $0
!macroend

!macro EnableASPNetApplicationInIIS6
	FileOpen $0 "$INSTDIR\enableaspnet.vbs" w
	FileWrite $0 'Set w3svc = GetObject( "IIS://localhost/w3svc" )$\n'
	FileWrite $0 'w3svc.EnableApplication("ASP.NET v4.0.30319")$\n'
	FileClose $0
!macroend

Function IISVersion
	ReadRegStr $IISVersion HKLM Software\Microsoft\InetStp "MajorVersion"
FunctionEnd

Function CheckForVersionPriorTo119FlatAndQuitIfDiscovered
	## Added check in 11.9.5.0 as we have removed support for OLD reports (Prioer to 11.9.0)
	## If we are on a version before 11.9.0 an upgrade must be performed to 11.9.4.x before 11.9.5.x
	## This is so that they cen get at OLD reports and re-publish them before loasing them in 11.9.5

	${if} $InstalledVersion != ""
		## Compare the version numbers to see which is newer (http://nsis.sourceforge.net/Docs/AppendixE.html#E.3.16)
		${VersionCompare} "$InstalledVersion" "11.9.0.0" $R0

		## If 11.9.0 is newer it means they have a prior version installed and we need to stop the installation with a message.
		${if} $R0 == "2"
			MessageBox MB_OK "The version you have installed, $InstalledVersion, can not be upgraded directly to versions greater than 11.9.5.0.$\r$\n$\r$\nYou must upgrade to CALUMO 11.9.4.x first and republish all web based published reports.$\r$\n$\r$\n For more information please see:$\r$\n$\t https://help.calumo.com/display/C1195/Upgrade+From+Prior+11.9.0.0+Version"
			Quit
		${endif}
	${endif}
FunctionEnd

##############################################################
##
##                      COMMAND LINE INSTALL FUNCTIONS
##
##############################################################
Function DisplayCommandLineArgsHelp

		StrCpy $1 "calumo11webserver.exe [Main Options] [Additional Options]$\n$\n"
		StrCpy $1 "$1Main command line installation options:$\n"
		StrCpy $1 "$1   /? - Shows this help text$\n"
		StrCpy $1 "$1   /S - Perform a silent, user interface less installation$\n$\n"
		StrCpy $1 "$1Additional command line installation options:$\n"
		StrCpy $1 "$1   /InstallPath - The directory in which to install$\n"
		StrCpy $1 "$1   /WebsiteName - The name of the website in IIS$\n"
		StrCpy $1 "$1   /SQLServer - The name of the SQL Server$\n"
		StrCpy $1 "$1   /SSASServer - The name of the Analysis Services Server$\n"
		StrCpy $1 "$1   /LDAPServer - The name of the LDAP Server$\n"
		StrCpy $1 "$1   /LDAPConnection - The connection string for LDAP queries$\n"
		StrCpy $1 "$1   /LDAPLoginName - The name of AD account to login with for LDAP$\n"
		StrCpy $1 "$1   /LDAPPassword - The password for the AD LDAP account$\n"
		StrCpy $1 "$1   /SupportEmail - The email address to send support issues to$\n$\n"
		StrCpy $1 "$1Notes:$\n"
		StrCpy $1 "$1 - Please ensure that the pre-requisites .NET 4.5 and IIS are installed beforehand$\n"
		StrCpy $1 "$1 - Setting install values via command line is only supported with new installations$\n"
		StrCpy $1 "$1 - Setting install values via command line is only supported with a silent install /S$\n"
		StrCpy $1 "$1 - All additionalvoptions are in the form of /option=value$\n"
		StrCpy $1 "$1        e.g. /SQLServer=MySQLServer01.domain$\n"
		StrCpy $1 "$1 - Excluded options will be given default values as detailed in the CALUMO$\n"
		StrCpy $1 "$1    Installation and Requirements Guide.$\n"

		MessageBox MB_OK $1

FunctionEnd

Function PromptForUAC
	!insertmacro RequestUACElevation
FunctionEnd

Function ParseParameters
		${GetOptions} $cmdLineParams "/InstallPath=" $option_InstallPath
		${GetOptions} $cmdLineParams "/WebsiteName=" $option_WebsiteName
		${GetOptions} $cmdLineParams "/SQLServer=" $option_SQLServer
		${GetOptions} $cmdLineParams "/SSASServer=" $option_SSASServer
		${GetOptions} $cmdLineParams "/LDAPServer=" $option_LDAPServer
		${GetOptions} $cmdLineParams "/LDAPConnection=" $option_LDAPConnection
		${GetOptions} $cmdLineParams "/LDAPLoginName=" $option_LDAPLoginName
		${GetOptions} $cmdLineParams "/LDAPPassword=" $option_LDAPPassword
		${GetOptions} $cmdLineParams "/SupportEmail=" $option_SupportEmail

		StrCpy $1 "InstallPath=$option_InstallPath$\n"
		StrCpy $1 "$1WebsiteName=$option_WebsiteName$\n"
		StrCpy $1 "$1SQLServer=$option_SQLServer$\n"
		StrCpy $1 "$1SSASServer=$option_SSASServer$\n"
		StrCpy $1 "$1LDAPServer=$option_LDAPServer$\n"
		StrCpy $1 "$1LDAConnection=$option_LDAPConnection$\n"
		StrCpy $1 "$1LDAPLoginName=$option_LDAPLoginName$\n"
		StrCpy $1 "$1LDAPPassword=$option_LDAPPassword$\n"
		StrCpy $1 "$1SupportEmail=$option_SupportEmail$\n"

		## MessageBox MB_OK $1
FunctionEnd

##############################################################
##
##				INSTALLATION FUNCTIONS
##
##############################################################

!macro ExtractWebInstallerRequiredFiles
	File /oname=$PLUGINSDIR\web.config.install.template ..\..\templates\web.config.install.template
	File /oname=$PLUGINSDIR\server.config.install.template.json ..\..\templates\server.config.install.template.json
!macroend

Function ExtractFiles
	${LogHeading} "EXTRACTING INSTALLATION FILES"

	!insertmacro ExtractInstallerRequiredFiles
	!insertmacro ExtractWebInstallerRequiredFiles

	Call ExtractInstallationFiles
FunctionEnd

Function IISReset
	${LogHeading} "RESTARTING INTERNET INFORMATION SERVICES (IIS)"

	${popOnStackAndExecute} 'iisreset'
FunctionEnd

Function DeleteAllExceptConfigs
	${LogHeading} "CLEANING DIRECTORY IN PREPARATION FOR UPGRADE"

	${popOnStackAndExecute} 'obiwan delete_all_except_configs "$INSTDIR\bin"'
	
	#all directories cleaned out except for license	and PublishedReports
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\Admin"'
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\ClientInstall"'
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\Editors"'
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\help"'
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\images"'
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\Properties"'
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\Scripts"'
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\Stylesheets"'
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\Viewers"'
	${popOnStackAndExecute} 'obiwan delete_folder "$INSTDIR\Views"'
FunctionEnd

Function CheckInstallationPreRequisites
	${LogHeading} "CHECKING SERVER PRE-REQUISITES:"

	Call GetNetFrameworkInstallPath

	## Always do the IIS components check
	${popOnStackAndExecute} 'obiwan checkiisprereq "CheckComponents" "$IISVersion"'

	# 11.4 doesn't have a site name in registry, so installer was erroneously assuming
	# that this was a new installation.
	# So now, check if existing assembly files have version of 11.4 and if so, ensure we upgrade.

	LogEx::Write false "Checking if version 11.4 is installed..."
	ExecDos::exec /TOSTACK 'obiwan getver "$INSTDIR\bin\Calumo.Core.dll"'
	Pop $0
	Pop $1
	Pop $2
	LogEx::Write false "Return Code: $0"
	LogEx::Write false "Detected Version: $2"

	StrCpy $0 $2 5

	${if} $0 == "11.4."
		StrCpy $NewInstallation "false"
	${endif}

	## Upgrade v's New install
	${if} $NewInstallation == "false"
		# Upgrade...
		LogEx::Write true ""
		LogEx::Write true "Checking that the CALUMO Website directory exists to be upgraded..."

		## Check for the existance of the web.config to tell us if the directory exists or not
		IfFileExists "$INSTDIR\web.config" InstallationExists 0
			LogEx::Write true "The CALUMO website directory does not exist in the specified location: $INSTDIR"
			LogEx::Write true "Performing an upgrade of CALUMO to a directory that does not exist or contain a CALUMO installation is not supported.");
			LogEx::Write true "The installation is unable to proceed at this time."

			## Pop a non zero code on the stack to indicate a failure
			Push 1
			Call AbortOrContinue
		InstallationExists:

		#####
		LogEx::Write true ""
		LogEx::Write true "Checking that the CALUMO Website exists in IIS"
		${popOnStackAndExecute} 'obiwan checkiisprereq "CheckWebsiteExists" "$IISVersion" "WebsiteName=\"$WebSiteName\""'

		#####
	${else}
		# New Install...
		LogEx::Write true ""
		LogEx::Write true "Checking that the CALUMO Website directory does not exist..."

		## Check for the existance of the web.config
		IfFileExists "$INSTDIR\web.config" 0 InstallationDoesNotExist
			LogEx::Write true "A CALUMO website has been detected at at: $INSTDIR"
			LogEx::Write true "Please install CALUMO into a new or empty directory."

			## Pop a non zero code on the stack to indicate a failure
			Push 1
			Call AbortOrContinue
		InstallationDoesNotExist:

		#####
		LogEx::Write true ""
		LogEx::Write true "Checking that the CALUMO Website exists in IIS..."
		${popOnStackAndExecute} 'obiwan checkiisprereq "CheckWebsiteDoesNotExist" "$IISVersion" "WebsiteName=\"$WebSiteName\""'
	${endif}
FunctionEnd

Function CopyServerJsonToRemotingDirectoryAndRestartService
	## This is only for Pre-11.9.5 Upgrades

	## Compare the version numbers to see which is newer (http://nsis.sourceforge.net/Docs/AppendixE.html#E.3.16)
	${VersionCompare} "$InstalledVersion" "11.9.5.0" $R0
	
	${if} $R0 == "2"
		${LogHeading} "RESETTING OBSELETE CALUMO REMOTING SERVICE"

		nsExec::execTolog 'sc stop "${SERVICE_NAME}"'

		CopyFiles $INSTDIR\server.config.json $INSTDIR\remoting\server.config.json
	
		nsExec::execTolog 'sc start "${SERVICE_NAME}"'
	${endif}
FunctionEnd


Function Msmgdsrv
	#${LogHeading} "INSTALLING SQL SERVER ANALYSIS SERVICES DLL"

	#${popOnStackAndExecute} 'obiwan copy.MSMGDSRV "$INSTDIR"'
FunctionEnd

Function ConfigureIIS
	${LogHeading} "PERFORMING IIS SETUP TASKS"

	# Register asp.net (dont bother checking if it's already registered, this will work or be tolerated in any case)
	${if} $IISVersion != ""
		LogEx::Write true  "Registering ASP.NET"
		ExecDos::exec '"$DotNetFrameworkPath\aspnet_regiis.exe" -i'
	${endif}

	${if} $IISVersion == "7"
		${if} $NewInstallation == "true"
			LogEx::Write true  "Creating IIS 7 application."
			${popOnStackAndExecute} 'obiwan setupiis "$IISVersion" "$WebSiteName" "$INSTDIR"'
		${else}
			LogEx::Write true  "Validating IIS 7 application."
			${popOnStackAndExecute} 'obiwan validateiis "$IISVersion" "$WebSiteName" "$INSTDIR"'
		${endif}

		LogEx::Write true  "Configuring IIS 7 application." #todo check doesn't require iis7
		${popOnStackAndExecute} 'obiwan configureiis "$IISVersion" "$WebSiteName" "$INSTDIR"'

	${elseif} $IISVersion == ""
		LogEx::Write true  "IIS has not been detected. The install of the CALUMO Web Server cannot continue."
		push 1
		call AbortOrContinue
	${else}
		## All for IIS 6
		LogEx::Write true  "Creating and Configuring IIS 6 application."

		!insertmacro CreateIISVDirScript
		LogEx::Write true  "Executing createIISVDir.vbs..."
		ExecDos::exec 'cscript.exe $INSTDIR\createIISVDir.vbs'

		!insertmacro CreateSetMvcMappingScript
		LogEx::Write true  "Executing setMvcMapping.vbs..."
		LogEx::Write true  $mvcMapping

		## Funky return codes come back from this, so it does not go into the usual poponstackandexecute call
		## TODO: Fix this up
		ExecDos::exec 'cscript.exe "$INSTDIR\setMvcMapping.vbs"'

		# Allow ASP.NET v4.0.30319 Web Service Extensions in IIS 6
		!insertmacro EnableASPNetApplicationInIIS6
		LogEx::Write true  "Executing enableaspnet.vbs..."
		ExecDos::exec 'cscript.exe "$INSTDIR\enableaspnet.vbs"'

		## Update the .NET Framework version of the Default Website to ASP.NET v4.0.30319
		Push '"$DotNetFrameworkPath\aspnet_regiis.exe" -sn "W3SVC/1/Root"'
		Call ExecuteCommandAndLogResult


		## Update the .NET Framework version of the CALUMO Application to ASP.NET v4.0.30319
		Push '"$DotNetFrameworkPath\aspnet_regiis.exe" -sn "W3SVC/1/Root/$WebSiteName"'
		Call ExecuteCommandAndLogResult


		## Yes.. yes yes.. we really have to do this to get it to work for ASP.NET 4 on IIS6
		## Get the v2.0.50727 framework directory
		${If} ${RunningX64}
			StrCpy $R0 "$WinDir\Microsoft.NET\Framework64\v2.0.50727"
		${Else}
			StrCpy $R0 "$WinDir\Microsoft.NET\Framework\v2.0.50727"
		${EndIf}

		## Set the aspnet version back to v2
		Push '"$R0\aspnet_regiis.exe" -sn "W3SVC/1/Root/$WebSiteName"'
		Call ExecuteCommandAndLogResult

		# Set the asp.net version to v4
		Push '"$DotNetFrameworkPath\aspnet_regiis.exe" -sn "W3SVC/1/Root/$WebSiteName"'
		Call ExecuteCommandAndLogResult

	${endif}

	## Create the script to be used by the Uninstall command to remove the IIS Virtual Dir
	!insertmacro DeleteIISVDirScript


FunctionEnd

Function CreateConfigs
	StrCpy $iisRootFolder $INSTDIR

	${if} $CurrentSiteName == ""
		${LogHeading} "CREATING CONFIGURATION FILES"

		LogEx::Write true "Creating web.config..."
		${popOnStackAndExecute} 'obiwan migrate web "$PLUGINSDIR\web.config.install.template" "$INSTDIR\web.config" args="SQLSERVERNAME=$DBServer,LDAPSERVERNAME=$LDAPserver,IISROOTFOLDER=$iisRootFolder,WEBSITENAME=$WebSiteName,SSASSERVERNAME=$SSASServer,LDAPCONNECTIONSTRING=$LDAPconnection,LDAPLOGINID=$LDAPlogin,LDAPPASSWORD=$LDAPpassword,SUPPORTEMAIL=$SupportEmail,NHIBERNATEPROFILE=false,SQLDATABASE=calumo11,ENVIRONMENT=Production"'

		# the new calumo.config.json (which replaces appsettings in web.config)
		LogEx::Write true "Creating server.config.json..."
		${popOnStackAndExecute} 'obiwan migrate server "$PLUGINSDIR\server.config.install.template.json" "$INSTDIR\server.config.json" args="IISROOTFOLDER=$iisRootFolder,WEBSITENAME=$WebSiteName,LDAPCONNECTIONSTRING=$LDAPconnection,LDAPLOGINID=$LDAPlogin,LDAPPASSWORD=$LDAPpassword,SUPPORTEMAIL=$SupportEmail,SSASSERVERNAME=$SSASServer"'

	${else}
		${LogHeading} "UPDATING CONFIGURATION FILES"

		# the new calumo.config.json (replaces appsettings in web.config)

		LogEx::Write true "Migrating server.config..."
		${popOnStackAndExecute} 'obiwan migrate server update "$INSTDIR\server.config.json" "$INSTDIR\web.config"'

		LogEx::Write true "Migrating web.config..."
		${popOnStackAndExecute} 'obiwan migrate web update "$INSTDIR\web.config"'
	${endif}
FunctionEnd

Function CreateShortcuts
	${LogHeading} "CREATING DESKTOP SHORTCUTS"

	CreateShortCut "$DESKTOP\CALUMO 11 Admin.lnk" "$PROGRAMFILES\Internet Explorer\iexplore.exe" "http://localhost/$WebSiteName/login.aspx" $INSTDIR\images\containerpage\Calumo.ico
	CreateShortCut "$DESKTOP\CALUMO 11.lnk" "$PROGRAMFILES\Internet Explorer\iexplore.exe" "http://localhost/$WebSiteName/container.aspx" $INSTDIR\images\containerpage\Calumo.ico
FunctionEnd

Function WriteRegistry
	${LogHeading} "WRITING SITE NAME REG KEYS"

	WriteRegStr HKLM "${RegKey}" "SiteName" $WebSiteName
	WriteRegStr HKLM "${RegKey}" "InstallationPath" "$INSTDIR"
	WriteRegStr HKLM "${RegKey}" "Version" "${Version}"

	WriteRegStr HKLM "${RegKey}" "Website Name" $WebSiteName
	WriteRegStr HKLM "${RegKey}" "SQL Database Server" $DBServer
	WriteRegStr HKLM "${RegKey}" "SSAS Database Server" $SSASServer
	WriteRegStr HKLM "${RegKey}" "LDAP Server" $LDAPserver
	WriteRegStr HKLM "${RegKey}" "LDAP Connection String" $LDAPconnection
	WriteRegStr HKLM "${RegKey}" "LDAP Login" $LDAPlogin
	WriteRegStr HKLM "${RegKey}" "LDAP Password" $LDAPpassword
	WriteRegStr HKLM "${RegKey}" "Support Email" $SupportEmail

	# Clean up old CALUMO Version Registry values
	DeleteRegKey HKLM "SOFTWARE\Calumo Labs Pty Ltd\Settings"

	!insertmacro CreateAddRemoveProgramsRegKeys

	LogEx::Write true "Registry updated successfully."
FunctionEnd

Function InstallerSpecificInit
FunctionEnd

##############################################################
##
##					INSTALLATION
##
##############################################################
Section "Install"

	SetOverwrite on

	## Initialisation
	Call ConfigureInstallation
	Call InitialiseVariables
	Call InitialiseLogging
	Call MaintenanceTasks
	Call PrintInstallVariables
	Call ExtractFiles
	Call CheckInstallationPreRequisites

	${if} $NewInstallation == "false"
		## Pre 11.9.5 where WCF was removed - copy the server.config.json into the remoting directory
		Call CopyServerJsonToRemotingDirectoryAndRestartService

		## Prepare for upgrade
		Call DeleteAllExceptConfigs
	${endif}

	## Install
	Call CopyExtractedFilesToInstDir
	Call Msmgdsrv
	Call CreateConfigs
	Call ConfigureIIS
	Call CreateShortcuts

	Call WriteRegistry
	Call WriteUninstallFile

	Call CloseLogging
SectionEnd


##############################################################
##
##						UNINSTALL FUNCTIONS
##
##############################################################
Function un.IISReset
	${un.LogHeading} "RESTARTING INTERNET INFORMATION SERVICES (IIS):"

	nsExec::execToLog 'iisreset'
FunctionEnd

Function un.ConfigureIIS
	!insertmacro un.DetailDivider
	DetailPrint "REMOVING IIS VIRTUAL DIRECTORY"
	!insertmacro un.DetailDivider

	nsExec::execTolog 'cscript.exe $INSTDIR\deleteIISVDir.vbs'
FunctionEnd

Function un.WindowsFirewall
	!insertmacro un.DetailDivider
	DetailPrint "Reverting Windows Firewall Changes"
	!insertmacro un.DetailDivider

	SimpleFC::RemovePort 808 6
	SimpleFC::RemoveApplication "$INSTDIR\Remoting\Calumo.Remoting.Service.exe"
FunctionEnd

Function un.UninstallRemotingService
	!insertmacro un.DetailDivider
	DetailPrint "UNINSTALLING CALUMO Remoting Service"
	!insertmacro un.DetailDivider

	nsExec::execTolog 'sc stop "${SERVICE_NAME}"'
	nsExec::execTolog 'sc delete "${SERVICE_NAME}"'
FunctionEnd

Function un.WriteRegistry
	!insertmacro un.DetailDivider
	DetailPrint "REMOVING REGISTRY KEYS"
	!insertmacro un.DetailDivider

	DeleteRegKey HKLM "${REGKEY}"

	!insertmacro RemoveAddRemoveProgramsRegKeys
FunctionEnd

Function un.DeleteDesktopIcons
	!insertmacro un.DetailDivider
	DetailPrint "REMOVING DESKTOP ICONS"
	!insertmacro un.DetailDivider

	Delete "$DESKTOP\CALUMO 11 Admin.lnk"
	Delete "$DESKTOP\CALUMO 11.lnk"
FunctionEnd

Function un.InstallerSpecificInit
FunctionEnd

##############################################################
##
##					UNINSTALLATION
##
##############################################################
Section "Uninstall"

	Call un.IISReset
	Call un.ConfigureIIS
	Call un.UninstallRemotingService
	Call un.WindowsFirewall
	Call un.WriteRegistry
	Call un.DeleteDesktopIcons
	Call un.ExtractFiles

SectionEnd
