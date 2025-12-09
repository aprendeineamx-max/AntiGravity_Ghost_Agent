# AntiGravity Ghost Agent 👻

Este repositorio contiene un agente de automatización ("Ghost Agent") diseñado para auto-autorizar solicitudes de permisos en VS Code de manera inmediata y silenciosa.

## Contenido
*   **ghost.js**: El script payload que vigila y hace clic automáticamente en los botones de "Accept", "Autorizar", "Allow", etc.
*   **injection_settings.json**: Configuración lista para copiar.

## Guía de Instalación Rápida

Sigue estos pasos para inyectar el agente en tu VS Code:

1.  **Instalar Extensión**:
    *   Busca e instala la extensión **"Custom CSS and JS Loader"** (ID: `be5invis.vscode-custom-css`) desde el Marketplace de VS Code.

2.  **Configurar Rutas**:
    *   Abre el archivo `injection_settings.json` incluido en esta carpeta.
    *   Copia el contenido.
    *   Abre tus ajustes de usuario en VS Code (`Ctrl + ,` -> ver como JSON icon arriba a la derecha, o busca "settings.json").
    *   Pega el contenido dentro de tu objeto de configuración.
    *   **IMPORTANTE**: Verifica que la ruta en `"vscode_custom_css.imports"` coincida con la ubicación real de `ghost.js` en tu disco.
        *   Ruta configurada: `file:///C:/AntiGravityExt/AntiGravity_Ghost_Agent/ghost.js`

3.  **Activar**:
    *   Presiona `F1` o `Ctrl+Shift+P`.
    *   Escribe y selecciona: **"Enable Custom CSS and JS"**.
    *   VS Code pedirá reiniciar. Acepta.

4.  **Permisos de Admin (Si es necesario)**:
    *   Si VS Code se queja de permisos o la extensión informa que está corrupta (es normal porque modificamos archivos core), simplemente haz clic en la rueda dentada de "Manage" en la notificación de "Code is corrupt" y elige "Don't Show Again".
    *   Si el script no carga, intenta ejecutar VS Code como Administrador una vez para aplicar los cambios.

## Verificación
Abre la consola de desarrollador (`Help` -> `Toggle Developer Tools`) y busca el mensaje:
`👻 Ghost Agent: Initialized and watching for prompts...`
