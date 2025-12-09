# 📡 Reporte de Integración: OmniControl + Ghost Agent

**Fecha**: 2025-12-09  
**Asunto**: Fusión de Sistemas y Roadmap Técnico

---

## 1. Análisis de Convergencia
Hemos identificado dos vectores de automatización complementarios en el ecosistema AntiGravity:

### A. Vector Interno (Ghost Agent)
*   **Tecnología**: JavaScript / DOM MutationObserver.
*   **Ámbito**: Dentro de VS Code (Renderer).
*   **Fortaleza**: Precisión quirúrgica, silencioso, opera en segundo plano (si la ventana no está minimizada agresivamente).
*   **Debilidad**: Ciego a ventanas fuera del DOM de VS Code (ej. alertas nativas del OS, diálogos de confirmación de administrador).

### B. Vector Externo (OmniControl HUD)
*   **Tecnología**: PowerShell / Win32 API / SendKeys.
*   **Ámbito**: Sistema Operativo (Global Windows).
*   **Fortaleza**: Fuerza bruta universa, capaz de cerrar ventanas nativas y actuar como "Capa de Seguridad" final.
*   **Debilidad**: Requiere foco (Foreground), menos elegante, riesgo de interferencia si el usuario escribe.

---

## 2. Estrategia de Fusión: "The Double Helix"

La solución propuesta no es elegir uno, sino utilizar ambos en tándem para una **cobertura del 100%**.

*   **Capa 1 (Fantasma)**: El `ghost.js` maneja el 90% de las interacciones diarias dentro del editor. Es la primera línea de defensa.
*   **Capa 2 (OmniOverwatch)**: `OmniControl_HUD.ps1` corre flotando en un monitor secundario o en la esquina. Monitoriza "Fugas" que el Ghost Agent no pudo capturar (ej. crashes, ventanas de error de sistema, o cuando VS Code roba el foco inesperadamente).

### Implementación Realizada (v2.0)
Se ha remasterizado `OmniControl` para incluir:
1.  **Multi-Targeting**: Ahora acepta una lista de objetivos, no solo "AntiGravity".
2.  **Visual Logger**: Historial de eventos en tiempo real para verificar qué sistema actuó.
3.  **Safety Typing**: Detecta si el usuario está escribiendo para NO disparar teclas y arruinar el trabajo.

---

## 3. Roadmap Funcional (Futuro)

### Fase 1: Consolidación (Actual)
*   [x] Inyección de Ghost Agent (JS).
*   [x] Despliegue de OmniControl v2.0 (PS1).

### Fase 2: Intercomunicación (Q1 2026)
*   **File-System Bridge**: Que `ghost.js` escriba en un archivo `heartbeat.log` y que `OmniControl` lo lea. Si `ghost.js` deja de reportar, OmniControl reinicia VS Code automáticamente (Self-Healing).

### Fase 3: AI Vision (Q2 2026)
*   Reemplazar la búsqueda de texto por **Computer Vision** (screenshot análisis) en OmniControl.
*   Capacidad de detectar ventanas "sin título" basándose en la forma de los botones.

### Fase 4: Modo Servicio (Q3 2026)
*   Convertir OmniControl en un Servicio de Windows silencioso (sin GUI) que solo notifica vía Toast Notification cuando actúa.

---

## 🏁 Conclusión
La combinación de **Ghost Agent** (In-Process) y **OmniControl** (Out-Process) crea un entorno blindado. El código remasterizado ya está en `tools/OmniControl_HUD.ps1`.
