# Network Monitor v8.0
# Dashboard + Logs + Events + Traceroute + HTML Report
# Windows PowerShell 5.1 compatible

$BasePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $BasePath "Config.json"
$LogFolder = Join-Path $BasePath "Logs"
$TraceFolder = Join-Path $LogFolder "Traceroutes"
$ReportFolder = Join-Path $BasePath "Reports"
$PingLog = Join-Path $LogFolder "PingLog.csv"
$EventLog = Join-Path $LogFolder "EventLog.csv"
$ReportFile = Join-Path $ReportFolder "NetworkReport.html"

foreach ($Folder in @($LogFolder, $TraceFolder, $ReportFolder)) {
    if (!(Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder | Out-Null
    }
}

if (!(Test-Path $ConfigPath)) {
    Write-Host "Config.json not found." -ForegroundColor Red
    exit
}

if (!(Test-Path $PingLog)) {
    "Timestamp,Target,Address,Status,LatencyMs,Sent,Received,LossPercent,JitterMs" | Out-File $PingLog
}

if (!(Test-Path $EventLog)) {
    "Timestamp,EventType,Target,Message" | Out-File $EventLog
}

$Config = Get-Content $ConfigPath | ConvertFrom-Json
$Targets = $Config.Targets
$Interval = [int]$Config.IntervalSeconds
$Stats = @{}
$StartTime = Get-Date

foreach ($Target in $Targets) {
    $Stats[$Target.Name] = @{
        Sent = 0; Received = 0; TotalLatency = 0; MaxLatency = 0
        LastLatency = "-"; PreviousLatency = $null; Jitter = 0
        LastStatus = "UNKNOWN"; PreviousStatus = "UNKNOWN"; Loss = 0
    }
}

function Start-TraceRoute {
    param ([string]$TargetName, [string]$Address)

    $SafeName = $TargetName -replace " ", "_"
    $TimeName = Get-Date -Format "yyyyMMdd_HHmmss"
    $TraceFile = Join-Path $TraceFolder "$TimeName`_$SafeName`_$Address.txt"

    "Traceroute started at $(Get-Date)" | Out-File $TraceFile
    "Target: $TargetName ($Address)" | Out-File $TraceFile -Append
    "" | Out-File $TraceFile -Append
    tracert -d $Address | Out-File $TraceFile -Append

    return $TraceFile
}

function Generate-Report {
    if (!(Test-Path $PingLog)) { return }

    $PingData = Import-Csv $PingLog
    $EventData = @()

    if (Test-Path $EventLog) {
        $EventData = Import-Csv $EventLog
    }

    $Rows = foreach ($Group in ($PingData | Group-Object Target)) {
        $Items = $Group.Group
        $Online = @($Items | Where-Object { $_.Status -eq "ONLINE" })
        $Failed = @($Items | Where-Object { $_.Status -eq "FAILED" })
        $Latencies = @($Online | Where-Object { $_.LatencyMs -ne "" } | ForEach-Object { [int]$_.LatencyMs })

        if ($Latencies.Count -gt 0) {
            $AvgLatency = [math]::Round(($Latencies | Measure-Object -Average).Average, 2)
            $MaxLatency = ($Latencies | Measure-Object -Maximum).Maximum
        }
        else {
            $AvgLatency = "N/A"
            $MaxLatency = "N/A"
        }

        [PSCustomObject]@{
            Target = $Group.Name
            Samples = $Items.Count
            Online = $Online.Count
            Failed = $Failed.Count
            LossPercent = [math]::Round(($Failed.Count / $Items.Count) * 100, 2)
            AvgLatencyMs = $AvgLatency
            MaxLatencyMs = $MaxLatency
        }
    }

    $SummaryHtml = $Rows | ConvertTo-Html -Fragment
    $EventsHtml = $EventData | Select-Object Timestamp,EventType,Target,Message | ConvertTo-Html -Fragment

    $Html = @"
<html>
<head>
<title>Network Monitor Report</title>
<style>
body { font-family: Arial; background: #111827; color: #e5e7eb; padding: 30px; }
h1, h2 { color: #38bdf8; }
table { border-collapse: collapse; width: 100%; margin-bottom: 30px; }
th { background: #1f2937; color: #ffffff; }
td, th { border: 1px solid #374151; padding: 8px; text-align: left; }
tr:nth-child(even) { background: #1f2937; }
.card { background: #0f172a; padding: 15px; border: 1px solid #334155; margin-bottom: 20px; border-radius: 8px; }
</style>
</head>
<body>
<h1>Network Monitor Report</h1>

<div class="card">
<p><b>Generated:</b> $(Get-Date)</p>
<p><b>Session Runtime:</b> $((Get-Date) - $StartTime)</p>
<p><b>Ping Log:</b> $PingLog</p>
<p><b>Event Log:</b> $EventLog</p>
<p><b>Traceroutes:</b> $TraceFolder</p>
</div>

<h2>Target Summary</h2>
$SummaryHtml

<h2>Event History</h2>
$EventsHtml

</body>
</html>
"@

    $Html | Out-File $ReportFile -Encoding UTF8
}

Write-Host "Network Monitor v8.0 started. Press Ctrl + C to stop." -ForegroundColor Cyan
Start-Sleep 1
Clear-Host

try {
    while ($true) {
        [Console]::SetCursorPosition(0, 0)
        $Results = @{}
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        foreach ($Target in $Targets) {
            $Name = $Target.Name
            $Address = $Target.Address

            $Stats[$Name].Sent++
            $Stats[$Name].PreviousStatus = $Stats[$Name].LastStatus

            $Ping = Test-Connection -ComputerName $Address -Count 1 -ErrorAction SilentlyContinue

            if ($Ping -and $Ping.StatusCode -eq 0) {
                $Latency = [int]$Ping.ResponseTime

                if ($Stats[$Name].PreviousLatency -ne $null) {
                    $Stats[$Name].Jitter = [math]::Abs($Latency - $Stats[$Name].PreviousLatency)
                }

                $Stats[$Name].PreviousLatency = $Latency
                $Stats[$Name].Received++
                $Stats[$Name].TotalLatency += $Latency
                $Stats[$Name].LastLatency = $Latency
                $Stats[$Name].LastStatus = "ONLINE"

                if ($Latency -gt $Stats[$Name].MaxLatency) {
                    $Stats[$Name].MaxLatency = $Latency
                }

                $Results[$Name] = $true
            }
            else {
                $Stats[$Name].LastLatency = "-"
                $Stats[$Name].LastStatus = "FAILED"
                $Results[$Name] = $false
            }

            $Sent = $Stats[$Name].Sent
            $Received = $Stats[$Name].Received
            $Stats[$Name].Loss = [math]::Round((($Sent - $Received) / $Sent) * 100, 2)

            if ($Stats[$Name].LastStatus -eq "ONLINE") {
                "$Timestamp,$Name,$Address,ONLINE,$($Stats[$Name].LastLatency),$Sent,$Received,$($Stats[$Name].Loss),$($Stats[$Name].Jitter)" | Out-File $PingLog -Append
            }
            else {
                "$Timestamp,$Name,$Address,FAILED,,$Sent,$Received,$($Stats[$Name].Loss),$($Stats[$Name].Jitter)" | Out-File $PingLog -Append
            }

            if ($Stats[$Name].PreviousStatus -ne "UNKNOWN" -and $Stats[$Name].PreviousStatus -ne $Stats[$Name].LastStatus) {
                if ($Stats[$Name].LastStatus -eq "FAILED") {
                    "$Timestamp,DOWN,$Name,$Name changed from ONLINE to FAILED" | Out-File $EventLog -Append

                    if ($Name -ne "Router") {
                        $TraceFile = Start-TraceRoute -TargetName $Name -Address $Address
                        "$Timestamp,TRACEROUTE,$Name,Traceroute saved to $TraceFile" | Out-File $EventLog -Append
                    }
                }

                if ($Stats[$Name].LastStatus -eq "ONLINE") {
                    "$Timestamp,UP,$Name,$Name recovered from FAILED to ONLINE" | Out-File $EventLog -Append
                }
            }
        }

        $RouterOK = $Results["Router"]
        $ISPGatewayOK = $Results["ISP Gateway"]
        $CloudflareOK = $Results["Cloudflare"]
        $GoogleOK = $Results["Google DNS"]
        $GameOK = $Results["Game Server"]

        if (-not $RouterOK) {
            $Diagnosis = "LOCAL ISSUE: PC to router failed. Check Ethernet cable, LAN port, NIC, or router."
            $DiagnosisColor = "Red"
        }
        elseif ($RouterOK -and -not $ISPGatewayOK) {
            $Diagnosis = "ISP ACCESS ISSUE: Router OK but ISP gateway failed. Possible PPPoE/fiber/ISP issue."
            $DiagnosisColor = "Red"
        }
        elseif ($RouterOK -and $ISPGatewayOK -and -not $CloudflareOK -and -not $GoogleOK) {
            $Diagnosis = "UPSTREAM ISSUE: ISP gateway OK but public internet failed."
            $DiagnosisColor = "Yellow"
        }
        elseif ($RouterOK -and $ISPGatewayOK -and $CloudflareOK -and $GoogleOK -and -not $GameOK) {
            $Diagnosis = "DESTINATION ISSUE: Only game server failed."
            $DiagnosisColor = "Yellow"
        }
        else {
            $Diagnosis = "HEALTHY: No current connectivity issue detected."
            $DiagnosisColor = "Green"
        }

        Write-Host "===================================================================="
        Write-Host "                    Network Monitor v8.0"
        Write-Host "===================================================================="
        Write-Host ("Time: {0}    Runtime: {1}" -f $Timestamp, ((Get-Date) - $StartTime).ToString("hh\:mm\:ss"))
        Write-Host "===================================================================="
        Write-Host ("{0,-15} {1,-10} {2,8} {3,8} {4,8} {5,8} {6,8}" -f "Target","Status","Last","Avg","Max","Loss","Jitter")
        Write-Host "--------------------------------------------------------------------"

        foreach ($Target in $Targets) {
            $Name = $Target.Name
            $Received = $Stats[$Name].Received

            if ($Received -gt 0) {
                $Avg = [math]::Round($Stats[$Name].TotalLatency / $Received, 1)
            }
            else {
                $Avg = "-"
            }

            $Color = "Green"
            if ($Stats[$Name].LastStatus -eq "FAILED") { $Color = "Red" }
            elseif ($Stats[$Name].LastLatency -ne "-" -and $Stats[$Name].LastLatency -gt 100) { $Color = "Yellow" }

            Write-Host ("{0,-15} {1,-10} {2,6}ms {3,6}ms {4,6}ms {5,7}% {6,6}ms" -f `
                $Name,$Stats[$Name].LastStatus,$Stats[$Name].LastLatency,$Avg,
                $Stats[$Name].MaxLatency,$Stats[$Name].Loss,$Stats[$Name].Jitter
            ) -ForegroundColor $Color
        }

        Write-Host "===================================================================="
        Write-Host "Diagnosis: $Diagnosis" -ForegroundColor $DiagnosisColor
        Write-Host "Ping Log:  $PingLog"
        Write-Host "Event Log: $EventLog"
        Write-Host "Traces:    $TraceFolder"
        Write-Host "Report:    $ReportFile"
        Write-Host "===================================================================="
        Write-Host "Press Ctrl + C to stop.                                            "

        Start-Sleep -Seconds $Interval
    }
}
finally {
    Generate-Report
    Clear-Host

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host " Network Monitor stopped" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Logs saved to:"
    Write-Host "  $PingLog"
    Write-Host "  $EventLog"
    Write-Host "  $TraceFolder"
    Write-Host ""
    Write-Host "HTML Report:"
    Write-Host "  $ReportFile"
    Write-Host ""
    Write-Host "Session Runtime: $((Get-Date) - $StartTime)"
    Write-Host ""

    Start-Process $ReportFile
}