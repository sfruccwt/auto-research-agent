param(
    [switch]$DisableComputerUse,
    [switch]$RestoreLatest
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path $env:USERPROFILE ".codex\config.toml"
if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Config not found: $configPath"
}

function Show-RelevantConfig {
    param([string]$Path)

    $lines = Get-Content -LiteralPath $Path
    $interesting = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\[windows\]$' -or
            $line -match '^\[sandbox_workspace_write\]$' -or
            $line -match '^\[plugins\."computer-use@openai-bundled"\]$') {
            $interesting.Add($line)
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^\[') { break }
                if ($lines[$j].Trim().Length -gt 0) {
                    $interesting.Add($lines[$j])
                }
            }
            $interesting.Add("")
        }
    }

    ($interesting -join [Environment]::NewLine).TrimEnd()
}

if ($RestoreLatest) {
    $backup = Get-ChildItem -LiteralPath (Split-Path -Parent $configPath) -Filter "config.toml.bak-browser-test-*" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $backup) {
        throw "No browser-test backup found next to $configPath"
    }

    Copy-Item -LiteralPath $backup.FullName -Destination $configPath -Force
    Write-Output "restored=$($backup.FullName)"
    Show-RelevantConfig -Path $configPath
    exit 0
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = "$configPath.bak-browser-test-$stamp"
Copy-Item -LiteralPath $configPath -Destination $backupPath -Force

$text = Get-Content -LiteralPath $configPath -Raw

if ($text -match '(?m)^\[windows\]') {
    if ($text -match '(?m)^\[windows\]\r?\n(?:(?!^\[).*\r?\n)*?sandbox\s*=') {
        $text = [regex]::Replace(
            $text,
            '(?ms)(^\[windows\]\r?\n(?:(?!^\[).*?\r?\n)*?)sandbox\s*=\s*"[^"]*"',
            '${1}sandbox = "unelevated"',
            1
        )
    } else {
        $text = [regex]::Replace($text, '(?m)^\[windows\]\r?\n', "[windows]`r`nsandbox = `"unelevated`"`r`n", 1)
    }
} else {
    $text = $text.TrimEnd() + "`r`n`r`n[windows]`r`nsandbox = `"unelevated`"`r`n"
}

if ($text -match '(?m)^\[sandbox_workspace_write\]') {
    if ($text -match '(?m)^\[sandbox_workspace_write\]\r?\n(?:(?!^\[).*\r?\n)*?network_access\s*=') {
        $text = [regex]::Replace(
            $text,
            '(?ms)(^\[sandbox_workspace_write\]\r?\n(?:(?!^\[).*?\r?\n)*?)network_access\s*=\s*(true|false)',
            '${1}network_access = true',
            1
        )
    } else {
        $text = [regex]::Replace(
            $text,
            '(?m)^\[sandbox_workspace_write\]\r?\n',
            "[sandbox_workspace_write]`r`nnetwork_access = true`r`n",
            1
        )
    }
} else {
    if ($text -match '(?m)^\[windows\]') {
        $text = [regex]::Replace(
            $text,
            '(?m)^\[windows\]',
            "[sandbox_workspace_write]`r`nnetwork_access = true`r`n`r`n[windows]",
            1
        )
    } else {
        $text = $text.TrimEnd() + "`r`n`r`n[sandbox_workspace_write]`r`nnetwork_access = true`r`n"
    }
}

if ($DisableComputerUse -and $text -match '(?m)^\[plugins\."computer-use@openai-bundled"\]') {
    if ($text -match '(?m)^\[plugins\."computer-use@openai-bundled"\]\r?\n(?:(?!^\[).*\r?\n)*?enabled\s*=') {
        $text = [regex]::Replace(
            $text,
            '(?ms)(^\[plugins\."computer-use@openai-bundled"\]\r?\n(?:(?!^\[).*?\r?\n)*?)enabled\s*=\s*(true|false)',
            '${1}enabled = false',
            1
        )
    }
}

Set-Content -LiteralPath $configPath -Value $text -Encoding UTF8

Write-Output "backup=$backupPath"
Show-RelevantConfig -Path $configPath
