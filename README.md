# WebEventId - Generador de Aplicación Web para Eventos de Windows

![Version](https://img.shields.io/badge/version-2.0-blue.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.0+-green.svg)
![License](https://img.shields.io/badge/license-MIT-orange.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)

**WebEventId** es una herramienta completa de PowerShell que extrae todos los eventos de Windows del sistema y genera una aplicación web moderna para explorar, buscar y analizar Event IDs, proveedores y descripciones con validaciones robustas y manejo de errores avanzado.

## 🚀 Características

### **🔧 Generación Automática Robusta**
- **Extracción completa** de eventos usando `Get-WinEvent -ListProvider *`
- **Validaciones de sistema** automáticas (PowerShell, permisos, espacio en disco)
- **Manejo robusto de errores** con try-catch en operaciones críticas
- **Contadores de éxito/error** por proveedor procesado
- **Archivos de error específicos** para troubleshooting (ERROR_*.txt)

### **🎨 Interfaz Web Moderna v2.0**
- **Diseño responsive optimizado** para móvil, tablet y escritorio
- **Modo oscuro/claro** con persistencia local
- **UI mejorada en PC**: Filtros en línea con checkbox de búsqueda exacta
- **Búsqueda avanzada colapsable** en pantallas pequeñas (≤440px)
- **Animaciones suaves** y transiciones fluidas

### **🔍 Búsqueda Avanzada e Inteligente**
- **Búsqueda en tiempo real** mientras escribes
- **Autocompletado inteligente** de nombres de proveedores
- **Búsqueda exacta de ID** para eventos específicos
- **Filtros combinables** por nivel y proveedor en línea
- **Navegación por teclado** (flechas, Enter, ESC)

### **🛡️ Validaciones y Robustez**
- **Validación de parámetros** (puerto 1024-65535, caracteres válidos)
- **Verificación de prerrequisitos** (PowerShell v5+, acceso a eventos, espacio)
- **Auto-lanzamiento inteligente** con validación de puerto y servidor
- **Manejo de campos nulos** y proveedores sin eventos
- **Rutas absolutas seguras** para evitar problemas de navegación

## 📋 Requisitos

- **Windows** 10/11 o Windows Server 2016+
- **PowerShell** 5.0 o superior
- **100MB de espacio libre** en disco
- **Permisos de administrador** (recomendado para acceso completo a eventos)
- **Navegador web moderno** (Chrome, Firefox, Edge)

## 🛠️ Instalación y Uso

### Uso Básico

```powershell
# Clona el repositorio
git clone https://github.com/rsessa/WebEventId.git
cd WebEventId

# Ejecuta el script con configuración predeterminada (ahora en la raíz)
.\crear-todo.ps1
```

### Opciones Avanzadas

```powershell
# Puerto personalizado y auto-abrir navegador
.\crear-todo.ps1 -Port 8081 -AutoOpen

# Carpetas personalizadas
.\crear-todo.ps1 -WebPath ".\mi-web" -OutputPath ".\datos"

# Configuración completa
.\crear-todo.ps1 -Port 9000 -AutoOpen -WebPath ".\aplicacion-web" -OutputPath ".\eventos-windows"
```

### Parámetros y Validaciones

| Parámetro | Tipo | Default | Validación | Descripción |
|-----------|------|---------|------------|-------------|
| `-Port` | `[int]` | `8080` | 1024-65535 | Puerto para el servidor web |
| `-AutoOpen` | `[switch]` | `false` | - | Auto-lanza navegador y servidor con validaciones |
| `-OutputPath` | `[string]` | `".\[SO]\eventos"` | Sin caracteres especiales | Carpeta para archivos de texto por proveedor |
| `-WebPath` | `[string]` | `".\[SO]\web"` | Sin caracteres especiales | Carpeta para la aplicación web |

### Validaciones Automáticas del Sistema

El script valida automáticamente:
- ✅ **PowerShell v5.0+** requerido
- ✅ **Puerto disponible** (detecta puertos en uso)
- ✅ **Espacio en disco** (mínimo 100MB)
- ✅ **Acceso a eventos** de Windows
- ✅ **Caracteres válidos** en rutas
- ✅ **Archivos críticos** antes del auto-lanzamiento

## 📁 Estructura de Archivos Generados (Organizados por SO)

```
WebEventId/
├── crear-todo.ps1                      # Script principal (movido a la raíz)
├── [Sistema-Build]/                    # Carpeta específica del SO detectado
│   ├── eventos/                        # Archivos por proveedor (organizados por SO)
│   │   ├── Microsoft-Windows-Kernel-General.txt
│   ├── Application.txt
│   └── ...
└── web/                        # Aplicación web (configurable)
    ├── index.html              # Interfaz web principal
    ├── events-data.json        # Base de datos de eventos
    └── start-server.ps1        # Servidor web
```

## 🌐 Aplicación Web

### Características de la Interfaz v2.0

- **🔍 Búsqueda Inteligente en Tiempo Real**: 
  - Búsqueda por Event ID (exacta o parcial)
  - Búsqueda por nombre de proveedor con autocompletado
  - Búsqueda en descripciones y palabras clave
  - Resultados instantáneos mientras escribes

- **🎨 UI Mejorada para PC y Móvil**:
  - **PC**: Filtros en línea (checkbox + selectores de nivel y proveedor)
  - **Móvil**: Búsqueda avanzada colapsable automática (≤440px)
  - Modo oscuro/claro conmutable con persistencia
  - Diseño responsive optimizado para todos los dispositivos
  - Cards organizadas en grid con animaciones suaves

- **📊 Estadísticas en Tiempo Real**:
  - Total de eventos procesados con contadores de éxito/error
  - Número de proveedores disponibles
  - Contador de resultados de búsqueda filtrados

- **🔧 Filtros Avanzados en Línea**:
  - Checkbox de búsqueda exacta de Event ID
  - Selector de nivel (Information, Warning, Error, Critical, Verbose)
  - Selector de proveedor específico
  - Todos los filtros combinables en tiempo real

### Navegación y Usabilidad Mejorada

- **� Optimización para PC**: 
  - Controles agrupados en línea para mejor aprovechamiento del espacio
  - Labels descriptivos ("Nivel:", "Proveedor:")
  - Interfaz más compacta y profesional

- **📱 Experiencia Móvil Superior**:
  - Búsqueda avanzada se colapsa automáticamente en pantallas ≤440px
  - Botón toggle intuitivo ("🔍 Búsqueda Avanzada")
  - Touch-friendly con elementos de tamaño adecuado (min 44px)
  - Filtros reorganizados verticalmente para mejor usabilidad

- **⌨️ Controles de Teclado Completos**:
  - Navegación con flechas ↑↓ en autocompletado
  - Enter para confirmar selecciones
  - ESC para cerrar dropdowns
  - Tab para navegación accesible

- **� Interacción Intuitiva**:
  - Feedback visual inmediato en todas las acciones
  - Estados hover y focus claramente definidos
  - Transiciones suaves entre estados
  - Indicadores de carga y progreso

### Iniciar la Aplicación Web

```powershell
# Navegar a la carpeta web
cd web

# Iniciar el servidor
.\start-server.ps1

# O con puerto personalizado
.\start-server.ps1 -Port 8081
```

Luego abre tu navegador en: `http://localhost:8080`

## 🔧 Funcionalidades del Script v2.0

### Proceso de Extracción Robusto

1. **Validaciones de Sistema**: Verifica PowerShell v5+, permisos, espacio en disco
2. **Descubrimiento Seguro**: Utiliza `Get-WinEvent -ListProvider *` con manejo de errores
3. **Extracción Inteligente**: Procesa eventos con validación de campos nulos
4. **Contadores de Rendimiento**: Rastrea proveedores exitosos vs errores
5. **Generación de Reportes**: Crea archivos ERROR_*.txt para troubleshooting
6. **Validación de Datos**: Verifica integridad antes de generar JSON
7. **Auto-lanzamiento Inteligente**: Valida servidor antes de abrir navegador

### Datos Extraídos con Validación

Para cada evento, el script extrae y valida:
- **Event ID**: Identificador único del evento
- **Proveedor**: Nombre del proveedor de eventos (con fallback)
- **Versión**: Versión del evento (manejo de nulos)
- **Nivel**: Information, Warning, Error, Critical, Verbose (con default)
- **Palabras Clave**: Keywords asociadas (join seguro)
- **Descripción**: Descripción detallada (con fallback "Sin descripción disponible")
- **Log Links**: Enlaces a logs asociados (manejo de arrays vacíos)

### Manejo de Errores Avanzado

- **Try-catch en operaciones críticas** (creación de directorios, JSON, HTML)
- **Validación de archivos** antes del auto-lanzamiento
- **Detección de puertos en uso** con puerto alternativo automático
- **Verificación del servidor** con reintentos antes de abrir navegador
- **Archivos de error específicos** para cada proveedor problemático
- **Estadísticas de procesamiento** (éxito/error) en tiempo real
3. **Generación de Archivos**: Crea archivos de texto individuales por proveedor
4. **Base de Datos JSON**: Genera un archivo JSON con todos los datos para la web
5. **Interfaz Web**: Crea una aplicación web completa
6. **Servidor HTTP**: Genera un servidor web con soporte CORS

### Datos Extraídos

Para cada evento, el script extrae:
- **Event ID**: Identificador único del evento
- **Proveedor**: Nombre del proveedor de eventos
- **Versión**: Versión del evento
- **Nivel**: Information, Warning, Error, Critical, Verbose
- **Palabras Clave**: Keywords asociadas al evento
- **Descripción**: Descripción detallada del evento
- **Log Links**: Enlaces a logs asociados

## 🚀 Características Técnicas v2.0

### Servidor Web Robusto
- **HTTP Server**: Basado en `System.Net.HttpListener` con manejo de errores
- **CORS**: Habilitado para desarrollo con headers completos
- **Content-Type**: Detección automática para HTML, JSON, JS, CSS
- **Error Handling**: Manejo robusto de errores 404, 500 con logging
- **UTF-8**: Soporte completo para caracteres especiales
- **Port Validation**: Detecta puertos en uso y sugiere alternativas

### Aplicación Web Avanzada
- **Vanilla JavaScript**: Sin dependencias externas, carga rápida
- **Local Storage**: Persistencia de preferencias de tema
- **Progressive Enhancement**: Funciona sin JavaScript (búsqueda básica)
- **Mobile First**: Diseño responsive desde 320px hasta 4K
- **Accessibility**: Navegación por teclado y lectores de pantalla
- **Touch Optimized**: Elementos táctiles de tamaño adecuado (44px mínimo)
- **CSS Variables**: Theming avanzado con modo oscuro/claro
- **Grid Layout**: Diseño flexible con auto-fit y minmax

### Validaciones y Robustez
- **System Requirements**: Validación automática de prerrequisitos
- **Parameter Validation**: Verificación de rangos y caracteres válidos
- **File System**: Rutas absolutas seguras y creación robusta de directorios
- **Error Recovery**: Manejo graceful de errores con mensajes informativos
- **Progress Tracking**: Contadores de éxito/error en tiempo real

## 🐛 Solución de Problemas Avanzada

### Error: "No se pueden cargar los datos"

**Causa**: Archivo JSON no accesible por políticas CORS del navegador.

**Solución Automática**: El script detecta este problema y muestra instrucciones específicas.

```powershell
# El script te guiará automáticamente:
cd "ruta-web-mostrada"
.\start-server.ps1
# Abrir: http://localhost:puerto-mostrado
```

### Error: "Puerto debe estar entre 1024 y 65535"

**Causa**: Puerto fuera del rango válido.

**Solución**: El script valida automáticamente y muestra el error.

```powershell
# Puerto válido
.\crear-todo.ps1 -Port 8080  # ✅ Válido
.\crear-todo.ps1 -Port 80    # ❌ Requiere privilegios admin
```

### Error: "Puerto ya está en uso"

**Causa**: El puerto especificado está ocupado.

**Solución**: El script detecta automáticamente y sugiere puerto alternativo.

```powershell
# El script automáticamente:
# 1. Detecta puerto en uso
# 2. Incrementa el puerto (+1)
# 3. Informa el nuevo puerto
```

### Error: "Acceso denegado a eventos"

**Causa**: Permisos insuficientes para acceder a proveedores de eventos.

**Solución**: El script muestra estadísticas de errores y sugerencias.

```powershell
# El script muestra:
# • Proveedores exitosos: X
# • Proveedores con errores: Y
# • Archivos ERROR_*.txt generados para troubleshooting

# Para acceso completo:
# Ejecuta PowerShell como Administrador
```

### Archivos de Error y Troubleshooting

El script genera automáticamente:
- **ERROR_NombreProveedor.txt**: Detalles específicos del error
- **Estadísticas de procesamiento**: Contadores de éxito/fallo
- **Advertencias contextuales**: Sugerencias específicas para cada problema

```powershell
# Revisar errores específicos
cd eventos
Get-ChildItem ERROR_*.txt | ForEach-Object { 
    Write-Host "Error en: $($_.BaseName)" 
    Get-Content $_.FullName 
}
```

## 📈 Rendimiento y Estadísticas

### Métricas de Procesamiento
- **Tiempo de Extracción**: ~2-5 minutos (dependiendo del sistema y permisos)
- **Eventos Típicos**: 15,000-50,000 eventos (varía por sistema)
- **Proveedores Típicos**: 200-800 proveedores
- **Tasa de Éxito**: >95% en sistemas con permisos de administrador
- **Tamaño JSON**: 5-20 MB (optimizado para carga web)
- **Tiempo de Carga Web**: <2 segundos para 50,000 eventos

### Optimizaciones Implementadas
- **Procesamiento en lotes** con progress tracking
- **Validación temprana** de datos para evitar errores tardíos
- **Manejo eficiente de memoria** durante la extracción
- **Compresión de datos** en el JSON de salida
- **Lazy loading** de resultados (muestra primeros 100)

### Estadísticas en Tiempo Real
El script muestra automáticamente:
```
✓ Procesamiento completado:
  • Proveedores exitosos: 756
  • Proveedores con errores: 12
  • Total eventos extraídos: 45,230
```

## 🔄 Novedades en v2.0

### 🛡️ Robustez y Validaciones
- ✅ **Validación completa de parámetros** antes de ejecutar
- ✅ **Verificación de prerrequisitos del sistema** automática
- ✅ **Manejo robusto de errores** con try-catch en operaciones críticas
- ✅ **Archivos de error específicos** para troubleshooting avanzado
- ✅ **Contadores de éxito/error** por proveedor

### 🎨 Mejoras de UI/UX
- ✅ **Filtros en línea en PC** (checkbox + selectores nivel/proveedor)
- ✅ **Búsqueda avanzada colapsable** en móviles (≤440px)
- ✅ **Responsive design mejorado** con breakpoints optimizados
- ✅ **Mejor aprovechamiento del espacio** horizontal en pantallas grandes
- ✅ **Touch-friendly** con elementos de tamaño adecuado (44px mínimo)

### ⚡ Auto-lanzamiento Inteligente
- ✅ **Validación de archivos críticos** antes del lanzamiento
- ✅ **Detección automática de puertos en uso** con alternativas
- ✅ **Verificación del servidor** con reintentos antes de abrir navegador
- ✅ **Feedback detallado** del estado del servidor y URL
- **Tamaño JSON**: 5-20 MB
- **Tiempo de Carga Web**: <2 segundos para 50,000 eventos

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Haz fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Añade nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📝 Casos de Uso

- **Administradores de Sistema**: Explorar Event IDs para troubleshooting y diagnóstico
- **Desarrolladores**: Encontrar códigos de evento específicos para aplicaciones
- **Auditores de Seguridad**: Revisar eventos de seguridad disponibles y sus descripciones
- **Estudiantes de IT**: Aprender sobre el sistema de eventos de Windows
- **Técnicos de Soporte**: Buscar rápidamente información detallada de eventos
- **Documentación**: Crear referencias completas de Event IDs con descripciones
- **Investigación Forense**: Analizar tipos de eventos disponibles para investigaciones
- **Monitoreo de Sistemas**: Identificar eventos relevantes para alertas y dashboards

## 🔄 Actualizaciones

Para actualizar los datos:

```powershell
# Re-ejecuta el script para obtener nuevos eventos
.\crear-todo.ps1

# Los datos se actualizarán automáticamente
```

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/rsessa/WebEventId/issues)
- **Wiki**: [Documentación completa](https://github.com/rsessa/WebEventId/wiki)

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

## 🙏 Reconocimientos

- Comunidad de PowerShell por las mejores prácticas
- Microsoft por la documentación de Event Logs
- Usuarios que han proporcionado feedback y sugerencias

---

**¿Te gusta este proyecto?** ⭐ ¡Dale una estrella en GitHub!

**¿Encontraste un bug?** 🐛 [Reporta un issue](https://github.com/rsessa/WebEventId/issues/new)

