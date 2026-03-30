# =============================================================
#  setup.ps1 - Prepare the FlinkSQL Studio file structure
#  Run this once before: docker compose up
#
#  Usage (from project root in PowerShell):
#    .\setup.ps1
#
#  If you get an execution policy error, run first:
#    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# =============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        FlinkSQL Studio — Docker Setup Script         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── 1. Create required directories ──────────────────────────────
Write-Host "[1/5] Creating directory structure..." -ForegroundColor Yellow

$dirs = @(
    "nginx",
    "studio",
    "sql-scripts",
    "streampark-data",
    "flink-versions",
    "plugins/s3-fs-hadoop",
    "connectors",
    "conf",
    "models"
)

foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "    Created: $d" -ForegroundColor DarkGray
    }
    else {
        Write-Host "    Exists:  $d" -ForegroundColor DarkGray
    }
}

Write-Host "    OK - directories ready" -ForegroundColor Green


# ── 2. Check nginx configs ──────────────────────────────────────
Write-Host ""
Write-Host "[2/5] Checking nginx configs..." -ForegroundColor Yellow

$failed = $false

$nginxFiles = @(
    "nginx/flink-cors.conf",
    "nginx/studio.conf"
)

foreach ($file in $nginxFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "    ERROR: $file is missing" -ForegroundColor Red
        $failed = $true
    }
    else {
        Write-Host "    OK - $file" -ForegroundColor Green
    }
}

if ($failed) {
    Write-Host ""
    Write-Host "Setup failed. Fix the errors above and re-run." -ForegroundColor Red
    exit 1
}


# ── 3. Check IDE HTML ───────────────────────────────────────────
Write-Host ""
Write-Host "[3/5] Checking FlinkSQL Studio HTML..." -ForegroundColor Yellow

if (-not (Test-Path "studio/flink-sql-ide.html")) {
    Write-Host "    ERROR: studio/flink-sql-ide.html is missing" -ForegroundColor Red
    Write-Host ""
    Write-Host "Setup failed." -ForegroundColor Red
    exit 1
}

Write-Host "    OK - studio/flink-sql-ide.html" -ForegroundColor Green


# ── 4. Check existing config files (warnings only) ──────────────
Write-Host ""
Write-Host "[4/5] Checking your existing config files..." -ForegroundColor Yellow

$configs = @(
    "conf/flink-conf.yaml",
    "sql-gateway-defaults.yaml",
    "sql-client-config.yaml",
    "Dockerfile.flink"
)

foreach ($f in $configs) {
    if (Test-Path $f) {
        Write-Host "    OK   - $f" -ForegroundColor Green
    }
    else {
        Write-Host "    WARN - $f not found (create before docker compose up)" -ForegroundColor Yellow
    }
}


# ── 5. Docker network check ─────────────────────────────────────
Write-Host ""
Write-Host "[5/5] Checking Docker network kafka-network-02..." -ForegroundColor Yellow

# Check Docker installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "    ERROR: Docker is not installed or not in PATH." -ForegroundColor Red
    exit 1
}

# Check Docker running
try {
    docker info > $null 2>&1
}
catch {
    Write-Host "    ERROR: Docker Desktop is not running." -ForegroundColor Red
    exit 1
}

# Check if network exists
$networkExists = docker network ls --format "{{.Name}}" | Select-String "^kafka-network-02$"

if ($networkExists) {
    Write-Host "    OK - kafka-network-02 already exists" -ForegroundColor Green
}
else {
    Write-Host "    Network not found. Creating kafka-network-02..." -ForegroundColor Yellow

    docker network create kafka-network-02 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "    OK - kafka-network-02 created" -ForegroundColor Green
    }
    else {
        Write-Host "    ERROR: Could not create Docker network." -ForegroundColor Red
        exit 1
    }
}


# ── Done ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "                Setup Complete                        " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next step:" -ForegroundColor Green
Write-Host "  docker compose up -d" -ForegroundColor Green
Write-Host ""
Write-Host "Services after startup:" -ForegroundColor Green
Write-Host "  FlinkSQL Studio IDE  ->  http://localhost:3030" -ForegroundColor Green
Write-Host "  CORS Proxy           ->  http://localhost:8084" -ForegroundColor Green
Write-Host "  Flink UI             ->  http://localhost:8012" -ForegroundColor Green
Write-Host "  StreamPark           ->  http://localhost:10000" -ForegroundColor Green
Write-Host ""
Write-Host "IDE connection:" -ForegroundColor Green
Write-Host "  Host: localhost" -ForegroundColor Green
Write-Host "  Port: 8084" -ForegroundColor Green
Write-Host ""
Write-Host "======================================================" -ForegroundColor Green