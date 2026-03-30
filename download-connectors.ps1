# download-connectors.ps1
# Downloads all connectors from Systems Manager

param(
    [string]$FlinkVersion = "1.19.1",
    [string]$ConnectorsDir = ".\connectors"
)

# Create connectors directory
if (-not (Test-Path $ConnectorsDir)) {
    New-Item -ItemType Directory -Path $ConnectorsDir -Force | Out-Null
    Write-Host "INFO: Created $ConnectorsDir" -ForegroundColor Cyan
}

# Multiple reliable mirrors
$Mirrors = @(
    "https://repo1.maven.apache.org/maven2",
    "https://repo.maven.apache.org/maven2",
    "https://mirrors.estointernet.in/maven2"
)

# Complete list of connectors from Systems Manager
$Connectors = @(
    # Messaging
    @{ group = "org/apache/flink"; artifact = "flink-sql-connector-kafka"; version = "3.3.0-1.19"; file = "flink-sql-connector-kafka-3.3.0-1.19.jar"; desc = "Apache Kafka SQL Connector" }
    @{ group = "org/apache/flink"; artifact = "flink-connector-pulsar"; version = "4.0.0-1.18"; file = "flink-connector-pulsar-4.0.0-1.18.jar"; desc = "Apache Pulsar Connector" }
    @{ group = "org/apache/flink"; artifact = "flink-connector-kinesis"; version = "4.2.0-1.18"; file = "flink-connector-kinesis-4.2.0-1.18.jar"; desc = "AWS Kinesis Connector" }
    
    # Database
    @{ group = "org/apache/flink"; artifact = "flink-connector-jdbc"; version = "3.2.0-1.19"; file = "flink-connector-jdbc-3.2.0-1.19.jar"; desc = "JDBC Connector (PostgreSQL/MySQL)" }
    @{ group = "org/apache/flink"; artifact = "flink-connector-mongodb"; version = "1.2.0-1.19"; file = "flink-connector-mongodb-1.2.0-1.19.jar"; desc = "MongoDB Connector" }
    
    # CDC
    @{ group = "org/apache/flink"; artifact = "flink-connector-mysql-cdc"; version = "3.1.1"; file = "flink-connector-mysql-cdc-3.1.1.jar"; desc = "MySQL CDC Connector" }
    @{ group = "org/apache/flink"; artifact = "flink-connector-postgres-cdc"; version = "3.1.1"; file = "flink-connector-postgres-cdc-3.1.1.jar"; desc = "PostgreSQL CDC Connector" }
    
    # Storage
    @{ group = "org/apache/flink"; artifact = "flink-s3-fs-hadoop"; version = "1.19.1"; file = "flink-s3-fs-hadoop-1.19.1.jar"; desc = "S3 Filesystem (Hadoop)" }
    
    # Search
    @{ group = "org/apache/flink"; artifact = "flink-sql-connector-elasticsearch7"; version = "3.0.1-1.17"; file = "flink-sql-connector-elasticsearch7-3.0.1-1.17.jar"; desc = "Elasticsearch 7 SQL Connector" }
    
    # Lakehouse
    @{ group = "org/apache/flink"; artifact = "flink-sql-connector-hive-3.1.3_2.12"; version = "1.19.1"; file = "flink-sql-connector-hive-3.1.3_2.12-1.19.1.jar"; desc = "Hive Connector" }
    @{ group = "org/apache/iceberg"; artifact = "iceberg-flink-runtime"; version = "1.5.2"; file = "iceberg-flink-runtime-1.5.2.jar"; desc = "Apache Iceberg Runtime" }
    
    # Formats
    @{ group = "org/apache/flink"; artifact = "flink-sql-avro"; version = "1.19.1"; file = "flink-sql-avro-1.19.1.jar"; desc = "Avro Format" }
    @{ group = "org/apache/flink"; artifact = "flink-sql-avro-confluent-registry"; version = "1.19.1"; file = "flink-sql-avro-confluent-registry-1.19.1.jar"; desc = "Avro Confluent Schema Registry" }
    @{ group = "org/apache/flink"; artifact = "flink-sql-json"; version = "1.19.1"; file = "flink-sql-json-1.19.1.jar"; desc = "JSON Format" }
    @{ group = "org/apache/flink"; artifact = "flink-sql-csv"; version = "1.19.1"; file = "flink-sql-csv-1.19.1.jar"; desc = "CSV Format" }
    @{ group = "org/apache/flink"; artifact = "flink-sql-parquet"; version = "1.19.1"; file = "flink-sql-parquet-1.19.1.jar"; desc = "Parquet Format" }
    @{ group = "org/apache/flink"; artifact = "flink-sql-orc"; version = "1.19.1"; file = "flink-sql-orc-1.19.1.jar"; desc = "ORC Format" }
    
    # Database Drivers
    @{ group = "org/postgresql"; artifact = "postgresql"; version = "42.7.3"; file = "postgresql-42.7.3.jar"; desc = "PostgreSQL JDBC Driver" }
    @{ group = "com/mysql"; artifact = "mysql-connector-j"; version = "8.3.0"; file = "mysql-connector-j-8.3.0.jar"; desc = "MySQL JDBC Driver" }
)

function Download-File {
    param($url, $dest, $desc)
    
    Write-Host "DOWNLOAD: $desc ..." -ForegroundColor Cyan
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell-Download-Script")
        $webClient.DownloadFile($url, $dest)
        
        if (Test-Path $dest) {
            $sizeMB = [math]::Round((Get-Item $dest).Length / 1MB, 2)
            Write-Host "OK: $sizeMB MB" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "FAILED: $_" -ForegroundColor DarkYellow
    }
    return $false
}

Write-Host ""
Write-Host "=== Flink Connector Downloader ===" -ForegroundColor Cyan
Write-Host "Target Flink Version: $FlinkVersion" -ForegroundColor Yellow
Write-Host "Target Directory: $ConnectorsDir" -ForegroundColor Yellow
Write-Host "Total Connectors: $($Connectors.Count)" -ForegroundColor Yellow
Write-Host ""

$downloaded = 0
$failed = 0
$skipped = 0

foreach ($connector in $Connectors) {
    $dest = Join-Path $ConnectorsDir $connector.file
    
    if (Test-Path $dest) {
        Write-Host "SKIP: $($connector.file) already exists" -ForegroundColor DarkYellow
        $skipped++
        continue
    }
    
    $success = $false
    
    # Try mirrors
    foreach ($mirror in $Mirrors) {
        $groupPath = $connector.group -replace '\.', '/'
        $url = "$mirror/$groupPath/$($connector.artifact)/$($connector.version)/$($connector.file)"
        
        if (Download-File -url $url -dest $dest -desc $connector.desc) {
            $success = $true
            $downloaded++
            break
        }
    }
    
    if (-not $success) {
        Write-Host "ERROR: Failed to download $($connector.file)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "=== Download Summary ===" -ForegroundColor Cyan
Write-Host "Downloaded: $downloaded" -ForegroundColor Green
Write-Host "Already existed: $skipped" -ForegroundColor Yellow
if ($failed -gt 0) { Write-Host "Failed: $failed" -ForegroundColor Red }

Write-Host ""
Write-Host "=== Connectors in $ConnectorsDir ===" -ForegroundColor Cyan
Get-ChildItem $ConnectorsDir -Filter "*.jar" -ErrorAction SilentlyContinue | 
    Sort-Object Name |
    Format-Table Name, @{n="Size(MB)";e={[math]::Round($_.Length/1MB, 2)}} -AutoSize

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Rebuild Flink containers:" -ForegroundColor White
Write-Host "   docker compose down" -ForegroundColor Yellow
Write-Host "   docker compose build --no-cache" -ForegroundColor Yellow
Write-Host "   docker compose up -d" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Verify connectors are loaded:" -ForegroundColor White
Write-Host "   docker exec codedstream-taskmanager ls -la /opt/flink/lib/ | wc -l" -ForegroundColor Yellow
Write-Host ""