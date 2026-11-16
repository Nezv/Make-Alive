# Measures real frame times and draw calls in a window, with a horde on screen.
#   tools\perf.ps1                      -> the corridor, 60 zombies, 30 seconds
#   tools\perf.ps1 city 20              -> the city, 20 seconds
#   tools\perf.ps1 city 30 hospital     -> a city mission
# Prints one [perf] line: average, 99th percentile and worst frame, draw calls.
# The budgets the headless tests hold maps to are in Config.BUDGET (tools\test.ps1 budget).
param([string]$Map = 'corridor', [int]$Seconds = 30, [string]$Mission = '')
$godot = Join-Path $PSScriptRoot 'godot.ps1'
$import = & $godot --headless --import 2>&1
if ($LASTEXITCODE -ne 0) { $import; exit $LASTEXITCODE }
$a = @('--', '--host', "--map=$Map", '--bot', "--spawn=60", "--perf=$Seconds")
if ($Mission) { $a += "--mission=$Mission" }
& $godot @a 2>&1 | ForEach-Object { "$_" } | Select-String -Pattern '^\[perf\]'
