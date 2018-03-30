#include <GuiConstantsEx.au3>

;Local $label1, $label2, $label3, $label4, $label5, $submit, $item, $numcy, $msg, $cy, $items, $idle

GUICreate("LongRun", 300, 150)

$label1 = GUICtrlCreateLabel("Item  ", 10, 10)
GUICtrlSetFont($label1, 15)
$label2 = GUICtrlCreateLabel("for ", 110, 10)
GUICtrlSetFont($label2, 15)
$label3 = GUICtrlCreateLabel("circles    ", 200, 10)
GUICtrlSetFont($label3, 15)
$label4 = GUICtrlCreateLabel("s resume, idle        ", 65, 55)
GUICtrlSetFont($label4, 15)
$label5 = GUICtrlCreateLabel("s", 265, 55)
GUICtrlSetFont($label5, 15)

$items = GUICtrlCreateCombo("S3", 55, 10, 50, 50)
GUICtrlSetData(-1, "S4")
GUICtrlSetFont($items, 15)

$cy = GUICtrlCreateInput("400", 145, 10, 50, 27)
GUICtrlSetFont($cy, 15)
$res = GUICtrlCreateInput("120", 10, 55, 50, 27)
GUICtrlSetFont($res, 15)
$idle = GUICtrlCreateInput("120", 210, 55, 50, 27)
GUICtrlSetFont($idle, 15)

$mode1 = GUICtrlCreateRadio("Silent", 10, 95, 80)
GUICtrlSetFont($mode1, 13)
$mode2 = GUICtrlCreateRadio("Interactive", 10, 120, 120)
GUICtrlSetFont($mode2, 13)
GUICtrlSetState($mode1, $GUI_CHECKED)

$submit = GUICtrlCreateButton("Start", 180, 100, 100, 40)
GUICtrlSetFont($submit, 15)

; GUI MESSAGE LOOP
GUISetState(@SW_SHOW)
While 1
	$msg = GUIGetMsg()
	Select
		Case $msg = $GUI_EVENT_CLOSE
			Exit
		Case $msg = $submit
			$item = GUICtrlRead($items)
			$numcy = GUICtrlRead($cy)
			$rest = GUICtrlRead($res)
			$idlet = GUICtrlRead($idle)
			
			If GUICtrlRead($mode1) = $GUI_CHECKED Then
				$mode = "S"
			ElseIf GUICtrlRead($mode2) = $GUI_CHECKED Then
				$mode = "I"
			EndIf
			
			If $item = "S3" Then
				$item = "Suspend"
				$itemcmd = "3"
			ElseIf $item = "S4" Then
				$item = "Hibernate"
				$itemcmd = "4"
			EndIf
			ExitLoop
	EndSelect
WEnd

Run("powershell.exe")
Sleep(500)

Send("cd .\"&$item&"INEX\{ENTER}")
Send("PowerShell.exe -ExecutionPolicy UnRestricted -File .\"&$item&"INEX-"&$mode&".ps1{ENTER}")
Run("cmd.exe")
Sleep(500)
;Send("pwrtest.exe /sleep /c:2 /d:"&$idlet&" /p:"&$rest&" /h:n /s:"&$itemcmd&"{ENTER}")