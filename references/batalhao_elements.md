# 62º Batalhão de Infantaria: element list

Everything that belongs at the barracks of the 62º BI and whether the game has it yet. Built from
`batalhao.jpg` (straight down the parade ground from the air) and `batalhao2.jpg` (the compound
from high up with the street grid round it).

Legend: [x] built · [~] built roughly · [ ] not built yet.
The set is `scripts/world/batalhao_set.gd` (`BatalhaoSet`), placed by `CityMap._batalhao` in the
lot's frame (`map.batalhao.frame`: -Z to rue Jules-Ferry, turned to face north-east; `gate`,
`ground`, `pad`). Long things turned with the lot close their cells through `CityMap._put_turned`.

## The buildings

- [x] The layout: the long front block on the street with a way through its middle, two side blocks down the parade ground, the headquarters at its head
- [x] Brown hipped tile roofs with tile courses, a ridge, a white cornice
- [x] White walls with a green band at the foot, a floor band, tall green-framed windows in two rows on both faces (a few lit), downpipes
- [x] The headquarters with its raised middle bay, porch on columns, steps, the arms and 62ºBI on its front
- [x] The gym hall with its barrel roof of metal sheet on ribs, strip windows, a roller door; the sports court beside it
- [ ] Gables over the side blocks' entrances, doors along the blocks
- [ ] A pool
- [x] Guard house at the gate; the gate's piers with their lamps, the barrier boom left up
- [x] Railings on a white plinth wall with piers along the street; plain walls round the other sides

## The parade ground

- [x] Concrete with painted drill lines, the round emblem bed with its white star and kerb
- [x] Stands: low stepped terraces either side of the way in
- [x] Trucks lined up at the head, three flagpoles before the headquarters
- [x] The lawn on the street with the four big stars cut into it (green and white)
- [x] The painted H in the middle where the helicopter comes down

## Around it

- [x] Trees along the sides and the back (broadleaves and imperial palms)
- [ ] The field and the running track behind (the west of the real lot)
- [~] Motor pool (a humvee by the gym; the trucks on the ground)

## Story and scatter

- [ ] Soldiers who turned (zombie outfits: soldier) placed as wanderers
- [x] Sandbag positions inside the gate, a truck left across the ground, crates, casings, blood trails
- [x] Mounted gun on the watch tower by the gate
- [ ] An overturned truck, ammo crates in an armoury (needs the crate element placed)

## The mission (DEFEND, `MapAreas.batalhao`)

- [x] Start inside the gate, hold the parade ground through three waves (closets behind the headquarters, the gym and both side yards)
- [x] The helicopter comes down on the H; board it to win
