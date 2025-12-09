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
global IsActive := true ; <--- ENCENDIDO POR DEFECTO (Solicitud Usuario)

; --- INICIO ---
TraySetIcon "shell32.dll", 1 ; Icono de ojo activo
SoundPlay "*64" ; Ding!
ToolTip "👁️ OmniGod: CAZANDO (Presiona F8 para pausar)", A_ScreenWidth/2, 10, 1
SetTimer RemoveToolTip, -3000

; --- HOTKEY TOGGLE (F8) ---
F8::
{
    global IsActive
    IsActive := !IsActive
    if (IsActive) {
        TraySetIcon "shell32.dll", 1 ; Icono activo
        SoundPlay "*64" ; Sonido Windows "Asterisk" (Ding!)
        ToolTip "👁️ OmniGod: CAZANDO", A_ScreenWidth/2, 10, 1
    } else {
        TraySetIcon "shell32.dll", 28
        SoundPlay "*16" ; Sonido Windows "Critical Stop" (Bonk!)
        ToolTip "💤 OmniGod: PAUSADO", A_ScreenWidth/2, 10, 1
        SetTimer RemoveToolTip, -2000
    }
}

; RemoveToolTip definition removed from here (it is defined at the end of file)

; --- BUCLE PRINCIPAL (CADA 500ms) ---
Loop {
    if (!IsActive) {
        Sleep 500
        continue
    }
    WatchDog()
    Sleep 500 ; Simulate the original SetTimer interval
}
return

WatchDog() {
    ; --- PRIORIDAD 0: FINALIZADOR (ACCEPT ALL) ---
    ; Este botón aparece cuando el agente termina. Hay que darle clic AUNQUE ya no haya cuadro rojo.
    ; Aumentamos tolerancia a *100 para asegurar detección (azules variables)
    if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*100 " . ImageFolder . "AcceptAll_Priority.png") {
         ToolTip "✨ FINALIZANDO TAREA: Accept All detectado", 10, 10, 1
         MouseGetPos &OrigX, &OrigY
         
         ; Click Preciso
         TargetX := FoundX + 30 ; Centro del botón ancho
         TargetY := FoundY + 10
         MouseMove TargetX, TargetY
         Sleep 50
         Click "Down"
         Sleep 50
         Click "Up"
         Sleep 50
         MouseMove OrigX, OrigY
         
         Sleep 500 ; Pausa para no spammear
         return
    }

    ; 1. CHEQUEO DE SEGURIDAD (¿USUARIO ESCRIBIENDO?)
    ; Si vemos el botón de "Enviar" (flecha azul), significa que tú tienes el control.
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
    ; ... (Keep existing scroll logic) ...

    ; 4. LISTA NEGRA (Evitar falsos positivos como botones de Code Runner)
    ; Si vemos algo de la lista negra, abortamos el ataque.
    Loop Files, IndicatorFolder . "Ignore\*.png"
    {
        if ImageSearch(&IgnX, &IgnY, 0, 0, A_ScreenWidth, A_ScreenHeight, Tolerance . " " . A_LoopFileFullPath) {
            ; Opción A: Abortar todo (Más seguro)
            ; ToolTip "🛑 OBJETIVO PROHIBIDO DETECTADO: " . A_LoopFileName, 10, 10, 1
            ; return
            
            ; Opción B: (Más avanzada) - Solo no dar clic si está muy cerca de donde íbamos a dar clic
            ; Por ahora usaremos Opción A si el usuario quiere pausar por defecto.
        }
    }

    Loop Targets.Length {
        imgName := Targets[A_Index]
        imgPath := ImageFolder . imgName
        
        if FileExist(imgPath) {
            try {
                if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, Tolerance . " " . imgPath) {
                    
                    ; --- VERIFICACIÓN DE SEGURIDAD (IGNORAR SI COINCIDE CON LISTA NEGRA) ---
                    ; Check de proximidad: Si lo que encontramos está cerca de una imagen prohibida...
                    ; Por simplicidad/rendimiento: Si hay una imagen 'Ignore' visible, asumimos riesgo y NO atacamos este ciclo.
                     Loop Files, IndicatorFolder . "Ignore\*.png"
                     {
                        if ImageSearch(&IgnX, &IgnY, 0, 0, A_ScreenWidth, A_ScreenHeight, Tolerance . " " . A_LoopFileFullPath) {
                            ToolTip "🛡️ ZONA SEGURA (Obj. Ignorado)", 10, 10, 1
                            return
                        }
                     }

                    MouseGetPos &OrigX, &OrigY
                    ; ... (Keep existing click logic) ...
                    
                    ; Mover al CENTRO SEGURO (Balanceado para iconos y botones grandes)
                    TargetX := FoundX + 15 
                    TargetY := FoundY + 10
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

    ; --- ESTRATEGIA DE SCROLL (Vertical Scan) ---
    ; Si hemos llegado aqui, no hay botones visibles.
    ; Usamos la posicion del boton "Stop" (working.png) como ancla para saber donde esta el chat.
    
    if ImageSearch(&AnchorX, &AnchorY, 0, 0, A_ScreenWidth, A_ScreenHeight, Tolerance . " " . IndicatorFolder . "working.png") {
        ; Mover el mouse 300 pixeles ARRIBA del boton de Stop.
        ; Esto coloca el cursor justo en medio del historial del chat.
        CenterX := AnchorX + 15
        CenterY := AnchorY - 300
        MouseMove CenterX, CenterY
        
        ToolTip "📜 SCROLL ACTIVO (Centrado en Chat)", 10, 10, 1
        
        ; Scroll Agresivo hacia ABAJO (Prioridad)
        Loop 5 {
            Click "WheelDown"
            Sleep 50
        }
        
        ; Pequeño rebote hacia ARRIBA para "sacudir" y revelar botones pegados al borde
        Click "WheelUp" 
        Sleep 100
        
    } else {
        ; Fallback si por alguna razon extraña perdimos el ancla
        ToolTip "⚠️ PERDIDO: No encuentro el chat para scrollear", 10, 10, 1
    }
}

RemoveToolTip() {
    ToolTip ,,,1
}

; End of Script
