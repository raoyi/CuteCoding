@echo off
Echo Going to set the execution policy of powershell to "Bypass"
powershell -command "& {Set-ExecutionPolicy Bypass}"
Echo Powershell Execution Policy is set to "Bypass"!