#Requires AutoHotkey v2.0

configFile := SubStr(A_ScriptDir, 1, InStr(A_ScriptDir, "\", , -1) - 1) . "\config.ini"
IniWrite("1", configFile, "Settings", "ShowConfigOnLaunch")