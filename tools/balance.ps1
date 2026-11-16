# Prints the balance sheet (every gun against every zombie type) and writes references\balance.md.
#   tools\balance.ps1
# The rules the numbers must keep are tests: tools\test.ps1 balance
$godot = Join-Path $PSScriptRoot 'godot.ps1'
$root = Split-Path -Parent $PSScriptRoot
$out = (Join-Path $root 'references\balance.md') -replace '\\', '/'
$import = & $godot --headless --import 2>&1
if ($LASTEXITCODE -ne 0) { $import; exit $LASTEXITCODE }
$a = @('--headless', '--', "--balance=$out")
& $godot @a
exit $LASTEXITCODE
