# Runs the test suite headless. Exit code 0 = all passed.
#   tools\test.ps1            -> all tests
#   tools\test.ps1 zombie     -> only tests whose file or method name contains "zombie"
param([string]$Filter = '')
$godot = Join-Path $PSScriptRoot 'godot.ps1'

# Refresh Godot's class cache so new class_name scripts are known (quiet unless it fails).
$import = & $godot --headless --import 2>&1
if ($LASTEXITCODE -ne 0) { $import; exit $LASTEXITCODE }

$extra = @()
if ($Filter) { $extra = @('--', "--filter=$Filter") }
& $godot --headless res://tests/run_tests.tscn @extra
exit $LASTEXITCODE
