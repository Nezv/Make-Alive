"""Classify every pixel of references/joinville.png -> scripts/world/city_picture.gd, for the menu map.

Classes: 0 ground, 1 building, 2 street, 3 main road, 4 water, 5 green (forest, parks, cemetery).
Map labels and icons are cut out and filled from what surrounds them. North and east of the
picture's edges (around the Mirante's hill), joinville_topography.png fills in: it is tinted by
height, so there only the forest is told apart.

Usage: python tools/trace_city.py [preview.png]
"""
import base64, sys, zlib
import numpy as np
from PIL import Image
from scipy import ndimage

REF = "references/joinville.png"
TOPO = "references/joinville_topography.png"
OUT = "scripts/world/city_picture.gd"
TOPO_OFFSET = (183, -477)        # CityData.TOPO_OFFSET_PX
TOP = -180                       # first row, in joinville.png pixels (negative = above the picture)
LEFT = 183                       # first column: where the topography picture starts, so the band has no seam
RIGHT = 2000                     # last column + 1: past joinville.png's right edge, for the Mirante's side of the hill
UI = [(1878, 0, 1920, 365), (1845, 990, 1920, 1020), (0, 0, 345, 40)]   # zoom/layer buttons, credits, search box
TOPO_UI = [(1855, 0, 1920, 500), (0, 0, 60, 190)]

GROUND, BUILDING, STREET, MAIN, WATER, GREEN = range(6)
PROTOS = {
    GROUND: [(242, 239, 233), (238, 234, 228), (243, 226, 220), (255, 214, 209), (237, 237, 237), (233, 236, 239),
             (220, 220, 219), (224, 223, 223), (244, 215, 209), (241, 238, 232)],
    BUILDING: [(217, 208, 201), (196, 182, 171), (205, 194, 184), (201, 189, 179), (193, 178, 166)],
    STREET: [(255, 255, 255), (255, 255, 229), (254, 254, 254)],
    MAIN: [(252, 214, 164), (247, 250, 191), (249, 178, 156), (232, 146, 162)],
    WATER: [(170, 211, 223)],
    GREEN: [(173, 209, 158), (179, 199, 153), (170, 203, 175), (205, 235, 176), (186, 189, 147), (69, 84, 63),
            (200, 250, 204), (222, 246, 192)],
}


def classify(rgb):
    protos, labels = [], []
    for k, cs in PROTOS.items():
        for c in cs:
            protos.append(c)
            labels.append(k)
    protos = np.array(protos, np.float32)
    d = ((rgb[:, :, None, :] - protos[None, None]) ** 2).sum(-1)
    return np.array(labels, np.uint8)[d.argmin(-1)]


def fill_holes(cls, holes):
    """Give masked pixels the class of the nearest unmasked one."""
    idx = ndimage.distance_transform_edt(holes, return_distances=False, return_indices=True)
    return cls[idx[0], idx[1]]


def main():
    ref = np.asarray(Image.open(REF).convert("RGB")).astype(np.float32)
    h, w, _ = ref.shape
    cls = classify(ref)
    # Labels and icons: dark, grey (not the forest's dark green tree marks), plus their white halos.
    lum = ref.mean(-1)
    sat = ref.max(-1) - ref.min(-1)
    text = (lum < 150) & (sat < 40)
    text |= (lum < 175) & (ref[:, :, 0] > ref[:, :, 1] + 25)          # brown/red map icons and labels
    holes = ndimage.binary_dilation(text, iterations=3)
    for x0, y0, x1, y1 in UI:
        holes[y0:y1, x0:x1] = True
    cls = fill_holes(cls, holes)
    # Labels written along main roads cut them into dashes: close the gaps.
    main = ndimage.binary_closing(cls == MAIN, structure=np.ones((3, 3)), iterations=2)
    cls = np.where(main & (cls != WATER), MAIN, cls)
    # Lone specks of road (halo leftovers) out, thin roads kept: a 3x3 majority for street pixels.
    road = (cls == STREET)
    keep = ndimage.uniform_filter(road.astype(np.float32), 3) > 0.3
    cls = np.where(road & ~keep, GROUND, cls)

    # Around it (the band above, the strip east of it): from the topography picture. It is tinted by
    # height, and under the tint its streets can't be told from its labels, so it gives only the
    # forest (the tint runs green-yellow-red on the hill: red well above blue). The play area out
    # there is the hill, whose road the menu draws on top.
    topo = np.asarray(Image.open(TOPO).convert("RGB")).astype(np.float32)
    rows, cols = h - TOP, RIGHT - LEFT
    out = np.full((rows, cols), GROUND, np.uint8)
    for y in range(rows):
        ty = TOP + y - TOPO_OFFSET[1]
        if not 0 <= ty < topo.shape[0]:
            continue
        for x in range(cols):
            tx = LEFT + x - TOPO_OFFSET[0]
            if not 0 <= tx < topo.shape[1] or any(x0 <= tx < x1 and y0 <= ty < y1 for x0, y0, x1, y1 in TOPO_UI):
                continue
            r, _, b = topo[ty, tx]
            if r > b + 20:
                out[y, x] = GREEN
    # joinville.png where it reaches.
    out[-TOP:-TOP + h, 0:w - LEFT] = cls[:, LEFT:w]
    w = cols

    packed = base64.b64encode(zlib.compress(out.tobytes(), 9)).decode()
    lines = [packed[i:i + 120] for i in range(0, len(packed), 120)]
    body = "\n".join('\t"%s" +' % s for s in lines)[:-2]
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write('''class_name CityPicture
## Central Joinville as a picture for the menu: one byte per pixel of references/joinville.png (plus a
## band above it from the topography map), classified by tools/trace_city.py. Generated, do not edit.
## 0 ground, 1 building, 2 street, 3 main road, 4 water, 5 green. Pixel (0, 0) is joinville.png's
## (LEFT, TOP).

const GROUND := 0
const BUILDING := 1
const STREET := 2
const MAIN := 3
const WATER := 4
const GREEN := 5
const LEFT := %d
const TOP := %d
const W := %d
const H := %d
const DATA := (
%s)


## The classes as an R8 image, W x H.
static func image() -> Image:
	var bytes := Marshalls.base64_to_raw(DATA).decompress(W * H, FileAccess.COMPRESSION_DEFLATE)
	return Image.create_from_data(W, H, false, Image.FORMAT_R8, bytes)
''' % (LEFT, TOP, w, out.shape[0], body))
    print("wrote %s: %dx%d, %d KB packed" % (OUT, w, out.shape[0], len(packed) // 1024))
    if len(sys.argv) > 1:
        pal = np.array([(30, 30, 32), (58, 56, 58), (150, 140, 140), (230, 90, 80), (60, 80, 100), (34, 48, 36)], np.uint8)
        Image.fromarray(pal[out]).save(sys.argv[1])


if __name__ == "__main__":
    main()
