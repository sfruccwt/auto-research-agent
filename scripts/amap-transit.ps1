param(
    [Parameter(Mandatory)]
    [string]$Origin,

    [string]$Destination = "116.364709,39.908487",

    [string]$City = "010",

    [int]$Strategy = 0
)

$key = $env:AMAP_MAPS_API_KEY
if (-not $key) {
    $mcpJson = Get-Content "$env:USERPROFILE\.claude.json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
    $key = $mcpJson.mcpServers.amap.env.AMAP_MAPS_API_KEY
}
if (-not $key) {
    Write-Error "AMAP_MAPS_API_KEY not found"; exit 1
}

if ($Origin -notmatch '^\d') {
    $geoUrl = "https://restapi.amap.com/v3/geocode/geo?key=$key&address=$([uri]::EscapeDataString($Origin))&city=$City"
    $geoResp = Invoke-RestMethod -Uri $geoUrl -TimeoutSec 10
    if ($geoResp.status -ne "1" -or $geoResp.geocodes.Count -eq 0) {
        Write-Error "Geocode failed for: $Origin"; exit 2
    }
    $Origin = $geoResp.geocodes[0].location
}

$url = "https://restapi.amap.com/v3/direction/transit/integrated?key=$key&origin=$Origin&destination=$Destination&city=$City&strategy=$Strategy"
$resp = Invoke-RestMethod -Uri $url -TimeoutSec 10

if ($resp.status -ne "1" -or -not $resp.route.transits) {
    Write-Error "Transit query failed: $($resp.info)"; exit 3
}

$results = @()
foreach ($t in $resp.route.transits | Select-Object -First 3) {
    $totalMin = [math]::Round([int]$t.duration / 60, 1)
    $walkMin = [math]::Round([int]$t.walking_distance / 80, 1)  # ~80m/min walk speed
    $transitMin = $totalMin - $walkMin

    $lines = @()
    foreach ($seg in $t.segments) {
        if ($seg.bus.buslines) {
            foreach ($bl in $seg.bus.buslines) {
                $lines += $bl.name
            }
        }
    }

    $results += [PSCustomObject]@{
        TotalMin    = $totalMin
        TransitMin  = [math]::Round($transitMin, 1)
        WalkMin     = $walkMin
        WalkMeters  = [int]$t.walking_distance
        Lines       = ($lines -join " → ")
    }
}

$results | Format-Table -AutoSize
