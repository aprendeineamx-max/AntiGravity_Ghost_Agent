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

### 3. Project OmniGod (Capa Visual) 👁️
*   **Tecnología**: AutoHotKey v2 (Computer Vision).
*   **Misión**: Escaneo de píxeles en pantalla (Image Search).
*   **Objetivos**: Cualquier cosa que veas. Si puedes hacerle screenshot, OmniGod puede hacerle clic.
*   **Inteligencia**:
    *   Modo "Heavy Click" (Down-Wait-Up) para apps Electron.
    *   Protección de escritura (Detecta inactividad antes de enviar comandos de teclado).

---

## ⚙️ Configuración y Personalización

### Ajustar Tiempos de Espera
Si sientes que el agente es muy rápido (o muy lento), edita `OmniBot/OmniGod.ahk`:
```autohotkey
; Tiempo que debe pasar sin que toques el teclado para que el bot actúe
if (A_TimeIdlePhysical > 5000) { ... } ; 5000ms = 5 Segundos
```

### Añadir Nuevos Objetivos
No necesitas tocar código. Solo agrega imágenes `.png` a `OmniBot/Targets/`. El sistema las carga dinámicamente al iniciarse.

---

## ❓ Solución de Problemas (Troubleshooting)

**P: El bot dice "CAZADO" pero no hace clic.**
R: El modo "Heavy Click" está activado por defecto en la V3.3. Asegúrate de que tu imagen `.png` no incluya mucho fondo (que sea solo el botón) para que el centro calculado sea correcto.

**P: VS Code me pide "Reload" a veces.**
R: Ghost Agent requiere inyectarse. Si VS Code se actualiza, es posible que debas reinstalar la extensión "Custom CSS and JS Loader" y re-aplicar.

**P: ¿Es seguro?**
R: Todo corre local en tu máquina. El código es Open Source. Tú tienes el control.

---

*Desarrollado para la Élite de Programación.*
**v3.3 Universal Soldier**
