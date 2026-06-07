@echo off
setlocal

set "APP_DIR=%~dp0web-quan-ly"
set "PS_FILE=%TEMP%\goalzone-local-server-%RANDOM%%RANDOM%.ps1"
set "NO_BROWSER="

if /I "%~1"=="--no-browser" set "NO_BROWSER=1"

if not exist "%APP_DIR%\index.html" (
    echo Khong tim thay thu muc web-quan-ly hoac file index.html.
    echo Kiem tra lai vi tri cua file CHAY_SERVER_LOCAL.bat.
    pause
    exit /b 1
)

> "%PS_FILE%" echo $ErrorActionPreference = 'Stop'
>> "%PS_FILE%" echo $root = [System.IO.Path]::GetFullPath('%APP_DIR%')
>> "%PS_FILE%" echo $rootBoundary = $root.TrimEnd('\') + '\'
>> "%PS_FILE%" echo $dataFile = Join-Path $root 'api\local-data.json'
>> "%PS_FILE%" echo $emptyState = [pscustomobject]@{
>> "%PS_FILE%" echo     version = 1
>> "%PS_FILE%" echo     updatedAt = 0
>> "%PS_FILE%" echo     data = $null
>> "%PS_FILE%" echo }
>> "%PS_FILE%" echo $openBrowser = [string]::IsNullOrWhiteSpace($env:GOALZONE_NO_BROWSER)
>> "%PS_FILE%" echo function Get-FreePort {
>> "%PS_FILE%" echo     foreach ($candidate in 5500..5510) {
>> "%PS_FILE%" echo         try {
>> "%PS_FILE%" echo             $tcp = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $candidate)
>> "%PS_FILE%" echo             $tcp.Start()
>> "%PS_FILE%" echo             $tcp.Stop()
>> "%PS_FILE%" echo             return $candidate
>> "%PS_FILE%" echo         } catch {
>> "%PS_FILE%" echo         }
>> "%PS_FILE%" echo     }
>> "%PS_FILE%" echo     throw 'No free port found between 5500 and 5510.'
>> "%PS_FILE%" echo }
>> "%PS_FILE%" echo function Get-ContentType([string]$path) {
>> "%PS_FILE%" echo     switch ([System.IO.Path]::GetExtension($path).ToLowerInvariant()) {
>> "%PS_FILE%" echo         '.html' { return 'text/html; charset=utf-8' }
>> "%PS_FILE%" echo         '.css' { return 'text/css; charset=utf-8' }
>> "%PS_FILE%" echo         '.js' { return 'application/javascript; charset=utf-8' }
>> "%PS_FILE%" echo         '.mjs' { return 'application/javascript; charset=utf-8' }
>> "%PS_FILE%" echo         '.json' { return 'application/json; charset=utf-8' }
>> "%PS_FILE%" echo         '.svg' { return 'image/svg+xml' }
>> "%PS_FILE%" echo         '.png' { return 'image/png' }
>> "%PS_FILE%" echo         '.jpg' { return 'image/jpeg' }
>> "%PS_FILE%" echo         '.jpeg' { return 'image/jpeg' }
>> "%PS_FILE%" echo         '.gif' { return 'image/gif' }
>> "%PS_FILE%" echo         '.ico' { return 'image/x-icon' }
>> "%PS_FILE%" echo         '.mp4' { return 'video/mp4' }
>> "%PS_FILE%" echo         default { return 'application/octet-stream' }
>> "%PS_FILE%" echo     }
>> "%PS_FILE%" echo }
>> "%PS_FILE%" echo function Write-TextResponse($response, [int]$statusCode, [string]$contentType, [string]$text) {
>> "%PS_FILE%" echo     $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
>> "%PS_FILE%" echo     $response.StatusCode = $statusCode
>> "%PS_FILE%" echo     $response.ContentType = $contentType
>> "%PS_FILE%" echo     $response.ContentLength64 = $bytes.Length
>> "%PS_FILE%" echo     $response.OutputStream.Write($bytes, 0, $bytes.Length)
>> "%PS_FILE%" echo     $response.Close()
>> "%PS_FILE%" echo }
>> "%PS_FILE%" echo function Write-JsonResponse($response, [int]$statusCode, $payload) {
>> "%PS_FILE%" echo     $json = ConvertTo-Json -InputObject $payload -Depth 20
>> "%PS_FILE%" echo     Write-TextResponse $response $statusCode 'application/json; charset=utf-8' $json
>> "%PS_FILE%" echo }
>> "%PS_FILE%" echo function Read-RequestBody([System.Net.HttpListenerRequest]$request) {
>> "%PS_FILE%" echo     $encoding = $request.ContentEncoding
>> "%PS_FILE%" echo     if ($null -eq $encoding) { $encoding = [System.Text.Encoding]::UTF8 }
>> "%PS_FILE%" echo     $reader = [System.IO.StreamReader]::new($request.InputStream, $encoding)
>> "%PS_FILE%" echo     try {
>> "%PS_FILE%" echo         return $reader.ReadToEnd()
>> "%PS_FILE%" echo     } finally {
>> "%PS_FILE%" echo         $reader.Dispose()
>> "%PS_FILE%" echo     }
>> "%PS_FILE%" echo }
>> "%PS_FILE%" echo function Read-State {
>> "%PS_FILE%" echo     if (-not (Test-Path -LiteralPath $dataFile -PathType Leaf)) {
>> "%PS_FILE%" echo         return $emptyState
>> "%PS_FILE%" echo     }
>> "%PS_FILE%" echo     try {
>> "%PS_FILE%" echo         $raw = Get-Content -LiteralPath $dataFile -Raw -Encoding UTF8
>> "%PS_FILE%" echo         $state = ConvertFrom-Json -InputObject $raw
>> "%PS_FILE%" echo         if ($null -eq $state) {
>> "%PS_FILE%" echo             return $emptyState
>> "%PS_FILE%" echo         }
>> "%PS_FILE%" echo         return $state
>> "%PS_FILE%" echo     } catch {
>> "%PS_FILE%" echo         return $emptyState
>> "%PS_FILE%" echo     }
>> "%PS_FILE%" echo }
>> "%PS_FILE%" echo function Save-State($state) {
>> "%PS_FILE%" echo     $dir = Split-Path -Parent $dataFile
>> "%PS_FILE%" echo     if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
>> "%PS_FILE%" echo         $null = New-Item -ItemType Directory -Path $dir -Force
>> "%PS_FILE%" echo     }
>> "%PS_FILE%" echo     $json = ConvertTo-Json -InputObject $state -Depth 20
>> "%PS_FILE%" echo     Set-Content -LiteralPath $dataFile -Value $json -Encoding UTF8
>> "%PS_FILE%" echo }
>> "%PS_FILE%" echo $port = Get-FreePort
>> "%PS_FILE%" echo $url = 'http://localhost:' + $port + '/'
>> "%PS_FILE%" echo if ($openBrowser) {
>> "%PS_FILE%" echo     Start-Process ($url + 'index.html')
>> "%PS_FILE%" echo }
>> "%PS_FILE%" echo Write-Host ''
>> "%PS_FILE%" echo Write-Host ('Local server running at ' + $url) -ForegroundColor Green
>> "%PS_FILE%" echo Write-Host ('App folder: ' + $root)
>> "%PS_FILE%" echo Write-Host ('Data file: ' + $dataFile)
>> "%PS_FILE%" echo Write-Host 'Press Ctrl+C to stop.'
>> "%PS_FILE%" echo Write-Host ''
>> "%PS_FILE%" echo $listener = [System.Net.HttpListener]::new()
>> "%PS_FILE%" echo $listener.Prefixes.Add($url)
>> "%PS_FILE%" echo $listener.Start()
>> "%PS_FILE%" echo try {
>> "%PS_FILE%" echo     while ($listener.IsListening) {
>> "%PS_FILE%" echo         $context = $listener.GetContext()
>> "%PS_FILE%" echo         $request = $context.Request
>> "%PS_FILE%" echo         $response = $context.Response
>> "%PS_FILE%" echo         $response.Headers['Cache-Control'] = 'no-store'
>> "%PS_FILE%" echo         try {
>> "%PS_FILE%" echo             $path = [Uri]::UnescapeDataString($request.Url.AbsolutePath)
>> "%PS_FILE%" echo             if ($path -eq '/api/data') {
>> "%PS_FILE%" echo                 if ($request.HttpMethod -eq 'GET') {
>> "%PS_FILE%" echo                     $state = Read-State
>> "%PS_FILE%" echo                     Write-JsonResponse $response 200 ([pscustomobject]@{
>> "%PS_FILE%" echo                         ok = $true
>> "%PS_FILE%" echo                         state = $state
>> "%PS_FILE%" echo                     })
>> "%PS_FILE%" echo                     continue
>> "%PS_FILE%" echo                 }
>> "%PS_FILE%" echo                 if ($request.HttpMethod -eq 'PUT') {
>> "%PS_FILE%" echo                     $rawBody = Read-RequestBody $request
>> "%PS_FILE%" echo                     $payload = $null
>> "%PS_FILE%" echo                     if (-not [string]::IsNullOrWhiteSpace($rawBody)) {
>> "%PS_FILE%" echo                         $payload = ConvertFrom-Json -InputObject $rawBody
>> "%PS_FILE%" echo                     }
>> "%PS_FILE%" echo                     $updatedAt = 0
>> "%PS_FILE%" echo                     if ($null -ne $payload -and $null -ne $payload.updatedAt) {
>> "%PS_FILE%" echo                         $updatedAt = [long]$payload.updatedAt
>> "%PS_FILE%" echo                     }
>> "%PS_FILE%" echo                     if ($updatedAt -le 0) {
>> "%PS_FILE%" echo                         $updatedAt = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
>> "%PS_FILE%" echo                     }
>> "%PS_FILE%" echo                     $data = $null
>> "%PS_FILE%" echo                     if ($null -ne $payload) {
>> "%PS_FILE%" echo                         $data = $payload.data
>> "%PS_FILE%" echo                     }
>> "%PS_FILE%" echo                     $state = [pscustomobject]@{
>> "%PS_FILE%" echo                         version = 1
>> "%PS_FILE%" echo                         updatedAt = $updatedAt
>> "%PS_FILE%" echo                         data = $data
>> "%PS_FILE%" echo                     }
>> "%PS_FILE%" echo                     Save-State $state
>> "%PS_FILE%" echo                     Write-JsonResponse $response 200 ([pscustomobject]@{
>> "%PS_FILE%" echo                         ok = $true
>> "%PS_FILE%" echo                         updatedAt = $updatedAt
>> "%PS_FILE%" echo                     })
>> "%PS_FILE%" echo                     continue
>> "%PS_FILE%" echo                 }
>> "%PS_FILE%" echo                 Write-TextResponse $response 405 'text/plain; charset=utf-8' 'Method not allowed'
>> "%PS_FILE%" echo                 continue
>> "%PS_FILE%" echo             }
>> "%PS_FILE%" echo             $relative = $path.TrimStart('/')
>> "%PS_FILE%" echo             if ([string]::IsNullOrWhiteSpace($relative)) {
>> "%PS_FILE%" echo                 $relative = 'index.html'
>> "%PS_FILE%" echo             }
>> "%PS_FILE%" echo             if ($relative.EndsWith('/')) {
>> "%PS_FILE%" echo                 $relative = $relative + 'index.html'
>> "%PS_FILE%" echo             }
>> "%PS_FILE%" echo             $fullPath = [System.IO.Path]::GetFullPath((Join-Path $root $relative))
>> "%PS_FILE%" echo             if (-not $fullPath.StartsWith($rootBoundary, [System.StringComparison]::OrdinalIgnoreCase)) {
>> "%PS_FILE%" echo                 Write-TextResponse $response 403 'text/plain; charset=utf-8' 'Forbidden'
>> "%PS_FILE%" echo                 continue
>> "%PS_FILE%" echo             }
>> "%PS_FILE%" echo             if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
>> "%PS_FILE%" echo                 Write-TextResponse $response 404 'text/plain; charset=utf-8' 'Not found'
>> "%PS_FILE%" echo                 continue
>> "%PS_FILE%" echo             }
>> "%PS_FILE%" echo             $bytes = [System.IO.File]::ReadAllBytes($fullPath)
>> "%PS_FILE%" echo             $response.StatusCode = 200
>> "%PS_FILE%" echo             $response.ContentType = Get-ContentType $fullPath
>> "%PS_FILE%" echo             $response.ContentLength64 = $bytes.Length
>> "%PS_FILE%" echo             $response.OutputStream.Write($bytes, 0, $bytes.Length)
>> "%PS_FILE%" echo             $response.Close()
>> "%PS_FILE%" echo         } catch {
>> "%PS_FILE%" echo             try {
>> "%PS_FILE%" echo                 Write-TextResponse $response 500 'text/plain; charset=utf-8' 'Internal server error'
>> "%PS_FILE%" echo             } catch {
>> "%PS_FILE%" echo             }
>> "%PS_FILE%" echo         }
>> "%PS_FILE%" echo     }
>> "%PS_FILE%" echo } finally {
>> "%PS_FILE%" echo     if ($listener.IsListening) {
>> "%PS_FILE%" echo         $listener.Stop()
>> "%PS_FILE%" echo     }
>> "%PS_FILE%" echo     $listener.Close()
>> "%PS_FILE%" echo }

if defined NO_BROWSER set "GOALZONE_NO_BROWSER=1"
if not defined NO_BROWSER set "GOALZONE_NO_BROWSER="

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS_FILE%"
set "EXIT_CODE=%ERRORLEVEL%"

del "%PS_FILE%" >nul 2>nul

if not "%EXIT_CODE%"=="0" (
    echo.
    echo Server dong voi ma loi %EXIT_CODE%.
    pause
)

exit /b %EXIT_CODE%
