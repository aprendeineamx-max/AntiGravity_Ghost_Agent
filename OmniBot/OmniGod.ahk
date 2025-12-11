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
    static LastWX := 0, LastWY := 0, LastWW := 0, LastWH := 0
    static LastState := ""
    
    Tick := Mod(Tick + 1, 100)
    
    ; [LOG] Inicio de Ciclo
    Log("CYCLE[" . Tick . "]: Iniciando WatchDog...")

    ; --- 0. GEOMETRÍA DE CONFINAMIENTO (CRUCIAL) ---
    WinID := 0
    HasWindow := false
    WX := 0, WY := 0, WW := 0, WH := 0
    
    SetTitleMatchMode 2
    
    ; Búsqueda de Ventana
    if WinExist("AntiGravity ahk_exe Code.exe") {
        WinID := WinGetID("AntiGravity ahk_exe Code.exe")
        Log("WIN: Encontrada 'AntiGravity ahk_exe Code.exe' ID: " . WinID)
    } else if WinExist("AntiGravity") && !WinActive("ahk_class CabinetWClass") {
        WinID := WinGetID("AntiGravity")
        Log("WIN: Encontrada 'AntiGravity' ID: " . WinID)
    } else if WinExist("ahk_exe Code.exe") {
        WinID := WinGetID("ahk_exe Code.exe")
        Log("WIN: Encontrada fallback 'Code.exe' ID: " . WinID)
    } else {
        Log("WIN: Ninguna ventana detectada.")
    }

    if (WinID != 0) {
        try {
            ; Verificar si está minimizada (-1)
            MinMax := WinGetMinMax("ahk_id " . WinID)
            Log("WIN-STATE: MinMax Status = " . MinMax)
            
            if (MinMax == -1) {
                HasWindow := false
                Log("ESTADO: MODO NINJA (Ventana Minimizada detectada)")
            } else {
                WinGetPos &WX, &WY, &WW, &WH, "ahk_id " . WinID
                Log("RAW-COORDS: X=" . WX . " Y=" . WY . " W=" . WW . " H=" . WH)
                
                ; --- ZONA CIEGA EXTENDIDA (VS CODE SIDEBAR) ---
                MarginLeft := 350 
                
                WX := WX + MarginLeft 
                WY := WY + 50 
                WW := WX + WW - MarginLeft - 20 
                WH := WY + WH - 60 
                
                Log("SAFE-ZONE: [" . WX . "," . WY . "] -> [" . WW . "," . WH . "] (Margen aplicado: " . MarginLeft . ")")
                
                ; Validación de coordenadas
                if (WW > WX and WH > WY) {
                    HasWindow := true
                } else {
                    HasWindow := false
                    Log("WARNING: Coordenadas inválidas (Zona negativa o cero).")
                }
            }
        } catch {
            HasWindow := false
            Log("ERROR: Excepción en WinGetPos/MinMax para ID: " . WinID)
        }
    }

    ; Formatear string de coordenadas
    CoordStr := (HasWindow) ? " [" . WX . "," . WY . "] " . Tick : " [-,-] " . Tick

    if (!HasWindow) {
         UpdateHUD("MODO NINJA", "Solo Remoto " . CoordStr, "cGray")
         Log("HUD: Actualizado a MODO NINJA")
    }

    ; --- SMART TYPING DETECTION (NO BLOQUEANTE) ---
    UserTyping := false
    if (HasWindow) {
        Log("SEARCH: Buscando 'send.png' para detectar usuario...")
        if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, Tolerance . " " . IndicatorFolder . "send.png") {
            UserTyping := true
            Log("DETECTADO: Usuario escribiendo (send.png en " . FoundX . "," . FoundY . "). Alt+Enter será SUPRIMIDO.")
            UpdateHUD("ESCRIBIENDO", "Clics: ON | Enter: OFF " . Tick, "cOrange")
        } else {
            Log("SEARCH: 'send.png' no encontrado. Usuario libre.")
        }
    }

    ; --- PRIORIDAD 0: FINALIZADOR (ACCEPT ALL) ---
    if (HasWindow) {
        Log("SEARCH: Buscando 'AcceptAll_Priority.png'...")
        if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*60 " . ImageFolder . "AcceptAll_Priority.png") {
             TargetX := FoundX + 30 
             TargetY := FoundY + 10
             
             Log("DETECCION: AcceptAll_Priority encontrado en " . FoundX . "," . FoundY)
             
             MouseMove TargetX, TargetY
             Sleep 10 
             MouseGetPos ,, &WinUnderMouse
             
             try {
                WinName := WinGetProcessName("ahk_id " . WinUnderMouse)
                TargetName := WinGetProcessName("ahk_id " . WinID)
                Log("Z-CHECK: MouseOver=" . WinName . " vs Target=" . TargetName)
             
                if (WinName == TargetName) {
                    UpdateHUD("PRIORIDAD", "Finalizando" . CoordStr, "c00FF00")
                    Log("ACCION: Clic CONFIRMADO en AcceptAll_Priority en " . TargetX . "," . TargetY)
                    Click "Down"
                    Sleep 10
                    Click "Up"
                    Sleep 500 
                    return
                } else {
                    Log("WARNING: Bloqueado por Z-Order. Ventana encima: " . WinName)
                }
             } catch {
                Log("ERROR: Fallo crítico en Z-Order check (Priority)")
             }
        } else {
            Log("Result: AcceptAll_Priority NO encontrado.")
        }
    }

    ; --- 1. CHEQUEO DE ACTIVIDAD (HÍBRIDO) ---
    static WasWorking := false
    IsWorkingVisual := false
    
    if (HasWindow) {
        Log("SEARCH: Buscando 'working.png' (Estado Activo)...")
        IsWorkingVisual := ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*15 " . IndicatorFolder . "working.png")
        if (IsWorkingVisual) {
             Log("DETECTADO: 'working.png' encontrado en " . FoundX . "," . FoundY)
        }
    }
    
    ; B. Chequeo Remoto 
    IsWorkingRemote := false
    if (!IsWorkingVisual) {
        try {
           ; Log("HTTP: Consultando estado remoto...") ; Comentado para no saturar EXCESIVAMENTE si es muy rápido
           whr := ComObject("WinHttp.WinHttpRequest.5.1")
           whr.Open("GET", "http://localhost:1337/api/status", true)
           whr.Send()
           if (whr.WaitForResponse(0.1)) { 
               resp := whr.ResponseText
               if InStr(resp, '"AgentWorking":true') {
                   IsWorkingRemote := true
                   Log("HTTP: Estado Remoto = WORKING")
               }
           }
        }
    }

    IsWorking := IsWorkingVisual or IsWorkingRemote

    if (IsWorking) {
        WasWorking := true
        ColorStatus := IsWorkingRemote ? "c00FFFF" : "cFFFF00"
        Source := IsWorkingRemote ? "GHOST LINK" : "VISUAL"
        
        Log("ESTADO: TRABAJANDO (" . Source . ")")
        
        if (!UserTyping) {
            UpdateHUD("TRABAJANDO", Source . " " . CoordStr, ColorStatus)
            try {
                 if (WinID != 0) {
                    Log("ACTION: Enviando Alt+Enter...")
                    SetKeyDelay 10, 10
                    ControlSend "{Alt down}{Enter}{Alt up}",, "ahk_id " . WinID
                }
            }
        } else {
             UpdateHUD("ESCRIBIENDO", "Enter Bloqueado (Working) " . Tick, "cOrange")
             Log("ACTION: Alt+Enter SUPRIMIDO por Modo Escritura.")
        }
    } 
    
    ; --- 2. MODALIDAD MUERTE SUBITA ---
    if (WasWorking and HasWindow) {
        Log("ESTADO: INICIANDO SECUENCIA MUERTE SÚBITA")
        Loop 20 { 
            Tick := Mod(Tick + 1, 100) 
            UpdateHUD("CAZANDO (SD)", "Limpieza Rápida " . Tick, "cOrange")
            Loop Targets.Length {
                tImg := Targets[A_Index]
                Log("SEARCH (SD): Buscando " . tImg)
                if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*30 " . ImageFolder . tImg) {
                     SafeToClick := true
                     Loop Files, IndicatorFolder . "Ignore\*.png"
                     {
                        x1 := FoundX - 10
                        y1 := FoundY - 10
                        x2 := FoundX + 50 
                        y2 := FoundY + 50
                        if ImageSearch(&IgnX, &IgnY, x1, y1, x2, y2, Tolerance . " " . A_LoopFileFullPath) {
                            SafeToClick := false
                            Log("IGNORED: " . tImg . " at " . FoundX . " (Blacklist match: " . A_LoopFileName . ")")
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
                     
                     try {
                         WinName := WinGetProcessName("ahk_id " . WinUnderMouse)
                         TargetName := WinGetProcessName("ahk_id " . WinID)
                         
                         if (WinName == TargetName) {
                             Click "Down"
                             Sleep 10
                             Click "Up"
                             Log("ACCION (SD): Clic CONFIRMADO en " . tImg . " at " . TargetX . "," . TargetY)
                             UpdateHUD("CAZADO (SD)", "[OBJETIVO ELIMINADO]", "c00FFFF")
                             Sleep 500 
                         } else {
                             Log("WARNING (SD): Clic bloqueado por ventana " . WinName)
                         }
                     } catch {
                        Log("ERROR (SD): Fallo Z-Order check")
                     }
                }
            }
            Sleep 100
        }
        WasWorking := false
        Log("ESTADO: MUERTE SÚBITA FINALIZADA")
        return 
    }

    ; --- 4. IDLE / SCAN NORMAL ---
    if (HasWindow) {
        if (!UserTyping) {
            UpdateHUD("👁️ BUSCANDO...", "Zona Conf.: " . WX . "," . WY . " | " . WW . "," . WH . " [" . Tick . "]", "cGray")
        }
        
        Log("SCAN: Iniciando escaneo de objetivos...")

        Loop Targets.Length {
            imgName := Targets[A_Index]
            imgPath := ImageFolder . imgName
            Log("SEARCH: Verificando " . imgName)
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
                                Log("IGNORED: " . imgName . " por proximidad a " . A_LoopFileName)
                                break
                            }
                         }
                         if (!SafeToClick) {
                             continue
                         }
    
                        MouseGetPos &OrigX, &OrigY
                        TargetX := FoundX + 15 
                        TargetY := FoundY + 10
                        
                        Log("DETECCION: " . imgName . " encontrado en " . FoundX . "," . FoundY)
                        
                        MouseMove TargetX, TargetY
                        
                        Sleep 10
                        MouseGetPos ,, &WinUnderMouse
                        
                        try {
                            WinName := WinGetProcessName("ahk_id " . WinUnderMouse)
                            TargetName := WinGetProcessName("ahk_id " . WinID)
                            Log("Z-CHECK: Mouse=" . WinName)
                            
                            if (WinName == TargetName) {
                                Click "Down"
                                Sleep 10
                                Click "Up"
                                Log("ACCION: Clic CONFIRMADO en " . imgName . " at " . TargetX . "," . TargetY)
                                UpdateHUD("👁️ CAZADO", "[OBJETIVO ELIMINADO]", "c00FFFF") 
                                MouseMove OrigX, OrigY
                                SetTimer RemoveToolTip, -1000
                                return 
                            } else {
                                MouseMove OrigX, OrigY
                                Log("WARNING: Objetivo detectado pero obstruido por: " . WinName)
                            }
                        } catch {
                            MouseMove OrigX, OrigY
                            Log("ERROR: Fallo Z-Order Normal Scan")
                        }
                    } else {
                        Log("RESULT: " . imgName . " no encontrado.")
                    }
                }
            }
        }
    } else {
        Log("SKIP: Sin ventana, saltando escaneo visual.")
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
