$script:QueueRoot = Join-Path (Join-Path $PSScriptRoot '..') 'queue' | Resolve-Path -ErrorAction SilentlyContinue

if (-not $script:QueueRoot) {
    $script:QueueRoot = Join-Path (Join-Path $PSScriptRoot '..') 'queue'
}

function Get-CurrentQuarter {
    $now = Get-Date
    $q = [Math]::Ceiling($now.Month / 3)
    return "$($now.Year)-Q$q"
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return @{ version = 1; items = @() }
    }
    $raw = Get-Content $Path -Raw -Encoding UTF8
    return $raw | ConvertFrom-Json
}

function Write-JsonFile {
    param([string]$Path, [object]$Data)
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $json = $Data | ConvertTo-Json -Depth 10
    Set-Content -Path $Path -Value $json -Encoding UTF8 -NoNewline
}

function Get-QueuePending {
    $path = Join-Path $script:QueueRoot 'pending.json'
    $data = Read-JsonFile $path
    return @($data.items)
}

function Get-QueueInFlight {
    $path = Join-Path $script:QueueRoot 'in_flight.json'
    $data = Read-JsonFile $path
    return @($data.items)
}

function Get-QueueDone {
    param([string]$Quarter)
    $doneDir = Join-Path $script:QueueRoot 'done'
    if (-not (Test-Path $doneDir)) { return @() }
    if ($Quarter) {
        $path = Join-Path $doneDir "$Quarter.json"
        $data = Read-JsonFile $path
        return @($data.items)
    }
    $allItems = [System.Collections.ArrayList]::new()
    Get-ChildItem $doneDir -Filter '*.json' | ForEach-Object {
        $data = Read-JsonFile $_.FullName
        foreach ($item in $data.items) { [void]$allItems.Add($item) }
    }
    return @($allItems)
}

function Get-QueueAbandoned {
    param([string]$Quarter)
    $abDir = Join-Path $script:QueueRoot 'abandoned'
    if (-not (Test-Path $abDir)) { return @() }
    if ($Quarter) {
        $path = Join-Path $abDir "$Quarter.json"
        $data = Read-JsonFile $path
        return @($data.items)
    }
    $allItems = [System.Collections.ArrayList]::new()
    Get-ChildItem $abDir -Filter '*.json' | ForEach-Object {
        $data = Read-JsonFile $_.FullName
        foreach ($item in $data.items) { [void]$allItems.Add($item) }
    }
    return @($allItems)
}

function Add-QueueInFlight {
    param([hashtable]$Item)
    $path = Join-Path $script:QueueRoot 'in_flight.json'
    $data = Read-JsonFile $path
    $items = [System.Collections.ArrayList]::new()
    foreach ($existing in $data.items) { [void]$items.Add($existing) }
    [void]$items.Add([PSCustomObject]$Item)
    $data = @{ version = 1; items = $items }
    Write-JsonFile -Path $path -Data $data
}

function Remove-QueueInFlight {
    param([string]$RunId)
    $path = Join-Path $script:QueueRoot 'in_flight.json'
    $data = Read-JsonFile $path
    $items = [System.Collections.ArrayList]::new()
    foreach ($item in $data.items) {
        if ($item.run_id -ne $RunId) { [void]$items.Add($item) }
    }
    $data = @{ version = 1; items = $items }
    Write-JsonFile -Path $path -Data $data
}

function Add-QueueDone {
    param([hashtable]$Item)
    $quarter = Get-CurrentQuarter
    $path = Join-Path (Join-Path $script:QueueRoot 'done') "$quarter.json"
    $data = Read-JsonFile $path
    $items = [System.Collections.ArrayList]::new()
    foreach ($existing in $data.items) { [void]$items.Add($existing) }
    [void]$items.Add([PSCustomObject]$Item)
    $data = @{ version = 1; items = $items }
    Write-JsonFile -Path $path -Data $data
}

function Add-QueueAbandoned {
    param([hashtable]$Item)
    $quarter = Get-CurrentQuarter
    $path = Join-Path (Join-Path $script:QueueRoot 'abandoned') "$quarter.json"
    $data = Read-JsonFile $path
    $items = [System.Collections.ArrayList]::new()
    foreach ($existing in $data.items) { [void]$items.Add($existing) }
    [void]$items.Add([PSCustomObject]$Item)
    $data = @{ version = 1; items = $items }
    Write-JsonFile -Path $path -Data $data
}

function Add-QueueClosed {
    param([hashtable]$Item)
    $quarter = Get-CurrentQuarter
    $path = Join-Path (Join-Path $script:QueueRoot 'closed') "$quarter.json"
    $data = Read-JsonFile $path
    $items = [System.Collections.ArrayList]::new()
    foreach ($existing in $data.items) { [void]$items.Add($existing) }
    [void]$items.Add([PSCustomObject]$Item)
    $data = @{ version = 1; items = $items }
    Write-JsonFile -Path $path -Data $data
}

function Get-QueueClosed {
    param([string]$Quarter)
    $closedDir = Join-Path $script:QueueRoot 'closed'
    if (-not (Test-Path $closedDir)) { return @() }
    if ($Quarter) {
        $path = Join-Path $closedDir "$Quarter.json"
        $data = Read-JsonFile $path
        return @($data.items)
    }
    $allItems = [System.Collections.ArrayList]::new()
    Get-ChildItem $closedDir -Filter '*.json' | ForEach-Object {
        $data = Read-JsonFile $_.FullName
        foreach ($item in $data.items) { [void]$allItems.Add($item) }
    }
    return @($allItems)
}

function Update-QueueGate {
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Gate
    )
    $path = Join-Path $script:QueueRoot 'in_flight.json'
    $data = Read-JsonFile $path
    $found = $false
    $items = [System.Collections.ArrayList]::new()
    foreach ($item in $data.items) {
        if ($item.run_id -eq $RunId) {
            $found = $true
            $item.current_gate = $Gate
        }
        [void]$items.Add($item)
    }
    if (-not $found) {
        Write-Error "RunId '$RunId' not found in in_flight queue"
        exit 1
    }
    $data = @{ version = 1; items = $items }
    Write-JsonFile -Path $path -Data $data

    $runsRoot = Join-Path (Join-Path $PSScriptRoot '..') 'runs'
    $logPath = Join-Path (Join-Path $runsRoot $RunId) 'log.md'
    if (Test-Path $logPath) {
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm'
        $entry = "$ts | event=gate_updated | gate=$Gate"
        Add-Content -Path $logPath -Value $entry -Encoding UTF8
    }
}

function Remove-QueueClosed {
    param([string]$RunId)
    $closedDir = Join-Path $script:QueueRoot 'closed'
    if (-not (Test-Path $closedDir)) { return }
    Get-ChildItem $closedDir -Filter '*.json' | ForEach-Object {
        $data = Read-JsonFile $_.FullName
        $filtered = [System.Collections.ArrayList]::new()
        $changed = $false
        foreach ($item in $data.items) {
            if ($item.run_id -eq $RunId) { $changed = $true }
            else { [void]$filtered.Add($item) }
        }
        if ($changed) {
            $data = @{ version = 1; items = $filtered }
            Write-JsonFile -Path $_.FullName -Data $data
        }
    }
}
