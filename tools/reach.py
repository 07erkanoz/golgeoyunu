"""Harita erişilebilirlik çözümleyicisi.

Sâye'nin gerçek fizik değerleriyle (zıplama, süzülme, tırmanma, ip, rüzgâr,
peri halkası, kenara tutunma) her duruş noktasından atlayışları kare kare
benzetir; başlangıçtan varılamayan önemli hücreleri (kontrol noktası,
hatıra, fısıltı, çıkış...) raporlar.

Hareketli düzenekler (asansör, kayan kaya, sal, avize...) cömert sayılır:
gerçek oyunda daha zor olabilir ama burada "imkânsız" diye işaretlenmez.

Kullanım: python3 tools/reach.py [bölüm_no ...]
"""
import math
import re
import sys

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
]

SOLID = set('#-')
ONEWAY = set('=lnuO/fAYRV_dC@a')       # üstüne basılır, altından geçilir
DEADLY = set('w^')
TARGETS = set('KMEB123456789()[]{}pLvyWTs*tm')


def load(name):
    src = open('lib/game/maps.dart', encoding='utf-8').read()
    m = re.search(r"const %s = <String>\[(.*?)\];" % name, src, re.S)
    rows = [l.strip()[1:-2].replace("\\'", "'").replace('\\$', '$') for l in m.group(1).strip().split('\n')]
    return rows


class Map:
    def __init__(self, rows, wings, headwind):
        self.rows = rows
        self.h = len(rows)
        self.w = len(rows[0])
        self.wings = wings or any('W' in r for r in rows)
        self.glide_x = max(40.0, GLIDE_X - headwind)
        # Hareketli platformların erişebildiği ek satırlar.
        self.extra = set()
        for r, row in enumerate(rows):
            for c, ch in enumerate(row):
                if ch in 'AYfV':
                    for k in range(-8, 9):
                        self.extra.add((c, r + k))
                        self.extra.add((c + 1, r + k))
                elif ch == 'R':
                    for k in range(0, 6):
                        self.extra.add((c + k, r))
                elif ch == 'd':          # avize: yarıçap 4 kare
                    for dc in range(-5, 6):
                        for dr in range(-5, 6):
                            self.extra.add((c + dc, r + dr))
                elif ch == '_':          # sal: suyun boyunca
                    k = c
                    while k < self.w and rows[r + 1][k] == 'w':
                        self.extra.add((k, r))
                        k += 1

    def cell(self, c, r):
        if r < 0:
            return '.'
        if c < 0 or c >= self.w or r >= self.h:
            return '#'
        return self.rows[r][c]

    def solid(self, c, r):
        ch = self.cell(c, r)
        return ch in SOLID

    def oneway(self, c, r):
        return self.cell(c, r) in ONEWAY or (c, r) in self.extra

    def floor(self, c, r):
        """(c, r) hücresinde durulabilir mi (altı dolu, kendisi boş)?"""
        if self.solid(c, r) or self.cell(c, r) in DEADLY:
            return False
        return self.solid(c, r + 1) or self.oneway(c, r + 1) and not self.solid(c, r)

    def box_solid(self, x, y):
        c0, c1 = int((x + 1) // T), int((x + W_P - 1) // T)
        r0, r1 = int((y + 1) // T), int((y + H_P - 1) // T)
        for c in range(c0, c1 + 1):
            for r in range(r0, r1 + 1):
                if self.solid(c, r):
                    return True
        return False


def simulate(m, x, y, vx0, glide, swing=None, release=None):
    """Bir atlayışı benzetir; konduğu (sütun, satır) kümesini döndürür."""
    out = set()
    vx = vx0
    vy = -JUMP if swing is None else swing
    for step in range(int(8 / DT)):
        if release is not None and step * DT > release:
            glide = False
        gliding = glide and m.wings and vy > -40
        if gliding:
            vy = min(vy + G * 0.3 * DT, GLIDE_FALL)
            if vx0:
                vx = (1 if vx0 > 0 else -1) * m.glide_x
        else:
            vy = min(vy + G * DT, MAXFALL)
        cc = int((x + W_P / 2) // T)
        cr = int((y + H_P / 2) // T)
        ch = m.cell(cc, cr)
        if ch == 'r':
            vy = max(vy - 2600 * DT, -260) if (glide and m.wings) else vy - 1100 * DT
            if vy < -150:   # akımla yükselirken yön bırakılır, tepede yeniden verilir
                vx = 0
            elif vx0:
                vx = (1 if vx0 > 0 else -1) * m.glide_x
        elif vx == 0 and vx0 and not m.box_solid(x + (1 if vx0 > 0 else -1), y):
            vx = vx0
        if ch in '|S':
            out.add(('vine', cc, cr))
        # Kenara tutunma (oyundaki kural): düşerken, yöne basılıyken.
        if vx0 and vy > -60:
            d = 1 if vx0 > 0 else -1
            pc = int(((x + W_P + 3) if d > 0 else (x - 3)) // T)
            oc0, oc1 = int((x + 1) // T), int((x + W_P - 1) // T)
            for r in range(math.ceil((y - 8) / T), int((y + 16) // T) + 1):
                free = lambda c, rr: not (m.solid(c, rr) or m.oneway(c, rr))
                if free(pc, r) or not free(pc, r - 1) or not free(pc, r - 2):
                    continue
                if all(free(oc, rr) for oc in range(oc0, oc1 + 1) for rr in (r, r - 1, r - 2)):
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
                            return out
                        out.add(('stand', c, r - 1))
                        landed = True
                        break
                    if m.cell(c, r) in DEADLY and m.cell(c, r - 1) not in DEADLY:
                        return out
            if landed:
                return out
            y = ny
            if m.box_solid(x, y):
                return out
        if y > m.h * T:
            return out
        if m.cell(int((x + W_P / 2) // T), int((y + H_P) // T)) == '"':
            vy = -880
    return out


# Süzülme seçenekleri: hiç, sonuna kadar, belli bir anda bırakarak.
GLIDES = [(False, None), (True, None), (True, 0.6), (True, 0.9), (True, 1.3)]


def analyze(idx, start=None):
    name, wings, hw = LEVELS[idx]
    if wings is None:
        return None
    m = Map(load(name), wings, hw)
    for r, row in enumerate(m.rows):
        c = row.find('P')
        if c >= 0 and start is None:
            start = (c, r)
    seen = set()
    vines = set()
    todo = [('stand', start[0], start[1])]
    while todo:
        node = todo.pop()
        kind, c, r = node
        if kind == 'stand':
            if (c, r) in seen:
                continue
            if not m.floor(c, r) and (c, r) not in m.extra:
                # düşerek ilk zemine
                rr = r
                while rr < m.h and not m.floor(c, rr) and not m.solid(c, rr) and m.cell(c, rr) not in DEADLY:
                    rr += 1
                if rr < m.h and m.floor(c, rr):
                    todo.append(('stand', c, rr))
                continue
            seen.add((c, r))
            for dc in (-1, 1):
                if not m.solid(c + dc, r):
                    todo.append(('stand', c + dc, r))
            # Ayakta: yerinde yürünerek bir kare çıkılmaz; zıplanır.
            x0 = c * T
            y0 = (r + 1) * T - H_P
            for off in (0, 9, 18):
                for vx in (-RUN, -80, 0, 80, RUN):
                    for glide, rel in GLIDES:
                        for res in simulate(m, x0 + off, y0, vx, glide, release=rel):
                            todo.append(res)
        elif kind == 'vine':
            if (c, r) in vines:
                continue
            vines.add((c, r))
            for dr in (-1, 1):
                if m.cell(c, r + dr) in '|S':
                    todo.append(('vine', c, r + dr))
            # tepesinden çık
            if m.cell(c, r - 1) not in '|S' and not m.solid(c, r - 1):
                todo.append(('stand', c, r - 1))
            for dc in (-1, 1):
                todo.append(('stand', c + dc, r))
            rope = m.cell(c, r) == 'S'
            # Sarmaşığın tepesinde gövde yarım kare daha yukarı çıkar.
            top = m.cell(c, r - 1) not in '|S'
            ys = (r * T, r * T - 13) if top else (r * T,)
            for vx in (-RUN, RUN, -300, 300) if rope else (-RUN, RUN):
                for glide in (False, True):
                    vy = -400 if rope else -JUMP * 0.85
                    for y in ys:
                        for res in simulate(m, c * T + 9, y, vx, glide, swing=vy):
                            todo.append(res)
    reach = set()
    for (c, r) in seen:
        for dc in (-1, 0, 1):
            for dr in (-1, 0, 1):
                reach.add((c + dc, r + dr))
    for (c, r) in vines:
        reach.add((c, r))
        reach.add((c - 1, r))
        reach.add((c + 1, r))
    missing = []
    for r, row in enumerate(m.rows):
        for c, ch in enumerate(row):
            if ch in TARGETS and (c, r) not in reach:
                missing.append((ch, c, r))
    return m, seen, missing


if __name__ == '__main__':
    # bölüm[:sütun:satır] — başlangıç yerine verilen noktadan tarar
    args = sys.argv[1:] or [str(i) for i in range(len(LEVELS))]
    for a in args:
        parts = [int(x) for x in a.split(':')]
        i = parts[0]
        res = analyze(i, (parts[1], parts[2]) if len(parts) == 3 else None)
        if res is None:
            print(f'{i:2d} {LEVELS[i][0]}: kayak bölümü, atlandı')
            continue
        m, seen, missing = res
        print(f'{i:2d} {LEVELS[i][0]}: {len(seen)} duruş noktası, {len(missing)} varılamayan')
        for ch, c, r in missing:
            print(f'     {ch} ({c},{r})')
