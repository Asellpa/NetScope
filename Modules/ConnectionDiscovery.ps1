function Get-NetScopeConnections {
    param (
        [string]$ProviderFile
    )

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

        $Provider = Get-NetScopeProvider -IPAddress $Connection.RemoteAddress -ProviderFile $ProviderFile

        [PSCustomObject]@{
            Process       = $ProcessName
            PID           = $Connection.OwningProcess
            LocalAddress  = $Connection.LocalAddress
            LocalPort     = $Connection.LocalPort
            RemoteAddress = $Connection.RemoteAddress
            RemotePort    = $Connection.RemotePort
            State         = $Connection.State
            Provider      = $Provider
        }
    }
}