# ⚛️ AntiGravity Ghost Agent
### *Protocolo de Automatización de Fricción Cero para VS Code*

> **"Tú escribes código. El Agente maneja la burocracia."**

AntiGravity Ghost Agent es una suite de automatización de **grado militar** diseñada para eliminar el 100% de las interrupciones en tu flujo de trabajo con IAs (Gemini, Copilot, etc.). Si aparece un botón pidiendo "Aceptar", "Permitir" o "Confirmar", este sistema lo destruye en milisegundos.

---

## 🔰 Inicio Rápido (Principiantes)

Si solo quieres que funcione **YA**:

1.  **Instala los Requisitos**:
    *   Tener **VS Code**.
    *   Tener **AutoHotKey v2** instalado.

2.  **Inicia el Sistema**:
    *   Ve a la carpeta del proyecto.
    *   Doble clic en `START_OMNICONTROL.bat`.
    *   Doble clic en `OmniBot/OmniGod.ahk`.

3.  **Calibra tu Arma (OmniGod)**:
    *   Cuando veas un botón azul molesto en VS Code...
    *   Usa `Win + Shift + S` y recorta **SOLO** el botón azul.
    *   Guárdalo como `.png` en la carpeta `OmniBot/Targets/`.
    *   Recarga el script OmniGod (Click derecho en el icono 'H' verde > Reload).

**¡Listo!** El sistema ahora vigila tu espalda.

---

## 🧠 Arquitectura del Sistema (Avanzados)

Este no es un simple script. Es una tríada de sistemas operando en paralelo para garantizar redundancia y velocidad.

### 1. Ghost Agent (Capa Interna) 👻
*   **Tecnología**: JavaScript inyectado en el proceso de renderizado de Electron.
*   **Misión**: Intercepta el DOM de VS Code.
*   **Objetivos**: Detecta botones `[aria-label="Accept"]`, `.monaco-button` y prompts de chat.
*   **Ventaja**: Latencia Cero.

### 2. OmniControl HUD (Capa Accesibilidad) 🛡️
*   **Tecnología**: PowerShell + .NET UIAutomation + Win32 API.
*   **Misión**: Escanea la ventana activa en busca de elementos de Accessibility Tree.
*   **Objetivos**: Popups nativos de Windows, cuadros de diálogo de sistema y ventanas que el DOM no ve.

### 3. Project OmniGod v3.5 (Ghost Architecture) 👁️
*   **Tecnología**: AutoHotKey v2 (Computer Vision) + Neural Heuristics.
*   **Misión**: Escaneo de píxeles en pantalla (Image Search).
*   **Novedades v3.5**:
    *   🧱 **Smart Zoning (Real Data)**: Usa **Raycast** de píxeles para detectar los bordes reales de la caja de chat. Adiós a los rectángulos arbitrarios. (F11)
    *   🧠 **Zone Memory**: Si el botón de enviar desaparece al escribir, el bot **recuerda** la última zona válida. Estabilidad total.
    *   🤝 **Hive Mind (Mente Colmena)**: OmniGod comparte su "Zona de Visión" en tiempo real con OmniControl. Si un botón aparece fuera del chat, OmniControl lo ignorará por seguridad.
    *   👻 **Strict Focus**: Diseño minimalista "Hollow Border" que desaparece si cambias de ventana.
    *   ⌨️ **Smart Typing v2**: Detecta actividad física en el teclado para no interrumpir tu escritura jamás.

---

## ⚙️ Configuración y Personalización

### Comandos de Teclado
*   **F8**: Pausar/Reanudar todo el sistema (Kill Switch).
*   **F10**: Calibración Manual de Zona (Dibuja tu rectángulo).
*   **F11**: **Auto-Detect / Reset Zone** (Usa Raycast para encontrar la caja de chat automáticamente).
*   **Shift+F11**: Mock de Visión Neuronal (Experimental).

### Ajustar Tiempos de Espera
Si sientes que el agente es muy rápido (o muy lento), edita `OmniBot/OmniGod.ahk`:
```autohotkey
; Tiempo que debe pasar sin que toques el teclado para que el bot actúe
if (A_TimeIdlePhysical > 2000) { ... } ; 2000ms = 2 Segundos
```

### Añadir Nuevos Objetivos
No necesitas tocar código.
*   **Para Objetivos (Cosas a destruir)**: Agrega imágenes `.png` a `OmniBot/Targets/`.
*   **Para Indicadores (Señales de Estado)**: Agrega imágenes `.png` a `OmniBot/Indicators/` (ej. botón de stop, icono de enviar).

---

## ❓ Solución de Problemas (Troubleshooting)

**P: El bot hace clic en el botón de Stop o Cancelar.**
R: ¡Cuidado! Esas imágenes deben ir en la carpeta `Indicators`, NO en `Targets`. Si están en Targets, el bot las atacará.

**P: OmniControl no hace clic en un botón fuera del chat.**
R: **Es una característica, no un bug.** Desde v3.5, OmniControl respeta la zona definida por OmniGod. Si quieres que haga clic, asegúrate de que OmniGod haya detectado esa área (F11).

**P: ¿Es seguro?**
R: Todo corre local en tu máquina. El código es Open Source. Tú tienes el control.

---

*Desarrollado para la Élite de Programación.*
**v3.5 Ghost Architecture**
