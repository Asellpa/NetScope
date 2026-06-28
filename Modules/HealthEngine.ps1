function Test-NetScopeHealth {
    param (
        [array]$Targets
    )

    $Results = @{}

    foreach ($Target in $Targets) {
        $Ping = Test-Connection -ComputerName $Target.Address -Count 1 -ErrorAction SilentlyContinue

        $Results[$Target.Name] = [PSCustomObject]@{
            Name      = $Target.Name
            Address   = $Target.Address
            Online    = ($Ping -and $Ping.StatusCode -eq 0)
            LatencyMs = if ($Ping -and $Ping.StatusCode -eq 0) { [int]$Ping.ResponseTime } else { $null }
        }
    }

    $RouterOK = $Results["Router"].Online
    $GatewayOK = $Results["ISP Gateway"].Online
    $CloudflareOK = $Results["Cloudflare"].Online
    $GoogleOK = $Results["Google DNS"].Online

    if (-not $RouterOK) {
        $Status = "Local Issue"
        $Message = "Router is unreachable. Possible Ethernet, Wi-Fi, NIC, router LAN, or router reboot issue."
        $Severity = "Critical"
    }
    elseif ($RouterOK -and -not $GatewayOK) {
        $Status = "ISP Access Issue"
        $Message = "Router is reachable, but ISP gateway is unreachable. Possible PPPoE, fiber, or ISP access network issue."
        $Severity = "Critical"
    }
    elseif ($RouterOK -and $GatewayOK -and -not $CloudflareOK -and -not $GoogleOK) {
        $Status = "Upstream Issue"
        $Message = "ISP gateway is reachable, but public internet targets are unreachable. Possible ISP upstream/routing issue."
        $Severity = "Warning"
    }
    else {
        $Status = "Healthy"
        $Message = "No current network health issue detected."
        $Severity = "OK"
    }

    return [PSCustomObject]@{
        Timestamp = Get-Date
        Status    = $Status
        Severity  = $Severity
        Message   = $Message
        Results   = $Results
    }
}