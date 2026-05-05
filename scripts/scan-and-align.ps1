param(
    [string]$WikiRoot = 'D:/Personal LLM Wiki',
    [switch]$AsJson = $true
)

. "$PSScriptRoot/queue.ps1"

$ideasDir = Join-Path $WikiRoot 'research' 'ideas'
$ideasDoneDir = Join-Path $ideasDir 'done'

# Step 1: List all idea files
$ideaFiles = [System.Collections.ArrayList]::new()

if (Test-Path $ideasDir) {
    Get-ChildItem $ideasDir -Filter '*.md' -File | ForEach-Object {
        [void]$ideaFiles.Add($_)
    }
}
if (Test-Path $ideasDoneDir) {
    Get-ChildItem $ideasDoneDir -Filter '*.md' -File | ForEach-Object {
        [void]$ideaFiles.Add($_)
    }
}

# Step 2: Read frontmatter status from each idea
function Get-IdeaStatus {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    if ($content -match '(?s)^---\r?\n(.+?)\r?\n---') {
        $yaml = $Matches[1]
        if ($yaml -match '(?m)^status:\s*(.+)$') {
            return $Matches[1].Trim()
        }
    }
    return 'pending'
}

# Step 3: Load local queue state
$doneItems = Get-QueueDone
$abandonedItems = Get-QueueAbandoned

$doneSlugs = @{}
foreach ($item in $doneItems) {
    $doneSlugs[$item.idea_slug] = $item
}

$abandonedSlugs = @{}
foreach ($item in $abandonedItems) {
    $abandonedSlugs[$item.idea_slug] = $item
}

# Step 4: Classify per FR-022
$runnable = [System.Collections.ArrayList]::new()
$awaitingIngest = [System.Collections.ArrayList]::new()
$previouslyAbandoned = [System.Collections.ArrayList]::new()

foreach ($file in $ideaFiles) {
    $slug = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $status = Get-IdeaStatus $file.FullName

    # Filter: done/abandoned wiki status → skip
    if ($status -eq 'done' -or $status -eq 'abandoned') { continue }

    # Remaining are pending (or missing status treated as pending)
    if ($doneSlugs.ContainsKey($slug)) {
        [void]$awaitingIngest.Add([PSCustomObject]@{
            idea_slug   = $slug
            wiki_status = $status
            delivered   = $doneSlugs[$slug].delivered
        })
    }
    elseif ($abandonedSlugs.ContainsKey($slug)) {
        [void]$previouslyAbandoned.Add([PSCustomObject]@{
            idea_slug   = $slug
            wiki_status = $status
            abandoned   = $abandonedSlugs[$slug].abandoned
            reason      = $abandonedSlugs[$slug].reason
        })
    }
    else {
        [void]$runnable.Add([PSCustomObject]@{
            idea_slug   = $slug
            wiki_status = $status
        })
    }
}

# Step 5: Output JSON
$report = [PSCustomObject]@{
    scanned_at       = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    wiki_ideas_count = $ideaFiles.Count
    categories       = [PSCustomObject]@{
        runnable             = @($runnable)
        awaiting_ingest      = @($awaitingIngest)
        previously_abandoned = @($previouslyAbandoned)
    }
}

$report | ConvertTo-Json -Depth 5
