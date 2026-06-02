param(
    [Parameter(Mandatory)]
    [string]$RunId,

    [string]$WikiRoot = 'D:/Personal LLM Wiki'
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/queue.ps1"

$runsRoot = Join-Path (Join-Path $PSScriptRoot '..') 'runs'
$runDir = Join-Path $runsRoot $RunId
$outputPath = Join-Path $runDir 'output.md'

# Step 1: Validate output.md exists and is non-empty
if (-not (Test-Path $outputPath)) {
    Write-Error "output.md not found in runs/$RunId/"
    exit 1
}
$content = Get-Content $outputPath -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($content)) {
    Write-Error "output.md is empty in runs/$RunId/"
    exit 1
}

# Step 2: Parse and validate frontmatter
$requiredFields = @('source', 'source_idea', 'captured', 'route', 'route_reason', 'status')
$frontmatter = @{}

if ($content -match '(?s)^---\r?\n(.+?)\r?\n---') {
    $yamlBlock = $Matches[1]
    foreach ($line in $yamlBlock -split '\r?\n') {
        if ($line -match '^(\w+):\s*(.+)$') {
            $frontmatter[$Matches[1]] = $Matches[2].Trim('"', "'", ' ')
        }
    }
}

$missing = $requiredFields | Where-Object { -not $frontmatter.ContainsKey($_) }
if ($missing) {
    Write-Error "output.md frontmatter missing required fields: $($missing -join ', ')"
    exit 2
}

# Step 3: Compute target path
$inboxDir = Join-Path (Join-Path (Join-Path $WikiRoot 'sources') 'notes') 'inbox'
if (-not (Test-Path $inboxDir)) {
    Write-Error "Wiki inbox directory does not exist: $inboxDir"
    exit 3
}

$captured = $frontmatter['captured']
# Derive filename slug from the run id leaf. Child run ids contain path
# separators, but inbox targets must be a single markdown filename.
$slug = ($RunId -split '[\\/]')[-1]
if ($slug -match '^\d{4}-\d{2}-\d{2}-(.+)$') {
    $slug = $Matches[1]
}
$targetName = "$captured-$slug.md"
$targetPath = Join-Path $inboxDir $targetName

# Step 4: Handle name collision
if (Test-Path $targetPath) {
    $n = 2
    while (Test-Path (Join-Path $inboxDir "$captured-$slug-$n.md")) { $n++ }
    $targetName = "$captured-$slug-$n.md"
    $targetPath = Join-Path $inboxDir $targetName
}

# Step 5: Copy file to wiki inbox
Copy-Item -Path $outputPath -Destination $targetPath

# Step 6: Add done record
$now = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
$ideaSlug = $RunId
if ($RunId -match '-rerun-\d+$') {
    $ideaSlug = $RunId -replace '-rerun-\d+$', ''
}
Add-QueueDone -Item @{
    run_id     = $RunId
    idea_slug  = $ideaSlug
    delivered  = $now
    inbox_path = $targetPath
}

# Step 7: Remove from in_flight
Remove-QueueInFlight -RunId $RunId

# Step 7a: Remove from closed if present (closed → delivered migration)
Remove-QueueClosed -RunId $RunId

# Step 8: Append to log.md
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$logPath = Join-Path $runDir 'log.md'
$logLine = "`n$timestamp | event=delivered | inbox=$targetPath"
Add-Content -Path $logPath -Value $logLine -Encoding UTF8

# Step 9: Output target path
Write-Output $targetPath
