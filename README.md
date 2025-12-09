# 👻 AntiGravity Ghost Agent

> **Resident Automation Agent for VS Code**  
> *Una herramienta de automatización silenciosa y de alto rendimiento para el auto-aceptado de permisos.*

## 📋 Descripción General

**AntiGravity Ghost Agent** es un script inyectado en el proceso de renderizado de VS Code (Electron) diseñado para eliminar la fricción de las interacciones repetitivas. 

Utilizando un `MutationObserver` optimizado, el agente monitorea el DOM en tiempo real y detecta ventanas modales, notificaciones y diálogos de confirmación específicos (como solicitudes de permisos o confirmaciones de "Alt+Enter"). Al interceptar estos elementos, el agente los autoriza automáticamente en menos de **1 segundo**, sin robar el foco del teclado ni del mouse.

### 🚀 Características Principales

*   **⚡ Latencia Cero**: Reacción inmediata ante la aparición de diálogos.
*   **🤫 Modo Silencioso**: No emite sonidos ni altera el foco de la ventana activa.
*   **🛡️ Robustez**: Lógica encapsulada y manejo de errores para evitar fugas de memoria.
*   **🔍 Detección Inteligente**: Filtrado insensible a mayúsculas/minúsculas para palabras clave como "Accept", "Autorizar", "Allow", "Confirm".

---

## 🛠️ Instalación

Este agente requiere la inyección de código JavaScript personalizado en VS Code.

### Prerrequisitos

1.  **VS Code Extension**: Instala [Custom CSS and JS Loader](https://marketplace.visualstudio.com/items?itemName=be5invis.vscode-custom-css).

### Pasos

1.  **Ubicación del Archivo**:
    Asegúrate de que este repositorio esté clonado en una ubicación estable.
    *   Ruta actual del script: `C:\AntiGravityExt\AntiGravity_Ghost_Agent\ghost.js`

2.  **Configurar VS Code**:
    Abre tu archivo `settings.json` de usuario y agrega la siguiente configuración:

    ```json
    "vscode_custom_css.imports": [
        "file:///C:/AntiGravityExt/AntiGravity_Ghost_Agent/ghost.js"
    ],
    "vscode_custom_css.policy": true
    ```

3.  **Activar el Agente**:
    *   Abre la Paleta de Comandos (`Ctrl+Shift+P`).
    *   Ejecuta: `> Enable Custom CSS and JS`.
    *   Reinicia VS Code cuando se te solicite.

    > **Nota**: Si recibes una advertencia de que "VS Code está corrupto", es normal debido a la modificación de archivos internos. Puedes ocultar la notificación permanentemente haciendo clic en el engranaje "Manage" -> "Don't Show Again".

---

## 🔍 Verificación

Para verificar que el agente está activo:

1.  Abre las Herramientas de Desarrollador en VS Code (`Help` -> `Toggle Developer Tools`).
2.  Ve a la pestaña **Console**.
3.  Deberías ver el mensaje de inicio:
    > `👻 Ghost Agent: Initialized and watching for prompts...`

---

## 🧩 Estructura del Proyecto

*   `ghost.js`: **Payload Principal**. Contiene la lógica del `MutationObserver` y la ejecución de clics.
*   `injection_settings.json`: Fragmento de configuración de referencia.
*   `README.md`: Esta documentación.

## ⚠️ Exención de Responsabilidad

Esta herramienta modifica el funcionamiento interno de VS Code. Úsala bajo tu propia responsabilidad. Diseñada para entornos de desarrollo controlados "AntiGravity".
