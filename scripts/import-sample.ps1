$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$externalDir = Join-Path $projectRoot 'data\external'
$archive = Join-Path $externalDir 'sakila-db.zip'
$expanded = Join-Path $externalDir 'sakila-db'
$schemaFile = Join-Path $expanded 'sakila-schema.sql'
$dataFile = Join-Path $expanded 'sakila-data.sql'
$rootPassword = $env:MYSQL_ROOT_PASSWORD
if (-not $rootPassword -and (Test-Path -LiteralPath '.env')) {
    $line = Get-Content '.env' | Where-Object { $_ -match '^MYSQL_ROOT_PASSWORD=' } | Select-Object -Last 1
    if ($line) { $rootPassword = $line.Substring('MYSQL_ROOT_PASSWORD='.Length) }
}
if (-not $rootPassword) { $rootPassword = 'mysql_dev' }

if (-not (Test-Path -LiteralPath $schemaFile) -or -not (Test-Path -LiteralPath $dataFile)) {
    try {
        if (-not (Test-Path -LiteralPath $archive)) {
            Invoke-WebRequest -Uri 'https://downloads.mysql.com/docs/sakila-db.zip' -OutFile $archive
        }
        Expand-Archive -LiteralPath $archive -DestinationPath $externalDir -Force
    }
    catch {
        # Oracle's download CDN can be temporarily unavailable.  The fallback
        # is a public mirror of the original MySQL Sakila scripts.
        Write-Warning 'Official Sakila ZIP is unavailable; using the SQL mirror.'
        New-Item -ItemType Directory -Force -Path $expanded | Out-Null
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jOOQ/sakila/main/mysql-sakila-db/mysql-sakila-schema.sql' -OutFile $schemaFile
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jOOQ/sakila/main/mysql-sakila-db/mysql-sakila-insert-data.sql' -OutFile $dataFile
    }
}

if (-not (Test-Path -LiteralPath $schemaFile) -or -not (Test-Path -LiteralPath $dataFile)) {
    throw 'Sakila schema/data SQL files could not be downloaded.'
}

docker compose cp $schemaFile mysql:/tmp/sakila-schema.sql
if ($LASTEXITCODE -ne 0) { throw 'Copying Sakila schema failed' }
docker compose cp $dataFile mysql:/tmp/sakila-data.sql
if ($LASTEXITCODE -ne 0) { throw 'Copying Sakila data failed' }
docker compose cp 'sql/07_external_sample_queries.sql' mysql:/tmp/external_queries.sql
if ($LASTEXITCODE -ne 0) { throw 'Copying sample queries failed' }

$sakilaExists = docker compose exec -T -e "MYSQL_PWD=$rootPassword" mysql mysql -N -uroot -e 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = CHAR(115,97,107,105,108,97)'
if ($LASTEXITCODE -ne 0) { throw 'Checking Sakila database failed' }
if ($sakilaExists -ne 'sakila') {
    docker compose exec -T -e "MYSQL_PWD=$rootPassword" mysql sh -c 'mysql -uroot < /tmp/sakila-schema.sql'
    if ($LASTEXITCODE -ne 0) { throw 'Creating Sakila schema failed' }
    docker compose exec -T -e "MYSQL_PWD=$rootPassword" mysql sh -c 'mysql -uroot < /tmp/sakila-data.sql'
    if ($LASTEXITCODE -ne 0) { throw 'Importing Sakila data failed' }
}
docker compose exec -T -e "MYSQL_PWD=$rootPassword" mysql sh -c 'mysql -uroot sakila < /tmp/external_queries.sql'
if ($LASTEXITCODE -ne 0) { throw 'Running Sakila queries failed' }

Write-Output 'Sakila sample imported and queried successfully.'
