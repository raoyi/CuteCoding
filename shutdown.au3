#include <GUIConstantsEx.au3>

_Main()

;show a window,press OK or exit to shutdown
Func _Main()
	Local $button
	Local $output
	GUICreate("Preload Completed", 300, 150, -1, -1)

	$button = GUICtrlCreateButton(" OK ", 200, 100, 70, 30)
	$output = GUICtrlCreateLabel("Please remove Type-C hub and press OK to shutdown.", 0, 20, 300, 60)
	GUICtrlSetFont($output, 15, 400, "", "Comic Sans MS")

	GUISetState()

	While 1
		If WinActive("Preload Completed") = 0 Then WinActivate("Preload Completed")
		$msg = GUIGetMsg()
		Select
			Case $msg = $button
				Shutdown(1)
		EndSelect
		If $msg = $GUI_EVENT_CLOSE Then Shutdown(1)
	WEnd
EndFunc
