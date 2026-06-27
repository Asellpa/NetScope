function Get-NetScopeProviderInfo {
    param (
        [string]$IPAddress,
        [string]$ProviderFile
    )

    if (!(Test-Path $ProviderFile)) {
        return [PSCustomObject]@{
            Provider = "Unknown"
            Category = "Unknown"
        }
    }

    $Providers = Get-Content $ProviderFile | ConvertFrom-Json

    foreach ($Provider in $Providers.PSObject.Properties) {
        foreach ($Prefix in $Provider.Value.Prefixes) {
            if ($IPAddress.StartsWith($Prefix)) {
                return [PSCustomObject]@{
                    Provider = $Provider.Name
                    Category = $Provider.Value.Category
                }
            }
        }
    }

    return [PSCustomObject]@{
        Provider = "Unknown"
        Category = "Unknown"
    }
}

function Get-NetScopeProvider {
    param (
        [string]$IPAddress,
        [string]$ProviderFile
    )

    $Info = Get-NetScopeProviderInfo -IPAddress $IPAddress -ProviderFile $ProviderFile
    return $Info.Provider
}