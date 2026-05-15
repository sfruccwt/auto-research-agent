param(
    [Parameter(Mandatory)]
    [string]$RunId,

    [Parameter(Mandatory)]
    [string]$Summary,

    [Parameter(Mandatory)]
    [string]$Reason,

    [string]$NextSteps = ''
)

. "$PSScriptRoot/queue.ps1"

$runsRoot = Join-Path (Join-Path $PSScriptRoot '..') 'runs'
$runDir = Join-Path $runsRoot $RunId

# Step 1: Validate run directory exists
if (-not (Test-Path $runDir)) {
    Write-Error "Run directory does not exist: runs/$RunId/"
    exit 1
}

# Step 2: Validate not already delivered
$doneItems = Get-QueueDone
$alreadyDone = $doneItems | Where-Object { $_.run_id -eq $RunId }
if ($alreadyDone) {
    Write-Error "Run '$RunId' has already been delivered. Cannot close a delivered run."
    exit 3
}

# Step 3: Write closing-summary.md
$notesDir = Join-Path $runDir 'notes'
if (-not (Test-Path $notesDir)) { New-Item -ItemType Directory -Path $notesDir -Force | Out-Null }

$nextStepsText = if ($NextSteps) { $NextSteps } else { '无' }

$closingContent = @"
# 结项总结

## 结论摘要
$Summary

## 不投递原因
$Reason

## 后续方向建议
$nextStepsText

## 关联
- 派生 idea: （由 Claude 后续补填）
- 母课题: （由 Claude 后续补填）
"@

$closingPath = Join-Path $notesDir 'closing-summary.md'
Set-Content -Path $closingPath -Value $closingContent -Encoding UTF8 -NoNewline

# Step 4: Append to log.md
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$reasonShort = $Reason
if ($reasonShort.Length -gt 50) { $reasonShort = $reasonShort.Substring(0, 50) }
$logPath = Join-Path $runDir 'log.md'
$logLine = "`n$timestamp | event=closed | reason=$reasonShort"
Add-Content -Path $logPath -Value $logLine -Encoding UTF8

# Step 5: Add to queue/closed
$now = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'

# Derive idea_slug from RunId or idea.md
$ideaSlug = $RunId
$ideaPath = Join-Path $runDir 'idea.md'
if (Test-Path $ideaPath) {
    $ideaContent = Get-Content $ideaPath -Raw -Encoding UTF8
    if ($ideaContent -match '(?s)^---\r?\n(.+?)\r?\n---') {
        $yaml = $Matches[1]
        if ($yaml -match '(?m)^source_idea:\s*(.+)$') {
            $sourceIdeaPath = $Matches[1].Trim()
            $ideaSlug = [System.IO.Path]::GetFileNameWithoutExtension($sourceIdeaPath)
        }
    }
}
if ($ideaSlug -match '-rerun-\d+$') {
    $ideaSlug = $ideaSlug -replace '-rerun-\d+$', ''
}

try {
    Add-QueueClosed -Item @{
        run_id    = $RunId
        idea_slug = $ideaSlug
        closed    = $now
        summary   = $Summary
        reason    = $Reason
    }
} catch {
    Write-Error "Failed to write queue/closed record: $_"
    exit 2
}

# Step 6: Remove from in_flight
Remove-QueueInFlight -RunId $RunId

# Step 7: Output closing-summary.md path
$resolvedPath = (Resolve-Path $closingPath).Path
Write-Output $resolvedPath
