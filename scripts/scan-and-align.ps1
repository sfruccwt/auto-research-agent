param(
    [string]$WikiRoot = 'D:/Personal LLM Wiki',
    [switch]$AsJson = $true
)

. "$PSScriptRoot/queue.ps1"

$wikiIdeasDir = Join-Path (Join-Path $WikiRoot 'research') 'ideas'
$wikiIdeasDoneDir = Join-Path $wikiIdeasDir 'done'
$localIdeasDir = Join-Path (Join-Path $PSScriptRoot '..') 'ideas'
$runsRoot = Join-Path (Join-Path $PSScriptRoot '..') 'runs'

# Step 1: List wiki idea files
$wikiIdeaFiles = [System.Collections.ArrayList]::new()

if (Test-Path $wikiIdeasDir) {
    Get-ChildItem $wikiIdeasDir -Filter '*.md' -File | ForEach-Object {
        [void]$wikiIdeaFiles.Add($_)
    }
}
if (Test-Path $wikiIdeasDoneDir) {
    Get-ChildItem $wikiIdeasDoneDir -Filter '*.md' -File | ForEach-Object {
        [void]$wikiIdeaFiles.Add($_)
    }
}

# Step 1a: List local idea files
$localIdeaFiles = [System.Collections.ArrayList]::new()

if (Test-Path $localIdeasDir) {
    Get-ChildItem $localIdeasDir -Filter '*.md' -File | ForEach-Object {
        [void]$localIdeaFiles.Add($_)
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

# Step 3a: Load closed records
$closedItems = Get-QueueClosed

$closedSlugs = @{}
foreach ($item in $closedItems) {
    $closedSlugs[$item.idea_slug] = $item
}

# Step 3b: Scan derived ideas from runs
$derivedIdeas = [System.Collections.ArrayList]::new()

if (Test-Path $runsRoot) {
    Get-ChildItem $runsRoot -Directory | ForEach-Object {
        $derivedFile = Join-Path $_.FullName 'notes' 'derived-ideas.md'
        if (Test-Path $derivedFile) {
            try {
                $content = Get-Content $derivedFile -Raw -Encoding UTF8
                $blocks = $content -split '(?m)^---\s*$'
                foreach ($block in $blocks) {
                    $block = $block.Trim()
                    if (-not $block -or $block -match '^#') { continue }

                    $entry = @{}
                    foreach ($line in $block -split '\r?\n') {
                        if ($line -match '^(\w[\w_]*):\s*(.*)$') {
                            $entry[$Matches[1]] = $Matches[2].Trim()
                        }
                    }

                    if ($entry.ContainsKey('title') -and (-not $entry['child_run'] -or $entry['child_run'] -eq '')) {
                        [void]$derivedIdeas.Add([PSCustomObject]@{
                            title       = $entry['title']
                            description = if ($entry['description']) { $entry['description'] } else { '' }
                            relation    = if ($entry['relation']) { $entry['relation'] } else { '' }
                            source_run  = $_.Name
                            recorded    = if ($entry['recorded']) { $entry['recorded'] } else { '' }
                        })
                    }
                }
            } catch {
                # Skip unparseable files
            }
        }
    }
}

# Step 4: Classify wiki ideas
$runnable = [System.Collections.ArrayList]::new()
$awaitingIngest = [System.Collections.ArrayList]::new()
$previouslyAbandoned = [System.Collections.ArrayList]::new()
$closedList = [System.Collections.ArrayList]::new()

foreach ($file in $wikiIdeaFiles) {
    $slug = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $status = Get-IdeaStatus $file.FullName

    if ($status -eq 'done' -or $status -eq 'abandoned') { continue }

    if ($doneSlugs.ContainsKey($slug)) {
        [void]$awaitingIngest.Add([PSCustomObject]@{
            idea_slug   = $slug
            wiki_status = $status
            delivered   = $doneSlugs[$slug].delivered
            source      = 'wiki'
        })
    }
    elseif ($closedSlugs.ContainsKey($slug)) {
        [void]$closedList.Add([PSCustomObject]@{
            run_id    = $closedSlugs[$slug].run_id
            idea_slug = $slug
            closed    = $closedSlugs[$slug].closed
            summary   = $closedSlugs[$slug].summary
        })
    }
    elseif ($abandonedSlugs.ContainsKey($slug)) {
        [void]$previouslyAbandoned.Add([PSCustomObject]@{
            idea_slug   = $slug
            wiki_status = $status
            abandoned   = $abandonedSlugs[$slug].abandoned
            reason      = $abandonedSlugs[$slug].reason
            source      = 'wiki'
        })
    }
    else {
        [void]$runnable.Add([PSCustomObject]@{
            idea_slug   = $slug
            wiki_status = $status
            source      = 'wiki'
        })
    }
}

# Step 4a: Classify local ideas
$runnableLocal = [System.Collections.ArrayList]::new()

foreach ($file in $localIdeaFiles) {
    $slug = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $status = Get-IdeaStatus $file.FullName

    if ($status -eq 'done' -or $status -eq 'abandoned') { continue }

    if ($doneSlugs.ContainsKey($slug)) {
        [void]$awaitingIngest.Add([PSCustomObject]@{
            idea_slug   = $slug
            wiki_status = $status
            delivered   = $doneSlugs[$slug].delivered
            source      = 'local'
        })
    }
    elseif ($closedSlugs.ContainsKey($slug)) {
        [void]$closedList.Add([PSCustomObject]@{
            run_id    = $closedSlugs[$slug].run_id
            idea_slug = $slug
            closed    = $closedSlugs[$slug].closed
            summary   = $closedSlugs[$slug].summary
        })
    }
    elseif ($abandonedSlugs.ContainsKey($slug)) {
        [void]$previouslyAbandoned.Add([PSCustomObject]@{
            idea_slug   = $slug
            wiki_status = $status
            abandoned   = $abandonedSlugs[$slug].abandoned
            reason      = $abandonedSlugs[$slug].reason
            source      = 'local'
        })
    }
    else {
        [void]$runnableLocal.Add([PSCustomObject]@{
            idea_slug = $slug
            source    = 'local'
            path      = "ideas/$($file.Name)"
        })
    }
}

# Step 5: Output JSON
$report = [PSCustomObject]@{
    scanned_at        = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    wiki_ideas_count  = $wikiIdeaFiles.Count
    local_ideas_count = $localIdeaFiles.Count
    categories        = [PSCustomObject]@{
        runnable             = @($runnable)
        runnable_local       = @($runnableLocal)
        awaiting_ingest      = @($awaitingIngest)
        previously_abandoned = @($previouslyAbandoned)
        derived_ideas        = @($derivedIdeas)
        closed               = @($closedList)
    }
}

$report | ConvertTo-Json -Depth 5
