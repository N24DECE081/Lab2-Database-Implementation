$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
& docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw 'Deployment failed' }
& powershell -ExecutionPolicy Bypass -File scripts/import-sample.ps1
if ($LASTEXITCODE -ne 0) { throw 'External sample verification failed' }
& docker compose --profile test run --rm tests
if ($LASTEXITCODE -ne 0) { throw 'MySQL tests failed' }
& docker compose exec -T api python -m app.cli list-students
if ($LASTEXITCODE -ne 0) { throw 'Python database read failed' }
$port = if ($env:API_PORT) { $env:API_PORT } else { '8001' }
if (Test-Path '.env') {
    $line = Get-Content '.env' | Where-Object { $_ -match '^API_PORT=\d+$' } | Select-Object -Last 1
    if ($line -and -not $env:API_PORT) { $port = $line.Split('=')[1] }
}
$ready = Invoke-RestMethod -Uri "http://localhost:$port/ready"
if ($ready.database -ne 'connected') { throw 'Database readiness failed' }
Write-Output "Labs verified. Swagger: http://localhost:$port/docs"
