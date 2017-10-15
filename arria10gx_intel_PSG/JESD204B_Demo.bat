@ECHO OFF
TITLE "JESD204B Demo Script"
MODE CON COLS=80 LINES=25
SETLOCAL EnableDelayedExpansion

CLS
ECHO  ------------------------------------------------------------------------------
ECHO  --
ECHO  -- Welcome to the Arria 10 GX/ADI DAQ2 JESD204B demonstration script! 
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
	ECHO  -- Press the "CPU RSTn" button on the Arria 10 GX board. 
	ECHO  --    (It is the button between the 2 green and 8 red illuminated LEDs.)
	ECHO  --
	ECHO  --    There will be a short delay (~40 seconds) while the Linux kernel  
  ECHO  --    boots and the DHCP address is issued.
  ECHO  --
	ECHO  --    Upon succesful DHCP allocation, verify DHCP server output on last line:
	ECHO  --    "...(Hostxxxxxxxxxxxx) allotted 192.168.0.2 for 36000 seconds"
	ECHO  --
	ECHO  -- Press any key to continue after IP address is allotted . . .
  ECHO  --
  ECHO  ------------------------------------------------------------------------------
  CHOICE /T 5 /D Y>nul
	@START CMD /K CALL "%~dp0DHCP Server\DELAY.bat"
	PAUSE>nul
	
	CLS
  ECHO  ------------------------------------------------------------------------------
  ECHO  --
  ECHO  -- IP address 192.168.0.2 is now assigned to the A10 GX board.
  ECHO  --
  ECHO  -- Start the Analog Devices IIO Oscilloscope by double-clicking the 
  ECHO  -- Desktop icon.
  ECHO  --
  ECHO  -- 1. Select Settings -- Connect
  ECHO  -- 2. Enter 192.168.0.2 for the IP addr-port
  ECHO  -- 3. Click Refresh then OK
  ECHO  --
  ECHO  -- When done with the demonstration, return to this window and press any key 
  ECHO  -- to terminate the DHCP server and reset DHCP on the host.
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
