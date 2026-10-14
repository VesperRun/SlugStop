param()
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Out-Ok([string]$event) {
    switch ($event) {
        "subagentStart" { '{"permission":"allow"}' | Write-Output }
        "beforeSubmitPrompt" { '{"continue":true}' | Write-Output }
        default { '{}' | Write-Output }
    }
    exit 0
}

$raw = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($raw)) { Out-Ok "" }
try { $p = $raw | ConvertFrom-Json } catch { Out-Ok "" }
$event = [string]$p.hook_event_name

try {
    $config = Get-Content (Join-Path $dir "slugstop.config.json") -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Out-Ok $event
}

function SlugHay($extra) {
    @([string]$p.model, [string]$p.model_id, [string]$extra) -join " "
}

function Allowed([string]$hay) {
    $h = $hay.ToLowerInvariant()
    foreach ($b in @($config.blocked_patterns)) {
        if ($null -eq $b) { continue }
        $s = ([string]$b).Trim().ToLowerInvariant()
        if ($s -and $h.Contains($s)) { return $false }
    }
    if (-not $config.allowed_patterns -or @($config.allowed_patterns).Count -eq 0) { return $true }
    foreach ($a in @($config.allowed_patterns)) {
        if ($null -eq $a) { continue }
        $s = ([string]$a).Trim().ToLowerInvariant()
        if ($s -and $h.Contains($s)) { return $true }
    }
    return $false
}

function Bypass([string]$prompt) {
    if ($env:SLUGSTOP_OFF -eq "1") { return $true }
    $pre = [string]$config.bypass_prefix
    if ($pre -and $prompt -match ("(?m)^" + [regex]::Escape($pre))) { return $true }
    return $false
}

function Audit([string]$line) {
    if (-not $config.audit_log) { return }
    $logDir = Join-Path $dir "logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
    Add-Content (Join-Path $logDir "slugstop.log") "$(Get-Date -Format o)`t$line"
}

switch ($event) {
    "beforeSubmitPrompt" {
        if (Bypass ([string]$p.prompt)) { Audit "allow bypass"; Out-Ok $event }
        if (Allowed (SlugHay "")) { Out-Ok $event }
        Audit "deny submit $(SlugHay '')"
        @{ continue = $false; user_message = [string]$config.deny_submit_message } | ConvertTo-Json -Compress | Write-Output
        exit 0
    }
    "subagentStart" {
        if (Allowed (SlugHay ([string]$p.subagent_model))) { Out-Ok $event }
        Audit "deny subagent $(SlugHay ([string]$p.subagent_model))"
        @{ permission = "deny"; user_message = [string]$config.deny_subagent_message } | ConvertTo-Json -Compress | Write-Output
        exit 0
    }
    "sessionStart" {
        $ctx = [string]$config.session_context
        if ($ctx) { @{ additional_context = $ctx } | ConvertTo-Json -Compress | Write-Output } else { '{}' | Write-Output }
        exit 0
    }
    default { Out-Ok $event }
}
