#Requires AutoHotkey v2.0

srcPath := SubStr(A_ScriptDir, 1, InStr(A_ScriptDir, "\", , -1) - 1) 
configFile := srcPath . "\config.ini"
IniWrite("1", configFile, "Settings", "ShowConfigOnLaunch")
parentPath := SubStr(srcPath, 1, InStr(srcPath, "\", , -1) - 1) 
Run parentPath . "\command-carousel.ahk"



