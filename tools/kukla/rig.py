"""Sâye (A1) kuklasının Python eşi: kukla2_test.dart ile aynı kemikler ve
deri giydirme. Örnek resimlerden poz ölçmek (eşleme) için silueti çizer.
Veri: build/kukla/kukla2.json (duruş koordinatı)."""
import json
import math
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
D = json.loads((ROOT / "build/kukla/kukla2.json").read_text())

HIP0 = (830, 1330)
NECK = (813, 705)
WAIST = (845, 1050)
SF, EF, HF = (905, 770), (1085, 960), (1420, 955)
BACK_ARM = (-55, 0)
NEAR_LEG, BACK_LEG = (-100, 0), (-122, 0)
# Bacak A1'deki gibi kısa (şalvar yüzde 30 kısaltıldı, çizme aynı).
LEG_H, LEG_K, LEG_A = (900, 1330), (921, 1540), (957, 1732.5)


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def ang(v):
    return math.atan2(v[1], v[0])


def smooth(v):
    c = min(1.0, max(0.0, v))
    return c * c * (3 - 2 * c)


class Af:
    __slots__ = ("a", "b", "c", "d", "tx", "ty")

    def __init__(self, a, b, c, d, tx, ty):
        self.a, self.b, self.c, self.d, self.tx, self.ty = a, b, c, d, tx, ty

    def __call__(self, p):
        return (self.a * p[0] + self.c * p[1] + self.tx, self.b * p[0] + self.d * p[1] + self.ty)

    @staticmethod
    def bone(at, th, k, rest):
        c, s = math.cos(th), math.sin(th)
        # t(at) * r(th) * s(k) * t(-rest)
        a, b, cc, d = c * k, s * k, -s * k, c * k
        return Af(a, b, cc, d, at[0] - (a * rest[0] + cc * rest[1]), at[1] - (b * rest[0] + d * rest[1]))


def along(line, v):
    best, at, acc = 1e18, 0.0, 0.0
    for i in range(len(line) - 1):
        a, b = line[i], line[i + 1]
        ab = sub(b, a)
        L2 = ab[0] ** 2 + ab[1] ** 2
        t = min(1.0, max(0.0, ((v[0] - a[0]) * ab[0] + (v[1] - a[1]) * ab[1]) / L2))
        q = (a[0] + ab[0] * t, a[1] + ab[1] * t)
        d = math.hypot(v[0] - q[0], v[1] - q[1])
        if d < best:
            best, at = d, acc + math.sqrt(L2) * t
        acc += math.sqrt(L2)
    return at


def rings(name, shift=(0, 0)):
    return [[(p[0] + shift[0], p[1] + shift[1]) for p in r] for r in D["layers"][name]]


# Kemikler: 0 gövde, 1 etek, 2 baş, 3/4 ön kol üst/alt, 5/6 arka kol, 7/8/9 ön
# uyluk/baldır/ayak, 10/11/12 arka; 13 örgü, 14 atkı (eşlemede tek parça).
def limb_w(v, line, a, b, band=40):
    u = along(line, v)
    j = math.dist(line[0], line[1])
    k = smooth((u - (j - band)) / (2 * band))
    return [(a, 1 - k), (b, k)]


def leg_w(v, shift, th, sh, ft):
    h, k, a = add(LEG_H, shift), add(LEG_K, shift), add(LEG_A, shift)
    foot = smooth((v[1] - (a[1] - 25)) / 50)
    u = along([h, k, a], v)
    kn = smooth((u - (math.dist(h, k) - 120)) / 240)
    return [(th, (1 - foot) * (1 - kn)), (sh, (1 - foot) * kn), (ft, foot)]


def build():
    L = []
    ba = add(SF, BACK_ARM), add(EF, BACK_ARM), add(HF, BACK_ARM)
    L.append(("kolB", rings("kol", BACK_ARM), lambda v: limb_w(v, list(ba), 5, 6)))
    L.append(("bacakB", rings("bacak", BACK_LEG), lambda v: leg_w(v, BACK_LEG, 10, 11, 12)))
    L.append(("atki", rings("atki_uclar"), lambda v: [(14, 1)]))
    L.append(("orgu", rings("orgu"), lambda v: [(13, 1)]))
    L.append(("bacakF", rings("bacak", NEAR_LEG), lambda v: leg_w(v, NEAR_LEG, 7, 8, 9)))
    L.append(("govde", rings("govde"), lambda v: [(0, 1 - smooth((v[1] - 1000) / 160)), (1, smooth((v[1] - 1000) / 160))]))
    L.append(("bas", rings("bas"), lambda v: [(2, 1)]))
    L.append(("dugum", rings("atki_dugum"), lambda v: [(0, 1)]))
    L.append(("kolF", rings("kol"), lambda v: limb_w(v, [SF, EF, HF], 3, 4)))
    out = []
    for name, rs, wf in L:
        ws = [[[(b, w) for b, w in wf(v) if w > 1e-4] for v in r] for r in rs]
        out.append((name, rs, ws))
    return out


LAYERS = build()
BRAID_ROOT = tuple(D["braid"][0])
SCARF_ROOT = tuple(D["scarf"][0])

PARAMS = ["x", "y", "k", "lean", "head", "skirt", "sf", "ef", "sb", "eb",
          "tf", "kf", "af", "tb", "kb", "ab", "braid", "scarf"]


def bones(p):
    k = p["k"]
    torso = Af.bone((p["x"], p["y"]), p["lean"], k, HIP0)
    skirt = Af.bone(torso(WAIST), p["lean"] + p["skirt"], k, WAIST)
    head = Af.bone(torso(NECK), p["lean"] + p["head"], k, NECK)
    uF = Af.bone(torso(SF), p["lean"] + p["sf"], k, SF)
    fF = Af.bone(uF(EF), p["lean"] + p["sf"] + p["ef"], k, EF)
    sb, eb = add(SF, BACK_ARM), add(EF, BACK_ARM)
    uB = Af.bone(torso(sb), p["lean"] + p["sb"], k, sb)
    fB = Af.bone(uB(eb), p["lean"] + p["sb"] + p["eb"], k, eb)

    def leg(shift, t, kk, a):
        h, kn, an = add(LEG_H, shift), add(LEG_K, shift), add(LEG_A, shift)
        th = Af.bone(torso(h), t, k, h)
        sh = Af.bone(th(kn), t + kk, k, kn)
        ft = Af.bone(sh(an), t + kk + a, k, an)
        return th, sh, ft

    tF, sF, aF = leg(NEAR_LEG, p["tf"], p["kf"], p["af"])
    tB, sB, aB = leg(BACK_LEG, p["tb"], p["kb"], p["ab"])
    braid = Af.bone(head(BRAID_ROOT), p["lean"] + p["head"] + p["braid"], k, BRAID_ROOT)
    scarf = Af.bone(torso(SCARF_ROOT), p["lean"] + p["scarf"], k, SCARF_ROOT)
    return [torso, skirt, head, uF, fF, uB, fB, tF, sF, aF, tB, sB, aB, braid, scarf]


def polygons(p):
    """Her katmanın dönüşmüş halkaları (çizim sırasıyla)."""
    bs = bones(p)
    out = []
    for name, rs, ws in LAYERS:
        pr = []
        for r, wr in zip(rs, ws):
            pts = []
            for v, w in zip(r, wr):
                x = y = 0.0
                for b, wt in w:
                    q = bs[b](v)
                    x += q[0] * wt
                    y += q[1] * wt
                pts.append((x, y))
            pr.append(pts)
        out.append((name, pr))
    return out


def rest_pose():
    p = {n: 0.0 for n in PARAMS}
    p["k"] = 0.24
    p["sb"], p["eb"] = 0.81, 0.6
    return p
