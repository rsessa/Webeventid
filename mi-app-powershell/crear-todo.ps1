# Script Maestro - Genera toda la aplicacion web de eventos de Windows
# Incluye: extraccion de datos, generacion de archivos, creacion del servidor web y lanzamiento
param(
    [int]$Port = 8080,
    [switch]$AutoOpen,
    [string]$OutputPath = ".\eventos"
)

Write-Host "======================================================"
Write-Host "    GENERADOR COMPLETO DE WEB DE EVENTOS WINDOWS     " 
Write-Host "======================================================"
Write-Host "ARCHIVOS GENERADOS:" 
Write-Host "   - web\index.html (Interfaz web)" 
Write-Host "   - web\events-data.json (Base de datos)" 
Write-Host "   - web\start-server.ps1 (Servidor web)" 
Write-Host "   - $OutputPath\ (Archivos por proveedor)" 
Write-Host "   - Total eventos procesados: $($allEventsData.Count)" 
Write-Host "   - Total proveedores: $($providers.Count)" 
Write-Host "   - Archivos individuales: $OutputPath\" 
Write-Host "======================================================" 
Write-Host ""

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
        } else {
            `$filePath = `$path.TrimStart('/')
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Busqueda de Eventos de Windows</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 10px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); overflow: hidden; }
        .header { background: linear-gradient(45deg, #2c3e50, #3498db); color: white; padding: 30px; text-align: center; position: relative; }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header p { font-size: 1.2em; opacity: 0.9; }
        .theme-toggle { position: absolute; top: 20px; right: 20px; background: rgba(255,255,255,0.2); border: 2px solid rgba(255,255,255,0.3); color: white; padding: 10px 15px; border-radius: 25px; cursor: pointer; font-size: 14px; transition: all 0.3s; backdrop-filter: blur(10px); }
        .theme-toggle:hover { background: rgba(255,255,255,0.3); transform: scale(1.05); }
        .search-section { padding: 30px; background: #f8f9fa; }
        .search-container { display: flex; gap: 20px; margin-bottom: 20px; }
        .search-input { flex: 1; padding: 15px; border: 2px solid #ddd; border-radius: 8px; font-size: 16px; transition: border-color 0.3s; }
        .search-input:focus { outline: none; border-color: #3498db; }
        .search-buttons { display: flex; gap: 10px; }
        .btn { padding: 15px 25px; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; transition: all 0.3s; }
        .btn-primary { background: #3498db; color: white; }
        .btn-primary:hover { background: #2980b9; }
        .btn-secondary { background: #95a5a6; color: white; }
        .btn-secondary:hover { background: #7f8c8d; }
        .stats { display: flex; gap: 20px; justify-content: center; margin-bottom: 20px; flex-wrap: wrap; }
        .stat-item { background: white; padding: 15px 25px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; }
        .stat-number { font-size: 2em; font-weight: bold; color: #3498db; }
        .stat-label { color: #666; margin-top: 5px; }
        .results-section { padding: 0 30px 30px 30px; }
        .loading { text-align: center; padding: 40px; display: none; }
        .loading-spinner { width: 40px; height: 40px; border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 20px auto; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .results { display: none; }
        .result-item { background: white; border: 1px solid #ddd; border-radius: 8px; padding: 20px; margin-bottom: 15px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); transition: transform 0.2s; }
        .result-item:hover { transform: translateY(-2px); box-shadow: 0 4px 15px rgba(0,0,0,0.15); }
        .event-id { font-size: 1.5em; font-weight: bold; color: #e74c3c; margin-bottom: 5px; }
        .provider-name { font-size: 1.2em; color: #2c3e50; margin-bottom: 10px; }
        .event-level { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 0.9em; font-weight: bold; margin-bottom: 10px; }
        .level-information { background: #d4edda; color: #155724; }
        .level-warning { background: #fff3cd; color: #856404; }
        .level-error { background: #f8d7da; color: #721c24; }
        .level-critical { background: #f5c6cb; color: #721c24; }
        .level-verbose { background: #cce5ff; color: #004085; }
        .event-description { color: #666; line-height: 1.6; margin-bottom: 10px; }
        .event-keywords { font-size: 0.9em; color: #888; }
        .no-results { text-align: center; padding: 40px; color: #666; display: none; }
        .filters { display: flex; gap: 15px; margin-bottom: 20px; flex-wrap: wrap; }
        .filter-select { padding: 10px; border: 2px solid #ddd; border-radius: 6px; font-size: 14px; }
        .results-count { margin-bottom: 15px; color: #666; font-style: italic; }
        @media (max-width: 768px) { .search-container { flex-direction: column; } .search-buttons { justify-content: center; } .stats { flex-direction: column; align-items: center; } .filters { flex-direction: column; } }
        
        /* MODO OSCURO */
        [data-theme="dark"] {
            --bg-gradient: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            --container-bg: #2d3748;
            --header-gradient: linear-gradient(45deg, #1a202c, #2d3748);
            --search-bg: #4a5568;
            --input-bg: #2d3748;
            --input-border: #4a5568;
            --input-border-focus: #63b3ed;
            --text-primary: #e2e8f0;
            --text-secondary: #a0aec0;
            --text-muted: #718096;
            --card-bg: #2d3748;
            --card-border: #4a5568;
            --card-shadow: rgba(0,0,0,0.3);
            --stat-bg: #4a5568;
            --btn-primary: #4299e1;
            --btn-primary-hover: #3182ce;
            --btn-secondary: #718096;
            --btn-secondary-hover: #4a5568;
            --loading-bg: #f7fafc;
            --loading-border: #4299e1;
        }
        
        [data-theme="dark"] body { background: var(--bg-gradient); }
        [data-theme="dark"] .container { background: var(--container-bg); box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
        [data-theme="dark"] .header { background: var(--header-gradient); }
        [data-theme="dark"] .search-section { background: var(--search-bg); }
        [data-theme="dark"] .search-input { background: var(--input-bg); border-color: var(--input-border); color: var(--text-primary); }
        [data-theme="dark"] .search-input:focus { border-color: var(--input-border-focus); }
        [data-theme="dark"] .search-input::placeholder { color: var(--text-muted); }
        [data-theme="dark"] .btn-primary { background: var(--btn-primary); }
        [data-theme="dark"] .btn-primary:hover { background: var(--btn-primary-hover); }
        [data-theme="dark"] .btn-secondary { background: var(--btn-secondary); }
        [data-theme="dark"] .btn-secondary:hover { background: var(--btn-secondary-hover); }
        [data-theme="dark"] .stat-item { background: var(--stat-bg); color: var(--text-primary); box-shadow: 0 2px 10px var(--card-shadow); }
        [data-theme="dark"] .stat-label { color: var(--text-secondary); }
        [data-theme="dark"] .filter-select { background: var(--input-bg); border-color: var(--input-border); color: var(--text-primary); }
        [data-theme="dark"] .filter-select option { background: var(--input-bg); color: var(--text-primary); }
        [data-theme="dark"] .result-item { background: var(--card-bg); border-color: var(--card-border); box-shadow: 0 2px 5px var(--card-shadow); }
        [data-theme="dark"] .result-item:hover { box-shadow: 0 4px 15px rgba(0,0,0,0.4); }
        [data-theme="dark"] .provider-name { color: var(--text-primary); }
        [data-theme="dark"] .event-description { color: var(--text-secondary); }
        [data-theme="dark"] .event-keywords { color: var(--text-muted); }
        [data-theme="dark"] .results-count { color: var(--text-secondary); }
        [data-theme="dark"] .no-results { color: var(--text-secondary); }
        [data-theme="dark"] .loading { color: var(--text-primary); }
        [data-theme="dark"] .loading-spinner { border-color: var(--loading-bg); border-top-color: var(--loading-border); }
        
        /* Niveles de eventos en modo oscuro */
        [data-theme="dark"] .level-information { background: rgba(72, 187, 120, 0.2); color: #9ae6b4; }
        [data-theme="dark"] .level-warning { background: rgba(237, 137, 54, 0.2); color: #fbb454; }
        [data-theme="dark"] .level-error { background: rgba(245, 101, 101, 0.2); color: #fc8181; }
        [data-theme="dark"] .level-critical { background: rgba(229, 62, 62, 0.2); color: #f56565; }
        [data-theme="dark"] .level-verbose { background: rgba(66, 153, 225, 0.2); color: #90cdf4; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <button class="theme-toggle" onclick="toggleTheme()" id="themeToggle">🌙 Modo Oscuro</button>
            <h1>Busqueda de Eventos de Windows</h1>
            <p>Encuentra IDs de eventos, proveedores y descripciones</p>
        </div>
        <div class="search-section">
            <div class="search-container">
                <input type="text" id="searchInput" class="search-input" placeholder="Buscar por ID de evento, nombre de proveedor o descripcion...">
                <div class="search-buttons">
                    <button class="btn btn-primary" onclick="searchEvents()">Buscar</button>
                    <button class="btn btn-secondary" onclick="clearSearch()">Limpiar</button>
                </div>
            </div>
            <div class="filters">
                <select id="levelFilter" class="filter-select">
                    <option value="">Todos los niveles</option>
                    <option value="Information">Information</option>
                    <option value="Warning">Warning</option>
                    <option value="Error">Error</option>
                    <option value="Critical">Critical</option>
                    <option value="Verbose">Verbose</option>
                </select>
                <select id="providerFilter" class="filter-select">
                    <option value="">Todos los proveedores</option>
                </select>
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
                <div id="resultsContainer"></div>
            </div>
            <div class="no-results" id="noResults">
                <h3>No se encontraron resultados</h3>
                <p>Intenta con otros terminos de busqueda</p>
            </div>
        </div>
    </div>
    <script>
        let eventsData = [];
        let filteredData = [];
        let allProviders = new Set();
        
        // FUNCIONES DE MODO OSCURO
        function initTheme() {
            const savedTheme = localStorage.getItem('theme') || 'light';
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            const theme = savedTheme === 'auto' ? (prefersDark ? 'dark' : 'light') : savedTheme;
            
            setTheme(theme);
            updateThemeToggle(theme);
        }
        
        function setTheme(theme) {
            document.documentElement.setAttribute('data-theme', theme);
            localStorage.setItem('theme', theme);
        }
        
        function toggleTheme() {
            const currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
            const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            setTheme(newTheme);
            updateThemeToggle(newTheme);
        }
        
        function updateThemeToggle(theme) {
            const toggle = document.getElementById('themeToggle');
            if (theme === 'dark') {
                toggle.innerHTML = '☀️ Modo Claro';
                toggle.setAttribute('aria-label', 'Cambiar a modo claro');
            } else {
                toggle.innerHTML = '🌙 Modo Oscuro';
                toggle.setAttribute('aria-label', 'Cambiar a modo oscuro');
            }
        }
        
        // Inicializar tema al cargar la página
        window.addEventListener('DOMContentLoaded', function() {
            initTheme();
            loadEventsData();
        });
        
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
            
            filteredData = eventsData.filter(event => {
                const matchesQuery = !query || 
                    event.EventId?.toString().includes(query) ||
                    event.Provider?.toLowerCase().includes(query) ||
                    event.Description?.toLowerCase().includes(query) ||
                    event.Keywords?.toLowerCase().includes(query);
                const matchesLevel = !levelFilter || event.Level === levelFilter;
                const matchesProvider = !providerFilter || event.Provider === providerFilter;
                return matchesQuery && matchesLevel && matchesProvider;
            });
            
            updateStats();
            displayResults(filteredData);
        }
        
        function displayResults(results) {
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
            
            results.slice(0, 100).forEach(event => {
                const item = createResultItem(event);
                resultsContainer.appendChild(item);
            });
        }
        
        function createResultItem(event) {
            const div = document.createElement('div');
            div.className = 'result-item';
            const levelClass = event.Level ? `level-${event.Level.toLowerCase()}` : 'level-information';
            
            div.innerHTML = `
                <div class="event-id">Event ID: ${event.EventId || 'N/A'}</div>
                <div class="provider-name">[PROVIDER] ${event.Provider || 'Unknown Provider'}</div>
                ${event.Level ? `<span class="event-level ${levelClass}">${event.Level}</span>` : ''}
                ${event.Version ? `<div style="margin-bottom: 10px;"><strong>Version:</strong> ${event.Version}</div>` : ''}
                ${event.Description ? `<div class="event-description">${event.Description}</div>` : ''}
                ${event.Keywords ? `<div class="event-keywords"><strong>Keywords:</strong> ${event.Keywords}</div>` : ''}
                ${event.LogLinks ? `<div class="event-keywords"><strong>Log Links:</strong> ${event.LogLinks}</div>` : ''}
            `;
            return div;
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
            alertDiv.innerHTML = `[OK] ${message}`;
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
        
        document.getElementById('searchInput').addEventListener('input', function() {
            if (this.value.length >= 2 || this.value.length === 0) searchEvents();
        });
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
New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
New-Item -ItemType Directory -Path ".\web" -Force | Out-Null

# PASO 2: Extraer datos de eventos
Write-Host "2. Extrayendo datos de eventos de Windows..." -ForegroundColor Green
$allEventsData = @()
$providers = Get-WinEvent -ListProvider * 2>$null

Write-Host "   Encontrados $($providers.Count) proveedores. Procesando..." -ForegroundColor Yellow

$counter = 0
foreach ($providerObj in $providers) {
    $counter++
    $provider = $providerObj.Name
    $safeFileName = $provider -replace '[\\/:*?"<>|]', '_'
    
    Write-Progress -Activity "Procesando proveedores" -Status "Proveedor: $provider" -PercentComplete (($counter / $providers.Count) * 100)
    
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
                    Level = $event.Level.DisplayName
                    Keywords = ($event.Keywords | ForEach-Object { $_.DisplayName }) -join ", "
                    Description = $event.Description
                    LogLinks = ($providerObj.LogLinks -join ", ")
                }
                
                $allEventsData += $eventInfo
                
                $output += "Event ID: $($event.Id)"
                $output += "Version: $($event.Version)"
                $output += "Level: $($event.Level.DisplayName)"
                $output += "Keywords: $(($event.Keywords | ForEach-Object { $_.DisplayName }) -join ', ')"
                $output += "Description: $($event.Description)"
                $output += "---"
            }
            
            $output | Out-File -FilePath "$OutputPath\$safeFileName.txt" -Encoding UTF8
        } else {
            $basicInfo = @()
            $basicInfo += "=== PROVIDER: $provider ==="
            $basicInfo += "Sin eventos especificos definidos"
            $basicInfo += "LogLinks: $($providerObj.LogLinks -join ', ')"
            $basicInfo | Out-File -FilePath "$OutputPath\$safeFileName.txt" -Encoding UTF8
        }
    }
    catch {
        Write-Warning "Error procesando $provider : $($_.Exception.Message)"
        "Error processing $provider : $($_.Exception.Message)" | Out-File -FilePath "$OutputPath\$safeFileName.txt" -Encoding UTF8
    }
}

Write-Progress -Activity "Procesando proveedores" -Completed

# PASO 3: Generar JSON para la web
Write-Host "3. Generando archivo JSON para la web..." -ForegroundColor Green
$jsonData = @{
    generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    totalEvents = $allEventsData.Count
    totalProviders = $providers.Count
    events = $allEventsData
}

$jsonData | ConvertTo-Json -Depth 3 | Out-File -FilePath ".\web\events-data.json" -Encoding UTF8

# PASO 4: Crear interfaz web
Write-Host "4. Creando interfaz web..." -ForegroundColor Green
Create-WebInterface -WebPath ".\web"

# PASO 5: Crear servidor web
Write-Host "5. Creando servidor web..." -ForegroundColor Green
Create-WebServer -WebPath ".\web" -ServerPort $Port

# PASO 6: Mostrar resumen
Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "           APLICACION GENERADA EXITOSAMENTE!        " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "ESTADISTICAS:" -ForegroundColor Cyan
Write-Host "   • Total eventos procesados: $($allEventsData.Count)" -ForegroundColor White
Write-Host "   • Total proveedores: $($providers.Count)" -ForegroundColor White
Write-Host "   • Archivos individuales: $OutputPath\" -ForegroundColor White
Write-Host ""
Write-Host "PARA INICIAR LA APLICACION WEB:" -ForegroundColor Cyan
Write-Host "   1. Ejecuta: cd web" -ForegroundColor White
Write-Host "   2. Ejecuta: .\start-server.ps1" -ForegroundColor White
Write-Host "   3. Abre: http://localhost:$Port/mi-app-powershell/web/index.html" -ForegroundColor White
Write-Host ""
Write-Host "ARCHIVOS GENERADOS:" -ForegroundColor Cyan
Write-Host "   • web\index.html (Interfaz web)" -ForegroundColor White
Write-Host "   • web\events-data.json (Base de datos)" -ForegroundColor White
Write-Host "   • web\start-server.ps1 (Servidor web)" -ForegroundColor White
Write-Host "   • $OutputPath\ (Archivos por proveedor)" -ForegroundColor White

# PASO 7: Auto-lanzar si se solicita
if ($AutoOpen) {
    Write-Host ""
    Write-Host "Auto-lanzando aplicacion..." -ForegroundColor Yellow
    
    Push-Location ".\web"
    
    # Lanzar servidor en segundo plano
    $job = Start-Job -ScriptBlock {
        param($webPath, $serverPort)
        Set-Location $webPath
        & ".\start-server.ps1" -Port $serverPort
    } -ArgumentList (Get-Location).Path, $Port
    
    Start-Sleep 3
    Start-Process "http://localhost:$Port/mi-app-powershell/web/index.html"

    Write-Host "Servidor ejecutandose (Job ID: $($job.Id))" -ForegroundColor Green
    Write-Host "   Para detener: Stop-Job $($job.Id); Remove-Job $($job.Id)" -ForegroundColor Yellow
    
    Pop-Location
}

Write-Host ""
Write-Host "LISTO PARA USAR!" -ForegroundColor Green


