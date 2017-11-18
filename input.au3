#include <GUIConstantsEx.au3>

If $CmdLine[0] = 0 Then
	$labelval = "input"
Else
	$labelval = $CmdLine[1]
EndIf

GUICreate($labelval, 400, 50)

$label = GUICtrlCreateLabel($labelval, 0, 0, 120, 50)
GUICtrlSetFont($label, 30, 400)

$inputbox = GUICtrlCreateInput("", 121, 0, 280, 50)
GUICtrlSetFont($inputbox, 30, 400)

GUISetState()

While 1
	$msg = GUIGetMsg()
	Select
		Case $msg = $inputbox
			$input = GUICtrlRead($inputbox)
			
			If $CmdLine[0] >= 2 And StringLen($input) <> $CmdLine[2] And $CmdLine[2] <> 0 Then
				MsgBox(16, "ERROR", "String Digit Error!")
				ExitLoop
			EndIf
			
			If $CmdLine[0] >= 3 Then
				$prelen = StringLen($CmdLine[3])
				If $CmdLine[3] <> StringLeft($input, $prelen) Or $prelen > $CmdLine[2] Then
					MsgBox(16, "ERROR", "String Prefix Error!")
					ExitLoop
				EndIf
			EndIf
			
			$file = FileOpen("input.bat", 2)
			FileWriteLine($file, "set " & $labelval & "=" & $input)
			FileClose($file)
			ExitLoop
	EndSelect
	
	If $msg = $GUI_EVENT_CLOSE Then ExitLoop
WEnd
