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
ConfigFile := A_ScriptDir . "\OmniGod_Config.ini"

; Initialize Calibrated zone
global ChatRelX := 0, ChatRelY := 0, ChatRelW := 0, ChatRelH := 0
try {
    ChatRelX := IniRead(ConfigFile, "ChatZone", "RelX", "0")
    ChatRelY := IniRead(ConfigFile, "ChatZone", "RelY", "0")
    ChatRelW := IniRead(ConfigFile, "ChatZone", "RelW", "0")
    ChatRelH := IniRead(ConfigFile, "ChatZone", "RelH", "0")
    if (ChatRelW > 0)
        Log("CONFIG: Zona calibrada cargada. " . ChatRelW . "x" . ChatRelH)
}

; --- OVERLAY GUI (VISUALIZER - HOLLOW BOX) ---
global BorderThickness := 5
global BorderColor := "00FFFF"
global BorderAlpha := 150 ; 0-255 (Visible but see-through)

global GuiTop := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
global GuiBot := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
global GuiLeft := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
global GuiRight := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")

GuiTop.BackColor := BorderColor
GuiBot.BackColor := BorderColor
GuiLeft.BackColor := BorderColor
GuiRight.BackColor := BorderColor

WinSetTransparent(BorderAlpha, GuiTop)
WinSetTransparent(BorderAlpha, GuiBot)
WinSetTransparent(BorderAlpha, GuiLeft)
WinSetTransparent(BorderAlpha, GuiRight)

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
    
    if (!IsActive) {
        ; Hide all borders
        GuiTop.Hide()
        GuiBot.Hide()
        GuiLeft.Hide()
        GuiRight.Hide()
    }
    
    ; Sync with Server
    try {
        statusJson := IsActive ? "true" : "false"
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", "http://localhost:1337/api/toggle_ghost", false) ; Sync=false guarantees delivery
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send('{"active": ' . statusJson . '}')
    } catch {
        Log("ERROR: Fallo al sincronizar F8 con OmniServer")
    }

    if (IsActive) {
        TraySetIcon "shell32.dll", 1 
        SoundPlay "*64" 
        UpdateHUD("ACTIVO", "CAZANDO (F8: Pausa | F9: HUD)", "c00FF00")
        Log("Estado cambiado a: ACTIVO (Sync Server)")
    } else {
        TraySetIcon "shell32.dll", 28
        SoundPlay "*16" 
        UpdateHUD("PAUSADO", "Sistema Detenido", "cFF0000")
        Log("Estado cambiado a: PAUSADO (Sync Server)")
    }
}

; --- BUCLE PRINCIPAL (CADA 500ms) ---
SyncTick := 0
Loop {
    ; Sincronización Remota (Siempre, incluso pausado)
    SyncTick := Mod(SyncTick + 1, 2) ; Cada ~1 segundo
    if (SyncTick == 0) {
        CheckRemoteStatus()
    }

    if (!IsActive) {
        Sleep 500
        continue
    }
    WatchDog()
    Sleep 500 
}
return

CheckRemoteStatus() {
    global IsActive
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "http://localhost:1337/api/status", true)
        whr.Send()
        if (whr.WaitForResponse(0.2)) {
             resp := whr.ResponseText
             ; Parsear respuesta JSON simple
             if (InStr(resp, '"OmniGod":true')) {
                 if (!IsActive) {
                     IsActive := true
                     UpdateHUD("ACTIVO", "Reanudado Remotamente", "c00FF00")
                     Log("REMOTE: Reactivado por Servidor")
                     TraySetIcon "shell32.dll", 1
                     SoundPlay "*64"
                 }
             } else if (InStr(resp, '"OmniGod":false')) {
                 if (IsActive) {
                     IsActive := false
                     UpdateHUD("PAUSADO", "Detenido Remotamente", "cFF0000")
                     Log("REMOTE: Pausado por Servidor")
                     TraySetIcon "shell32.dll", 28
                     SoundPlay "*16"
                 }
             }
        }
    } catch {
        ; Fallo silencioso si el servidor no responde
    }
}

WatchDog() {
    static Tick := 0
    static LastWX := 0, LastWY := 0, LastWW := 0, LastWH := 0
    static LastState := ""
    static WasTyping := false 
    static LastAltEnter := 0 ; Fix: Initialize variable
    
    ; 1. DETECTAR FOCO ACTUAL
    try {
        ActiveProcess := WinGetProcessName("A")
    } catch {
        ActiveProcess := "Unknown"
    }
    FriendlyName := GetFriendlyName(ActiveProcess)

    Tick := Mod(Tick + 1, 100)
    
    ; [LOG] Inicio de Ciclo
    Log("CYCLE[" . Tick . "]: Iniciando WatchDog... Focus=" . FriendlyName)
    
    HasWindow := false
    WinID := 0
    WX := 0, WY := 0, WW := 0, WH := 0
    
    if (ActiveProcess = "Code.exe" or ActiveProcess = "Antigravity.exe" or ActiveProcess = "AntiGravity.exe") {
        HasWindow := true
        WinID := WinExist("A")
        WinGetPos &WX, &WY, &WW, &WH, "ahk_id " . WinID
    } else {
        UpdateHUD("ESPERANDO", "Buscando AntiGravity...", "cGray")
        GuiTop.Hide()
        GuiBot.Hide()
        GuiLeft.Hide()
        GuiRight.Hide()
        return
    }

    ; Formatear string de coordenadas
    CoordStr := (HasWindow) ? " [" . WX . "," . WY . "] " . Tick : " [-,-] " . Tick

    ; --- DEFINICIÓN DE ZONA DE CHAT (CALIBRADA) ---
    ; Prioridad: Configuración de Usuario > Heurística Simple
    global ChatRelX, ChatRelY, ChatRelW, ChatRelH
    
    ; Debug de variables globales para asegurar que F10 funciona
    ; if (Tick == 0) Log("DEBUG: ChatRelW=" . ChatRelW)

    if (ChatRelW > 0) {
        ; Usar calibración guardada (Relativa a la ventana)
        ScanX := WX + ChatRelX
        ScanY := WY + ChatRelY
        ScanW := ChatRelW
        ScanH := ChatRelH
    } else {
        ; Fallback: Heurística Inteligente (Asumir Sidebar izquierdo ~20%)
        SidebarMargin := WW * 0.20 
        
        ScanX := WX + SidebarMargin
        ScanY := WY + 80 ; Saltar header
        ScanW := WW - SidebarMargin - 25 ; Margen derecho pequeño
        ScanH := WH - 90
    }

    ; --- VISUAL OVERLAY UPDATE (HOLLOW BOX) ---
    if (IsActive && HUDVisible && HasWindow) {
        ; Top
        GuiTop.Show("x" . ScanX . " y" . ScanY . " w" . ScanW . " h" . BorderThickness . " NoActivate")
        ; Bottom
        GuiBot.Show("x" . ScanX . " y" . (ScanY + ScanH - BorderThickness) . " w" . ScanW . " h" . BorderThickness . " NoActivate")
        ; Left
        GuiLeft.Show("x" . ScanX . " y" . ScanY . " w" . BorderThickness . " h" . ScanH . " NoActivate")
        ; Right
        GuiRight.Show("x" . (ScanX + ScanW - BorderThickness) . " y" . ScanY . " w" . BorderThickness . " h" . ScanH . " NoActivate")
    } else {
        GuiTop.Hide()
        GuiBot.Hide()
        GuiLeft.Hide()
        GuiRight.Hide()
    }

    ; --- SMART TYPING DETECTION (FASE 2: HEURÍSTICA + VISUAL + AUDITIVA) ---
    UserTyping := false
    
    ; --- SMART TYPING DETECTION (FASE 2: HEURÍSTICA + VISUAL + AUDITIVA) ---
    UserTyping := false
    
    ; 1. Heurística Física (Teclado/Mouse activo recientemente)
    ; Si el usuario tocó algo en los últimos 2 segundos, asumimos que está interactuando.
    if (A_TimeIdlePhysical < 2000) {
        UserTyping := true
        ; Log("HEURISTICA: Actividad física reciente.")
    }

    ; 2. Heurística de Cursor (Mouse sobre el chat + Icono de texto)
    MouseGetPos(&MX, &MY)
    if (MX >= ScanX && MX <= (ScanX + ScanW) && MY >= ScanY && MY <= (ScanY + ScanH)) {
        if (A_Cursor == "IBeam") {
            UserTyping := true
        }
    }

    ; 3. Chequeo Visual (Respaldo: send.png = Caja con texto)
    if (HasWindow) {
        if ImageSearch(&FoundX, &FoundY, ScanX, ScanY, ScanX+ScanW, ScanY+ScanH, Tolerance . " " . IndicatorFolder . "send.png") {
            UserTyping := true
        }
    }
    
    ; 4. Feedback Sensorial (Cambio de Estado)
    if (UserTyping != WasTyping) {
        if (UserTyping) {
            SoundBeep 1000, 50 
        } else {
            SoundBeep 600, 50
        }
        WasTyping := UserTyping
    }
    
    ; --- LOGICA PRINCIPAL (DUAL MODE) ---
    HUDText := "CAZANDO (" . FriendlyName . ")"
    HUDSub := "Zona: " . WX . "," . WY . " [" . Tick . "]"
    HUDColor := "cGray"

    if (UserTyping) {
        ; MODO: USUARIO ESCRIBIENDO / BOT CAZANDO
        HUDText := "USUARIO ESCRIBIENDO"
        HUDSub := "Alt+Enter: BLOQUEADO | Clics: ACTIVOS"
        HUDColor := "cOrange"
        
        ; Resetear timer de Alt+Enter para que no dispare apenas dejes de escribir
        LastAltEnter := A_TickCount 
        
    } else {
        ; MODO: CAZANDO AUTOMÁTICO
        HUDText := "CAZANDO"
        HUDSub := "Auto-Confirm: ON | Clics: ACTIVOS"
        HUDColor := "c00FF00" 
        
        ; AUTO-CONFIRM (ALT+ENTER cada 3s si la caja está vacía)
        if (A_TickCount - LastAltEnter > 3000) {
            Send "!{Enter}"
            LastAltEnter := A_TickCount
            Log("ACTION: Auto-Confirm (Alt+Enter) enviado (Idle Check)")
            
            UpdateHUD("CONFIRMANDO...", "Enviando Alt+Enter", "cCyan")
            Sleep 200
        }
    }
    
    UpdateHUD(HUDText, HUDSub, HUDColor)

    ; --- CONTINUAR SIEMPRE CON LA CAZA DE BOTONES (NO RETURN) ---
    
    ; --- PRIORIDAD 0: FINALIZADOR (ACCEPT ALL) ---
    if (HasWindow) {
        Log("SEARCH: Buscando 'AcceptAll_Priority.png'...")
        if ImageSearch(&FoundX, &FoundY, ScanX, ScanY, ScanX+ScanW, ScanY+ScanH, "*60 " . ImageFolder . "AcceptAll_Priority.png") {
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
                    UpdateHUD("PRIORIDAD (" . FriendlyName . ")", "Finalizando" . CoordStr, "c00FF00")
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
        IsWorkingVisual := ImageSearch(&FoundX, &FoundY, ScanX, ScanY, ScanX+ScanW, ScanY+ScanH, "*100 " . IndicatorFolder . "working.png")
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
            UpdateHUD("TRABAJANDO (" . FriendlyName . ")", Source . " " . CoordStr, ColorStatus)
            try {
                 if (WinID != 0) {
                    Log("ACTION: Enviando Alt+Enter...")
                    SetKeyDelay 10, 10
                    ControlSend "{Alt down}{Enter}{Alt up}",, "ahk_id " . WinID
                }
            }
        } else {
             Log("SKIP: Activo pero Usuario escribiendo. Clics permitidos, Enter bloqueado.")
             UpdateHUD("ESCRIBIENDO (" . FriendlyName . ")", "Enter Bloqueado (Working) " . Tick, "cOrange")
        }
    } 

 
    
    ; --- 2. MODALIDAD MUERTE SUBITA ---
    if (WasWorking and HasWindow) {
        Log("ESTADO: INICIANDO SECUENCIA MUERTE SÚBITA")
        Loop 20 { 
            if (!IsActive) {
                Log("BREAK: Interrupción por Usuario (F8) durante Muerte Súbita")
                return
            }
            Tick := Mod(Tick + 1, 100) 
            UpdateHUD("CAZANDO (" . FriendlyName . ")", "Limpieza Rápida " . Tick, "cOrange")
            Loop Targets.Length {
                if (!IsActive) {
                     return
                }
                tImg := Targets[A_Index]
                ; (Rest of the loop code remains the same, just adding the check)
                Log("SEARCH (SD): Buscando " . tImg)
                if ImageSearch(&FoundX, &FoundY, ScanX, ScanY, ScanX+ScanW, ScanY+ScanH, "*30 " . ImageFolder . tImg) {
                     SafeToClick := true
                     Loop Files, IndicatorFolder . "Ignore\*.png"
                     {
                        x1 := Max(0, FoundX - 10)
                        y1 := Max(0, FoundY - 10)
                        x2 := FoundX + 50 
                        y2 := FoundY + 50
                        
                        try {
                            if ImageSearch(&IgnX, &IgnY, x1, y1, x2, y2, Tolerance . " " . A_LoopFileFullPath) {
                                SafeToClick := false
                                Log("IGNORED: " . tImg . " at " . FoundX . " (Blacklist match: " . A_LoopFileName . ")")
                                break
                            }
                        } catch {
                            ; Ignorar errores de handle inválido si la zona es extraña
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
                             UpdateHUD("CAZADO (" . FriendlyName . ")", "[OBJETIVO ELIMINADO]", "c00FFFF")
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
            UpdateHUD("CAZANDO (" . FriendlyName . ")", "Zona: " . WX . "," . WY . " [" . Tick . "]", "cGray")
        }
        
        Log("SCAN: Iniciando escaneo de objetivos...")

        Loop Targets.Length {
            if (!IsActive) {
                Log("BREAK: Interrupción por Usuario (F8) durante Escaneo Normal")
                return
            }
            
            imgName := Targets[A_Index]
            imgPath := ImageFolder . imgName
            Log("SEARCH: Verificando " . imgName)
            if FileExist(imgPath) {
                try {
                    if ImageSearch(&FoundX, &FoundY, ScanX, ScanY, ScanX+ScanW, ScanY+ScanH, Tolerance . " " . imgPath) {
                         SafeToClick := true
                         Loop Files, IndicatorFolder . "Ignore\*.png"
                         {
                            x1 := Max(0, FoundX - 10)
                            y1 := Max(0, FoundY - 10)
                            x2 := FoundX + 50 
                            y2 := FoundY + 50
                            
                            try {
                                if ImageSearch(&IgnX, &IgnY, x1, y1, x2, y2, Tolerance . " " . A_LoopFileFullPath) {
                                    SafeToClick := false
                                    Log("IGNORED: " . imgName . " por proximidad a " . A_LoopFileName)
                                    break
                                }
                            } catch {
                                ; Ignorar fallos de handle
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
                                UpdateHUD("CAZADO (" . FriendlyName . ")", "[OBJETIVO ELIMINADO]", "c00FFFF") 
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
    } catch {
        ; Ignore log errors
    }
}

; Double-check closure of previous functions
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

GetFriendlyName(procName) {
    if (procName == "AntiGravity.exe")
        return "AntiGravity"
    if (procName == "explorer.exe")
        return "Escritorio/Explorer"
    if (procName == "chrome.exe")
        return "Google Chrome"
    if (procName == "Code.exe")
        return "VS Code"
    if (procName == "notepad.exe")
        return "Bloc de Notas"
    if (procName == "powershell.exe")
        return "PowerShell / Terminal"
    return procName ; Default fallback
}

; --- DEBUG TOOLS ---
F7::
{
    Log("DEBUG: Iniciando Diagnóstico Visual COMPLETO (F7)...")
    Msg := "=== REPORTE DE DIAGNÓSTICO VISUAL ===`n`n"
    
    ; 1. Scan Indicators
    Msg .= "--- INDICADORES ---`n"
    Loop Files, IndicatorFolder . "*.png"
    {
        IsFound := ImageSearch(&FX, &FY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*100 " . A_LoopFileFullPath)
        Status := IsFound ? "✅ ENCONTRADO (" . FX . "," . FY . ")" : "❌ NO ENCONTRADO"
        Msg .= A_LoopFileName . ": " . Status . "`n"
    }

    ; 2. Scan Targets
    Msg .= "`n--- OBJETIVOS (TARGETS) ---`n"
    Loop Files, ImageFolder . "*.png"
    {
        IsFound := ImageSearch(&TX, &TY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*100 " . A_LoopFileFullPath)
        Status := IsFound ? "✅ ENCONTRADO (" . TX . "," . TY . ")" : "❌ NO ENCONTRADO"
        Msg .= A_LoopFileName . ": " . Status . "`n"
    }
    
    ; Guardar reporte en log también
    Log("DEBUG REPORT:`n" . Msg)
    
    ; Mostrar en pantalla
    MsgBox Msg, "OmniGod Visual Scanner", "Iconi"
}

; --- CALIBRATION WIZARD (F10) ---
F10::
{
    global ChatRelX, ChatRelY, ChatRelW, ChatRelH
    
    WinID := WinExist("A")
    if (!WinID) {
        MsgBox "¡Abre AntiGravity primero y asegúrate de que esté activo!", "Error", "Icon!"
        return
    }
    
    WinGetPos &WX, &WY, &WW, &WH, "ahk_id " . WinID
    
    MsgBox "MODO CALIBRACIÓN`n`n1. Pon el mouse en la esquina SUPERIOR IZQUIERDA del cuadro de chat.`n2. Presiona ENTER (Click OK) lo más rápido posible o usa ESPACIO.", "Paso 1", "Icon?"
    MouseGetPos &X1, &Y1
    SoundBeep 750, 100
    
    MsgBox "Paso 2`n`n1. Pon el mouse en la esquina INFERIOR DERECHA del cuadro de chat.`n2. Presiona ENTER/ESPACIO.", "Paso 2", "Icon?"
    MouseGetPos &X2, &Y2
    SoundBeep 750, 100
    
    if (X2 <= X1 or Y2 <= Y1) {
        MsgBox "Coordenadas inválidas. Intenta de nuevo (Izquierda-Arriba -> Derecha-Abajo).", "Error"
        return
    }
    
    ; Calcular coordenadas relativas a la ventana
    ChatRelX := X1 - WX
    ChatRelY := Y1 - WY
    ChatRelW := X2 - X1
    ChatRelH := Y2 - Y1
    
    ; Guardar
    try {
        IniWrite(ChatRelX, ConfigFile, "ChatZone", "RelX")
        IniWrite(ChatRelY, ConfigFile, "ChatZone", "RelY")
        IniWrite(ChatRelW, ConfigFile, "ChatZone", "RelW")
        IniWrite(ChatRelH, ConfigFile, "ChatZone", "RelH")
        
        MsgBox "¡CALIBRACIÓN GUARDADA!`n`nZona: " . ChatRelW . "x" . ChatRelH . "`nOffset: " . ChatRelX . "," . ChatRelY . "`n`nEl bot ahora usará EXCLUSIVAMENTE esta zona.", "Éxito", "Iconi"
        Log("CALIBRATION: Nueva zona guardada. " . ChatRelW . "x" . ChatRelH)
    } catch as err {
        MsgBox "Error al guardar config: " . err.Message
    }
}

; --- PHASE 3: NEURAL VISION (F11) ---
; --- AUTO-DETECT / RESET ZONE (F11) ---
F11::
{
    global ChatRelX, ChatRelY, ChatRelW, ChatRelH
    
    ; Resetear variables a 0 activa el modo "Dinámico" en WatchDog
    ChatRelX := 0
    ChatRelY := 0
    ChatRelW := 0
    ChatRelH := 0
    
    try {
        IniWrite("0", ConfigFile, "ChatZone", "RelW") ; Marcar como no-calibrado en disco
        
        SoundBeep 1000, 100
        UpdateHUD("ZONA AUTO", "Modo Dinámico Activado", "cCyan")
        Log("CALIBRATION: Reset a MODO AUTOMÁTICO (Dinámico)")
        
        MsgBox "Modo de Detección Automática ACTIVADO.`n`nEl bot ahora ajustará la zona azul automáticamente al tamaño de la ventana.", "Auto-Detect", "Iconi T2"
    } catch as err {
        Log("ERROR al resetear config: " . err.Message)
    }
}

; --- PHASE 3: NEURAL VISION (SHIFT + F11) ---
+F11::
{
    Log("VISION: Iniciando Neural Scan (Python/PS Bridge)...")
    UpdateHUD("VISION", "Analizando...", "c00FFFF")
    
    VisionScript := A_ScriptDir . "\..\tools\OmniVision.ps1"
    OutputFile := A_ScriptDir . "\..\vision_result.json"
    
    ; Ejecutar PS1 oculto
    RunWait("powershell -NoProfile -ExecutionPolicy Bypass -File `"" . VisionScript . "`" > `"" . OutputFile . "`"", , "Hide")
    
    try {
        if FileExist(OutputFile) {
            JSON := FileRead(OutputFile)
            Log("VISION RESULT: " . JSON)
            MsgBox "Neural Vision Result:`n" . JSON, "OmniGod Eyes", "Iconi"
            UpdateHUD("VISION", "Datos Recibidos", "green")
        } else {
            Log("VISION ERROR: No output file")
        }
    } catch as err {
        Log("VISION ERROR: " . err.Message)
    }
}
