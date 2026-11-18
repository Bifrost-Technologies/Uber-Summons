param([string]$LuaRunner)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'scripts/build-uber-release.ps1') -LuaRunner $LuaRunner
