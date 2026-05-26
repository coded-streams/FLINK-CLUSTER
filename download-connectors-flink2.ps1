# download-connectors-flink2.ps1

param(
    [string]$ConnectorsDir = ".\connectors"
)

if (-not (Test-Path $ConnectorsDir)) {
    New-Item -ItemType Directory -Path $ConnectorsDir -Force | Out-Null
}

$Maven = "https://repo1.maven.apache.org/maven2"

$Connectors = @(

    # Kafka connector — correct for Flink 2.0
    @{
        url  = "$Maven/org/apache/flink/flink-sql-connector-kafka/4.0.1-2.0/flink-sql-connector-kafka-4.0.1-2.0.jar"
        name = "flink-sql-connector-kafka-4.0.1-2.0.jar"
        desc = "Kafka SQL Connector"
    }

    # JDBC connector
    @{
        url  = "$Maven/org/apache/flink/flink-connector-jdbc/3.3.0-1.20/flink-connector-jdbc-3.3.0-1.20.jar"
        name = "flink-connector-jdbc-3.3.0-1.20.jar"
        desc = "JDBC Connector"
    }

    # Postgres JDBC Driver
    @{
        url  = "$Maven/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar"
        name = "postgresql-42.7.3.jar"
        desc = "PostgreSQL Driver"
    }

    # MySQL JDBC Driver
    @{
        url  = "$Maven/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar"
        name = "mysql-connector-j-8.3.0.jar"
        desc = "MySQL Driver"
    }
)

Write-Host ""
Write-Host "=== Flink 2.0 Connector Downloader ===" -ForegroundColor Cyan
Write-Host ""

$downloaded = 0
$failed = 0
$skipped = 0

foreach ($c in $Connectors) {

    $dest = Join-Path $ConnectorsDir $c.name

    if (Test-Path $dest) {
        Write-Host "[SKIP] $($c.name)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    Write-Host "[DOWNLOAD] $($c.desc)" -ForegroundColor Cyan

    try {
        Invoke-WebRequest `
            -Uri $c.url `
            -OutFile $dest `
            -UseBasicParsing `
            -ErrorAction Stop

        if ((Get-Item $dest).Length -gt 10000) {
            Write-Host "[OK] $($c.name)" -ForegroundColor Green
            $downloaded++
        }
        else {
            Remove-Item $dest -Force
            throw "Downloaded file invalid"
        }

    }
    catch {
        Write-Host "[FAILED] $($c.name)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "Downloaded : $downloaded"
Write-Host "Skipped    : $skipped"
Write-Host "Failed     : $failed"
Write-Host ""

Get-ChildItem $ConnectorsDir -Filter "*.jar" |
Sort-Object Name |
Format-Table Name,
@{Label="MB";Expression={[math]::Round($_.Length/1MB,2)}} -AutoSize