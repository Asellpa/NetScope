function Get-NetScopeProvider {
    param (
        [string]$IPAddress,
        [string]$ProviderFile
    )

    if (!(Test-Path $ProviderFile)) {
        return "Unknown"
    }

    $Providers = Get-Content $ProviderFile | ConvertFrom-Json

    foreach ($Provider in $Providers.PSObject.Properties) {
        foreach ($Prefix in $Provider.Value) {
            if ($IPAddress.StartsWith($Prefix)) {
                return $Provider.Name
            }
        }
    }

    return "Unknown"
}