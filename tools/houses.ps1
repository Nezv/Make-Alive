# The house interiors' master script (S244): lays out the sample house's floors and a spread of
# other houses (HousePlan, headless: no window), saves them as JSON and draws them.
#   tools\houses.ps1                 -> seed 18000, 8 variants
#   tools\houses.ps1 -Seed 42        -> another sample house
#   tools\houses.ps1 -Variants 0     -> the sample only
# Writes references/shots/houses/houses.json, house_floors.png (the sample's floors, large, with a
# legend) and house_variants.png. Walk the sample in 3D with: tools\godot.ps1 -- --house-rack=<seed>
param([int]$Seed = 18000, [int]$Variants = 8)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $PSScriptRoot 'godot.ps1'
$dir = Join-Path $root 'references\shots\houses'
New-Item -ItemType Directory -Force $dir | Out-Null

# Refresh Godot's class cache so new class_name scripts are known (quiet unless it fails).
$import = & $godot --headless --import 2>&1
if ($LASTEXITCODE -ne 0) { $import; exit $LASTEXITCODE }

$a = @('--headless', '--', ('--house-plans=' + $dir.Replace([char]92, [char]47)), "--seed=$Seed", "--variants=$Variants")
& $godot @a 2>&1 | Where-Object { "$_" -match '^\[houses\]' } | ForEach-Object { "$_" }
if (-not (Test-Path (Join-Path $dir 'houses.json'))) { Write-Error 'no houses.json written'; exit 1 }

python (Join-Path $PSScriptRoot 'house_plans.py') (Join-Path $dir 'houses.json')
exit $LASTEXITCODE
