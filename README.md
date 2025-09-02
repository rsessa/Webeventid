# WebEventId - Generador de Aplicación Web para Eventos de Windows

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Windows](https://img.shields.io/badge/platform-Windows-lightgrey.svg)

Una herramienta completa de PowerShell que extrae todos los eventos de Windows del sistema y genera una aplicación web moderna para explorar, buscar y analizar Event IDs, proveedores y descripciones.

## 🚀 Características

- **Extracción Completa**: Obtiene todos los proveedores de eventos de Windows y sus Event IDs
- **Aplicación Web Moderna**: Interfaz responsive con modo oscuro/claro
- **Búsqueda Avanzada**: Búsqueda por ID exacto, proveedor, descripción o palabras clave
- **Modal de Detalles**: Tarjetas clicables que abren ventanas modales con información completa
- **Servidor Web Integrado**: Servidor HTTP con soporte CORS incluido
- **Filtros Inteligentes**: Filtrado por nivel de evento y proveedor
- **Autocompletado**: Sugerencias automáticas de proveedores
- **Responsive Design**: Optimizada para móviles y tablets
- **Datos Estructurados**: Genera archivos de texto por proveedor y JSON para la web

## 📋 Requisitos

- Windows 10/11 o Windows Server 2016+
- PowerShell 5.1 o superior
- Permisos de administrador (recomendado para acceso completo a eventos)

## 🛠️ Instalación y Uso

### Uso Básico

```powershell
# Clona el repositorio
git clone https://github.com/rsessa/WebEventId.git
cd WebEventId\mi-app-powershell

# Ejecuta el script con configuración predeterminada
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

### Parámetros

| Parámetro | Tipo | Predeterminado | Descripción |
|-----------|------|----------------|-------------|
| `-Port` | int | 8080 | Puerto para el servidor web |
| `-AutoOpen` | switch | false | Abre automáticamente el navegador |
| `-OutputPath` | string | ".\eventos" | Carpeta para archivos de texto por proveedor |
| `-WebPath` | string | ".\web" | Carpeta para la aplicación web |

## 📁 Estructura de Archivos Generados

```
WebEventId/
├── mi-app-powershell/
│   └── crear-todo.ps1          # Script principal
├── eventos/                    # Archivos por proveedor (configurable)
│   ├── Microsoft-Windows-Kernel-General.txt
│   ├── Application.txt
│   └── ...
└── web/                        # Aplicación web (configurable)
    ├── index.html              # Interfaz web principal
    ├── events-data.json        # Base de datos de eventos
    └── start-server.ps1        # Servidor web
```

## 🌐 Aplicación Web

### Características de la Interfaz

- **🔍 Búsqueda Inteligente**: 
  - Búsqueda por Event ID (exacta o parcial)
  - Búsqueda por nombre de proveedor
  - Búsqueda en descripciones y palabras clave
  - Autocompletado de proveedores

- **📋 Modal de Detalles Completos**:
  - Tarjetas clicables que abren ventanas modales
  - Información organizada en secciones claras
  - Descripción completa sin truncar
  - Datos técnicos adicionales (Opcode, Task, Channel)
  - Controles intuitivos (ESC, click fuera, botón cerrar)

- **🎨 Diseño Moderno**:
  - Modo oscuro/claro conmutable
  - Diseño responsive para todos los dispositivos
  - Cards organizadas en grid
  - Animaciones suaves y efectos de hover
  - Modal con backdrop difuminado

- **📊 Estadísticas en Tiempo Real**:
  - Total de eventos procesados
  - Número de proveedores
  - Contador de resultados de búsqueda

- **🔧 Filtros Avanzados**:
  - Por nivel de evento (Information, Warning, Error, Critical, Verbose)
  - Por proveedor específico
  - Búsqueda exacta de Event ID

### Navegación y Usabilidad

- **👆 Interacción Intuitiva**: 
  - Click en cualquier tarjeta para ver detalles completos
  - Indicadores visuales claros ("Click para ver detalles")
  - Transiciones suaves entre vistas

- **⌨️ Controles de Teclado**:
  - Navegación con flechas en autocompletado
  - Enter para confirmar selecciones
  - ESC para cerrar modales
  - Tab para navegación accesible

- **📱 Optimización Móvil**:
  - Búsqueda avanzada colapsable en pantallas pequeñas
  - Modal que ocupa toda la pantalla en móviles
  - Touch-friendly con elementos de tamaño adecuado

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

## 🔧 Funcionalidades del Script

### Proceso de Extracción

1. **Descubrimiento de Proveedores**: Utiliza `Get-WinEvent -ListProvider *` para obtener todos los proveedores
2. **Extracción de Eventos**: Para cada proveedor, extrae todos los Event IDs disponibles
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

## 🚀 Características Técnicas

### Aplicación Web
- **HTTP Server**: Basado en `System.Net.HttpListener`
- **CORS**: Habilitado para desarrollo
- **Content-Type**: Detección automática para HTML, JSON, JS, CSS
- **Error Handling**: Manejo robusto de errores 404 y 500
- **UTF-8**: Soporte completo para caracteres especiales

### Interfaz de Usuario
- **Vanilla JavaScript**: Sin dependencias externas
- **Modal System**: Ventanas emergentes para detalles completos
- **Local Storage**: Persistencia de preferencias de tema
- **Progressive Enhancement**: Funciona sin JavaScript (búsqueda básica)
- **Mobile First**: Diseño responsive desde 320px
- **Accessibility**: Navegación por teclado y lectores de pantalla
- **Touch Optimized**: Elementos táctiles de tamaño adecuado
- **Keyboard Navigation**: Soporte completo para navegación por teclado

## 🐛 Solución de Problemas

### Error: "No se pueden cargar los datos"

**Causa**: Archivo JSON no accesible por políticas CORS del navegador.

**Solución**:
```powershell
# Asegúrate de estar en la carpeta web
cd web

# Ejecuta el servidor
.\start-server.ps1

# Accede vía servidor HTTP, no file://
# ✅ http://localhost:8080
# ❌ file:///C:/ruta/web/index.html
```

### Error: "Acceso denegado a eventos"

**Causa**: Permisos insuficientes para acceder a algunos proveedores.

**Solución**:
```powershell
# Ejecuta PowerShell como Administrador
# Luego ejecuta el script normalmente
.\crear-todo.ps1
```

### Puerto en uso

**Solución**:
```powershell
# Usa un puerto diferente
.\crear-todo.ps1 -Port 8081
```

## 📈 Rendimiento

- **Tiempo de Extracción**: ~2-5 minutos (dependiendo del sistema)
- **Eventos Típicos**: 15,000-50,000 eventos
- **Proveedores Típicos**: 200-800 proveedores
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

