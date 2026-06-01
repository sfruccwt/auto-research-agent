$ErrorActionPreference = "Stop"

<#
Temporary PR-only verification asset.

This script checks the document-layer research-state lifecycle migration.
If this PR should merge without test assets, drop or revert the commit that
adds this file and the matching fixture files before merging.
#>

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$Failures = [System.Collections.Generic.List[string]]::new()

function Get-RepoText {
    param([Parameter(Mandatory)][string]$RelativePath)
    $Path = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $Path)) {
        $Failures.Add("missing file: $RelativePath")
        return ""
    }
    return [System.IO.File]::ReadAllText($Path)
}

function Assert-Contains {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Label
    )
    $Text = Get-RepoText $RelativePath
    if ($Text -notmatch $Pattern) {
        $Failures.Add("missing expected content: $Label <$RelativePath>")
    }
}

function Assert-NotContains {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$Label
    )
    $Text = Get-RepoText $RelativePath
    if ($Text -match $Pattern) {
        $Failures.Add("unexpected content: $Label <$RelativePath>")
    }
}

function Assert-PathExists {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Label
    )
    $Path = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $Path)) {
        $Failures.Add("missing path: $Label <$RelativePath>")
    }
}

function Assert-PathAbsent {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Label
    )
    $Path = Join-Path $RepoRoot $RelativePath
    if (Test-Path -LiteralPath $Path) {
        $Failures.Add("path should be absent: $Label <$RelativePath>")
    }
}

Write-Host "[research-state-slot-lifecycle] repo root: $RepoRoot"

$RequiredFiles = @(
    "sop/template-research-state.md",
    "sop/template-search-round.md",
    "sop/template-memo.md",
    "sop/templates.md",
    "sop/flow-card.md",
    "sop/workflow.md",
    "sop/stages/1-opening.md",
    "sop/stages/2-research.md",
    "sop/tasks/research-state-slot-lifecycle.md",
    "sop/tasks/research-state-slot-lifecycle-migration-plan.md",
    "sop/tasks/research-state-slot-lifecycle-test-cases.md"
)

foreach ($File in $RequiredFiles) {
    Assert-PathExists $File "required lifecycle document"
}

# L1: Template surface.
$StateTemplate = "sop/template-research-state.md"
foreach ($Heading in @(
    "## origin_context",
    "## inquiry_shape",
    "## scope_boundary",
    "## evidence_contract",
    "## output_action_contract",
    "### use_intent",
    "### objective",
    "### search_plan",
    "### enoughness",
    "## child_runs",
    "## tracked_facets",
    "## legacy_import",
    "## change_log"
)) {
    Assert-Contains $StateTemplate ([regex]::Escape($Heading)) "research-state heading $Heading"
}

foreach ($Value in @("missing", "unresolved", "temporary", "confirmed", "deferred")) {
    Assert-Contains $StateTemplate $Value "resolution_state value $Value"
}
foreach ($Value in @("user", "evidence", "inference", "default", "mixed", "legacy_doc")) {
    Assert-Contains $StateTemplate $Value "basis value $Value"
}
Assert-NotContains $StateTemplate "confidence" "no mandatory confidence field"
Assert-NotContains $StateTemplate "tool_routing" "no tool_routing in research state"

$SearchRoundTemplate = "sop/template-search-round.md"
foreach ($Term in @(
    "## search_intent",
    "## queries_and_sources",
    "## key_findings",
    "### state_before",
    "### state_delta",
    "### state_after",
    "### new_gaps",
    "### enoughness_current",
    "### agent_recommendation"
)) {
    Assert-Contains $SearchRoundTemplate ([regex]::Escape($Term)) "search-round template term $Term"
}
Assert-Contains $SearchRoundTemplate "continue_search.*pivot.*ask_user.*write_memo.*stop" "agent recommendation choices"

$MemoTemplate = "sop/template-memo.md"
Assert-Contains $MemoTemplate "research-state-pre-memo\.md" "memo references pre-memo state"
Assert-Contains $MemoTemplate "## enoughness" "memo enoughness review"
Assert-Contains $MemoTemplate "## action boundary" "memo action boundary review"

# L2: Legacy field coverage and tool routing exclusion.
$TaskDoc = "sop/tasks/research-state-slot-lifecycle.md"
$CoverageDoc = "sop/tasks/research-state-slot-lifecycle-test-cases.md"
foreach ($Term in @(
    "origin_context\.initial_topic",
    "objective\.decision_or_action",
    "objective\.research_question",
    "scope_boundary\.out_of_scope",
    "search_plan\.source_surfaces",
    "enoughness\.stop_criteria",
    "AGENTS\.md"
)) {
    Assert-Contains $CoverageDoc $Term "task-card field coverage $Term"
}
Assert-Contains $CoverageDoc "objective\.research_question" "judgment research question coverage"
Assert-Contains $CoverageDoc "search-round-N\.enoughness_current" "judgment current judgment coverage"
Assert-Contains $TaskDoc "tool_routing" "tool routing is explicitly excluded"
Assert-Contains $TaskDoc "agent-reach" "agent-reach remains global routing rule"

# L3: Gate rebinding.
Assert-Contains "sop/stages/1-opening.md" "notes/research-state\.md" "opening writes research-state"
Assert-Contains "sop/stages/1-opening.md" "research-state-opening\.md" "opening snapshot"
Assert-Contains "sop/stages/1-opening.md" "Update-QueueGate -RunId .* -Gate opening" "opening gate command"
Assert-NotContains "sop/stages/1-opening.md" "notes/task-card\.md" "new opening stage does not depend on task-card"

Assert-Contains "sop/stages/2-research.md" "sources/search-round-N\.md" "research stage writes search round"
Assert-Contains "sop/stages/2-research.md" "search_round_summary\.state_delta" "research stage requires state delta"
Assert-Contains "sop/stages/2-research.md" "research-state-rNN\.md" "research stage saves round snapshot"
Assert-Contains "sop/stages/2-research.md" "agent_recommendation" "research stage uses recommendation"
Assert-NotContains "sop/stages/2-research.md" "notes/judgment\.md" "new research stage does not depend on judgment"
Assert-NotContains "sop/stages/2-research.md" "Update-QueueGate -Gate midway" "new research stage does not call midway gate"

Assert-Contains "sop/flow-card.md" "memo review \+ done" "flow-card gate model"
Assert-Contains "sop/flow-card.md" "memo review" "memo review is not queue gate"
Assert-Contains "sop/flow-card.md" "midway" "midway mentioned only as legacy concept"
Assert-Contains "sop/flow-card.md" "Legacy" "legacy compatibility section exists"
Assert-Contains "sop/templates.md" "template-task-card\.md.*legacy import" "task-card marked legacy"
Assert-Contains "sop/templates.md" "template-judgment\.md.*legacy import" "judgment marked legacy"

# L4: Scenario coverage plus minimal fixtures that force branch conditions.
$ScenarioDoc = "sop/tasks/research-state-slot-lifecycle-test-cases.md"
foreach ($Case in @("C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9")) {
    Assert-Contains $ScenarioDoc "### $Case\." "scenario case $Case exists"
}

$FixtureRoot = "sop/tasks/fixtures/research-state-slot-lifecycle"
Assert-PathExists "$FixtureRoot/c5-pivot-after-round-1/research-state-before.md" "C5 research-state fixture"
Assert-PathExists "$FixtureRoot/c5-pivot-after-round-1/search-round-1.md" "C5 search-round fixture"
Assert-Contains "$FixtureRoot/c5-pivot-after-round-1/search-round-1.md" 'agent_recommendation\s*:\s*pivot|`pivot`' "C5 forces pivot"
Assert-Contains "$FixtureRoot/c5-pivot-after-round-1/search-round-1.md" 'searchable gap.*user-only gap|user-only gap.*searchable gap' "C5 gap split"

Assert-PathExists "$FixtureRoot/c6-enough-after-round-2/research-state-r02.md" "C6 research-state fixture"
Assert-PathExists "$FixtureRoot/c6-enough-after-round-2/search-round-2.md" "C6 search-round fixture"
Assert-Contains "$FixtureRoot/c6-enough-after-round-2/search-round-2.md" 'agent_recommendation\s*:\s*write_memo|`write_memo`' "C6 forces write_memo"
Assert-Contains "$FixtureRoot/c6-enough-after-round-2/search-round-2.md" "write_memo" "C6 enoughness"

Assert-PathExists "$FixtureRoot/c9-legacy-run-resume/task-card.md" "C9 legacy task-card fixture"
Assert-PathExists "$FixtureRoot/c9-legacy-run-resume/judgment.md" "C9 legacy judgment fixture"
Assert-PathExists "$FixtureRoot/c9-legacy-run-resume/memo.md" "C9 legacy memo fixture"
Assert-PathAbsent "$FixtureRoot/c9-legacy-run-resume/research-state.md" "C9 has no research-state before import"
Assert-Contains "$FixtureRoot/c9-legacy-run-resume/task-card.md" "AGENTS\.md" "C9 legacy includes tool routing field"
Assert-Contains "$FixtureRoot/c9-legacy-run-resume/judgment.md" "legacy" "C9 legacy judgment fixture"

if ($Failures.Count -gt 0) {
    Write-Host ""
    Write-Host "FAILED checks:" -ForegroundColor Red
    foreach ($Failure in $Failures) {
        Write-Host "- $Failure" -ForegroundColor Red
    }
    exit 1
}

Write-Host "All research-state slot lifecycle checks passed." -ForegroundColor Green
