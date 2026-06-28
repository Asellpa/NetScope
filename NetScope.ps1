# NetScope
# Main Orchestrator

$BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesPath = Join-Path $BasePath "Modules"
$ConfigPath = Join-Path $BasePath "Config.json"
$ProviderFile = Join-Path $BasePath "Data\Providers.json"

. "$ModulesPath\ModuleLoader.ps1"
Import-NetScopeModules -ModulesPath $ModulesPath

if (!(Test-Path $ConfigPath)) {
    Write-Host "Config.json not found." -ForegroundColor Red
    exit
}

if (!(Test-Path $ProviderFile)) {
    Write-Host "Providers.json not found." -ForegroundColor Red
    exit
}

$Config = Get-Content $ConfigPath | ConvertFrom-Json
$Interval = [int]$Config.IntervalSeconds

Write-Host "NetScope started. Press Ctrl + C to stop." -ForegroundColor Cyan
Start-Sleep 1

try {
    while ($true) {
        $Connections = Get-NetScopeConnections -ProviderFile $ProviderFile
        Show-NetScopeConnectionDashboard -Connections $Connections

        Start-Sleep -Seconds $Interval
    }
}
finally {
    Clear-Host
    Write-Host "NetScope stopped." -ForegroundColor Cyan
}