#Requires AutoHotKey v2.0
#SingleInstance Force
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"
SetMouseDelay -1 ; Velocidad máxima

; --- CONFIGURACIÓN ---
ImageFolder := A_ScriptDir . "\Targets\"
IndicatorFolder := A_ScriptDir . "\Indicators\"
Targets := []
Loop Files, ImageFolder . "*.png"
    Targets.Push(A_LoopFileName)

Tolerance := "*50" ; Tolerancia de color (0-255)

; --- INDICADOR VISUAL ---
ToolTip "🧠 OMNIGOD: CEREBRO ACTIVADO (Detectando Estado...)", 10, 10, 1
SetTimer RemoveToolTip, -3000

; --- BUCLE PRINCIPAL (CADA 500ms) ---
SetTimer WatchDog, 500
return

WatchDog() {
    ; 1. CHEQUEO DE SEGURIDAD (¿USUARIO ESCRIBIENDO?)
    ; Si vemos el botón de "Enviar" (flecha azul), significa que tú tienes el control. No tocamos nada.
    if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, Tolerance . " " . IndicatorFolder . "send.png") {
        ToolTip "🛑 USUARIO AL MANDO (Pausado)", 10, 10, 1
        return
    }

    ; 2. CHEQUEO DE ACTIVIDAD (¿AGENTE TRABAJANDO?)
    ; Solo actuamos si vemos el botón de "Stop" (cuadrado rojo), que indica trabajo en progreso.
    if !ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, Tolerance . " " . IndicatorFolder . "working.png") {
        ToolTip "💤 AGENTE INACTIVO (Esperando...)", 10, 10, 1
        return 
    }

    ; --- MODO CAZA (SOLO SI EL AGENTE ESTÁ TRABAJANDO) ---
    ToolTip "⚡ AGENTE TRABAJANDO: Buscando objetivos...", 10, 10, 1
    
    ; 3. ESTRATEGIA DE EXPANSIÓN (Collapse = Scroll)
    ; Si vemos "Collapse all", significa que hay una lista abierta.
    ; Hacemos Scroll para bajar y ver los botones que puedan estar ocultos abajo.
    if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, Tolerance . " " . IndicatorFolder . "collapse.png") {
         ToolTip "📜 LISTA EXPANDIDA: Scrolleando...", 10, 10, 1
         MouseGetPos &CurrX, &CurrY
         MouseMove A_ScreenWidth/2, A_ScreenHeight/2 
         Click "WheelDown"
         Sleep 200 ; Pequeña pausa para que el scroll termine
         MouseMove CurrX, CurrY
    }

    Loop Targets.Length {
        imgName := Targets[A_Index]
        imgPath := ImageFolder . imgName
        
        if FileExist(imgPath) {
            try {
                if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, Tolerance . " " . imgPath) {
                    
                    MouseGetPos &OrigX, &OrigY
                    
                    ; Mover al CENTRO PROFUNDO de la imagen (evitar bordes)
                    TargetX := FoundX + 30 
                    TargetY := FoundY + 15
                    MouseMove TargetX, TargetY
                    
                    ; --- CLIC ROBUSTO ---
                    Sleep 50
                    Click "Down"
                    Sleep 50
                    Click "Up"
                    Sleep 50
                    
                    ; Regresar mouse instantáneamente
                    MouseMove OrigX, OrigY
                    
                    ToolTip "👻 CAZADO: " . imgName, 10, 10, 1
                    SetTimer RemoveToolTip, -1000
                    return 
                }
            }
        }
    }
}

RemoveToolTip() {
    ToolTip ,,,1
}

; --- PAUSA DE EMERGENCIA CON F8 ---
F8:: {
    Pause -1
    if A_IsPaused
        ToolTip "🛑 OMNIGOD PAUSADO", 10, 10, 1
    else
        ToolTip "🟢 OMNIGOD VIGILANDO", 10, 10, 1
    SetTimer RemoveToolTip, -2000
}
