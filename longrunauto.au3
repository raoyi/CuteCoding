#include <GuiConstantsEx.au3>
Local $submit, $item, $num, $msg, $input, $items

GUICreate("LongRun", 300, 150)
GUICtrlCreateLabel("RunItem:", 10, 10)
$items = GUICtrlCreateCombo("S3", 70, 10, 70, 50)
GUICtrlSetData(-1, "S4|Reboot")
GUICtrlCreateLabel("For", 150, 10)
$input = GUICtrlCreateInput("", 180, 10, 40, 20)
GUICtrlCreateLabel("Circles", 230, 10)
$submit = GUICtrlCreateButton("Submit", 20, 50, 200, 30)

; GUI MESSAGE LOOP
GUISetState(@SW_SHOW)
While 1
	$msg = GUIGetMsg()
	Select
		Case $msg = $GUI_EVENT_CLOSE
			ExitLoop
		Case $msg = $submit
			$item = GUICtrlRead($items)
			$num = GUICtrlRead($input)
			ExitLoop
	EndSelect
WEnd

Run("powershell.exe")
Sleep(500)
Send($num&' '&$item&"{ENTER}") 
