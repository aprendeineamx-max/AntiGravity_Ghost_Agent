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
    static LogHeartbeat := 0
    
    Tick := Mod(Tick + 1, 100) ; 0-99 Heartbeat
    LogHeartbeat := Mod(LogHeartbeat + 1, 10) ; Log cada ~10 ticks (approx 1-2 segs)

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
            ; Verificar si está minimizada (-1)
            MinMax := WinGetMinMax("ahk_id " . WinID)
            if (MinMax == -1) {
                HasWindow := false
                ; Consolidamos estado NINJA/MINIMIZED
                if (LastState != "NINJA") {
                    UpdateHUD("MODO NINJA", "Ventana Minimizada - Solo Remoto", "cGray")
                    Log("ESTADO: MODO NINJA (Ventana Minimizada)")
                    LastState := "NINJA"
                }
                if (LogHeartbeat == 0) {
                     Log("ESTADO: MODO NINJA (Ventana Minimizada - Heartbeat)")
                }
            } else {
                WinGetPos &WX, &WY, &WW, &WH, "ahk_id " . WinID
                
                ; --- ZONA CIEGA EXTENDIDA (VS CODE SIDEBAR) ---
                ; 122px era la sidebar. Subimos a 350px para saltar Explorer, Search, etc.
                MarginLeft := 350 
                
                WX := WX + MarginLeft 
                WY := WY + 50 
                WW := WX + WW - MarginLeft - 20 
                WH := WY + WH - 60 
                
                ; Validación de coordenadas anti-crash (Error 87)
                if (WW > WX and WH > WY) {
                    HasWindow := true
                } else {
                    HasWindow := false
                    if (LastState != "INVALID_SIZE") {
                        Log("WARNING: Coordenadas inválidas (Ventana muy pequeña?)")
                        LastState := "INVALID_SIZE"
                    }
                    if (LogHeartbeat == 0) {
                        Log("WARNING: Ventana muy pequeña tras aplicar margen de " . MarginLeft . "px. [WX:" . WX . "]")
                    }
                }

                ; Log Geometría Change (Siempre)
                if (HasWindow and (WX != LastWX or WY != LastWY or WW != LastWW or WH != LastWH)) {
                    Log("GEOMETRIA CAMBIO: Zona Segura [" . WX . "," . WY . "] -> [" . WW . "," . WH . "] (Margen Izq: " . MarginLeft . "px)")
                    LastWX := WX, LastWY := WY, LastWW := WW, LastWH := WH
                }
            }
        } catch {
            HasWindow := false
            Log("ERROR: Fallo al obtener WinGetPos de ID: " . WinID)
        }
    }

    ; Formatear string de coordenadas + Heartbeat
    CoordStr := (HasWindow) ? " [" . WX . "," . WY . "] " . Tick : " [-,-] " . Tick

    if (!HasWindow) {
         UpdateHUD("MODO NINJA", "Solo Remoto " . CoordStr, "cGray")
         if (LogHeartbeat == 0) {
             Log("ESTADO: MODO NINJA (Buscando ventana...)")
         }
    }

    ; --- PRIORIDAD 0: FINALIZADOR (ACCEPT ALL) ---
    if (HasWindow) {
        if ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*60 " . ImageFolder . "AcceptAll_Priority.png") {
             TargetX := FoundX + 30 
             TargetY := FoundY + 10
             
             Log("DETECCION: AcceptAll_Priority encontrado en " . FoundX . "," . FoundY)
             
             MouseMove TargetX, TargetY
             Sleep 10 
             MouseGetPos ,, &WinUnderMouse
             
             ; Z-ORDER RELAXED: Check Process Name instead of ID
             try {
                WinName := WinGetProcessName("ahk_id " . WinUnderMouse)
                TargetName := WinGetProcessName("ahk_id " . WinID)
             
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
        }
    }

    ; --- 1. CHEQUEO DE ACTIVIDAD (HÍBRIDO) ---
    static WasWorking := false
    IsWorkingVisual := false
    
    if (HasWindow) {
        ; Tolerancia estricta para botón rojo working sin confundir gris
        IsWorkingVisual := ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, "*15 " . IndicatorFolder . "working.png")
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
        
        if (LastState != "TRABAJANDO") {
            Log("ESTADO: TRABAJANDO (" . Source . ") - Bloqueando clics")
            LastState := "TRABAJANDO"
        }
        ; Log masivo si el usuario quiere "todo"
        if (LogHeartbeat == 0) {
             Log("ESTADO: TRABAJANDO por " . Source)
        }
        
        UpdateHUD("TRABAJANDO", Source . " " . CoordStr, ColorStatus)
        
        try {
             if (WinID != 0) {
                SetKeyDelay 10, 10
                ControlSend "{Alt down}{Enter}{Alt up}",, "ahk_id " . WinID
                ; No logueamos cada Alt+Enter para no explotar el log (pasa cada 500ms), 
                ; pero el cambio de estado ya indica que está ocurriendo.
            } else {
                 UpdateHUD("BUSCANDO", "Esperando ventana..." . CoordStr, "cRed")
            }
        }
        return 
    } 
    
    ; --- 2. MODALIDAD MUERTE SUBITA ---
    if (WasWorking and HasWindow) {
        Log("ESTADO: INICIANDO SECUENCIA MUERTE SÚBITA")
        Loop 20 { 
            Tick := Mod(Tick + 1, 100) ; Heartbeat en sub-loop
            UpdateHUD("CAZANDO (SD)", "Limpieza Rápida " . Tick, "cOrange")
            Loop Targets.Length {
                tImg := Targets[A_Index]
                ; TOLERANCIA REDUCIDA: *100 -> *30 para evitar falsos positivos
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
        LastState := "CLEANUP_DONE"
        Log("ESTADO: MUERTE SÚBITA FINALIZADA")
        return 
    }

    ; --- 3. CHEQUEO DE SEGURIDAD USER ---
    if (HasWindow and ImageSearch(&FoundX, &FoundY, WX, WY, WW, WH, Tolerance . " " . IndicatorFolder . "send.png")) {
        if (LastState != "USER_TYPING") {
            UpdateHUD("PAUSADO", "Usuario Escribiendo " . Tick, "cOrange")
            Log("ESTADO: PAUSADO - Usuario detectado escribiendo (send.png visible)")
            LastState := "USER_TYPING"
        }
        if (LogHeartbeat == 0) {
             Log("ESTADO: PAUSADO - Usuario detectado escribiendo")
        }
        UpdateHUD("PAUSADO", "Usuario Escribiendo " . Tick, "cOrange")
        return
    }

    ; --- 4. IDLE / SCAN NORMAL ---
    if (HasWindow) {
        if (LastState != "HUNTING") {
             LastState := "HUNTING"
             Log("ESTADO: CAZANDO (Escaneo Normal)")
        }
        
        UpdateHUD("👁️ BUSCANDO...", "Zona Conf.: " . WX . "," . WY . " | " . WW . "," . WH . " [" . Tick . "]", "cGray")
        
        if (LogHeartbeat == 0) {
             ; Log heartbeat para mostrar que está escaneando
             Log("SCAN: Escaneando targets en zona confinada...")
        }

        Loop Targets.Length {
            ; ... (loop code) ...

            imgName := Targets[A_Index]
            imgPath := ImageFolder . imgName
            if FileExist(imgPath) {
                try {
                    ; Tolerancia estandar (*50) para escaneo normal
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
                        MouseGetPos ,,, &WinUnderMouse
                        
                        try {
                            WinName := WinGetProcessName("ahk_id " . WinUnderMouse)
                            TargetName := WinGetProcessName("ahk_id " . WinID)
                            
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
