######################################################################
# NewFileHere
#
# Create an empty TXT file
# * On click create a new text file (txt) in
#		* a. The frontmost Finder Window
#		* b. A custom location (User can select another folder)
# * Default filename: NewFile <YYYY-MM-dd_HHMMss>.txt
# * User can select to automatically paste the current clipboard content into the newly created file
#	
# 
#
# 2015-07-12
# Timo Kahle
#
# Changes
#
# v1.0.0 (2015-06-03)
# o Initial version
#
# v1.1.0 (2015-07-12)
# o Refactored whole app
#
# v1.2.0 (2016-07-19)
# o Exchanged Min OS version check function with more robust one
# o Updated min OS X version to 10.10
# o Added plist support to store last used location
# o Completely refactored flow logic
#
# v1.2.1 (2016-07-24)
# o Fixed a bug which led to an unrecoverable error if the path specified inside the plist wasn't available
#
#
# ToDo
#
# + Refactor
# + Add option to define default location (plist)
# + Add option to open the created file with the default application
# 
#
######################################################################

# Environment
property APP_ICON : "applet.icns"
property APP_NAME : "NewFileHere"
property APP_VERSION : "1.2.1"
property TIMEOUT_SEC : 120 -- 2 minutes

# Environment
property OSX_VERSION_MIN : "10.10"

# UI texts
property APP_DETAILS : APP_NAME & " " & APP_VERSION
property DLG_TITLE_ERROR : "ERROR"
property DLG_MSG_ERROR : "An error occurred."
property DLG_MSG_OS_UNSUPPORTED : "Your OS X version is not supported. You need at least OS X " & OSX_VERSION_MIN & " to use this app."
property DLG_MSG_ENTER_TITLE : "Enter a filename."
property DLG_MSG_SELECT_FOLDER : "Select a folder where to save the new file."
property DLG_TITLE_SELECT_LOCATION : "Select a location"
property FILENAME_PREFIX : "New File "
property FILENAME_EXTENSION : ".txt"
property UI_TXT_INFO_NOTSUPPORTED : " is not supported on your OS X version and cannot be run. Please update your OS X version."
property UI_TXT_CREATE_LOCATION : "Select a filename and location for the new txt file. The file type (.txt) will automatically be added."

# Buttons
property BTN_OK : "OK"
property BTN_CANCEL : "Cancel"
property BTN_CREATE : "Create Here"
property BTN_CREATE_OTHER : "Choose..."

# Plist
property SETTINGS_FILE : "net.thk.NewTxtFile.plist"
property LASTUSED_PATH_KEY : "LastUsedCreatePath"
property CMD_PLIST_READ : "defaults read " & SETTINGS_FILE & " " & LASTUSED_PATH_KEY
property CMD_PLIST_WRITE : "defaults write " & SETTINGS_FILE & " " & LASTUSED_PATH_KEY & " -string "


##################################################################

# Applet mode
on run
	set dlgIcon to (path to resource APP_ICON)
	set theNewFile to ""
	set theLocation to ""
	
	# Dynamic Dialog texts
	set dlg_Info_OSVersion_Check_Failed to APP_NAME & UI_TXT_INFO_NOTSUPPORTED
	
	
	# Check OS X Version for compatibility
	if OSXVersionSupported(OSX_VERSION_MIN) is false then
		display dialog dlg_Info_OSVersion_Check_Failed & return with title dlgTitle buttons {BTN_OK} default button {BTN_OK} cancel button {BTN_OK} with icon ICON_WARN
	end if
	
	
	# Define the default filename
	#set theFileNameDefault to FILENAME_PREFIX & GetFormattedTimestamp() & FILENAME_EXTENSION
	set theFileNameDefault to FILENAME_PREFIX & GetFormattedTimestamp()
	
	
	# Initialize possible locations
	#
	# Check if Finder has an open window and if so, get the path to the frontmost Finder window
	tell application "Finder"
		if exists Finder window 1 then
			# Initialize the paths
			set theCurrentFinderPath to (target of front Finder window)
			set theCurrentFinderPathPOSIX to (POSIX path of (target of front Finder window as text))
		else
			set theCurrentFinderPath to ""
			set theCurrentFinderPathPOSIX to ""
		end if
	end tell
	
	# Check if last used path is available in a plist
	set theDefaultPath to ExecCommand(CMD_PLIST_READ)
	if (theDefaultPath contains "does not exist") or (theDefaultPath is "") then
		# Initialize with safe defaults
		set theLastUsedPath to (path to home folder)
		set theLastUsedPathPOSIX to (POSIX path of (path to home folder))
	else
		# If the plist exists, we need to convert the path to Apple format to work with "choose folder"
		try
			set theLastUsedPath to (POSIX file theDefaultPath as alias)
			set theLastUsedPathPOSIX to (POSIX path of theDefaultPath)
		on error
			set theLastUsedPath to (path to home folder)
			set theLastUsedPathPOSIX to (POSIX path of (path to home folder))
		end try
	end if
	
	
	# No frontmost Finder window available
	if theCurrentFinderPath is "" then
		# Limited options (no current Finder location)
		# Ask the user for the filename and location
		set theFileName to (display dialog UI_TXT_CREATE_LOCATION with title DLG_MSG_ENTER_TITLE default answer theFileNameDefault buttons {BTN_CANCEL, BTN_CREATE_OTHER} default button {BTN_CREATE_OTHER} cancel button {BTN_CANCEL} with icon dlgIcon)
		
		# Get the users selection
		set theFileName_Selected to text returned of theFileName
		set theAnswerButton to button returned of the theFileName
		
		# User selected to use another target folder
		if theAnswerButton is BTN_CREATE_OTHER then
			# Ask for other folder
			set theLocation to (choose folder with prompt DLG_MSG_SELECT_FOLDER default location theLastUsedPath)
			set theLocation to (POSIX path of theLocation)
			
			# Get the users selection
			set theNewFile to quoted form of (theLocation & theFileName_Selected & FILENAME_EXTENSION)
		end if
	else
		# Offer all options
		# Ask the user for the filename and location
		set theFileName to (display dialog UI_TXT_CREATE_LOCATION & return & return & "ⓘ " & BTN_CREATE & return & theCurrentFinderPathPOSIX with title DLG_MSG_ENTER_TITLE default answer theFileNameDefault buttons {BTN_CANCEL, BTN_CREATE_OTHER, BTN_CREATE} default button {BTN_CREATE} cancel button {BTN_CANCEL} with icon dlgIcon)
		
		# Get the users selection
		set theFileName_Selected to text returned of theFileName
		set theAnswerButton to button returned of the theFileName
		
		# User selected to use another target folder
		if theAnswerButton is BTN_CREATE_OTHER then
			# Ask for other folder
			set theLocation to (choose folder with prompt DLG_MSG_SELECT_FOLDER default location theLastUsedPath)
			set theLocation to (POSIX path of theLocation)
			
			# Get the users selection
			set theNewFile to quoted form of (theLocation & theFileName_Selected)
		end if
		
		# User selected to use the frontmost Finder window
		if theAnswerButton is BTN_CREATE then
			# Ask for other folder
			set theLocation to theCurrentFinderPathPOSIX
			
			# Get the users selection
			set theNewFile to quoted form of (theLocation & theFileName_Selected & FILENAME_EXTENSION)
		end if
		
	end if
	
	
	#display alert "New file" message theNewFile
	
	# Create/update plist
	set thePlistPathValue to ExecCommand(CMD_PLIST_WRITE & theLocation)
	(*
	if thePlistPathValue does not contain "Error: " then
		display alert "Successfully updated plist" # DEBUG
	else
		display alert "An error occured updating/creating the plist" message thePlistPathValue # DEBUG
		return
	end if
	
	return
	*)
	
	
	# Create the file		
	set theFileCreated to (do shell script "touch " & theNewFile)
	# Check for errors
	if theFileCreated contains "Error: " then
		# An error occurred
		display notification theFileCreated with title DLG_TITLE_ERROR
	end if
	
end run

######################################################################
######################################################################


# Run a command without admin privileges
on ExecCommand(thisAction)
	try
		#set returnValue to do shell script (thisAction & " 2>&1")
		set returnValue to do shell script (thisAction)
	on error errMsg
		set returnValue to "Error: " & errMsg
	end try
	
	return returnValue
end ExecCommand


# Valid OS X version
on OSXVersionSupported(minSupportedOSXVersion)
	set strOSXVersion to system version of (system info)
	considering numeric strings
		set IsSupportedOSXVersion to strOSXVersion is greater than or equal to minSupportedOSXVersion
	end considering
	
	return IsSupportedOSXVersion
end OSXVersionSupported


# Get formatted date/time stamp
on GetFormattedTimestamp()
	set dtStamp to do shell script ("date \"+%Y-%m-%d_%H%M%S\"")
	return dtStamp as string
end GetFormattedTimestamp
