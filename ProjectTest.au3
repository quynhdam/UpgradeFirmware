; -- Created with ISN Form Studio 2 for ISN AutoIt Studio -- ;
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <EditConstants.au3>
#include <CommInterface.au3>
#include <CommObsolete.au3>
#include <GuiEdit.au3>
#include <WinAPIFiles.au3>
#include <File.au3>
;#include <Timers.au3>
#include <Date.au3>
HotKeySet("{ESC}", "_Exit")
Opt("GUICoordMode", 1)
Opt("GUIOnEventMode", 1)
Opt("GUIResizeMode", 1)
Opt("WinTitleMatchMode", 2)
Global Const $iPort = 1
Global Const $iBaud = 115200
Global Const $iParity = 0
Global Const $iByteSize = 8
Global Const $iStopBits = 0
Global $g_hTimer, $g_iSecs, $g_iMins, $g_iHour, $g_sTime
Global $iCount = 0
Global $hFile = 0
Global $text_go
Global $text_compare
Global $sResult
Global $sGetTextCmd = ""
Global $tmp = ""
Global $sText = ""
$ProjectTest = GUICreate("ProjectTest",458,437,-1,-1,$WS_OVERLAPPEDWINDOW,-1)
GUISetOnEvent($GUI_EVENT_CLOSE, "Special")
GUISetOnEvent($GUI_EVENT_MINIMIZE, "Special")
GUISetOnEvent($GUI_EVENT_MAXIMIZE, "Special")
;GUISetOnEvent($ProjectTest, "Time")
GUICtrlCreateGroup("Log Serial",7,45,441,337,-1,-1)
GUICtrlSetBkColor(-1,"0xF0F0F0")
Global $edLog = GUICtrlCreateEdit("",15,67,420,28,$WS_VSCROLL,-1)
;GUICtrlSetOnEvent($edLog, "Textchange")
Global $edAllLog = GUICtrlCreateEdit("",15,100,420,270,$WS_VSCROLL,-1)
GUICtrlSetColor(-1,"0xFFFFFF")
GUICtrlSetBkColor(-1,"0x000000")
GUICtrlCreateGroup("",10,0,440,42,-1,-1)
GUICtrlSetBkColor(-1,"0xF0F0F0")
GUICtrlCreateLabel("00:00:00",10,7,206,35,BitOr($SS_CENTER,$SS_CENTERIMAGE))
GUICtrlSetFont(-1,14,700,0,"MS Sans Serif")
GUICtrlSetColor(-1,"0x00FF00")
GUICtrlSetBkColor(-1,"0xFFFF80")
Global $lblStatus = GUICtrlCreateLabel("Waiting",216,7,232,35,BitOr($SS_CENTER,$SS_CENTERIMAGE),-1)
GUICtrlSetFont(-1,14,700,0,"MS Sans Serif")
GUICtrlSetColor(-1,"0xFF0000")
GUICtrlSetBkColor(-1,"0xFFFF80")
Global $btn = GUICtrlCreateButton("Start",180,390,60,20,-1,-1)
GUICtrlSetOnEvent($btn, "COMHandling")
$hStatusBar = _GUICtrlStatusBar_Create($ProjectTest, -1)
GUISetState(@SW_SHOW,$ProjectTest)
; Start timer
$g_hTimer = TimerInit()
AdlibRegister("ProjectTest", 50)
 
While 1
	;$sGetTextCmd &= StdOutRead($tmp)
	;If @error Then ExitLoop 
Wend

Func COMHandling()
			$iRunTime = 1
			;Local Const $sFilePath =  _WinAPI_GetTempFileName(@MyDocumentsDir, "Log1")
			Local Const $sFilePath1 = "C:\Users\QuynhDam\Documents\Log1"
			Local Const $sFilePath2 = "C:\Users\QuynhDam\Documents\Log2"
			Local $sFilePath = $sFilePath1
			$sTextLogBootLoader = "Press any key in 3 secs to enter boot command mode."
			$sWriteFlash =  "Write to flash from 0x80020000 to 0x20000 with B4BA69 bytes"
			
			GUICtrlSetData($lblStatus, "Connected")	
			_GUICtrlEdit_LineScroll($edAllLog, 0, _GUICtrlEdit_GetLineCount($edLog) * 120)
			$sResult = ""		
			$hFile = _CommAPI_OpenCOMPort($iPort, $iBaud, $iParity, $iByteSize, $iStopBits)
			If @error Then Return SetError(@error, @extended, @ScriptLineNumber)
			_CommAPI_ClearCommError($hFile)
			If @error Then Return SetError(@error, @extended, @ScriptLineNumber)			
			Local $iTextScrollback = 2000 * 120
			GUICtrlSetLimit($edAllLog,$iTextScrollback)
			;ConsoleWrite("Run time(s): " & $iRunTime)
			
			While 1
				;MsgBox(0, "Notification", "Run time(s): " & $iRunTime, 1)
				
				$sResult = _CommAPI_ReceiveString($hFile, 1, 0)
				If Not FileWrite($sFilePath, $sResult) Then
					MsgBox($MB_SYSTEMMODAL, "", "An error occurred whilst writing the temporary file.")
					Return False
				EndIf
				
				_GUICtrlStatusBar_SetText($hStatusBar, @TAB & "Lines: " & _GUICtrlEdit_GetLineCount($edAllLog))
				
				If @error Then Return SetError(@error, @extended, @ScriptLineNumber)
				
				If $sResult Then	
					GUICtrlSetData($edAllLog, $sResult , "append")
					
					GUICtrlSetData($edLog, $sResult)
					
					$mess = _GUICtrlEdit_GetText($edLog)
						If StringInStr(_GUICtrlEdit_GetText($edLog), $sTextLogBootLoader) Then
							
							_CommAPI_TransmitData($hFile, " ")
							Local $tmp = Run("C:\Windows\system32\cmd.exe")
							WinActivate("C:\Windows\system32\cmd.exe")
							Sleep(100)
							Send("{ENTER}")
							Send("{SPACE}tftp -i 192.168.1.1 put tclinux.bin {ENTER}")
							;$tmp = Run(@ComSpec & " /c " & 'tftp -i 192.168.1.1 put tclinux.bin {ENTER}', "",@SW_MAXIMIZE,$STDOUT_CHILD)	
							;$tmp = Run(@ComSpec &  " /k " &  "tftp -i 192.168.1.1 put tclinux.bin {ENTER}", "", @SW_SHOW,0)
							WinActivate("ProjectTest")
							$text_compare = "null"
							
							ConsoleWrite($sGetTextCmd)
							$sTextError = "Timeout expired"
							If StringInStr($sGetTextCmd, $sTextError ) Then 
								MsgBox(0, "Error", "Re-check LAN or TFTP")
								Return False 	
							EndIf
						EndIf 
						
						If StringInStr(_GUICtrlEdit_GetText($edLog), $sWriteFlash) Then 
							Sleep(5000);
							_CommAPI_TransmitData($hFile, "go" )
							_CommAPI_TransmitData($hFile, @CRLF )
							WinClose("C:\Windows\system32\cmd.exe")
							;AdlibRegister("MyFunction", 250)
						EndIf
							
						
						$sLinuxStart =  "Please press Enter to activate this console."
						$sLogin = "Enabling SSL security systemEncrypt ROMFILE"
						If StringInStr(_GUICtrlEdit_GetText($edLog),$sLinuxStart) Then 
							
							;_CommAPI_TransmitData($hFile,  @CRLF)
						
							_CommAPI_TransmitData($hFile,  @CRLF)
							Sleep(2000)
							;MsgBox(0, "Notification", "Logging to console", 1)
							_CommAPI_TransmitData($hFile, "ambit" & @LF)
							
							_CommAPI_TransmitData($hFile, "ambitdebug" & @LF)
							
							_CommAPI_TransmitData($hFile, "retsh foxconn168!" & @LF)
							Sleep(100)
							_CommAPI_TransmitData($hFile, " prolinecmd serialnum display" & @LF)
							;MsgBox(0, "Notification", "Logged success", 1)
							If ($iRunTime = 1) Then 
								_CommAPI_TransmitData($hFile, " reboot" &@CRLF)
							EndIf

							If ($iRunTime = 2) Then 
								;MsgBox(0, "Notification", "Run time(s): " & $iRunTime, 1)
								_CommAPI_TransmitData($hFile, @CRLF)
								;ExitLoop
								;Sleep(1000)
								
								For $i = 1 To _FileCountLines($sFilePath)
									$sMess = FileReadLine($sFilePath, $i)
									If StringInStr($sMess, "SerialNum:") Then
										$sText &= @CRLF & $sMess
										
									EndIf
								Next
								MsgBox(0, "", "Checking Serial Number", 1)
								For $i = 1 To _FileCountLines($sFilePath)
									$sMess = FileReadLine($sFilePath, $i)
									If StringInStr($sMess, "SerialNum:") Then
										$sText &= @CRLF & $sMess
										
									EndIf
								Next
								MsgBox(0, "Result", "This is Serial Number of GPON after upgrade firmware." & @CRLF & "Please re-check." & $sText)
								FileDelete($sFilePath)
							EndIf
							
						$iRunTime += 1
						EndIf 
					
				EndIf
			
			Wend
			_CommAPI_ClosePort($hFile)
		
EndFunc




Func Special()
	Select 
		Case @GUI_CtrlId = $GUI_EVENT_CLOSE
			GUIDelete()
			Exit 
		Case @GUI_CtrlId = $GUI_EVENT_MINIMIZE
		
		Case @GUI_CtrlId = $GUI_EVENT_MAXIMIZE
		
		
	EndSelect 
EndFunc


Func ProjectTest()
    _TicksToTime(Int(TimerDiff($g_hTimer)), $g_iHour, $g_iMins, $g_iSecs)
    Local $sTime = $g_sTime ; save current time to be able to test and avoid flicker..
    $g_sTime = StringFormat("%02i:%02i:%02i", $g_iHour, $g_iMins, $g_iSecs)
    If $sTime <> $g_sTime Then ControlSetText("ProjectTest", "", "Static1", $g_sTime)
	
EndFunc   ;==>Timer

Func MyFunction()
	Local Static $iCount = 1
	If $iCount = 1 Then 
	_CommAPI_TransmitData($hFile, @CRLF)
	$iCount = 2
	EndIf 
EndFunc

