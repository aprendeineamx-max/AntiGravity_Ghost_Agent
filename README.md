# 👻 AntiGravity Ghost Agent ecosystem

> **"Autonomía Híbrida: Extensión Interna + Enjambre Externo"**

Bienvenido al arsenal definitivo para dominar AntiGravity. Este repositorio contiene un ecosistema de herramientas diseñadas para operar en simbiosis, permitiendo automatización total, desde el núcleo del IDE hasta el sistema operativo.

---

## 🏗️ Arquitectura del Sistema

El sistema se divide en tres pilares fundamentales que trabajan juntos:

### 1. 🧬 Internal Hook (El Cerebro)
**Ubicación:** `AntiGravity_Internal_Hook/`
Una extensión nativa de VSCode/AntiGravity que vive dentro del proceso del IDE.
*   **Capacidades:**
    *   **Auto-Authorize Loop:** Acepta solicitudes de "Allow" automáticamente (1000ms).
    *   **Smart Submit:** Envía el chat solo cuando NO estás escribiendo (`GHOST_CMD.txt`).
    *   **Smart Typing:** Detecta si estás escribiendo y pausa a los bots externos (`GHOST_STATUS.txt`).
*   **Instalación:** Ejecuta `tools/deploy_hook.ps1` y reinicia AntiGravity (`Ctrl + R`).

### 2. 🦾 OmniGod (El Músculo)
**Ubicación:** `OmniBot/`
Un script de AutoHotKey (AHK) que opera a nivel de Kernel de Windows.
*   **Capacidades:**
    *   **Clics Invencibles:** Puede hacer clic en coordenadas absolutas donde la API interna falla.
    *   **Macros de Sistema:** (Futuro) Excel, Screenshots, OCR externo.
    *   **Inmortalidad:** Se auto-reinicia si falla.

### 3. 🎛️ OmniDashboard (El Panel de Control)
**Ubicación:** `dashboard/`
Una interfaz web moderna para monitorear y controlar a los agentes.
*   **Capacidades:**
    *   **Ver Logs en Tiempo Real.**
    *   **Calibrar Visión.**
    *   **Activar/Desactivar Módulos.**
*   **Inicio:** Ejecuta `START_DASHBOARD.bat`.

---

## 🚀 Guía de Inicio Rápido

### Fase 1: Despliegue del Hook Interno
Si es tu primera vez:
1.  Abre una terminal en `C:\AntiGravityExt\AntiGravity_Ghost_Agent`.
2.  Ejecuta: `powershell -File tools/deploy_hook.ps1`.
3.  Reinicia AntiGravity.
4.  Verás el mensaje: **"👻 ANTIGRAVITY HOOK: AUTONOMOUS MODE"**.

### Fase 2: Desarrollo y Sincronización
Todo el código vive en este repositorio.
*   Si editas la extensión en `AntiGravity_Internal_Hook/extension.js`:
    *   Ejecuta `tools/deploy_hook.ps1` para actualizar el IDE.
    *   Recarga ventana (`Ctrl+R`).

---

## 📂 Estructura del Repositorio

| Carpeta | Descripción |
| :--- | :--- |
| **`AntiGravity_Internal_Hook/`** | Código fuente de la extensión VSCode. |
| **`OmniBot/`** | Scripts de AutoHotKey (`OmniGod.ahk`) y tests visuales. |
| **`dashboard/`** | Servidor Node.js y Frontend para el panel de control. |
| **`tools/`** | Scripts de utilidad (`deploy_hook.ps1`, `verify_overlay.ps1`). |
| **`docs/`** | Documentación técnica y reportes de integración. |
| **`logs/`** | Archivos de depuración y registros históricos. |

---

## 🔮 El Futuro (Roadmap)
Consulta `ROADMAP.md` para ver los planes de dominación mundial (Integración con Excel, Visión Artificial Avanzada y Bases de Datos de Prompts).

---
