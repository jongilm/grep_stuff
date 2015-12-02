@echo off

rem ///////////////////////////////////////////////////////////////////////////////
rem // grep_stuff.bat
rem // JGilmore, 05/07/2012 15:10
rem //
rem // USAGE: grep_stuff.bat <InputLogFile>
rem //
rem // The input log file is not modified by this script.
rem // All generated output files are in subdir of "results_grep_stuff_<InputLogFile>."
rem //
rem // This script does the following...
rem //    a) Run log through readable.pl
rem //       Output sent to "log_readable.log"
rem //    b) Run this readable log through insert_tabs.pl
rem //       Output sent to "log_readable_tabs.log"
rem //    c) grep this readable, tabbed log file for various strings and patterns.
rem //       For each search, a separate file is created in the results subdir.
rem //       These resultant log files are particularly useful in comparisons
rem //       of different logs/scenarios using BeyondCompare as follows:
rem //       in 'Data' mode which separates the fields into columns.
rem //       I use the "NDS Tabbed Log" format and specific session settings.
rem //       See TreePad notes: "NDS_notes201205/Reference/Logs/Beyond Compare settings".
rem //
rem ///////////////////////////////////////////////////////////////////////////////

if not exist %1 goto :ERROR01

rem TODO: Strip the following:
rem "[35m"
rem "[0m"
rem "[K"
rem "\n[A"
rem "[1;32;41m"
rem "[0m"

rem CALL :PROCESS_SI_LOGS %1
CALL :PROCESS_ENG_LOGS %1
CALL :PROCESS_DMS_LOGS %1

:Do_Done
@echo ----------------------------------------------
@echo Done
@echo ----------------------------------------------
pause
goto :EOF

:ERROR01
echo Cannot find input file: %1
pause
goto :EOF

:ERROR_SRC_FILE
echo Cannot find source file: %SRC_FILE%
pause
goto :EOF

:ERROR_TGT_FILE
echo Cannot find target file: %TGT_FILE%
pause
goto :EOF

:ERROR02
echo Cannot find intermediate file: %TARGET_DIR%\grepstuff_exceptions.log
pause
goto :EOF


rem ************************************************************************
rem ************************************************************************
rem ** TOP LEVEL FUNCTIONS BEGIN
rem ************************************************************************
rem ************************************************************************



rem ----------------------------------------------
:PROCESS_SI_LOGS
rem ----------------------------------------------

set TARGET_DIR=results_grep_stuff_SI_%1
if not exist %TARGET_DIR% mkdir %TARGET_DIR%

rem Not used
rem rem ----------------------------------------------
rem @echo Simple copy of log with leading line numbers...
rem rem ----------------------------------------------
rem set SRC_FILE=%1
rem set TGT_FILE=%TARGET_DIR%\log_with_linenumbers.log
rem if not exist %SRC_FILE% goto :ERROR_SRC_FILE
rem if exist %TGT_FILE% del %TGT_FILE%
rem grep NDS: %SRC_FILE% > %TGT_FILE%
rem if not exist %TGT_FILE% goto :ERROR_TGT_FILE


rem ----------------------------------------------
@echo Readable... (timestamps, keypress names and dialog names)
rem ----------------------------------------------
set SRC_FILE=%1
set TGT_FILE=%TARGET_DIR%\log_readable.log
if not exist %SRC_FILE% goto :ERROR_SRC_FILE
if exist %TGT_FILE% del %TGT_FILE%
readable.pl %SRC_FILE% %TGT_FILE%
if not exist %TGT_FILE% goto :ERROR_TGT_FILE

rem ----------------------------------------------
@echo Insert Tabs...
rem ----------------------------------------------
rem Need to change FDM messages to prevent them being incorrectly recognised as fields: "Station O:  " -->  "Station_O:__"
rem Need to change FDM messages to prevent them being incorrectly recognised as fields: "Station A:  " -->  "Station_A:__"
rem Need to change FDM messages to prevent them being incorrectly recognised as fields: "Station V:  " -->  "Station_V:__"
rem Need to change FDM messages to prevent them being incorrectly recognised as fields: "Station T:  " -->  "Station_T:__"
set SRC_FILE=%TARGET_DIR%\log_readable.log
set TGT_FILE=%TARGET_DIR%\log_readable_tabs.log
if not exist %SRC_FILE% goto :ERROR_SRC_FILE
if exist %TGT_FILE% del %TGT_FILE%
insert_tabs.pl %SRC_FILE% %TGT_FILE%
if not exist %TGT_FILE% goto :ERROR_TGT_FILE

rem ----------------------------------------------
@echo Add line numbers and strip lines which are unrecognised/unformatted
rem ----------------------------------------------
set SRC_FILE=%TARGET_DIR%\log_readable_tabs.log
set TGT_FILE=%TARGET_DIR%\log_readable_tabs_numbers.log
grep -n "^Id:\|^NDS:\|^//" %SRC_FILE% > %TGT_FILE%
grep -nv "^Id:\|^NDS:\|^//" %SRC_FILE% > %TARGET_DIR%\log_readable_tabs_numbers_unrecognised.log
rem CALL :ADD_DLG_NAMES %TGT_FILE%

set SRC_FILE=%TARGET_DIR%\log_readable_tabs_numbers.log

@echo ----------------------------------------------
@echo Searching %SRC_FILE% ...
@echo ----------------------------------------------
CALL :PROCESS_PCAT ..\PCAT.DB %TARGET_DIR%
CALL :GREP_CHANNELS    %SRC_FILE% %TARGET_DIR%
CALL :GREP_IMP_STRINGS %SRC_FILE% %TARGET_DIR%
CALL :GREP_SI_STRINGS  %SRC_FILE% %TARGET_DIR%
CALL :GREP_FEATURE_DCA %SRC_FILE% %TARGET_DIR%
CALL :GREP_HTTP_STUFF  %SRC_FILE% %TARGET_DIR%
CALL :GREP_UNITS       %SRC_FILE% %TARGET_DIR%
CALL :GREP_SEVERITIES  %SRC_FILE% %TARGET_DIR%
CALL :DO_DATABASES     %SRC_FILE% %TARGET_DIR%
goto :EOF



rem ----------------------------------------------
:PROCESS_ENG_LOGS
rem ----------------------------------------------
set TARGET_DIR=results_grep_stuff_ENG_%1
if not exist %TARGET_DIR% mkdir %TARGET_DIR%

set SRC_FILE=%1
set TGT_FILE=%TARGET_DIR%\log_numbers.log
grep -n "$" %SRC_FILE% > %TGT_FILE%

rem For HTTP we will not exculed unrecognisable lines (i.e. we'll use log_readable_tabs.log instead of log_readable_tabs_numbers.log)
set SRC_FILE=%TARGET_DIR%\log_numbers.log

@echo ----------------------------------------------
@echo Searching %SRC_FILE% ...
@echo ----------------------------------------------
CALL :GREP_IMP_STRINGS           %SRC_FILE% %TARGET_DIR%
CALL :GREP_HTTP_STUFF            %SRC_FILE% %TARGET_DIR%
CALL :GREP_UNITS                 %SRC_FILE% %TARGET_DIR%
CALL :GREP_SEVERITIES            %SRC_FILE% %TARGET_DIR%
rem CALL :DO_DATABASES               %SRC_FILE% %TARGET_DIR%
CALL :GREP_DMS_0804_1_STUFF      %SRC_FILE% %TARGET_DIR%
goto :EOF

rem ----------------------------------------------
:PROCESS_DMS_LOGS
rem ----------------------------------------------
set TARGET_DIR=results_grep_stuff_DMS_%1
if not exist %TARGET_DIR% mkdir %TARGET_DIR%

set SRC_FILE=%1
set TGT_FILE=%TARGET_DIR%\log_numbers.log
grep -n "$" %SRC_FILE% > %TGT_FILE%

rem set SRC_FILE=%TARGET_DIR%\log_readable_tabs_numbers.log
set SRC_FILE=%TARGET_DIR%\log_numbers.log

@echo ----------------------------------------------
@echo Searching %SRC_FILE% ...
@echo ----------------------------------------------
CALL :GREP_DMS_0804_1_STUFF      %SRC_FILE% %TARGET_DIR%
goto :EOF


rem ************************************************************************
rem ************************************************************************
rem ** FUNCTIONS BEGIN
rem ************************************************************************
rem ************************************************************************

:ADD_DLG_NAMES
rem ************************************************************************
rem  1 /r "Showing dialog 1121" "Showing dialog 1121 // SEARCHING_FOR_LOCAL_NETWORK"
rem  2 /r "Showing dialog 1205" "Showing dialog 1205 // WIFI_NOT_CONFIGURED_AT_BOOT_ID"
rem  3 /r "Showing dialog 1269" "Showing dialog 1269 // CONNECTING_TO_NETWORK_ID"
rem  4 /r "Showing dialog 1340" "Showing dialog 1340 // NETWORK_ENTER_PIN"
rem  5 /r "Showing dialog 1343" "Showing dialog 1343 // RESET_CONNECTION_CONFIRMATION"
rem  6 /r "Showing dialog 1344" "Showing dialog 1344 // NETWORK_CONNECTION_SUCCESSFUL"
rem  7 /r "Showing dialog 1270" "Showing dialog 1270 // PROBLEM_CONNECTING_TO_NETWORK_ID"
rem  8 /r "Showing dialog 1342" "Showing dialog 1342 // CONFIGURE_WPS_PIN_VIA_ROUTER"
rem  9 /r "Showing dialog 1112" "Showing dialog 1112 // SEARCHING_FOR_LISTINGS_ID"
rem 10 /r "Showing dialog 1023" "Showing dialog 1023 // DLG_NO_SCHEDULE_INFO_ID"
rem ************************************************************************
change32 -o %1.dlgtemp /r "Showing dialog 1121" "Showing dialog 1121 // SEARCHING_FOR_LOCAL_NETWORK" /r "Showing dialog 1205" "Showing dialog 1205 // WIFI_NOT_CONFIGURED_AT_BOOT_ID" /r "Showing dialog 1269" "Showing dialog 1269 // CONNECTING_TO_NETWORK_ID" /r "Showing dialog 1340" "Showing dialog 1340 // NETWORK_ENTER_PIN" /r "Showing dialog 1343" "Showing dialog 1343 // RESET_CONNECTION_CONFIRMATION" /r "Showing dialog 1344" "Showing dialog 1344 // NETWORK_CONNECTION_SUCCESSFUL" /r "Showing dialog 1270" "Showing dialog 1270 // PROBLEM_CONNECTING_TO_NETWORK_ID" /r "Showing dialog 1342" "Showing dialog 1342 // CONFIGURE_WPS_PIN_VIA_ROUTER" /r "Showing dialog 1112" "Showing dialog 1112 // SEARCHING_FOR_LISTINGS_ID" /r "Showing dialog 1023" "Showing dialog 1023 // DLG_NO_SCHEDULE_INFO_ID" %1
copy %1.dlgtemp %1
del %1.dlgtemp
GOTO :EOF

:PROCESS_PCAT
rem ************************************************************************
rem items_new.exe [-f] [-d] [-do] [-s] [-x] [database]
rem   -f  : Full - include more information with each row (Verbose)
rem   -d  : Full - include more information with each row
rem   -do : Full - include more information with each row
rem   -s  : Full - include more information with each row
rem   -x  : Output Comma-Separated-Value (CSV) file for use with Excel
rem   database : If not given, defaults to PCAT.DB
rem ************************************************************************
pushd %2
if exist %1 items_new.exe -f -d -do -s -x %1
popd
goto :EOF


rem ----------------------------------------------
:GREP_CHANNELS
rem ----------------------------------------------
@echo GREP_CHANNELS
set SRC_FILE=%1
set TARGET_DIR=%2
rem Find all occurances of "Channel 998"
grep -w 998 %SRC_FILE% > %TARGET_DIR%\grepstuff_word_Ch998.log
grep -w 535 %SRC_FILE% > %TARGET_DIR%\grepstuff_word_Ch535.log
grep -w 103 %SRC_FILE% > %TARGET_DIR%\grepstuff_word_Ch103.log
grep -w 201 %SRC_FILE% > %TARGET_DIR%\grepstuff_word_Ch201.log
grep -w 609 %SRC_FILE% > %TARGET_DIR%\grepstuff_word_Ch609.log
grep -w 610 %SRC_FILE% > %TARGET_DIR%\grepstuff_word_Ch610.log
grep    "TUNING TO" %SRC_FILE% > %TARGET_DIR%\grepstuff_word_TuningTo.log
goto :EOF


rem ----------------------------------------------
:GREP_IMP_STRINGS
rem ----------------------------------------------
@echo GREP_IMP_STRINGS (Important Strings)
set SRC_FILE=%1
set TARGET_DIR=%2

rem  Find all occurances of "Exception"
grep -i Exception %SRC_FILE% > %TARGET_DIR%\grepstuff_string_exception.log

if not exist %TARGET_DIR%\grepstuff_string_exception.log goto :ERROR02
rem  Exclude all occurances of "NO_EXCEPTION"
grep -v NO_EXCEPTION %TARGET_DIR%\grepstuff_string_exception.log > %TARGET_DIR%\grepstuff_string_exception_not_NO_EXCEPTION.log

rem  Find all occurances of "PMON"
grep @@PMON@@ %SRC_FILE% > %TARGET_DIR%\grepstuff_string_PMON.log

grep    "VGV_VGC"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_VGV_VGC.log


GOTO :EOF



rem ----------------------------------------------
:GREP_SI_STRINGS
rem ----------------------------------------------
@echo GREP_SI_STRINGS
set SRC_FILE=%1
set TARGET_DIR=%2

rem  Find all occurances of "BAT Update"
grep -i "BAT.*update\|capt\-BAT\|BAT table\|SIM_NEW_BOUQUET_ID\|BOUQUET" %SRC_FILE% > %TARGET_DIR%\grepstuff_string_ts_BAT.log
grep -i "capt\-PAT\|PAT table" %SRC_FILE% > %TARGET_DIR%\grepstuff_string_ts_PAT.log
grep -i "capt\-NIT\|NIT table\|missing from NIT\|SIM_DBC_QUERY_GetTransportStreamObjectByTSAndNetKeys" %SRC_FILE% > %TARGET_DIR%\grepstuff_string_ts_NIT.log


rem  Find various other stuff
grep    "JG\|PPPD_PMSG_Log"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_JG.log
grep    "JG\|KEY_PRESS:"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_KEY_PRESS.log
grep -i "JG\|KEY_PRESS:\|Showing dialog\|STANDBY STATE"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_Keys_and_Dialogs.log
rem change32 -o %TARGET_DIR%\grepstuff_string_Keys_and_Dialogs2.log /r "Showing dialog 1121" "Showing dialog 1121 // SEARCHING_FOR_LOCAL_NETWORK" /r "Showing dialog 1205" "Showing dialog 1205 // WIFI_NOT_CONFIGURED_AT_BOOT_ID" /r "Showing dialog 1269" "Showing dialog 1269 // CONNECTING_TO_NETWORK_ID" /r "Showing dialog 1340" "Showing dialog 1340 // NETWORK_ENTER_PIN" /r "Showing dialog 1343" "Showing dialog 1343 // RESET_CONNECTION_CONFIRMATION" /r "Showing dialog 1344" "Showing dialog 1344 // NETWORK_CONNECTION_SUCCESSFUL" /r "Showing dialog 1270" "Showing dialog 1270 // PROBLEM_CONNECTING_TO_NETWORK_ID" /r "Showing dialog 1342" "Showing dialog 1342 // CONFIGURE_WPS_PIN_VIA_ROUTER" /r "Showing dialog 1112" "Showing dialog 1112 // SEARCHING_FOR_LISTINGS_ID" /r "Showing dialog 1023" "Showing dialog 1023 // DLG_NO_SCHEDULE_INFO_ID" %TARGET_DIR%\grepstuff_string_Keys_and_Dialogs.log
rem CALL :ADD_DLG_NAMES %TARGET_DIR%\grepstuff_string_Keys_and_Dialogs.log


grep -i "JG\|KEY_PRESS:\|Showing dialog\|STANDBY STATE\|UUID"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_Keys_and_Dialogs_UUID.log
rem change32 -o %TARGET_DIR%\grepstuff_string_Keys_and_Dialogs_UUID2.log /r "Showing dialog 1121" "Showing dialog 1121 // SEARCHING_FOR_LOCAL_NETWORK" /r "Showing dialog 1205" "Showing dialog 1205 // WIFI_NOT_CONFIGURED_AT_BOOT_ID" /r "Showing dialog 1269" "Showing dialog 1269 // CONNECTING_TO_NETWORK_ID" /r "Showing dialog 1340" "Showing dialog 1340 // NETWORK_ENTER_PIN" /r "Showing dialog 1343" "Showing dialog 1343 // RESET_CONNECTION_CONFIRMATION" /r "Showing dialog 1344" "Showing dialog 1344 // NETWORK_CONNECTION_SUCCESSFUL" /r "Showing dialog 1270" "Showing dialog 1270 // PROBLEM_CONNECTING_TO_NETWORK_ID" /r "Showing dialog 1342" "Showing dialog 1342 // CONFIGURE_WPS_PIN_VIA_ROUTER" /r "Showing dialog 1112" "Showing dialog 1112 // SEARCHING_FOR_LISTINGS_ID" %TARGET_DIR%\grepstuff_string_Keys_and_Dialogs_UUID.log
rem CALL :ADD_DLG_NAMES %TARGET_DIR%\grepstuff_string_Keys_and_Dialogs_UUID.log

rem * build\applications\Picasso\picasso\Picasso\src\java\picasso\tvviewingmgr\fullscreen\SatelliteSignalController.java
rem *   old:   logger.logMilestone("DISPLAYING NSS DIALOG WITH CODE " + dialogCode);
rem *   new:   logger.logMilestone("DISPLAYING DIALOG " + dialogId + " WITH CODE " + dialogCode);
rem * NSS Codes (IMediaEngine.java) ...
rem *   NO_ERROR(-1),
rem *   PLAYER_SESSION_FAIL(10),
rem *   PLAYER_COMPONENT_FAIL(14),
rem *   PLAYER_CONNECTION_FRONTEND(25),
rem *   SPM_FAILURE(29),
rem *   PLAYER_COMPONENT_TIMEOUT(30),
rem *   PLAYER_COMPONENT_VIDEO_ERROR(31),
rem *   CATCH_ALL(48);
grep    "JG\|DISPLAYING NSS DIALOG WITH CODE\|DISPLAYING DIALOG\|PLAYER_SESSION_FAIL\|PLAYER_COMPONENT_FAIL\|PLAYER_CONNECTION_FRONTEND\|SPM_FAILURE\|PLAYER_COMPONENT_TIMEOUT\|PLAYER_COMPONENT_VIDEO_ERROR"  %SRC_FILE% >> %TARGET_DIR%\_grepstuff_string_CHECKME.log
grep    "JG\|DISPLAYING NSS DIALOG WITH CODE\|DISPLAYING DIALOG\|PLAYER_SESSION_FAIL\|PLAYER_COMPONENT_FAIL\|PLAYER_CONNECTION_FRONTEND\|SPM_FAILURE\|PLAYER_COMPONENT_TIMEOUT\|PLAYER_COMPONENT_VIDEO_ERROR"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_NSS_Dialog.log

rem * Example "Showing Dialog" and "NSS DIALOG" messages...
rem * 3400661:NDS:	^2013/11/07 06:07:50.315293	!MIL	 EPG_FS	<	p:0x0000015e	P:APP	t:0x2bc6d520	T:no name	M:SatelliteSignalController	F:showDialogNoSatelliteSignalOrTechnicalFault	L:205	> T:CEE-J EventQueue Reader 0:DISPLAYING NSS DIALOG WITH CODE PLAYER_COMPONENT_FAIL
rem * 3400680:NDS:	^2013/11/07 06:07:50.959630	!MIL	 EPG_DLG	<	p:0x0000015e	P:APP	t:0x2bc6d520	T:no name	M:DialogManager	F:showDialog	L:1644	> T:CEE-J EventQueue Reader 0:Showing dialog 1000
rem * Where...
rem *   PLAYER_COMPONENT_FAIL indicates NSS14
rem *   1000 indicates "NO_SATELLITE_SIGNAL_ID"



grep    "JG\|PMT_NOT_AVAILABLE"  %SRC_FILE% >> %TARGET_DIR%\_grepstuff_string_CHECKME.log


grep    XSI_SKEVT  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_XSI_SKEVT.log
grep    XSI        %SRC_FILE% > %TARGET_DIR%\grepstuff_string_XSI.log
grep    DVB        %SRC_FILE% > %TARGET_DIR%\grepstuff_string_DVB.log
grep -i SKEVT      %SRC_FILE% > %TARGET_DIR%\grepstuff_string_SKEVT.log
grep    SIM_       %SRC_FILE% > %TARGET_DIR%\grepstuff_string_SIM_.log
grep -i AssetAcquisition %SRC_FILE% > %TARGET_DIR%\grepstuff_string_AssetAcquisition.log
grep -i standby %SRC_FILE% > %TARGET_DIR%\grepstuff_string_standby.log
grep -i "d-manifest-start\|d-manifest-end\|d-book-asset\|d-rec-asset-end\|d-quota\|scte35-splcmsg\|rule-eval-chosen\|d-prf-mod-recieved\|PICASSO STANDBY STATE\|DISPLAYING NSS DIALOG\|DISPLAYING DIALOG" %SRC_FILE% > %TARGET_DIR%\grepstuff_string_quota.log

:SI5841_CallBackStuff
rem Mmmm... this is a bit messy...
rem rem Look for occurances of: "callback", "MODEM_DATA_STATUS_", "NCM_PPP", "APP_START event", "Application params: app_id=", "VGC_SSF_FILE_OPEN_MSG"
rem grep -i "callback\|MODEM_DATA_STATUS_\|NCM_PPP\|APP_START event\|Application params\: app_id\=\|VGC_SSF_FILE_OPEN_MSG"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_Callback1_temp.log
rem rem Remove lines relating to callback functions rather than telephone callbacks
rem grep -v "runLevelNotificationCallback\|SYSTEMTIME_TimeStampCallback\|DataClientCallBackFunc\|GraphEngineJobCallback\|FusionAPIFrontEndCallback\|SSM_UPNP_ClientCallbackEventHandler\|ATG_OIGC_ResponseCallback\|DiskManNotifyCallback\|ATMLIB_MPL_CA_DATA_RegisterCallback\|GUIDE_CALLBACK\|FDM_FS_HANDLER_MessageHandler\|AtmCompletionCallback\|FilterGetPositionCallbackHandler\|PrepareVideoDecoderCallback\|ItemEventCallback\|HandleRangesActivateResponse\|SYSINIT_API_HandleRunLevelRequest\|ATG_API_Iterator_MoveByRelative\|oigc.c\|HandleFsmEventGetPosCallback\|SIM_pi_xsi_DVBSISectionCallback\|SIM_engine_xsi_mc_MpegSectionCallback" %TARGET_DIR%\grepstuff_string_Callback1_temp.log > %TARGET_DIR%\grepstuff_string_Callback1.log
rem del %TARGET_DIR%\grepstuff_string_Callback1_temp.log

rem Let's remove "callback" from the strings...
rem Look for occurances of: "MODEM_DATA_STATUS_", "NCM_PPP", "APP_START event", "Application params: app_id=", "VGC_SSF_FILE_OPEN_MSG"
grep -i "JG\|MODEM_DATA_\|NCM_PPP\|APP_START event\|Application params\: app_id\=\|VGC_SSF_FILE_OPEN_MSG\|UAM_DCM_PARAM_DATA_TYPE_APP_START\|App params\: ApplicationId\=0x00000010\|Application params\: app_id\=16"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_Callback1.log

grep -i "JG\|\-ams\|\-uam\|ppp\|dial\|ssf\|modem\|KEY_PRESS:\|callback\|MODEM_DATA_STATUS_\|NCM_PPP"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_Callback2.log

grep    "JG\|MODEM_DATA_STATUS"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_MODEM_DATA_STATUS.log

grep -i "JG\|socket\.c\|Network is unreachable\|modem device\|modem0\|HALT\!\!\!\|Unexpected Modem Status\|TelephoneLine\$1\.run\|Creating CSV file\|\.csv"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_Callback3.log
grep -i "JG\|socket\.c\|Network\|HALT\!\!\!\|\phone\|csv\|\-ams\|\-uam\|ppp\|dial\|ssf\|modem\|KEY_PRESS\|\-OFS"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_Callback4.log
grep -i "JG\|cacallback\|reportback\|dial\|dialog\|phone"     %SRC_FILE% > %TARGET_DIR%\grepstuff_string_Callback5.log

grep    "STANDBY STATE\|socket\.c\|Network is unreachable\|modem device\|modem0\|HALT\!\!\!\|Unexpected Modem Status\|TelephoneLine\$1\.run\|KEY_PRESS:\|Showing dialog\|MODEM_DATA_STATUS_\|Command Ret\: COMMAND_\|NCM_SESSION_EVENT_TYPE_GLOBAL_NET_UNSET\|modem error\|single-frame allocator is full\|NCM_SESSION_EVENT_TYPE_\|NCM_SESSION_EVENT_TYPE_NCM_CONFIG_AVAILABLE\|CABLEMODEM\|MODEM_SETUP\|CA_CALLBACK\|SPM config is read successfuly"  %SRC_FILE% > %TARGET_DIR%\grepstuff_string_Callback6.log

rem Requires: ATM INFO
grep    "JG:\|GetCARegionBits\|d-prfl-ca-atrib-rgn\|d-prfl-ca-atrib-svc\|d-prf-mod-recieved\|d-manifest-start\|d-manifest-end\|CalcCachedData\|CaAttribute::SetValue\|HandleDynamicEnablingMessage\|CheckEnablingState\|M:atmlib.c F:??? L:00720\|M:atmlib.c F:??? L:720\|M:ca_attribute.cpp F:??? L:00092\|M:ca_attribute.cpp F:??? L:92\|> start, start_location: \|> get from byte \|> region_bits: \|> Start Enable sequence\|> Start Disable sequence\|M:ca_attribute_table.cpp F:??? L:00116\|M:ca_attribute_table.cpp F:??? L:116\|ParseCampaignRulesData" %SRC_FILE% > %TARGET_DIR%\grepstuff_string_smartcard_CARegionBits.log
rem change -r "\nT:DPE_THREAD M:ca_attribute.cpp F:CaAttribute::SetValue L:00092 > start" "Start\t"
rem        -r "T:DPE_THREAD M:atmlib_mpl_ca_data.c F:ATMLIB_MPL_CA_DATA_GetCARegionBits L:00377 > start, " "\t"
rem        -r "T:DPE_THREAD M:atmlib_mpl_ca_data.c F:ATMLIB_MPL_CA_DATA_GetCARegionBits L:00419 > " "\t"
rem        -r "T:DPE_THREAD M:atmlib_mpl_ca_data.c F:ATMLIB_MPL_CA_DATA_GetCARegionBits L:00427 > " "\t"
rem change32 -o %TARGET_DIR%\grepstuff_string_smartcard_CARegionBits2.log -r "\nT:DPE_THREAD M:ca_attribute.cpp F:CaAttribute::SetValue L:00092 > start" "Start\t" -r "T:DPE_THREAD M:atmlib_mpl_ca_data.c F:ATMLIB_MPL_CA_DATA_GetCARegionBits L:00377 > start, " "\t" -r "T:DPE_THREAD M:atmlib_mpl_ca_data.c F:ATMLIB_MPL_CA_DATA_GetCARegionBits L:00419 > " "\t" -r "T:DPE_THREAD M:atmlib_mpl_ca_data.c F:ATMLIB_MPL_CA_DATA_GetCARegionBits L:00427 > " "\t" %TARGET_DIR%\grepstuff_string_smartcard_CARegionBits.log

GOTO :EOF


rem ----------------------------------------------
:GREP_FEATURE_DCA
rem  DCA (DirectChannelAccess) stuff
rem ----------------------------------------------
@echo GREP_FEATURE_DCA
set SRC_FILE=%1
set TARGET_DIR=%2
rem set SRC_FILE=log_readable_tabs_numbers.log
rem set TARGET_DIR=.
grep    "JG\|\<\=\=\|Showing dialog\|STANDBY STATE\|DirectChannelAccess\|DCA\|KEY_PRESS\|TUNING TO\|CHANNEL CHANGED TO\|TVVM_DCA\|VisibilityController\.show\|Keyevent is\|Keycode is\|KEYPRESS\|Sending to Gnome\|EventQueue Reader 0\:Using handler\:" %SRC_FILE% > %TARGET_DIR%\grepstuff_feature_DCA.log
grep    "JG\|\<\=\=\|Showing dialog\|STANDBY STATE\|DirectChannelAccess\|DCA\|KEY_PRESS\|TUNING TO\|CHANNEL CHANGED TO\|TVVM_DCA\|VisibilityController\.show\|Keyevent is\|Keycode is\|KEYPRESS\|Sending to Gnome\|EventQueue Reader 0\:Using handler\:\|M\:BannerController\|M\:DirectChannelAccessModel\|M\:ExampleConcretePinComponent\|M\:FullScreenController\|M\:KeyProcessor\|M\:MilestoneNotifier\|M\:ScreenDirectingKeyListener\|M\:Screens\|M\:SpcPortOutput\|M\:VisibilityController\|M\:aem_list.c\|M\:aem_userinput.c\|M\:ssm_upnp_client.c" %SRC_FILE% > %TARGET_DIR%\grepstuff_feature_DCA2.log
rem grep    "JG\|\<\=\=\|Showing dialog\|STANDBY STATE\|DirectChannelAccess\|DCA\|KEY_PRESS\|TUNING TO\|CHANNEL CHANGED TO\|TVVM_DCA\|VisibilityController\.show\|Keyevent is\|Keycode is\|KEYPRESS\|Sending to Gnome\|EventQueue Reader 0\:Using handler\:\|M\:BannerController\|M\:DirectChannelAccessModel\|M\:ExampleConcretePinComponent\|M\:FullScreenController\|M\:KeyProcessor\|M\:MilestoneNotifier\|M\:ScreenDirectingKeyListener\|M\:Screens\|M\:SpcPortOutput\|M\:VisibilityController\|M\:aem_list.c\|M\:aem_userinput.c\|M\:ssm_upnp_client.c" log_readable_tabs_numbers.log > grepstuff_feature_DCA2.log

rem ####################################################################################
rem Part 1 (Thread A: AEM_INPUT_MONITOR_THREAD)
rem 1082552:NDS:	^2013/12/07 13:17:15.644944	!MIL	 aem	    M:aem_userinput.c	            F:AEM_InputMonitorThread	        L:566	> KEY_PRESS: code=0xe304 // NUMERIC_FOUR    <=== DCA1a
rem 1082553:NDS:	^2013/12/07 13:17:15.644993	!INFO	 aem	    M:aem_userinput.c	            F:AEM_InputMonitorThread	        L:764	> AEM_USERINACTIVITYTIMER_LIST_PRIV_RestartPendingTimers failed!
rem 1082554:NDS:	^2013/12/07 13:17:15.645029	!INFO	 aem	    M:aem_userinput.c	            F:AEM_InputMonitorThread	        L:773	> SDV disabled, no keep alive notification sent to Player
rem 1082555:NDS:	^2013/12/07 13:17:15.645052	!INFO	 aem	    M:aem_list.c	                F:AEM_ListGetKeySubscription	    L:4377	> Can't find subscription
rem 1082556:NDS:	^2013/12/07 13:17:15.645083	!INFO	 aem	    M:aem_list.c	                F:AEM_ListGetFocusedApplication	    L:3879	> Application handle = 0x00000000 has focus
rem 1082557:NDS:	^2013/12/07 13:17:15.645109	!INFO	 aem	    M:aem_list.c	                F:FindApplicationInList	            L:1271	> found application name = and handle = 0
rem 1082558:NDS:	^2013/12/07 13:17:15.645154	!INFO	 aem	    M:aem_userinput.c	            F:AEM_InputRouteEventToApp	        L:1445	> event e304 consumed by application 0 event type 1
rem Part 2 (Thread B: 7b520)
rem 1082559:NDS:	^2013/12/07 13:17:15.647298	!MIL	 EPG_KEY	M:KeyProcessor	                F:keyPressed	                    L:144	> T:CEE-J EventQueue Reader 0:Keyevent is 4868
rem 1082560:NDS:	^2013/12/07 13:17:15.647713	!MIL	 EPG_KEY	M:KeyProcessor	                F:keyPressed	                    L:189	> T:CEE-J EventQueue Reader 0:Keycode is 2:VK_4 x1
rem 1082561:NDS:	^2013/12/07 13:17:15.648660	!MIL	 EPG_FS 	M:FullScreenController	        F:getPlaybackHandler	            L:718	> T:CEE-J EventQueue Reader 0:Using handler:LiveNoBufferPlaybackHandler Based on PlaybackHandlerDecisionParameter{playbackType=LIVE, isCurrentPlaybackPPV=false, isPlayingRemoteRecording=false, mediaEngineCurrentlyTuning=false}
rem Part 3 (Thread B: 7b520)
rem 4518:NDS:	^2013/12/05 15:52:53.589900	!MIL	 EPG_FS	        M:VisibilityController	        F:externalComponentStateIs	        L:1013	> T:CEE-J EventQueue Reader 0:externalComponentState = -1
rem 4519:NDS:	^2013/12/05 15:52:53.590331	!FATAL	 EPG_BAN	    M:BannerController	            F:showSynopsisView	                L:1918	> T:CEE-J EventQueue Reader 0:setSynopsisView show = false
rem 4520:NDS:	^2013/12/05 15:52:53.593208	!FATAL	 EPG_UI	        M:ExampleConcretePinComponent	F:deactivatePin	                    L:167	> T:CEE-J EventQueue Reader 0:Pin does not have focus!
rem 4521:NDS:	^2013/12/05 15:52:53.600301	!MIL	 EPG_SCR	    M:Screens	                    F:dumpLayers	                    L:1255	> T:CEE-J EventQueue Reader 0:Screen Stack [0..7] : 0 X X X X X X X
rem 4522:NDS:	^2013/12/05 15:52:53.600700	!MIL	 EPG_SCR	    M:Screens$6	                    F:doCloseScreen	                    L:1637	> T:CEE-J EventQueue Reader 0:SCREEN BANNER layer=1, id=1 closed
rem 4523:NDS:	^2013/12/05 15:52:53.603038	!MIL	 EPG_SCR	    M:Screens	                    F:dumpLayers	                    L:1255	> T:CEE-J EventQueue Reader 0:Screen Stack [0..7] : 0 X X X X X X X
rem 4524:NDS:	^2013/12/05 15:52:53.604609	!MIL	 EPG_FS	        M:VisibilityController	        F:show	                            L:571	> T:CEE-J EventQueue Reader 0:VisibilityController.show TVVM_DCA
rem 4525:NDS:	^2013/12/05 15:52:53.605334	!MIL	 EPG_TVVM	    M:DirectChannelAccessModel	    F:isComplete	                    L:219	> T:CEE-J EventQueue Reader 0:### DirectChannelAccessModel.isComplete false
rem 4526:NDS:	^2013/12/05 15:52:53.606046	!MIL	 EPG_UI	        M:ScreenDirectingKeyListener	F:dispatchKeyToScreen	            L:59	> T:CEE-J EventQueue Reader 0:KEYPRESS 2:VK_3 x1 handled by Screen FULLSCREEN layer=0, id=0 View 458756
rem Part 4 (Thread C: 0e520)
rem 4527:NDS:	^2013/12/05 15:52:53.607938	!MIL	 EPG_ME	        M:SpcPortOutput	                F:write	                            L:24	> T:PooledExecutor#4:Sending to Gnome
rem 4528:NDS:	^2013/12/05 15:52:53.607959	!MIL	 EPG_ME	        M:SpcPortOutput	                F:write	                            L:24	> T:PooledExecutor#4:015CE000103--a6
rem Part 5 (Thread D: ad520)
rem 4529:NDS:	^2013/12/05 15:52:53.609091	!MIL	 EPG_MISC	    M:MilestoneNotifier	            F:send	                            L:21	> T:GoogleAnalytics#0:vr@946685333603: Closed screen BANNER
rem Part 6 (Thread B: 7b520)
rem 4530:NDS:	^2013/12/05 15:52:53.629765	!MIL	 EPG_FS	        M:VisibilityController	        F:externalComponentStateIs	        L:1013	> T:CEE-J EventQueue Reader 0:externalComponentState = -1
rem Part 7  (Thread A: AEM_INPUT_MONITOR_THREAD)
rem 1082562:NDS:	^2013/12/07 13:17:15.811685	!INFO	 aem	    M:aem_userinput.c	            F:AEM_InputMonitorThread	        L:764	> AEM_USERINACTIVITYTIMER_LIST_PRIV_RestartPendingTimers failed!
rem 1082563:NDS:	^2013/12/07 13:17:15.811700	!INFO	 aem	    M:aem_userinput.c	            F:AEM_InputMonitorThread	        L:773	> SDV disabled, no keep alive notification sent to Player
rem 1082564:NDS:	^2013/12/07 13:17:15.811720	!INFO	 aem	    M:aem_list.c	                F:AEM_ListGetKeySubscription	    L:4377	> Can't find subscription
rem 1082565:NDS:	^2013/12/07 13:17:15.811756	!INFO	 aem	    M:aem_list.c	                F:AEM_ListGetFocusedApplication	    L:3879	> Application handle = 0x00000000 has focus
rem 1082566:NDS:	^2013/12/07 13:17:15.811781	!INFO	 aem	    M:aem_list.c	                F:FindApplicationInList	            L:1271	> found application name = and handle = 0
rem 1082567:NDS:	^2013/12/07 13:17:15.811828	!INFO	 aem	    M:aem_userinput.c	            F:AEM_InputRouteEventToApp	        L:1445	> event e304 consumed by application 0 event type 2
rem Part 8 (Thread B: 7b520)
rem 1082568:NDS:	^2013/12/07 13:17:15.814264	!MIL	 EPG_FS	    M:FullScreenController	        F:getPlaybackHandler	            L:718	> T:CEE-J EventQueue Reader 0:Using handler:LiveNoBufferPlaybackHandler Based on PlaybackHandlerDecisionParameter{playbackType=LIVE, isCurrentPlaybackPPV=false, isPlayingRemoteRecording=false, mediaEngineCurrentlyTuning=false}
rem Part 9 (Thread x: 6f520)
rem 1082569:NDS:	^2013/12/07 13:17:16.309945	!ERROR	 SSM_UPNP	M:ssm_upnp_client.c	            F:SSM_UPNP_Client_DownloadDescDoc	L:10610	> Failed to add description download to pending queue: http://172.16.5.11:49153/description3.xml pending list is full
rem 1082570:NDS:	^2013/12/07 13:17:16.309961	!ERROR	 SSM_UPNP	M:ssm_upnp_client.c	            F:SSM_UPNP_ClientThread	            L:11424	> Failed to process ALIVE event
rem Part 10 (Thread B: 7b520)
rem 4537:NDS:	^2013/12/05 15:52:53.753654	!MIL	 EPG_UI	        M:ScreenDirectingKeyListener	F:dispatchKeyToScreen	            L:59	> T:CEE-J EventQueue Reader 0:KEYPRESS 2:RELEASED x1 handled by Screen FULLSCREEN layer=0, id=0 View 458756
rem ####################################################################################

goto :EOF

rem ----------------------------------------------
:GREP_HTTP_STUFF
rem ----------------------------------------------
@echo GREP_HTTP_STUFF
set SRC_FILE=%1
set TARGET_DIR=%2
@rem echo on

grep    "JG\|\-HTTPSERVER"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_HTTPSERVER.log
grep    "JG\|\-LIGHTTPD"                                                            %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_LIGHTTPD.log
grep    "JG\|\-HTTP[^S]\|48 54 54 50"                                               %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_HTTP.log
grep    "JG\|\-CURL"                                                                %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_CURL.log
grep    "JG\|\-VGC"                                                                 %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_VGC.log
grep    "JG\|\-DRM"                                                                 %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_DRM.log
grep    "JG\|\-VWSC"                                                                %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_VWSC.log
grep    "JG\|\-VWSS"                                                                %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_VWSS.log
grep    "JG\|\-VWS"                                                                 %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_VWS.log
grep    "JG\|\-CMDC"                                                                %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_CMDC.log
                                                                                 
grep -i "JG\|vws"                                                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_vws_string.log
grep -i "JG\|sgw"                                                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_sgw_string.log
grep -i "JG\|ofs"                                                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_ofs_string.log
grep -i "JG\|sac"                                                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_sac_string.log
                                                                                    
grep -i "JG\|\sac"                                                                  %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_sac.log
grep -i "JG\|http\|curl\|sac"                                                       %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_http_curl_sac.log
grep -i "JG\|httpserver\|lighttpd"                                                  %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_httpserver_lighttpd.log
grep -i "JG\|http\|curl\|sac\|httpserver\|lighttpd"                                 %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_http_curl_sac_httpserver_lighttpd.log
grep -i "JG\|VGC\|SAC\|DRM\|SGW\|VWSC\|CMDC"                                        %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_vgc_sac_drm_sgw_vwsc_cmdc.log
grep -i "JG\|HTTP\|\LIGHTTPD\|curl\|SAC\|VGC\|DRM\|SGW\|VWSC\|WEB\|VWSS\|CMDC"      %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_all1.LOG
grep -i "JG\|HTTP\|\LIGHTTPD\|curl\|SAC\|VGC\|DRM\|SGW\|VWSC\|WEB\|VWSS\|CMDC|url\|uri\|ip_addr\|ipaddr\|proxy\|dns\|dhcp\|http\|tcp\|udp\|upnp\|ssl\|oig\|sky\|Content\-\|H T T P\|C o n t e n t\|S e r v e r\|S A C\|0d 0a\|v w s\|u t f\|L e n g t h\|E r r\|SYSTEMTIME_TimeStampCallback"  %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_all2.LOG

grep -v ":NDS:"                                                                     %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_unformatted_lines.LOG


grep -i "JG\|VWSC\|VWSS\|CMDC\|HTTPSERVER_API_Get_Socket\|HTTPSERVER_API_Close_Socket\|HTTPSERVER_API_PBAG_Destroy\|HTTPSERVER_API_PBAG_SetParam_IpAddr\|HTTPSERVER_API_PBAG_SetParam_Port\|HTTPSERVER_API_PBAG_SetParam_Uri\|HTTPSERVER_API_PBAG_Create\|Lighttpd_Connection_Create\|Lighttpd_Connection_Destroy"  %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_HttpStuff_GetCloseSocket.LOG

rem --------------------------------------------------------------
rem 0124A47C: 48 54 54 50 2f 31 2e 31   H T T P / 1 . 1
rem 0124A484: 20 35 30 30 20 49 6e 74     5 0 0   I n t
rem 0124A48C: 65 72 6e 61 6c 20 53 65   e r n a l   S e
rem 0124A494: 72 76 65 72 20 45 72 72   r v e r   E r r
rem 0124A49C: 6f 72 0d 0a   o r . .
rem --------------------------------------------------------------
rem 0124A47C: 43 6f 6e 74 65 6e 74 2d   C o n t e n t -
rem 0124A484: 4c 65 6e 67 74 68 3a 20   L e n g t h :
rem 0124A48C: 30 0d 0a   0 . .
rem --------------------------------------------------------------
rem 0124A47C: 43 6f 6e 74 65 6e 74 2d   C o n t e n t -
rem 0124A484: 54 79 70 65 3a 20 74 65   T y p e :   t e
rem 0124A48C: 78 74 2f 70 6c 61 69 6e   x t / p l a i n
rem 0124A494: 3b 20 63 68 61 72 73 65   ;   c h a r s e
rem 0124A49C: 74 3d 75 74 66 2d 38 0d   t = u t f - 8 .
rem 0124A4A4: 0a   .
rem --------------------------------------------------------------
rem 0124A47C: 53 65 72 76 65 72 3a 20   S e r v e r :
rem 0124A484: 76 77 73 2f 31 2e 30 0d   v w s / 1 . 0 .
rem 0124A48C: 0a   .
rem --------------------------------------------------------------
rem 0124A47C: 58 2d 53 41 43 2d 50 72   X - S A C - P r
rem 0124A484: 6f 78 79 2d 45 72 72 6f   o x y - E r r o
rem 0124A48C: 72 3a 20 55 4e 4b 4e 4f   r :   U N K N O
rem 0124A494: 57 4e 0d 0a   W N . .
rem --------------------------------------------------------------
rem Content-Length: 0
rem Content-Type: text/plain; charset=utf-8
rem Server: vws/1.0
rem X-SAC-Proxy-Error: UNKNOWN
rem
rem ]
rem --------------------------------------------------------------

goto :EOF
rem ####################################################################################



rem ----------------------------------------------
:GREP_DMS_0804_1_STUFF
rem ----------------------------------------------
@echo GREP_DMS_0804_1_STUFF
set SRC_FILE=%1
set TARGET_DIR=%2
@rem echo on

grep -i "DMS_0804_1"                                                                                                                                                                                                               %SRC_FILE% > %TARGET_DIR%\grepstuff_dms_DMS_0804_1_only.log
grep -i "JG\|DMS_0804_1"                                                                                                                                                                                                           %SRC_FILE% > %TARGET_DIR%\grepstuff_dms_DMS_0804_1.log
grep -i "JG\|HTTP\|\LIGHTTPD\|curl\|SAC\|wait_for_ofs_response\|OFS_callback\|HTTP_RP_\|VGC_SSF_NOTIFICATION_TYPE_SESSION_INIT_COMPLETE\|SYSTEMTIME_TimeStampCallback\|DMS_0804_1\|OFS"                                            %SRC_FILE% > %TARGET_DIR%\grepstuff_dms_DMS_0804_1_and_http_stuff.log
grep -i "JG\|HTTP\|\LIGHTTPD\|curl\|SAC\|VGC\|DRM\|SGW\|VWSC\|WEB\|VWSS\|CMDC\|wait_for_ofs_response\|OFS_callback\|HTTP_RP_\|VGC_SSF_NOTIFICATION_TYPE_SESSION_INIT_COMPLETE\|SYSTEMTIME_TimeStampCallback\|DMS_0804_1\|OFS"      %SRC_FILE% > %TARGET_DIR%\grepstuff_dms_DMS_0804_1_and_HttpStuff_all1.LOG
grep -i "JG\|HTTP\|\LIGHTTPD\|curl\|SAC\|VGC\|DRM\|SGW\|VWSC\|WEB\|VWSS\|CMDC|url\|uri\|ip_addr\|ipaddr\|proxy\|dns\|dhcp\|http\|tcp\|udp\|upnp\|ssl\|oig\|sky\|Content\-\|H T T P\|C o n t e n t\|S e r v e r\|S A C\|0d 0a\|v w s\|u t f\|L e n g t h\|E r r\|wait_for_ofs_response\|OFS_callback\|HTTP_RP_\|VGC_SSF_NOTIFICATION_TYPE_SESSION_INIT_COMPLETE\|SYSTEMTIME_TimeStampCallback\|DMS_0804_1\|OFS"  %SRC_FILE% > %TARGET_DIR%\grepstuff_dms_DMS_0804_1_and_HttpStuff_all2.LOG
rem --------------------------------------------------------------

goto :EOF
rem ####################################################################################



rem ----------------------------------------------
:GREP_UNITS
rem ----------------------------------------------
@echo GREP_UNITS
set SRC_FILE=%1
set TARGET_DIR=%2
@rem echo on
grep    "JG\|\-EPG"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_EPG.log
grep    "JG\|\-EPG_CA"                                                       %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_EPG_CA.log
                                                                             
grep    "JG\|\-aem"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_AEM.log
grep    "JG\|\-ASM"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_ASM.log
grep    "JG\|\-ATM"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_ATM.log
grep    "JG\|\-MSM "                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_MSM.log
grep    "JG\|\-MSM_MS"                                                       %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_MSM_MS.log
grep    "JG\|\-MSM_MDI"                                                      %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_MSM_MDI.log
                                                                             
grep    "JG\|\-PCATS"                                                        %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_PCAT_PCATS.log
grep    "JG\|\-PCATC"                                                        %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_PCAT_PCATC.log
grep    "JG\|\-DBENGINE_SRV"                                                 %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_PCAT_DBENGINE_SRV.log
grep -v "DB_MEM_OTHER_GetStat"                                               %TARGET_DIR%\grepstuff_unit_PCAT_DBENGINE_SRV.log > %TARGET_DIR%\grepstuff_unit_PCAT_DBENGINE_SRV2.log

grep    "JG\|\-VRMS"                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_VRMS.log
grep    "JG\|\-VRMC"                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_VRMC.log
grep    "JG\|\-VRM\|\-VRMS\|\-VRMC"                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_VRM.log
rem System Booking Management                                                
grep    "JG\|\-SBM"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SBM.log
rem Resource Management Framework                                            
grep    "JG\|\-RMF"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_RMF.log
grep -i "JG\|\-PCATC\|\-PCATS\|\-VRM\|\-VRMS\|\-VRMC\|\-SBM\|\-RMF\|malformed\|RECORD_Start\|VRM:RECORD:IF_JOB:SEVERE:FAILURE\-VRM\|\-VRMS\|\-VRMC"   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_PCAT_RecordingStuff.log

grep    "JG\|\-SPC"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SPC.log
                                                                             
grep    "JG\|\-SIM"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SIM.log
grep    "JG\|\-P_Api"                                                        %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_Player.log
grep    "JG\|\-Planner"                                                      %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_Planner.log
                                                                             
grep    "JG\|\-AMS"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_AMS.log
grep    "JG\|\-UAM"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_UAM.log
grep    "JG\|\-NCM_SERVER"                                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_NCM_SERVER.log
grep    "JG\|\-PPPD_SERVER\|NCM_PPP"                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_PPPD_SERVER1.log
grep -v "TimeOut Happend for poll(). So checking Read\|PPPD_SERVER_thread into While" %TARGET_DIR%\grepstuff_unit_PPPD_SERVER1.log > %TARGET_DIR%\grepstuff_unit_PPPD_SERVER2.log
grep    "JG\|\-SPM"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SPM.log
                                                                             
grep    "JG\|\-OFS"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_OFS.log
                                                                             
grep    "JG\|\-MM_CLIENT"                                                    %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_MM_CLIENT.log
grep    "JG\|\-VGV"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_VGV.log
grep    "JG\|\-VGC"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_VGC.log
                                                                             
rem SIM (SQ = SIM Query Handler)                                             
grep    "JG\|\-SQ13"                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SIM_SQ13.log
grep    "JG\|\-SQ22"                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SIM_SQ22.log
grep    "JG\|\-SQ41"                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SIM_SQ41.log
grep    "JG\|\-SQ42"                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SIM_SQ42.log
                                                                             
grep    "JG\|\-CAMM"                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_CAMM.log
                                                                             
                                                                             
grep    "JG\|\-SSM_UPNP"                                                     %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_R4_SSM_UPNP.log
grep    "JG\|\-SCM"                                                          %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_R4_SCM.log
                                                                             
grep    "JG\|\-UPNP_TESTS"                                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_UPNP_TESTS.log
grep    "JG\|\-SSM_SERVER_UPNP"                                              %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SSM_SERVER_UPNP.log
grep    "JG\|\-SSM_SERVER"                                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SSM_SERVER.log
grep    "JG\|\-SSM_CLIENT"                                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SSM_CLIENT.log
grep    "JG\|\-SSM_COMMON"                                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_SSM_COMMON.log
grep    "JG\|\-UPNP_COMMON"                                                  %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_UPNP_COMMON.log
grep    "JG\|\-UPNP"                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_UPNP.log


grep    "JG\|\-UPNP_TESTS\|\-SSM_SERVER_UPNP\|\-SSM_SERVER\|\-SSM_CLIENT\|\-SSM_COMMON\|\-UPNP_COMMON\|\-UPNP" %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_UPNP_all.log
                                                                             
grep    "JG\|\-GFX"                                                               %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_GFX.log
grep -i "JG\|gfx\|pixmap"                                                         %SRC_FILE% > %TARGET_DIR%\grepstuff_string_GFX_pixmap.log
grep    "JG\|\-FDM"                                                               %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_FDM.log
grep -i "JG\|KEY_PRESS:\|Showing dialog\|STANDBY STATE\|\-FDM"                    %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_FDM_KeysDialogs.log
grep -i "JG\|KEY_PRESS:\|Showing dialog\|STANDBY STATE\|\-FDM\|\-P_Api"           %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_FDM_Player_KeysDialogs.log
grep -i "JG\|KEY_PRESS:\|Showing dialog\|STANDBY STATE\|\-FDM\|\-P_Api\|-LAE"     %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_FDM_Player_LAE_KeysDialogs.log

rem  Find all occurances of -EPG, -VGV or -CARNG (The LOG in SI-5250 had only -EPG, -VGV and -CARNG entries)
rem (Is "CARNG" the CA Random Number Generator? Doubtful!)
grep    "JG\|STANDBY STATE\|KEY_PRESS:\|Showing dialog\|\-EPG_\|\-VGV\|\-CARNG"   %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_EPG_VGV_CARNG.log

grep    "JG\|\-LAE"                                                               %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_LAE.log
grep    "JG\|\-JAE"                                                               %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_JAE.log
grep    "JG\|STANDBY STATE\|KEY_PRESS:\|Showing dialog\|\-LAE\|\-JAE"             %SRC_FILE% > %TARGET_DIR%\grepstuff_unit_LAE_JAE.log


GOTO :EOF


rem ----------------------------------------------
:GREP_SEVERITIES
rem ----------------------------------------------
@echo GREP_SEVERITIES
set SRC_FILE=%1
set TARGET_DIR=%2
grep !MIL                                    %SRC_FILE% > %TARGET_DIR%\grepstuff_severity_MIL.log
grep -v "Time has been updated to"           %TARGET_DIR%\grepstuff_severity_MIL.log > %TARGET_DIR%\grepstuff_severity_MIL_excl_timeupdates.log
grep    "Time has been updated to"           %SRC_FILE% > %TARGET_DIR%\grepstuff_severity_MIL_timeupdates.log
grep !FATAL                                  %SRC_FILE% > %TARGET_DIR%\grepstuff_severity_FATAL.log
grep !ERROR                                  %SRC_FILE% > %TARGET_DIR%\grepstuff_severity_ERROR.log
grep !WARN                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_severity_WARN.log
grep !INFO                                   %SRC_FILE% > %TARGET_DIR%\grepstuff_severity_INFO.log
grep -v "!MIL\|!FATAL\|!ERROR\|!WARN\|!INFO" %SRC_FILE% > %TARGET_DIR%\grepstuff_severity_others.log

grep -v "Component\-EPG"                     %TARGET_DIR%\grepstuff_severity_FATAL.log >%TARGET_DIR%\grepstuff_severity_FATAL_EPG.log
grep -v "Component\-EPG\|Component\-FSI_UA"  %TARGET_DIR%\grepstuff_severity_ERROR.log >%TARGET_DIR%\grepstuff_severity_ERROR_EPG_FSI_UA.log
rem pause
GOTO :EOF

rem ----------------------------------------------
:DO_DATABASES
rem ----------------------------------------------
@echo DO_DATABASES
set SRC_FILE=%1
set TARGET_DIR=%2

:PCAT_Begin
if NOT exist PCAT.DB goto :PCAT_End
sqlite3_analyzer.exe PCAT.DB > %TARGET_DIR%\PCAT_sqlite3_analyzer.txt
sqlite3.exe PCAT.DB "pragma integrity_check;"> %TARGET_DIR%\db_PCAT_integrity_check.txt

rem #items > %TARGET_DIR%\PCAT_items.txt
rem #python j_bars_to_tabs.py %TARGET_DIR%\item.txt %TARGET_DIR%\db_PCAT_items_tabbed.txt
rem #items_newer.exe -F  > %TARGET_DIR%\db_PCAT_items.txt
rem #grep    "Recd|PVOD|" %TARGET_DIR%\item.txt > %TARGET_DIR%\db_PCAT_items_pvod.rec
rem #grep    "Recd|Rec |" %TARGET_DIR%\item.txt > %TARGET_DIR%\db_PCAT_items_recorded.rec
rem #grep    "Seen|Rec |" %TARGET_DIR%\item.txt >> %TARGET_DIR%\db_PCAT_items_recorded.rec

sqlite3.exe PCAT.DB "SELECT is_viewed, keep, booking_type, actual_start_time, actual_end_time, event_name, shrec_locator, logical_channel, booking_exception, channel_name, series_id, push_locator, trigger_time, program_size, push_expiryend, is_disappeared, is_active, start_time, duration, is_linked, B.event_id, J.booking_job_id, booking_disk_quota_name, booking_source, booking_job_deletion_time, booking_time FROM del_item I, del_booking_jobs J, del_booking_info B LEFT OUTER JOIN av_content A ON A.av_content_id = B.av_content_id WHERE B.event_id = I.event_id AND B.booking_id = J.booking_id ORDER BY ifnull(actual_start_time,trigger_time)"
:PCAT_End

:REMBOOK_Begin
if NOT exist PCAT.DB goto :REMBOOK_End
sqlite3_analyzer.exe REMBOOK.DB > %TARGET_DIR%\REMBOOK_sqlite3_analyzer.txt
sqlite3.exe REMBOOK.DB "pragma integrity_check;"> %TARGET_DIR%\db_REMBOOK_integrity_check.txt
:REMBOOK_End

:MFS_Begin
if NOT exist PCAT.DB goto :MFS_End
sqlite3_analyzer.exe MFS.DB > %TARGET_DIR%\MFS_sqlite3_analyzer.txt
sqlite3.exe MFS.DB "pragma integrity_check;"> %TARGET_DIR%\db_MFS_integrity_check.txt
:MFS_End
GOTO :EOF

rem ************************************************************************
rem ************************************************************************
rem ** FUNCTIONS END
rem ************************************************************************
rem ************************************************************************
