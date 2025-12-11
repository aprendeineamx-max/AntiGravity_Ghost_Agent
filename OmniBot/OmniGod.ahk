#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"
SetMouseDelay -1 ; Velocidad máxima

; --- OMNIGOD v3.4: VISUAL PROTECTOR ---
; AutoHotKey v2 Script
SetWorkingDir A_ScriptDir
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"

; --- CONFIGURACIÓN ---
ImageFolder := "Targets\"
IndicatorFolder := "Indicators\"
Targets := []
Loop Files, ImageFolder . "*.png"
    Targets.Push(A_LoopFileName)

Tolerance := "*50" ; 0-255 (Variación de color permitida)
global IsActive := true 
global HUDVisible := true
LogFile := A_ScriptDir . "\OmniGod_Logs.txt"

; --- INICIO ---
TraySetIcon "shell32.dll", 1
CreateHUD()
UpdateHUD("ACTIVO", "CAZANDO (F8: Pausa | F9: HUD)", "c00FF00")
SoundPlay "*64" 
Log("SISTEMA INICIADO")

; --- HOTKEY TOGGLE (F8) ---
F8::
{
    global IsActive
    IsActive := !IsActive
    if (IsActive) {
        TraySetIcon "shell32.dll", 1 
        SoundPlay "*64" 
        UpdateHUD("ACTIVO", "CAZANDO (F8: Pausa | F9: HUD)", "c00FF00")
        Log("Estado cambiado a: ACTIVO")
    } else {
        TraySetIcon "shell32.dll", 28
        SoundPlay "*16" 
        UpdateHUD("PAUSADO", "Sistema Detenido", "cFF0000")
        Log("Estado cambiado a: PAUSADO")
    }
}

; --- BUCLE PRINCIPAL (CADA 500ms) ---
Loop {
    if (!IsActive) {
        Sleep 500
        continue
    }
    WatchDog()
    Sleep 500 
}
return

WatchDog() {
    static Tick := 0
    Tick := Mod(Tick + 1, 100) ; 0-99 Heartbeat

    ; --- 0. GEOMETRÍA DE CONFINAMIENTO (CRUCIAL) ---
    WinID := 0
    HasWindow := false
    WX := 0, WY := 0, WW := 0, WH := 0
    
    SetTitleMatchMode 2
    
    ; Búsqueda de Ventana
    if WinExist("AntiGravity ahk_exe Code.exe") {
        WinID := WinGetID("AntiGravity ahk_exe Code.exe")
    } else if WinExist("AntiGravity") && !WinActive("ahk_class CabinetWClass") {
        WinID := WinGetID("AntiGravity")
    } else if WinExist("ahk_exe Code.exe") {
        WinID := WinGetID("ahk_exe Code.exe")
    }

    if (WinID != 0) {
        try {
            WinGetPos &WX, &WY, &WW, &WH, "ahk_id " . WinID
            ; Ajuste de bordes
            WX := WX + 10
            WY := WY + 50 
            WW := WX + WW - 20 
            WH := WY + WH - 60 
            HasWindow := true
        } catch {
            HasWindow := false
        }
    }

    ; Formatear string de coordenadas + Heartbeat
    CoordStr := (HasWindow) ? " [" . WX . "," . WY . "] " . Tick : " [-,-] " . Tick

    if (!HasWindow) {
        UpdateHUD("MODO NINJA", "Solo Remoto " . CoordStr, "cGray")
    }

    ; --- PRIORIDAD 0: FINALIZADOR (ACCEPT ALL) ---
    if (HasWindow) {
        if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*100 " . ImageFolder . "AcceptAll_Priority.png") {
             TargetX := FoundX + 30 
             TargetY := FoundY + 10
             
             MouseMove TargetX, TargetY
             Sleep 10 
             MouseGetPos ,, &WinUnderMouse
             
             ; Z-ORDER RELAXED: Check Process Name instead of ID
             WinName := WinGetProcessName("ahk_id " . WinUnderMouse)
             TargetName := WinGetProcessName("ahk_id " . WinID)
             
             if (WinName == TargetName) {
                 UpdateHUD("PRIORIDAD", "Finalizando" . CoordStr, "c00FF00")
                 Click "Down"
                 Sleep 10
                 Click "Up"
                 Sleep 500 
                 return
             }
        }
    }

    ; --- 1. CHEQUEO DE ACTIVIDAD (HÍBRIDO) ---
    static WasWorking := false
    IsWorkingVisual := false
    
    if (HasWindow) {
        IsWorkingVisual := ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*10 " . IndicatorFolder . "working.png")
    }
    
    ; B. Chequeo Remoto 
    IsWorkingRemote := false
    if (!IsWorkingVisual) {
        try {
           whr := ComObject("WinHttp.WinHttpRequest.5.1")
           whr.Open("GET", "http://localhost:1337/api/status", true)
           whr.Send()
           if (whr.WaitForResponse(0.1)) { 
               resp := whr.ResponseText
               if InStr(resp, '"AgentWorking":true') {
                   IsWorkingRemote := true
               }
           }
        }
    }

    IsWorking := IsWorkingVisual or IsWorkingRemote

    if (IsWorking) {
        WasWorking := true
        ColorStatus := IsWorkingRemote ? "c00FFFF" : "cFFFF00"
        Source := IsWorkingRemote ? "GHOST LINK" : "VISUAL"
        UpdateHUD("TRABAJANDO", Source . " " . CoordStr, ColorStatus)
        
        try {
             if (WinID != 0) {
                SetKeyDelay 10, 10
                ControlSend "{Alt down}{Enter}{Alt up}",, "ahk_id " . WinID
            } else {
                 UpdateHUD("BUSCANDO", "Esperando ventana..." . CoordStr, "cRed")
            }
        }
        return 
    } 
    
    ; --- 2. MODALIDAD MUERTE SUBITA ---
    if (WasWorking and HasWindow) {
        Loop 20 { 
            Tick := Mod(Tick + 1, 100) ; Heartbeat en sub-loop
            UpdateHUD("CAZANDO (SD)", "Limpieza Rápida " . Tick, "cOrange")
            Loop Targets.Length {
                tImg := Targets[A_Index]
                if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*100 " . ImageFolder . tImg) {
                     SafeToClick := true
                     Loop Files, IndicatorFolder . "Ignore\*.png"
                     {
                        x1 := FoundX - 10
                        y1 := FoundY - 10
                        x2 := FoundX + 50 
                        y2 := FoundY + 50
                        if ImageSearch(&IgnX, &IgnY, x1, y1, x2, y2, Tolerance . " " . A_LoopFileFullPath) {
                            SafeToClick := false
                            break
                        }
                     }
                     if (!SafeToClick) {
                         continue
                     }

                     TargetX := FoundX + 15 
                     TargetY := FoundY + 10
                     MouseMove TargetX, TargetY
                     Sleep 10
                     MouseGetPos ,, &WinUnderMouse
                     
                     WinName := WinGetProcessName("ahk_id " . WinUnderMouse)
                     TargetName := WinGetProcessName("ahk_id " . WinID)
                     
                     if (WinName == TargetName) {
                         Click "Down"
                         Sleep 10
                         Click "Up"
                         UpdateHUD("CAZADO (SD)", "[OBJETIVO ELIMINADO]", "c00FFFF")
                         Sleep 500 
                     }
                }
            }
            Sleep 100
        }
        WasWorking := false
        return 
    }

    ; --- 3. CHEQUEO DE SEGURIDAD USER ---
    if (HasWindow and ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, Tolerance . " " . IndicatorFolder . "send.png")) {
        UpdateHUD("PAUSADO", "Usuario Escribiendo " . Tick, "cOrange")
        return
    }

    ; --- 4. IDLE / SCAN NORMAL ---
    if (HasWindow) {
        ; MOSTRAR COORDENADAS CON HEARTBEAT
        UpdateHUD("👁️ BUSCANDO...", "Zona: " . WX . "," . WY . " | " . WW . "," . WH . " [" . Tick . "]", "cGray")
        
        Loop Targets.Length {
            ; ... (loop code) ...

            imgName := Targets[A_Index]
            imgPath := ImageFolder . imgName
            if FileExist(imgPath) {
                try {
                    if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, Tolerance . " " . imgPath) {
                         SafeToClick := true
                         Loop Files, IndicatorFolder . "Ignore\*.png"
                         {
                            x1 := FoundX - 10
                            y1 := FoundY - 10
                            x2 := FoundX + 50 
                            y2 := FoundY + 50
                            if ImageSearch(&IgnX, &IgnY, x1, y1, x2, y2, Tolerance . " " . A_LoopFileFullPath) {
                                SafeToClick := false
                                break
                            }
                         }
                         if (!SafeToClick) {
                             continue
                         }
    
                        MouseGetPos &OrigX, &OrigY
                        TargetX := FoundX + 15 
                        TargetY := FoundY + 10
                        MouseMove TargetX, TargetY
                        
                        Sleep 10
                        MouseGetPos ,,, &WinUnderMouse
                        
                        WinName := WinGetProcessName("ahk_id " . WinUnderMouse)
                        TargetName := WinGetProcessName("ahk_id " . WinID)
                         
                        if (WinName == TargetName) {
                            Click "Down"
                            Sleep 10
                            Click "Up"
                            UpdateHUD("👁️ CAZADO", "[OBJETIVO ELIMINADO]", "c00FFFF") 
                            MouseMove OrigX, OrigY
                            SetTimer RemoveToolTip, -1000
                            return 
                        } else {
                            ; Obstruido por otra ventana
                            MouseMove OrigX, OrigY
                        }
                    }
                }
            }
        }
        
    } else {
        ; Ya manejado al principio
    }
}

RemoveToolTip() {
    ToolTip ,,,1
}

; End of Script

; --- HUD SYSTEM ---
CreateHUD() {
    global MyGui, StatusHeader, StatusDetail
    MyGui := Gui("+AlwaysOnTop +ToolWindow -Caption +E0x20") ; E0x20 = ClickThrough
    MyGui.BackColor := "1e1e1e"
    MyGui.SetFont("s10 w700", "Segoe UI")
    StatusHeader := MyGui.Add("Text", "c00FF00 w300 Center", "INIT")
    MyGui.SetFont("s8 w400", "Segoe UI")
    StatusDetail := MyGui.Add("Text", "cWhite w300 Center", "Iniciando...")
    
    ; Posicionar arriba al centro
    XPos := (A_ScreenWidth / 2) - 150
    MyGui.Show("x" . XPos . " y0 NoActivate")
    
    ; Transparencia visual
    WinSetTransparent(200, "ahk_id " . MyGui.Hwnd)
}

UpdateHUD(Title, Detail, ColorStr) {
    global StatusHeader, StatusDetail, HUDVisible
    if (HUDVisible) {
        try {
            StatusHeader.Text := Title
            StatusHeader.Opt(ColorStr)
            StatusDetail.Text := Detail
        }
    }
}

Log(Msg) {
    global LogFile
    Timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    try {
        FileAppend "[" . Timestamp . "] " . Msg . "`n", LogFile
    }
}

F9::
{
    global HUDVisible
    HUDVisible := !HUDVisible
    if HUDVisible {
        MyGui.Show("NoActivate")
        Log("HUD visible")
    } else {
        MyGui.Hide()
        Log("HUD oculto")
    }
}
