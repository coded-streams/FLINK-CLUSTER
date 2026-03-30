# download-connectors-simple.ps1
$ConnectorsDir = ".\connectors"

# Create directory
if (-not (Test-Path $ConnectorsDir)) {
    New-Item -ItemType Directory -Path $ConnectorsDir -Force | Out-Null
}

# List of essential connector URLs (only the most important ones)
$JarsToDownload = @(
    @{url = "https://repo1.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.3.0-1.19/flink-sql-connector-kafka-3.3.0-1.19.jar"; name = "flink-sql-connector-kafka-3.3.0-1.19.jar"}
    @{url = "https://repo1.maven.apache.org/maven2/org/apache/flink/flink-connector-jdbc/3.2.0-1.19/flink-connector-jdbc-3.2.0-1.19.jar"; name = "flink-connector-jdbc-3.2.0-1.19.jar"}
    @{url = "https://repo1.maven.apache.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar"; name = "postgresql-42.7.3.jar"}
    @{url = "https://repo1.maven.apache.org/maven2/org/apache/flink/flink-sql-avro/1.19.1/flink-sql-avro-1.19.1.jar"; name = "flink-sql-avro-1.19.1.jar"}
    @{url = "https://repo1.maven.apache.org/maven2/org/apache/flink/flink-sql-json/1.19.1/flink-sql-json-1.19.1.jar"; name = "flink-sql-json-1.19.1.jar"}
)

Write-Host "=== Downloading Essential Connector JARs ===" -ForegroundColor Cyan

foreach ($jar in $JarsToDownload) {
    $dest = Join-Path $ConnectorsDir $jar.name
    
    if (Test-Path $dest) {
        Write-Host "[SKIP] $($jar.name) already exists" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "[DOWNLOAD] $($jar.name)..." -ForegroundColor Cyan
    
    try {
        # Use curl if available, otherwise use Invoke-WebRequest
        $curlResult = curl.exe -L -o $dest $jar.url 2>&1
        if ($LASTEXITCODE -eq 0) {
            $size = [math]::Round((Get-Item $dest).Length / 1KB, 1)
            Write-Host "[OK] $($jar.name) ($size KB)" -ForegroundColor Green
        } else {
            throw "curl failed"
        }
    } catch {
        # Fallback to PowerShell
        try {
            Invoke-WebRequest -Uri $jar.url -OutFile $dest -UseBasicParsing
            $size = [math]::Round((Get-Item $dest).Length / 1KB, 1)
            Write-Host "[OK] $($jar.name) ($size KB)" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to download $($jar.name)" -ForegroundColor Red
            Write-Host "        Please download manually from: $($jar.url)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=== Connectors in $ConnectorsDir ===" -ForegroundColor Cyan
Get-ChildItem $ConnectorsDir -Filter "*.jar" | Format-Table Name, Length -AutoSize