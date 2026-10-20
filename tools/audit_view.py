"""Denetim görüntüsü: python3 tools/audit_view.py bölüm c0 c1 r0 r1
o = ulaşılan duruş, x = sıkışma (çıkışa ya da ölüme bağlanmayan)."""
import sys
sys.argv, args = sys.argv[:1], sys.argv[1:]
sys.path.insert(0, 'tools')
import audit

i, c0, c1, r0, r1 = map(int, args)
m, seen, missing, traps, opened, gs = audit.audit(i)
pts = {(c, r) for k, c, r in seen}
tr = set(traps)
print('    ' + ''.join(str(c // 10 % 10) if c % 10 == 0 else ' ' for c in range(c0, c1 + 1)))
print('    ' + ''.join(str(c % 10) for c in range(c0, c1 + 1)))
for r in range(r0, r1 + 1):
    line = ''
    for c in range(c0, c1 + 1):
        ch = m.rows[r][c] if 0 <= r < m.h and 0 <= c < m.w else ' '
        if (c, r) in tr:
            ch = 'x'
        elif (c, r) in pts and ch == '.':
            ch = 'o'
        line += ch
    print(f'{r:3d} ' + line)
