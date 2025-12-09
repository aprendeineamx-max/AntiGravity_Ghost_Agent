#Requires AutoHotKey v2.0
#SingleInstance Force
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"
SetMouseDelay -1 ; Velocidad máxima

; --- CONFIGURACIÓN ---
ImageFolder := A_ScriptDir . "\Targets\"
Targets := []
Loop Files, ImageFolder . "*.png"
    Targets.Push(A_LoopFileName)

Tolerance := "*50" ; Tolerancia de color (0-255)

; --- INDICADOR VISUAL ---
ToolTip "👻 OMNIGOD: PROTOCOLO VISUAL ACTIVO...", 10, 10, 1
SetTimer RemoveToolTip, -3000

; --- BUCLE PRINCIPAL (CADA 500ms) ---
SetTimer WatchDog, 500
return

WatchDog() {
    ; 1. ESTRATEGIA VISUAL (IMAGE SEARCH)
    Loop Targets.Length {
        imgName := Targets[A_Index]
        imgPath := ImageFolder . imgName
        
        if FileExist(imgPath) {
            try {
                ; Busca la imagen en toda la pantalla
                if ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, Tolerance . " " . imgPath) {
                    
                    ; Guardar posición actual del mouse
                    MouseGetPos &OrigX, &OrigY
                    
                    ; Clicar en el centro de la imagen encontrada
                    Click FoundX + 10, FoundY + 5
                    
                    ; Regresar mouse instantáneamente
                    MouseMove OrigX, OrigY
                    
                    ; Feedback
                    ToolTip "👻 CAZADO: " . imgName, 10, 10, 1
                    SetTimer RemoveToolTip, -1000
                    return ; Terminar ciclo para no saturar
                }
            }
        }
    }

    ; 2. ESTRATEGIA TECLADO (SOLO SI ESTAMOS EN ANTIGRAVITY)
    try {
        if WinActive("AntiGravity") {
            ; Enviar Alt+Enter suavemente si no se está escribiendo
            if (A_TimeIdlePhysical > 1000) {
                SendInput "!{Enter}"
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
