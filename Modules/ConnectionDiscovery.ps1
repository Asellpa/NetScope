function Get-NetScopeConnections {
    param (
        [string]$ProviderFile
    )

    $Timestamp = Get-Date

    $Connections = Get-NetTCPConnection |
        Where-Object {
            $_.State -eq "Established" -and
            $_.RemoteAddress -ne "127.0.0.1" -and
            $_.RemoteAddress -ne "::1" -and
            $_.RemoteAddress -ne "0.0.0.0" -and
            $_.RemoteAddress -ne "::"
        }

    foreach ($Connection in $Connections) {
        $ProcessName = "Unknown"

        try {
            $Process = Get-Process -Id $Connection.OwningProcess -ErrorAction Stop
            $ProcessName = $Process.ProcessName
        }
        catch {
            $ProcessName = "Unknown"
        }

        $ProviderInfo = Get-NetScopeProviderInfo -IPAddress $Connection.RemoteAddress -ProviderFile $ProviderFile

        [PSCustomObject]@{
            Timestamp     = $Timestamp
            Process       = $ProcessName
            PID           = $Connection.OwningProcess
            Protocol      = "TCP"
            State         = $Connection.State
            LocalAddress  = $Connection.LocalAddress
            LocalPort     = $Connection.LocalPort
            RemoteAddress = $Connection.RemoteAddress
            RemotePort    = $Connection.RemotePort
            Provider      = $ProviderInfo.Provider
            Category      = $ProviderInfo.Category
            Country       = $null
            ASN           = $null
            LatencyMs     = $null
            PacketLoss    = $null
        }
    }
}