# shit-coding...

shutdown.au3  显示提示框，始终置顶，按OK键或关闭窗口后关机

input.au3
Purpose:
         show an input box and generate a file named input.bat

Format:
         input.exe [parameter1] [parameter2] [parameter3]

Explain:
         [parameter1]:variable name. default:input, non essential parameter
         [parameter2]:string length(integer), [parameter2] >= length([parameter3]). if 0, length limitless, non essential parameter
         [parameter3]:string prefix, length <= [parameter2], non essential parameter

Content of input.bat:
         set [parameter1]=[inputed value]
