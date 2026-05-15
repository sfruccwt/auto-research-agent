[CmdletBinding(DefaultParameterSetName = 'FromPath')]
param(
    [Parameter(Mandatory, ParameterSetName = 'FromPath')]
    [string]$IdeaPath,

    [Parameter(ParameterSetName = 'FromPath')]
    [switch]$Force,

    [Parameter(Mandatory, ParameterSetName = 'FromTopic')]
    [string]$Topic,

    [Parameter(ParameterSetName = 'FromTopic')]
    [string]$Slug,

    [string]$ParentRunId
)

. "$PSScriptRoot/queue.ps1"

# --- Topic path: create local idea file first, then fall through ---
if ($PSCmdlet.ParameterSetName -eq 'FromTopic') {
    if ([string]::IsNullOrWhiteSpace($Topic)) {
        Write-Error "Topic must not be empty"
        exit 5
    }

    # Generate slug
    if (-not $Slug) {
        $words = ($Topic -replace '[^\w\s-]', '' -split '\s+') | Where-Object { $_ -ne '' } | Select-Object -First 5
        $Slug = ($words -join '-').ToLower()
        if ($Slug.Length -gt 50) { $Slug = $Slug.Substring(0, 50).TrimEnd('-') }
    }

    $today = Get-Date -Format 'yyyy-MM-dd'
    $ideaFileName = "$today-$Slug.md"
    $ideasDir = Join-Path (Join-Path $PSScriptRoot '..') 'ideas'
    if (-not (Test-Path $ideasDir)) { New-Item -ItemType Directory -Path $ideasDir -Force | Out-Null }

    $ideaFilePath = Join-Path $ideasDir $ideaFileName

    # Handle name collision
    if (Test-Path $ideaFilePath) {
        $n = 2
        while (Test-Path (Join-Path $ideasDir "$today-$Slug-$n.md")) { $n++ }
        $ideaFileName = "$today-$Slug-$n.md"
        $ideaFilePath = Join-Path $ideasDir $ideaFileName
    }

    $routeReason = $Topic
    if ($routeReason.Length -gt 80) { $routeReason = $routeReason.Substring(0, 80) }

    $readableTitle = ($Slug -replace '-', ' ')
    $readableTitle = (Get-Culture).TextInfo.ToTitleCase($readableTitle)

    $ideaContent = @"
---
source: runner-local
source_file:
captured: $today
route: research
route_reason: "$routeReason"
status: pending
---

# $readableTitle

$Topic
"@
    Set-Content -Path $ideaFilePath -Value $ideaContent -Encoding UTF8 -NoNewline

    $IdeaPath = $ideaFilePath
}

# Step 1: Validate IdeaPath
if (-not (Test-Path $IdeaPath) -or -not $IdeaPath.EndsWith('.md')) {
    Write-Error "IdeaPath does not exist or is not a .md file: $IdeaPath"
    exit 1
}

# Step 2: Derive run_id from idea filename
$ideaBasename = [System.IO.Path]::GetFileNameWithoutExtension($IdeaPath)
$runId = $ideaBasename
$runsRoot = Join-Path (Join-Path $PSScriptRoot '..') 'runs'

# Step 2a: Handle sub-run (child of a parent run)
if ($ParentRunId) {
    $parentDir = Join-Path $runsRoot $ParentRunId
    if (-not (Test-Path $parentDir)) {
        Write-Error "Parent run directory does not exist: runs/$ParentRunId/"
        exit 4
    }
    # Child slug: strip date prefix from ideaBasename
    $childSlug = $ideaBasename
    if ($childSlug -match '^\d{4}-\d{2}-\d{2}-(.+)$') {
        $childSlug = $Matches[1]
    }
    $runId = "$ParentRunId/sub/$childSlug"
    $runDir = Join-Path $parentDir "sub/$childSlug"
    New-Item -ItemType Directory -Path $runDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $runDir 'notes') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $runDir 'sources') -Force | Out-Null
} else {
    # Step 3: Check done records (only for top-level runs)
    $doneItems = Get-QueueDone
    $alreadyDone = $doneItems | Where-Object { $_.idea_slug -eq $ideaBasename }

    if ($alreadyDone) {
        if (-not $Force) {
            Write-Error "Idea '$ideaBasename' has already been delivered. Use -Force to create a rerun."
            exit 3
        }
        $n = 2
        while (Test-Path (Join-Path $runsRoot "$ideaBasename-rerun-$n")) { $n++ }
        $runId = "$ideaBasename-rerun-$n"
    }

    # Step 4: Create run directory structure
    $runDir = Join-Path $runsRoot $runId
    New-Item -ItemType Directory -Path $runDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $runDir 'notes') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $runDir 'sources') -Force | Out-Null
}

# Step 5: Freeze idea snapshot with source_idea field
$ideaContent = Get-Content $IdeaPath -Raw -Encoding UTF8
$resolvedIdeaPath = (Resolve-Path $IdeaPath).Path
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# Compute relative source_idea path if within repo, otherwise use absolute
$sourceIdea = $resolvedIdeaPath
if ($resolvedIdeaPath.StartsWith($repoRoot)) {
    $sourceIdea = $resolvedIdeaPath.Substring($repoRoot.Length).TrimStart('\', '/')
    $sourceIdea = $sourceIdea -replace '\\', '/'
}

# Inject source_idea (and parent_run if applicable) into frontmatter
if ($ideaContent -match '(?s)^---\r?\n(.+?)\r?\n---') {
    $frontmatter = $Matches[1]
    $newFrontmatter = "$frontmatter`nsource_idea: $sourceIdea"
    if ($ParentRunId) {
        $newFrontmatter = "$newFrontmatter`nparent_run: $ParentRunId"
    }
    $ideaContent = $ideaContent -replace '(?s)^---\r?\n.+?\r?\n---', "---`n$newFrontmatter`n---"
}

Set-Content -Path (Join-Path $runDir 'idea.md') -Value $ideaContent -Encoding UTF8 -NoNewline

# Step 6: Initialize log.md
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$logLine = "$timestamp | event=run_init | idea=$([System.IO.Path]::GetFileName($IdeaPath))"
if ($ParentRunId) {
    $logLine = "$logLine | parent=$ParentRunId"
}
Set-Content -Path (Join-Path $runDir 'log.md') -Value $logLine -Encoding UTF8

# Step 7: Add to in_flight queue
$now = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
$queueItem = @{
    run_id       = $runId
    idea_slug    = $ideaBasename
    started      = $now
    current_gate = 'opening'
}
if ($ParentRunId) {
    $queueItem['parent_run'] = $ParentRunId
}
Add-QueueInFlight -Item $queueItem

# Step 8: Output run directory path
$resolvedPath = (Resolve-Path $runDir).Path
Write-Output $resolvedPath
