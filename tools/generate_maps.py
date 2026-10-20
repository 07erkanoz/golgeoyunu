import sys
sys.path.insert(0, 'tools')
from sections import rope_chasm
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
y.put(178,13,'B'); y.put(188,13,'G'); y.put(180,13,'I'); y.put(184,13,'F')
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
# Kule uzar: altta Yanan Mahzen, tepede Çan Katı ve külah.
TOP, BOT = 34, 40
k2 = G(W, TOP + H + BOT)
for r, row in enumerate(k.g):
    k2.g[r + TOP] = list(row)
k = k2
k.put(3, TOP + 91, '.', force=True)          # eski başlangıç
k.put(21, TOP + 3, '.', force=True)          # eski çıkış
k.fill(0, 0, 1, k.H - 1, '#'); k.fill(28, 0, 29, k.H - 1, '#')
B = TOP + H                                   # alt kısmın ilk satırı (130)
# --- Yanan Mahzen
k.fill(2, B + 38, 27, B + 39, '#')
k.put(4, B + 37, 'P'); k.put(5, B + 37, 'p'); k.put(6, B + 37, '6'); k.put(7, B + 37, 'B')
k.put(8, B + 37, 'K'); k.put(11, B + 37, 'C'); k.put(12, B + 37, '7')
k.fill(10, B + 33, 25, B + 34, '#')          # alçak tavan
for c in (14, 17, 20):
    k.put(c, B + 37, '!')
k.fill(26, B + 20, 26, B + 37, '|')
k.fill(14, B + 20, 25, B + 21, '#')
k.put(24, B + 19, 'K'); k.put(22, B + 19, '~'); k.put(23, B + 19, '~'); k.put(18, B + 19, 'G')
k.put(15, B + 19, '!'); k.put(20, B + 19, 'M'); k.put(25, B + 19, 'B')
k.fill(4, B + 18, 12, B + 18, '=')          # adadan iki kare yukarıda: zıplanır
k.fill(3, TOP + 92, 3, B + 17, '|')          # eski zeminden rafın hizasına sarmaşık
k.fill(8, TOP + 96, 27, TOP + 97, '#')       # Haliç'in dibi
k.put(5, B + 17, 'B')
# --- Çan Katı ve külah
k.fill(14, 22, 16, TOP + 1, 'r')
k.fill(2, 26, 9, 27, '#'); k.fill(3, 23, 5, 23, '#'); k.put(4, 24, 'c')
k.put(3, 25, 'K'); k.put(5, 25, 'M'); k.put(6, 25, '8'); k.put(7, 25, 'k'); k.put(8, 25, 'p')
k.fill(20, 26, 21, 27, '#'); k.fill(22, 26, 24, 26, 'u'); k.fill(25, 26, 27, 27, '#')
k.put(26, 25, 'G')
k.fill(27, 11, 27, 25, '|')
k.fill(20, 9, 26, 10, '#'); k.put(21, 8, 'B'); k.put(24, 8, 'p')
k.put(17, 7, 'O')
k.fill(11, 4, 16, 4, '#'); k.fill(12, 5, 15, 5, '#'); k.put(14, 3, 'E'); k.put(12, 3, 'B')
H = k.H
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
# --- Gökyolu uzar
s2=G(336,H)
for r,row in enumerate(s.g):
    s2.g[r][:150]=row
s=s2
s.put(145,8,'.',force=True)                  # eski çıkış
# A) Balon geçidi: adacıklar, üstte süzülen fener balonları
for a,b in [(152,156),(162,165),(172,175),(182,186),(194,199)]:
    s.fill(a,10,b,11,'#'); s.fill(a+1,12,b-1,12,'#')
s.put(153,9,'p'); s.put(154,9,'5'); s.put(155,9,'K'); s.put(163,9,'~'); s.put(164,9,'~')
s.put(173,9,'B'); s.put(184,9,'~'); s.put(185,9,'~'); s.put(196,9,'M')
s.put(166,3,'N'); s.put(186,2,'N')
s.fill(178,14,179,20,'r'); s.fill(176,4,178,4,'='); s.put(177,3,'F')  # yan ada: ateşböceği
# B) Gölgeden köprü: balonun ışığı değince kaybolur; süzülerek aşılamaz
s.fill(200,10,203,11,'#'); s.put(201,9,'K'); s.put(202,9,'6'); s.put(200,9,'p')
s.fill(204,10,209,10,'n'); s.fill(210,10,211,11,'#'); s.put(210,9,'~'); s.put(211,9,'~')
s.fill(212,10,217,10,'n'); s.put(210,4,'N')
s.put(203,0,'<'); s.put(218,12,'>')               # sağanak: kanatlar ıslanır
s.fill(218,10,223,11,'#'); s.put(219,9,'B')
# C) Fırtına adaları: çöken ve kayan kayalar, rüzgâr, Gözcü
s.put(226,10,'O'); s.put(230,9,'O'); s.put(234,8,'R')
s.fill(242,7,244,16,'#'); s.put(243,6,'g')
s.fill(247,4,248,15,'r'); s.put(245,3,'p')
s.fill(251,6,256,7,'#'); s.put(252,5,'K'); s.put(253,5,'7'); s.put(255,5,'B')
s.put(260,7,'O'); s.put(265,8,'V'); s.put(270,7,'O')
s.fill(262,2,266,2,'='); s.put(264,1,'M')    # rüzgârla çıkılan gizli bulut
s.fill(258,3,259,14,'r')
s.fill(274,8,280,9,'#'); s.put(275,7,'K'); s.put(277,7,'B')
# D) Güneşin kapısı: Kandilcilerin gök kampı
s.fill(281,8,334,10,'#'); s.fill(283,11,332,11,'#')
s.put(283,7,'p'); s.put(284,7,'8'); s.put(287,7,'F')
s.put(292,7,'G'); s.fill(296,7,297,7,'~'); s.put(302,7,'I'); s.put(308,7,'G')
s.fill(312,7,313,7,'~'); s.put(300,2,'N'); s.put(320,7,'G'); s.fill(316,7,317,7,'~')
s.put(325,7,'B'); s.put(328,7,'K'); s.put(331,7,'E'); s.put(329,7,'B')
W=336
lvl3=s.rows()

# ------------------------------------------------------------ IV · KAF
W,H=247,24
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
# 5) Simurg'un tüyleri: üç tüy, üç sınav; sunak ayna salonunu açar
f.fill(122,18,196,23,'#'); f.put(123,17,'K'); f.put(125,17,'p'); f.put(126,17,'6')
# tüy 1: rüzgârla çıkılan kristal raf, kargalar
f.fill(128,7,129,17,'r'); f.fill(131,6,135,6,'#'); f.put(133,5,'T'); f.put(134,5,'k'); f.put(132,5,'k')
# tüy 2: iki Gözcü'nün sırayla süpürdüğü gölge köprüsü
f.fill(139,18,158,23,'.'); f.fill(139,18,158,18,'n')
f.put(148,15,'T')
f.fill(159,10,161,23,'#'); f.put(160,9,'g')
f.fill(139,10,141,10,'#'); f.put(139,9,'#'); f.put(140,9,'g')
f.put(138,17,'7')
# tüy 3: dikey kayan kayalarla yüksek buluta
f.put(165,16,'V'); f.put(169,14,'V'); f.put(173,12,'V')
f.fill(176,7,180,7,'='); f.put(178,6,'T'); f.put(177,6,'M')
f.put(166,17,'B'); f.put(170,17,'8')
# sunak ve tüy kapısı
f.put(186,17,'K'); f.put(190,17,'s'); f.put(188,17,'B')
f.fill(194,3,194,11,'#'); f.fill(194,12,194,17,'H')
HO=75
# 5) Simurg'un ayna salonu
f.fill(122+HO,0,171+HO,2,'#')
f.fill(122+HO,18,171+HO,23,'#'); f.put(124+HO,17,'K'); f.put(127+HO,17,'B'); f.put(132+HO,17,'5')
f.fill(136+HO,13,149+HO,13,'#'); f.fill(151+HO,13,152+HO,13,'#'); f.fill(134+HO,11,134+HO,12,'#')
f.put(140+HO,4,'j'); f.put(140+HO,12,'m'); f.put(150+HO,12,'m'); f.put(150+HO,17,'m')
f.put(152+HO,17,'C'); f.put(153+HO,18,'.',force=True)
f.put(146+HO,17,'G'); f.put(138+HO,12,'M'); f.put(143+HO,17,'F')
f.put(158+HO,17,'t')
f.fill(161+HO,3,161+HO,11,'#'); f.fill(161+HO,12,161+HO,17,'H')
f.put(165+HO,17,'B'); f.put(167+HO,17,'E')
for c,r in [(8,16),(32,8),(66,8),(98,7),(126+HO,16)]:
    f.put(c,r,'p')
lvl4=f.rows()

# ------------------------------------------------------------ V · AĞRI
W,H=314,26
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
# 5) Akori: Nuh'un bağı. Basamaklı bağlar, donmuş asma çardakları
a.fill(136,17,145,25,'#'); a.put(137,16,'K'); a.put(139,16,'p'); a.put(141,16,'6')
a.fill(146,15,148,25,'#'); a.fill(149,13,151,25,'#'); a.fill(152,11,175,25,'#')
a.fill(160,5,160,10,'|'); a.fill(168,5,168,10,'|'); a.fill(159,4,169,4,'=')
a.put(164,3,'M'); a.put(165,10,'G'); a.put(172,10,'k'); a.put(174,10,'k'); a.put(156,10,'B')
a.fill(176,13,178,25,'#'); a.fill(179,15,181,25,'#')
a.fill(182,17,190,25,'#'); a.fill(182,17,190,17,'-')          # kaygan buz
a.fill(191,17,192,25,'.'); a.fill(193,17,195,25,'#'); a.put(194,16,'B')
# 6) Aziz Hakob Manastırı: revak, sarkıtlar, çan, kule ve kapı
a.fill(196,17,259,25,'#'); a.put(199,16,'&'); a.put(197,16,'K'); a.put(198,16,'p')
a.fill(206,11,231,12,'#')
for c in (209,214,219,224,229):
    a.put(c,13,'i')
a.put(220,16,'G'); a.put(234,16,'~'); a.put(235,16,'~'); a.put(204,16,'F')
a.fill(239,14,241,14,'#'); a.put(240,15,'c'); a.put(242,16,'7')
a.fill(246,8,249,16,'#'); a.fill(245,9,245,16,'|'); a.put(248,7,'L'); a.put(247,7,'M')
a.fill(258,2,258,12,'#'); a.fill(258,13,258,16,'H')
a.put(252,16,'K'); a.put(254,16,'B')
AO=124
# 5) Tufanın eşiği: iplerle yukarı
a.fill(136+AO,17,142+AO,25,'#'); a.put(137+AO,16,'K'); a.put(139+AO,16,'B'); a.put(140+AO,16,'p')
a.fill(146+AO,15,150+AO,25,'#')
a.fill(151+AO,5,158+AO,5,'#'); a.fill(153+AO,6,153+AO,14,'S')
a.fill(159+AO,12,165+AO,25,'#'); a.put(160+AO,11,'K')
a.put(168+AO,10,'O'); a.put(172+AO,9,'O')
a.fill(176+AO,8,180+AO,25,'#'); a.put(177+AO,7,'5')
a.fill(183+AO,7,189+AO,25,'#'); a.put(184+AO,6,'M'); a.put(185+AO,6,'B'); a.put(187+AO,6,'E')
lvl5=a.rows()

# ------------------------------------------------------------ VI · NUH'UN GEMİSİ
W,H=300,30
n=G(W,H)
n.fill(0,0,191,18,'#')                       # alt ambarın tavanı (gövde)
n.fill(0,26,299,29,'#')                      # omurga
# 1) Giriş ve birinci ambar: aslan, eşinin gölgesine
n.put(2,25,'P'); n.put(3,25,'p'); n.put(4,25,'1'); n.put(6,25,'B'); n.put(8,25,'K')
n.put(18,25,'a')                             # aslan (1. hayvan)
n.put(30,25,'G'); n.put(26,25,'I'); n.put(38,25,'I'); n.put(14,25,'F')
n.put(52,25,'d')                             # aslanın eşi (1. gölge)
n.fill(58,19,58,25,'H')
# 2) İkinci ambar: fil ve zürafa; araya düşen çukuru düz sandık doldurur
n.put(60,25,'K'); n.put(61,25,'p'); n.put(62,25,'2'); n.put(64,25,'B')
n.put(70,25,'a'); n.put(74,25,'a')          # fil, zürafa
n.fill(80,23,83,23,'#'); n.put(81,22,'C')    # rafta düz sandık
n.put(84,26,'.',force=True)                  # sandığın oturacağı tek karelik çukur
n.put(96,25,'d'); n.put(102,25,'d')          # filin ve zürafanın gölgeleri
n.fill(108,19,108,25,'H')
n.put(90,25,'M'); n.put(99,25,'3')
# 3) Kandillerin ambarı: Kandilciler, karanlık, gözler
n.put(110,25,'K'); n.put(111,25,'p'); n.put(113,25,'B')
n.put(114,20,'x'); n.put(150,25,'X')
n.put(122,25,'G'); n.put(140,25,'G'); n.fill(130,25,131,25,'~'); n.put(134,25,'I'); n.put(146,25,'~')
n.put(118,25,'F'); n.put(136,25,'F'); n.put(128,22,'e'); n.put(144,25,'4')
n.fill(152,24,156,25,'#'); n.fill(157,22,161,25,'#')   # yük yığınları
n.fill(165,26,175,29,'w'); n.fill(165,22,175,22,'=')   # sızan su, üstünde kiriş
n.put(170,21,'M')
n.put(178,25,'K'); n.put(180,25,'B'); n.put(185,25,'5')
# 4) Ambar kuyusu: tufan geri döner, yukarı kaç
n.fill(192,0,229,2,'#')
n.put(193,3,'q'); n.put(229,25,'Q')
n.put(195,25,'o'); n.put(197,25,'p')
for i,r in enumerate(range(24,9,-2)):
    a = 199 if i % 2 == 0 else 205
    n.fill(a,r,a+7,r,'=')
n.fill(218,3,218,11,'S')                     # sallanılan ip
n.fill(224,8,229,8,'=')
n.fill(230,9,299,25,'#')                     # üst güverte (buzula gömülü)
n.fill(230,8,236,8,'-')
# 5) Üst güverte: buz, Kandilci, sönmüş ışığın yeri
n.put(232,7,'K'); n.put(233,7,'p'); n.put(234,7,'6'); n.put(238,7,'B')
n.put(248,7,'G'); n.fill(244,7,245,7,'~'); n.put(258,7,'I'); n.put(262,7,'G')
n.fill(266,6,268,7,'#'); n.put(267,5,'M')    # sönmüş ışığın kaidesi
n.put(270,7,'7'); n.put(276,7,'K'); n.put(284,7,'B'); n.put(290,7,'E')
n.fill(252,7,256,7,'-')
lvl6=n.rows()

# ------------------------------------------------------------ VII · NEMRUT
W,H=330,26
F=20
m=G(W,H)
# 1) Dağın yolu
m.fill(0,22,14,25,'#'); m.put(2,21,'P'); m.put(3,21,'p'); m.put(4,21,'1'); m.put(6,21,'B')
m.fill(15,21,19,25,'#'); m.fill(20,F,39,25,'#'); m.put(10,21,'F')
m.fill(24,11,32,12,'#'); m.put(26,13,'%'); m.put(30,13,'%')   # sarkan kaya, gevşek taşlar
m.put(22,F-1,'K'); m.put(34,F-1,'2')
# 2) Batı Terası: dört taş tanrı, omuzlarında yıldız taşları
m.fill(40,F,91,25,'#'); m.put(41,F-1,'p'); m.put(42,F-1,'K'); m.put(45,F-1,'+'); m.put(51,F-1,'3')
for i,x in enumerate((53,62,71,80)):
    m.put(x,F-10,'?')                       # heykelin çizimi (zemine oturur)
    m.fill(x,F-4,x+5,F-1,'#')               # taht
    m.fill(x-1,F-2,x-1,F-1,'#')             # ayak taburesi
    m.fill(x+6,F-3,x+6,F-1,'#')             # diz
    m.put(x+5,F-6,'#')                      # kol
    m.fill(x+1,F-8,x+4,F-8,'#')             # omuzlar
    m.put(x+2,F-9,'*')                      # yıldız taşı
m.put(47,F-1,'G'); m.put(66,F-9,'M')
m.fill(91,2,91,F-7,'#'); m.fill(91,F-6,91,F-1,'H')
# 3) Deprem yarığı: çöken kayalar, tepeden düşen gevşek taşlar
m.fill(92,F,95,25,'#'); m.put(93,F-1,'K'); m.put(94,F-1,'B'); m.put(95,F-1,'p')
m.fill(100,8,128,9,'#')
for c in (102,107,112,117,122,126):
    m.put(c,10,'%')
m.put(98,F,'O'); m.put(103,F-1,'O'); m.put(108,F,'O'); m.put(113,F-1,'O'); m.put(118,F,'O'); m.put(123,F-1,'O')
m.fill(127,F,140,25,'#'); m.put(128,F-1,'K'); m.put(130,F-1,'4'); m.put(133,F-1,'B')
# 4) Kartalın gözü: kartalın tepesinde Gözcü, düşmüş başların ardı saklanma yeri
m.fill(141,F,199,25,'#'); m.put(142,F-1,'p')
m.fill(176,F-5,178,F-1,'#'); m.put(175,F-1,':'); m.put(177,F-6,'g')
for x in (148,156,164,186):
    m.put(x,F-1,';'); m.put(x+1,F-1,'I')
m.put(152,F-1,'G'); m.put(160,F-1,'F'); m.put(170,F-1,'5'); m.put(190,F-1,'M')
m.put(195,F-1,'K'); m.put(197,F-1,'B')
# 5) Tümülüs: çakıl yamacında tırmanış
m.fill(200,F,206,25,'#'); m.put(201,F-1,'p'); m.put(203,F-1,'6')
m.fill(207,F-2,209,25,'#'); m.fill(210,F-4,212,25,'#'); m.put(214,F-6,'O'); m.put(218,F-7,'O')
m.fill(222,F-8,230,25,'#'); m.put(224,F-9,'K'); m.put(226,F-9,'B')
m.fill(225,F-18,235,F-17,'#'); m.put(229,F-16,'%'); m.put(233,F-16,'%')
m.fill(231,F-10,233,25,'#'); m.fill(234,F-12,236,25,'#')
m.put(240,F-13,'O'); m.put(245,F-14,'O')
m.fill(249,F-14,262,25,'#'); m.put(250,F-15,'K'); m.put(253,F-15,'7'); m.put(258,F-15,'M')
# 6) Doğuya geçit: tipili sırt, Kandilci kampı
m.fill(263,F-12,329,25,'#'); m.put(264,F-13,'p')
m.put(272,F-13,'G'); m.fill(276,F-13,277,F-13,'~'); m.put(282,F-13,'I'); m.put(290,F-13,'G')
m.fill(294,F-13,295,F-13,'~'); m.put(300,F-13,','); m.put(303,F-13,'F'); m.put(310,F-13,'G')
m.fill(314,F-13,315,F-13,'~'); m.put(320,F-13,'K'); m.put(322,F-13,'B'); m.put(326,F-13,'E')
m.put(306,F-13,'8')
lvl7=m.rows()

# ------------------------------------------------------------ VIII · GÜN DOĞUMU
W,H=212,26
F=20
d=G(W,H)
d.fill(0,F,211,25,'#')
# 1) Tören yolu: şafakta Kandilciler, dikili taşlar, düşmüş başlar
d.put(2,F-1,'P'); d.put(3,F-1,'p'); d.put(4,F-1,'1'); d.put(6,F-1,'B'); d.put(8,F-1,'F')
d.put(14,F-1,';'); d.put(15,F-1,'I'); d.put(20,F-1,'G'); d.put(25,F-1,'I')
d.put(30,F-1,';'); d.put(31,F-1,'I'); d.put(36,F-1,'G'); d.put(41,F-1,'I')
d.put(28,F-9,'N'); d.put(34,F-1,'2'); d.put(44,F-1,'K'); d.put(46,F-1,'B')
# 2) Terasın kapısı: kol bir tanrının omzunda
d.put(51,F-1,'p'); d.put(52,F-1,'3')
x=55
d.put(x,F-10,'?'); d.fill(x,F-4,x+5,F-1,'#'); d.fill(x-1,F-2,x-1,F-1,'#'); d.fill(x+6,F-3,x+6,F-1,'#')
d.put(x+5,F-6,'#'); d.fill(x+1,F-8,x+4,F-8,'#'); d.put(x+2,F-9,'L'); d.put(x+3,F-9,'M')
d.fill(66,2,66,F-7,'#'); d.fill(66,F-6,66,F-1,'H')
# 3) Doğu Terası: taş dev Nemrud. Kulak hizasında raflar, ateşböcekleri
d.put(68,F-1,'K'); d.put(69,F-1,'p'); d.put(71,F-1,'4'); d.put(73,F-1,'B')
d.fill(76,F-5,79,F-5,'#'); d.fill(76,F-4,76,F-1,'|')     # sol raf ve sarmaşık
d.fill(100,F-5,103,F-5,'#'); d.fill(103,F-4,103,F-1,'|')  # sağ raf ve sarmaşık
d.put(74,F-1,'5')
d.put(78,F-6,'F'); d.put(101,F-6,'F'); d.put(112,F-1,'F')
d.put(82,F-1,'`')
d.fill(125,2,125,F-7,'#'); d.fill(125,F-6,125,F-1,'H')
# 4) Güneşin doğduğu yer: ayin, Kandilciler, ışık
d.put(127,F-1,'K'); d.put(128,F-1,'p'); d.put(130,F-1,'B')
d.fill(134,F-2,137,F-1,'#'); d.fill(140,F-4,143,F-1,'#'); d.fill(146,F-6,212-1,F-1,'#')
d.put(150,F-7,'G'); d.fill(154,F-7,155,F-7,'~'); d.put(160,F-7,';'); d.put(161,F-7,'I')
d.put(166,F-7,'G'); d.fill(170,F-7,171,F-7,'~'); d.put(176,F-7,'G'); d.put(172,F-15,'N')
d.put(180,F-7,'6'); d.put(184,F-7,'M'); d.put(190,F-7,'K'); d.put(195,F-7,'B'); d.put(205,F-7,'E')
d.put(188,F-7,'?')
lvl8=d.rows()

# ------------------------------------------------------------ IX · KAR YOLU
W,H=320,26
F=20
k9=G(W,H)
# 1) Kervan yolu: palanlarını döken kervanların yolu
k9.fill(0,F,64,25,'#'); k9.put(2,F-1,'P'); k9.put(3,F-1,'p'); k9.put(4,F-1,'1'); k9.put(6,F-1,'B')
k9.fill(12,F-2,14,F-1,'#'); k9.fill(20,F-1,22,F-1,'#'); k9.put(26,F-1,'M'); k9.put(30,F-1,'F')
k9.fill(34,F-3,36,F-1,'#'); k9.put(40,F-1,'2'); k9.fill(44,F-2,46,F-1,'#'); k9.put(52,F-1,'K')
k9.fill(50,10,58,11,'#'); k9.put(53,12,'i'); k9.put(56,12,'i')
# 2) Kurtların ormanı: kurtlar kokuyu izler; ağaçlara tırman, ateşböceğiyle kaçır
k9.fill(65,F,129,25,'#'); k9.put(66,F-1,'p'); k9.put(68,F-1,'3')
for x,top in [(72,10),(84,9),(96,10),(108,9),(120,10)]:
    k9.fill(x,top,x,F-1,'|')                   # ağaç gövdesi (tırmanılır)
    k9.fill(x-2,top-1,x+2,top-1,'=')           # dal
k9.fill(73,9,83,9,'='); k9.fill(97,9,107,9,'=')          # dallar arası köprü
k9.put(78,F-1,'b'); k9.put(102,F-1,'b'); k9.put(75,F-1,'F'); k9.put(90,F-1,'F'); k9.put(114,F-1,'F')
k9.put(90,8,'M'); k9.put(110,F-1,'4'); k9.put(126,F-1,'K'); k9.put(127,F-1,'B')
# 3) Donmuş göl: ince buz, güvenli buz, kurdu ince buza çek
k9.put(130,F-1,'p'); k9.put(131,F-1,'5')
k9.fill(130,F,133,25,'#'); k9.fill(134,F+1,190,25,'w')
for x in range(134,191):
    k9.put(x,F,'/' if (x//4) % 3 != 0 else '-')
k9.fill(150,F-2,151,F-1,'#'); k9.fill(170,F-2,171,F-1,'#')    # buzdan çıkan kayalar
k9.put(123,F-1,'b'); k9.put(160,F-6,'F'); k9.fill(158,F-5,162,F-5,'=')
k9.fill(191,F,199,25,'#'); k9.put(192,F-1,'K'); k9.put(194,F-1,'B')
# 4) Terk edilmiş han: Kandilciler, çan, kapı
k9.fill(200,F,262,25,'#'); k9.fill(203,F-9,252,F-8,'#')     # hanın çatısı
k9.fill(203,F-7,203,F-2,'#'); k9.put(201,F-1,'p'); k9.put(205,F-1,'6')
k9.put(212,F-1,'G'); k9.put(216,F-1,'I'); k9.put(222,F-1,'I'); k9.put(228,F-1,'G')
k9.put(234,F-1,'~'); k9.put(235,F-1,'~'); k9.put(219,F-7,'c'); k9.fill(218,F-8,220,F-8,'#')
k9.put(240,F-1,'M'); k9.fill(244,F-4,246,F-1,'#'); k9.put(245,F-5,'L')
k9.fill(252,F-7,252,F-1,'H'); k9.put(258,F-1,'K'); k9.put(260,F-1,'B')
# 5) Ejder'in eteği: rüzgârlı tırmanış
k9.fill(263,F-2,267,25,'#'); k9.fill(268,F-4,272,25,'#'); k9.put(269,F-5,'p'); k9.put(270,F-5,'7')
k9.fill(275,F-6,278,25,'#'); k9.put(282,F-7,'O'); k9.put(287,F-8,'O')
k9.fill(291,F-9,296,25,'#'); k9.put(292,F-10,'K'); k9.fill(293,2,296,3,'#'); k9.put(294,4,'%')
k9.fill(297,F-11,302,25,'#'); k9.fill(303,F-13,319,25,'#')
k9.put(306,F-14,'8'); k9.put(310,F-14,'B'); k9.put(315,F-14,'E')
lvl9=k9.rows()

# ------------------------------------------------------------ kayak pisti
class Ski:
    """Kayak yamacı: segmentlerle yükseklik dizisi kurar, işaretleri koyar."""
    def __init__(s, start_row):
        s.y=[]; s.row=start_row; s.marks=[]; s.magnets=[]
    @property
    def x(s): return len(s.y)
    def flat(s,n):
        s.y += [s.row]*n
    def slope(s,n,drop,amp=0.0,period=10):
        for i in range(n):
            t=(i+1)/n
            s.y.append(s.row + drop*t + amp*math.sin(i*2*math.pi/period))
        s.row += drop
    def kicker(s,n,rise):
        for i in range(n):
            s.y.append(s.row - rise*(i+1)/n)
        s.row -= rise
    def gap(s,n,drop_after):
        s.y += [-1]*n
        s.row += drop_after
    def magnet(s,n,rise):
        a=s.x
        s.kicker(n,rise)
        s.magnets.append((a,s.x-1))
    def mark(s,ch,dx=0,up=1):
        c=s.x+dx
        s.marks.append((c,ch,up))
    def rail_over_gap(s,n,drop_after):
        c=s.x; r=int(round(s.row))
        s.marks.append((c-1,'=',('rail',n+2,r)))
        s.gap(n,drop_after)
    def build(s,H):
        W=len(s.y)
        g=G(W,H)
        for c,ch,up in s.marks:
            if isinstance(up,tuple):
                _,n,r=up
                for k in range(n):
                    g.put(c+k,r-1,'=',force=True)
                continue
            base=s.y[c] if 0<=c<W and s.y[c]>=0 else s.row
            r=int(math.floor(base))-up
            if g.g[r][c]=='.': g.g[r][c]=ch
        return g, [round(v,2) for v in s.y]

import math
# ------------------------------------------------------------ X · PALANDÖKEN
sk=Ski(8)
sk.flat(3); sk.mark('P',0); sk.mark('p',1); sk.mark('1',2); sk.flat(6); sk.mark('B',0)
sk.slope(24,5,0.6,9); sk.mark('K'); sk.mark('2',2)
sk.slope(10,2); sk.mark('%',0); sk.slope(10,3); sk.mark('%',0); sk.slope(8,2)
sk.mark('p'); sk.kicker(3,1); sk.gap(4,5); sk.slope(14,4); sk.mark('F',-8,4)
sk.mark('K'); sk.mark('B',1); sk.slope(10,2)
sk.rail_over_gap(7,2); sk.slope(14,4); sk.mark('3',3)
sk.slope(40,10,1.6,10); sk.mark('F',-12,4); sk.mark('F',-22,4); sk.mark('M',-30,5)
sk.mark('K'); sk.mark('p',1); sk.mark('4',3)
sk.slope(44,10,0.8,14); sk.mark('N',-14,7); sk.mark('N',-34,7); sk.mark('%',-20,0); sk.mark('B',-2)
sk.mark('K'); sk.mark('p',2); sk.mark('5',3)
sk.slope(6,2); sk.magnet(24,6); sk.mark('F',-6,3); sk.slope(4,1)
sk.mark('6',0); sk.mark('K',1)
sk.slope(12,3); sk.mark('p'); sk.kicker(4,2); sk.gap(9,10); sk.slope(16,5); sk.mark('F',-14,7); sk.mark('7',2)
sk.mark('K'); sk.mark('B',1)
for i in range(4):
    sk.slope(14,4); sk.mark('%',0)
sk.slope(8,2); sk.rail_over_gap(5,2); sk.slope(8,2); sk.rail_over_gap(6,3); sk.slope(10,3); sk.mark('M',-4,1)
sk.mark('K'); sk.mark('p',1); sk.mark('8',3)
sk.slope(60,14,1.2,12); sk.mark('F',-20,4); sk.mark('F',-40,4)
sk.flat(12); sk.mark('B',-6); sk.mark('E',-3)
pal_grid, pal_surface = sk.build(int(max(sk.y))+12)
lvl10 = pal_grid.rows()

# ------------------------------------------------------------ XI · ÇIĞ
ck=Ski(8)
ck.flat(4); ck.mark('P',1); ck.mark('p',2); ck.mark('1',3); ck.flat(6); ck.mark('B',0); ck.mark('z',2)
ck.slope(30,9,0.8,10); ck.mark('2',-10)
ck.kicker(3,1); ck.gap(5,6); ck.slope(16,6); ck.mark('K'); ck.mark('F',-8,5)
ck.slope(10,3); ck.mark('%',0); ck.slope(14,5); ck.mark('%',0); ck.slope(10,3)
ck.mark('p'); ck.mark('3',2); ck.slope(40,14,1.4,11); ck.mark('M',-20,5)
ck.rail_over_gap(6,3); ck.slope(12,4); ck.mark('K'); ck.mark('B',1)
ck.mark('p',2); ck.mark('4',3)
for i in range(3):
    ck.slope(10,3); ck.kicker(2,1); ck.gap(4,5); ck.slope(8,3); ck.mark('%',-4)
ck.slope(20,6,0.6,8); ck.mark('K')
ck.mark('p',1); ck.mark('5',2); ck.slope(10,4); ck.kicker(4,2); ck.gap(10,12); ck.slope(20,8)
ck.mark('F',-18,8); ck.mark('M',-6,1)
ck.slope(40,10,1.0,13); ck.mark('Z',-2)
ck.flat(14); ck.mark('p',-12); ck.mark('6',-10); ck.mark('K',-9); ck.mark('B',-6); ck.mark('E',-3)
cig_grid, cig_surface = ck.build(int(max(ck.y))+12)
lvl11 = cig_grid.rows()

# ------------------------------------------------------------ XII · PERİ BACALARI
W,H=388,30
pb=G(W,H)
def chimney(g,x,top,ring=False,holds=True,w=2):
    g.fill(x,top+1,x+w-1,H-1,'#')
    g.fill(x,top,x+w,top,'#')                   # bazalt şapka (sağa taşar)
    if holds:
        g.fill(x-1,top+1,x-1,H-5,'|')           # oyma tutamaklar (sol yüz)
    if ring:
        g.put(x+1,top-1,'"')
# 1) Muşkara köyü
pb.fill(0,26,43,29,'#')
pb.put(2,25,'P'); pb.put(3,25,'p'); pb.put(4,25,'1'); pb.put(6,25,'B')
pb.fill(10,21,14,25,'#'); pb.put(12,20,'k'); pb.fill(20,19,25,25,'#'); pb.put(22,18,'k')
pb.put(17,25,'2'); pb.put(28,25,'F'); pb.put(32,25,'K'); pb.put(35,25,'M')
# 2) Peri bacaları: tutamaklarla tırmanış, peri halkalarıyla yükseliş
pb.fill(44,26,108,29,'#'); pb.put(45,25,'p'); pb.put(46,25,'3')
for x,top,ring in [(48,22,True),(54,19,False),(60,16,True),(67,13,False),(74,15,True),(81,10,False),(88,7,False),(95,12,True),(102,17,False)]:
    chimney(pb,x,top,ring)
pb.put(88,6,'M'); pb.put(81,9,'k'); pb.put(60,15,'F') if False else None
pb.put(72,25,'4'); pb.put(92,25,'F'); pb.put(105,25,'K'); pb.put(107,25,'B')
# 3) Güvercinlik vadisi: iki ipli geçiş (Ağrı'da denenmiş düzen), ortada güvercinlikli ada
x=rope_chasm(pb,109,18,n=5)
pb.fill(x,18,156,29,'#')
pb.put(110,17,'p'); pb.put(111,17,'5'); pb.put(112,17,'K')
pb.put(152,17,'k'); pb.put(154,17,'k'); pb.put(153,17,'K'); pb.put(155,17,'B')
x=rope_chasm(pb,157,18,n=4)
pb.put(192,17,'6'); pb.put(193,17,'F')
pb.fill(195,24,197,29,'#'); pb.put(196,23,'G')
PO=4
# 4) Kaya kilisesi: Kandilcilerin kampı, tavandan düşen ışık, apsiste Gözcü
pb.fill(194+PO,6,254+PO,29,'#')
pb.fill(197+PO,14,251+PO,25,'.')                    # nef
pb.fill(194+PO,23,196+PO,25,'.')                    # kapı
pb.fill(193+PO,26,196+PO,29,'#')
pb.put(198+PO,25,'p'); pb.put(199+PO,25,'K'); pb.put(201+PO,25,'7')
for x in (206+PO,214+PO,230+PO,238+PO):
    pb.put(x,25,'I')
pb.put(210+PO,25,'G'); pb.put(234+PO,25,'G'); pb.put(222+PO,22,'M')
pb.put(220+PO,14,'j'); pb.put(220+PO,24,'m'); pb.put(248+PO,25,'g')
pb.fill(252+PO,23,254+PO,25,'.')                    # apsisin ardındaki çıkış
pb.put(244+PO,25,'F')
# 5) Perilerin dansı: halkadan halkaya
pb.fill(255+PO,26,329+PO,29,'#'); pb.put(256+PO,25,'K'); pb.put(257+PO,25,'p'); pb.put(258+PO,25,'8')
for x,top,ring in [(262+PO,22,True),(269+PO,18,True),(276+PO,14,False),(283+PO,12,True),(291+PO,9,False),(299+PO,12,True),(307+PO,16,False),(314+PO,20,True)]:
    chimney(pb,x,top,ring)
pb.put(291+PO,8,'M'); pb.put(299+PO,11,'F') if False else None
pb.put(320+PO,25,'F'); pb.put(324+PO,25,'K'); pb.put(326+PO,25,'B')
# 6) Uçhisar: dev kaya kaleye tırmanış
pb.fill(330+PO,26,383+PO,29,'#'); pb.put(331+PO,25,'p')
pb.fill(338+PO,4,370+PO,25,'#')
pb.fill(337+PO,4,337+PO,25,'|')
for r in (21,16,11):
    pb.fill(338,r,341,r,'.')                  # dinlenme oyukları
pb.fill(338+PO,3,372+PO,3,'#')
pb.put(345+PO,2,'9'); pb.put(352+PO,2,'K'); pb.put(360+PO,2,'B'); pb.put(366+PO,2,'E')
lvl12=pb.rows()

# ------------------------------------------------------------ XIII · DERİNKUYU
W,H=362,48
dk=G(W,H,fill='#')
def carve(c0,r0,c1,r1): dk.fill(c0,r0,c1,r1,'.')
# 1) Mahzen
carve(1,10,22,15); dk.put(2,15,'P'); dk.put(3,15,'p'); dk.put(5,15,'1'); dk.put(7,15,'B'); dk.put(12,15,'F')
# 2) Ahırlar ve şarap evi: alçak geçit, Kandilciler, sürgü taşı
carve(22,12,94,15)
carve(30,9,45,11); dk.fill(36,9,36,15,'#'); dk.put(34,15,'I'); dk.put(40,15,'K'); dk.put(42,15,'2')
dk.put(50,15,'G'); carve(44,16,44,16); carve(44,17,57,17); carve(57,16,57,16)   # alçak geçit
dk.put(52,17,'3'); dk.put(48,17,'M')
carve(60,10,74,11); dk.put(66,15,'I'); dk.put(80,15,'G'); dk.put(70,15,'F')
dk.put(86,15,'@'); dk.put(84,15,'K'); dk.put(85,15,'B')
carve(90,16,94,23); carve(80,17,94,23)          # aşağı kat (üst katın altına uzanır)
# Aşağı kat: şapel, karanlık; yüksek kapıya sürgü taşıyla çıkılır
carve(95,17,107,23); carve(98,14,104,16); dk.put(101,23,'p'); dk.put(99,23,'K'); dk.put(103,23,'4')
dk.put(105,23,'I')
carve(108,17,150,20); dk.put(109,20,'B'); dk.put(116,20,'G'); dk.put(124,20,'~'); dk.put(125,20,'~')
dk.put(128,17,'x'); dk.put(148,20,'X'); dk.put(132,20,'F'); dk.put(142,20,'F'); dk.put(138,18,'e')
# 3) Havalandırma bacası: aşağıdan sıcak rüzgâr, devlerin nefesi
carve(151,10,172,39); dk.put(152,20,'p'); dk.put(153,20,'5')
dk.fill(151,21,154,21,'#'); dk.put(152,20,'.',force=True); dk.put(153,20,'5',force=True)
dk.fill(158,22,161,39,'r')
dk.fill(165,27,169,27,'#'); dk.put(167,26,'!'); dk.put(165,26,'M'); dk.put(151,19,'p')
dk.fill(151,32,155,32,'#'); dk.put(153,31,'!'); dk.put(151,31,'F')
dk.fill(164,36,169,36,'#'); dk.put(166,35,'!')
# 4) Derin kuyu: boşalt, in, doldur, tahtayla üst geçide çık
carve(173,34,198,39); dk.put(174,39,'K'); dk.put(175,39,'B'); dk.put(177,39,'6'); dk.put(176,39,'p')
carve(186,21,198,33)
dk.put(186,23,'q'); dk.put(198,39,'Q'); dk.put(188,39,'y'); dk.put(194,39,'f')
dk.fill(186,40,198,40,'#')
carve(199,20,250,23); dk.fill(199,24,250,24,'#'); dk.put(202,23,'K'); dk.put(204,23,'B')
dk.put(215,23,'G'); dk.put(222,23,'I'); dk.put(232,23,'G'); dk.put(240,23,'M')
# 5) Devlerin kapısı: en dip, ışığı yiyen karanlık, dev gölgesinden kaçış
for i in range(6):
    carve(250+i*2,24+i*3,252+i*2,27+i*3)
carve(262,32,320,43); dk.put(263,43,'p'); dk.put(264,43,'K'); dk.put(266,43,'7'); dk.put(267,43,'F')
dk.put(262,33,'x'); dk.put(319,43,'X'); dk.put(270,36,'e')
dk.put(272,43,'z'); dk.put(318,43,'Z')
for c in (280,292,304):
    dk.fill(c,41,c+1,43,'#')
dk.fill(286,43,288,43,'^'); dk.fill(298,43,300,43,'^')
dk.put(276,43,'F'); dk.put(296,40,'F') if False else None
# 6) Yukarıya: ana bacadan aya
carve(320,4,330,43); dk.fill(325,6,325,43,'|')
for r in (36,28,20,12):
    dk.fill(321,r,323,r,'#'); dk.fill(327,r,329,r,'#')
dk.put(322,35,'K'); dk.put(328,19,'M')
carve(330,4,361,7); dk.put(333,7,'p') if False else None
dk.put(334,7,'8'); dk.put(340,7,'K'); dk.put(346,7,'B'); dk.put(355,7,'E')
dk.put(331,7,'p')
lvl13=dk.rows()

# ------------------------------------------------------------ XIV · KONYA (ŞEB-İ ARÛS)
from sections import ground, stealth_hall, crumble_run, lever_gate, mirror_lock
W,H=468,48
kn=G(W,H)
def kc(c0,r0,c1,r1): kn.fill(c0,r0,c1,r1,'.')
# 1) Konya Ovası ve eski höyük: damdan girilen evler; donmuş bataklık, kurtlar
kn.fill(0,40,65,47,'#')
kn.put(2,39,'P'); kn.put(3,39,'p'); kn.put(5,39,'1'); kn.put(7,39,'B')
kn.fill(18,38,62,39,'#'); kn.fill(24,36,56,37,'#'); kn.fill(30,34,50,35,'#'); kn.fill(36,32,44,33,'#')
kn.put(20,37,'p'); kn.put(21,37,'2'); kn.put(40,31,'B')
kc(32,36,46,39)                                   # evin içi
kn.fill(33,34,33,39,'|'); kn.fill(45,34,45,39,'|')   # damdaki delikler
kn.put(35,39,'K'); kn.put(36,39,'3'); kn.put(38,39,'F'); kn.put(40,39,'M')
kn.fill(66,40,79,40,'/'); kn.fill(66,41,79,46,'w'); kn.fill(66,47,79,47,'#')   # donmuş bataklık
kn.fill(80,40,85,47,'#'); kn.put(82,39,'b'); kn.put(84,39,'b')
# 2) İkonion Kapısı: surun içinden geçen kemer, sonunda Medusa'nın başı
kn.fill(86,28,124,47,'#')
kc(86,34,121,37)
kn.put(121,35,'U'); kn.put(90,37,'@')
kn.fill(117,28,117,37,'|')                        # sura çıkan merdiven
kn.put(87,37,'p'); kn.put(88,37,'K'); kn.put(89,37,'4'); kn.put(95,37,'5')
kn.put(100,27,'M'); kn.put(119,27,'6'); kn.put(122,27,'F')
# 3) Alâeddin Tepesi: Selçuklu köşkünün kalıntıları
x=stealth_hall(kn,125,28,n=30,guards=2)
kn.put(125,27,'K'); kn.put(126,27,'p'); kn.put(128,27,'7')
x=crumble_run(kn,x,28,n=4)
kn.put(175,27,'8'); kn.put(176,27,'B')
kn.put(177,27,'K')
x=lever_gate(kn,x,28)
# 4) Karatay Medresesi: kubbedeki açıklıktan inen ay ışığı
kn.put(191,27,'p')
x=mirror_lock(kn,x,28)
kn.put(194,27,'9'); kn.put(218,27,'K')
# 5) İnce Minare: şerefedeki büyük fenerler damları tarar
ground(kn,219,28,16); kn.fill(220,24,226,25,'#')
kn.put(220,27,'p'); kn.put(221,27,'('); kn.put(223,27,'K')
kn.fill(231,26,231,27,'#')                        # baca
ground(kn,238,28,27); kn.fill(239,24,245,25,'#')  # revak
kn.fill(249,9,250,23,'#'); kn.fill(246,9,253,9,'#')   # minare (altı kemer)
kn.put(247,10,'0'); kn.put(252,10,'0')
kn.fill(260,26,261,27,'#'); kn.put(263,27,'I')    # kubbe, gölge
ground(kn,269,28,14); kn.fill(270,24,280,25,'#')
kn.put(271,27,'K'); kn.put(275,27,'M'); kn.put(277,27,'F')
# 6) Şems'in Kuyusu: sokak kuyuda biter; dipte karanlık bir geçit
kn.fill(283,28,331,47,'#')
kn.fill(330,12,331,27,'#')                        # dergâhın duvarı
kc(305,28,306,39); kc(305,40,331,42)
kn.put(305,42,'p'); kn.put(306,42,'K'); kn.put(309,42,'F'); kn.put(308,41,')')
kn.put(307,40,'x'); kn.put(330,42,'X'); kn.put(318,40,'e'); kn.put(322,42,'M')
# 7) Dergâh avlusu: semâzenler döner, Kandilciler dolaşır
kn.fill(332,26,372,47,'#')
kc(330,30,372,33)
kn.fill(331,34,331,42,'|')                        # avluya çıkan merdiven
kn.put(330,33,'I'); kn.put(333,33,'p'); kn.put(335,33,'[')
for c in (342,352,362): kn.put(c,33,'a')
kn.put(346,33,'G'); kn.put(360,33,'G'); kn.put(370,33,'I')
# 8) Semâhane: dönen avizeler, yerde semâ ve Kandilciler
kn.fill(373,8,430,47,'#')
kc(373,30,375,33); kn.put(373,33,'#',force=True)  # kapı eşiği
kc(376,12,427,43)
kn.fill(376,34,381,43,'#')                        # mutribhane
kn.fill(382,34,382,43,'|')
kn.put(376,33,'p'); kn.put(377,33,'K'); kn.put(378,33,']'); kn.put(379,33,'F'); kn.put(380,33,'B')
for c,r in ((387,32),(396,28),(405,24)): kn.put(c,r,'d')
for c in (392,404): kn.put(c,43,'a')
kn.put(397,43,'G'); kn.put(408,43,'G')
kn.fill(412,22,427,43,'#')                        # çıkış
kc(428,18,430,21)
# 9) Kubbe-i Hadrâ: ışık seli yükselirken tepeye tırmanış
kn.fill(431,22,467,47,'#')
kn.put(418,21,'K'); kn.put(419,21,'{'); kn.put(431,21,'p'); kn.put(434,21,'z')
kn.fill(438,20,440,20,'#'); kn.fill(442,18,444,18,'#'); kn.put(446,16,'O'); kn.put(447,16,'O')
kn.fill(450,14,453,14,'#'); kn.fill(453,5,453,13,'|')
kn.fill(446,8,452,8,'#')
kn.fill(441,6,443,6,'#'); kn.fill(436,4,438,4,'#')
kn.fill(430,3,434,3,'#'); kn.put(435,4,'Z')
kn.put(431,2,'E'); kn.put(433,2,'M')
lvl14=kn.rows()

MAPS = [('kMapYerebatan', lvl1), ('kMapKule', lvl2), ('kMapGokyolu', lvl3), ('kMapKaf', lvl4), ('kMapAgri', lvl5), ('kMapGemi', lvl6), ('kMapNemrut', lvl7), ('kMapGunDogumu', lvl8), ('kMapKarYolu', lvl9), ('kMapPalandoken', lvl10), ('kMapCig', lvl11), ('kMapPeri', lvl12), ('kMapDerinkuyu', lvl13), ('kMapKonya', lvl14)]

out = ['// Bu dosya tools/generate_maps.py ile üretilir; elle düzenleme.',
       '// Gösterim: lib/game/level.dart başındaki açıklamaya bakın.', '']
for name, rows in MAPS:
    widths = set(len(r) for r in rows)
    assert len(widths) == 1, (name, widths)
    out.append(f'const {name} = <String>[')
    out += [f"  '{r}'," for r in rows]
    out += ['];', '']
    print(name, len(rows), 'x', widths.pop())
SURFACES = [('kSkiPalandoken', pal_surface), ('kSkiCig', cig_surface)]
for name, ys in SURFACES:
    out.append(f'const {name} = <double>[')
    for i in range(0, len(ys), 12):
        out.append('  ' + ', '.join(f'{v:.2f}' if v >= 0 else '-1' for v in ys[i:i+12]) + ',')
    out += ['];', '']
open('lib/game/maps.dart', 'w').write('\n'.join(out))
print('magnet', sk.magnets)
