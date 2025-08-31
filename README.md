# Windows Event Explorer Web App

Una aplicación web completa para explorar y buscar Event IDs, proveedores y descripciones del registro de eventos de Windows de manera visual e intuitiva.

![Windows Event Explorer](https://img.shields.io/badge/Platform-Windows-blue) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue) ![HTML5](https://img.shields.io/badge/HTML5-CSS3-orange) ![JavaScript](https://img.shields.io/badge/JavaScript-ES6-yellow)

## 🚀 Características

- **🔍 Búsqueda en tiempo real** - Busca por Event ID, nombre de proveedor o descripción
- **📊 Filtros avanzados** - Filtra por nivel de evento y proveedor específico
- **📱 Interfaz responsive** - Funciona en desktop, tablet y móvil
- **⚡ Generación automática** - Script único que extrae todos los datos y crea la aplicación
- **🌐 Servidor web integrado** - No requiere instalaciones adicionales
- **📁 Exportación de datos** - Archivos individuales por proveedor y base de datos JSON
- **🎯 Totalmente portable** - Se ejecuta sin dependencias externas

## 📋 Requisitos

- **Windows 10/11** o **Windows Server 2016+**
- **PowerShell 5.1** o superior
- **Permisos de administrador** (para acceder a algunos proveedores de eventos)

## 🛠️ Instalación y Uso

### Opción 1: Generación automática con lanzamiento

```powershell
# Clona o descarga el repositorio
git clone https://github.com/tu-usuario/WebEventId.git
cd WebEventId\mi-app-powershell

# Ejecuta el script maestro con auto-lanzamiento
.\crear-todo.ps1 -AutoOpen
```

### Opción 2: Generación manual

```powershell
# Genera todos los archivos
.\crear-todo.ps1

# Navega al directorio web
cd web

# Inicia el servidor
.\start-server.ps1

# Abre en el navegador
start http://localhost:8080
```

### Parámetros del script principal

```powershell
.\crear-todo.ps1 [parámetros]

# Parámetros disponibles:
-Port 8080          # Puerto del servidor web (por defecto: 8080)
-AutoOpen           # Lanza automáticamente el navegador
-OutputPath ".\eventos"  # Directorio para archivos individuales
```

## 📁 Estructura del Proyecto

```
WebEventId/
├── README.md                    # Este archivo
├── .gitignore                   # Archivos ignorados por Git
└── mi-app-powershell/
    ├── crear-todo.ps1          # Script maestro - genera toda la aplicación
    ├── web/                    # Aplicación web generada
    │   ├── index.html          # Interfaz web principal
    │   ├── events-data.json    # Base de datos JSON con todos los eventos
    │   └── start-server.ps1    # Servidor web con soporte CORS
    └── eventos/                # Archivos individuales por proveedor
        ├── Microsoft-Windows-Kernel-General.txt
        ├── Microsoft-Windows-Security-Auditing.txt
        └── [1200+ archivos más...]
```

## 🎯 Funcionalidades de la Interfaz Web

### Dashboard Principal
- **Estadísticas en tiempo real** - Total de eventos, proveedores y resultados
- **Búsqueda inteligente** - Busca en Event IDs, nombres de proveedores y descripciones
- **Filtros dinámicos** - Por nivel (Information, Warning, Error, Critical, Verbose)

### Resultados de Búsqueda
- **Vista de tarjetas** - Información organizada y fácil de leer
- **Paginación** - Muestra 50 resultados por página para mejor rendimiento
- **Información detallada** por evento:
  - Event ID
  - Proveedor
  - Nivel de severidad
  - Versión
  - Descripción
  - Keywords
  - Log Links

### Características Técnicas
- **Carga asíncrona** - Los datos se cargan de forma no bloqueante
- **Búsqueda incremental** - Resultados actualizados mientras escribes
- **Manejo de errores** - Notificaciones claras de estado y errores
- **Soporte CORS** - Servidor web configurado correctamente

## 🔧 Personalización

### Modificar el puerto del servidor

```powershell
.\crear-todo.ps1 -Port 9090
```

### Cambiar directorio de archivos individuales

```powershell
.\crear-todo.ps1 -OutputPath "C:\MisEventos"
```

### Personalizar la interfaz web

Edita el archivo `web\index.html` para modificar:
- Estilos CSS
- Funcionalidades JavaScript
- Layout y diseño

## 📊 Datos Procesados

La aplicación extrae información de **todos los proveedores de eventos** disponibles en el sistema:

- **~1,200 proveedores** típicos en Windows 10/11
- **~60,000 eventos únicos** procesados
- **Metadatos completos** por cada evento
- **Archivos individuales** para análisis detallado

### Ejemplos de proveedores incluidos:
- Microsoft-Windows-Security-Auditing
- Microsoft-Windows-Kernel-General
- Microsoft-Windows-Application-Experience
- Microsoft-Windows-DNS-Client
- Microsoft-Windows-Winlogon
- Y muchos más...

## 🚨 Solución de Problemas

### El servidor no inicia
```powershell
# Verifica que el puerto no esté en uso
netstat -an | findstr :8080

# Usa un puerto diferente
.\crear-todo.ps1 -Port 8081
```

### Error de permisos
```powershell
# Ejecuta PowerShell como administrador
# Clic derecho en PowerShell > "Ejecutar como administrador"
```

### Problemas de codificación
```powershell
# Asegúrate de usar UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

### Datos no se cargan en la web
1. Verifica que `events-data.json` exista en el directorio `web\`
2. Asegúrate de que el servidor esté ejecutándose
3. Revisa la consola del navegador para errores CORS

## 🛡️ Seguridad

- **Servidor local únicamente** - Solo acepta conexiones desde localhost
- **Sin almacenamiento de datos sensibles** - Solo metadatos públicos de eventos
- **Archivos temporales** - Los datos se pueden eliminar después del uso
- **Sin modificaciones del sistema** - Solo lectura de información de eventos

## 🔄 Actualizaciones

Para obtener datos actualizados de eventos:

```powershell
# Regenera todos los archivos
.\crear-todo.ps1
```

Esto volverá a escanear todos los proveedores y actualizará la base de datos.

## 📝 Notas Técnicas

### Codificación de Caracteres
- Todos los archivos utilizan **UTF-8** para soporte completo de caracteres
- Los símbolos Unicode problemáticos se han reemplazado por equivalentes ASCII
- Compatible con diferentes configuraciones regionales de Windows

### Rendimiento
- **Procesamiento en lotes** de proveedores para mejor rendimiento
- **Paginación** en la interfaz web para evitar sobrecarga
- **Carga diferida** de resultados para respuesta rápida

### Compatibilidad
- **PowerShell 5.1+** (incluido en Windows 10/11)
- **Navegadores modernos** (Chrome, Firefox, Edge, Safari)
- **Windows 10/11** y **Windows Server 2016+**

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## 📜 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 🙏 Reconocimientos

- **Microsoft** - Por la API de PowerShell Get-WinEvent
- **Comunidad PowerShell** - Por ejemplos y mejores prácticas
- **MDN Web Docs** - Por documentación de tecnologías web

## 📞 Soporte

¿Encontraste un problema o tienes una sugerencia?

1. **Issues** - Crea un issue en GitHub
2. **Discussions** - Únete a las discusiones del proyecto
3. **Wiki** - Consulta la documentación extendida

---

**⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub!**

*Última actualización: Septiembre 2025*
