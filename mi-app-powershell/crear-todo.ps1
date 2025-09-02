# Script Maestro - Genera toda la aplicacion web de eventos de Windows
# Incluye: extraccion de datos, generacion de archivos, creacion del servidor web y lanzamiento
#
# Parametros:
#   -Port: Puerto para el servidor web (default: 8080)
#   -AutoOpen: Lanza automaticamente el navegador
#   -OutputPath: Carpeta para archivos de texto por proveedor (default: .\eventos)
#   -WebPath: Carpeta para la aplicacion web (default: .\web)
#
# Ejemplos:
#   .\crear-todo.ps1                                    # Configuracion basica
#   .\crear-todo.ps1 -Port 8081 -AutoOpen              # Puerto personalizado y auto-abrir
#   .\crear-todo.ps1 -WebPath ".\mi-web" -OutputPath ".\datos"  # Carpetas personalizadas
#
param(
    [int]$Port = 8080,
    [switch]$AutoOpen,
    [string]$OutputPath = ".\eventos",
    [string]$WebPath = ".\web"
)

# VALIDACIONES DE PARÁMETROS
if ($Port -lt 1024 -or $Port -gt 65535) {
    Write-Host "Error: Puerto debe estar entre 1024 y 65535" -ForegroundColor Red
    exit 1
}

# Validar caracteres en rutas
if ($WebPath -match '[<>:"|?*]' -or $OutputPath -match '[<>:"|?*]') {
    Write-Host "Error: Las rutas contienen caracteres no válidos" -ForegroundColor Red
    exit 1
}

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "    GENERADOR COMPLETO DE WEB DE EVENTOS WINDOWS     " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Función para validar prerrequisitos del sistema
function Test-SystemRequirements {
    Write-Host "Validando prerrequisitos del sistema..." -ForegroundColor Cyan
    
    # Verificar PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "Error: Se requiere PowerShell 5.0 o superior" -ForegroundColor Red
        return $false
    }
    
    # Verificar que puede acceder a eventos de Windows
    try {
        $testProvider = Get-WinEvent -ListProvider "Microsoft-Windows-PowerShell" -ErrorAction SilentlyContinue
        if (-not $testProvider) {
            Write-Host "Advertencia: Acceso limitado a eventos. Considera ejecutar como Administrador" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Advertencia: No se puede acceder a eventos de Windows" -ForegroundColor Yellow
    }
    
    # Verificar espacio en disco
    $drive = Split-Path $PWD -Qualifier
    $freeSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$drive'").FreeSpace
    if ($freeSpace -lt 100MB) {
        Write-Host "Advertencia: Poco espacio libre en disco (< 100MB)" -ForegroundColor Yellow
    }
    
    Write-Host "   ✓ Validación completada" -ForegroundColor Green
    return $true
}

# Ejecutar validaciones
if (-not (Test-SystemRequirements)) {
    exit 1
}

# Funcion para crear el servidor web
function Create-WebServer {
    param([string]$WebPath, [int]$ServerPort)
    
    $serverScript = @"
# Servidor web con CORS habilitado para eventos de Windows
param([int]`$Port = $ServerPort)

Add-Type -AssemblyName System.Net.Http

`$listener = New-Object System.Net.HttpListener
`$listener.Prefixes.Add("http://localhost:`$Port/")
`$listener.Start()

Write-Host "Servidor iniciado en http://localhost:`$Port" -ForegroundColor Green
Write-Host "Sirviendo archivos desde: `$(Get-Location)" -ForegroundColor Cyan
Write-Host "Presiona Ctrl+C para detener el servidor" -ForegroundColor Yellow
Write-Host ""

try {
    while (`$listener.IsListening) {
        `$context = `$listener.GetContext()
        `$request = `$context.Request
        `$response = `$context.Response
        
        # Configurar headers CORS
        `$response.Headers.Add("Access-Control-Allow-Origin", "*")
        `$response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        `$response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        
        `$path = `$request.Url.LocalPath
        Write-Host "Solicitud: `$(`$request.HttpMethod) `$path" -ForegroundColor Gray
        
        # Manejar preflight OPTIONS
        if (`$request.HttpMethod -eq "OPTIONS") {
            `$response.StatusCode = 200
            `$response.OutputStream.Close()
            continue
        }
        
        # Determinar archivo a servir
        if (`$path -eq "/" -or `$path -eq "/index.html") {
            `$filePath = "index.html"
        } elseif (`$path -eq "/events-data.json") {
            `$filePath = "events-data.json"
        } else {
            `$filePath = `$path.TrimStart('/')
            # Evitar acceso a archivos fuera del directorio web
            if (`$filePath.Contains("..") -or `$filePath.Contains(":")) {
                `$filePath = "index.html"
            }
        }
        
        if (Test-Path `$filePath) {
            try {
                `$content = Get-Content `$filePath -Raw -Encoding UTF8
                `$buffer = [System.Text.Encoding]::UTF8.GetBytes(`$content)
                
                # Establecer Content-Type apropiado
                if (`$filePath.EndsWith(".html")) {
                    `$response.ContentType = "text/html; charset=utf-8"
                } elseif (`$filePath.EndsWith(".json")) {
                    `$response.ContentType = "application/json; charset=utf-8"
                } elseif (`$filePath.EndsWith(".js")) {
                    `$response.ContentType = "text/javascript; charset=utf-8"
                } elseif (`$filePath.EndsWith(".css")) {
                    `$response.ContentType = "text/css; charset=utf-8"
                } else {
                    `$response.ContentType = "text/plain; charset=utf-8"
                }
                
                `$response.StatusCode = 200
                `$response.ContentLength64 = `$buffer.Length
                `$response.OutputStream.Write(`$buffer, 0, `$buffer.Length)
                
                Write-Host "Servido: `$filePath (`$(`$buffer.Length) bytes)" -ForegroundColor Green
            }
            catch {
                Write-Host "Error sirviendo `$filePath : `$(`$_.Exception.Message)" -ForegroundColor Red
                `$response.StatusCode = 500
            }
        } else {
            `$notFound = "Archivo no encontrado: `$filePath"
            `$buffer = [System.Text.Encoding]::UTF8.GetBytes(`$notFound)
            `$response.StatusCode = 404
            `$response.ContentType = "text/plain; charset=utf-8"
            `$response.OutputStream.Write(`$buffer, 0, `$buffer.Length)
            
            Write-Host "No encontrado: `$filePath" -ForegroundColor Red
        }
        
        `$response.OutputStream.Close()
    }
}
catch {
    Write-Host "Error en el servidor: `$(`$_.Exception.Message)" -ForegroundColor Red
}
finally {
    `$listener.Stop()
    Write-Host "Servidor detenido" -ForegroundColor Yellow
}
"@
    
    $serverScript | Out-File -FilePath "$WebPath\start-server.ps1" -Encoding UTF8
}

# Funcion para crear el HTML
function Create-WebInterface {
    param([string]$WebPath)
    
    $htmlContent = @'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes, minimum-scale=1.0, maximum-scale=3.0">
    <meta name="description" content="Herramienta para buscar y explorar eventos de Windows, proveedores y descripciones de Event Logs">
    <meta name="keywords" content="Windows Events, Event Logs, PowerShell, Event ID, Windows Administration">
    <meta name="author" content="Windows Event Search Tool">
    <title>Busqueda de Eventos de Windows</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        /* Variables CSS para modo claro y oscuro */
        :root {
            --bg-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            --container-bg: white;
            --text-color: #333;
            --search-bg: #f8f9fa;
            --border-color: #ddd;
            --card-bg: white;
            --card-shadow: 0 2px 5px rgba(0,0,0,0.1);
            --card-hover-shadow: 0 4px 15px rgba(0,0,0,0.15);
            --autocomplete-bg: white;
            --autocomplete-hover: #f8f9fa;
        }
        
        [data-theme="dark"] {
            --bg-gradient: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
            --container-bg: #2c3e50;
            --text-color: #ecf0f1;
            --search-bg: #34495e;
            --border-color: #4a6741;
            --card-bg: #34495e;
            --card-shadow: 0 2px 5px rgba(0,0,0,0.3);
            --card-hover-shadow: 0 4px 15px rgba(0,0,0,0.4);
            --autocomplete-bg: #34495e;
            --autocomplete-hover: #4a6741;
        }
        
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: var(--bg-gradient); 
            min-height: 100vh; 
            padding: 20px;
            color: var(--text-color);
            transition: all 0.3s ease;
        }
        .container { 
            max-width: 1400px; 
            margin: 0 auto; 
            background: var(--container-bg); 
            border-radius: 10px; 
            box-shadow: 0 10px 30px rgba(0,0,0,0.3); 
            overflow: hidden;
            transition: all 0.3s ease;
        }
        .header { 
            background: linear-gradient(45deg, #2c3e50, #3498db); 
            color: white; 
            padding: 30px; 
            text-align: center;
            position: relative;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { font-size: 1.2em; opacity: 0.9; }
        .theme-toggle {
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(255,255,255,0.2);
            border: 2px solid rgba(255,255,255,0.3);
            color: white;
            padding: 10px 15px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s ease;
            white-space: nowrap;
        }
        .theme-toggle:hover {
            background: rgba(255,255,255,0.3);
            border-color: rgba(255,255,255,0.5);
        }
        .search-section { 
            padding: 30px; 
            background: var(--search-bg);
            transition: all 0.3s ease;
        }
        .search-container { display: flex; gap: 20px; margin-bottom: 20px; flex-wrap: wrap; }
        .search-input-container { flex: 1; position: relative; min-width: 250px; }
        .search-input { 
            width: 100%; 
            padding: 15px; 
            border: 2px solid var(--border-color); 
            border-radius: 8px; 
            font-size: 16px; 
            transition: border-color 0.3s;
            background: var(--card-bg);
            color: var(--text-color);
            box-sizing: border-box;
        }
        .search-input:focus { outline: none; border-color: #3498db; }
        .autocomplete-dropdown { 
            position: absolute; 
            top: 100%; 
            left: 0; 
            right: 0; 
            background: var(--autocomplete-bg); 
            border: 1px solid var(--border-color); 
            border-top: none; 
            border-radius: 0 0 8px 8px; 
            max-height: 200px; 
            overflow-y: auto; 
            z-index: 1000; 
            display: none;
        }
        .autocomplete-item { 
            padding: 12px 15px; 
            cursor: pointer; 
            border-bottom: 1px solid var(--border-color);
            color: var(--text-color);
        }
        .autocomplete-item:hover, .autocomplete-item.highlighted { 
            background: var(--autocomplete-hover); 
        }
        .autocomplete-item:last-child { border-bottom: none; }
        .search-options { 
            display: flex; 
            gap: 20px; 
            align-items: center; 
            margin-bottom: 15px; 
            justify-content: center;
            flex-wrap: wrap;
        }
        .checkbox-container { display: flex; align-items: center; gap: 8px; }
        .checkbox-container input[type="checkbox"] { width: 18px; height: 18px; }
        .checkbox-container label { font-size: 14px; color: var(--text-color); cursor: pointer; }
        
        /* Selectores en línea para PC */
        .inline-filters {
            display: flex;
            gap: 15px;
            align-items: center;
            flex-wrap: wrap;
        }
        
        .filter-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .filter-item label {
            font-size: 14px;
            color: var(--text-color);
            white-space: nowrap;
            font-weight: 500;
        }
        
        /* Búsqueda avanzada colapsable */
        .advanced-search-toggle {
            display: none;
            background: var(--card-bg);
            border: 2px solid var(--border-color);
            color: var(--text-color);
            padding: 12px 15px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            margin-bottom: 15px;
            width: 100%;
            text-align: center;
            transition: all 0.3s ease;
            font-weight: 500;
            box-shadow: var(--card-shadow);
        }
        
        .advanced-search-toggle:hover {
            background: var(--autocomplete-hover);
            border-color: #3498db;
            transform: translateY(-1px);
        }
        
        .advanced-search-content {
            transition: max-height 0.3s ease, opacity 0.3s ease, padding 0.3s ease;
            overflow: hidden;
            max-height: 500px;
            opacity: 1;
        }
        
        .advanced-search-content.collapsed {
            max-height: 0;
            opacity: 0;
            padding-top: 0;
            padding-bottom: 0;
        }
        .search-buttons { 
            display: flex; 
            gap: 10px; 
            flex-wrap: wrap; 
            justify-content: center;
            margin-bottom: 25px;
        }
        .btn { 
            padding: 15px 25px; 
            border: none; 
            border-radius: 8px; 
            cursor: pointer; 
            font-size: 16px; 
            transition: all 0.3s; 
            white-space: nowrap;
            min-height: 44px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .btn-primary { background: #3498db; color: white; }
        .btn-primary:hover { background: #2980b9; }
        .btn-secondary { background: #95a5a6; color: white; }
        .btn-secondary:hover { background: #7f8c8d; }
        .stats { 
            display: flex; 
            gap: 20px; 
            justify-content: center; 
            margin-bottom: 20px; 
            flex-wrap: nowrap;
            background: var(--card-bg);
            padding: 20px;
            border-radius: 10px;
            box-shadow: var(--card-shadow);
            max-width: fit-content;
            margin: 0 auto 20px auto;
            overflow-x: auto;
        }
        .stat-item { 
            background: transparent; 
            padding: 0 20px; 
            border-radius: 0; 
            box-shadow: none; 
            text-align: center;
            border-right: 2px solid var(--border-color);
            transition: all 0.3s ease;
            min-width: 80px;
            flex-shrink: 0;
        }
        .stat-item:last-child {
            border-right: none;
        }
        .stat-number { font-size: 2em; font-weight: bold; color: #3498db; }
        .stat-label { color: var(--text-color); margin-top: 5px; opacity: 0.8; }
        .results-section { padding: 0 30px 30px 30px; }
        .loading { text-align: center; padding: 40px; display: none; }
        .loading-spinner { width: 40px; height: 40px; border: 4px solid var(--border-color); border-top: 4px solid #3498db; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 20px auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .results { display: none; }
        .results-count { margin-bottom: 15px; color: var(--text-color); font-style: italic; opacity: 0.8; }
        .filters { display: flex; gap: 15px; margin-bottom: 20px; flex-wrap: wrap; }
        .filter-select { 
            padding: 10px 12px; 
            border: 2px solid var(--border-color); 
            border-radius: 6px; 
            font-size: 14px;
            background: var(--card-bg);
            color: var(--text-color);
            min-width: 160px;
            cursor: pointer;
        }
        .filter-select:focus {
            outline: none;
            border-color: #3498db;
        }
        
        /* Estilos para las tarjetas en grid */
        .results-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
            margin-top: 20px;
            width: 100%;
        }
        
        .result-card {
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 20px;
            box-shadow: var(--card-shadow);
            transition: all 0.3s ease;
            height: 400px;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            word-wrap: break-word;
            hyphens: auto;
        }
        
        .result-card {
            cursor: pointer;
        }
        
        .result-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--card-hover-shadow);
        }
        
        .card-header {
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 15px;
            margin-bottom: 15px;
        }
        
        .event-id {
            font-size: 1.4em;
            font-weight: bold;
            color: #e74c3c;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .provider-name {
            font-size: 1.1em;
            color: var(--text-color);
            margin-bottom: 10px;
            font-weight: 600;
            word-break: break-word;
            overflow-wrap: break-word;
        }
        
        .card-content {
            flex: 1;
            overflow: hidden;
            display: flex;
            flex-direction: column;
        }
        
        .event-level {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
            margin-bottom: 12px;
            text-align: center;
            max-width: fit-content;
        }
        
        .level-information { background: #d4edda; color: #155724; }
        .level-warning { background: #fff3cd; color: #856404; }
        .level-error { background: #f8d7da; color: #721c24; }
        .level-critical { background: #f5c6cb; color: #721c24; }
        .level-verbose { background: #cce5ff; color: #004085; }
        
        .event-description {
            color: var(--text-color);
            line-height: 1.5;
            margin-bottom: 12px;
            flex: 1;
            overflow: hidden;
            word-wrap: break-word;
            overflow-wrap: break-word;
            hyphens: auto;
        }
        
        .description-content {
            display: -webkit-box;
            -webkit-line-clamp: 4;
            -webkit-box-orient: vertical;
            overflow: hidden;
            transition: all 0.3s ease;
        }
        
        .description-content.expanded {
            -webkit-line-clamp: unset;
            overflow: visible;
        }
        
        .read-more-btn {
            background: none;
            border: none;
            color: #3498db;
            cursor: pointer;
            font-size: 0.9em;
            padding: 5px 0;
            text-decoration: underline;
            margin-top: 8px;
        }
        
        .read-more-btn:hover {
            color: #2980b9;
        }
        
        .event-keywords {
            font-size: 0.85em;
            color: var(--text-color);
            opacity: 0.7;
            margin-top: auto;
            padding-top: 10px;
            border-top: 1px solid var(--border-color);
        }
        
        .no-results {
            text-align: center;
            padding: 40px;
            color: var(--text-color);
            display: none;
        }
        
        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            z-index: 10000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(5px);
        }
        
        .modal-content {
            background-color: var(--card-bg);
            margin: 5% auto;
            padding: 0;
            border: none;
            border-radius: 12px;
            width: 90%;
            max-width: 800px;
            max-height: 85vh;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
            animation: modalSlideIn 0.3s ease-out;
        }
        
        @keyframes modalSlideIn {
            from {
                opacity: 0;
                transform: translateY(-50px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .modal-header {
            background: linear-gradient(45deg, #2c3e50, #3498db);
            color: white;
            padding: 20px 30px;
            border-bottom: none;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-title {
            font-size: 1.5em;
            font-weight: bold;
            margin: 0;
        }
        
        .close {
            color: white;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
            background: rgba(255, 255, 255, 0.2);
            border: none;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.3s ease;
        }
        
        .close:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: scale(1.1);
        }
        
        .modal-body {
            padding: 30px;
            max-height: 60vh;
            overflow-y: auto;
            color: var(--text-color);
        }
        
        .modal-section {
            margin-bottom: 25px;
            padding: 20px;
            background: var(--search-bg);
            border-radius: 8px;
            border-left: 4px solid #3498db;
        }
        
        .modal-section-title {
            font-size: 1.2em;
            font-weight: bold;
            color: #3498db;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .modal-field {
            display: flex;
            margin-bottom: 12px;
            flex-wrap: wrap;
        }
        
        .modal-field-label {
            font-weight: bold;
            min-width: 120px;
            color: var(--text-color);
            opacity: 0.8;
        }
        
        .modal-field-value {
            flex: 1;
            color: var(--text-color);
            word-break: break-word;
            overflow-wrap: break-word;
        }
        
        .modal-description {
            background: var(--card-bg);
            padding: 20px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            line-height: 1.6;
            white-space: pre-wrap;
            word-break: break-word;
            overflow-wrap: break-word;
        }
        
        /* Responsive modal */
        @media (max-width: 768px) {
            .modal-content {
                width: 95%;
                margin: 2% auto;
                max-height: 95vh;
            }
            
            .modal-header {
                padding: 15px 20px;
            }
            
            .modal-title {
                font-size: 1.3em;
            }
            
            .modal-body {
                padding: 20px;
                max-height: 75vh;
            }
            
            .modal-section {
                padding: 15px;
                margin-bottom: 20px;
            }
            
            .modal-field {
                flex-direction: column;
                margin-bottom: 15px;
            }
            
            .modal-field-label {
                min-width: unset;
                margin-bottom: 5px;
            }
        }
        
        @media (max-width: 480px) {
            .modal-content {
                width: 98%;
                margin: 1% auto;
                max-height: 98vh;
            }
            
            .modal-header {
                padding: 12px 15px;
            }
            
            .modal-title {
                font-size: 1.1em;
            }
            
            .close {
                width: 35px;
                height: 35px;
                font-size: 24px;
            }
            
            .modal-body {
                padding: 15px;
                max-height: 80vh;
            }
            
            .modal-section {
                padding: 12px;
                margin-bottom: 15px;
            }
            
            .modal-section-title {
                font-size: 1.1em;
            }
        }
        
        /* Responsive Design */
        @media (max-width: 1200px) {
            .results-grid {
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 15px;
            }
            .result-card {
                height: 350px;
            }
        }
        
        @media (max-width: 768px) {
            body { padding: 10px; }
            
            .container { border-radius: 8px; }
            
            .header { padding: 20px 15px; }
            .header h1 { font-size: 2em; }
            .header p { font-size: 1em; }
            
            .theme-toggle {
                position: static;
                margin-bottom: 15px;
                width: fit-content;
                align-self: center;
            }
            
            .search-section { padding: 20px 15px; }
            
            .search-container { 
                flex-direction: column; 
                gap: 15px;
            }
            
            .search-buttons { 
                justify-content: center; 
                flex-direction: row;
                margin-bottom: 20px;
            }
            
            .btn { 
                padding: 12px 20px; 
                font-size: 14px;
                flex: 1;
                max-width: 120px;
            }
            
            .search-options {
                justify-content: center;
                text-align: center;
                flex-direction: column;
                gap: 15px;
            }
            
            .inline-filters {
                flex-direction: column;
                align-items: stretch;
                gap: 12px;
            }
            
            .filter-item {
                flex-direction: column;
                align-items: stretch;
                gap: 5px;
            }
            
            .filter-item label {
                text-align: left;
                font-size: 13px;
            }
            
            .stats { 
                flex-direction: row; 
                justify-content: center;
                gap: 10px;
                padding: 15px 10px;
                margin: 0 auto 15px auto;
                flex-wrap: nowrap;
                overflow-x: auto;
            }
            
            .stat-item {
                padding: 0 10px;
                border-right: 1px solid var(--border-color);
                min-width: 70px;
                flex-shrink: 0;
            }
            
            .stat-item:last-child {
                border-right: none;
            }
            
            .stat-number { font-size: 1.6em; }
            .stat-label { font-size: 0.8em; }
            
            .stat-number { font-size: 1.8em; }
            
            .filters { 
                display: none; /* Ocultar en móvil ya que están en línea arriba */
            }
            
            .filter-select {
                width: 100%;
                padding: 12px;
                font-size: 16px;
                min-width: unset;
            }
            
            .results-section { padding: 0 15px 20px 15px; }
            
            .results-grid { 
                grid-template-columns: 1fr; 
                gap: 15px;
            }
            
            .result-card {
                height: auto;
                min-height: 280px;
                padding: 15px;
            }
            
            .event-id { font-size: 1.2em; }
            
            .provider-name { 
                font-size: 1em; 
                word-break: break-word;
            }
            
            .card-content {
                overflow: visible;
            }
            
            .description-content {
                -webkit-line-clamp: 3;
            }
            
            .autocomplete-dropdown {
                font-size: 14px;
            }
            
            .autocomplete-item {
                padding: 10px 12px;
            }
        }
        
        @media (max-width: 480px) {
            body { padding: 5px; }
            
            .header { padding: 15px 10px; }
            .header h1 { font-size: 1.8em; }
            .header p { font-size: 0.9em; }
            
            .theme-toggle {
                padding: 8px 12px;
                font-size: 12px;
            }
            
            .search-section { padding: 15px 10px; }
            
            .search-input { 
                padding: 12px; 
                font-size: 16px; /* Evita zoom en iOS */
            }
            
            .btn { 
                padding: 10px 15px; 
                font-size: 13px;
            }
            
            .search-buttons { 
                justify-content: center; 
                flex-direction: row;
                margin-bottom: 20px;
            }
            
            .stats {
                gap: 8px;
                padding: 12px 8px;
                flex-wrap: nowrap;
                overflow-x: auto;
                margin: 0 auto 15px auto;
                width: 100%;
                max-width: 100%;
            }
            
            .stat-item {
                padding: 0 8px;
                min-width: 60px;
                flex-shrink: 0;
            }
            
            .stat-number { font-size: 1.4em; }
            .stat-label { 
                font-size: 0.75em; 
                white-space: nowrap;
            }
            
            .results-section { padding: 0 10px 15px 10px; }
            
            .result-card {
                padding: 12px;
                min-height: 250px;
            }
            
            .card-header {
                padding-bottom: 12px;
                margin-bottom: 12px;
            }
            
            .event-id { 
                font-size: 1.1em; 
                flex-direction: column;
                align-items: flex-start;
                gap: 5px;
            }
            
            .provider-name { font-size: 0.95em; }
            
            .event-level {
                font-size: 0.8em;
                padding: 4px 8px;
            }
            
            .event-description { 
                font-size: 0.9em; 
                line-height: 1.4;
            }
            
            .description-content {
                -webkit-line-clamp: 2;
            }
            
            .event-keywords { 
                font-size: 0.8em; 
                margin-top: 8px;
                padding-top: 8px;
            }
            
            .read-more-btn {
                font-size: 0.85em;
                margin-top: 5px;
            }
            
            .results-count {
                font-size: 0.9em;
                text-align: center;
            }
            
            .no-results h3 { font-size: 1.2em; }
            .no-results p { font-size: 0.9em; }
        }
        
        /* Pantallas muy pequeñas - Activar búsqueda avanzada colapsable */
        @media (max-width: 440px) {
            .advanced-search-toggle {
                display: block;
            }
            
            .search-options {
                margin-bottom: 10px;
                flex-direction: column;
                gap: 10px;
            }
            
            .inline-filters {
                width: 100%;
            }
            
            .filter-item {
                width: 100%;
            }
            
            .filter-select {
                min-width: unset;
                width: 100%;
            }
        }
        
        /* Pantallas extra pequeñas (320px y menos) */
        @media (max-width: 320px) {
            body { padding: 2px; }
            
            .header { padding: 10px 5px; }
            .header h1 { font-size: 1.5em; }
            .header p { font-size: 0.8em; }
            
            .search-section { padding: 10px 5px; }
            
            .advanced-search-toggle {
                padding: 10px 12px;
                font-size: 13px;
                margin-bottom: 10px;
            }
            
            .search-options {
                gap: 8px;
            }
            
            .filter-item label {
                font-size: 12px;
            }
            
            .filter-select {
                padding: 8px 10px;
                font-size: 14px;
            }
            
            .stats {
                gap: 5px;
                padding: 8px 5px;
                font-size: 0.9em;
            }
            
            .stat-item {
                padding: 0 5px;
                min-width: 50px;
            }
            
            .stat-number { font-size: 1.2em; }
            .stat-label { 
                font-size: 0.7em;
                line-height: 1.2;
            }
            
            .results-section { padding: 0 5px 10px 5px; }
        }
        
        /* Mejoras adicionales para touch devices */
        @media (hover: none) and (pointer: coarse) {
            .btn {
                min-height: 44px; /* Tamaño mínimo recomendado para touch */
            }
            
            .theme-toggle {
                min-height: 44px;
            }
            
            .autocomplete-item {
                min-height: 44px;
                display: flex;
                align-items: center;
            }
            
            .read-more-btn {
                min-height: 36px;
                padding: 8px 12px;
                border: 1px solid #3498db;
                border-radius: 4px;
                background: rgba(52, 152, 219, 0.1);
            }
            
            .result-card:hover {
                transform: none; /* Quitar animaciones hover en touch */
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <button class="theme-toggle" onclick="toggleTheme()">🌙 Modo Oscuro</button>
            <h1>Busqueda de Eventos de Windows</h1>
            <p>Encuentra IDs de eventos, proveedores y descripciones</p>
        </div>
        <div class="search-section">
            <div class="search-container">
                <div class="search-input-container">
                    <input type="text" id="searchInput" class="search-input" placeholder="Buscar por ID de evento, nombre de proveedor o descripcion...">
                    <div id="autocompleteDropdown" class="autocomplete-dropdown"></div>
                </div>
            </div>
            <button class="advanced-search-toggle" id="advancedToggle" onclick="toggleAdvancedSearch()">
                🔍 Búsqueda Avanzada
            </button>
            <div class="advanced-search-content" id="advancedContent">
                <div class="search-options">
                    <div class="checkbox-container">
                        <input type="checkbox" id="exactIdSearch">
                        <label for="exactIdSearch">Búsqueda exacta de ID</label>
                    </div>
                    <div class="inline-filters">
                        <div class="filter-item">
                            <label for="levelFilter">Nivel:</label>
                            <select id="levelFilter" class="filter-select">
                                <option value="">Todos los niveles</option>
                                <option value="Information">Information</option>
                                <option value="Warning">Warning</option>
                                <option value="Error">Error</option>
                                <option value="Critical">Critical</option>
                                <option value="Verbose">Verbose</option>
                            </select>
                        </div>
                        <div class="filter-item">
                            <label for="providerFilter">Proveedor:</label>
                            <select id="providerFilter" class="filter-select">
                                <option value="">Todos los proveedores</option>
                            </select>
                        </div>
                    </div>
                </div>
                <div class="search-buttons">
                    <button class="btn btn-primary" onclick="searchEvents()">Buscar</button>
                    <button class="btn btn-secondary" onclick="clearSearch()">Limpiar</button>
                </div>
            </div>
            <div class="stats" id="stats">
                <div class="stat-item"><div class="stat-number" id="totalEvents">-</div><div class="stat-label">Total Eventos</div></div>
                <div class="stat-item"><div class="stat-number" id="totalProviders">-</div><div class="stat-label">Proveedores</div></div>
                <div class="stat-item"><div class="stat-number" id="resultsCount">0</div><div class="stat-label">Resultados</div></div>
            </div>
        </div>
        <div class="results-section">
            <div class="loading" id="loading">
                <div class="loading-spinner"></div>
                <p>Cargando datos de eventos...</p>
            </div>
            <div class="results" id="results">
                <div class="results-count" id="resultsText"></div>
                <div id="resultsContainer" class="results-grid"></div>
            </div>
            <div class="no-results" id="noResults">
                <h3>No se encontraron resultados</h3>
                <p>Intenta con otros terminos de busqueda</p>
            </div>
        </div>
    </div>
    
    <!-- Modal para mostrar detalles del evento -->
    <div id="eventModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2 class="modal-title" id="modalTitle">Detalles del Evento</h2>
                <button class="close" onclick="closeModal()">&times;</button>
            </div>
            <div class="modal-body" id="modalBody">
                <!-- Contenido dinámico -->
            </div>
        </div>
    </div>
    <script>
        let eventsData = [];
        let filteredData = [];
        let allProviders = new Set();
        
        window.addEventListener('DOMContentLoaded', loadEventsData);
        window.addEventListener('DOMContentLoaded', initializeTheme);
        window.addEventListener('DOMContentLoaded', initializeAdvancedSearch);
        window.addEventListener('resize', initializeAdvancedSearch);
        
        function initializeTheme() {
            const savedTheme = localStorage.getItem('theme');
            const body = document.body;
            const button = document.querySelector('.theme-toggle');
            
            if (savedTheme === 'dark') {
                body.setAttribute('data-theme', 'dark');
                button.innerHTML = '☀️ Modo Claro';
            } else {
                body.removeAttribute('data-theme');
                button.innerHTML = '🌙 Modo Oscuro';
            }
        }
        
        async function loadEventsData() {
            const loading = document.getElementById('loading');
            loading.style.display = 'block';
            try {
                const response = await fetch('events-data.json');
                if (!response.ok) throw new Error(`HTTP ${response.status}`);
                const data = await response.json();
                eventsData = data.events || [];
                filteredData = [...eventsData];
                eventsData.forEach(event => { if (event.Provider) allProviders.add(event.Provider); });
                populateProviderFilter();
                updateStats();
                displayResults(filteredData.slice(0, 50));
                showSuccessMessage(`Datos cargados: ${eventsData.length} eventos de ${allProviders.size} proveedores`);
            } catch (error) {
                console.error('Error cargando datos:', error);
                showErrorMessage(error.message);
            } finally {
                loading.style.display = 'none';
            }
        }
        
        function populateProviderFilter() {
            const select = document.getElementById('providerFilter');
            Array.from(allProviders).sort().forEach(provider => {
                const option = document.createElement('option');
                option.value = provider;
                option.textContent = provider;
                select.appendChild(option);
            });
        }
        
        function updateStats() {
            document.getElementById('totalEvents').textContent = eventsData.length.toLocaleString();
            document.getElementById('totalProviders').textContent = allProviders.size.toLocaleString();
            document.getElementById('resultsCount').textContent = filteredData.length.toLocaleString();
        }
        
        function searchEvents() {
            const query = document.getElementById('searchInput').value.trim().toLowerCase();
            const levelFilter = document.getElementById('levelFilter').value;
            const providerFilter = document.getElementById('providerFilter').value;
            const exactIdSearch = document.getElementById('exactIdSearch').checked;
            
            filteredData = eventsData.filter(event => {
                let matchesQuery = !query;
                
                if (query) {
                    if (exactIdSearch && /^\d+$/.test(query)) {
                        // Busqueda exacta de ID numerico
                        matchesQuery = event.EventId?.toString() === query;
                    } else {
                        // Busqueda normal (contiene)
                        matchesQuery = 
                            event.EventId?.toString().includes(query) ||
                            event.Provider?.toLowerCase().includes(query) ||
                            event.Description?.toLowerCase().includes(query) ||
                            event.Keywords?.toLowerCase().includes(query);
                    }
                }
                
                const matchesLevel = !levelFilter || event.Level === levelFilter;
                const matchesProvider = !providerFilter || event.Provider === providerFilter;
                return matchesQuery && matchesLevel && matchesProvider;
            });
            
            updateStats();
            displayResults(filteredData);
        }        function displayResults(results) {
            const resultsContainer = document.getElementById('resultsContainer');
            const resultsSection = document.getElementById('results');
            const noResults = document.getElementById('noResults');
            const resultsText = document.getElementById('resultsText');
            
            resultsContainer.innerHTML = '';
            
            if (results.length === 0) {
                resultsSection.style.display = 'none';
                noResults.style.display = 'block';
                return;
            }
            
            noResults.style.display = 'none';
            resultsSection.style.display = 'block';
            resultsText.textContent = `Mostrando ${Math.min(results.length, 100)} de ${results.length} resultados`;
            
            const grid = document.createElement('div');
            grid.className = 'results-grid';
            
            results.slice(0, 100).forEach(event => {
                const item = createResultItem(event);
                grid.appendChild(item);
            });
            
            resultsContainer.appendChild(grid);
        }
        
        function createResultItem(event) {
            const div = document.createElement('div');
            div.className = 'result-card';
            div.style.cursor = 'pointer';
            div.addEventListener('click', () => openEventModal(event));
            
            const levelClass = event.Level ? `level-${event.Level.toLowerCase()}` : 'level-information';
            
            const description = event.Description || 'Sin descripcion disponible';
            const needsReadMore = description.length > 150;
            const shortDescription = needsReadMore ? description.substring(0, 150) + '...' : description;
            
            div.innerHTML = `
                <div class="card-header">
                    <div class="event-id">🆔 Event ID: ${event.EventId || 'N/A'}</div>
                    <div class="provider-name">📦 ${event.Provider || 'Unknown Provider'}</div>
                    ${event.Level ? `<span class="event-level ${levelClass}">${event.Level}</span>` : ''}
                </div>
                <div class="card-content">
                    ${event.Version ? `<div style="margin-bottom: 10px; font-size: 0.9em;"><strong>Version:</strong> ${event.Version}</div>` : ''}
                    <div class="event-description">
                        <div class="description-content" ${needsReadMore ? 'data-full="' + description.replace(/"/g, '&quot;') + '"' : ''}>
                            ${needsReadMore ? shortDescription : description}
                        </div>
                        ${needsReadMore ? '<button class="read-more-btn" onclick="event.stopPropagation(); toggleDescription(this)">Leer más</button>' : ''}
                    </div>
                    ${event.Keywords ? `<div class="event-keywords"><strong>Keywords:</strong> ${event.Keywords}</div>` : ''}
                    ${event.LogLinks ? `<div class="event-keywords"><strong>Log Links:</strong> ${event.LogLinks}</div>` : ''}
                </div>
                <div style="text-align: center; margin-top: 15px; padding-top: 10px; border-top: 1px solid var(--border-color); color: #3498db; font-size: 0.9em;">
                    👆 Click para ver detalles completos
                </div>
            `;
            return div;
        }
        
        function toggleDescription(button) {
            const content = button.previousElementSibling;
            const isExpanded = content.classList.contains('expanded');
            
            if (isExpanded) {
                content.classList.remove('expanded');
                content.innerHTML = content.getAttribute('data-full').substring(0, 150) + '...';
                button.textContent = 'Leer más';
            } else {
                content.classList.add('expanded');
                content.innerHTML = content.getAttribute('data-full');
                button.textContent = 'Leer menos';
            }
        }
        
        function openEventModal(event) {
            const modal = document.getElementById('eventModal');
            const modalTitle = document.getElementById('modalTitle');
            const modalBody = document.getElementById('modalBody');
            
            modalTitle.innerHTML = `🆔 Event ID: ${event.EventId || 'N/A'} - ${event.Provider || 'Unknown Provider'}`;
            
            modalBody.innerHTML = `
                <div class="modal-section">
                    <div class="modal-section-title">
                        <span>📊</span>
                        Información Básica
                    </div>
                    <div class="modal-field">
                        <div class="modal-field-label">Event ID:</div>
                        <div class="modal-field-value">${event.EventId || 'N/A'}</div>
                    </div>
                    <div class="modal-field">
                        <div class="modal-field-label">Proveedor:</div>
                        <div class="modal-field-value">${event.Provider || 'Unknown Provider'}</div>
                    </div>
                    ${event.Version ? `
                    <div class="modal-field">
                        <div class="modal-field-label">Versión:</div>
                        <div class="modal-field-value">${event.Version}</div>
                    </div>
                    ` : ''}
                    ${event.Level ? `
                    <div class="modal-field">
                        <div class="modal-field-label">Nivel:</div>
                        <div class="modal-field-value">
                            <span class="event-level level-${event.Level.toLowerCase()}">${event.Level}</span>
                        </div>
                    </div>
                    ` : ''}
                    ${event.Keywords ? `
                    <div class="modal-field">
                        <div class="modal-field-label">Keywords:</div>
                        <div class="modal-field-value">${event.Keywords}</div>
                    </div>
                    ` : ''}
                    ${event.LogLinks ? `
                    <div class="modal-field">
                        <div class="modal-field-label">Log Links:</div>
                        <div class="modal-field-value">${event.LogLinks}</div>
                    </div>
                    ` : ''}
                </div>
                
                <div class="modal-section">
                    <div class="modal-section-title">
                        <span>📝</span>
                        Descripción Completa
                    </div>
                    <div class="modal-description">
                        ${event.Description || 'Sin descripción disponible'}
                    </div>
                </div>
                
                ${event.Opcode || event.Task || event.Channel ? `
                <div class="modal-section">
                    <div class="modal-section-title">
                        <span>⚙️</span>
                        Información Técnica
                    </div>
                    ${event.Opcode ? `
                    <div class="modal-field">
                        <div class="modal-field-label">Opcode:</div>
                        <div class="modal-field-value">${event.Opcode}</div>
                    </div>
                    ` : ''}
                    ${event.Task ? `
                    <div class="modal-field">
                        <div class="modal-field-label">Task:</div>
                        <div class="modal-field-value">${event.Task}</div>
                    </div>
                    ` : ''}
                    ${event.Channel ? `
                    <div class="modal-field">
                        <div class="modal-field-label">Channel:</div>
                        <div class="modal-field-value">${event.Channel}</div>
                    </div>
                    ` : ''}
                </div>
                ` : ''}
            `;
            
            modal.style.display = 'block';
            document.body.style.overflow = 'hidden'; // Prevenir scroll en el fondo
        }
        
        function closeModal() {
            const modal = document.getElementById('eventModal');
            modal.style.display = 'none';
            document.body.style.overflow = 'auto'; // Restaurar scroll
        }
        
        // Cerrar modal al hacer click fuera de él
        window.addEventListener('click', function(event) {
            const modal = document.getElementById('eventModal');
            if (event.target === modal) {
                closeModal();
            }
        });
        
        // Cerrar modal con tecla ESC
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeModal();
            }
        });
        
        function toggleTheme() {
            const body = document.body;
            const button = document.querySelector('.theme-toggle');
            const isDark = body.getAttribute('data-theme') === 'dark';
            
            if (isDark) {
                body.removeAttribute('data-theme');
                button.innerHTML = '🌙 Modo Oscuro';
                localStorage.setItem('theme', 'light');
            } else {
                body.setAttribute('data-theme', 'dark');
                button.innerHTML = '☀️ Modo Claro';
                localStorage.setItem('theme', 'dark');
            }
        }
        
        function toggleAdvancedSearch() {
            const content = document.getElementById('advancedContent');
            const button = document.getElementById('advancedToggle');
            const isCollapsed = content.classList.contains('collapsed');
            
            if (isCollapsed) {
                content.classList.remove('collapsed');
                button.innerHTML = '🔼 Ocultar Búsqueda Avanzada';
            } else {
                content.classList.add('collapsed');
                button.innerHTML = '🔍 Búsqueda Avanzada';
            }
        }
        
        function initializeAdvancedSearch() {
            const content = document.getElementById('advancedContent');
            const button = document.getElementById('advancedToggle');
            
            // Verificar si estamos en pantalla pequeña
            if (window.innerWidth <= 440) {
                content.classList.add('collapsed');
                button.innerHTML = '🔍 Búsqueda Avanzada';
            } else {
                content.classList.remove('collapsed');
            }
        }
        
        function clearSearch() {
            document.getElementById('searchInput').value = '';
            document.getElementById('levelFilter').value = '';
            document.getElementById('providerFilter').value = '';
            filteredData = [...eventsData];
            updateStats();
            displayResults(filteredData.slice(0, 50));
        }
        
        function showSuccessMessage(message) {
            const alertDiv = document.createElement('div');
            alertDiv.style.cssText = `position: fixed; top: 20px; right: 20px; background: #d4edda; color: #155724; padding: 15px 20px; border-radius: 8px; border: 1px solid #c3e6cb; z-index: 1000; box-shadow: 0 4px 12px rgba(0,0,0,0.1); max-width: 400px;`;
            alertDiv.innerHTML = `✅ ${message}`;
            document.body.appendChild(alertDiv);
            setTimeout(() => alertDiv.remove(), 5000);
        }
        
        function showErrorMessage(message) {
            const resultsSection = document.getElementById('results');
            const noResults = document.getElementById('noResults');
            resultsSection.style.display = 'none';
            noResults.style.display = 'block';
            noResults.innerHTML = `
                <h3>Error cargando datos</h3>
                <p><strong>Problema:</strong> ${message}</p>
                <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-top: 15px; text-align: left;">
                    <h4>Solucion:</h4>
                    <ol style="margin-left: 20px;">
                        <li>Asegurate de estar en la carpeta <code>web</code></li>
                        <li>Ejecuta el servidor: <code>.\\start-server.ps1</code></li>
                        <li>Abre el navegador en: <a href="http://localhost:8080" target="_blank">http://localhost:8080</a></li>
                    </ol>
                    <p style="margin-top: 15px;"><strong>Nota:</strong> Los archivos JSON no se pueden cargar directamente desde el sistema de archivos debido a las politicas de seguridad del navegador (CORS).</p>
                </div>
            `;
        }
        
        // Funciones de autocompletado
        let currentSuggestionIndex = -1;
        
        function showAutocomplete(suggestions) {
            const dropdown = document.getElementById('autocompleteDropdown');
            dropdown.innerHTML = '';
            
            if (suggestions.length === 0) {
                dropdown.style.display = 'none';
                return;
            }
            
            suggestions.forEach((suggestion, index) => {
                const item = document.createElement('div');
                item.className = 'autocomplete-item';
                item.textContent = suggestion;
                item.addEventListener('click', () => selectSuggestion(suggestion));
                dropdown.appendChild(item);
            });
            
            dropdown.style.display = 'block';
            currentSuggestionIndex = -1;
        }
        
        function hideAutocomplete() {
            document.getElementById('autocompleteDropdown').style.display = 'none';
            currentSuggestionIndex = -1;
        }
        
        function selectSuggestion(suggestion) {
            document.getElementById('searchInput').value = suggestion;
            hideAutocomplete();
            searchEvents();
        }
        
        function getProviderSuggestions(query) {
            if (!query || query.length < 2) return [];
            
            const providers = Array.from(allProviders)
                .filter(provider => provider.toLowerCase().includes(query.toLowerCase()))
                .sort()
                .slice(0, 8); // Limitar a 8 sugerencias
                
            return providers;
        }
        
        function handleKeyNavigation(e) {
            const dropdown = document.getElementById('autocompleteDropdown');
            const items = dropdown.querySelectorAll('.autocomplete-item');
            
            if (items.length === 0) return;
            
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                currentSuggestionIndex = Math.min(currentSuggestionIndex + 1, items.length - 1);
                updateHighlight(items);
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                currentSuggestionIndex = Math.max(currentSuggestionIndex - 1, -1);
                updateHighlight(items);
            } else if (e.key === 'Enter' && currentSuggestionIndex >= 0) {
                e.preventDefault();
                selectSuggestion(items[currentSuggestionIndex].textContent);
            } else if (e.key === 'Escape') {
                hideAutocomplete();
            }
        }
        
        function updateHighlight(items) {
            items.forEach((item, index) => {
                item.classList.toggle('highlighted', index === currentSuggestionIndex);
            });
        }
        
        document.getElementById('searchInput').addEventListener('input', function() {
            const query = this.value.trim();
            
            // Mostrar autocompletado solo si no parece ser un ID numerico
            if (query.length >= 2 && !/^\d+$/.test(query)) {
                const suggestions = getProviderSuggestions(query);
                showAutocomplete(suggestions);
            } else {
                hideAutocomplete();
            }
            
            // Realizar busqueda si tiene contenido o esta vacio
            if (query.length >= 2 || query.length === 0) {
                searchEvents();
            }
        });
        
        document.getElementById('searchInput').addEventListener('keydown', handleKeyNavigation);
        document.getElementById('searchInput').addEventListener('blur', function() {
            // Delay para permitir clicks en el dropdown
            setTimeout(() => hideAutocomplete(), 150);
        });
        
        // Click fuera del autocompletado para cerrarlo
        document.addEventListener('click', function(e) {
            if (!e.target.closest('.search-input-container')) {
                hideAutocomplete();
            }
        });
        
        document.getElementById('exactIdSearch').addEventListener('change', searchEvents);
        document.getElementById('levelFilter').addEventListener('change', searchEvents);
        document.getElementById('providerFilter').addEventListener('change', searchEvents);
        document.getElementById('searchInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') searchEvents();
        });
    </script>
</body>
</html>
'@
    
    $htmlContent | Out-File -FilePath "$WebPath\index.html" -Encoding UTF8
}

# PASO 1: Crear directorios
Write-Host "1. Creando estructura de directorios..." -ForegroundColor Green

# Crear directorios y convertir a rutas absolutas para evitar problemas
try {
    $OutputPath = (New-Item -ItemType Directory -Path $OutputPath -Force).FullName
    $WebPath = (New-Item -ItemType Directory -Path $WebPath -Force).FullName
    Write-Host "   • OutputPath: $OutputPath" -ForegroundColor Gray
    Write-Host "   • WebPath: $WebPath" -ForegroundColor Gray
}
catch {
    Write-Host "Error creando directorios: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# PASO 2: Extraer datos de eventos
Write-Host "2. Extrayendo datos de eventos de Windows..." -ForegroundColor Green
$allEventsData = @()

try {
    $providers = Get-WinEvent -ListProvider * 2>$null
    Write-Host "   Encontrados $($providers.Count) proveedores. Procesando..." -ForegroundColor Yellow
}
catch {
    Write-Host "Error obteniendo proveedores de eventos: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Verifica que tengas permisos suficientes o ejecuta como Administrador" -ForegroundColor Yellow
    exit 1
}

if ($providers.Count -eq 0) {
    Write-Host "No se encontraron proveedores de eventos. Verifica permisos." -ForegroundColor Red
    exit 1
}

$counter = 0
$errorCount = 0
$successCount = 0

foreach ($providerObj in $providers) {
    $counter++
    $provider = $providerObj.Name
    $safeFileName = $provider -replace '[\\/:*?"<>|]', '_'
    
    Write-Progress -Activity "Procesando proveedores" -Status "Proveedor: $provider ($counter/$($providers.Count))" -PercentComplete (($counter / $providers.Count) * 100)
    
    try {
        $events = $providerObj.Events
        
        if ($events) {
            $output = @()
            $output += "=== PROVIDER: $provider ==="
            $output += "Numero de eventos: $($events.Count)"
            $output += ""
            
            foreach ($event in $events) {
                $eventInfo = [PSCustomObject]@{
                    Provider = $provider
                    EventId = $event.Id
                    Version = $event.Version
                    Level = if ($event.Level) { $event.Level.DisplayName } else { "Unknown" }
                    Keywords = if ($event.Keywords) { ($event.Keywords | ForEach-Object { $_.DisplayName }) -join ", " } else { "" }
                    Description = if ($event.Description) { $event.Description } else { "Sin descripción disponible" }
                    LogLinks = if ($providerObj.LogLinks) { ($providerObj.LogLinks -join ", ") } else { "" }
                }
                
                $allEventsData += $eventInfo
                
                $output += "Event ID: $($event.Id)"
                $output += "Version: $($event.Version)"
                $output += "Level: $(if ($event.Level) { $event.Level.DisplayName } else { 'Unknown' })"
                $output += "Keywords: $(if ($event.Keywords) { ($event.Keywords | ForEach-Object { $_.DisplayName }) -join ', ' } else { 'None' })"
                $output += "Description: $(if ($event.Description) { $event.Description } else { 'Sin descripción disponible' })"
                $output += "---"
            }
            
            $output | Out-File -FilePath "$OutputPath\$safeFileName.txt" -Encoding UTF8
            $successCount++
        } else {
            $basicInfo = @()
            $basicInfo += "=== PROVIDER: $provider ==="
            $basicInfo += "Sin eventos especificos definidos"
            $basicInfo += "LogLinks: $(if ($providerObj.LogLinks) { $providerObj.LogLinks -join ', ' } else { 'None' })"
            $basicInfo | Out-File -FilePath "$OutputPath\$safeFileName.txt" -Encoding UTF8
            $successCount++
        }
    }
    catch {
        $errorCount++
        Write-Warning "Error procesando $provider : $($_.Exception.Message)"
        try {
            "Error processing $provider : $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\ERROR_$safeFileName.txt" -Encoding UTF8
        }
        catch {
            Write-Warning "No se pudo crear archivo de error para $provider"
        }
    }
}

Write-Progress -Activity "Procesando proveedores" -Completed

Write-Host "   ✓ Procesamiento completado:" -ForegroundColor Green
Write-Host "     • Proveedores exitosos: $successCount" -ForegroundColor Gray
Write-Host "     • Proveedores con errores: $errorCount" -ForegroundColor Gray
Write-Host "     • Total eventos extraídos: $($allEventsData.Count)" -ForegroundColor Gray

# PASO 3: Generar JSON para la web
Write-Host "3. Generando archivo JSON para la web..." -ForegroundColor Green
$jsonData = @{
    generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    totalEvents = $allEventsData.Count
    totalProviders = $providers.Count
    events = $allEventsData
}

try {
    $jsonData | ConvertTo-Json -Depth 3 | Out-File -FilePath "$WebPath\events-data.json" -Encoding UTF8
    Write-Host "   • JSON generado exitosamente: $($allEventsData.Count) eventos" -ForegroundColor Gray
}
catch {
    Write-Host "Error generando archivo JSON: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# PASO 4: Crear interfaz web
Write-Host "4. Creando interfaz web..." -ForegroundColor Green
try {
    Create-WebInterface -WebPath $WebPath
    Write-Host "   • Interfaz HTML creada exitosamente" -ForegroundColor Gray
}
catch {
    Write-Host "Error creando interfaz web: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# PASO 5: Crear servidor web
Write-Host "5. Creando servidor web..." -ForegroundColor Green
try {
    Create-WebServer -WebPath $WebPath -ServerPort $Port
    Write-Host "   • Servidor PowerShell creado para puerto $Port" -ForegroundColor Gray
}
catch {
    Write-Host "Error creando servidor web: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# PASO 6: Mostrar resumen
Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "           APLICACION GENERADA EXITOSAMENTE!        " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "ESTADISTICAS:" -ForegroundColor Cyan
Write-Host "   • Total eventos procesados: $($allEventsData.Count)" -ForegroundColor White
Write-Host "   • Total proveedores procesados: $($providers.Count)" -ForegroundColor White
Write-Host "   • Proveedores exitosos: $successCount" -ForegroundColor White
Write-Host "   • Proveedores con errores: $errorCount" -ForegroundColor White
Write-Host "   • Archivos generados en: $OutputPath\" -ForegroundColor White
Write-Host ""
Write-Host "PARA INICIAR LA APLICACION WEB:" -ForegroundColor Cyan
Write-Host "   1. Ejecuta: cd `"$WebPath`"" -ForegroundColor White
Write-Host "   2. Ejecuta: .\start-server.ps1" -ForegroundColor White
Write-Host "   3. Abre tu navegador en: http://localhost:$Port" -ForegroundColor White
Write-Host ""
Write-Host "ESTRUCTURA DE ARCHIVOS:" -ForegroundColor Cyan
Write-Host "   • Carpeta `"$WebPath`" contiene la aplicacion web completa" -ForegroundColor White
Write-Host "   • El servidor sirve archivos desde la carpeta web" -ForegroundColor White
Write-Host "   • URL de acceso: http://localhost:$Port (redirige a index.html)" -ForegroundColor White
Write-Host ""
Write-Host "ARCHIVOS GENERADOS:" -ForegroundColor Cyan
Write-Host "   • $WebPath\index.html (Interfaz web)" -ForegroundColor White
Write-Host "   • $WebPath\events-data.json (Base de datos)" -ForegroundColor White
Write-Host "   • $WebPath\start-server.ps1 (Servidor web)" -ForegroundColor White
Write-Host "   • $OutputPath\ (Archivos por proveedor)" -ForegroundColor White

if ($errorCount -gt 0) {
    Write-Host ""
    Write-Host "ADVERTENCIAS:" -ForegroundColor Yellow
    Write-Host "   • $errorCount proveedores no pudieron procesarse completamente" -ForegroundColor White
    Write-Host "   • Revisa los archivos ERROR_*.txt en $OutputPath\" -ForegroundColor White
    Write-Host "   • Considera ejecutar como Administrador para acceso completo" -ForegroundColor White
}

# PASO 7: Auto-lanzar si se solicita
if ($AutoOpen) {
    Write-Host ""
    Write-Host "Auto-lanzando aplicacion..." -ForegroundColor Yellow
    
    # Validar que la carpeta web existe y tiene archivos
    $webIndexPath = Join-Path $WebPath "index.html"
    $webServerPath = Join-Path $WebPath "start-server.ps1"
    
    if (-not (Test-Path $webIndexPath) -or -not (Test-Path $webServerPath)) {
        Write-Host "Error: Archivos web no encontrados en $WebPath" -ForegroundColor Red
        Write-Host "Verifica que el proceso de creación fue exitoso" -ForegroundColor Yellow
        return
    }
    
    try {
        # Validar que el puerto no esté en uso
        $portInUse = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        if ($portInUse) {
            Write-Host "Advertencia: Puerto $Port ya está en uso" -ForegroundColor Yellow
            Write-Host "Intentando usar puerto alternativo..." -ForegroundColor Yellow
            $Port = $Port + 1
        }
        
        Push-Location $WebPath
        
        # Lanzar servidor en segundo plano con mejor manejo de errores
        $job = Start-Job -ScriptBlock {
            param($webPath, $serverPort)
            try {
                Set-Location $webPath
                & ".\start-server.ps1" -Port $serverPort
            }
            catch {
                Write-Error "Error iniciando servidor: $($_.Exception.Message)"
            }
        } -ArgumentList $WebPath, $Port
        
        # Esperar un poco más para asegurar que el servidor inicie
        Start-Sleep 5
        
        # Validar que el servidor responde antes de abrir el navegador
        $maxRetries = 3
        $retryCount = 0
        $serverReady = $false
        
        while ($retryCount -lt $maxRetries -and -not $serverReady) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 2 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    $serverReady = $true
                }
            }
            catch {
                $retryCount++
                Start-Sleep 2
            }
        }
        
        if ($serverReady) {
            Start-Process "http://localhost:$Port"
            Write-Host "Servidor ejecutandose exitosamente (Job ID: $($job.Id))" -ForegroundColor Green
            Write-Host "   URL: http://localhost:$Port" -ForegroundColor Cyan
            Write-Host "   Para detener: Stop-Job $($job.Id); Remove-Job $($job.Id)" -ForegroundColor Yellow
        } else {
            Write-Host "Advertencia: El servidor puede no estar respondiendo" -ForegroundColor Yellow
            Write-Host "   Verifica manualmente: http://localhost:$Port" -ForegroundColor Cyan
            Write-Host "   Job ID: $($job.Id)" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Host "Error durante el auto-lanzamiento: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Puedes iniciar manualmente:" -ForegroundColor Yellow
        Write-Host "   1. cd $WebPath" -ForegroundColor White
        Write-Host "   2. .\start-server.ps1 -Port $Port" -ForegroundColor White
    }
    finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "LISTO PARA USAR!" -ForegroundColor Green
