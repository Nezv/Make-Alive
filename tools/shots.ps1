# Takes the standard set of screenshots into references\shots\ (not in git) and writes a contact
# sheet, references\shots\index.html. Run it after a visual change and read the pictures.
#   tools\shots.ps1            -> every shot
#   tools\shots.ps1 rack       -> only shots whose name contains "rack"
# A shot is a name and the game options that set it up. Add one line to $shots for a new one.
# `--shot-cam=x,y,z,yaw,pitch` puts a free camera exactly there, so a shot repeats pixel for pixel.
param([string]$Filter = '')
$godot = Join-Path $PSScriptRoot 'godot.ps1'
$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root 'references\shots'
New-Item -ItemType Directory -Force $dir | Out-Null
$out = $dir -replace '\\', '/'

$import = & $godot --headless --import 2>&1
if ($LASTEXITCODE -ne 0) { $import; exit $LASTEXITCODE }

$corridor = @('--host', '--map=corridor', '--no-hordes')
$shots = [ordered]@{
    'gun_rack'          = $corridor + '--gun-rack'
    'zombie_rack_1'     = $corridor + '--zombie-rack=1'
    'zombie_rack_2'     = $corridor + '--zombie-rack=2'
    'zombie_rack_1_back' = $corridor + '--zombie-rack=1', '--back'
    'zombie_rack_2_back' = $corridor + '--zombie-rack=2', '--back'
    'fx_rack'           = $corridor + '--fx-rack'
    'corridor_zones'    = $corridor + '--zones', '--shot-cam=18,34,22,0,-62'
    'view_aim'          = $corridor + '--weapon=4', '--pose=aim'
    'view_sprint'       = $corridor + '--weapon=4', '--pose=sprint'
    'view_reload'       = $corridor + '--weapon=4', '--pose=reload'
    'demo_zombies'      = @('--host', '--demo')
}
foreach ($m in 'terminal', 'hospital', 'prefeitura', 'batalhao', 'mirante') {
    $shots["${m}_street"] = @('--host', "--mission=$m", '--no-hordes')
    $shots["${m}_landmark"] = @('--host', "--mission=$m", '--no-hordes', '--poi-cam')
}

$made = @()
foreach ($name in $shots.Keys) {
    if ($Filter -and $name -notlike "*$Filter*") { continue }
    $a = @('--') + $shots[$name] + "--screenshot=$out/$name.png", '--shot-at=2.2', '--quit-after=3'
    & $godot @a 2>&1 | Out-Null
    $file = Join-Path $dir "${name}_0.png"
    if (Test-Path $file) {
        Move-Item -Force $file (Join-Path $dir "$name.png")
        $made += $name
        "shot  $name"
    } else {
        "FAIL  $name (no picture)"
    }
}

# The contact sheet lists every picture in the folder, not only the ones just taken.
$all = Get-ChildItem $dir -Filter *.png | Sort-Object Name
$cells = ($all | ForEach-Object {
    "<figure><a href=`"$($_.Name)`"><img src=`"$($_.Name)`" loading=`"lazy`"></a><figcaption>$($_.BaseName)</figcaption></figure>"
}) -join "`n"
$html = @"
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Make Alive shots</title>
<style>
body { background: #111316; color: #cfd3d8; font: 14px system-ui, sans-serif; margin: 24px; }
main { display: grid; grid-template-columns: repeat(auto-fill, minmax(380px, 1fr)); gap: 16px; }
figure { margin: 0; } img { width: 100%; display: block; border-radius: 4px; }
figcaption { padding: 6px 2px; }
</style></head><body>
<h1>Make Alive shots</h1>
<p>$($all.Count) pictures, taken $(Get-Date -Format 'yyyy-MM-dd HH:mm') by tools\shots.ps1.</p>
<main>
$cells
</main></body></html>
"@
Set-Content -Path (Join-Path $dir 'index.html') -Value $html -Encoding utf8
"$($made.Count) shots taken, $($all.Count) on the sheet: $dir\index.html"
