"""Trace the OpenStreetMap tiles references/1.png .. 9.png into scripts/world/city_osm.gd.

The tiles are screenshots of openstreetmap.org at four times the zoom of references/joinville.png (their
scale bars: 50 m over 89 px against 200 m over 89 px), so each maps onto joinville.png by a shift and a
scale of 1/4. Each tile's two control points (its top-left and bottom-right corners of the traced area,
in tile pixels and in joinville.png pixels) are kept in TILES below; `--register` finds them again by
cross-correlating the tile's buildings with joinville.png's and prints them.

Out of the tiles come: building footprints (simplified to a few corners, with area and centroid), the
streets by colour class as cells of joinville.png pixels, and water, parks, parking lots and forest as
polygons. All in joinville.png pixels. references/osm_on_reference.png draws it all over joinville.png to
prove the registration by eye; gaps between the tiles are reported, not guessed.

    python tools/trace_osm.py              write city_osm.gd and the overlay picture
    python tools/trace_osm.py --register   find the control points again and print them
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage, signal
from shapely.geometry import MultiPoint, Polygon, box
from shapely.ops import unary_union

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF = os.path.join(ROOT, "references")
OUT = os.path.join(ROOT, "scripts", "world", "city_osm.gd")
OVERLAY = os.path.join(REF, "osm_on_reference.png")

SCALE = 0.25                    # a tile pixel in joinville.png pixels
M_PER_TILE_PX = 50.0 / 89.0     # metres per tile pixel (the scale bar)
CROP = (0, 122, 1868, 1040)     # the map in a tile, without the site's bars and buttons (x0, y0, x1, y1)

# Tile colours (the tiles use a newer map style than joinville.png).
T_BUILDING = [(215, 203, 200), (216, 195, 194), (214, 204, 192)]
J_BUILDING = [(217, 208, 201), (213, 203, 195), (216, 207, 200)]
STREET_CLASSES = {  # name: colours in the tiles
    "trunk": [(221, 159, 159)],
    "primary": [(249, 214, 170), (252, 214, 164)],
    "secondary": [(247, 239, 183), (247, 250, 191)],
    "residential": [(255, 255, 255)],
    "pedestrian": [(225, 225, 225), (221, 221, 232)],
}
AREA_CLASSES = {
    "water": [(181, 208, 208), (170, 211, 223)],
    "park": [(206, 248, 202), (207, 236, 168), (51, 204, 153)],  # park, grass, pitch
    "parking": [(238, 238, 238)],
    "forest": [(190, 218, 179), (173, 209, 158)],
}
MIN_BUILDING_PX = 60            # tile pixels: smaller blobs are labels and dots

# Control points per tile: [[tile x, tile y], [joinville x, joinville y]] for the crop's two corners.
# Found by `--register`; kept here so the trace is the same every run.
TILES = {
    1: [[(0, 122), (1108, 9)], [(1868, 1040), (1575.0, 238.5)]],  # match 0.77
    2: [[(0, 122), (915, 15)], [(1868, 1040), (1382.0, 244.5)]],  # match 0.75
    3: [[(0, 122), (817, 181)], [(1868, 1040), (1284.0, 410.5)]],  # match 0.72
    4: [[(0, 122), (915, 356)], [(1868, 1040), (1382.0, 585.5)]],  # match 0.72
    5: [[(0, 122), (916, 552)], [(1868, 1040), (1383.0, 781.5)]],  # match 0.70
    6: [[(0, 122), (714, 638)], [(1868, 1040), (1181.0, 867.5)]],  # match 0.69
    7: [[(0, 122), (467, 732)], [(1868, 1040), (934.0, 961.5)]],  # match 0.71
    8: [[(0, 122), (536, 516)], [(1868, 1040), (1003.0, 745.5)]],  # match 0.72
    9: [[(0, 122), (631, 294)], [(1868, 1040), (1098.0, 523.5)]],  # match 0.64
}


def colour_mask(a, colours, tol):
    m = np.zeros(a.shape[:2], bool)
    for c in colours:
        m |= (np.abs(a.astype(np.int16) - np.array(c, np.int16)).max(axis=2) <= tol)
    return m


def load(path):
    return np.asarray(Image.open(path).convert("RGB"))


def tile_crop(a):
    x0, y0, x1, y1 = CROP
    return a[y0:y1, x0:x1]


def register(n, jmask):
    """Where tile n's crop lies in joinville.png: (x, y) of its top-left corner, and the match score."""
    t = tile_crop(load(os.path.join(REF, "%d.png" % n)))
    tm = colour_mask(t, T_BUILDING, 8).astype(np.float32)
    h, w = tm.shape
    small = tm[: h - h % 4, : w - w % 4].reshape(h // 4, 4, w // 4, 4).mean(axis=(1, 3))
    small -= small.mean()
    j = jmask.astype(np.float32)
    j -= j.mean()
    num = signal.fftconvolve(j, small[::-1, ::-1], mode="valid")
    energy = signal.fftconvolve(j * j, np.ones_like(small), mode="valid")
    score = num / np.sqrt(np.maximum(energy, 1e-6) * (small * small).sum())
    y, x = np.unravel_index(np.argmax(score), score.shape)
    return int(x), int(y), float(score[y, x])


def to_j(n, p):
    """A tile pixel (in the whole tile image) in joinville.png pixels."""
    (t0, j0), (t1, j1) = TILES[n]
    sx = (j1[0] - j0[0]) / (t1[0] - t0[0])
    sy = (j1[1] - j0[1]) / (t1[1] - t0[1])
    return (j0[0] + (p[0] - t0[0]) * sx, j0[1] + (p[1] - t0[1]) * sy)


def components(mask, min_px):
    lab, count = ndimage.label(mask)
    if count == 0:
        return []
    sizes = ndimage.sum(mask, lab, range(1, count + 1))
    out = []
    slices = ndimage.find_objects(lab)
    for i, sl in enumerate(slices):
        if sizes[i] < min_px:
            continue
        sub = lab[sl] == i + 1
        edge = sub & ~ndimage.binary_erosion(sub)
        ys, xs = np.nonzero(edge)
        out.append((xs + sl[1].start, ys + sl[0].start, int(sizes[i])))
    return out


def trace_buildings(n, a):
    x0, y0 = CROP[0], CROP[1]
    m = colour_mask(tile_crop(a), T_BUILDING, 8)
    m = ndimage.binary_closing(m, iterations=2)  # close the house numbers printed on them
    found = []
    for xs, ys, px in components(m, MIN_BUILDING_PX):
        hull = MultiPoint(list(zip(xs + x0 + 0.5, ys + y0 + 0.5))).convex_hull
        if hull.geom_type != "Polygon":
            continue
        simple = hull.simplify(1.5, preserve_topology=True)
        pts = [to_j(n, p) for p in list(simple.exterior.coords)[:-1]]
        poly = Polygon(pts)
        found.append({"tile": n, "pts": pts, "area": round(px * M_PER_TILE_PX ** 2, 1),
            "centroid": (poly.centroid.x, poly.centroid.y)})
    return found


def trace_cells(n, a, colours, cell):
    """Cells (`cell` joinville.png pixels square) that colour mostly covers, as their centres."""
    x0, y0 = CROP[0], CROP[1]
    m = colour_mask(tile_crop(a), colours, 3)
    k = int(round(cell / SCALE))
    h, w = m.shape
    frac = m[: h - h % k, : w - w % k].reshape(h // k, k, w // k, k).mean(axis=(1, 3))
    ys, xs = np.nonzero(frac > 0.35)
    return [to_j(n, ((x + 0.5) * k + x0, (y + 0.5) * k + y0)) for x, y in zip(xs, ys)]


def cells_to_polygons(cells, cell):
    if not cells:
        return []
    u = unary_union([box(x - cell / 2, y - cell / 2, x + cell / 2, y + cell / 2) for x, y in cells])
    parts = [u] if u.geom_type == "Polygon" else list(u.geoms)
    out = []
    for p in parts:
        p = p.simplify(cell * 0.6, preserve_topology=True)
        if p.is_empty or p.area < cell * cell * 4:
            continue
        out.append({"outer": list(p.exterior.coords)[:-1], "holes": [list(r.coords)[:-1] for r in p.interiors if Polygon(r).area > cell * cell * 4]})
    return out


def v2(p):
    return "Vector2(%.1f, %.1f)" % (p[0], p[1])


def gd_points(pts):
    return "[" + ", ".join(v2(p) for p in pts) + "]"


def main():
    jmask = colour_mask(load(os.path.join(REF, "joinville.png")), J_BUILDING, 8)
    if "--register" in sys.argv:
        print("TILES = {")
        for n in range(1, 10):
            x, y, s = register(n, jmask)
            x0, y0, x1, y1 = CROP
            jx1 = x + (x1 - x0) * SCALE
            jy1 = y + (y1 - y0) * SCALE
            print("    %d: [[(%d, %d), (%d, %d)], [(%d, %d), (%.1f, %.1f)]],  # match %.2f" % (n, x0, y0, x, y, x1, y1, jx1, jy1, s))
        print("}")
        return
    if not TILES:
        sys.exit("No control points yet: run with --register and paste them into TILES.")
    buildings = []
    streets = {k: [] for k in STREET_CLASSES}
    area_cells = {k: [] for k in AREA_CLASSES}
    rects = []
    for n in sorted(TILES):
        a = load(os.path.join(REF, "%d.png" % n))
        for b in trace_buildings(n, a):
            dup = False
            for o in buildings: # the tiles overlap: keep one of each
                if abs(o["centroid"][0] - b["centroid"][0]) < 1.5 and abs(o["centroid"][1] - b["centroid"][1]) < 1.5:
                    dup = True
                    break
            if not dup:
                buildings.append(b)
        for k, cols in STREET_CLASSES.items():
            streets[k].extend(trace_cells(n, a, cols, 1.0))
        for k, cols in AREA_CLASSES.items():
            area_cells[k].extend(trace_cells(n, a, cols, 2.0))
        x0, y0, x1, y1 = CROP
        rects.append((n, to_j(n, (x0, y0)), to_j(n, (x1, y1))))
    for k in streets: # cells from overlapping tiles: once each, on the whole-pixel grid
        streets[k] = sorted(set((math.floor(x), math.floor(y)) for x, y in streets[k]))
    areas = {k: cells_to_polygons(sorted(set((math.floor(x / 2) * 2 + 1, math.floor(y / 2) * 2 + 1) for x, y in v)), 2.0) for k, v in area_cells.items()}
    # Gaps: what the tiles' bounding box holds that no tile covers.
    cover = unary_union([box(r[1][0], r[1][1], r[2][0], r[2][1]) for r in rects])
    hull = cover.envelope
    gaps = hull.difference(cover)
    gap_parts = [] if gaps.is_empty else ([gaps] if gaps.geom_type == "Polygon" else list(gaps.geoms))
    gap_parts = [g for g in gap_parts if g.area > 50]
    write_gd(buildings, streets, areas, rects, gap_parts)
    draw_overlay(buildings, areas, rects, gap_parts)
    print("buildings %d, street cells %s, areas %s, gaps %d (%.0f px²)" % (len(buildings),
        {k: len(v) for k, v in streets.items()}, {k: len(v) for k, v in areas.items()}, len(gap_parts), sum(g.area for g in gap_parts)))


def write_gd(buildings, streets, areas, rects, gaps):
    L = []
    L.append("class_name CityOsm")
    L.append("## GENERATED by tools/trace_osm.py from references/1.png .. 9.png: never edit by hand.")
    L.append("## Everything is in pixels of references/joinville.png (like CityData).")
    L.append("")
    L.append("## Per tile: [[tile x, tile y], [joinville x, joinville y]] for two control points (the traced area's corners).")
    L.append("const TILES := {")
    for n in sorted(TILES):
        (t0, j0), (t1, j1) = TILES[n]
        L.append("\t%d: [[%s, %s], [%s, %s]]," % (n, v2(t0), v2(j0), v2(t1), v2(j1)))
    L.append("}")
    L.append("## Where each tile's traced area lies: [tile, top-left, bottom-right].")
    L.append("const COVER := [" + ", ".join("[%d, %s, %s]" % (n, v2(a), v2(b)) for n, a, b in rects) + "]")
    L.append("## Building footprints: [points, area in m², centroid].")
    L.append("const BUILDINGS := [")
    for b in buildings:
        L.append("\t[%s, %.1f, %s]," % (gd_points(b["pts"]), b["area"], v2(b["centroid"])))
    L.append("]")
    L.append("## Streets by colour class: the centres of the joinville.png pixels each covers.")
    L.append("const STREETS := {")
    for k, cells in streets.items():
        L.append("\t\"%s\": [%s]," % (k, ", ".join("Vector2(%d, %d)" % c for c in cells)))
    L.append("}")
    L.append("## Water, parks, parking lots, forest: polygons as { outer, holes }.")
    L.append("const AREAS := {")
    for k, polys in areas.items():
        L.append("\t\"%s\": [" % k)
        for p in polys:
            L.append("\t\t{ \"outer\": %s, \"holes\": [%s] }," % (gd_points(p["outer"]), ", ".join(gd_points(h) for h in p["holes"])))
        L.append("\t],")
    L.append("}")
    L.append("## Parts of the tiles' bounding box no tile covers (reported, not guessed).")
    L.append("const GAPS := [" + ", ".join(gd_points(list(g.exterior.coords)[:-1]) for g in gaps) + "]")
    L.append("")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L))


def draw_overlay(buildings, areas, rects, gaps):
    im = Image.open(os.path.join(REF, "joinville.png")).convert("RGB")
    im = Image.blend(im, Image.new("RGB", im.size, (255, 255, 255)), 0.45)
    d = ImageDraw.Draw(im)
    for k, col in (("water", (40, 110, 220)), ("forest", (40, 150, 60)), ("park", (120, 200, 90)), ("parking", (150, 150, 150))):
        for p in areas[k]:
            d.polygon([tuple(q) for q in p["outer"]], outline=col)
    for b in buildings:
        d.polygon([tuple(q) for q in b["pts"]], outline=(220, 30, 30))
    for n, a, b in rects:
        d.rectangle([a, b], outline=(30, 30, 200), width=2)
        d.text((a[0] + 4, a[1] + 4), str(n), fill=(30, 30, 200))
    for g in gaps:
        d.polygon([tuple(q) for q in g.exterior.coords], outline=(255, 140, 0), width=3)
    im.save(OVERLAY)


if __name__ == "__main__":
    main()
