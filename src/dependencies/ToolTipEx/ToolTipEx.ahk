#Requires AutoHotkey v2.0

class RECT {
    L: i32, T: i32, R: i32, B: i32
}

class POINT {
    x: i32, y: i32
}

/**
 * Creates a Pop-up Tooltip window that follows the mouse movement.
 * @param {string} [Text]  
 * If omitted, the existing tooltip (if any) will be hidden.  
 * Otherwise, this parameter is the text to display in the tooltip.
 * @param {number} [TimeOut]  
 * The tooltip will be hidden after the set number of seconds.  
 * If you do not want the tooltip to be hidden automatically after a timeout, set this parameter to 0.
 * @param {interger} [WhichToolTip]  
 * Omit this parameter if you don't need multiple tooltips to appear simultaneously.  
 * Otherwise, this is a number between 1 and 20 to indicate which tooltip window to operate upon.  
 * If unspecified, that number is 1 (the first).
 * @param {interger} Darkmode  
 * - `true` : Enable dark mode.  
 * - `false`: Disable dark mode.  
 * By default, this function will automatically detect whether the system has enabled dark mode.
 * @param {interger} [ClickMode=false]  
 * When the `ClickMode` is `true`, the following features will be enable:  
 * - Holding LButton to move the ToolTip.  
 * - Doble click to close the ToolTip.
 * Otherwise, the Tooltip will follow the mouse movement.
 * @returns {Integer}
 * @author nperovic
 * @see https://github.com/nperovic/ToolTipEx
 */
ToolTipEx(Text := "", TimeOut?, WhichToolTip?, Darkmode?, ClickMode := false)
{
    static timers := Map()
    static EnumCursorPos(hwnd) => (&p) => (DllCall("GetCursorPos", "ptr", p := POINT()), WinExist(hwnd))
    static flags          := (VerCompare(A_OSVersion, "6.2") < 0 ? 0 : 0x10000)
         , isDarkMode     := !RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 1)
         , WM_LBUTTONDOWN := 0x0201, WM_NCLBUTTONDOWN := 0x00A1, WM_LBUTTONDBLCLK := 0x0203
         , _              := (OnMessage(WM_LBUTTONDOWN, OnClickEvent), OnMessage(WM_LBUTTONDBLCLK, OnClickEvent))

    ; Clear existing timer if there is one for this tooltip

    if !IsSet(WhichToolTip)
        ToolTip()
    
    if !(ttw := ToolTip(Text?,,, WhichToolTip?))
        return

    if (Darkmode ??= isDarkMode)
        DllCall("uxtheme\SetWindowTheme", "ptr", ttw, "ptr", StrPtr("DarkMode_Explorer"), "ptr", 0)

    if ClickMode
        return ttw

   


    return ttw

    OnClickEvent(wParam, lParam, msg, hwnd) {
        MouseGetPos(,, &win)
        if WinExist("ahk_class tooltips_class32 ahk_id" . win) {
            switch msg {
                case WM_LBUTTONDOWN: 
                    PostMessage(WM_NCLBUTTONDOWN, 2)
                case WM_LBUTTONDBLCLK:
                    WinClose()
                    ; Clean up timer when tooltip is closed
                    if timers.Has(WhichToolTip ?? 1) {
                        SetTimer(timers[WhichToolTip ?? 1], 0)
                        timers.Delete(WhichToolTip ?? 1)
                    
                    }
                }
            }
        }
    }
