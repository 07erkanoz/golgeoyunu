"""Bölüm denetleyicisi: reach.py'nin oyunun gerçek kurallarıyla sıkılaştırılmış hali.

reach.py'nin cömert kaldığı ve gerçek hataları kaçırdığı yerler burada
oyundaki gibi işlenir:

- Kapılar (`H`) kapalı başlar. Açan düzeneğe varılınca en yakın kapı açılır
  ve tarama yeniden yapılır: kol `L`; tüy sunağı `s` (bütün `T` tüylerine
  varılabiliyorsa); güneş kilidi `t` (kilit ve aynalar `m`/`h`); yıldız
  taşları `*` (hepsi); Nemrut'un taş devi (backtick, sağındaki kapı); Gemi'de
  kaideler `d` (hepsi).
- Gölge tahtası `n`: Sâye'nin kendi kavanozu onu siler; yalnızca çömelerek,
  yandaki zeminden yürüyerek geçilir. Üstüne zıplayarak ya da düşerek inilmez.
- Kayan kayalar ve teraziler gerçek yollarında: dikey kaya `V` 4 kare yukarı,
  yatay `R` 4 kare sağa; terazi kefeleri `A`/`Y` en çok 4 kare, suya gömülmez.
- Sıkışma: girilen ama ne çıkışa ne bir ölüme (yeniden doğuş) bağlanan duruş
  noktaları raporlanır.

Sandıklar (`C`) basamak sayılmaz: sandık bulmacalarında "varılamaz" çıkan
yerler elle bakılmalıdır.

Kullanım: python3 tools/audit.py [bölüm_no ...]
"""
import math
import re
import sys
from collections import defaultdict

T = 32.0
W_P, H_P = 14.0, 28.0
JUMP, G, RUN, MAXFALL = 580.0, 1900.0, 160.0, 900.0
GLIDE_X, GLIDE_FALL = 205.0, 75.0
DT = 1 / 60

LEVELS = [
    ('kMapYerebatan', False, 0), ('kMapKule', False, 0), ('kMapGokyolu', True, 0),
    ('kMapKaf', True, 0), ('kMapAgri', True, 140), ('kMapGemi', True, 0),
    ('kMapNemrut', True, 80), ('kMapGunDogumu', True, 0), ('kMapKarYolu', True, 120),
    ('kMapPalandoken', None, 0), ('kMapCig', None, 0), ('kMapPeri', True, 0),
    ('kMapDerinkuyu', True, 0), ('kMapKonya', True, 0),
    ('kMapErlik', False, 0), ('kMapErgenekon', False, 0), ('kMapGok', True, 0),
    ('kMapOtuken', False, 0), ('kMapGok2', True, 0), ('kMapYesilKubbe', True, 0),
]

# Ötüken Ormanı: `a` Ak Geyik, `d` geyik kökü (üstüne basılmaz). Geyik
# ateşböceğiyle köke götürülür: köke varılınca en yakın kapı açılır
# (geyiğin yürüyüşü benzetilmez, oyun içi sınamayla doğrulanır).
FOREST = {'kMapOtuken'}
# Yeşil Kubbe: kafesler (levels.dart cages) kol gibi en yakın kapıyı açar;
# finalin üç aynasına varılınca Kandilci Başı çıkış kapısını açar; avlunun
# ay kilidi havadadır (aynalara varmak yeter).
CAGES = {'kMapYesilKubbe': [(92, 51), (132, 51), (182, 51)]}
FINALE = {'kMapYesilKubbe': [(266, 9), (272, 7), (296, 9)],
          # Gemi'nin Delikli Ambarı: üç deliğe (sandıkla) varılınca kapı açılır.
          'kMapGemi': [(191, 25), (209, 25), (225, 25)]}
LOCK_ANY = {'kMapYesilKubbe'}
# Kaf: aynalı gölün görünmeyen basamakları ve kuşlardan köprü (kuşlar
# hareketli; denetimde uçuş satırında üç karede bir kuş sayılır).
_KAF_STEPS = [(8,17),(12,16),(16,17),(26,16),(30,16),(34,17),(38,17),(46,16),(50,16),(54,17),(58,17)]
def _stream(pts, step=3):
    out = []
    for (c0, r0), (c1, r1) in zip(pts, pts[1:]):
        for c in range(c0, c1, step):
            r = round(r0 + (r1 - r0) * (c - c0) / (c1 - c0)) + 1
            out.append((c, r, 2))
    return out


# Göğün Katları, Kuş Yolu: ışık nehri taşır (denetimde nehrin boyunca
# tahta sayılır); Ülker köprüsü yıldızlar yanınca (yıldızlar bulutun
# üstünde, varılır).
DECKS = {'kMapKaf': [(122 + c, r, 2) for c, r in _KAF_STEPS]
         + [(c, 16, 2) for c in range(275, 324, 3)],
         'kMapGok': _stream([(295, 23), (300, 20), (306, 16), (312, 13), (318, 11), (323, 11)])
         + _stream([(362, 11), (367, 14), (373, 18), (379, 22), (384, 23)])
         + [(c, 12, 2) for c in range(334, 356, 2)]}

# Göğün katları: `W` Tulpar'dır (kanat değil). Ona varılınca Tulpar'la uçulur;
# uçuş benzetilmez: Tulpar'ın sağındaki hedefler varılmış sayılır (yaklaşık,
# oyun içi sınamayla doğrulanır).
FLYING = {'kMapGok2'}

# Ergenekon: `d` demir damarı kapı gibi kapalıdır; ona bağlı bütün körüklere
# (LevelDef.bellows, sırası > 0, en yakın damara bağlı) varılınca erir.
VEINS = {'kMapErgenekon'}


def _def_block(name):
    """Bölüm tanımının tamamı (map satırından sonrakiler de: coldRuns…)."""
    src = open('lib/game/levels.dart', encoding='utf-8').read()
    i = src.index('map: %s,' % name)
    j = src.rindex('LevelDef(', 0, i)
    k = src.find('LevelDef(', i)
    return src[j:k if k > 0 else len(src)]


def heavens_extras(name):
    """Göğün katlarının harita dışı düzenekleri (levels.dart): yıldız
    çarklarının yolu ve şimşek basamakları basılabilir yer sayılır (yaklaşık:
    çarkın her açısı); Yel Ana'nın alanlarında süzülüş soluğun gücüyle uzar
    (yada taşı yönü çevirdiğinden iki yöne de)."""
    b = _def_block(name)
    cells, zones = set(), []
    m = re.search(r'wheels:\s*\[(.*?)\],', b, re.S)
    if m:
        for c, r, rad in re.findall(r'\((\d+),\s*(\d+),\s*([\d.]+),', m.group(1)):
            c, r, rad = int(c), int(r), float(rad)
            for k in range(48):
                a = k / 48 * 2 * math.pi
                x = c + 0.5 + math.cos(a) * rad
                y = r + 0.5 + math.sin(a) * rad
                cells.add((int(x - 1), int(y)))
                cells.add((int(x), int(y)))
    m = re.search(r'stormSteps:\s*\[(.*?)\],', b, re.S)
    if m:
        for c, r, n in re.findall(r'\((\d+),\s*(\d+),\s*(\d+)\)', m.group(1)):
            for k in range(int(n)):
                cells.add((int(c) + k, int(r)))
    # Kandilci yolu (coldRuns): yalnız Kandilcinin feneriyle belirir; burada
    # basılır sayılır (ateşböceğiyle kandırılan Kandilci oyun içi sınamayla
    # doğrulanır: test/kandilci_yolu_test.dart).
    m = re.search(r'coldRuns:\s*\[(.*?)\],', b, re.S)
    if m:
        for c, r, n in re.findall(r'\((\d+),\s*(\d+),\s*(\d+)\)', m.group(1)):
            for k in range(int(n)):
                cells.add((int(c) + k, int(r)))
    m = re.search(r'yel:\s*\[(.*?)\],', b, re.S)
    if m:
        for t in re.findall(r'\((\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*-?\d+\)', m.group(1)):
            zones.append(tuple(int(v) for v in t))
    return cells, zones


def bellows_of(name):
    src = open('lib/game/levels.dart', encoding='utf-8').read()
    i = src.index('map: %s' % name)
    j = src.rindex('LevelDef(', 0, i)
    block = src[j:i]
    k = block.find('bellows: [')
    if k < 0:
        return []
    body = block[k:block.index(']', k)]
    return [tuple(int(v) for v in t) for t in re.findall(r'\((\d+),\s*(\d+),\s*(\d+)\)', body)]

def nevruz_of(name):
    """Bölümün Nevruz örsü (levels.dart `nevruz: (sütun, satır)`): üç kez
    vurulunca sağındaki en yakın kapıyı açar."""
    src = open('lib/game/levels.dart', encoding='utf-8').read()
    i = src.index('map: %s' % name)
    j = src.rindex('LevelDef(', 0, i)
    k = src.find('LevelDef(', i)
    block = src[j:k if k > 0 else len(src)]
    m = re.search(r'nevruz:\s*\((\d+),\s*(\d+)\)', block)
    return (int(m.group(1)), int(m.group(2))) if m else None


# Yerin altı (Erlik'in katı): `a` kut kafesi (kol gibi en yakın kapıyı
# açar, üstüne basılmaz), `b` Körmös (havada, engel değil), `W` Çalkuyruk:
# ona varılınca atla zıplanır (1.42 kat hız: yaklaşık iki kat yükseklik).
UNDERWORLD = {'kMapErlik'}
HORSE_JUMP = 1.42

ONEWAY = set('=luO/fAYRV_dC@a')     # üstüne basılır (n ayrı işlenir)
DEADLY = set('w^')
TARGETS = set('KMEB123456789()[]{}LvyWTs*tm')


def load(name):
    src = open('lib/game/maps.dart', encoding='utf-8').read()
    m = re.search(r"const %s = <String>\[(.*?)\];" % name, src, re.S)
    rows = []
    for line in m.group(1).split('\n'):
        line = line.strip()
        if line.startswith("'"):
            rows.append(line[1:-2].replace("\\'", "'").replace('\\$', '$'))
    return rows


class Map:
    def __init__(self, rows, wings, headwind, opened, konya=False,
                 underworld=False, jump_k=1.0):
        self.rows = rows
        self.h = len(rows)
        self.w = len(rows[0])
        self.underworld = underworld
        self.forest = False
        self.yel = []
        self.jump_k = jump_k
        self.run_k = 1.4 if jump_k > 1 else 1.0          # atın koşusu
        self.wings = (wings or any('W' in r for r in rows)) and not underworld
        self.mount = False                       # W Tulpar ise kanat sayılmaz
        self.glide_x = max(40.0, GLIDE_X - headwind)
        self.opened = opened                     # açılmış kapı hücreleri
        self.konya = konya
        self.extra = set()
        # Sağanak (`<` sol üst, `>` sağ alt; oyundaki gibi sırayla eşlenir):
        # içindeyken kanatlar ıslanır, süzülünmez.
        self.rain = []
        starts = []
        for r, row in enumerate(rows):
            for c, ch in enumerate(row):
                if ch == '<':
                    starts.append((c, r))
                elif ch == '>' and starts:
                    c0, r0 = starts.pop(0)
                    self.rain.append((c0, r0, c, r))
        self.generous = set()                    # yaklaşık sayılan düzenekler
        for r, row in enumerate(rows):
            for c, ch in enumerate(row):
                if ch == 'C':
                    # Sandık durduğu zemin boyunca itilebilir; itilebildiği
                    # her yerde üstü basamaktır (yaklaşık).
                    for d in (-1, 1):
                        k = c
                        while 0 <= k < self.w and rows[r][k] in '.CKBpF123456789M' and \
                                r + 1 < self.h and rows[r + 1][k] in '#=-':
                            self.extra.add((k, r))
                            self.generous.add((k, r))
                            k += d
                if ch == '@':
                    # Sürgü taşı / kalkan: zemini boyunca sağa itilir; zemin
                    # bitince aşağıdaki zemine düşer, itilmeye devam eder.
                    # (Sola itiş benzetilmez: düştüğü geçitleri tıkamış
                    # sayılmasın.)
                    for d in (1,):
                        k, rr = c, r
                        for _ in range(200):
                            if not (0 <= k < self.w):
                                break
                            if rows[rr][k] in '#H':
                                break
                            below = rows[rr + 1][k] if rr + 1 < self.h else '#'
                            if below in '#=-':
                                self.extra.add((k, rr))
                                self.generous.add((k, rr))
                                k += d
                            else:
                                rr += 1
                                if rr + 1 >= self.h:
                                    break
                if ch == 'O':                    # çöken kaya: iki kare geniş
                    self.extra.add((c + 1, r))
                if ch == 'V':                    # 4 kare yukarı çıkar
                    for k in range(-4, 1):
                        self.extra |= {(c, r + k), (c + 1, r + k)}
                elif ch == 'R':                  # 4 kare sağa gider
                    for k in range(0, 6):
                        self.extra.add((c + k, r))
                elif ch in 'AY':                 # terazi: suya gömülmez
                    travel = 4
                    for rr in range(r + 1, min(self.h, r + 5)):
                        if rows[rr][c] == 'w' or rows[rr][c + 1] == 'w':
                            travel = min(travel, rr - r - 1)
                            break
                    for k in range(-travel, travel + 1):
                        self.extra |= {(c, r + k), (c + 1, r + k)}
                elif ch == 'f':                  # yüzen tahta: haznenin dibinden ağzına
                    top, bottom = r - 8, r + 8
                    qs = [(x, y) for y, rw in enumerate(rows) for x, v in enumerate(rw) if v == 'q']
                    Qs = [(x, y) for y, rw in enumerate(rows) for x, v in enumerate(rw) if v == 'Q']
                    for qc, qr in qs:
                        for Qc, Qr in Qs:
                            if qc <= c <= Qc and qr <= r <= Qr:
                                top, bottom = qr, Qr
                    for rr in range(top, bottom + 1):
                        self.extra |= {(c, rr), (c + 1, rr), (c + 2, rr)}
                        self.generous.add((c, rr))
                elif ch == 'd' and self.konya:
                    # Avize: kollarındaki mum tablaları göbeğin çevresinde
                    # döner (yarıçap ~4 kare).
                    for dc in range(-5, 6):
                        for dr in range(-5, 6):
                            if dc * dc + dr * dr <= 26:
                                self.extra.add((c + dc, r + dr))
                elif ch == '_':
                    k = c
                    while k < self.w and r + 1 < self.h and rows[r + 1][k] == 'w':
                        self.extra.add((k, r))
                        k += 1

    def in_rain(self, c, r):
        return any(c0 <= c <= c1 and r0 <= r <= r1 for c0, r0, c1, r1 in self.rain)

    def cell(self, c, r):
        if c < 0 or c >= self.w:
            return '#'                           # yanlar her yükseklikte duvar
        if r < 0 or r >= self.h:
            return '.'                           # üstü açık, altı dipsiz
        ch = self.rows[r][c]
        if ch == 'H' and (c, r) in self.opened:
            return '.'
        if self.underworld and ch in 'ab':
            return '.'
        if self.forest and ch in 'ad':
            return '.'
        return ch

    def solid(self, c, r):
        return self.cell(c, r) in '#-H'

    def oneway(self, c, r):
        return self.cell(c, r) in ONEWAY or (c, r) in self.extra

    def shade(self, c, r):
        return self.cell(c, r) == 'n'

    def floor(self, c, r):
        """Zıplayarak ya da yürüyerek durulabilir mi (gölge tahtası hariç)?"""
        if self.solid(c, r) or self.cell(c, r) in DEADLY:
            return False
        return self.solid(c, r + 1) or self.oneway(c, r + 1)

    def box_solid(self, x, y):
        c0, c1 = int((x + 1) // T), int((x + W_P - 1) // T)
        r0, r1 = int((y + 1) // T), int((y + H_P - 1) // T)
        for c in range(c0, c1 + 1):
            for r in range(r0, r1 + 1):
                if self.solid(c, r):
                    return True
        return False


def simulate(m, x, y, vx0, glide, swing=None, release=None):
    """Bir atlayış; (konulan yerler, ölümle bitti mi)."""
    out = set()
    vx = vx0
    vy = -JUMP * m.jump_k if swing is None else swing
    for step in range(int(8 / DT)):
        if release is not None and step * DT > release:
            glide = False
        wet = m.rain and m.in_rain(int((x + W_P / 2) // T), int((y + H_P / 2) // T))
        gliding = glide and m.wings and not wet and (vy > -40 or m.cell(
            int((x + W_P / 2) // T), int((y + H_P / 2) // T)) == 'r')
        if gliding:
            vy = min(vy + G * 0.3 * DT, GLIDE_FALL)
            if vx0:
                gx = m.glide_x
                cc0, cr0 = (x + W_P / 2) / T, (y + H_P / 2) / T
                if any(a <= cc0 <= c and b <= cr0 <= d for a, b, c, d in m.yel):
                    gx += 230 * 1.5
                vx = (1 if vx0 > 0 else -1) * gx
        else:
            vy = min(vy + G * DT, MAXFALL)
        cc = int((x + W_P / 2) // T)
        cr = int((y + H_P / 2) // T)
        AIR.add((cc, cr))
        ch = m.cell(cc, cr)
        if ch == 'r':
            vy = max(vy - 2600 * DT, -260) if (glide and m.wings and not wet) else vy - 1100 * DT
            if vy < -150:
                vx = 0
            elif vx0:
                vx = (1 if vx0 > 0 else -1) * m.glide_x
        elif vx == 0 and vx0 and not m.box_solid(x + (1 if vx0 > 0 else -1), y):
            vx = vx0
        if ch in '|S':
            out.add(('vine', cc, cr))
        # Kenara tutunma (oyundaki kural): yalnızca # ve = tutulur.
        if vx0 and vy > -60:
            d = 1 if vx0 > 0 else -1
            pc = int(((x + W_P + 3) if d > 0 else (x - 3)) // T)
            oc0, oc1 = int((x + 1) // T), int((x + W_P - 1) // T)
            hand = y
            for r in range(math.ceil((hand - 8) / T), int((hand + 16) // T) + 1):
                # Oyunda yalnızca kaya ve tahta karoları tutulur (kapı bir
                # nesnedir, tepesine tutunulmaz).
                held = lambda c, rr: m.cell(c, rr) in '#=-'
                if not held(pc, r) or held(pc, r - 1) or held(pc, r - 2):
                    continue
                if all(not held(oc, rr) for oc in range(oc0, oc1 + 1) for rr in (r, r - 1, r - 2)):
                    out.add(('stand', pc, r - 1))
        nx = x + vx * DT
        if m.box_solid(nx, y):
            vx = 0
        else:
            x = nx
        ny = y + vy * DT
        if vy < 0:
            if m.box_solid(x, ny):
                vy = 0
            else:
                y = ny
        else:
            prev_bottom = y + H_P
            new_bottom = ny + H_P
            landed = False
            for c in range(int((x + 4) // T), int((x + W_P - 4) // T) + 1):
                r = int(new_bottom // T)
                top = r * T
                if prev_bottom <= top + 1 and new_bottom >= top:
                    if m.solid(c, r) or m.oneway(c, r):
                        if m.cell(c, r - 1) in DEADLY:
                            return out, True
                        out.add(('stand', c, r - 1))
                        landed = True
                        break
                    if m.cell(c, r) in DEADLY and m.cell(c, r - 1) not in DEADLY:
                        return out, True
            if landed:
                return out, False
            y = ny
            if m.box_solid(x, y):
                return out, False
        if y > m.h * T:
            return out, True
        if m.cell(int((x + W_P / 2) // T), int((y + H_P) // T)) == '"':
            vy = -880
    return out, False


GLIDES = [(False, None), (True, None), (True, 0.6), (True, 0.9), (True, 1.3)]

# Atlayışların gövde merkeziyle geçtiği hücreler (havada alınan hatıra/tüy).
AIR = set()


def search(m, start):
    """Duruş noktaları, kenarlar ve ölümle kaçılabilen noktalar."""
    edges = defaultdict(set)
    escapes = set()
    seen = set()
    todo = [('stand', start[0], start[1])]
    while todo:
        node = todo.pop()
        if node in seen:
            continue
        kind, c, r = node
        if kind == 'stand':
            if not m.floor(c, r) and (c, r) not in m.extra:
                # düşerek ilk zemine (gölge tahtası tutmaz)
                rr = r
                while rr < m.h and not m.floor(c, rr) and not m.solid(c, rr) and m.cell(c, rr) not in DEADLY:
                    rr += 1
                if rr < m.h and m.floor(c, rr):
                    nxt = ('stand', c, rr)
                    edges[node].add(nxt)
                    todo.append(nxt)
                else:
                    escapes.add(node)
                seen.add(node)
                continue
        seen.add(node)
        if kind in ('stand', 'crouch'):
            for dc in (-1, 1):
                if m.solid(c + dc, r):
                    continue
                if m.floor(c + dc, r) or (c + dc, r) in m.extra:
                    nxt = ('stand', c + dc, r)
                elif m.shade(c + dc, r + 1):
                    nxt = ('crouch', c + dc, r)   # çömelerek gölge tahtasına
                else:
                    nxt = ('stand', c + dc, r)    # boşluğa yürür, düşer
                edges[node].add(nxt)
                todo.append(nxt)
            x0 = c * T
            y0 = (r + 1) * T - H_P
            for off in (0, 9, 18):
                run = RUN * m.run_k
                for vx in (-run, -80, 0, 80, run):
                    for glide, rel in GLIDES:
                        res, died = simulate(m, x0 + off, y0, vx, glide, release=rel)
                        if died:
                            escapes.add(node)
                        for nxt in res:
                            edges[node].add(nxt)
                            todo.append(nxt)
        elif kind == 'vine':
            for dr in (-1, 1):
                if m.cell(c, r + dr) in '|S':
                    nxt = ('vine', c, r + dr)
                    edges[node].add(nxt)
                    todo.append(nxt)
            if m.cell(c, r - 1) not in '|S' and not m.solid(c, r - 1):
                edges[node].add(('stand', c, r - 1))
                todo.append(('stand', c, r - 1))
            for dc in (-1, 1):
                edges[node].add(('stand', c + dc, r))
                todo.append(('stand', c + dc, r))
            rope = m.cell(c, r) == 'S'
            top = m.cell(c, r - 1) not in '|S'
            ys = (r * T, r * T - 13) if top else (r * T,)
            # Kanatsız ormanda ip tek yoldur: oyunun ip fiziğiyle ölçülen
            # salınım (tools/preview/ip_olcum_test.dart: pompalayıp 0.8
            # radyanda bırakınca ~380 px/sn ileri, ~560 px/sn yukarı).
            fast = rope and m.forest
            for vx in ((-RUN, RUN, -300, 300, -380, 380) if fast else (-RUN, RUN, -300, 300)) if rope else (-RUN * m.run_k, RUN * m.run_k):
                for glide in (False, True):
                    vy = (-560 if abs(vx) > 300 else -400) if rope else -JUMP * 0.85
                    for y in ys:
                        res, died = simulate(m, c * T + 9, y, vx, glide, swing=vy)
                        if died:
                            escapes.add(node)
                        for nxt in res:
                            edges[node].add(nxt)
                            todo.append(nxt)
    return seen, edges, escapes


def near_cells(seen):
    out = set()
    for kind, c, r in seen:
        span = (-1, 0, 1) if kind != 'vine' else (-1, 0, 1)
        for dc in span:
            for dr in (-1, 0, 1):
                out.add((c + dc, r + dr))
    return out


def gates(rows):
    """Dikey H dizileri: (sütun, üst, alt)."""
    out = []
    h = len(rows)
    for c in range(len(rows[0])):
        r = 0
        while r < h:
            if rows[r][c] == 'H':
                top = r
                while r < h and rows[r][c] == 'H':
                    r += 1
                out.append((c, top, r - 1))
            else:
                r += 1
    return out


def cells(rows, ch):
    return [(c, r) for r, row in enumerate(rows) for c, x in enumerate(row) if x == ch]


def nearest_gate(gs, opened_gates, at, right_only=False):
    best, bd = None, 1e9
    for g in gs:
        if g in opened_gates:
            continue
        if right_only and g[0] <= at[0]:
            continue
        d = math.hypot(g[0] + 0.25 - at[0], g[1] - at[1])
        if d < bd:
            best, bd = g, d
    return best


def _stuck(seen, edges, escapes, goal_cells):
    """Hedef hücrelere (1 kare yakınına) ya da bir ölüme bağlanmayan duruş
    noktaları."""
    goal = {n for n in seen
            if any(abs(n[1] - c) <= 1 and abs(n[2] - r) <= 1 for c, r in goal_cells)}
    rev = defaultdict(set)
    for a, bs in edges.items():
        for b in bs:
            rev[b].add(a)
    ok = set(goal) | (escapes & seen)
    stack = list(ok)
    while stack:
        n = stack.pop()
        for q in rev[n]:
            if q not in ok:
                ok.add(q)
                stack.append(q)
    return {(c, r) for (k, c, r) in seen - ok if k != 'vine'}


def audit(idx):
    name, wings, hw = LEVELS[idx]
    if wings is None:
        return None
    rows = load(name)
    # Haritada görünmeyen basamaklar (levels.dart): denetimde tahta sayılır.
    for (c, r, n) in DECKS.get(name, []):
        rows[r] = rows[r][:c] + '=' * n + rows[r][c + n:]
    if name in VEINS:
        rows = [r.replace('d', 'H') for r in rows]
    start = cells(rows, 'P')[0]
    gs = gates(rows)
    opened_gates = []
    used = set()
    stage_traps = set()
    under = name in UNDERWORLD
    horse = False
    while True:
        opened = {(g[0], r) for g in opened_gates for r in range(g[1], g[2] + 1)}
        m = Map(rows, wings and name not in FLYING, hw, opened,
                konya=name == 'kMapKonya',
                underworld=under or name in FLYING,
                jump_k=HORSE_JUMP if horse else 1.0)
        m.forest = name in FOREST
        hx_cells, hx_zones = heavens_extras(name)
        m.extra |= hx_cells
        m.generous |= hx_cells
        m.yel = hx_zones
        AIR.clear()
        seen, edges, escapes = search(m, start)
        reach = near_cells(seen)
        new = []

        def all_reached(ch):
            cs = cells(rows, ch)
            return cs and all(c in reach for c in cs)

        for c in cells(rows, 'L') + (cells(rows, 'a') if under else []):
            if c in reach and ('L', c) not in used:
                new.append((('L', c), nearest_gate(gs, opened_gates, c)))
        if all_reached('T'):
            for c in cells(rows, 's'):
                if c in reach and ('s', c) not in used:
                    new.append((('s', c), nearest_gate(gs, opened_gates, c)))
        for c in CAGES.get(name, []):
            if c in reach and ('L', c) not in used:
                new.append((('L', c), nearest_gate(gs, opened_gates, c)))
        fin = FINALE.get(name)
        if fin and all(x in reach for x in fin) and ('fin', fin[0]) not in used:
            new.append((('fin', fin[0]), nearest_gate(gs, opened_gates, fin[-1], right_only=True)))
        for c in cells(rows, 't'):
            mirrors = cells(rows, 'm') + cells(rows, 'h')
            if name in LOCK_ANY:
                # Yalnız bu kilidin aynaları (yakındakiler) sayılır.
                mirrors = [x for x in mirrors if abs(x[0] - c[0]) < 40]
            if (c in reach or name in LOCK_ANY) and all(x in reach for x in mirrors) and ('t', c) not in used:
                new.append((('t', c), nearest_gate(gs, opened_gates, c)))
        if all_reached('*'):
            for c in cells(rows, '*')[:1]:
                if ('*', c) not in used:
                    new.append((('*', c), nearest_gate(gs, opened_gates, c)))
        for c in cells(rows, '`'):
            if c in reach and ('`', c) not in used:
                new.append((('`', c), nearest_gate(gs, opened_gates, c, right_only=True)))
        # Sarnıcın iki yüzü: perde (ipi solunda) ve göz taşları
        # erişilebilirse perdenin sağındaki kapı açılır.
        eyes = cells(rows, '$')
        for c in cells(rows, 'J') if eyes else []:
            if c in reach and all(e in reach for e in eyes) and ('J', c) not in used:
                new.append((('J', c), nearest_gate(gs, opened_gates, c, right_only=True)))
        if name in FOREST:
            for c in cells(rows, 'd'):
                if c in reach and ('d', c) not in used:
                    new.append((('d', c), nearest_gate(gs, opened_gates, c)))
        if name == 'kMapGemi':
            # Hayvan kaideleri: ilerleyiş sırasıyla eşleşir; her kaideye
            # varılınca (sandık itilebilir sayılır) en yakın kapı açılır.
            # Terazi kefelerinin gölgeleri kefenin hemen üstündedir: üstüne
            # erişilen gölge sayılır.
            for c in cells(rows, 'd'):
                if (c in reach or (c[0], c[1] - 1) in reach) and ('d', c) not in used:
                    new.append((('d', c), nearest_gate(gs, opened_gates, c)))
        new = [(k, g) for k, g in new if g is not None]
        # Aşama tuzağı: kapılar henüz kapalıyken girilip ne kapıyı açan
        # düzeneğe, ne çıkışa, ne bir ölüme (yeniden doğuş) varılabilen yer.
        if new:
            stage_goals = {k[1] for k, _ in new}
            stage_goals |= set(cells(rows, 'E'))
            if name in LOCK_ANY:
                stage_goals |= set(cells(rows, 'm') + cells(rows, 'h'))
            stage_traps |= _stuck(seen, edges, escapes, stage_goals)
        if name in VEINS:
            veins = [g for g in gs if g not in opened_gates]
            groups = defaultdict(list)
            for (bc, br, order) in bellows_of(name):
                if order <= 0:
                    continue
                g = min(gs, key=lambda g: abs(g[0] - bc) + abs(g[2] - br))
                groups[g].append((bc, br))
            for g in veins:
                bs = groups.get(g, [])
                if bs and all(b in reach for b in bs) and ('vein', g) not in used:
                    new.append((('vein', g), g))
        anvil = nevruz_of(name)
        if anvil and ('nevruz', anvil) not in used and any(
                (anvil[0] + dc, anvil[1] + dr) in reach
                for dc in (-1, 0, 1) for dr in (-1, 0, 1)):
            g = nearest_gate(gs, opened_gates, anvil, right_only=True)
            if g is not None:
                new.append((('nevruz', anvil), g))
        if under and not horse and any(c in reach for c in cells(rows, 'W')):
            # Çalkuyruk'a varıldı: bundan sonra atla zıplanır.
            horse = True
            continue
        if not new:
            break
        for k, g in new:
            used.add(k)
            if g not in opened_gates:
                opened_gates.append(g)

    # Sıkışma: çıkışa ya da ölüme (yeniden doğuş) bağlanmayan duruş noktaları.
    exit_c = cells(rows, 'E')[0]
    goal = {n for n in seen if abs(n[1] - exit_c[0]) <= 1 and abs(n[2] - exit_c[1]) <= 1}
    rev = defaultdict(set)
    for a, bs in edges.items():
        for b in bs:
            rev[b].add(a)
    ok = set(goal) | (escapes & seen)
    stack = list(ok)
    while stack:
        n = stack.pop()
        for p in rev[n]:
            if p not in ok:
                ok.add(p)
                stack.append(p)
    traps = sorted({(c, r) for (k, c, r) in seen - ok if k != 'vine'} | stage_traps)
    # Hatıra, tüy ve fısıltılar havada geçerken de alınır.
    airborne = set('MT123456789()[]{}B')
    missing = [(ch, c, r) for r, row in enumerate(rows) for c, ch in enumerate(row)
               if ch in TARGETS and (c, r) not in reach
               and not (ch == 't' and name in LOCK_ANY)
               and not (ch in airborne and (c, r) in AIR)]
    if name in FLYING:
        ws = cells(rows, 'W')
        if ws and ws[0] in reach:
            missing = [x for x in missing if x[1] < ws[0][0]]
    return m, seen, missing, traps, opened_gates, gs


def clusters(points):
    """Yan yana noktaları gruplar (rapor kısa kalsın)."""
    pts = sorted(points)
    groups = []
    for p in pts:
        for g in groups:
            if any(abs(p[0] - q[0]) <= 2 and abs(p[1] - q[1]) <= 2 for q in g):
                g.append(p)
                break
        else:
            groups.append([p])
    return groups


if __name__ == '__main__':
    args = sys.argv[1:] or [str(i) for i in range(len(LEVELS))]
    problems = 0
    for a in args:
        i = int(a)
        res = audit(i)
        if res is None:
            print(f'{i:2d} {LEVELS[i][0]}: kayak bölümü, atlandı')
            continue
        m, seen, missing, traps, opened, gs = res
        print(f'{i:2d} {LEVELS[i][0]}: {len(seen)} düğüm; kapı {len(opened)}/{len(gs)} açıldı;'
              f' {len(missing)} varılamayan; {len(clusters(traps))} sıkışma bölgesi')
        for g in gs:
            if g not in opened:
                print(f'     KAPALI KAPI sütun {g[0]} satır {g[1]}-{g[2]}')
        for ch, c, r in missing:
            print(f'     varılamaz {ch} ({c},{r})')
        for g in clusters(traps):
            xs = [p[0] for p in g]
            ys = [p[1] for p in g]
            print(f'     sıkışma: sütun {min(xs)}-{max(xs)}, satır {min(ys)}-{max(ys)} ({len(g)} nokta)')
        problems += len(missing) + len(traps) + sum(g not in opened for g in gs)
    # CI'da: bir sorun varsa derleme kırılır.
    sys.exit(1 if problems else 0)
