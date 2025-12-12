####################################################################################
# Put custom attribute with name "Capacité Batterie" Tu have result in general tab #
####################################################################################
try {
    $xmlPath = "$env:TEMP\battery-report.xml"
    powercfg /batteryreport /output $xmlPath /xml > $null

    if (-not (Test-Path $xmlPath)) {
        throw "Impossible de générer le rapport batterie."
    }

    [xml]$xml = Get-Content $xmlPath

    $battery = $xml.BatteryReport.Batteries.Battery
    if (-not $battery) {
        throw "Aucune batterie détectée."
    }

    $design = [double]$battery.DesignCapacity
    $full   = [double]$battery.FullChargeCapacity

    if ($design -gt 0 -and $full -gt 0) {
        $percent = [math]::Round(($full / $design) * 100, 2)
        Action1-Set-CustomAttribute "Capacité Batterie" "$percent %"
        exit 0
    } else {
        throw "Valeurs non disponibles."
    }
}
catch {
    Action1-Set-CustomAttribute "Capacité Batterie" "N/A"
    exit 1
}
