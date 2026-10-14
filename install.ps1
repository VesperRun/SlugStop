$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$root = Join-Path $env:USERPROFILE ".cursor"
$hooks = Join-Path $root "hooks"
New-Item -ItemType Directory -Force -Path $hooks | Out-Null

$destHooksJson = Join-Path $root "hooks.json"
$srcHooksJson = Join-Path $here "hooks.json"
if (Test-Path -LiteralPath $destHooksJson) {
    $bak = "$destHooksJson.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $destHooksJson -Destination $bak
    Write-Host "Backed up existing hooks.json -> $bak"
    if ((Get-FileHash $srcHooksJson).Hash -ne (Get-FileHash $destHooksJson).Hash) {
        Write-Host "WARNING: install replaces hooks.json. Merge SlugStop entries from repo hooks.json if the backup had other hooks."
    }
}
Copy-Item -Force -LiteralPath $srcHooksJson -Destination $destHooksJson

Copy-Item -Force -LiteralPath (Join-Path $here "hooks\slugstop.ps1") -Destination (Join-Path $hooks "slugstop.ps1")
$destCfg = Join-Path $hooks "slugstop.config.json"
if (-not (Test-Path -LiteralPath $destCfg)) {
    Copy-Item -LiteralPath (Join-Path $here "hooks\slugstop.config.json") -Destination $destCfg
} else {
    Write-Host "Kept existing slugstop.config.json (not overwritten)."
}
Write-Host "Config: $destCfg — reload Cursor; Default model → Last used."
