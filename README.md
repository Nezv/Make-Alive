# Zombie Extraction

A LAN multiplayer zombie FPS made with Godot 4. Early development: one test corridor, hordes of zombies that lose limbs, ragdoll and bleed.

## Play
Install [Godot 4.7](https://godotengine.org/download) (or `winget install GodotEngine.GodotEngine`), then from this folder:

```powershell
tools\godot.ps1
```

- **Host game** on one PC. The top-left of the screen shows the IP to give your friends.
- Everyone else types that IP and clicks **Join**, or just clicks the game when it appears under "Games on your network".
- First time, allow Godot through the Windows firewall on **Private networks** (port 7777 UDP, plus 7778 for the game list).

Controls: WASD move, Shift sprint, Space jump, left click shoot, **right click aim** (or **use** when looking at a door or lootbox), R reload, 1-9 or mouse wheel change gun, H heal, G throw, hold Tab for the item wheel, Esc menu.

Guns: P19, P90, Type 95, AK47, AS Val, USAS-12, SPAS-12, Orsis T-5000, Dragunov.

To try multiplayer alone, `tools\play2.ps1` opens a host and a guest on the same PC.

## Develop
```powershell
tools\test.ps1
```
runs the tests (about 12 seconds). Write the test first, then the code. See [CLAUDE.md](CLAUDE.md) for the workflow, the layout and the rules.

Gameplay reactions live in one file: [scripts/hooks.gd](scripts/hooks.gd) (`on_low_hp`, `on_right_click_door`, `on_zombie_killed`, ...). Tuning numbers live in [scripts/config.gd](scripts/config.gd).
