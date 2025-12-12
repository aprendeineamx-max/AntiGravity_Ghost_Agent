# 👻 AntiGravity Ghost Agent

> **Ecosistema completo de automatización para AntiGravity IDE**

Suite profesional de extensiones y herramientas de automatización con instaladores portables para despliegue rápido en cualquier VPS.

---

## ✨ Características Principales

### 🔧 Chat Export System (v3)
**Exportación profesional de conversaciones con búsqueda indexada**

- ✅ Exportación estructurada en Markdown
- ✅ Search Index (archivos + keywords)
- ✅ Analytics Dashboard integrado
- ✅ Monitoreo automático vía clipboard
- ✅ **Instalador portable incluido**

[📁 Ver extensión](AntiGravity_Chat_Exporter/)

### 🎯 Internal Hook Extension
**Automatización nativa completamente autónoma**

- ✅ Auto-click en acciones del agente (cada 1s)
- ✅ Auto-click en "Always Allow" (cada 500ms)
- ✅ Auto-click en "Accept all" (cada 500ms)
- ✅ Detección inteligente de escritura
- ✅ Smart Submit condicional
- ✅ **Instalador portable incluido**

[📁 Ver extensión](AntiGravity_Internal_Hook/)

### 🤖 Automation Bots
**Suite de bots externos para automatización avanzada**

- **OmniGod**: Automation bot con AHK
- **OmniControl**: Control de sistema
- **Dashboard**: Panel de monitoreo web

[📁 Ver bots](Bots/)

---

## 🚀 Instalación Rápida

### Chat Exporter

```bash
# 1. Ir a la carpeta del instalador
cd AntiGravity_Chat_Exporter/Portable_Installer_Chat_Exporter/

# 2. Ejecutar instalador
INSTALL.bat

# 3. Reiniciar AntiGravity
# ✅ Listo!
```

**Comandos disponibles** (Ctrl+Shift+P):
- `Configure Chat Exporter`
- `Force Chat Export`
- `Start Auto Export Monitor`

---

### Internal Hook

```bash
# 1. Ir a la carpeta del instalador
cd AntiGravity_Internal_Hook/Portable_Installer_Internal_Hook/

# 2. Ejecutar instalador
INSTALL.bat

# 3. Reiniciar AntiGravity
# ✅ Auto-click activado!
```

**Características automáticas**:
- ✅ Auto-activa al iniciar AntiGravity
- ✅ Clicks automáticos sin configuración
- ✅ Crea carpetas necesarias automáticamente

---

## 📁 Estructura del Repositorio

```
AntiGravity_Ghost_Agent/
├── AntiGravity_Chat_Exporter/          # Extensión de exportación
│   ├── extension.js
│   ├── package.json
│   └── Portable_Installer_Chat_Exporter/  # 📦 Instalador portable
│       ├── INSTALL.bat
│       ├── README.txt
│       ├── extension/
│       └── scripts/
│
├── AntiGravity_Internal_Hook/          # Extensión de automatización
│   ├── extension.js
│   ├── package.json
│   └── Portable_Installer_Internal_Hook/  # 📦 Instalador portable
│       ├── INSTALL.bat
│       ├── DIAGNOSTICS.bat
│       ├── README.txt
│       └── extension/
│
├── Bots/                               # Bots externos
│   ├── OmniGod/                        # Bot principal AHK
│   └── OmniControl/                    # Control de sistema
│
├── System/                             # Herramientas del sistema
│   └── tools/                          # Scripts de utilidad
│
├── Exports/                            # Carpeta de exportaciones
│   └── Scripts/                        # Scripts de exportación
│
├── dashboard/                          # Panel web de monitoreo
│
├── _Archive/                           # Archivos archivados
│   ├── logs/
│   └── tests/
│
├── README.md                           # Este archivo
└── ROADMAP.md                          # Roadmap del proyecto
```

---

## 🛠️ Características de los Instaladores Portables

### Auto-Detección
- ✅ Detecta AntiGravity automáticamente (3 métodos)
- ✅ Maneja rutas personalizadas
- ✅ Verifica instalación de AntiGravity

### Instalación Dual-Path
- ✅ Built-in extensions (funciona inmediatamente)
- ✅ User extensions (sobrevive updates)
- ✅ Redundancia para máxima compatibilidad

### Sistema de Backup
- ✅ Backup automático antes de sobrescribir
- ✅ Rollback manual disponible
- ✅ Preserva versiones anteriores

### Configuración Zero
- ✅ Crea carpetas necesarias automáticamente
- ✅ Verifica permisos de escritura
- ✅ Configuración predeterminada óptima

---

## 📊 Chat Export Features

### Formatos de Exportación

**Markdown Estructurado**:
- Numeración secuencial de mensajes
- Metadata por mensaje (From, Time, Type)
- Preservación de code blocks
- Clean separators

**Search Index**:
- Index de archivos mencionados
- Top keywords con referencias
- Enlaces directos a mensajes

**Analytics Dashboard**:
- Total de mensajes
- Conteo user/agent
- Code snippets
- Estadísticas de volume

### Export Scripts Incluidos

**export_v3.ps1** - Exporter refinado
- Search index automático
- Analytics dashboard
- Collapsible long messages
- File linking

**export_now.ps1** - One-shot export
- Exportación rápida desde clipboard
- Formato profesional
- Auto-apertura del resultado

**test_exporter.ps1** - Self-test
- Validación automática
- Verificación de parseo
- Tests de exportación

---

## 🤖 Internal Hook Features

### Auto-Click Loops

**Loop 1: Agent Steps** (1000ms)
```javascript
antigravity.agent.acceptAgentStep
```

**Loop 2: Always Allow** (500ms)
```javascript
antigravity.agent.alwaysAllow
```

**Loop 3: Accept All** (500ms)
```javascript
antigravity.agent.acceptAll
```

### Smart Features

**Typing Detection**:
- Detecta cuando estás escribiendo
- Pausa auto-submit durante escritura
- Resume automáticamente al terminar

**Status Tracking**:
- `HOOK_ALIVE.txt` - Proof of activation
- `GHOST_STATUS.txt` - TYPING / IDLE
- `GHOST_CMD.txt` - Command queue

---

## 🔧 Desarrollo

### Requisitos

- **Windows 10/11**
- **AntiGravity IDE** instalado
- **PowerShell 5.1+** (para scripts)
- **Node.js** (para dashboard)
- **AutoHotkey v2** (para bots)

### Estructura de Desarrollo

**Extensiones** (VSCode/AntiGravity):
- Lenguaje: JavaScript (Node.js)
- API: VSCode Extension API
- Activación: Automática

**Scripts** (PowerShell):
- Lenguaje: PowerShell 5.1+
- Compatibilidad: Windows nativo
- Ejecución: Manual o auto

**Bots** (AutoHotkey):
- Lenguaje: AHK v2
- Nivel: Kernel de Windows
- Modo: Background service

---

## 📝 Documentación

### Guías Incluidas

- **[ROADMAP.md](ROADMAP.md)** - Plan de desarrollo
- **[Portable Installer README](AntiGravity_Chat_Exporter/Portable_Installer_Chat_Exporter/README.txt)** - Guía de instalación Chat Exporter
- **[Internal Hook README](AntiGravity_Internal_Hook/Portable_Installer_Internal_Hook/README.txt)** - Guía de instalación Internal Hook
- **[DIAGNOSTICS.bat](AntiGravity_Internal_Hook/Portable_Installer_Internal_Hook/DIAGNOSTICS.bat)** - Herramienta de diagnóstico

### Troubleshooting

**Internal Hook no se activa**:
1. Ejecutar `DIAGNOSTICS.bat`
2. Verificar `C:\AntiGravityExt\HOOK_ALIVE.txt` existe
3. Revisar Developer Tools Console

**Chat Export no funciona**:
1. Verificar export directory existe
2. Comprobar modo de auto-export
3. Revisar extension output channel

---

## 🎯 Casos de Uso

### Desarrollo Asistido por IA
- Auto-acepta acciones del agente
- Auto-click en permisos
- Workflow completamente autónomo

### Documentación de Conversaciones
- Exportación profesional de chats
- Search y análisis de conversaciones
- Archivo histórico organizado

### Automatización de Tareas
- Bots externos para tareas complejas
- Dashboard de monitoreo
- Control centralizado

---

## 🔄 Actualizaciones

### Versión 1.1 (Actual)

**Internal Hook**:
- ✅ Auto-click "Always Allow"
- ✅ Auto-click "Accept all"
- ✅ Creación automática de carpetas

**Chat Exporter**:
- ✅ Export v3 con search index
- ✅ Analy tics dashboard
- ✅ Portable installer

**Organización**:
- ✅ Archivos sueltos organizados
- ✅ Structure limpia
- ✅ README actualizado

---

## 📞 Soporte

**Para problemas de instalación**:
1. Ejecutar `DIAGNOSTICS.bat` (Internal Hook)
2. Revisar README.txt del instalador
3. Verificar permisos de administrador

**Para errores de ejecución**:
1. Abrir Developer Tools (Help → Toggle Developer Tools)
2. Revisar Console tab
3. Buscar errores relacionados con la extensión

---

## 📜 Licencia

**UNLICENSED** - Uso interno

---

## 🚀 Próximos Pasos

Ver [ROADMAP.md](ROADMAP.md) para planes futuros:
- Fase 2: JSON + Arquitectura Modular
- Fase 3: Inteligencia Avanzada
- Fase 4: UI Reader Profesional

---

**Última actualización**: 2025-12-12  
**Versión**: 1.1
