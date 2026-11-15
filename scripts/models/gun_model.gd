class_name GunModel
extends Node3D
## One gun built by Guns.build(). Origin is near the trigger, barrel points -Z, metres.
## The magazine and the moving part of the action are separate nodes so they can be animated.

var body: MeshInstance3D
var mag: Node3D               ## null for tube-fed guns
var action: Node3D            ## slide, charging handle, pump or bolt
var muzzle := Vector3.ZERO    ## where the flash appears
var sight := Vector3.ZERO     ## where your eye goes when aiming
var grip := Vector3.ZERO      ## right hand
var support := Vector3.ZERO   ## left hand
var port := Vector3.ZERO      ## where shells go in (tube-fed guns)
var mag_at := Vector3.ZERO    ## middle of the magazine (the left hand grabs it here)
var mag_out := Vector3(0, -0.3, 0)       ## how the magazine leaves the gun
var action_travel := Vector3(0, 0, 0.07) ## how far the action moves when it cycles
var hip := Vector3(0.19, -0.19, -0.5)   ## where the gun sits on screen when not aiming
var ads_dist := 0.2                      ## eye to rear sight distance when aiming
var reload_rot := Vector3(0.28, 0.1, -0.5) ## how the gun is tilted while you work on it
