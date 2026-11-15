"""Read Morro da Boa Vista's heights off references/joinville_topography.png -> scripts/world/city_heights.gd.

The topography picture colours the ground by elevation (legend top right, 3 ft cyan to 689 ft pink).
Every pixel is matched to the nearest legend colour, labels and icons are filtered out, the result is
smoothed and sampled on a STEP_PX grid in joinville.png pixels (CityData's coordinates).
Heights are metres above the city floor (BASE_FT), so the streets stay at y = 0.

Usage: python tools/trace_heights.py [preview.png]
"""
import base64, sys, zlib
import numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import gaussian_filter

TOPO = "references/joinville_topography.png"
OUT = "scripts/world/city_heights.gd"
TOPO_OFFSET = (183, -477)          # topography pixel + this = joinville.png pixel (CityData.TOPO_OFFSET_PX)
LEGEND_X = 1885
LEGEND_Y0, LEGEND_DY = 76, 20      # first swatch centre, spacing
LEGEND_FT = [689, 653, 617, 581, 545, 509, 472, 436, 400, 364, 328, 292, 256, 220, 184, 148, 112, 75, 39, 3]
UI_BOXES = [(1855, 0, 1920, 500), (0, 0, 60, 190), (1640, 1060, 1920, 1080), (0, 1040, 110, 1080)]  # legend, buttons, credits
BASE_FT = 39.0                     # the city floor around the hill
OVERLAY_ALPHA = 0.6
BASE_RGB = (230, 230, 225)
SUMMIT_M = 230.0                   # the trig point; the legend stops at 689 ft (210 m)
BOX = (1150, -340, 2116, 764)      # area to sample, joinville.png pixels: the hill and its foot
STEP_PX = 6                        # ~13.5 m between samples
FADE_PX = 60                       # below the picture's bottom edge, heights ease down to 0 over this


def main():
    img = Image.open(TOPO).convert("RGB")
    a = np.asarray(img).astype(np.float32)
    # The legend swatches are solid; on the map the same colours are laid at ~60 % over the street
    # map, so match against swatches blended over a pale base.
    swatches = []
    for i in range(len(LEGEND_FT)):
        y = LEGEND_Y0 + i * LEGEND_DY
        patch = a[y - 7:y + 8, 1863:1908].reshape(-1, 3)
        colours, counts = np.unique(patch, axis=0, return_counts=True)
        swatches.append(colours[counts.argmax()])
    swatches = np.array(swatches) * OVERLAY_ALPHA + np.array(BASE_RGB) * (1 - OVERLAY_ALPHA)
    m_per_ft = 0.3048
    heights_m = np.array([max(0.0, (ft - BASE_FT) * m_per_ft) for ft in LEGEND_FT])

    # Nearest swatch for each pixel, after a median filter that removes thin text and icons.
    smooth = np.asarray(img.filter(ImageFilter.MedianFilter(7))).astype(np.float32)
    d = ((smooth[:, :, None, :] - swatches[None, None, :, :]) ** 2).sum(-1)
    h = heights_m[d.argmin(-1)]
    valid = np.ones(h.shape, bool)
    for x0, y0, x1, y1 in UI_BOXES:
        valid[y0:y1, x0:x1] = False

    # Fill the UI holes from their surroundings, then blur away the colour bands' steps.
    hv = np.where(valid, h, 0).astype(np.float32)
    wv = valid.astype(np.float32)
    for r in (6, 12, 24):
        hb = gaussian_filter(hv, r)
        wb = gaussian_filter(wv, r)
        fill = np.where(wb > 1e-3, hb / np.maximum(wb, 1e-3), 0)
        h = np.where(valid, h, fill)
    h = gaussian_filter(h.astype(np.float32), 5)
    h = h * ((SUMMIT_M - BASE_FT * 0.3048) / max(1.0, float(h.max())))  # the legend tops out below the summit
    th, tw = h.shape

    w = (BOX[2] - BOX[0]) // STEP_PX + 1
    hh = (BOX[3] - BOX[1]) // STEP_PX + 1
    grid = np.zeros((hh, w), np.float32)
    for r in range(hh):
        for c in range(w):
            jx, jy = BOX[0] + c * STEP_PX, BOX[1] + r * STEP_PX
            tx, ty = jx - TOPO_OFFSET[0], jy - TOPO_OFFSET[1]
            fade = 1.0
            if ty >= th:                            # below the topography picture: ease down
                fade = max(0.0, 1.0 - (ty - th + 1) / FADE_PX)
                ty = th - 1
            tx = min(max(tx, 0), tw - 1)
            ty = max(ty, 0)
            grid[r, c] = h[int(ty), int(tx)] * fade
    q = np.clip(np.round(grid), 0, 255).astype(np.uint8)
    packed = base64.b64encode(zlib.compress(q.tobytes(), 9)).decode()
    lines = [packed[i:i + 100] for i in range(0, len(packed), 100)]
    body = "\n".join('\t"%s" +' % s for s in lines)[:-2]
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write('''class_name CityHeights
## Morro da Boa Vista: metres above the city floor, read off references/joinville_topography.png by
## tools/trace_heights.py (generated, do not edit). A W x H grid of bytes, one every STEP_PX pixels of
## joinville.png starting at ORIGIN_PX, zlib-packed in base64. Everywhere else is 0.

const ORIGIN_PX := Vector2(%d, %d)
const STEP_PX := %d.0
const W := %d
const H := %d
const DATA := (
%s)

static var _grid := PackedByteArray()


## Height in metres at a joinville.png pixel, bilinear between samples; 0 outside the grid.
static func at_px(px: Vector2) -> float:
	if _grid.is_empty():
		_grid = Marshalls.base64_to_raw(DATA).decompress(W * H, FileAccess.COMPRESSION_DEFLATE)
	var g := (px - ORIGIN_PX) / STEP_PX
	if g.x < 0.0 or g.y < 0.0 or g.x > W - 1 or g.y > H - 1:
		return 0.0
	var c := mini(floori(g.x), W - 2)
	var r := mini(floori(g.y), H - 2)
	var fx := g.x - c
	var fy := g.y - r
	var a := lerpf(_grid[r * W + c], _grid[r * W + c + 1], fx)
	var b := lerpf(_grid[(r + 1) * W + c], _grid[(r + 1) * W + c + 1], fx)
	return lerpf(a, b, fy)
''' % (BOX[0], BOX[1], STEP_PX, w, hh, body))
    print("wrote %s: %dx%d samples, max %.0f m, %d bytes packed" % (OUT, w, hh, grid.max(), len(packed)))
    if len(sys.argv) > 1:
        Image.fromarray((q.astype(np.float32) / max(1, q.max()) * 255).astype(np.uint8)).resize((w * 3, hh * 3)).save(sys.argv[1])


if __name__ == "__main__":
    main()
