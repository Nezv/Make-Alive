# Finds Blender and runs a model script in it, headless. The models in assets\models are made
# by these scripts; never edit the .glb or the textures by hand, change the script and re-run.
#   tools\blender.ps1 tools\models\outfits.py             -> build every outfit, male and female
#   tools\blender.ps1 tools\models\outfits.py cop --f     -> only those
#   tools\blender.ps1 tools\models\body.py --quick        -> shapes only, quick previews
# Blender: $env:BLENDER, or blender on PATH, or a portable copy in %LOCALAPPDATA%\Programs
# (download the zip from blender.org/download and unzip it there).
param([Parameter(ValueFromRemainingArguments)]$Rest)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Find-Blender {
    if ($env:BLENDER -and (Test-Path $env:BLENDER)) { return $env:BLENDER }
    $cmd = Get-Command blender -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $exe = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Programs') -Directory -Filter 'blender*' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | ForEach-Object { Join-Path $_.FullName 'blender.exe' } |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($exe) { return $exe }
    throw 'Blender not found. Unzip the portable build into %LOCALAPPDATA%\Programs or set $env:BLENDER.'
}

$blender = Find-Blender
$script = $Rest[0]
$extra = @()
if ($Rest.Count -gt 1) { $extra = $Rest[1..($Rest.Count - 1)] }
& $blender --background --factory-startup --python-exit-code 1 --python (Join-Path $root $script) -- @extra
exit $LASTEXITCODE
