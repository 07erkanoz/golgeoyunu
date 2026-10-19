import sys
class G:
    def __init__(s,W,H,fill='.'):
        s.W,s.H=W,H; s.g=[[fill]*W for _ in range(H)]
    def fill(s,c0,r0,c1,r1,ch):
        for r in range(r0,r1+1):
            for c in range(c0,c1+1): s.g[r][c]=ch
    def put(s,c,r,ch,force=False):
        if not force and s.g[r][c] not in '.':
            raise SystemExit(f'cakisma {c},{r}: {s.g[r][c]} -> {ch}')
        s.g[r][c]=ch
    def rows(s): return [''.join(r) for r in s.g]

# ------------------------------------------------------------ I · YEREBATAN
# Sarnıcın ilk yarısı (elle çizilmiş, ilk 67 sütun).
BASE_I = [
    '###################################################################',
    '###################################################################',
    '#..................................................................',
    '#..................................................................',
    '#..................................................................',
    '#..................................................................',
    '#..................KB...F....3....BM...............................',
    '#.................######..#####..#####..#######....................',
    '#................|.................................................',
    '#................|....................................MLB..........',
    '#................|...................................####.......B..',
    '#................|..........................................H..####',
    '#................|.............................#............H..####',
    '#.P.1..F.B.I......2..I....I....I.G..I....I.....#.CK4B.....F.H..####',
    '######========..=============================..####################',
    '######.........................................####################',
    '######.........................................####################',
    '######.........................D....D..........####################',
    '######wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww####################',
    '######wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww####################',
]
old=BASE_I
W,H=290,20
y=G(W,H)
for r,row in enumerate(old):
    for c,ch in enumerate(row):
        if c<67: y.g[r][c]=ch
y.put(65,10,'.',force=True)                 # eski çıkış kalktı
y.fill(0,0,W-1,1,'#'); y.fill(W-1,0,W-1,H-1,'#')
# 4) yarasa galerisi
y.fill(67,14,96,19,'#')
y.fill(68,2,92,7,'#')                        # alçak tavan
y.fill(70,12,70,13,'#'); y.fill(91,12,91,13,'#')
for c in (76,81,86): y.put(c,13,'I')
for c in (72,79,86): y.put(c,8,'b')
y.put(82,13,'G'); y.put(69,13,'F'); y.put(88,13,'M'); y.put(68,13,'5'); y.put(91,11,'B')
# 5) asansör
y.fill(95,12,96,13,'#')                      # basamak
y.fill(97,10,101,11,'#')                     # raf
y.put(98,9,'C'); y.put(99,8,'B') if False else None
y.put(100,9,'B')
y.fill(97,12,107,19,'.'); y.fill(97,18,107,19,'w')
y.fill(97,10,101,11,'#')
y.put(102,14,'A'); y.put(105,14,'Y')
y.put(93,13,'K'); y.put(94,13,'6')
# 6) Dev perde, ışık ve gölge tahtaları, çürük köprü, su haznesi
y.fill(108,10,127,19,'#')
y.put(108,9,'K'); y.put(110,9,'J'); y.put(112,9,'B'); y.put(125,9,'M')
y.fill(128,18,135,19,'w')                    # ışık tahtasının altı: su
y.fill(128,10,133,10,'l')                    # ışık tahtası
y.fill(134,10,135,19,'#'); y.put(134,9,'F'); y.put(135,9,'B')
y.put(129,9,'7')
y.fill(136,18,141,19,'w'); y.fill(136,10,141,10,'n')   # gölge tahtası
y.fill(142,10,147,19,'#'); y.put(143,9,'I'); y.put(142,9,'K'); y.put(145,9,'8')
y.fill(148,18,150,19,'w'); y.fill(148,10,150,10,'u')   # çürük köprü
y.fill(151,10,160,19,'#'); y.fill(151,2,160,6,'#')     # Kandilci'nin dar geçidi
y.put(156,9,'G'); y.put(152,9,'B')
y.put(159,9,'v'); y.put(157,9,'9')
# su haznesi: q sol üst, Q sağ alt; dipte dolduran vana, ortada yüzen tahta
y.put(161,5,'q'); y.put(168,18,'Q'); y.fill(161,19,168,19,'#')
y.put(163,18,'y'); y.put(166,11,'f')
y.fill(169,6,172,19,'#'); y.put(171,5,'B'); y.put(172,5,'K')
# 7) Medusa Salonu: iki baş, bir Kandilci, Perseus'un kalkanı
y.fill(173,14,222,19,'#'); y.put(174,13,'K'); y.put(176,13,'p'); y.put(175,13,'(')
y.put(178,13,'B'); y.put(184,13,'G'); y.put(180,13,'I'); y.put(187,13,'F')
y.fill(190,10,190,11,'#'); y.put(191,11,'U')          # sağa bakan baş
y.fill(194,11,198,11,'#'); y.put(196,10,'M')           # taş Kandilci'yle çıkılan raf
y.put(203,13,'@'); y.put(201,13,')')                   # Perseus'un kalkanı
y.fill(222,2,223,10,'#'); y.put(222,11,'U')           # sola bakan baş
y.fill(223,14,223,19,'#')
# 8) Sal Kanalı: yukarıdaki iskelede Kandilciler, sudan yükselen sütunlar
y.fill(224,14,227,19,'#'); y.put(225,13,'K'); y.put(226,13,'p'); y.put(227,13,'[')
y.fill(228,14,262,19,'w'); y.put(228,13,'_')
y.fill(232,10,258,10,'='); y.put(236,9,'G'); y.put(250,9,'G')
for c in (238,246,254): y.put(c,13,'I')
y.put(246,12,'M'); y.put(231,9,'B')
y.fill(263,14,267,19,'#'); y.put(264,13,'B')
y.fill(266,12,267,13,'#')                              # kovalamacaya basamak
O=160
# 7) Karabasan (O kadar sağa kaydı)
y.fill(108+O,10,113+O,19,'#')
y.fill(114+O,18,128+O,19,'w')
y.fill(116+O,10,118+O,11,'#')
y.put(119+O,10,'O')
y.fill(122+O,8,128+O,9,'#')
y.put(109+O,9,'K'); y.put(110+O,9,'z'); y.put(126+O,7,'Z'); y.put(127+O,7,'E'); y.put(124+O,7,'B')
y.put(112+O,9,'F')
# Gerilim: karanlıkta beliren gözler, ışığı yiyen yarasa galerisi.
y.put(38,16,'e'); y.put(99,16,'e')
y.put(71,8,'x'); y.put(90,13,'X'); y.put(79,13,'F')
# Yer adları
for c,r in [(14,12),(32,12),(50,12),(72,10),(101,8),(113,8),(127,9),(153,9),(160,8),(176,8)]:
    y.put(c,r,'p')
lvl1=y.rows()

# ------------------------------------------------------------ II · KULE
W,H=30,96
k=G(W,H)
k.fill(0,0,1,H-1,'#'); k.fill(28,0,29,H-1,'#')
k.fill(2,92,7,95,'#'); k.fill(8,94,27,95,'w')
k.put(3,91,'P'); k.put(5,91,'1'); k.put(7,91,'F'); k.put(6,91,'B')
k.put(9,92,'V')
k.fill(12,88,15,89,'#'); k.put(13,87,'B')
k.put(17,86,'O')
k.fill(20,84,24,85,'#'); k.put(23,83,'k'); k.put(24,83,'M')
k.fill(26,74,26,83,'|')
k.fill(21,74,24,75,'#'); k.put(22,73,'K'); k.put(21,73,'2'); k.put(23,73,'B')
k.put(18,72,'O')
k.put(15,70,'O')
k.fill(8,68,13,69,'#'); k.put(9,67,'k'); k.put(11,67,'F')
k.put(3,66,'R')
k.fill(2,55,2,65,'|')
k.fill(4,55,9,56,'#'); k.put(6,54,'3'); k.put(8,54,'M'); k.put(5,54,'B')
k.fill(11,53,16,53,'='); k.put(12,52,'K')
k.fill(18,51,26,51,'='); k.put(23,50,'G'); k.fill(20,50,21,50,'~'); k.put(16,50,'B') if False else None
k.put(18,50,'B')
k.fill(27,40,27,50,'|')
k.fill(13,40,25,40,'='); k.put(21,39,'k'); k.put(24,39,'F'); k.put(17,39,'k'); k.put(19,39,'K')
k.fill(12,38,17,38,'='); k.put(15,37,'C'); k.put(14,37,'B')
k.put(10,41,'A'); k.put(8,41,'Y')
k.fill(2,46,11,47,'#'); k.fill(2,45,11,45,'^')   # kuyunun dibi: düşen baştan dener
k.fill(2,35,7,35,'='); k.put(3,34,'K')
k.put(6,33,'V')
k.fill(9,27,14,27,'='); k.put(13,26,'F'); k.put(11,26,'B')
k.fill(22,24,25,25,'#'); k.put(24,23,'g')
k.fill(16,25,19,25,'='); k.put(17,24,'M')
k.fill(12,23,21,23,'=')
# Hezarfen'in merceği: ışık aynayla Gözcü'nün gözüne çevrilir.
k.put(20,13,'j'); k.put(20,22,'m'); k.put(17,22,'5')
k.fill(13,13,13,22,'|')
k.fill(4,11,12,12,'#'); k.put(11,10,'W'); k.put(9,10,'4'); k.put(10,10,'K'); k.put(7,10,'B')
k.fill(14,2,16,11,'r')
k.fill(19,4,23,4,'='); k.put(21,3,'E')
for c,r in [(4,90),(10,66),(12,50),(9,38),(8,26),(8,9)]:
    k.put(c,r,'p')
lvl2=k.rows()

# ------------------------------------------------------------ III · GÖKYOLU
W,H=150,22
s=G(W,H)
s.fill(0,15,7,17,'#'); s.fill(1,18,6,18,'#'); s.fill(2,19,5,19,'#')
s.put(2,14,'P'); s.put(4,14,'3'); s.put(5,14,'B')
s.fill(13,16,16,16,'='); s.put(14,15,'K'); s.put(15,15,'B'); s.put(16,15,'4')
s.fill(18,3,19,15,'r')
s.fill(22,6,26,6,'='); s.put(24,5,'M'); s.put(25,5,'B')
s.put(29,9,'R')
s.put(38,10,'O')
s.fill(42,11,56,12,'#'); s.fill(44,13,54,13,'#'); s.fill(47,14,51,14,'#')
s.put(43,10,'K'); s.put(44,10,'2'); s.put(45,10,'F'); s.fill(47,10,48,10,'~'); s.put(50,10,'G'); s.fill(53,10,54,10,'~')
s.put(46,10,'B')
s.fill(59,12,60,12,'='); s.fill(61,6,63,8,'#'); s.put(63,5,'g')
s.fill(66,12,69,12,'='); s.put(67,11,'B')
s.fill(72,10,75,10,'=')
s.put(79,14,'V')
s.fill(84,4,85,16,'r')
s.fill(88,5,93,5,'='); s.put(89,4,'K'); s.put(90,4,'M'); s.put(91,4,'B')
s.fill(104,12,112,13,'#'); s.fill(106,14,110,14,'#')
s.put(105,11,'K'); s.put(106,11,'k'); s.put(108,11,'F'); s.put(110,11,'k'); s.put(107,11,'B')
s.put(116,12,'O'); s.put(121,11,'O'); s.put(126,10,'O')
s.fill(131,9,149,11,'#'); s.fill(133,12,147,12,'#')
s.put(132,8,'K'); s.put(135,8,'B'); s.put(140,8,'1'); s.put(145,8,'E'); s.put(143,8,'B')
s.put(60,17,'e')
for c,r in [(10,13),(44,9),(60,4),(90,3),(106,9),(134,7)]:
    s.put(c,r,'p')
s.fill(95,9,100,9,'l')                       # bulutların arasında ışık köprüsü
lvl3=s.rows()

# ------------------------------------------------------------ IV · KAF
W,H=172,24
f=G(W,H)
# 1) varış ve zümrüt köprü
f.fill(0,18,10,23,'#'); f.put(2,17,'P'); f.put(4,17,'1'); f.put(5,17,'B'); f.put(7,17,'F')
f.fill(11,18,16,18,'l')
f.fill(17,18,24,23,'#'); f.put(17,17,'K'); f.put(22,17,'M'); f.put(19,17,'B')
f.fill(23,6,24,16,'r')                       # rüzgâr: yamaca çıkarır
f.fill(25,10,28,23,'#')
# 2) Kandilcilerin gök karakolu
f.fill(29,10,58,12,'#'); f.put(29,9,'K'); f.put(30,9,'2'); f.put(31,9,'B')
f.fill(33,9,34,9,'~'); f.put(37,9,'G'); f.put(40,9,'I'); f.fill(44,9,45,9,'~'); f.put(51,9,'G')
f.put(48,9,'F')
f.fill(59,10,61,10,'u')
# 3) Gözcü'nün gölge köprüsü; ay ışığı aynayla gözüne çevrilir
f.fill(62,10,70,12,'#'); f.put(63,9,'K'); f.put(64,9,'3'); f.put(66,9,'B')
f.fill(71,10,84,10,'n')
f.put(75,2,'j'); f.put(75,8,'m'); f.put(72,8,'#')     # kristal: sola kaçan ışığı tutar
f.fill(85,10,93,23,'#'); f.put(89,9,'g')
# 4) çöken kayalar, rüzgâr
f.put(96,11,'O'); f.put(100,10,'O'); f.put(104,9,'R')
f.fill(110,4,111,14,'r')
f.fill(114,6,121,7,'#'); f.put(115,5,'K'); f.put(116,5,'4'); f.put(117,5,'B'); f.put(119,5,'M')
# 5) Simurg'un ayna salonu
f.fill(122,0,171,2,'#')
f.fill(122,18,171,23,'#'); f.put(124,17,'K'); f.put(127,17,'B'); f.put(132,17,'5')
f.fill(136,13,149,13,'#'); f.fill(151,13,152,13,'#'); f.fill(134,11,134,12,'#')
f.put(140,4,'j'); f.put(140,12,'m'); f.put(150,12,'m'); f.put(150,17,'m')
f.put(152,17,'C'); f.put(153,18,'.',force=True)
f.put(146,17,'G'); f.put(138,12,'M'); f.put(143,17,'F')
f.put(158,17,'t')
f.fill(161,3,161,11,'#'); f.fill(161,12,161,17,'H')
f.put(165,17,'B'); f.put(167,17,'E')
for c,r in [(8,16),(32,8),(66,8),(98,7),(126,16)]:
    f.put(c,r,'p')
lvl4=f.rows()

# ------------------------------------------------------------ V · AĞRI
W,H=190,26
a=G(W,H)
# 1) Dağın eteği: buzlu dere, ilk ip
a.fill(0,20,12,25,'#'); a.put(2,19,'P'); a.put(4,19,'1'); a.put(6,19,'B'); a.put(8,19,'p')
a.fill(13,21,22,25,'#'); a.fill(13,20,22,20,'-')
a.fill(24,10,40,11,'#')                      # kaya saçağı
a.fill(25,12,25,17,'S')
a.fill(31,17,35,25,'#')
# 2) İplerin geçidi
a.put(31,16,'p'); a.put(32,16,'K'); a.put(33,16,'2'); a.put(34,16,'B'); a.put(35,16,'F')
a.fill(36,6,58,7,'#')                        # taş kemer
a.fill(37,8,37,17,'S'); a.fill(44,8,44,17,'S'); a.fill(51,8,51,17,'S')
a.fill(59,17,100,25,'#')
# 3) Terk edilmiş ağıl
a.put(60,16,'K'); a.put(62,16,'3'); a.put(64,16,'B'); a.put(66,16,'p')
a.fill(68,15,69,16,'#'); a.fill(70,16,71,16,'~'); a.put(75,16,'G'); a.put(78,16,'M')
a.fill(80,14,81,16,'#'); a.fill(82,16,83,16,'~'); a.put(90,16,'G'); a.put(86,16,'F')
a.fill(96,17,98,25,'.',); a.fill(96,17,98,17,'u'); a.put(97,24,'^') if False else None
a.fill(99,17,135,25,'#')
# 4) Buz mağarası
a.fill(100,0,135,12,'#')
a.put(102,16,'p'); a.put(101,16,'K'); a.put(105,16,'4')
a.put(104,13,'x'); a.put(132,16,'X')
a.fill(110,17,118,17,'-')
a.put(107,16,'F'); a.put(121,16,'F'); a.put(129,16,'F'); a.put(116,14,'e'); a.put(127,16,'M')
a.fill(122,17,124,17,'^')
# 5) Tufanın eşiği: iplerle yukarı
a.fill(136,17,142,25,'#'); a.put(137,16,'K'); a.put(139,16,'B'); a.put(140,16,'p')
a.fill(146,15,150,25,'#')
a.fill(151,5,158,5,'#'); a.fill(153,6,153,14,'S')
a.fill(159,12,165,25,'#'); a.put(160,11,'K')
a.put(168,10,'O'); a.put(172,9,'O')
a.fill(176,8,180,25,'#'); a.put(177,7,'5')
a.fill(183,7,189,25,'#'); a.put(184,6,'M'); a.put(185,6,'B'); a.put(187,6,'E')
lvl5=a.rows()

MAPS = [('kMapYerebatan', lvl1), ('kMapKule', lvl2), ('kMapGokyolu', lvl3), ('kMapKaf', lvl4), ('kMapAgri', lvl5)]

out = ['// Bu dosya tools/generate_maps.py ile üretilir; elle düzenleme.',
       '// Gösterim: lib/game/level.dart başındaki açıklamaya bakın.', '']
for name, rows in MAPS:
    widths = set(len(r) for r in rows)
    assert len(widths) == 1, (name, widths)
    out.append(f'const {name} = <String>[')
    out += [f"  '{r}'," for r in rows]
    out += ['];', '']
    print(name, len(rows), 'x', widths.pop())
open('lib/game/maps.dart', 'w').write('\n'.join(out))
