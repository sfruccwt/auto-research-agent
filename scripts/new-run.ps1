param(
    [Parameter(Mandatory)]
    [string]$IdeaPath,

    [switch]$Force
)

. "$PSScriptRoot/queue.ps1"

# Step 1: Validate IdeaPath
if (-not (Test-Path $IdeaPath) -or -not $IdeaPath.EndsWith('.md')) {
    Write-Error "IdeaPath does not exist or is not a .md file: $IdeaPath"
    exit 1
}

# Step 2: Derive run_id from idea filename
$ideaBasename = [System.IO.Path]::GetFileNameWithoutExtension($IdeaPath)
$runId = $ideaBasename

# Step 3: Check done records
$doneItems = Get-QueueDone
$alreadyDone = $doneItems | Where-Object { $_.idea_slug -eq $ideaBasename }

if ($alreadyDone) {
    if (-not $Force) {
        Write-Error "Idea '$ideaBasename' has already been delivered. Use -Force to create a rerun."
        exit 3
    }
    # Find next available rerun suffix
    $runsRoot = Join-Path $PSScriptRoot '..' 'runs'
    $n = 2
    while (Test-Path (Join-Path $runsRoot "$ideaBasename-rerun-$n")) { $n++ }
    $runId = "$ideaBasename-rerun-$n"
}

# Step 4: Create run directory structure
$runsRoot = Join-Path $PSScriptRoot '..' 'runs'
$runDir = Join-Path $runsRoot $runId
New-Item -ItemType Directory -Path $runDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $runDir 'notes') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $runDir 'sources') -Force | Out-Null

# Step 5: Freeze idea snapshot
Copy-Item -Path $IdeaPath -Destination (Join-Path $runDir 'idea.md')

# Step 6: Initialize log.md
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$logLine = "$timestamp | event=run_init | idea=$([System.IO.Path]::GetFileName($IdeaPath))"
Set-Content -Path (Join-Path $runDir 'log.md') -Value $logLine -Encoding UTF8

# Step 7: Add to in_flight queue
$now = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
Add-QueueInFlight -Item @{
    run_id     = $runId
    idea_slug  = $ideaBasename
    started    = $now
    current_gate = 'opening'
}

# Step 8: Output run directory path
$resolvedPath = (Resolve-Path $runDir).Path
Write-Output $resolvedPath
