# 📡 Reporte de Integración: OmniControl V3.2 (Universal Soldier)

**Fecha**: 2025-12-09  
**Arquitectura**: Deep Scan + Fuzzy Logic  
**Versión**: 3.2

---

## 🚀 Novedades: "The Universal Soldier"

Esta actualización marca el cambio de una herramienta pasiva a un **Cazador Activo**.

### 1. Estrategia de Búsqueda y Destrucción (`ScanAndDestroy`)
A diferencia de la V2 que buscaba botones exactos ("Accept All"), la V3.2 implementa:
*   **Búsqueda Profunda (Deep Scan)**: Recorre todo el árbol visual de la ventana objetivo, no solo la superficie.
*   **Lógica Difusa (Fuzzy Match)**: Utiliza `IndexOf(..., StringComparison.OrdinalIgnoreCase)` para encontrar CUALQUIER botón que contenga la palabra "Accept". 
    *   *Ejemplos detectados*: "Accept All", "Please Accept", "Accept Changes", "Auto-Accept".

### 2. Auto-Lock de Ventana en Segundo Plano
*   El sistema ahora **cachea** la ventana "AntiGravity" una vez encontrada.
*   Aunque minimices o cambies de foco, OmniControl sigue "sosteniendo" el enlace a la ventana y puede pulsar botones en ella mientras trabajas en otra cosa (Background Execution).

### 3. Inyección Agresiva
*   Si la ventana tiene el foco, el script **siempre** dispara `Alt+Enter` como medida preventiva, cubriendo los milisegundos que el escáner UI tarda en procesar el árbol visual.

### 4. Métricas
*   **Hit Counter**: UI mejorada con contador visual de amenazas neutralizadas.
*   **Scan Rate Variable**: Acelera a 500ms cuando busca, descansa a 1500ms tras un éxito para ahorrar CPU.

---

## ⚠️ Protocolos de Seguridad Actualizados

Debido a la naturaleza agresiva de la V3.2:
1.  **Safety Typing**: Se mantiene estricto. Si tocas una tecla, el agente se congela instantáneamente.
2.  **Scope Limit**: Aunque escanea en profundidad, sigue limitado a ventanas que contengan "AntiGravity" en el título (o lo que configures en la variable `$TargetTitle`).

## Conclusión
OmniControl V3.2 es autónomo. Ya no espera a que le presentes el problema; lo busca en la estructura de la ventana y lo elimina.
