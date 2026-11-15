# Opens two game windows on this PC: one hosting, one joining it. For testing multiplayer alone.
$godot = Join-Path $PSScriptRoot 'godot.ps1'
Start-Process powershell -ArgumentList '-NoProfile', '-File', $godot, '--', '--host', '--name=Host'
Start-Sleep -Seconds 2
Start-Process powershell -ArgumentList '-NoProfile', '-File', $godot, '--', '--join=127.0.0.1', '--name=Guest'
