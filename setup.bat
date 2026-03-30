@echo off
REM =============================================================
REM  setup.bat — Prepare the FlinkSQL Studio file structure
REM  Run this once before: docker compose up
REM  Usage: Double-click or run from Command Prompt
REM =============================================================

echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║        FlinkSQL Studio — Docker Setup Script         ║
echo ╚══════════════════════════════════════════════════════╝
echo.

REM ── 1. Create required directories ──────────────────────────
echo [1/5] Creating directory structure...
if not exist "nginx"              mkdir nginx
if not exist "studio"             mkdir studio
if not exist "sql-scripts"        mkdir sql-scripts
if not exist "streampark-data"    mkdir streampark-data
if not exist "flink-versions"     mkdir flink-versions
if not exist "plugins\s3-fs-hadoop" mkdir plugins\s3-fs-hadoop
if not exist "connectors"         mkdir connectors
if not exist "conf"               mkdir conf
if not exist "models"             mkdir models
echo     OK - directories ready

REM ── 2. Check nginx configs ───────────────────────────────────
echo.
echo [2/5] Checking nginx configs...
if not exist "nginx\flink-cors.conf" (
    echo     ERROR: nginx\flink-cors.conf is missing
    echo     Copy it from the downloaded files into the nginx\ folder
    goto :error
)
if not exist "nginx\studio.conf" (
    echo     ERROR: nginx\studio.conf is missing
    echo     Copy it from the downloaded files into the nginx\ folder
    goto :error
)
echo     OK - nginx\flink-cors.conf
echo     OK - nginx\studio.conf

REM ── 3. Check IDE HTML ────────────────────────────────────────
echo.
echo [3/5] Checking FlinkSQL Studio HTML...
if not exist "studio\flink-sql-ide.html" (
    echo     ERROR: studio\flink-sql-ide.html is missing
    echo     Copy it from the downloaded files into the studio\ folder
    goto :error
)
echo     OK - studio\flink-sql-ide.html

REM ── 4. Check existing required config files ──────────────────
echo.
echo [4/5] Checking your existing config files...
if exist "conf\flink-conf.yaml"       (echo     OK - conf\flink-conf.yaml) else (echo     WARN - conf\flink-conf.yaml not found ^(create before docker compose up^))
if exist "sql-gateway-defaults.yaml"  (echo     OK - sql-gateway-defaults.yaml) else (echo     WARN - sql-gateway-defaults.yaml not found)
if exist "sql-client-config.yaml"     (echo     OK - sql-client-config.yaml) else (echo     WARN - sql-client-config.yaml not found)
if exist "Dockerfile.flink"           (echo     OK - Dockerfile.flink) else (echo     WARN - Dockerfile.flink not found)

REM ── 5. Ensure kafka-network-02 Docker network exists ─────────
echo.
echo [5/5] Checking Docker network kafka-network-02...
docker network inspect kafka-network-02 >nul 2>&1
if %errorlevel% equ 0 (
    echo     OK - kafka-network-02 already exists
) else (
    echo     Network not found. Creating kafka-network-02...
    docker network create kafka-network-02
    if %errorlevel% equ 0 (
        echo     OK - kafka-network-02 created
    ) else (
        echo     ERROR: Could not create Docker network. Is Docker Desktop running?
        goto :error
    )
)

REM ── Done ─────────────────────────────────────────────────────
echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║                  Setup Complete ✓                    ║
echo ╠══════════════════════════════════════════════════════╣
echo ║  Next step:                                          ║
echo ║    docker compose up -d                              ║
echo ║                                                      ║
echo ║  Services after startup:                             ║
echo ║   FlinkSQL Studio IDE  →  http://localhost:3030      ║
echo ║   CORS Proxy           →  http://localhost:8084      ║
echo ║   Flink UI             →  http://localhost:8012      ║
echo ║   StreamPark           →  http://localhost:10000     ║
echo ║                                                      ║
echo ║  In the IDE connection dialog:                       ║
echo ║    Host: localhost    Port: 8084                     ║
echo ╚══════════════════════════════════════════════════════╝
echo.
pause
goto :eof

:error
echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║              Setup failed — see errors above         ║
echo ╚══════════════════════════════════════════════════════╝
echo.
pause
exit /b 1