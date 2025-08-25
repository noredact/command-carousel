#Requires AutoHotkey v2+
#SingleInstance
try 
    TraySetIcon A_ScriptDir "\src\media\iconConfig.png",,"Freeze"

CycleSelector()

; --- Global Variables ---

class CycleSelector {
    ; Save As... handler
    SaveConfigAs() {
        file := FileSelect("S", A_ScriptDir "\User Configs\config.ini", "Save Config As", "INI Files (*.ini)")
        if (!file)
            return
        this.SaveConfigCore(file)
        MsgBox("Configuration saved to: " file)
    }

    ; Load... handler
    LoadConfigFromFile() {
        file := FileSelect("1", A_ScriptDir "\User Configs\", "Load Config", "INI Files (*.ini)")
        if (!file)
            return
        FileCopy(file, this.CySe_ConfigPath, 1)
        this.LoadMenus()
        this.RefreshMenuList()
        MsgBox("Configuration loaded from: " file)
    }

    ; Update backup count in ini
    UpdateBackupCount() {
        val := this.BackupCountEdit.Value
        if (val = "" || val < 1)
            val := 1
        IniWrite(val, this.CySe_ConfigPath, "Settings", "BackupCount")
    }

    ; Make a backup in src/tmp, keep only N most recent
    MakeBackup() {
        backupDir := A_ScriptDir "\src\tmp"
        if !DirExist(backupDir)
            DirCreate(backupDir)
        timestamp := FormatTime(A_Now, "yyyyMMdd-HHmmss")
        backupFile := backupDir "\config-" timestamp ".ini"
        FileCopy(this.CySe_ConfigPath, backupFile, 1)
        ; Retention logic
        backupCount := IniRead(this.CySe_ConfigPath, "Settings", "BackupCount", 10)
        files := []
        Loop Files, backupDir "\config-*.ini"
            files.Push(A_LoopFileFullPath)
        if (files.Length > backupCount) {
            ; Sort by name (timestamp)
            files.Sort()
            for i, f in files {
                if (i <= files.Length - backupCount)
                    FileDelete(f)
            }
        }
    }

    ; Core save logic, used by SaveConfig and SaveConfigAs
    SaveConfigCore(path) {
        ; Save current config to given path
        ; (copy of SaveConfig, but writes to 'path')
        this.SaveConfig() ; Save to main config
        FileCopy(this.CySe_ConfigPath, path, 1)
    }
    ; Helper to join array elements with a delimiter (for confirmation messages)
    StrJoin(delim, arr*) {
        out := ""
        for i, v in arr[1] {
            if (i > 1)
                out .= delim
            out .= v
        }
        return out
    }

    ; Properties
    CySe_Menus := Map()
    CySe_LeaderKey := ""
    CySe_CycleKey := ""
    CySe_SelectorKey := ""
    CySe_SuspendKey := ""
    CySe_ScriptsDir := ""
    CySe_ConfigPath := ""
    CySe_TemplatePath := ""
    CySe_ScriptPath := ""
    CySe_ShowConfigOnLaunch := ""
    CySe_ShowConfirmOnSave := ""
    SuspendKeyReplaceValue := ""

    ; GUI controls
    MyGui := ""
    MyTab := ""
    LeaderKeyDD := ""
    LeaderKeyEdit := ""
    CycleKeyDD := ""
    CycleKeyEdit := ""
    SelectorKeyDD := ""
    SelectorKeyEdit := ""
    SuspendKeyDD := ""
    SuspendKeyEdit := ""
    ShowGuiCB := ""
    MenuLV := ""
    ItemLV := ""

    ; Constructor
    __New() {
        this.Setup()
    }

    Setup() {
        this.CySe_ConfigPath := A_ScriptDir "\src\config.ini"
        this.CySe_TemplatePath := A_ScriptDir "\src\template"
        this.CySe_ScriptPath := A_ScriptDir "\src\ccarousel-launcher.ahk"
        this.CySe_ScriptsDir := A_ScriptDir "\src\scripts"
        this.oldVer := 0
        
        
        if VerCompare(A_AhkVersion, ">=2.1-alpha") = 0
            this.oldVer := 1
        
        
        if !DirExist(this.CySe_ScriptsDir) {
        DirCreate(this.CySe_ScriptsDir)
        }
        if !FileExist(this.CySe_ConfigPath) {
        this.FirstTimeSetup()
        }
        
        this.CySe_LeaderKey := IniRead(this.CySe_ConfigPath, "Hotkeys", "LeaderKey", "")
        this.CySe_CycleKey := IniRead(this.CySe_ConfigPath, "Hotkeys", "CycleKey", "")
        this.CySe_SelectorKey := IniRead(this.CySe_ConfigPath, "Hotkeys", "SelectorKey", "")
        this.CySe_SuspendKey := IniRead(this.CySe_ConfigPath, "Hotkeys", "SuspendKey", "")
        this.CySe_ShowConfigOnLaunch := IniRead(this.CySe_ConfigPath, "Settings", "ShowConfigOnLaunch", 1)
        this.CySe_ShowConfirmOnSave := IniRead(this.CySe_ConfigPath, "Settings", "ShowConfirmOnSave", 1)
        this.instructionMessage := "While pressing and holding: " . this.CySe_LeaderKey . 
        "`nPress: " . this.CySe_CycleKey . " to cycle through menus. (When you reach the last menu, pressing this again will return to the first menu)`nPress: " . 
        this.CySe_SelectorKey . " to move down the list in the current menu`nRelease: " . 
        this.CySe_LeaderKey . " to run the selected program/script.`nRight Click the icon in the task bar to exit."
        this.scriptProccess := IniRead(this.CySe_ConfigPath, "Script", "PID","")
        
        this.LoadMenus()
        this.ValidateShortcuts()
        
        if this.CySe_ShowConfigOnLaunch
            this.ShowConfigGUI()
        else 
            run this.CySe_ScriptPath
    }

    FirstTimeSetup() {
        MsgBox("No configuration file found. Assuming first launch. Writing .ini file and showing setup GUI.", "Command Carousel Setup", "OK")
        
        FileCopy(this.CySe_TemplatePath, this.CySe_ScriptPath, 1)
        
        IniWrite(this.CySe_ScriptPath, this.CySe_ConfigPath, "Script", "Path")
        IniWrite("Ctrl", this.CySe_ConfigPath, "Hotkeys", "LeaderKey")
        IniWrite("RButton", this.CySe_ConfigPath, "Hotkeys", "CycleKey")
        IniWrite("LButton", this.CySe_ConfigPath, "Hotkeys", "SelectorKey")
        IniWrite(this.CySe_SuspendKey, this.CySe_ConfigPath, "Hotkeys", "SuspendKey")
        IniWrite(1, this.CySe_ConfigPath, "Settings", "ShowConfigOnLaunch")
        IniWrite(1, this.CySe_ConfigPath, "Settings", "ShowConfirmOnSave")
        IniWrite("Menu1", this.CySe_ConfigPath, "Menus", "1")
        IniWrite("Work", this.CySe_ConfigPath, "Menu1", "Name")
        IniWrite("1", this.CySe_ConfigPath, "Menu1", "Order")
        IniWrite("Notepad", this.CySe_ConfigPath, "Menu1", "Item1Name")
        IniWrite("notepad.exe", this.CySe_ConfigPath, "Menu1", "Item1Path")
        IniWrite("Calculator", this.CySe_ConfigPath, "Menu1", "Item2Name")
        IniWrite("calc.exe", this.CySe_ConfigPath, "Menu1", "Item2Path")
        IniWrite("Menu2", this.CySe_ConfigPath, "Menus", "2")
        IniWrite("Settings", this.CySe_ConfigPath, "Menu2", "Name")
        IniWrite("2", this.CySe_ConfigPath, "Menu2", "Order")
        IniWrite("Show settings next launch", this.CySe_ConfigPath, "Menu2", "Item1Name")
        IniWrite(this.CySe_ScriptsDir . "\settingsnextlaunch.ahk", this.CySe_ConfigPath, "Menu2", "Item1Path")
        IniWrite("Show settings now", this.CySe_ConfigPath, "Menu2", "Item2Name")
        IniWrite(this.CySe_ScriptsDir . "\settingsnow.ahk", this.CySe_ConfigPath, "Menu2", "Item2Path")
        IniWrite("Open script parent folder", this.CySe_ConfigPath, "Menu2", "Item3Name")
        IniWrite(A_ScriptDir, this.CySe_ConfigPath, "Menu2", "Item3Path")
    }

    ShowConfigGUI() {
        this.MyGui := Gui()
        ; --- File MenuBar ---
        fileMenu := Menu()
        fileMenu.Add("Save As...", (*) => this.SaveConfigAs())
        fileMenu.Add("Load...", (*) => this.LoadConfigFromFile())
        fileMenu.Add()
        fileMenu.Add("Exit", (*) => this.MyGui.Destroy())
        myMenuBar := MenuBar()
        myMenuBar.Add("File", fileMenu)
        this.MyGui.MenuBar := myMenuBar
        ; --- Tabs and Controls ---
        this.MyTab := this.MyGui.AddTab( "w600 h400",["Hotkeys", "Menus", "Settings"])
        this.MyTab.UseTab("Hotkeys")
        this.MyGui.Add("Text", "x360 y45", "Recommended hotkeys for mouse users:`nLeader Key: Ctrl`nCycle Key: RButton (Right click)`nSelector Key: LButton (Left Click)")
        this.MyGui.Add("Text", "x360 y125", "Recommended hotkeys for keyboard users:`nLeader Key: Ctrl`nCycle Key: , (Comma)`nSelector Key: . (Period)")
        this.MyGui.Add("Text", "x20 y50", "Leader Key:")
        this.LeaderKeyDD := this.MyGui.Add("DropDownList", "x100 y50 w100", this.GetKeyList())
        this.LeaderKeyEdit := this.MyGui.Add("Edit", "x205 y50 w100 ReadOnly", this.CySe_LeaderKey)
        this.LeaderKeyDD.OnEvent("Change", (*) => this.UpdateHotkeyDisplay("Leader"))
        this.MyGui.Add("Text", "x20 y90", "Cycle Key:")
        this.CycleKeyDD := this.MyGui.Add("DropDownList", "x100 y90 w100", this.GetKeyList())
        this.CycleKeyEdit := this.MyGui.Add("Edit", "x205 y90 w100 ReadOnly", this.CySe_CycleKey)
        this.CycleKeyDD.OnEvent("Change", (*) => this.UpdateHotkeyDisplay("Cycle"))
        this.MyGui.Add("Text", "x20 y130", "Selector Key:")
        this.SelectorKeyDD := this.MyGui.Add("DropDownList", "x100 y130 w100", this.GetKeyList())
        this.SelectorKeyEdit := this.MyGui.Add("Edit", "x205 y130 w100 ReadOnly", this.CySe_SelectorKey)
        this.SelectorKeyDD.OnEvent("Change", (*) => this.UpdateHotkeyDisplay("Selector"))
        this.MyGui.Add("Text", "x20 y185", "This key will toggle the hotkeys on/off")
        this.MyGui.Add("Text", "x20 y200", "Suspend Key:")
        this.SuspendKeyDD := this.MyGui.Add("DropDownList", "x100 y200 w100", this.GetKeyList())
        this.SuspendKeyEdit := this.MyGui.Add("Edit", "x205 y200 w100 ReadOnly", this.CySe_SuspendKey)
        this.SuspendKeyDD.OnEvent("Change", (*) => this.UpdateHotkeyDisplay("Suspend"))
        this.instructionText := this.MyGui.Add("Text", "x20 y250", this.instructionMessage)
        ShowKeysBtn := this.MyGui.Add("Button", "x20 y360 w110", "Show Key List")
        ShowKeysBtn.OnEvent("Click", (*) => this.ShowAvailableKeys())
        this.SetInitialHotkeyValues()
        this.MyTab.UseTab("Menus")
        this.MyGui.Add("Text", "x20 y50", "Menus:")
        this.MenuLV := this.MyGui.Add("ListView", "x20 y70 w250 h200 Grid NoSort NoSortHdr", ["Order", "Menu Name", "Items"])
        this.MenuLV.OnEvent("ItemSelect", (*) => this.MenuLV_SelectionChange())
        MoveMenuUpBtn := this.MyGui.Add("Button", "x20 y280 w80", "Move Up")
        MoveMenuUpBtn.OnEvent("Click", (*) => this.MoveMenuUp())
        MoveMenuDownBtn := this.MyGui.Add("Button", "x105 y280 w80", "Move Down")
        MoveMenuDownBtn.OnEvent("Click", (*) => this.MoveMenuDown())
        this.MyGui.Add("Text", "x290 y50", "Items (in selected menu):")
        this.ItemLV := this.MyGui.Add("ListView", "x290 y70 w290 h200 Grid NoSort NoSortHdr", ["Order","Name", "Path"])
        MoveItemUpBtn := this.MyGui.Add("Button", "x290 y280 w80", "Move Up")
        MoveItemUpBtn.OnEvent("Click", (*) => this.MoveItemUp())
        MoveItemDownBtn := this.MyGui.Add("Button", "x375 y280 w80", "Move Down")
        MoveItemDownBtn.OnEvent("Click", (*) => this.MoveItemDown())
        MoveItemMenuBtn := this.MyGui.Add("Button", "x460 y280 w88", "Move to Menu...")
        MoveItemMenuBtn.OnEvent("Click", (*) => this.MoveItemMenu())
        this.RefreshMenuList()
        this.MenuLV.ModifyCol(1, "50")
        this.MenuLV.ModifyCol(2, "150")
        this.MenuLV.ModifyCol(3, "50")
        this.ItemLV.ModifyCol(1, "50")
        this.ItemLV.ModifyCol(2, "140")
        this.ItemLV.ModifyCol(3, "140")
        AddMenuButton := this.MyGui.Add("Button", "x20 y310 w80", "Add Menu")
        AddMenuButton.OnEvent("Click", (*) => this.AddMenu())
        EditMenuButton := this.MyGui.Add("Button", "x105 y310 w80", "Edit Menu")
        EditMenuButton.OnEvent("Click", (*) => this.EditMenu())
        RemoveMenuButton := this.MyGui.Add("Button", "x190 y310 w80", "Remove Menu")
        RemoveMenuButton.OnEvent("Click", (*) => this.RemoveMenu())
        AddItemButton := this.MyGui.Add("Button", "x290 y310 w80", "Add Item")
        AddItemButton.OnEvent("Click", (*) => this.AddItem())
        EditItemButton := this.MyGui.Add("Button", "x375 y310 w80", "Edit Item")
        EditItemButton.OnEvent("Click", (*) => this.EditItem())
        RemoveItemButton := this.MyGui.Add("Button", "x460 y310 w80", "Remove Item")
        RemoveItemButton.OnEvent("Click", (*) => this.RemoveItem())
    this.MyTab.UseTab("Settings")
    this.ShowGuiCB := this.MyGui.Add("Checkbox", "x20 y50 vShowConfigOnLaunch", "Show this configuration window on launch")
    this.ShowGuiCB.Value := this.CySe_ShowConfigOnLaunch
    this.ShowConfirmationCB := this.MyGui.Add("Checkbox", "x20 y+50 vShowConfirmOnSave", "Show confirmation message after save")
    this.ShowConfirmationCB.Value := this.CySe_ShowConfirmOnSave
    this.ShowConfirmationCB.OnEvent("Click", (*) => this.showConfirmChange())
    ; --- Backup Count Setting ---
    backupCount := IniRead(this.CySe_ConfigPath, "Settings", "BackupCount", 10)
    this.BackupCountEdit := this.MyGui.Add("Edit", "x20 y+50 w60 vBackupCountEdit Number", backupCount)
    this.MyGui.Add("Text", "x90 yp+2", "Number of backups to keep (in src\\tmp)")
    this.BackupCountEdit.OnEvent("Change", (*) => this.UpdateBackupCount())
    this.MyTab.UseTab(0)
    SaveButton := this.MyGui.Add("Button", "x20 y410 w80", "Save")
    SaveButton.OnEvent("Click", (*) => this.SaveConfig())
    CloseButton := this.MyGui.Add("Button", "x110 y410 w80", "Close")
    CloseButton.OnEvent("Click", (*) => this.MyGui.Destroy())
    this.MyGui.OnEvent("Close", (*) => this.MyGui.Destroy())
    this.MenuLV.Modify(1, "Select Focus")
    this.MenuLV_SelectionChange()
    this.MyGui.Show()
    ; Save As... handler
    SaveConfigAs() {
        file := FileSelect("S", A_ScriptDir "\User Configs\config.ini", "Save Config As", "INI Files (*.ini)")
        if (!file)
            return
        this.SaveConfigCore(file)
        MsgBox("Configuration saved to: " file)
    }

    ; Load... handler
    LoadConfigFromFile() {
        file := FileSelect("1", A_ScriptDir "\User Configs\", "Load Config", "INI Files (*.ini)")
        if (!file)
            return
        FileCopy(file, this.CySe_ConfigPath, 1)
        this.LoadMenus()
        this.RefreshMenuList()
        MsgBox("Configuration loaded from: " file)
    }

    ; Update backup count in ini
    UpdateBackupCount() {
        val := this.BackupCountEdit.Value
        if (val = "" || val < 1)
            val := 1
        IniWrite(val, this.CySe_ConfigPath, "Settings", "BackupCount")
    }

    ; Make a backup in src/tmp, keep only N most recent
    MakeBackup() {
        backupDir := A_ScriptDir "\src\tmp"
        if !DirExist(backupDir)
            DirCreate(backupDir)
        timestamp := FormatTime(A_Now, "yyyyMMdd-HHmmss")
        backupFile := backupDir "\config-" timestamp ".ini"
        FileCopy(this.CySe_ConfigPath, backupFile, 1)
        ; Retention logic
        backupCount := IniRead(this.CySe_ConfigPath, "Settings", "BackupCount", 10)
        files := []
        Loop Files, backupDir "\config-*.ini"
            files.Push(A_LoopFileFullPath)
        if (files.Length > backupCount) {
            ; Sort by name (timestamp)
            files.Sort()
            for i, f in files {
                if (i <= files.Length - backupCount)
                    FileDelete(f)
            }
        }
    }

    ; Core save logic, used by SaveConfig and SaveConfigAs
    SaveConfigCore(path) {
        ; Save current config to given path
        ; (copy of SaveConfig, but writes to 'path')
        ; ...existing code for validation and writing...
        ; For brevity, just copy current config file
        this.SaveConfig() ; Save to main config
        FileCopy(this.CySe_ConfigPath, path, 1)
    }
    }
    
    showConfirmChange() {
            IniWrite(this.ShowConfirmationCB.Value, this.CySe_ConfigPath, "Settings", "ShowConfirmOnSave")
            this.CySe_ShowConfirmOnSave := this.ShowConfirmationCB.Value
        }
    
    ; All other functions become methods, e.g.:
    MenuLV_SelectionChange() {
        this.ItemLV.Delete()
        selectedRow := this.MenuLV.GetNext()
        if (selectedRow > 0) {
            menuName := this.MenuLV.GetText(selectedRow, 2)
            if this.CySe_Menus.Has(menuName) {
                for _, item in this.CySe_Menus[menuName]["Items"] {
                    this.ItemLV.Add(, A_Index, item["Name"], item["Path"])
                }
            }
        }
    }

    AddMenu(*) {
        result := InputBox("Enter the name for the new menu:", "Add Menu")
        if (result.Result != "OK" || !result.Value)
            return
        newMenuName := result.Value
        SaveConfig(*) {
            this.MakeBackup()
            MsgBox("A menu with that name already exists!")
            return
        }
        maxOrder := 0
        for menuName, menuData in this.CySe_Menus {
            if (menuData["Order"] > maxOrder)
                maxOrder := menuData["Order"]
        }
        newOrder := maxOrder + 1
        menuData := Map()
        menuData["Order"] := newOrder
        menuData["Items"] := []
        this.CySe_Menus[newMenuName] := menuData
        this.RefreshMenuList()
    }

    EditMenu(*) {
        selectedRow := this.MenuLV.GetNext()
        if (!selectedRow) {
            MsgBox("Please select a menu to edit.")
            return
        }
        menuName := this.MenuLV.GetText(selectedRow, 2)
        result := InputBox("Enter the new name for the menu:", "Edit Menu", "", menuName)
        if (result.Result != "OK" || !result.Value)
            return
        newMenuName := result.Value
        if (newMenuName != menuName) {
            if this.CySe_Menus.Has(newMenuName) {
                MsgBox("A menu with that name already exists!")
                return
            }
            this.CySe_Menus[newMenuName] := this.CySe_Menus[menuName]
            this.CySe_Menus.Delete(menuName)
            this.RefreshMenuList()
        }
    }

    RemoveMenu(*) {
            IniWrite(this.BackupCountEdit.Value, this.CySe_ConfigPath, "Settings", "BackupCount")
        selectedRow := this.MenuLV.GetNext()
        if (!selectedRow) {
            MsgBox("Please select a menu to remove.")
            return
        }
        menuName := this.MenuLV.GetText(selectedRow, 2)
        if (MsgBox("Are you sure you want to delete the '" menuName "' menu?", "Confirm", "YesNo") = "Yes") {
            removedOrder := this.CySe_Menus[menuName]["Order"]
            this.CySe_Menus.Delete(menuName)
            for name, menuData in this.CySe_Menus {
                if (menuData["Order"] > removedOrder) {
                    menuData["Order"] -= 1
                }
            }
            this.RefreshMenuList()
            this.ItemLV.Delete()
        }
    }

    AddItem(*) {
        selectedMenuRow := this.MenuLV.GetNext()
        if (!selectedMenuRow) {
            MsgBox("Please select a menu first.")
            return
        }
        menuName := this.MenuLV.GetText(selectedMenuRow, 2)
        result := InputBox("Enter the item's name:", "Add Item")
        if (result.Result != "OK" || !result.Value)
            return
        newItemName := result.Value
        response := MsgBox("How do you want to specify the path?`n`nYes = Browse for specific file`nNo = Type simple command/path", "Select Path Method", "YesNo")
        newItemPath := ""
        if (response = "Yes") {
            newItemPath := FileSelect(, this.CySe_ScriptsDir, "Select executable or file", "All Files (*.*)|Executables (*.exe;*.bat;*.cmd)|*.*|*.exe;*.bat;*.cmd")
            if (!newItemPath)
                return
        } else {
            result := InputBox("Enter the command or path (e.g., notepad.exe, calc.exe):", "Add Item")
            if (result.Result != "OK" || !result.Value)
                return
            newItemPath := result.Value
        }
        this.CySe_Menus[menuName]["Items"].Push(Map("Name", newItemName, "Path", newItemPath))
        if (InStr(newItemPath, "\\") || InStr(newItemPath, "/")) {
            this.CreateShortcut(newItemName, newItemPath)
        }
        this.RefreshItemList(menuName)
        this.RefreshMenuList()
    }

    EditItem(*) {
        selectedMenuRow := this.MenuLV.GetNext()
        selectedItemRow := this.ItemLV.GetNext()
        if (!selectedMenuRow || !selectedItemRow) {
            MsgBox("Please select a menu and an item to edit.")
            return
        }
        menuName := this.MenuLV.GetText(selectedMenuRow, 2)
        itemName := this.ItemLV.GetText(selectedItemRow, 2)
        itemPath := this.ItemLV.GetText(selectedItemRow, 3)
        result := InputBox("Enter the new item name:", "Edit Item", "", itemName)
        if (result.Result != "OK" || !result.Value)
            return
        newItemName := result.Value
        response := MsgBox("How do you want to change the path?`n`nYes = Browse for specific file`nNo = Type command/path`nCancel = Keep current path (" itemPath ")", "Edit Item Path", "YesNoCancel")
        newItemPath := itemPath
        if (response = "Yes") {
            startDir := this.CySe_ScriptsDir
            if (InStr(itemPath, "\\") && FileExist(itemPath)) {
                SplitPath(itemPath, , &itemDir)
                startDir := itemDir
            }
            selectedPath := FileSelect(, startDir, "Select executable or file", "All Files (*.*)|Executables (*.exe;*.bat;*.cmd)|*.*|*.exe;*.bat;*.cmd")
            if (!selectedPath)
                return
            newItemPath := selectedPath
        } else if (response = "No") {
            result := InputBox("Enter the command or path (e.g., notepad.exe, calc.exe):", "Edit Item", "", itemPath)
            if (result.Result != "OK" || !result.Value)
                return
            newItemPath := result.Value
        }
        this.CySe_Menus[menuName]["Items"][selectedItemRow] := Map("Name", newItemName, "Path", newItemPath)
        if (newItemPath != itemPath && (InStr(newItemPath, "\\") || InStr(newItemPath, "/"))) {
            this.RemoveShortcut(itemName)
            this.CreateShortcut(newItemName, newItemPath)
        } else if (newItemName != itemName) {
            this.RenameShortcut(itemName, newItemName)
        }
        this.RefreshItemList(menuName)
    }

    RemoveItem(*) {
        selectedMenuRow := this.MenuLV.GetNext()
        ; Get all selected item rows
        selectedItemRows := []
        row := 0
        while (row := this.ItemLV.GetNext(row)) {
            selectedItemRows.Push(row)
        }
        if (!selectedMenuRow || selectedItemRows.Length = 0) {
            MsgBox("Please select a menu and at least one item to remove.")
            return
        }
        menuName := this.MenuLV.GetText(selectedMenuRow, 2)
        ; Gather item names for confirmation
        itemNames := []
        for _, idx in selectedItemRows {
            itemNames.Push(this.ItemLV.GetText(idx, 2))
        }
    msg := "Are you sure you want to delete the following " itemNames.Length " item(s)?`n`n- " . this.StrJoin("`n- ", itemNames)
        if (MsgBox(msg, "Confirm", "YesNo") = "Yes") {
            ; Sort descending so RemoveAt doesn't shift indices
            n := selectedItemRows.Length
            loop n - 1 {
                i := A_Index
                loop n - i {
                    j := A_Index
                    if (selectedItemRows[j] < selectedItemRows[j+1]) {
                        temp := selectedItemRows[j]
                        selectedItemRows[j] := selectedItemRows[j+1]
                        selectedItemRows[j+1] := temp
                    }
                }
            }
            ; Remove shortcuts and items
            for _, idx in selectedItemRows {
                this.RemoveShortcut(this.CySe_Menus[menuName]["Items"][idx]["Name"])
                this.CySe_Menus[menuName]["Items"].RemoveAt(idx)
            }
            this.RefreshItemList(menuName)
            this.RefreshMenuList()
        }
    }

    MoveMenuUp(*) {
        selectedRow := this.MenuLV.GetNext()
        if (selectedRow <= 1) {
            return
        }
        menuName := this.MenuLV.GetText(selectedRow, 2)
        prevMenuName := this.MenuLV.GetText(selectedRow - 1, 2)
        currentOrder := this.CySe_Menus[menuName]["Order"]
        prevOrder := this.CySe_Menus[prevMenuName]["Order"]
        this.CySe_Menus[menuName]["Order"] := prevOrder
        this.CySe_Menus[prevMenuName]["Order"] := currentOrder
        this.RefreshMenuList()
        this.MenuLV.Modify(selectedRow - 1, "Select Focus")
    }

    MoveMenuDown(*) {
        selectedRow := this.MenuLV.GetNext()
        if (selectedRow = 0 || selectedRow = this.MenuLV.GetCount()) {
            return
        }
        menuName := this.MenuLV.GetText(selectedRow, 2)
        nextMenuName := this.MenuLV.GetText(selectedRow + 1, 2)
        currentOrder := this.CySe_Menus[menuName]["Order"]
        nextOrder := this.CySe_Menus[nextMenuName]["Order"]
        this.CySe_Menus[menuName]["Order"] := nextOrder
        this.CySe_Menus[nextMenuName]["Order"] := currentOrder
        this.RefreshMenuList()
        this.MenuLV.Modify(selectedRow + 1, "Select Focus")
    }

    RefreshMenuList() {
        selectedRow := this.MenuLV.GetNext()
        selectedMenuName := ""
        if (selectedRow > 0) {
            selectedMenuName := this.MenuLV.GetText(selectedRow, 2)
        }
        menuArray := []
        for menuName, menuData in this.CySe_Menus {
            menuArray.Push({Name: menuName, Order: menuData["Order"], Data: menuData})
        }
        this.SortMenuArray(menuArray)
        this.MenuLV.Delete()
        newSelectedRow := 0
        for menu in menuArray {
            rowNum := this.MenuLV.Add(, menu.Order, menu.Name, menu.Data["Items"].Length)
            if (menu.Name = selectedMenuName) {
                newSelectedRow := rowNum
            }
        }
        if (newSelectedRow > 0) {
            this.MenuLV.Modify(newSelectedRow, "Select Focus")
            this.MenuLV_SelectionChange()
        }
    }

    MoveItemUp(*) {
        selectedMenuRow := this.MenuLV.GetNext()
        ; Get all selected item rows
        selectedItemRows := []
        row := 0
        while (row := this.ItemLV.GetNext(row)) {
            selectedItemRows.Push(row)
        }
        if (!selectedMenuRow || selectedItemRows.Length = 0)
            return
        ; Sort ascending so we move topmost first
        n := selectedItemRows.Length
        loop n - 1 {
            i := A_Index
            loop n - i {
                j := A_Index
                if (selectedItemRows[j] > selectedItemRows[j+1]) {
                    temp := selectedItemRows[j]
                    selectedItemRows[j] := selectedItemRows[j+1]
                    selectedItemRows[j+1] := temp
                }
            }
        }
        menuName := this.MenuLV.GetText(selectedMenuRow, 2)
        items := this.CySe_Menus[menuName]["Items"]
        ; Only move if all selected rows are above 1
        for _, idx in selectedItemRows {
            if (idx <= 1)
                return
        }
        ; Move each selected item up, preserving relative order
        for _, idx in selectedItemRows {
            temp := items[idx].Clone()
            items[idx] := items[idx - 1].Clone()
            items[idx - 1] := temp
        }
        this.RefreshItemList(menuName)
        ; Reselect moved items
        for _, idx in selectedItemRows {
            this.ItemLV.Modify(idx - 1, "Select")
        }
        this.ItemLV.Modify(selectedItemRows[1] - 1, "Focus")
    }

    MoveItemDown(*) {
        selectedMenuRow := this.MenuLV.GetNext()
        ; Get all selected item rows
        selectedItemRows := []
        row := 0
        while (row := this.ItemLV.GetNext(row)) {
            selectedItemRows.Push(row)
        }
        if (!selectedMenuRow || selectedItemRows.Length = 0)
            return
        ; Sort descending so we move bottommost first
        n := selectedItemRows.Length
        loop n - 1 {
            i := A_Index
            loop n - i {
                j := A_Index
                if (selectedItemRows[j] < selectedItemRows[j+1]) {
                    temp := selectedItemRows[j]
                    selectedItemRows[j] := selectedItemRows[j+1]
                    selectedItemRows[j+1] := temp
                }
            }
        }
        menuName := this.MenuLV.GetText(selectedMenuRow, 2)
        items := this.CySe_Menus[menuName]["Items"]
        maxIdx := this.ItemLV.GetCount()
        ; Only move if all selected rows are below max
        for _, idx in selectedItemRows {
            if (idx >= maxIdx)
                return
        }
        ; Move each selected item down, preserving relative order
        for _, idx in selectedItemRows {
            temp := items[idx].Clone()
            items[idx] := items[idx + 1].Clone()
            items[idx + 1] := temp
        }
        this.RefreshItemList(menuName)
        ; Reselect moved items
        for _, idx in selectedItemRows {
            this.ItemLV.Modify(idx + 1, "Select")
        }
        this.ItemLV.Modify(selectedItemRows[1] + 1, "Focus")
    }
    
    ; Allows user to move item to a different menu or create a new menu and move it to that. 
    MoveItemMenu(*) {
        selectedMenuRow := this.MenuLV.GetNext()
        ; Get all selected item rows
        selectedItemRows := []
        row := 0
        while (row := this.ItemLV.GetNext(row)) {
            selectedItemRows.Push(row)
        }
        if (!selectedMenuRow || selectedItemRows.Length = 0) {
            MsgBox("Please select a menu and at least one item to move.")
            return
        }
        currentMenuName := this.MenuLV.GetText(selectedMenuRow, 2)
        ; Gather all selected items (in order, highest to lowest for safe removal)
        itemsToMove := []
        for idx in selectedItemRows {
            itemsToMove.Push(this.CySe_Menus[currentMenuName]["Items"][idx])
        }
        ; Sort selectedItemRows descending so RemoveAt doesn't shift indices
        ; Manual bubble sort (descending)
        n := selectedItemRows.Length
        loop n - 1 {
            i := A_Index
            loop n - i {
                j := A_Index
                if (selectedItemRows[j] < selectedItemRows[j+1]) {
                    temp := selectedItemRows[j]
                    selectedItemRows[j] := selectedItemRows[j+1]
                    selectedItemRows[j+1] := temp
                }
            }
        }
        menuNames := []
        for menuName, _ in this.CySe_Menus {
            menuNames.Push(menuName)
        }
        moveMenuGui := Gui(, "Change Item's Menu")
        moveMenuGui.Add("Text", "x20 y20", "Select a menu to move the item(s) to:")
        menuDD := moveMenuGui.Add("DropDownList", "x20 y50 w180", menuNames)
        menuDD.Choose(1)
        moveBtn := moveMenuGui.Add("Button", "x20 y90 w80", "Move")
        newMenuBtn := moveMenuGui.Add("Button", "x110 y90 w80", "New Menu...")
        cancelBtn := moveMenuGui.Add("Button", "x200 y90 w70", "Cancel")

        moveMenuGui.OnEvent("Close", MoveMenuGui_Close)
        moveBtn.OnEvent("Click", MoveMenuGui_Move)
        newMenuBtn.OnEvent("Click", MoveMenuGui_NewMenu)
        cancelBtn.OnEvent("Click", MoveMenuGui_Cancel)
        moveMenuGui.Show("w300 h200")

        this_ := this ; for closure
        ; Handler functions
        MoveMenuGui_Close(*) {
            moveMenuGui.Destroy()
        }
        MoveMenuGui_Move(*) {
            targetMenuName := menuDD.Text
            if (targetMenuName == currentMenuName) {
                MsgBox("Item(s) already in the selected menu.")
                return
            }
            ; Remove all selections from MenuLV
            menuCount := this_.MenuLV.GetCount()
            Loop menuCount {
                this_.MenuLV.Modify(A_Index, "-Select -Focus")
            }
            ; Remove items from current menu (descending order)
            for _, idx in selectedItemRows {
                this_.CySe_Menus[currentMenuName]["Items"].RemoveAt(idx)
            }
            ; Add all items to target menu
            for _, item in itemsToMove {
                this_.CySe_Menus[targetMenuName]["Items"].Push(item)
            }
            moveMenuGui.Destroy()
            this_.RefreshMenuList()
            ; Set MenuLV selection to the new menu
            menuCount := this_.MenuLV.GetCount()
            foundRow := 0
            Loop menuCount {
                row := A_Index
                if (this_.MenuLV.GetText(row, 2) == targetMenuName) {
                    foundRow := row
                    break
                }
            }
            if (foundRow) {
                this_.MenuLV.Modify(foundRow, "Select Focus")
            }
            this_.RefreshItemList(targetMenuName)
        }
        MoveMenuGui_NewMenu(*) {
            result := InputBox("Enter the name for the new menu:", "New Menu")
            if (result.Result != "OK" || !result.Value)
                return
            newMenuName := result.Value
            if this_.CySe_Menus.Has(newMenuName) {
                MsgBox("A menu with that name already exists!")
                return
            }
            maxOrder := 0
            for menuName, menuData in this_.CySe_Menus {
                if (menuData["Order"] > maxOrder)
                    maxOrder := menuData["Order"]
            }
            newOrder := maxOrder + 1
            menuData := Map()
            menuData["Order"] := newOrder
            menuData["Items"] := []
            ; Remove all selections from MenuLV
            menuCount := this_.MenuLV.GetCount()
            Loop menuCount {
                this_.MenuLV.Modify(A_Index, "-Select -Focus")
            }
            ; Remove items from current menu (descending order)
            for _, idx in selectedItemRows {
                this_.CySe_Menus[currentMenuName]["Items"].RemoveAt(idx)
            }
            ; Add all items to new menu
            for _, item in itemsToMove {
                menuData["Items"].Push(item)
            }
            this_.CySe_Menus[newMenuName] := menuData
            moveMenuGui.Destroy()
            this_.RefreshMenuList()
            ; Set MenuLV selection to the new menu
            menuCount := this_.MenuLV.GetCount()
            foundRow := 0
            Loop menuCount {
                row := A_Index
                if (this_.MenuLV.GetText(row, 2) == newMenuName) {
                    foundRow := row
                    break
                }
            }
            if (foundRow) {
                this_.MenuLV.Modify(foundRow, "Select Focus")
            }
            this_.RefreshItemList(newMenuName)
        }
        MoveMenuGui_Cancel(*) {
            moveMenuGui.Destroy()
        }
    }
    
    RefreshItemList(menuName) {
        this.ItemLV.Delete()
        for index, item in this.CySe_Menus[menuName]["Items"] {
            this.ItemLV.Add(, index, item["Name"], item["Path"])
        }
    }

    SaveConfig(*) {
        ; make sure no blank hotkeys
        if (!this.LeaderKeyEdit.Value || !this.CycleKeyEdit.Value || !this.SelectorKeyEdit.Value) {
            MsgBox("Please set all hotkeys before saving.")
            return
        }
        
        ; make sure no duplicate hotkeys
        if (this.LeaderKeyEdit.Value = this.CycleKeyEdit.Value || 
            this.LeaderKeyEdit.Value = this.SelectorKeyEdit.Value || 
            this.CycleKeyEdit.Value = this.SelectorKeyEdit.Value) {
            MsgBox("Hotkeys must be unique. Please change them before saving.")
            return
        }
        
        ; Close script if it's running
        if (this.scriptProccess != "") {
            try {
                ProcessClose this.scriptProccess
            } catch as e {
                MsgBox("Error closing the script process: " e.Message)
                return
            }
        }
        ; Clear existing config/script
        FileDelete(this.CySe_ConfigPath)
        FileDelete(this.CySe_ScriptPath)
        
        ; overwrite formatted script
        FileCopy this.CySe_TemplatePath, this.CySe_ScriptPath, 1
        
        ; Save Hotkeys
        
        IniWrite(this.LeaderKeyEdit.Value, this.CySe_ConfigPath, "Hotkeys", "LeaderKey")
        IniWrite(this.CycleKeyEdit.Value, this.CySe_ConfigPath, "Hotkeys", "CycleKey")
        IniWrite(this.SelectorKeyEdit.Value, this.CySe_ConfigPath, "Hotkeys", "SelectorKey")
        IniWrite(this.SuspendKeyEdit.Value, this.CySe_ConfigPath, "Hotkeys", "SuspendKey")
        ; Save Settings
        IniWrite(this.ShowGuiCB.Value, this.CySe_ConfigPath, "Settings", "ShowConfigOnLaunch")
        IniWrite(this.ShowConfirmationCB.Value, this.CySe_ConfigPath, "Settings", "ShowConfirmOnSave")
        ; Save Script Path
        IniWrite(this.CySe_ScriptPath, this.CySe_ConfigPath, "Script", "Path")
        ; Sort menus by order before saving
        menuArray := []
        for menuName, menuData in this.CySe_Menus {
            menuArray.Push({Name: menuName, Order: menuData["Order"], Data: menuData})
        }
        this.SortMenuArray(menuArray)
        ; Save Menus in correct order
        menuCount := 1
        for menu in menuArray {
            menuId := "Menu" menuCount
            IniWrite(menuId, this.CySe_ConfigPath, "Menus", menuCount)
            IniWrite(menu.Name, this.CySe_ConfigPath, menuId, "Name")
            IniWrite(menu.Order, this.CySe_ConfigPath, menuId, "Order")
            
            itemCount := 1
            for _, item in menu.Data["Items"] {
                IniWrite(item["Name"], this.CySe_ConfigPath, menuId, "Item" itemCount "Name")
                IniWrite(item["Path"], this.CySe_ConfigPath, menuId, "Item" itemCount "Path")
                itemCount++
            }
            menuCount++
        }
        
        this.getTTVar(this.oldVer)
        
        ; Replace variables in the script template
        this.ReplaceFileVariables(this.CySe_ScriptPath, "REPLACEWITHLEADER", this.LeaderKeyEdit.Value)
        this.ReplaceFileVariables(this.CySe_ScriptPath, "REPLACEWITHCYCLE", this.CycleKeyEdit.Value)
        this.ReplaceFileVariables(this.CySe_ScriptPath, "REPLACEWITHSELECTOR", this.SelectorKeyEdit.Value)
        this.ReplaceFileVariables(this.CySe_ScriptPath, "REPLACE92", this.tt92Var)
        this.ReplaceFileVariables(this.CySe_ScriptPath, "REPLACE139", this.tt139Var)
        this.ReplaceFileVariables(this.CySe_ScriptPath, "REPLACE112", this.tt112Var)
        this.ReplaceFileVariables(this.CySe_ScriptPath, "REPLACEVER", this.verVar)
        
        this.SuspendKeyReplaceValue := ""
        if (this.SuspendKeyEdit.Value != "") {
            this.SuspendKeyReplaceValue := "#SuspendExempt`n~" . this.CySe_SuspendKey . ":: {`n"
            this.SuspendKeyReplaceValue .= "
            (
            try
                TraySetIcon A_ScriptDir "\media\icon.png"
            Suspend
            if A_isSuspended {
                try
                    TraySetIcon A_ScriptDir "\media\iconPause.png",,"Freeze"
            }
            }
            #SuspendExempt False
            )"
            }
        this.ReplaceFileVariables(this.CySe_ScriptPath, "REPLACEWITHSUSPEND", this.SuspendKeyReplaceValue)
        
        ; Create shortcuts for all full paths
        this.CreateAllShortcuts()
        this.MyGui.Destroy()
        if this.CySe_ShowConfirmOnSave
            MsgBox("Configuration saved successfully!`n`nThe script will now run with the updated settings.", "Configuration Saved", "OK Icon")
        Run(this.CySe_ScriptPath)
    }

    getTTVar(versionBool) {
        if versionBool = 1 {
            this.tt92Var := "ToolTip curMenu ,,,5"
            this.tt112Var := "ToolTip selector.sectionMenu.ttm ,,,5"
            this.tt139Var := "ToolTip ,,,5"
            this.verVar := ";"
            return
        }
        else {
        this.tt92Var := "ToolTipEx curMenu ,,5"
        this.tt112Var := "ToolTipEx selector.sectionMenu.ttm ,,5"
        this.tt139Var := "ToolTipEx ,,5"
        this.verVar  := ""
        return
        }
    }
    

    ReplaceFileVariables(filePath, targetVar, newContent) {
        try {
            fileContent := FileRead(filePath)
            pattern := "%%" . targetVar . "%%"
            newFileContent := StrReplace(fileContent, pattern, newContent)
            if (fileContent != newFileContent) {
                FileDelete(filePath)
                FileAppend(newFileContent, filePath)
                return true
            }
            return true
        } catch as e {
            MsgBox("Error replacing variables in file: " e.Message)
            return false
        }
    }

    ; --- Shortcut Management Methods ---
    CreateShortcut(itemName, targetPath) {
        if (!targetPath || !FileExist(targetPath))
            return false
        if this.SkipShortcutsInScriptsDir(targetPath)
            return true
        cleanName := RegExReplace(itemName, "[<>:`"`"/\\|?*]", "_")
        shortcutPath := this.CySe_ScriptsDir "\" cleanName ".lnk"
        try {
            WshShell := ComObject("WScript.Shell")
            Shortcut := WshShell.CreateShortcut(shortcutPath)
            Shortcut.TargetPath := targetPath
            SplitPath(targetPath, , &workingDir)
            Shortcut.WorkingDirectory := workingDir
            Shortcut.Save()
            return true
        } catch as e {
            MsgBox("Error creating shortcut for '" itemName "':`n" e.Message)
            return false
        }
    }

    RemoveShortcut(itemName) {
        cleanName := RegExReplace(itemName, "[<>:`"`"/\\|?*]", "_")
        shortcutPath := this.CySe_ScriptsDir "\" cleanName ".lnk"
        if (FileExist(shortcutPath)) {
            try {
                FileDelete(shortcutPath)
                return true
            } catch as e {
                MsgBox("Error removing shortcut for '" itemName "':`n" e.Message)
                return false
            }
        }
        return true
    }

    RenameShortcut(oldName, newName) {
        cleanOldName := RegExReplace(oldName, "[<>:`"`"/\\|?*]", "_")
        cleanNewName := RegExReplace(newName, "[<>:`"`"/\\|?*]", "_")
        oldPath := this.CySe_ScriptsDir "\" cleanOldName ".lnk"
        newPath := this.CySe_ScriptsDir "\" cleanNewName ".lnk"
        msgbox oldPath
        msgbox newPath
        if (FileExist(oldPath) && oldPath != newPath) {
            try {
                FileMove(oldPath, newPath)
                return true
            } catch as e {
                MsgBox("Error renaming shortcut from '" oldName "' to '" newName "':`n" e.Message)
                return false
            }
        }
        return true
    }

    CreateAllShortcuts() {
        for menuName, menuData in this.CySe_Menus {
            for _, item in menuData["Items"] {
                itemPath := item["Path"]
                if (InStr(itemPath, "\\") || InStr(itemPath, "/")) {
                    this.CreateShortcut(item["Name"], itemPath)
                }
            }
        }
    }

ValidateShortcuts() {
    CySe_Menus := this.CySe_Menus
    
    brokenPaths := []
    missingShortcuts := []
    
    for menuName, menuData in CySe_Menus {
        for _, item in menuData["Items"] {
            itemName := item["Name"]
            itemPath := item["Path"]
            
            if this.SkipShortcutsInScriptsDir(itemPath)
                return true 
            
            ; Check if it's a full path
            if (InStr(itemPath, "\") || InStr(itemPath, "/")) {
                ; Check if the target file exists
                if (!FileExist(itemPath)) {
                    brokenPaths.Push(menuName ": " itemName " -> " itemPath)
                }
                
                ; Check if shortcut exists, create if missing
                cleanName := RegExReplace(itemName, "[<>:`"`"/\\|?*]", "_")
                shortcutPath := this.CySe_ScriptsDir "\" cleanName ".lnk"
                if (!FileExist(shortcutPath)) {
                    missingShortcuts.Push(itemName)
                    this.CreateShortcut(itemName, itemPath)
                }
            }
        }
    }
    
    ; Report any issues
    if (brokenPaths.Length > 0) {
        brokenList := ""
        for _, path in brokenPaths {
            brokenList .= "• " path "`n"
        }
        MsgBox("Warning: The following paths no longer exist:`n`n" brokenList "`nPlease update your configuration.", "Broken Paths Found", "OK Icon!")
    }
    
    if (missingShortcuts.Length > 0) {
        MsgBox("Created " missingShortcuts.Length " missing shortcuts in the scripts directory.", "Shortcuts Updated", "OK")
    }
}
LoadMenus() {
    CySe_Menus := this.CySe_Menus
    CySe_ConfigPath:= this.CySe_ConfigPath
    CySe_Menus := Map() ; Clear and reinitialize
    
    menuCount := 1
    while (menuNum := IniRead(CySe_ConfigPath, "Menus", menuCount, "")) {
        menuName := IniRead(CySe_ConfigPath, menuNum, "Name", "")
        menuOrder := IniRead(CySe_ConfigPath, menuNum, "Order", menuCount)
        if (menuName != "") {
            menuData := Map()
            menuData["Order"] := Integer(menuOrder)
            menuData["Items"] := []
            
            itemNum := 1
            while true {
                itemName := IniRead(CySe_ConfigPath, menuNum, "Item" itemNum "Name", "")
                itemPath := IniRead(CySe_ConfigPath, menuNum, "Item" itemNum "Path", "")
                if (itemName = "" || itemPath = "")
                    break
                menuData["Items"].Push(Map("Name", itemName, "Path", itemPath))
                itemNum++
            }
            this.CySe_Menus[menuName] := menuData
        }
        menuCount++
    }
}
    SkipShortcutsInScriptsDir(targetPath) {
        if InStr(targetPath, this.CySe_ScriptsDir)
            return true
        else
            return false
    }

    GetKeyList() {
        return [
            "None",
            "Ctrl", "Alt", "Shift", "Win", "LCtrl", "LAlt", "LShift", "LWin", "RCtrl", "RAlt", "RShift", "RWin",
            "LButton", "RButton", "MButton", "XButton1",
            ; "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
            ; "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
            ; "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
            ".", ",", "-", "=", "'", ";", "\", "[", "]", "``",
            "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
            "Space", "Tab", "Enter", "Escape", "Backspace", "Delete", "Insert",
            "Home", "End", "PgUp", "PgDn", "Up", "Down", "Left", "Right",
            "Numpad0", "Numpad1", "Numpad2", "Numpad3", "Numpad4", "Numpad5",
            "Numpad6", "Numpad7", "Numpad8", "Numpad9", "NumpadDot", "NumpadEnter",
            "NumpadAdd", "NumpadSub", "NumpadMult", "NumpadDiv",
            "CapsLock", "ScrollLock", "NumLock", "PrintScreen", "Pause", "AppsKey"
        ]
    }

    SetInitialHotkeyValues() {
        this.ParseAndSetHotkey(this.CySe_LeaderKey, this.LeaderKeyDD, this.LeaderKeyEdit)
        this.ParseAndSetHotkey(this.CySe_CycleKey, this.CycleKeyDD, this.CycleKeyEdit)
        this.ParseAndSetHotkey(this.CySe_SelectorKey, this.SelectorKeyDD, this.SelectorKeyEdit)
        this.ParseAndSetHotkey(this.CySe_SuspendKey, this.SuspendKeyDD, this.SuspendKeyEdit)
    }

    ParseAndSetHotkey(hotkeyStr, keyDD, editBox) {
        if (!hotkeyStr) {
            keyDD.Choose(1)
            editBox.Value := ""
            return
        }
        key := hotkeyStr
        keyList := this.GetKeyList()
        for i, keyOption in keyList {
            if (keyOption = key) {
                keyDD.Choose(i)
                break
            }
        }
        editBox.Value := hotkeyStr
    }

    UpdateHotkeyDisplay(type) {
        local keyDD, editBox
        if (type = "Leader") {
            keyDD := this.LeaderKeyDD
            editBox := this.LeaderKeyEdit
            IniWrite(this.LeaderKeyEdit.Value, this.CySe_ConfigPath, "Hotkeys", "LeaderKey")
        } else if (type = "Cycle") {
            keyDD := this.CycleKeyDD
            IniWrite(this.CycleKeyEdit.Value, this.CySe_ConfigPath, "Hotkeys", "CycleKey")
            editBox := this.CycleKeyEdit
        } else if (type = "Selector") {
            IniWrite(this.SelectorKeyEdit.Value, this.CySe_ConfigPath, "Hotkeys", "SelectorKey")
            keyDD := this.SelectorKeyDD
            editBox := this.SelectorKeyEdit
        } else if (type = "Suspend") {
            IniWrite(this.SuspendKeyEdit.Value, this.CySe_ConfigPath, "Hotkeys", "SuspendKey")
            keyDD := this.SuspendKeyDD
            editBox := this.SuspendKeyEdit
        }
        keyText := keyDD.Text
        if keyText = "None"
            keyText := ""
        hotkeyStr := keyText
        editBox.Value := hotkeyStr
        this.instructionMessage := "While pressing and holding " . this.LeaderKeyEdit.Value . 
        "`nPress " . this.CycleKeyEdit.Value . " to cycle through menus. (When you reach the last menu, pressing this again will return to the first menu)`nPress " . 
        this.SelectorKeyEdit.Value . " to move down the list in the current menu`nRelease " . 
        this.LeaderKeyEdit.Value . " to run the selected program/script.`nRight Click the icon in the task bar to exit."
        
        this.instructionText.Value := this.instructionMessage
    }

    ShowAvailableKeys() {
        KeysGui := Gui("+Resize", "AutoHotkey Available Keys Reference")
        KeysGui.Add("Text", "x10 y10", "Common AutoHotkey Keys (select from dropdowns above):")
        keysArr := this.getKeyList()
        for keys in keysArr {
            if (keys = "RWin" ||
            keys = "XButton1" || keys = "``" ||
            keys = "m" || keys = "z" ||
            keys = "0" || keys = "F12" ||
            keys = "Insert" || keys = "Right" ||
            keys = "Numpad5" || keys = "NumpadEnter" || keys = "NumpadDiv" ||
            keys = "AppsKey") {
                keysText .= keys "`n`n" 
            }
            else {
                keysText  .= keys " "
            }
            }
        KeysGui.Add("Text", "x10 y40 w500 h300", keysText)
        KeysGui.Add("Button", "x10 y350 w100", "Close").OnEvent("Click", (*) => KeysGui.Destroy())
        KeysGui.Show("w520 h390")
    }

SortMenuArray(arr) {
    ; Simple bubble sort implementation
    n := arr.Length
    loop n - 1 {
        i := A_Index
        loop n - i {
            j := A_Index
            if (arr[j].Order > arr[j+1].Order) {
                ; Swap elements
                temp := arr[j]
                arr[j] := arr[j+1]
                arr[j+1] := temp
            }
        }
    }
}
}