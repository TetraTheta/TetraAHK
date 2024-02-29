/**
 * MarkdownHelper v1.2.0 : My Hugo Blog Markdown Helper
 */
#Requires AutoHotkey v2.0
#Include "..\Lib\darkMode.ahk"
#Include "..\Lib\ini.ahk"
#Include "..\Lib\KV.ahk"
#include "l10n.ahk"
#SingleInstance Force

; Information about executable
;@Ahk2Exe-SetCompanyName TetraTheta
;@Ahk2Exe-SetCopyright Copyright 2023. TetraTheta. All rights reserved.
;@Ahk2Exe-SetDescription My Hugo Blog Markdown Helper
;@Ahk2Exe-SetFileVersion 2.0.0.0
;@Ahk2Exe-SetLanguage 0x0412
;@Ahk2Exe-SetMainIcon icon_normal.ico ; Default icon
;@Ahk2Exe-SetProductName MarkdownHelper

; ------------------------------------------------------------------------------
; Hotkey
; ------------------------------------------------------------------------------
; Ctrl + B : 「」
^B::Send("「」{left}")
; Ctrl + Shift + C : Show Tidy GUI
^+C::InputTidy()
; Ctrl + D : Insert single image
^D::
{
  R := InputSimpleSingle(L_SINGLE_TITLE, L_SINGLE_MSG, L_SINGLE_EDIT_LABEL, L_SINGLE_HELP, , 128)
  if (R[1] && R[2] != "") {
    F := ParseName(R[2])
    if (IsNumber(F.name)) {
      FN := Number(F.name)
      output := "![](" . Format("{:03}", FN) . "." . F.ext . ")`n`n"
    } else {
      output := "![](" . F.name . "." . F.ext . ")`n`n"
    }
    SendText(output)
  }
}
; Ctrl + Shift + D : Insert multiple images in a row
^+D::
{
  R := InputSimpleMulti(L_MULTI_TITLE, L_MULTI_MSG, L_MULTI_EDIT_1_LABEL, L_MULTI_EDIT_2_LABEL, L_MULTI_HELP, , 319)
  if (R[1] && R[2] != "" && R[3] != "") {
    F1 := ParseName(R[2])
    F2 := ParseName(R[3])
    if (!CheckNumber(F1.name) || !CheckNumber(F2.name)) {
      return
    }
    F1N := Number(F1.name)
    F2N := Number(F2.name)
    output := ""
    lp := F2N - F1N + 1
    Loop lp {
      output .= "![](" . Format("{:03}", F1N + A_Index - 1) . "." . F2.ext . ")`n`n"
      if (A_Index != lp) {
        output .= "`n`n"
      }
    }
    ; SendText() lags
    A_Clipboard := output
    Sleep(10)
    Send("^v")
    Sleep(10)
    A_Clipboard := ""
  }
}
; Ctrl + G : Insert gallery/image with two sources, with given numbers
^G::
{
  R := InputSimpleSingle(L_GAL2_TITLE, L_GAL2_MSG, L_GAL2_EDIT_LABEL, L_GAL2_HELP, , 128)
  if (R[1] && R[2] != "") {
    F := ParseName(R[2])
    if (!CheckNumber(F.name)) {
      return
    }
    FN := Number(F.name)
    SendText("{{< gallery/image src=`"" . Format("{:03}", FN) . "|" . Format("{:03}", FN + 1) . "`" >}}`n`n")
  }
}
; Ctrl + Shift + G : Insert gallery/image with three sources and caption
^+G::
{
  R := InputSimpleSingle(L_GAL3_TITLE, L_GAL3_MSG, L_GAL3_EDIT_LABEL, L_GAL3_HELP, , 319)
  if (R[1] && R[2] != "") {
    F := ParseName(R[2])
    if (!CheckNumber(R[2])) {
      return
    }
    FN := Number(F.name)
    SendText("{{< gallery/image src=`"" . Format("{:03}", FN) . "|" . Format("{:03}", FN + 1) . "|" . Format("{:03}", FN + 2) . "`" >}}`n`n")
  }
}
; Win + G : Insert gallery/image with two sources
#G::SendText("{{< gallery/image src=`"|`" >}}`n`n")
; Win + Shift + G : Insert gallery/image with three sources
#+G::SendText("{{< gallery/image src=`"||`" >}}`n`n")
; Ctrl + Alt + N : New Post
^!N::
{
  global LastIndex, LastTitle
  R := InputAdvanced(L_NEW_TITLE, L_NEW_MSG, L_NEW_CAT_LABEL, LastIndex, L_NEW_EDIT_LABEL, LastTitle, L_NEW_HELP, , 2)
  if (R[1] && R[3] != "" && R[4] != "") {
    LastIndex := R[2]
    LastTitle := R[4]
    IniWrite(LastIndex, GetIniPath(), "New Post", "Last Index")
    IniWrite(LastTitle, GetIniPath(), "New Post", "Last Title")
    if (KeepConsole) {
      cmdSwitch := "/k"
    } else {
      cmdSwitch := "/c"
    }
    args := A_ComSpec . " " . cmdSwitch . " cd /d `"" . WorkingDir . "`" && npm run new " . R[3] . " " . R[4]
    Run(args, WorkingDir)
  }
}
; Ctrl + Q : Insert NBSP
^Q::SendText("&nbsp;`n`n")
; ------------------------------------------------------------------------------
; Variable
; ------------------------------------------------------------------------------
; Config variables
WorkingDir := IniGet("Setting", "Blog Repository Root", A_ScriptDir)
KeepConsole := IniGet("Setting", "Keep Console Open", false)
ExplorerExec := IniGet("Open Explorer", "Executable", "explorer.exe")
ExplorerArgs := IniGet("Open Explorer", "Arguments", "")
CmdExec := IniGet("Open Terminal", "Executable", A_ComSpec)
CmdArgs := IniGet("Open Terminal", "Arguments", "/K cd /d C:\")
TestServerDir := IniGet("Start Hugo Test Server", "Start Directory", "")
TestServerExec := IniGet("Start Hugo Test Server", "Executable", "")
TestServerArgs := IniGet("Start Hugo Test Server", "Arguments", "")
TestPageExec := IniGet("Open Test Page", "Browser Executable", "firefox.exe")
TestPageArgs := IniGet("Open Test Page", "Arguments", "")
NotepadExec := IniGet("Open Tistory Redirect Script", "Executable", "notepad.exe")
RedirectScriptFilePath := IniGet("Open Tistory Redirect Script", "Redirect Script Path", "")
; Runtime variables (will be written back to INI)
LastIndex := IniGet("New Post", "Last Index", "3")
LastTitle := IniGet("New Post", "Last Title", "")
; Sanitize variables
KeepConsole := (IsNumber(KeepConsole) && KeepConsole == 0) ? 0 : 1
LastIndex := IsNumber(LastIndex) ? Number(LastIndex) : 3
; ------------------------------------------------------------------------------
; Tray Icon & Menu (+functions)
; ------------------------------------------------------------------------------
A_IconTip := "MarkdownHelper" ; Tray icon tip
;@Ahk2Exe-IgnoreBegin
TraySetIcon("icon_normal.ico")
;@Ahk2Exe-IgnoreEnd
; Define misc sub menu
SubMenuTray := Menu()
SubMenuTray.Add("Open Tistory Redirect Script`tT", OpenRedirectScript)
SubMenuTray.Add()
SubMenuTray.Add("Reload`tR", ReloadScript)
SubMenuTray.Add("List Hotkeys`tH", ListHotkey)
SubMenuTray.SetIcon("Open Tistory Redirect Script`tT", "imageres.dll", 15)
SubMenuTray.SetIcon("Reload`tR", "imageres.dll", 230)
SubMenuTray.SetIcon("List Hotkeys`tH", "shell32.dll", 2)
; Re-define tray menu
MenuTray := A_TrayMenu
MenuTray.Delete() ; Reset tray menu
MenuTray.Add("Open &Explorer`tE", OpenExplorer)
MenuTray.Add("Open &Terminal`tT", OpenTerminal)
MenuTray.Add()
MenuTray.Add("Start Hugo Test &Server`tS", RunServer)
MenuTray.Add("Open Test &Page`tP", OpenPage)
MenuTray.Add()
MenuTray.Add("Misc`tM", SubMenuTray)
MenuTray.Add()
MenuTray.Add("E&xit`tX", ExitScript)
MenuTray.SetIcon("Open &Explorer`tE", "imageres.dll", 4)
MenuTray.SetIcon("Open &Terminal`tT", "imageres.dll", 264)
MenuTray.SetIcon("Start Hugo Test &Server`tS", "imageres.dll", 264)
MenuTray.SetIcon("Open Test &Page`tP", "netshell.dll", 86)
MenuTray.SetIcon("E&xit`tX", "imageres.dll", 85)
; Set default entry
MenuTray.Default := "E&xit`tX" ; Default action is 'Exit'
; Menu function
OpenExplorer(*) {
  Run("`"" . ExplorerExec . "`" " . ExplorerArgs)
}
OpenTerminal(*) {
  Run("`"" . CmdExec . "`" " . CmdArgs)
}
RunServer(*) {
  Run("`"" . TestServerExec . "`" " . TestServerArgs, TestServerDir)
}
OpenPage(*) {
  Run("`"" . TestPageExec . "`" " . TestPageArgs)
}
OpenRedirectScript(*) {
  Run("`"" . NotepadExec . "`" " . RedirectScriptFilePath)
}
ReloadScript(*) {
  Reload()
}
ListHotkey(*) {
  ListHotkeys()
}
ExitScript(*) {
  ExitApp()
}
; Dark Context Menu
SetMenuAttr()
; ------------------------------------------------------------------------------
; Function
; ------------------------------------------------------------------------------
/**
 * Show GUI that returns values of two Edit controls
 * 
 * Target: MULTI
 * @param {String} aTitle Title of the GUI
 * @param {String} aMessage Message to show on the GUI
 * @param {String} aLabel1 Label text for the first Edit control
 * @param {String} aLabel2 Label text for the second Edit control
 * @param {String} aHelp Help message for 'Help' button
 * @param {String} aIconFile DLL file that contains icon
 * @param {Integer} aIconIndex Icon index
 * @param {Integer} aTimeout Timeout for the GUI
 * @returns {Array} [R_OK, R_Edit1, R_Edit2]
 */
InputSimpleMulti(aTitle := A_ScriptName, aMessage := "", aLabel1 := "", aLabel2 := "", aHelp := "", aIconFile := "shell32.dll", aIconIndex := 1, aTimeout := 10) {
  ; Get global variables
  global L_CANCEL, L_HELP, L_OK

  ; Define variables to return
  R_Edit1 := ""
  R_Edit2 := ""
  R_OK := false

  ; Create GUI and set icon (hack)
  TraySetIcon(aIconFile, aIconIndex)
  MyGui := Gui(, aTitle)
  /*@Ahk2Exe-Keep
  TraySetIcon("*")
  */
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon_normal.ico")
  ;@Ahk2Exe-IgnoreEnd

  ; Main GUI
  MyGui.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
  MyGui.OnEvent("Escape", (*) => (MyGui.Destroy()))
  MyGui.SetFont("s10", "Malgun Gothic")

  ; GUI element
  Gui_Icon := MyGui.AddPicture("x12 y12 w32 h-1 Icon" . aIconIndex, aIconFile)
  Gui_Timer := MyGui.AddText("x21 y47 w25 h19", Format("{:02}", aTimeout))
  Gui_Msg := MyGui.AddText("x50 y12 w422 h70", aMessage)
  Gui_Label1 := MyGui.AddText("x12 y82 w460 h19", aLabel1)
  Gui_Edit1 := MyGui.AddEdit("x12 y105 w460 h25 -Multi")
  Gui_Label2 := MyGui.AddText("x12 y134 w460 h19", aLabel2)
  Gui_Edit2 := MyGui.AddEdit("x12 y157 w460 h25 -Multi")
  Gui_Help := MyGui.AddButton("x12 y190 w75 h33", L_HELP)
  Gui_OK := MyGui.AddButton("x316 y190 w75 h33 +Default", L_OK)
  Gui_Cancel := MyGui.AddButton("x397 y190 w75 h33", L_CANCEL)

  ; GUI event
  Gui_OK.OnEvent("Click", ParseControl)
  Gui_Cancel.OnEvent("Click", (*) => (MyGui.Destroy()))
  ParseControl(*) {
    if (Gui_Edit2.Value == "") {
      Shake(MyGui)
    } else {
      R_OK := true
      R_Edit1 := Gui_Edit1.Value == "" ? "001" : Gui_Edit1.Value
      R_Edit2 := Gui_Edit2.Value
      MyGui.Destroy()
    }
  }
  Gui_Help.OnEvent("Click", (*) => (MsgBox(aHelp, L_HELP, 4096)))

  ; Set dark mode
  SetWinAttr(MyGui)
  SetWinTheme(MyGui)

  ; Show GUI
  MyGui.Show("AutoSize Center")
  Gui_Edit2.Focus()

  ; Start timer
  GuiHwnd := MyGui.Hwnd
  SetTimer(CountDown, 1000)
  WinWaitClose(GuiHwnd)
  return [R_OK, R_Edit1, R_Edit2]

  CountDown() {
    if (WinExist("ahk_id" . GuiHwnd)) {
      Gui_Timer.Text := Format("{:02}", --aTimeout)
    }
    if (!aTimeout) {
      MyGui.Destroy()
      R_OK := false
      R_Edit1 := ""
      R_Edit2 := ""
      SetTimer(, 0)
    }
  }
}
/**
 * Show GUI that returns value of a Edit control
 * 
 * Target: G2, G3, SINGLE
 * @param {String} aTitle Title of the GUI
 * @param {String} aMessage Message to show on the GUI
 * @param {String} aLabel Label text for the Edit control
 * @param {String} aHelp Help message for 'Help' button
 * @param {String} aIconFile DLL file that contains icon
 * @param {Integer} aIconIndex Icon index
 * @param {Integer} aTimeout Timeout for the GUI
 * @returns {Array} [R_OK, R_Edit]
 */
InputSimpleSingle(aTitle := A_ScriptName, aMessage := "", aLabel := "", aHelp := "", aIconFile := "shell32.dll", aIconIndex := 1, aTimeout := 10) {
  ; Get global variables
  global L_CANCEL, L_HELP, L_OK

  ; Define variables to return
  R_Edit := ""
  R_OK := false

  ; Create GUI and set icon (hack)
  TraySetIcon(aIconFile, aIconIndex)
  MyGui := Gui(, aTitle)
  /*@Ahk2Exe-Keep
  TraySetIcon("*")
  */
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon_normal.ico")
  ;@Ahk2Exe-IgnoreEnd

  ; GUI option
  MyGui.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
  MyGui.OnEvent("Escape", (*) => (MyGui.Destroy()))
  MyGui.SetFont("s10", "Malgun Gothic")

  ; GUI element
  Gui_Icon := MyGui.AddPicture("x12 y12 w32 h-1 Icon" . aIconIndex, aIconFile)
  Gui_Timer := MyGui.AddText("x21 y47 w25 h19", Format("{:02}", aTimeout))
  Gui_Msg := MyGui.AddText("x50 y12 w422 h97", aMessage)
  Gui_Label := MyGui.AddText("x12 y109 w460 h19", aLabel)
  Gui_Edit := MyGui.AddEdit("x12 y132 w460 h25 -Multi")
  Gui_Help := MyGui.AddButton("x12 y165 w75 h33", L_HELP)
  Gui_OK := MyGui.AddButton("x316 y165 w75 h33 +Default", L_OK)
  Gui_Cancel := MyGui.AddButton("x397 y165 w75 h33", L_CANCEL)

  ; GUI event
  Gui_OK.OnEvent("Click", ParseControl)
  Gui_Cancel.OnEvent("Click", (*) => (MyGui.Destroy()))
  ParseControl(*) {
    if (Gui_Edit.Value == "") {
      Shake(MyGui)
    } else {
      R_Edit := Gui_Edit.Value
      R_OK := true
      MyGui.Destroy()
    }
  }
  Gui_Help.OnEvent("Click", (*) => (MsgBox(aHelp, L_HELP, 4096)))

  ; Set dark mode
  SetWinAttr(MyGui)
  SetWinTheme(MyGui)

  ; Show GUI
  MyGui.Show("AutoSize Center")
  Gui_Edit.Focus()

  ; Start timer
  GuiHwnd := MyGui.Hwnd
  SetTimer(CountDown, 1000)
  WinWaitClose(GuiHwnd)
  return [R_OK, R_Edit]

  CountDown() {
    if (WinExist("ahk_id" . GuiHwnd)) {
      Gui_Timer.Text := Format("{:02}", --aTimeout)
    }
    if (!aTimeout) {
      MyGui.Destroy()
      R_Edit := ""
      R_OK := false
      SetTimer(, 0)
    }
  }
}
/**
 * Show GUI that returns index/value of a DropDownList control and a Edit control
 * 
 * Target: NEW
 * @param {String} aTitle Title of the GUI
 * @param {String} aMessage Message to show on the GUI
 * @param {String} aLabel1 Label text for the DropDownList control
 * @param {Integer} aDDLIndex Default index of the DropDownList control
 * @param {String} aLabel2 Label text for the Edit control
 * @param {String} aEditDefault Default text for the Edit control
 * @param {String} aHelp Help message for 'Help' button
 * @param {String} aIconFile DLL file that contains icon
 * @param {Integer} aIconIndex Icon index
 * @param {Integer} aTimeout Timeout for the GUI
 * @returns {Array} [R_OK, R_DDL_Idx, R_DDL_Val, R_Edit]
 */
InputAdvanced(aTitle := A_ScriptName, aMessage := "", aLabel1 := "", aDDLIndex := 0, aLabel2 := "", aEditDefault := "", aHelp := "", aIconFile := "shell32.dll", aIconIndex := 1, aTimeout := 30) {  
  ; Get global variables
  global KeyValue, L_CANCEL, L_HELP, L_OK

  kv := KeyValue()
  kv.Add("Archon Quests (Genshin)", "genshin-archon")
  kv.Add("Blue Archive", "blue-archive")
  kv.Add("Chit Chat", "chit-chat")
  kv.Add("Default", "default")
  kv.Add("Event Quests (Genshin)", "genshin-event")
  kv.Add("Game Misc", "game-misc")
  kv.Add("Genshin Misc", "genshin-misc")
  kv.Add("Honkai: Star Rail", "honkai-star-rail")
  kv.Add("Minecraft", "minecraft")
  kv.Add("Music", "music")
  kv.Add("Story Quests (Genshin)", "genshin-story")
  kv.Add("The Division", "the-division")
  kv.Add("Tower of Fantasy", "tower-of-fantasy")
  kv.Add("World Quests (Genshin)", "genshin-world")
  ; _K := ["Archon Quests (Genshin)", "Blue Archive", "Chit Chat", "Default", "Event Quests (Genshin)", "Game Misc", "Genshin Misc", "Honkai: Star Rail", "Minecraft", "Music", "Story Quests (Genshin)", "The Division", "Tower of Fantasy", "World Quests (Genshin)"]
  ; _V := ["genshin-archon", "blue-archive", "chit-chat", "default", "genshin-event", "game-misc", "genshin-misc", "honkai-star-rail", "minecraft", "music", "genshin-story", "the-division", "tower-of-fantasy", "genshin-world"]

  ; Define variables to return
  R_DDL_Idx := aDDLIndex
  R_DDL_Val := ""
  R_Edit := ""
  R_OK := false

  ; Create GUI and set icon (hack)
  TraySetIcon(aIconFile, aIconIndex)
  MyGui := Gui(, aTitle)
  /*@Ahk2Exe-Keep
  TraySetIcon("*")
  */
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon_normal.ico")
  ;@Ahk2Exe-IgnoreEnd

  ; GUI option
  MyGui.Opt("+AlwaysOnTop -MaximizeBox -MinimizeBox -Resize +OwnDialogs")
  MyGui.OnEvent("Escape", (*) => (MyGui.Destroy()))
  MyGui.SetFont("s10", "Malgun Gothic")

  ; GUI element
  Gui_Icon := MyGui.AddPicture("x12 y12 w32 h-1 Icon" . aIconIndex, aIconFile)
  Gui_Timer := MyGui.AddText("x21 y47 w25 h19", Format("{:02}", aTimeout))
  Gui_Msg := MyGui.AddText("x50 y12 w422 h66", aMessage)
  Gui_Label1 := MyGui.AddText("x12 y78 w460 h19", aLabel1)
  Gui_DDL := MyGui.AddDropDownList("x12 y105 w460 h25 vPostDir Choose" . aDDLIndex . " R200", kv.keys)
  Gui_Label2 := MyGui.AddText("x12 y134 w460 h19", aLabel2)
  Gui_Edit := MyGui.AddEdit("x12 y157 w460 h25 -Multi")
  Gui_Help := MyGui.AddButton("x12 y190 w75 h33", L_HELP)
  Gui_OK := MyGui.AddButton("x316 y190 w75 h33 +Default", L_OK)
  Gui_Cancel := MyGui.AddButton("x397 y190 w75 h33", L_CANCEL)

  ; GUI event
  Gui_OK.OnEvent("Click", ParseControl)
  Gui_Cancel.OnEvent("Click", (*) => (MyGui.Destroy()))
  ParseControl(*) {
    if (Gui_Edit.Value == "") {
      Shake(MyGui)
    } else {
      R_DDL_Idx := Gui_DDL.Value
      R_DDL_Val := kv.values[Gui_DDL.Value]
      R_Edit := Gui_Edit.Value
      R_OK := true
      MyGui.Destroy()
    }
  }
  Gui_Help.OnEvent("Click", (*) => (MsgBox(aHelp, L_HELP, 4096)))

  ; Set dark mode
  SetWinAttr(MyGui)
  SetWinTheme(MyGui)

  ; Show GUI
  MyGui.Show("AutoSize Center")
  Gui_Edit.Focus()

  ; Start timer
  GuiHwnd := MyGui.Hwnd
  SetTimer(CountDown, 1000)
  WinWaitClose(GuiHwnd)
  return [R_OK, R_DDL_Idx, R_DDL_Val, R_Edit]

  CountDown() {
    if (WinExist("ahk_id" . GuiHwnd)) {
      Gui_Timer.Text := Format("{:02}", --aTimeout)
    }
    if (!aTimeout) {
      MyGui.Destroy()
      R_DDL_Idx := -1
      R_DDL_Val := ""
      R_Edit := ""
      R_OK := false
      SetTimer(, 0)
    }
  }
}
/**
 * Show GUI that removes excessive line breaks
 */
InputTidy() {
  ; Get global variable
  global L_CANCEL, L_OK, L_TIDY_BTN_TIDY, L_TIDY_BTN_TIDY_COPY, L_TIDY_LENGTH, L_TIDY_TITLE

  ; Create GUI and set icon (hack)
  TraySetIcon("shell32.dll", 2)
  MyGui := Gui(, L_TIDY_TITLE)
  /*@Ahk2Exe-Keep
  TraySetIcon("*")
  */
  ;@Ahk2Exe-IgnoreBegin
  TraySetIcon("icon_normal.ico")
  ;@Ahk2Exe-IgnoreEnd

  ; GUI option
  MyGui.Opt("-MaximizeBox -MinimizeBox -Resize +OwnDialogs")
  MyGui.OnEvent("Escape", (*) => (MyGui.Destroy()))

  ; GUI elements
  Gui_Edit := MyGui.AddEdit("x12 y12 w600 h600 +Multi +Wrap")
  Gui_TextLength := MyGui.AddText("x12 y615 w600 h12", L_TIDY_LENGTH . "0")
  Gui_Tidy := MyGui.AddButton("x12 y630 w297 h23", L_TIDY_BTN_TIDY)
  Gui_TidyCopy := MyGui.AddButton("x315 y630 w297 h23", L_TIDY_BTN_TIDY_COPY)

  ; GUI event
  Gui_Tidy.OnEvent("Click", TidyBtnClick)
  Gui_TidyCopy.OnEvent("Click", TidyCopyBtnClick)
  TidyBtnClick(*) {
    if (Gui_Edit.Value == "") {
      Shake(MyGui)
    } else {
      if (!TidyText()) {
        Shake(MyGui)
      }
    }
  }
  TidyCopyBtnClick(*) {
    if (Gui_Edit.Value == "") {
      Shake(MyGui)
    } else {
      if (!TidyText(true)) {
        Shake(MyGui)
      } else {
        MyGui.Destroy()
      }
    }
  }
  TidyText(copyText := false) {
    oldText := Gui_Edit.Value
    newText := RegExReplace(oldText, "(\s*[\r\n]){2,}", "`n`n")
    newText := LTrim(newText, "`n")
    newText := RTrim(newText, "`n")
    Gui_Edit.Value := newText

    flatText := StrReplace(newText, "`n", "")
    flatTextLength := StrLen(flatText)
    Gui_TextLength.Value := L_TIDY_LENGTH . flatTextLength

    isOK := false
    if (flatTextLength > 1000) {
      Gui_TextLength.SetFont("cRed")
      Gui_TextLength.Redraw()
    } else {
      isOK := true
      Gui_TextLength.SetFont("cDefault")
      Gui_TextLength.Redraw()
    }

    if (copyText && isOK) {
      A_Clipboard := newText
    }

    return isOK
  }

  ; Dark mode
  SetWinAttr(MyGui)
  SetWinTheme(MyGui)

  ; Show GUI
  MyGui.Show("AutoSize Center")
  Gui_Edit.Focus()
}
/**
 * Check if given input is number
 * @param input 
 * @returns {Integer} `true` if given input is Number
 */
CheckNumber(input) {
  global L_ERR_NOT_NUMBER, L_ERR_TITLE
  if (!IsNumber(input)) {
    MsgBox(Format(L_ERR_NOT_NUMBER, input), L_ERR_TITLE, "OK Iconx T3")
    return false
  } else {
    return true
  }
}
/**
 * Get file name without extension and extension
 * @param fileName Name of the file. If it doesn't have any extension, it will be set to 'webp'
 * @returns {Object} {name: name, ext: extension}
 */
ParseName(fileName) {
  if (!(fileName is String)) {
    return {name: "", ext: ""}
  }
  name := ""
  ext := ""
  SplitPath(fileName, , , &ext, &name)
  ext := ext == "" ? "webp" : ext
  return {name: name, ext: ext}
}
/**
 * Shake given GUI
 * @param targetGui GUI to shake
 * @param {Integer} aShakes Number of shake
 * @param {Integer} aRattleX Magnitude of shake, in X axis.
 * @param {Integer} aRattleY Magnitude of shake, in Y axis.
 */
Shake(targetGui, aShakes := 20, aRattleX := 3, aRattleY := 3) {
  if (!IsObject(targetGui) || !(targetGui is Gui)) {
    return
  }
  oriX := 0, oriY := 0
  targetGui.GetPos(&oriX, &oriY)
  Loop aShakes {
    rx := Random(oriX - aRattleX, oriX + aRattleX)
    ry := Random(oriY - aRattleY, oriY + aRattleY)
    targetGui.Move(rx, ry)
    Sleep(10)
  }
  targetGui.Move(oriX, oriY)
}
; ------------------------------------------------------------------------------
; Event
; ------------------------------------------------------------------------------
; OnExit : Play ding sound when exit by #SingleInstance Force
OnExitFunc(ExitReason, ExitCode) {
  if (ExitReason == "Single" || ExitReason == "Reload") {
    SoundPlay("*48")
  }
}
OnExit(OnExitFunc)
