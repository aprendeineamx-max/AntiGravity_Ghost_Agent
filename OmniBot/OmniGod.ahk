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
    ; --- 0. GEOMETRÍA DE CONFINAMIENTO (CRUCIAL) ---
    ; Calculamos el perímetro ANTES de buscar cualquier cosa.
    ; Si no hay ventana, NO HAY BÚSQUEDA VISUAL. Punto.
    
    TargetWin := ""
    HasWindow := false
    WX := 0, WY := 0, WW := 0, WH := 0
    
    SetTitleMatchMode 2
    if WinExist("AntiGravity") {
        TargetWin := "AntiGravity"
    } else if WinExist("ahk_exe Code.exe") {
        TargetWin := "ahk_exe Code.exe"
    }

    if (TargetWin != "") {
        WinGetPos &WX, &WY, &WW, &WH, TargetWin
        ; Ajuste de bordes (Client Area aproximada)
        WX := WX + 10
        WY := WY + 50 ; Saltar barra de título
        WW := WX + WW - 20 ; Convertir WW a X2 absoluto
        WH := WY + WH - 60 ; Convertir WH a Y2 absoluto
        HasWindow := true
    } else {
        UpdateHUD("MODO NINJA", "Sin ventana visual. Solo remoto.", "cGray")
    }

    ; --- PRIORIDAD 0: FINALIZADOR (ACCEPT ALL) ---
    ; SOLO si tenemos ventana (Confinado)
    if (HasWindow) {
        if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*100 " . ImageFolder . "AcceptAll_Priority.png") {
             UpdateHUD("PRIORIDAD", "Finalizando Tarea", "c00FF00")
             MouseGetPos &OrigX, &OrigY
             TargetX := FoundX + 30 
             TargetY := FoundY + 10
             MouseMove TargetX, TargetY
             Sleep 10
             Click "Down"
             Sleep 10
             Click "Up"
             Sleep 10
             MouseMove OrigX, OrigY
             Sleep 500 
             return
        }
    }

    ; --- 1. CHEQUEO DE ACTIVIDAD (HÍBRIDO) ---
    static WasWorking := false
    IsWorkingVisual := false
    
    if (HasWindow) {
        IsWorkingVisual := ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, Tolerance . " " . IndicatorFolder . "working.png")
    }
    
    ; B. Chequeo Remoto (Para modo Minimizado/Background)
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
        UpdateHUD("TRABAJANDO", Source . ": Enviando Alt+Enter...", ColorStatus)
        
        try {
            if WinExist("AntiGravity") or WinExist("ahk_exe Code.exe") {
                WinID := WinGetID()
                SetKeyDelay 10, 10
                ControlSend "{Alt down}{Enter}{Alt up}",, "ahk_id " . WinID
            } else {
                 UpdateHUD("BUSCANDO", "Esperando ventana de Antigravity...", "cRed")
            }
        }
        return 
    } 
    
    ; --- 2. MODALIDAD MUERTE SUBITA ---
    ; Solo si tenemos ventana (Visual Cleanup)
    if (WasWorking and HasWindow) {
        ; Loop rápido de limpieza en área confinada
        Loop 20 { ; Reducido a 2s (20*100ms) para ser más preciso
            Loop Targets.Length {
                tImg := Targets[A_Index]
                if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*100 " . ImageFolder . tImg) {
                     ; Proximity Check
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
                     Click "Down"
                     Sleep 10
                     Click "Up"
                     Sleep 10
                     MouseMove OrigX, OrigY
                     UpdateHUD("CAZADO (SD)", "[OBJETIVO ELIMINADO]", "c00FFFF")
                     Sleep 500 
                }
            }
            Sleep 100
        }
        WasWorking := false
        return 
    }

    ; --- 3. CHEQUEO DE SEGURIDAD USER ---
    if (HasWindow and ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, Tolerance . " " . IndicatorFolder . "send.png")) {
        UpdateHUD("PAUSADO", "Usuario Escribiendo", "cOrange")
        return
    }

    ; --- 4. IDLE / SCAN NORMAL ---
    if (HasWindow) {
        UpdateHUD("👁️ BUSCANDO...", "Escaneando Perímetro...", "cGray")
        Loop Targets.Length {
            imgName := Targets[A_Index]
            imgPath := ImageFolder . imgName
            if FileExist(imgPath) {
                try {
                    if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, Tolerance . " " . imgPath) {
                        ; Proximity Check
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
                        Click "Down"
                        Sleep 10
                        Click "Up"
                        Sleep 10
                        MouseMove OrigX, OrigY
                        UpdateHUD("👁️ CAZADO", "[OBJETIVO ELIMINADO]", "c00FFFF") 
                        SetTimer RemoveToolTip, -1000
                        return 
                    }
                }
            }
        }
        
        ; Scroll Logic (Optional, confined)
        if ImageSearch(&AnchorX, &AnchorY, WX, WY, WW, WH, Tolerance . " " . IndicatorFolder . "working.png") {
             ; Scroll logic if needed
        }

    } else {
        ; Ya manejado al principio (Modo Ninja No-Visual)
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
