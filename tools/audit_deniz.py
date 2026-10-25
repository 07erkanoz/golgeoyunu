#!/usr/bin/env python3
"""Ak Ana'nın Denizi: haritanın nefes denetimi.

Platform denetleyicisi (audit.py) yüzüşü bilmez. Burada su hücreleri
serbest yüzülür; nefes alınan yerler hava (cepler, açık su yüzü ve üstü)
ve kabarcık sütunlarıdır. Bir nefes yerinden ötekine en kısa su yolu,
dolu nefesin yettiği yoldan uzun olmamalı (pay bırakılarak). Akıntıya
karşı yol daha pahalı sayılır.

Kullanım: python3 tools/generate_maps.py && python3 tools/audit_deniz.py
"""
import heapq
import json
import re
import sys

# Dolu nefes 25 sn; yüzüş ~3,3 kare/sn (kulaçsız). Pay: üçte biri.
BREATH_TILES = 25 * 3.3 * 0.66
CURRENT_COST = 2.5


def load():
    src = open('lib/game/maps.dart').read()
    m = re.search(r"const kMapDeniz = <String>\[(.*?)\n\];", src, re.S)
    rows = [r.replace("\\$", "$") for r in re.findall(r"'(.*?)',", m.group(1))]
    data = json.load(open('build/deniz.json'))
    return rows, data


def main():
    rows, d = load()
    H, W = len(rows), len(rows[0])
    S = d['surface']
    air_rects = [tuple(a) for a in d['air']]

    def solid(c, r):
        return not (0 <= c < W and 0 <= r < H) or rows[r][c] == '#'

    def in_air_rect(c, r):
        return any(c0 <= c <= c1 and r0 <= r <= r1 for c0, r0, c1, r1 in air_rects)

    def water(c, r):
        return not solid(c, r) and r >= S and not in_air_rect(c, r)

    def air(c, r):
        return not solid(c, r) and not water(c, r)

    # Kabarcık sütunları: kaynaktan yukarı, kaya ya da suyun yüzüne dek.
    vent = set()
    for c, r in d['vents']:
        rr = r
        while rr > 0 and water(c, rr):
            vent.add((c, rr))
            rr -= 1
    # Akıntı hücreleri (yol boyunca, 1 kare yarıçap).
    current = set()
    for path in d['currents']:
        for (c0, r0), (c1, r1) in zip(path, path[1:]):
            n = max(abs(c1 - c0), abs(r1 - r0))
            for i in range(n + 1):
                c = round(c0 + (c1 - c0) * i / n)
                r = round(r0 + (r1 - r0) * i / n)
                for dc in (-1, 0, 1):
                    for dr in (-1, 0, 1):
                        current.add((c + dc, r + dr))

    # Kaplumbağanın yolu: sırtında hızlı ve yorulmadan gidilir.
    ride = set()
    tp = d['turtle']
    for (c0, r0), (c1, r1) in zip(tp, tp[1:]):
        n = max(abs(c1 - c0), abs(r1 - r0))
        for i in range(n + 1):
            ride.add((round(c0 + (c1 - c0) * i / n), round(r0 + (r1 - r0) * i / n)))

    def source(c, r):
        if air(c, r):
            return True
        if (c, r) in vent:
            return True
        # Yüzeyde süzülen: başı üstteki havada.
        return water(c, r) and air(c, r - 1)

    # Nefes yerlerini kümelere ayır (bitişik olanlar bir küme).
    cluster = {}
    k = 0
    for r in range(H):
        for c in range(W):
            if (c, r) in cluster or not source(c, r):
                continue
            stack = [(c, r)]
            cluster[(c, r)] = k
            while stack:
                x, y = stack.pop()
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if (nx, ny) not in cluster and source(nx, ny):
                        cluster[(nx, ny)] = k
                        stack.append((nx, ny))
            k += 1
    members = {}
    for cell, i in cluster.items():
        members.setdefault(i, []).append(cell)

    def passable(c, r):
        return not solid(c, r)

    # Her kümeden su yolu: nefes yetiyorsa hangi kümelere varılır, en
    # uzun nefessiz yol ne kadar.
    links = {i: {} for i in members}
    for i, cells in members.items():
        dist = {cell: 0.0 for cell in cells}
        pq = [(0.0, cell) for cell in cells]
        heapq.heapify(pq)
        while pq:
            dd, (x, y) = heapq.heappop(pq)
            if dd > dist.get((x, y), 1e9) or dd > BREATH_TILES:
                continue
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if not passable(nx, ny):
                    continue
                j = cluster.get((nx, ny))
                if j is not None and j != i:
                    links[i][j] = min(links[i].get(j, 1e9), dd + 1)
                    continue
                if j == i:
                    continue
                step = (0.3 if (nx, ny) in ride
                        else CURRENT_COST if (nx, ny) in current else 1.0)
                nd = dd + step
                if nd < dist.get((nx, ny), 1e9):
                    dist[(nx, ny)] = nd
                    heapq.heappush(pq, (nd, (nx, ny)))

    def find(ch):
        return [(c, r) for r in range(H) for c in range(W) if rows[r][c] == ch]

    start = find('P')[0]
    exit_ = find('E')[0]
    start_k = cluster[start]
    seen = {start_k: None}
    queue = [start_k]
    while queue:
        i = queue.pop(0)
        for j in links[i]:
            if j not in seen:
                seen[j] = i
                queue.append(j)

    reach = {cell for i in seen for cell in members[i]}
    # Bir kümeden nefes yetecek kadar uzaktaki su hücreleri de varılabilir.
    def near_reach(target):
        tx, ty = target
        best = 1e9
        for i in seen:
            for (x, y) in members[i]:
                best = min(best, abs(x - tx) + abs(y - ty))
        return best

    ok = True
    print(f'nefes yolu: {BREATH_TILES:.0f} kare · {len(members)} nefes kümesi, '
          f'{len(seen)} tanesine varılıyor')
    for name, ch in (('Umay', 'K'), ('hatıra', 'M'), ('ateşböceği', 'F'),
                     ('kol', 'L'), ('fısıltı', '1'), ('çıkış', 'E')):
        for cell in find(ch):
            if cell in reach:
                continue
            gap = near_reach(cell)
            if gap > BREATH_TILES / 2:
                print(f'  VARILMAZ {name} {cell}: en yakın nefes {gap} kare')
                ok = False
    # Uzun nefessiz geçitler (bilgi): bağlantının uzunluğu.
    longest = []
    for i in seen:
        for j, dd in links[i].items():
            if j in seen:
                a = min(members[i])
                b = min(members[j])
                longest.append((dd, a, b))
    longest.sort(reverse=True)
    print('en uzun nefessiz geçitler (kare):')
    shown = set()
    for dd, a, b in longest:
        key = tuple(sorted((a, b)))
        if key in shown:
            continue
        shown.add(key)
        print(f'  {dd:5.1f}  {a} → {b}')
        if len(shown) >= 8:
            break
    print('TAMAM' if ok else 'SORUN VAR')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
