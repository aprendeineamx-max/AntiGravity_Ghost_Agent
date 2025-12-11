# 🗺️ ANTI-GRAVITY ROADMAP: The Future of Automation

> **Objetivo:** Trascender la automatización del IDE y conectar el Agente Fantasma con el mundo exterior (Excel, Web, Bases de Datos).

---

## ✅ Fase 1 & 2: Cimientos Sólidos (COMPLETADO)
*   [x] **Internal Hook:** Inyección directa en el IDE.
*   [x] **Auto-Authorize:** Clics nativos sin fallos.
*   [x] **Smart Typing:** Detección de actividad del usuario.
*   [x] **Hybrid Bridge:** Archivos `GHOST_CMD` y `GHOST_STATUS` para comunicación externa.

---

## 📅 Fase 3: Integración de Datos (Excel Macro Bridge)
**Objetivo:** Permitir que el Agente del IDE "lea" y "escriba" en hojas de cálculo externas usando los bots antiguos (ahora reciclados como Macros).

*   [ ] **Excel Reader Bot (Python/AHK):**
    *   Script que vigila un archivo `.xlsx`.
    *   Extrae contenido de celdas específicas (Ej: Columna "Prompt").
    *   Escribe el contenido en `GHOST_INPUT.txt`.
    *   **Internal Hook Upgrade:** Leer `GHOST_INPUT.txt` y pegarlo en el chat del IDE.
*   [ ] **Excel Writer Bot:**
    *   Internal Hook extrae la respuesta del Agente (vía scraping del DOM del webview o comando interno).
    *   Escribe la respuesta en `GHOST_OUTPUT.txt`.
    *   Macro Bot pega la respuesta en Excel (Columna "Respuesta").

---

## 👁️ Fase 4: Visión Avanzada (Screenshot Loop)
**Objetivo:** Darle "Ojos" al Agente para que vea (literalmente) lo que pasa en tu pantalla/navegador.

*   [ ] **Snapshot Protocol:**
    *   Internal Hook comando: `antigravity.screenshot.take`.
    *   O Macro externo (`Win + Shift + S` automatizado de un área específica).
*   [ ] **Vision Pipeline:**
    *   Enviar la captura a una API de visión (o al mismo Agente si soporta multimodo).
    *   El Agente analiza la imagen y decide si la tarea (ej: "Cambiar botón a rojo") se cumplió.

---

## 🧠 Fase 5: La Colmena (Database AI Hivemind)
**Objetivo:** Automatización Masiva Desatendida.

*   [ ] **DB Connector:**
    *   Bot Servidor que conecta SQLite/Postgres.
    *   Tabla `Queue_Prompts`.
*   [ ] **Prompt Swarm:**
    *   El Agente saca un prompt de la BD.
    *   Lo ejecuta en el IDE.
    *   Guarda la respuesta en la BD.
    *   Repite infinitamente (24/7).
*   [ ] **Human-in-the-Loop Dashboard:**
    *   Panel web para ver el progreso de miles de prompts procesados.

---

## 🛠️ Mantenimiento Continuo
*   Refactorización regular de `OmniGod.ahk` para mantenerlo ligero.
*   Actualizaciones de la API Interna (`Hooks`) conforme AntiGravity evolucione.

*Powered by AntiGravity Ghost Architecture*
