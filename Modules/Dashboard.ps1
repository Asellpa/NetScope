function Show-NetScopeConnectionDashboard {
    param (
        [array]$Connections
    )

    Clear-Host

    Write-Host "============================================================"
    Write-Host "                  NetScope Connection Dashboard"
    Write-Host "============================================================"
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""

    Write-Host "Applications"
    Write-Host "------------------------------------------------------------"

    $AppSummary = $Connections |
        Group-Object Process |
        Sort-Object Count -Descending

    foreach ($App in $AppSummary) {
        Write-Host ("{0,-25} {1,5} connections" -f $App.Name, $App.Count)
    }

    Write-Host ""
    Write-Host "Providers"
    Write-Host "------------------------------------------------------------"

    $ProviderSummary = $Connections |
        Group-Object Provider |
        Sort-Object Count -Descending

    foreach ($Provider in $ProviderSummary) {
        Write-Host ("{0,-25} {1,5} connections" -f $Provider.Name, $Provider.Count)
    }

    Write-Host ""
    Write-Host "Categories"
    Write-Host "------------------------------------------------------------"

    $CategorySummary = $Connections |
        Group-Object Category |
        Sort-Object Count -Descending

    foreach ($Category in $CategorySummary) {
        Write-Host ("{0,-25} {1,5} connections" -f $Category.Name, $Category.Count)
    }

    Write-Host ""
    Write-Host "Top Connections"
    Write-Host "------------------------------------------------------------"

    $Connections |
        Select-Object Process, Provider, Category, RemoteAddress, RemotePort |
        Sort-Object Process, Provider |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host "============================================================"
    Write-Host ("Total Applications : {0}" -f ($AppSummary.Count))
    Write-Host ("Total Connections  : {0}" -f ($Connections.Count))
    Write-Host "============================================================"
}