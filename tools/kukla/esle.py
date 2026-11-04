"""Örnek resimlerden poz ölçer: kuklanın siluetini her örnek karenin
siluetine oturtan eklem açılarını arar (koordinat inişi; her kare bir
öncekinin pozundan başlar, iki bacak birbirine karışmasın).
Kullanım: python3 tools/kukla/esle.py <sayfa.jpg> <ad> <y0> <y1> [kare sayısı]
Çıktı: build/kukla/esle/<ad>.json ve <ad>_karsilastirma.png"""
import json
import math
import pathlib
import sys

from PIL import Image, ImageChops, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import rig  # noqa: E402

OUT = rig.ROOT / "build/kukla/esle"
OUT.mkdir(parents=True, exist_ok=True)
W, H = 260, 300
FIG = 240.0  # örnek figürün boyu (piksel)


def fill_holes(m):
    """Kapalı delikleri (göz, etek oymaları) doldurur: arka plan köşeden
    doldurulur, ulaşılamayan her yer figürdür."""
    inv = m.point(lambda v: 0 if v else 255)
    ImageDraw.floodfill(inv, (0, 0), 128)
    return inv.point(lambda v: 0 if v == 128 else 255)


def figure_mask(img):
    rgb = img.convert("RGB")
    px = rgb.load()
    m = Image.new("L", rgb.size, 0)
    mp = m.load()
    for y in range(rgb.size[1]):
        for x in range(rgb.size[0]):
            r, g, b = px[x, y]
            lum = 0.3 * r + 0.59 * g + 0.11 * b
            # Koyu siluet ve kırmızı atkı/kurdele; amber kavanoz (yeşili yüksek)
            # katılmaz: kuklada ayrı çizilir.
            if lum < 95 or (r > 110 and g < 110 and r - g > 45 and r - b > 35):
                mp[x, y] = 255
    return m


def frames(path, y0, y1, n):
    im = Image.open(path)
    band = im.crop((0, y0, im.size[0], y1))
    m = figure_mask(band)
    cols = [sum(1 for y in range(0, m.size[1], 3) if m.getpixel((x, y))) for x in range(m.size[0])]
    segs, inside = [], False
    for x, c in enumerate(cols + [0]):
        if c > 1 and not inside:
            s, inside = x, True
        elif c <= 1 and inside:
            inside = False
            if x - s > 30:
                segs.append((s, x))
    # Birbirine değen iki figür tek parça sayılırsa, çok geniş parçaları böl.
    out = []
    for a, b in segs:
        box = m.crop((a, 0, b, m.size[1])).getbbox()
        out.append((a, box[1], b, box[3]))
    return band, m, out[:n]


def ref_canvas(m, box):
    a, t, b, bot = box
    crop = m.crop((a, t, b, bot))
    s = FIG / (bot - t)
    crop = crop.resize((max(1, int((b - a) * s)), int(FIG)))
    can = Image.new("L", (W, H), 0)
    can.paste(crop, ((W - crop.size[0]) // 2, H - 20 - crop.size[1]))
    return fill_holes(can.point(lambda v: 255 if v > 127 else 0)), s


def rig_mask(p):
    can = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(can)
    for name, pr in rig.polygons(p):
        for r in pr[:1]:
            if len(r) > 2:
                d.polygon(r, fill=255)
    return can


def iou(a, b):
    inter = ImageChops.logical_and(a.convert("1"), b.convert("1"))
    uni = ImageChops.logical_or(a.convert("1"), b.convert("1"))
    i = inter.histogram()[-1]
    u = uni.histogram()[-1]
    return i / u if u else 0


STEPS = {"x": 6, "y": 6, "k": 0.006, "lean": 0.25, "head": 0.2, "skirt": 0.2,
         "sf": 0.5, "ef": 0.5, "sb": 0.5, "eb": 0.5, "tf": 0.4, "kf": 0.5, "af": 0.4,
         "tb": 0.4, "kb": 0.5, "ab": 0.4, "braid": 0.4, "scarf": 0.4}
# Doğal sınırlar: siluetin içinde kaybolan kol ve bacak saçma açılara
# kaçmasın (yürürken diz en çok ~70°, gövde hafif eğik).
MODES = {
    "yuru": {"kf": (0.0, 1.2), "kb": (0.0, 1.2), "tf": (-0.8, 0.8), "tb": (-0.8, 0.8),
             "ef": (-0.3, 1.5), "eb": (-0.6, 1.3), "sf": (-0.9, 0.9), "sb": (0.0, 1.7),
             "lean": (-0.08, 0.2), "head": (-0.25, 0.25), "skirt": (-0.3, 0.3),
             "af": (-0.6, 0.7), "ab": (-0.6, 0.7), "braid": (-0.8, 0.8), "scarf": (-0.8, 0.8)},
    "kos": {"kf": (0.0, 2.0), "kb": (0.0, 2.0), "tf": (-1.1, 1.0), "tb": (-1.1, 1.0),
            "ef": (-1.8, 1.6), "eb": (-1.8, 1.6), "sf": (-1.2, 1.2), "sb": (-0.6, 1.9),
            "lean": (0.0, 0.35), "head": (-0.3, 0.25), "skirt": (-0.3, 0.3),
            "af": (-0.9, 0.8), "ab": (-0.9, 0.8), "braid": (-0.8, 0.8), "scarf": (-0.8, 0.8)},
}
LIMITS = MODES["yuru"]
# Süreklilik: önceki kareden uzaklaştıkça az bir ceza (radyan kare başına).
PREV = None
CONT = 0.012
ANGLES = ["lean", "head", "skirt", "sf", "ef", "sb", "eb", "tf", "kf", "af", "tb", "kb", "ab", "braid", "scarf"]


def clampp(q):
    for n, (lo, hi) in LIMITS.items():
        q[n] = min(hi, max(lo, q[n]))
    return q


def score(ref, q):
    s = iou(ref, rig_mask(q))
    if PREV:
        s -= CONT * sum((q[n] - PREV[n]) ** 2 for n in ANGLES)
    return s


def grid(ref, p, a, b, ra, rb, step_a, step_b):
    """İki açıyı birlikte tarar (kalça-diz, omuz-dirsek)."""
    best = (score(ref, p), p[a], p[b])
    x = ra[0]
    while x <= ra[1] + 1e-9:
        y = rb[0]
        while y <= rb[1] + 1e-9:
            q = dict(p)
            q[a], q[b] = x, y
            clampp(q)
            if q[a] != x or q[b] != y:
                y += step_b
                continue
            s = score(ref, q)
            if s > best[0]:
                best = (s, x, y)
            y += step_b
        x += step_a
    q = dict(p)
    q[a], q[b] = best[1], best[2]
    return q


def staged(ref, p0, near_first=True):
    p = dict(p0)
    # 1) Gövdenin yeri, boyu, eğimi.
    p, _ = fit(ref, p, rounds=3, only=["x", "y", "k", "lean"])
    # 2) Bacaklar: her biri için kalça-diz taraması (iki tur).
    legs = [("tf", "kf"), ("tb", "kb")]
    if not near_first:
        legs.reverse()
    for _ in range(2):
        for a, b in legs:
            p = grid(ref, p, a, b, (-1.1, 1.1), (0.0, 2.0), 0.1, 0.12)
    # 3) Kollar.
    p = grid(ref, p, "sf", "ef", (-1.4, 1.4), (-2.2, 1.4), 0.15, 0.2)
    p = grid(ref, p, "sb", "eb", (-1.4, 1.8), (-2.2, 1.4), 0.15, 0.2)
    # 4) Hepsi birlikte ince ayar.
    return fit(ref, p, rounds=4)


def fit(ref, p0, rounds=6, only=None):
    p = dict(p0)
    best = score(ref, p)
    scale = 1.0
    for _ in range(rounds):
        improved = True
        while improved:
            improved = False
            for n in (only or rig.PARAMS):
                for sgn in (1, -1):
                    q = dict(p)
                    q[n] += sgn * STEPS[n] * scale
                    clampp(q)
                    s = score(ref, q)
                    if s > best + 1e-5:
                        p, best, improved = q, s, True
        scale *= 0.5
    return p, best


def initial(ref):
    box = ref.getbbox()
    p = rig.rest_pose()
    # Kuklanın ayakta boyu ~1706 birim (kısa bacaklarla): örnek boyuna göre.
    p["k"] = (box[3] - box[1]) / 1706.0
    p["x"] = (box[0] + box[2]) / 2 - 30 * p["k"] / 0.24 * 0.24
    p["y"] = box[3] - (1892.5 - 1330) * p["k"]
    return p


def main():
    path, name, y0, y1 = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
    n = int(sys.argv[5]) if len(sys.argv) > 5 else 8
    global LIMITS, PREV
    LIMITS = MODES[sys.argv[6] if len(sys.argv) > 6 else "yuru"]
    seed = None
    if len(sys.argv) > 7:
        seed = json.loads(pathlib.Path(sys.argv[7]).read_text())[-1]["pose"]
    band, m, boxes = frames(path, y0, y1, n)
    print(name, len(boxes), "kare")
    res, prev = [], seed
    sheet = []
    for i, box in enumerate(boxes):
        ref, s = ref_canvas(m, box)
        PREV = prev
        starts = [prev] if prev else []
        base = clampp(initial(ref))
        starts.append(base)
        if not prev:
            sw = dict(base)
            for a, b in (("tf", "tb"), ("kf", "kb"), ("af", "ab")):
                sw[a], sw[b] = base[b], base[a]
            starts.append(sw)
        best = None
        for st in starts:
            q = dict(st)
            if prev:
                q["x"], q["y"], q["k"] = base["x"], base["y"], prev["k"]
            fp, sc = staged(ref, q)
            if best is None or sc > best[1]:
                best = (fp, sc)
        p, sc = best
        prev = p
        res.append({"pose": p, "iou": iou(ref, rig_mask(p))})
        sc = res[-1]["iou"]
        print(f"  kare {i}: örtüşme {sc:.3f}")
        # Karşılaştırma: örnek kırmızı, kukla mavi, örtüşen mor.
        rm = rig_mask(p)
        img = Image.merge("RGB", (ref, Image.new("L", (W, H), 0), rm))
        bg = Image.new("RGB", (W, H), (235, 220, 190))
        comp = Image.composite(img, bg, ImageChops.lighter(ref, rm))
        sheet.append(comp)
    (OUT / f"{name}.json").write_text(json.dumps(res, indent=1))
    full = Image.new("RGB", (W * len(sheet), H), (40, 40, 40))
    for i, c in enumerate(sheet):
        full.paste(c, (i * W, 0))
    full.save(OUT / f"{name}_karsilastirma.png")


if __name__ == "__main__":
    main()
