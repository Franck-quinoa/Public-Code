$xmlPath = "$env:TEMP\battery-report.xml"
powercfg /batteryreport /output $xmlPath /xml > $null

[xml]$xml = Get-Content $xmlPath

$design = $xml.BatteryReport.Batteries.Battery.DesignCapacity
$full = $xml.BatteryReport.Batteries.Battery.FullChargeCapacity

if ($design -and $full -gt 0) {
    $percent = [math]::Round(($full / $design) * 100, 2)
    "$percent %"
} else {
    "Valeurs non disponibles"
}