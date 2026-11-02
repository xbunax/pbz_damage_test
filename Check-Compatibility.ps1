param(
    [Parameter(Mandatory=$true)][string]$UE4SSDirectory,
    [string]$GameExecutable
)
$ErrorActionPreference = 'Stop'
$lock = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dependencies.json') -Raw | ConvertFrom-Json
$dll = Join-Path $UE4SSDirectory 'UE4SS.dll'
$actual = (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "UE4SS.dll SHA256: $actual"
if ($actual -eq $lock.ue4ss.dll_sha256) {
    Write-Output "MATCH: tested UE4SS $($lock.ue4ss.version)"
} else {
    throw 'Untested UE4SS binary. Do not overwrite an existing runtime; review docs/COMPATIBILITY.md.'
}
if ($GameExecutable) {
    $gameHash = (Get-FileHash -LiteralPath $GameExecutable -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Output "PBZ.exe SHA256: $gameHash"
    if ($gameHash -ne $lock.game.exe_sha256) { throw 'Untested game build.' }
    Write-Output "MATCH: tested Steam build $($lock.game.steam_build) / UE $($lock.game.engine)"
}
Write-Output 'Read-only check passed. No files or settings were changed.'
