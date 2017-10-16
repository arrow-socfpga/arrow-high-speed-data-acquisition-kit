@ECHO OFF
TITLE "Flash Arria 10 GX development kit"
MODE CON COLS=80 LINES=25
SETLOCAL EnableDelayedExpansion

CLS
ECHO  ------------------------------------------------------------------------------
ECHO  --
ECHO  -- Flash the JESD204B demo onto the Arria 10 GX Development kit
ECHO  --
ECHO  -- This script temporarily assigns the host PC a static IP address of 
ECHO  -- 192.168.0.1 and starts a DHCP server to provide the IP address   
ECHO  -- 192.168.0.2 to the Arria 10 GX board.
ECHO  --
ECHO  ------------------------------------------------------------------------------
PAUSE

NET session >nul 2>&1

IF %errorLevel% NEQ 0 (
  CLS
  ECHO  ------------------------------------------------------------------------------
  ECHO  -- ERROR: Current permissions inadequate.
  ECHO  --
  ECHO  -- Right click on batch file and select "Run as administrator"
  ECHO  ------------------------------------------------------------------------------
  PAUSE
  GOTO :EOF
) 

  CLS
  SET _INPUT=
  SET _INDEX=
  ECHO ------------------------------------------------------------------------------
  ECHO --
  ECHO -- Power ON the Arria 10 GX board now if it is not already on.
  ECHO --
  ECHO -- Configure the dev kit to boot the Board Update Portal
  ECHO --
  ECHO -- 1. Press switch S5 until PGM_LED2 (right most LED) is lit
  ECHO -- 2. Press switch S6 to configure the board.
  ECHO ------------------------------------------------------------------------------
  PAUSE

	CLS
  ECHO ------------------------------------------------------------------------------
  ECHO --
  ECHO -- Looking for active Ethernet connections...
  ECHO --
  ECHO ------------------------------------------------------------------------------
  TIMEOUT /T 5

:START
  CLS
  ECHO ------------------------------------------------------------------------------
  ECHO --
 	ECHO -- Here are the active Ethernet connections on the host PC:
  ECHO.
	@WMIC nic where "NetConnectionStatus=2" get "NetConnectionId", "Index"
  ECHO --
	ECHO -- Enter the Index of the Ethernet connection the A10 GX board is plugged into.
  ECHO --
	ECHO -- Note: If there are no connections or the expected wired connection is not
	ECHO -- shown, press 'Enter' to refresh the list until the expected wired  
	ECHO -- connection is shown.
  ECHO --
  ECHO ------------------------------------------------------------------------------
  ECHO.
	SET /P _INPUT="Enter Index number and press Enter: "

	IF "!_INPUT!"=="" (GOTO:START)

	IF !_INPUT! EQU 0 (
		SET _INDEX=0 
		GOTO:START_TASKS
	)
	SET /A _INDEX=!_INPUT!*1
	IF !_INDEX! GTR 0 GOTO START_TASKS
	IF !_INDEX! EQU 0 (
		ECHO !_INPUT! -- NOT A VALID CHOICE
		PAUSE
		GOTO :START
	)
	
	:START_TASKS
	CLS
  @WMIC nicconfig where Index=!_INDEX! call EnableStatic "192.168.0.1","255.255.255.0">nul
	@%~d0
  ECHO  ------------------------------------------------------------------------------
  ECHO  --
  ECHO  -- Assigning static IP address 192.168.0.1 to local host...
  CHOICE /T 1 /D Y>nul
 	ECHO  --
	ECHO  -- Starting DHCP server...
  CHOICE /T 1 /D Y>nul
	ECHO  --   (You will see a few status messages here for just a momment.)
	ECHO  --
  ECHO  ------------------------------------------------------------------------------
	@START "DHCP Server" /B "%~dp0DHCP Server\OpenDHCPServer.exe" -v
  CHOICE /T 5 /D Y>nul

	CLS
  ECHO  ------------------------------------------------------------------------------
	ECHO  --
	ECHO  -- There will be a short delay (~40 seconds) while the DHCP address is issued.
    ECHO  --
	ECHO  -- Upon succesful DHCP allocation, verify DHCP server output on last line:
	ECHO  -- "...(Hostxxxxxxxxxxxx) allotted 192.168.0.2 for 36000 seconds"
	ECHO  --
	ECHO  -- Press any key to continue after IP address is allotted . . .
  ECHO  --
  ECHO  ------------------------------------------------------------------------------
  CHOICE /T 5 /D Y>nul
rem sjk	@START CMD /K CALL "%~dp0DHCP Server\DELAY.bat"
	PAUSE>nul
	
	CLS
  ECHO  ------------------------------------------------------------------------------
  ECHO  --
  ECHO  -- IP address 192.168.0.2 is now assigned to the A10 GX board.
  ECHO  --
  ECHO  -- Open a web browser with the URL set to 192.168.0.2
  ECHO  --
  ECHO  -- Leave this window open while flashing the development kit. Press any key 
  ECHO  -- to terminate the DHCP server and reset DHCP on the host once flashing is 
  ECHO  -- complete
  ECHO  --
  ECHO  ------------------------------------------------------------------------------
	ECHO Press any key to terminate demonstration . . .
	PAUSE>nul
	
	TASKKILL /f /im OpenDHCPServer.exe /t>nul
  
  :CLEANUP
  @WMIC nicconfig where Index=!_INDEX! call EnableDHCP>nul
  @CD %~dp0"DHCP Server\"
	@DEL OpenDHCPServer.url>nul
  @DEL OpenDHCPServer.htm>nul
  @DEL OpenDHCPServer.state>nul
	
	CLS
	ECHO  -----------------------------------------------------------------------------
  ECHO  --
	ECHO  -- Restored DHCP on the host and cleaning up...
	ECHO  --
	ECHO  -----------------------------------------------------------------------------
	ECHO Press any key to close window and exit . . .
  
	PAUSE>nul
)
