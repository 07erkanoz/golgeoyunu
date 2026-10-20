"""Haritanın bir bölgesini varılan duruş noktaları ('o') işaretli çizer.
Kullanım: python3 tools/reach_view.py bölüm c0 c1 r0 r1"""
import sys
sys.argv, args = sys.argv[:1], sys.argv[1:]
exec(open('tools/reach.py').read().split("if __name__")[0])
i, c0, c1, r0, r1 = map(int, args[:5])
m, seen, missing = analyze(i)
for r in range(r0, r1 + 1):
    line = ''.join('o' if (c, r) in seen and m.rows[r][c] == '.' else m.rows[r][c] for c in range(c0, c1 + 1))
    print(f'{r:3d} {line}')
