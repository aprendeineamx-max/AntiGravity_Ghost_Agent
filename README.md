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

### 3. Project OmniGod v2.0 (Capa Visual Inteligente) 👁️
*   **Tecnología**: AutoHotKey v2 (Computer Vision).
*   **Misión**: Escaneo de píxeles en pantalla (Image Search).
*   **Inteligencia ("Smart Brain")**:
    *   🛑 **Semáforo de Contexto**: Detecta si estás escribiendo (icono "Enviar" o Chat Vacío) y se pausa automáticamente. Solo actúa cuando ve el indicador de "Agente Trabajando" (Cuadrado Rojo).
    *   📜 **Scroll Táctico**: Si detecta una lista expandida ("Collapse all"), hace scroll automático para cazar botones ocultos.
    *   🎯 **Puntería Zen**: Ajuste de coordenadas al centro exacto del botón para evitar clics fallidos en bordes.
*   **Objetivos**: Cualquier cosa en la carpeta `Targets`.


---

## ⚙️ Configuración y Personalización

### Ajustar Tiempos de Espera
Si sientes que el agente es muy rápido (o muy lento), edita `OmniBot/OmniGod.ahk`:
```autohotkey
; Tiempo que debe pasar sin que toques el teclado para que el bot actúe
if (A_TimeIdlePhysical > 5000) { ... } ; 5000ms = 5 Segundos
```

### Añadir Nuevos Objetivos
No necesitas tocar código.
*   **Para Objetivos (Cosas a destruir)**: Agrega imágenes `.png` a `OmniBot/Targets/`.
*   **Para Indicadores (Señales de Estado)**: Agrega imágenes `.png` a `OmniBot/Indicators/` (ej. botón de stop, icono de enviar).

---

## ❓ Solución de Problemas (Troubleshooting)

**P: El bot hace clic en el botón de Stop o Cancelar.**
R: ¡Cuidado! Esas imágenes deben ir en la carpeta `Indicators`, NO en `Targets`. Si están en Targets, el bot las atacará.

**P: VS Code me pide "Reload" a veces.**
R: Ghost Agent requiere inyectarse. Si VS Code se actualiza, es posible que debas reinstalar la extensión "Custom CSS and JS Loader" y re-aplicar.

**P: ¿Es seguro?**
R: Todo corre local en tu máquina. El código es Open Source. Tú tienes el control.

---

*Desarrollado para la Élite de Programación.*
**v3.3 Universal Soldier**
