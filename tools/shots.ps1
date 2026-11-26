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
    'body_rack'         = $corridor + '--body-rack'
    'body_rack_back'    = $corridor + '--body-rack', '--back'
    'body_rack_walk'    = $corridor + '--body-rack', '--rack-anim=walk'
    'body_rack_attack'  = $corridor + '--body-rack', '--rack-anim=attack'
    'outfit_rack_1'     = $corridor + '--outfit-rack=1'
    'outfit_rack_2'     = $corridor + '--outfit-rack=2'
    'outfit_rack_3'     = $corridor + '--outfit-rack=3'
    'outfit_rack_1_back' = $corridor + '--outfit-rack=1', '--back'
    'outfit_rack_2_walk' = $corridor + '--outfit-rack=2', '--rack-anim=walk'
    'outfit_rack_3_attack' = $corridor + '--outfit-rack=3', '--rack-anim=attack'
    'outfit_rack_1_run' = $corridor + '--outfit-rack=1', '--rack-anim=run'
    'outfit_rack_2_stumps' = $corridor + '--outfit-rack=2', '--rack-sever=arm'
    'outfit_rack_3_stumps_back' = $corridor + '--outfit-rack=3', '--rack-sever=leg', '--back'
    'outfit_rack_1_headless' = $corridor + '--outfit-rack=1', '--rack-sever=head'
    'fx_rack'           = $corridor + '--fx-rack'
    'prop_rack_hydrant' = @('--prop-rack=hydrant', '--state=abandoned')
    'corridor_zones'    = $corridor + '--zones', '--shot-cam=18,34,22,0,-62'
    'view_aim'          = $corridor + '--weapon=4', '--pose=aim'
    'view_sprint'       = $corridor + '--weapon=4', '--pose=sprint'
    'view_reload'       = $corridor + '--weapon=4', '--pose=reload'
    'demo_zombies'      = @('--host', '--demo')
    'prop_rack_kit'     = @('--prop-rack=kit')
    'bite_rack_1'       = $corridor + '--bite-rack=1', '--outfit=nurse'
    'bite_rack_2'       = $corridor + '--bite-rack=2', '--outfit=nurse'
    'survivor_rack'     = $corridor + '--survivor-rack'
    'view_heal'         = $corridor + '--weapon=1', '--pose=heal'
    'view_downed'       = $corridor + '--weapon=1', '--pose=downed'
    'view_inspect'      = $corridor + '--weapon=4', '--pose=inspect'
    'view_shove'        = $corridor + '--weapon=4', '--pose=shove'
    'item_wheel'        = $corridor + '--wheel'
    'heli_landing'      = $corridor + '--heli=1'
    'feed_death'        = $corridor + '--feed'
}
# The town's mass (S043, references/elements/city_blocks.md): the skyline from the place du Marché,
# the bridge and the hill, a street in the old core, the roofscape from the helicopter's height.
$city = @('--host', '--no-hordes', '--review-light')
$shots['city_marche'] = $city + '--shot-cam=150,1.7,40,40,6'
$shots['city_core_street'] = $city + '--shot-cam=-150,1.7,160,80,4'
$shots['city_bridge'] = $city + '--shot-cam=262,7,-150,180,2'
$shots['city_hill'] = $city + '--shot-cam=560,140,-240,100,-14'
$shots['city_roofs'] = $city + '--shot-cam=60,140,180,30,-48'
foreach ($m in 'terminal', 'hospital', 'prefeitura', 'batalhao', 'mirante') {
    $shots["${m}_street"] = @('--host', "--mission=$m", '--no-hordes')
    $shots["${m}_landmark"] = @('--host', "--mission=$m", '--no-hordes', '--poi-cam')
}

# The Prefeitura from every side (references/prefeitura_elements.md): front, air, top, door, lawn,
# roof, stair tower, the avenue from the forecourt, the back.
$pref = @('--host', '--mission=prefeitura', '--no-hordes')
$prefCams = [ordered]@{
    'pref_front'     = '308.8,7.0,-649.4,-90.0,0.7'
    'pref_air'       = '285.8,48.0,-594.4,-59.9,-20.9'
    'pref_air_north' = '300.8,40.0,-709.4,-126.2,-18.5'
    'pref_top'       = '388.8,150.0,-649.4,-90.0,-89.0'
    'pref_door'      = '356.8,1.8,-656.4,-109.3,4.6'
    'pref_lawn'      = '324.8,1.7,-623.4,-71.6,3.3'
    'pref_roof'      = '362.8,28.0,-619.4,-35.0,-14.9'
    'pref_tower'     = '360.8,6.0,-701.4,-120.2,6.4'
    'pref_avenue'    = '369.8,2.6,-649.4,90.0,-0.6'
    'pref_back'      = '432.8,30.0,-659.4,102.8,-24.0'
}
foreach ($k in $prefCams.Keys) { $shots[$k] = $pref + "--shot-cam=$($prefCams[$k])" }

# The Hospital Dona Helena from every side (references/hospital_elements.md): the street front,
# two air views, the top, the ambulance bay, the old wing, the roof and its pad, the fire stair,
# the yard behind, Rua Blumenau.
$hosp = @('--host', '--mission=hospital', '--no-hordes')
$hospCams = [ordered]@{
    'hosp_front'      = '-598.4,6.0,-253.5,90.0,15.0'
    'hosp_air'        = '-568.4,60.0,-182.5,55.7,-19.7'
    'hosp_air_south'  = '-588.4,55.0,-322.5,129.4,-20.2'
    'hosp_top'        = '-658.4,170.0,-232.5,90.0,-89.0'
    'hosp_bay'        = '-634.4,1.8,-246.5,64.4,4.0'
    'hosp_wing'       = '-612.4,3.0,-203.5,90.0,12.0'
    'hosp_roof'       = '-680.4,40.0,-210.5,-14.5,-12.0'
    'hosp_stair'      = '-718.4,4.0,-246.5,-90.0,25.0'
    'hosp_yard'       = '-733.4,30.0,-253.5,-90.0,-25.0'
    'hosp_street'     = '-611.4,3.0,-312.5,180.0,2.0'
}
foreach ($k in $hospCams.Keys) { $shots[$k] = $hosp + "--shot-cam=$($hospCams[$k])" }

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
