# Writes every world sound as a WAV into references/shots/sounds/ and draws their waveforms and
# spectrograms on one sheet (references/shots/sounds/sheet.png) to look at.
$godot = Join-Path $PSScriptRoot 'godot.ps1'
& $godot --headless res://tools/sound_sheet.tscn
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python (Join-Path $PSScriptRoot 'sound_sheet.py')
exit $LASTEXITCODE
