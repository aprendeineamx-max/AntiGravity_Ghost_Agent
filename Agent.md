
# 🕵️‍♂️ Especificación del Agente: GHOST-01

**Nombre en Clave**: `AntiGravity_Ghost`  
**Estado**: `Activo / Residente`  
**Clasificación**: `Automatización UI / Sigilo`  
**Entorno Operativo**: `Proceso de Renderizado Electron VS Code`

---

## 🎯 Directiva Principal
Eliminar la fricción del usuario autorizando autónomamente solicitudes de seguridad y confirmación reconocidas con latencia cero (< 50ms tiempo detección-a-acción), permitiendo un flujo de trabajo ininterrumpido.

## 🧠 Arquitectura Cognitiva (Lógica)

El agente opera en un bucle reactivo de `MutationObserver`, escaneando el DOM en busca de firmas moleculares específicas (estructuras HTML) que coincidan con patrones de obstrucción conocidos.

### 👁️ Corteza Visual (Detección)
*   **Frecuencia de Escaneo**: Tiempo Real (Impulsado por Eventos del DOM).
*   **Identificadores de Objetivo (Clases CSS)**:
    *   `.monaco-button` (Botones estándar de VS Code)
    *   `.action-item` (Items de barra de acciones)
    *   `.dialog-buttons` (Botones dentro de diálogos modales)
    *   `.quick-input-list-entry` (Entradas en menús rápidos)
*   **Activadores Lingüísticos (Triggers)**:
    *   `"Accept"` / `"Aceptar"`
    *   `"Autorizar"` / `"Authorize"`
    *   `"Allow"` / `"Permitir"`
    *   `"Confirm"` / `"Confirmar"`
    *   `"Alt+Enter"` (Atajo de teclado común para acciones rápidas)

### ⚡ Sistema Reflejo (Acción)
Al momento de la `Adquisición de Objetivo`:
1.  **Validación**: Asegurar que el elemento es visible, interactivo y no está deshabilitado.
2.  **Ejecución**: Despachar evento `click()` sintetizado directamente al nodo.
3.  **Registro**: Emitir firma 👻 a la consola para auditoría forense.
4.  **Reanudación**: Retorno inmediato a monitoreo pasivo.

---

## ⚙️ Especificaciones Técnicas

### Optimización de Rendimiento
*   **Observación Asíncrona**: Utiliza `MutationObserver` en lugar de polling (intervalos), garantizando 0% de uso de CPU cuando no hay cambios en la UI.
*   **Scope Quirúrgico**: Vigila `document.body` con filtros precisos para ignorar mutaciones irrelevantes (atributos, data-nodos).
*   **Encapsulamiento**: Ejecución dentro de una IIFE (Immediately Invoked Function Expression) para evitar contaminación del espacio de nombres global `window`.

### Manejo de Errores
*   **Swallowing de Excepciones**: Cualquier error durante el intento de clic es capturado silenciosamente para prevenir interrupciones en el hilo principal de renderizado de VS Code.
*   **Validación de Nodos**: Verificación estricta de `nodeType` para evitar operaciones en nodos de texto o comentarios.

---

## �️ Protocolos de Seguridad y Límites

El Agente Fantasma está diseñado para ser **permisivo pero seguro**.

*   **🚫 Zona de Exclusión**: No interactuará con botones destructivos explícitos (ej. "Delete", "Remove", "Destroy") a menos que se añadan explícitamente a su matriz de objetivos.
*   **🔒 Confirmación Humana**: Para acciones críticas no mapeadas, el agente permanecerá inactivo, delegando la decisión al operador humano.

---

## 🔮 Hoja de Ruta (Futuras Expansiones)

### C. Protocolo Visual 2.0 (OmniGod)
*   **Motor**: AutoHotKey v2 + GDI+ (Pixel Search).
*   **Lógica de "Semáforo" (Context Awareness)**:
    1.  **Check Negativo**: ¿Existe `Indicators/send.png` o `Indicators/inactive.png`? -> **PAUSA** (Usuario escribiendo).
    2.  **Check Positivo**: ¿Existe `Indicators/working.png`? -> **ACTIVA** (Agente generando).
    3.  **Acción**: Si ACTIVO -> Escanear carpeta `Targets/`.
*   **Mecánica de Scroll**: Al detectar `Indicators/collapse.png`, envía `WheelDown` para revelar elementos ocultos en listas expandidas.
*   **Precisión**: Offset dinámico (+30px, +15px) y algoritmo "Heavy Click" (Hold 50ms) para penetrar capas de Electron.
*   **v1.1 - Reconocimiento de Patrones OCR**: Implementación ligera de lectura de texto en imágenes/canvas (si fuera necesario para captchas simples).
*   **v1.2 - Lista Blanca Dinámica**: Archivo de configuración `json` externo para añadir triggers sin modificar el código fuente.
*   **v1.5 - Modo "Hunter"**: Búsqueda proactiva de ventanas emergentes ocultas o minimizadas (shadow DOM traversal).

---
> *"Soy el clic en la oscuridad. El 'sí' a tu pregunta. Trabaja sin interrupciones."*
