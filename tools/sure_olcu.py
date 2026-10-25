"""Bölümlerin en kısa geçiş süresi (kaba ölçü): denetleyicinin (audit.py)
duruş noktaları grafında başlangıçtan çıkışa en kısa yol. Her adım,
uzaklığı koşu hızıyla (saniyede 5 kare) ve adım başına küçük bir payla
saniyeye çevrilir. Bulmacayı düşünme, bekleme, ölüm sayılmaz: usta bir
oyuncunun alt sınırıdır. Bölümleri birbiriyle karşılaştırmak içindir.

    python3 tools/sure_olcu.py [bölüm_no ...]
"""
import heapq
import math
import sys

sys.path.insert(0, 'tools')
import audit  # noqa: E402


def shortest(idx):
    res = audit.audit(idx)
    if res is None:
        return None
    m = res[0]
    name = audit.LEVELS[idx][0]
    rows = audit.load(name)
    start = audit.cells(rows, 'P')[0]
    seen, edges, _ = audit.search(m, start)
    ex = audit.cells(rows, 'E')[0]
    goal = {n for n in seen if abs(n[1] - ex[0]) <= 1 and abs(n[2] - ex[1]) <= 1}
    src = [n for n in seen if n[1] == start[0] and abs(n[2] - start[1]) <= 1]
    dist = {}
    pq = []
    for s in src:
        dist[s] = 0.0
        heapq.heappush(pq, (0.0, s))
    while pq:
        d, n = heapq.heappop(pq)
        if n in goal:
            return d, rows
        if d > dist.get(n, 1e18):
            continue
        for q in edges.get(n, ()):
            step = math.hypot(q[1] - n[1], q[2] - n[2]) / 5 + 0.15
            nd = d + step
            if nd < dist.get(q, 1e18):
                dist[q] = nd
                heapq.heappush(pq, (nd, q))
    return None, rows


if __name__ == '__main__':
    args = [int(a) for a in sys.argv[1:]] or range(len(audit.LEVELS))
    for i in args:
        r = shortest(i)
        name = audit.LEVELS[i][0]
        if r is None:
            print(f'{i:2d} {name:16} kayak')
            continue
        d, rows = r
        mech = sum(row.count(ch) for row in rows for ch in 'LtCGgHa*')
        w = len(rows[0])
        print(f'{i:2d} {name:16} {w:4d} kare  en kısa yol {d/60 if d else 0:4.1f} dk'
              f'  düzenek/canlı {mech}')
