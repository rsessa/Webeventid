# Script Maestro - Genera toda la aplicacion web de eventos de Windows
# Incluye: extraccion de datos, generacion de archivos, creacion del servidor web y lanzamiento
param(
    [int]$Port = 8080,
    [switch]$AutoOpen,
    [string]$OutputPath = ".\eventos"
)

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "    GENERADOR COMPLETO DE WEB DE EVENTOS WINDOWS     " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
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
        .search-container { display: flex; gap: 20px; margin-bottom: 20px; }
        .search-input-container { flex: 1; position: relative; }
        .search-input { 
            width: 100%; 
            padding: 15px; 
            border: 2px solid var(--border-color); 
            border-radius: 8px; 
            font-size: 16px; 
            transition: border-color 0.3s;
            background: var(--card-bg);
            color: var(--text-color);
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
        .search-options { display: flex; gap: 15px; align-items: center; margin-bottom: 15px; }
        .checkbox-container { display: flex; align-items: center; gap: 8px; }
        .checkbox-container input[type="checkbox"] { width: 18px; height: 18px; }
        .checkbox-container label { font-size: 14px; color: var(--text-color); cursor: pointer; }
        .search-buttons { display: flex; gap: 10px; }
        .btn { padding: 15px 25px; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; transition: all 0.3s; }
        .btn-primary { background: #3498db; color: white; }
        .btn-primary:hover { background: #2980b9; }
        .btn-secondary { background: #95a5a6; color: white; }
        .btn-secondary:hover { background: #7f8c8d; }
        .stats { display: flex; gap: 20px; justify-content: center; margin-bottom: 20px; flex-wrap: wrap; }
        .stat-item { 
            background: var(--card-bg); 
            padding: 15px 25px; 
            border-radius: 8px; 
            box-shadow: var(--card-shadow); 
            text-align: center;
            transition: all 0.3s ease;
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
            padding: 10px; 
            border: 2px solid var(--border-color); 
            border-radius: 6px; 
            font-size: 14px;
            background: var(--card-bg);
            color: var(--text-color);
        }
        
        /* Estilos para las tarjetas en grid */
        .results-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
            margin-top: 20px;
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
        
        @media (max-width: 768px) { 
            .search-container { flex-direction: column; } 
            .search-buttons { justify-content: center; } 
            .stats { flex-direction: column; align-items: center; } 
            .filters { flex-direction: column; }
            .results-grid { grid-template-columns: 1fr; }
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
                <div class="search-buttons">
                    <button class="btn btn-primary" onclick="searchEvents()">Buscar</button>
                    <button class="btn btn-secondary" onclick="clearSearch()">Limpiar</button>
                </div>
            </div>
            <div class="search-options">
                <div class="checkbox-container">
                    <input type="checkbox" id="exactIdSearch">
                    <label for="exactIdSearch">Busqueda exacta de ID</label>
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
                <div id="resultsContainer" class="results-grid"></div>
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
        
        window.addEventListener('DOMContentLoaded', loadEventsData);
        window.addEventListener('DOMContentLoaded', initializeTheme);
        
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
                        ${needsReadMore ? '<button class="read-more-btn" onclick="toggleDescription(this)">Leer más</button>' : ''}
                    </div>
                    ${event.Keywords ? `<div class="event-keywords"><strong>Keywords:</strong> ${event.Keywords}</div>` : ''}
                    ${event.LogLinks ? `<div class="event-keywords"><strong>Log Links:</strong> ${event.LogLinks}</div>` : ''}
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
Write-Host "   3. Abre: http://localhost:$Port" -ForegroundColor White
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
