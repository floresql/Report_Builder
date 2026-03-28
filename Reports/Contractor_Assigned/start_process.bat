@echo off
setlocal EnableDelayedExpansion

REM #########################################################################################################
REM  Configuration Section _ Define all variables here for easy maintenance.
REM  Don't need to edit here
REM #########################################################################################################

REM Determine environment: DEV, UAT, or PROD
REM -------------------------------------------------------------------------------------------------
	:: Get the full path
	SET "full_path=%~dp0"
	:: remove the trailing backslash 
	CALL SET "REPORT_DIR=%%full_path:~0,-1%%"
	:: --- Get the parent directory
	FOR %%I IN ("%REPORT_DIR%") DO SET "PARENT_DIR=%%~dpI"
	:: remove the trailing backslash
	CALL SET "PARENT_DIR=%%PARENT_DIR:~0,-1%%"
	:: Get the grandparent directory
	FOR %%I IN ("%PARENT_DIR%") DO SET "GRANDPARENT_DIR=%%~dpI"
	:: remove the trailing backslash 
	CALL SET "GRANDPARENT_DIR=%%GRANDPARENT_DIR:~0,-1%%"

	for %%A in ("%REPORT_DIR%") do set "REPORT_NAME=%%~nxA"

REM Directory Variables
REM -------------------------------------------------------------------------------------------------

	call :GetTimestamp myTimestamp
	set "LOG_DIR=%REPORT_DIR%\logs"
	set "LOG_FILE=%LOG_DIR%\LOG_%REPORT_NAME%_%myTimestamp%.txt"
	set "ERROR_LOG_FILE=%REPORT_DIR%\logs\ERROR_%REPORT_NAME%_%myTimestamp%.txt"

	set "SECURE_FOLDER=\\ncemcorpsmb03.corp.twcable.com\Groups\Ops_Analytics_Secure"
	set "SERVER_FILE=%SECURE_FOLDER%\Server_Bin\Server_Config.txt"

	:: -- Create log directory if it doesn't exist
	if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
	IF exist "%LOG_FILE%" del /F /Q "%LOG_FILE%"

	:: -- Pass the log file path to Python via an environment variable
	set "LOG_FILE_PATH=%LOG_FILE%" 
	set "REPORT_DIR=%REPORT_DIR%"
	set "REPORT_NAME=%REPORT_NAME%"


REM Initialization
REM -------------------------------------------------------------------------------------------------

	::  Read names from the configuration file.
	<"%SERVER_FILE%" (
		set /p SERVER=
		set /p PUBLIC_DRIVE=
		set /p PYTHON_EXE=
		set /p EXCEL_EXE=
	)

REM Script Info
REM -------------------------------------------------------------------------------------------------
	call :LogMessage "INFO   " "PATH: %REPORT_DIR%"
	call :LogMessage "INFO   " "Script for %REPORT_NAME% started"
	
	
	
REM #########################################################################################################
REM  Main Script _ Initialize config variables, run macros, and python scripts
REM  Make changes here for your report.
REM #########################################################################################################

REM  STEP 1: Execute Python script for SQL data retrieval
REM -------------------------------------------------------------------------------------------------

	set "STEP_NAME=main.py"
	call :LogMessage "INFO   " "Running %STEP_NAME%"

	"%PYTHON_EXE%" "%GRANDPARENT_DIR%\src\%STEP_NAME%"
	call :HandleError "!ERRORLEVEL!" "%STEP_NAME%"	


REM  STEP 2: Run Excel macro to update datamaster.xlsx
REM -------------------------------------------------------------------------------------------------

	set "STEP_NAME=autoMacro.xlsm"
	call :LogMessage "INFO   " "Running %STEP_NAME%"

	"%EXCEL_EXE%" "%REPORT_DIR%\macros\%STEP_NAME%"
	call :HandleError "!ERRORLEVEL!" "%STEP_NAME%"


REM  STEP 3: Run Excel macro to update report
REM -------------------------------------------------------------------------------------------------

	set "STEP_NAME=UpdateReport.xlsm"
	call :LogMessage "INFO   " "Running %STEP_NAME%"

	"%EXCEL_EXE%" "%REPORT_DIR%\macros\%STEP_NAME%"
	call :HandleError "!ERRORLEVEL!" "%STEP_NAME%"


REM  STEP 4: Copy report to OpsDesk
REM -------------------------------------------------------------------------------------------------

REM	set "STEP_NAME=Copy_%REPORT_NAME%.xlsx"
REM	call :LogMessage "INFO   " "Running %STEP_NAME%"

REM	Set "FName1=%REPORT_DIR%\%REPORT_NAME%.xlsx"
REM	Set "FName2=%PUBLIC_DRIVE%\%REPORT_NAME%.xlsx"

	:: remove read only
REM	attrib -r %FName2%

	:: copy file
REM	Copy %FName1% %FName2% /Y
REM	call :HandleError "!ERRORLEVEL!" "%STEP_NAME%"
		
	:: read only
 	:: attrib +r %FName2%	


REM  STEP 5: Run script to send email
REM -------------------------------------------------------------------------------------------------

REM	set "STEP_NAME=Send Email"
REM	call :LogMessage "INFO   " "Running %STEP_NAME%"

REM	Call %SERVER%\D\EMail_Blat\Blat250\full\blat "%REPORT_DIR%\email\email.htm"  -tf "%REPORT_DIR%\email\masterList.txt" -subject "%REPORT_NAME%_Report" -attach "%PUBLIC_DRIVE%\%REPORT_NAME%.xlsx" -serverSMTP mailrelay.chartercom.com -f "Northeast Ops Analytics Team <DL-NER-OPS-ANALYTICS@charter.com>" 
REM	call :HandleError "!ERRORLEVEL!" "%STEP_NAME%"


REM  STEP 5: END OF SCRIPT
REM -------------------------------------------------------------------------------------------------

	call :LogMessage "SUCCESS" "Batch script completed."
	goto :EOF



REM #########################################################################################################
REM  Subroutines used above
REM  Don't need to edit here
REM #########################################################################################################


REM  Subroutine for error handling _ Checks for errors and provide info to log file
REM -------------------------------------------------------------------------------------------------
:HandleError
	set LAST_ERRORLEVEL=%1
	set LAST_STEP_NAME=%2

	IF %ERRORLEVEL% NEQ 0 (
		call :LogMessage "ERROR  " "%LAST_STEP_NAME% FAILED with Error-Level %LAST_ERRORLEVEL% on %DATE% at %TIME%"
		exit /b !LAST_ERRORLEVEL!
	) ELSE (
		call :LogMessage "SUCCESS" "%STEP_NAME% ran without any reported errors"
	)
goto :EOF


REM  Subroutine for Log Messages _ Handels log messages with a consistent timestamp
REM -------------------------------------------------------------------------------------------------
:LogMessage
    set log_level=%~1
    set log_message=%~2
	for /f "tokens=*" %%a in ('%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -Command "Get-Date -format yyyy-MM-dd_HH-mm-ss.fff"') do (
    set fullstamp=%%a
    )
    echo !fullstamp! ^| !log_level!  ^| !log_message! >> "%LOG_FILE%"
	echo !fullstamp! ^| !log_level!  ^| !log_message!
goto :EOF


REM  Weekday Subroutine
REM -------------------------------------------------------------------------------------------------
:GetWeekday
	:: ## Sets the variable named by the first argument (%1) to the full weekday name
	for /f "tokens=*" %%x in ('%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -Command "[DateTime]::Now.DayOfWeek.ToString()"') do set "%1=%%x"
goto :eof


rem  Timestamp Subroutine
REM -------------------------------------------------------------------------------------------------
:GetTimestamp
	rem ## Sets the variable named by the first argument (%1)
	for /f "tokens=*" %%x in ('%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -Command "[DateTime]::Now.ToString('yyyy-MM-dd_HH-mm-ss.fff')"') do set "%1=%%x"
goto :eof