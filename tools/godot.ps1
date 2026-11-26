# Finds the Godot console executable and runs it with the given arguments, in this project.
#   tools\godot.ps1                 -> open the game
#   tools\godot.ps1 -e              -> open the editor
#   tools\godot.ps1 -- --host --bot -> pass game options after --
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Find-Godot {
    if ($env:GODOT -and (Test-Path $env:GODOT)) { return $env:GODOT }
    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $pkgs = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    $exe = Get-ChildItem $pkgs -Recurse -Filter 'Godot*console*.exe' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if ($exe) { return $exe.FullName }
    throw 'Godot not found. Install it (winget install GodotEngine.GodotEngine) or set $env:GODOT to the exe path.'
}

$godot = Find-Godot
# An engine error printed on stderr must not stop a caller that redirects it (shots.ps1, 2>&1).
$ErrorActionPreference = 'Continue'
& $godot --path $root @args
exit $LASTEXITCODE
