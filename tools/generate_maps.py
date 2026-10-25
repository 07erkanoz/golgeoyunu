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
# Kolun rafı yere kadar dolu: sandık altına kaçıp tırmanışı kapatmasın,
# rafın dibine dayansın; sandıktan doğrudan kenara tutunulur.
y.fill(53,11,56,13,'#')
# Rafın sağ yüzünde zincir: kolu çekmeden aşağı inen geri tırmanabilsin
# (kapı ile raf arasında sıkışıp kalmasın).
y.fill(57,10,57,13,'|')
# S2a · Unutulmuş Gölgehane: yolun sonundaki boşluğun dibinde taş gibi
# boyanmış bir perde (levels.dart'ta 'golgehane'); ardında kayaya oyulmuş,
# ustanın eski çalışma odası. Sahanlık ve basamaklar bir zıplamada aşılır.
y.fill(45,16,46,17,'#')                      # perdenin sahanlığı
y.fill(47,15,62,18,'.')                      # oda
y.fill(47,16,47,18,'#'); y.fill(48,17,48,18,'#')   # dar geçit, basamak
y.fill(0,0,W-1,1,'#'); y.fill(W-1,0,W-1,H-1,'#')
# 4) yarasa galerisi
y.fill(67,14,96,19,'#')
y.fill(68,2,92,7,'#')                        # alçak tavan
y.fill(70,12,70,13,'#'); y.fill(91,12,91,13,'#')
for c in (76,81,86): y.put(c,13,'I')
for c in (72,79,86): y.put(c,8,'b')
y.put(82,13,'G'); y.put(69,13,'F'); y.put(88,13,'M'); y.put(68,13,'5'); y.put(91,11,'B')
# Kaçış odası: girişte çan (bekçiyi sese çeker), çıkışta sola bakan Gözcü
# (ayarı levels.dart'ta). Çanı çal, sütunda saklan, Gözcü dönünce geç.
y.put(73,10,'c'); y.put(95,11,'g')
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
# Sarnıcın iki yüzü: perdenin ardındaki kandil iple kayar (ip perdenin
# solunda); dev gölgenin başı perdedeki göze, kavanozun ışığı taştaki göze
# ($) değince kapı açılır.
y.put(115,8,'$')
y.fill(126,2,126,9,'H')
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
# Su en çok geçidin tabanına (satır 10) çıkar: üstü açık havaya dayanıp
# dimdik bir su duvarı gibi durmasın; çıkış sütunu da o hizada.
y.put(161,9,'q'); y.put(168,18,'Q'); y.fill(161,19,168,19,'#')
y.put(163,18,'y'); y.put(166,11,'f')
y.fill(169,10,172,19,'#'); y.put(171,9,'B'); y.put(172,9,'K')
# Haznenin çıkışında isteğe bağlı ritim yolu (ayarları levels.dart'ta):
# basınca kalkan geniş kaya, karşılıklı inip kalkan iki kaya, uçta ateşböceği.
y.put(173,10,'V'); y.put(177,10,'V'); y.put(180,10,'V')
y.fill(183,5,184,5,'#'); y.put(183,4,'F'); y.fill(185,2,185,5,'#')
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
y.put(246,12,'M'); y.put(233,9,'B')
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
# Uzun zincir tırmanışlarında dinlenme balkonları: tırmanış bölünsün
# (yalnız ekleme; yol değişmez; çan yok, ses Kandilciyi çağırırdı).
for (bc0, bc1, br) in [(4, 6, 137), (23, 25, 158), (24, 26, 18)]:
    if all(k.g[br][c] == '.' for c in range(bc0, bc1 + 1)):
        k.fill(bc0, br, bc1, br, '=')
H = k.H
# Uzatma (2026-10-25): kulenin zindanı haritanın altına eklenir (eski
# satırlar yerinde; başlangıç zindana iner). Kanuni döneminde kule,
# Kasımpaşa tersanesinde çalıştırılan esirlerin zindanıydı.
z=G(30,42)
z.fill(0,0,1,41,'#'); z.fill(28,0,29,41,'#'); z.fill(0,40,29,41,'#')
z.put(4,39,'P'); z.put(5,39,'p'); z.put(7,39,'9'); z.put(9,39,'F')
z.put(2,14,'x'); z.put(27,39,'X')                 # karanlık: ışığı yer
z.fill(11,37,15,37,'='); z.fill(17,34,22,34,'='); z.fill(23,31,26,31,'=')
z.put(24,30,'K')
z.fill(27,18,27,30,'|')                           # duvardaki zincir
z.fill(19,17,26,17,'='); z.put(22,16,'G'); z.fill(20,16,20,16,'~')
z.fill(12,15,16,15,'='); z.put(14,14,'F')
z.put(9,13,'O'); z.put(6,11,'O')
z.fill(2,9,5,9,'='); z.put(4,8,'M')
z.fill(3,0,3,8,'|')                               # zindanın kapağına zincir
rows=k.rows()
rows[167]=rows[167][:4]+'.'+rows[167][5:]         # eski başlangıç
for r in (168,169):
    rows[r]=rows[r][:3]+'|'+rows[r][4:]           # zindanın kapağı
lvl2=rows+z.rows()

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
# Yan raf: düşeni yukarı taşıyan akımdan sola, rafa süzülünür (raf eskiden 10
# kare yukarıdaydı, akım oraya hiç ulaşmıyordu).
s.fill(178,11,179,20,'r'); s.fill(176,12,177,12,'='); s.put(176,11,'F')
# B) Gölgeden köprü: balonun ışığı değince kaybolur; süzülerek aşılamaz
s.fill(200,10,203,11,'#'); s.put(201,9,'K'); s.put(202,9,'6'); s.put(200,9,'p')
s.fill(204,10,209,10,'n'); s.fill(210,10,211,11,'#'); s.put(210,9,'~'); s.put(211,9,'~')
s.fill(212,10,217,10,'n'); s.put(210,4,'N')
s.put(203,0,'<'); s.put(218,12,'>')               # sağanak: kanatlar ıslanır
s.fill(218,10,223,11,'#'); s.put(219,9,'B')
# C) Fırtına adaları: çöken ve kayan kayalar, rüzgâr, Gözcü
s.put(226,10,'O'); s.put(230,9,'O'); s.put(234,8,'R')
s.fill(242,7,244,16,'#'); s.put(243,6,'g')
s.put(242,6,'~')                             # Gözcü'nün dibinde saklanılacak ot
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
s.put(300,2,'N')
# Kandilci yolu: kampın ortasında boşluk; üstündeki soğuk ışık tahtaları
# (bölüm tanımında coldRuns) yalnız Kandilcinin feneriyle belirir. Ateşböceği
# atılınca Kandilci kenarda ona dalar, feneri yolu gösterir. Sağanak:
# kanat ıslanır, boşluk süzülerek aşılmaz.
s.fill(312,8,319,11,'.'); s.put(304,7,'K'); s.put(305,7,'F')
s.put(310,0,'<'); s.put(321,12,'>')
s.fill(322,7,323,7,'~')                      # yolun ucu: dinlenme
s.put(325,7,'B'); s.put(328,7,'K'); s.put(331,7,'E'); s.put(329,7,'B')
W=336
# Uzatma (2026-10-25): iki kesit araya girer (273. sütunda, GOKYOLU_INS).
# Y1) Lodos ile Poyraz: Evliya'ya göre Hezarfen lodosla uçtu. Arkadan esen
# lodos süzülüşü uzatır, önden esen poyrazda çömel (levels.dart yel).
y1=G(70,22)
for c0,c1 in ((0,4),(13,17),(27,31),(43,47),(59,69)):
    y1.fill(c0,8,c1,9,'#')
y1.put(30,7,'#')                              # poyrazda ardına sığınılan taş
y1.put(46,7,'#')
y1.put(1,7,'p'); y1.put(2,7,'K'); y1.put(3,7,'9'); y1.put(15,7,'F')
y1.put(62,7,'B')
# Y2) Uçurtmalar: aşağıdaki damlardan yükselen çocuk uçurtmaları
# (levels.dart kites); kuştan kuşa değil, uçurtmadan uçurtmaya.
y2=G(64,22)
y2.fill(0,8,4,9,'#'); y2.fill(58,8,63,9,'#')
y2.put(1,7,'p'); y2.put(2,7,'K'); y2.put(3,7,'('); y2.put(60,7,'B')
GOKYOLU_INS=[(273, y1.rows()), (273, y2.rows())]
rows=s.rows()
for at, ins in reversed(GOKYOLU_INS):
    rows=[r[:at]+x+r[at:] for r,x in zip(rows,ins)]
lvl3=rows

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
# Ayna köprüden önceki sağlam zeminin üstünde: gölge köprüsünde ancak
# çömelip ışık saklanarak durulur, ayağa kalkıp aynayı çeviren köprüden
# düşüyordu. Ayna çevrilince ay ışığı köprünün üstünden Gözcü'nün gözüne.
f.put(70,2,'j'); f.put(70,8,'m'); f.put(67,8,'#')     # kristal: sola kaçan ışığı tutar
f.fill(85,10,93,23,'#'); f.put(89,9,'g')
# Asılı kristal: aynanın ışığı bu Gözcü'de durur; ileride, tüylerin
# Gözcülerini kör etmesin.
f.put(92,8,'#')
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
f.put(148,17,'T')                            # köprünün üstünde: çömelerek yürürken alınır
f.fill(159,10,161,23,'#'); f.put(160,9,'g')
f.fill(159,16,161,17,'.')                    # gözcünün altı, kör noktası: geçit
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
f.fill(135+HO,13,135+HO,17,'|')                          # raftan sarkan zincir: tırmanılır
f.put(140+HO,4,'j'); f.put(140+HO,12,'m'); f.put(150+HO,12,'m'); f.put(150+HO,17,'m')
f.put(152+HO,17,'C'); f.put(153+HO,18,'.',force=True)
f.put(146+HO,17,'G'); f.put(138+HO,12,'M'); f.put(143+HO,17,'F')
f.put(158+HO,17,'t')
f.fill(161+HO,3,161+HO,11,'#'); f.fill(161+HO,12,161+HO,17,'H')
f.put(165+HO,17,'B'); f.put(167+HO,17,'E')
for c,r in [(8,16),(32,8),(66,8),(98,7),(126+HO,16)]:
    f.put(c,r,'p')
# Uzatma (2026-10-25): Attâr'ın vadilerinden iki kesit araya girer
# (öncekiler yerinde, sonrası sağa kayar; KAF_INS).
# K1) Hayret Vadisi · Aynalı Göl: görünmeyen basamaklar yalnız yansımada
# (levels.dart lake, mirrorSteps); iki taş ada.
k1=G(70,24)
k1.fill(0,18,5,23,'#'); k1.fill(6,20,61,23,'w')
k1.fill(20,17,22,23,'#'); k1.fill(41,17,43,23,'#')
k1.fill(62,18,69,23,'#')
k1.put(1,17,'p'); k1.put(3,17,'K'); k1.put(4,17,'9'); k1.put(21,16,'F')
k1.put(65,17,'B')
# K2) Otuz Kuş · Kuşlardan Köprü: uçurumun üstünden sürü uçar
# (levels.dart birdBridges).
k2=G(64,24)
k2.fill(0,18,5,23,'#'); k2.fill(58,18,63,23,'#')
k2.put(1,17,'p'); k2.put(2,17,'K'); k2.put(4,17,'('); k2.put(60,17,'B')
k2.put(3,17,'F')                                   # ateşböceği: Gözcü'yü oyala
k2.fill(29,9,32,9,'#'); k2.put(30,8,'g')           # uçurumun ortasında asılı kaya, Gözcü
KAF_INS=[(122, k1.rows()), (197, k2.rows())]
rows=f.rows()
for at, ins in sorted(KAF_INS, reverse=True):
    rows=[r[:at]+x+r[at:] for r,x in zip(rows,ins)]
lvl4=rows

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
# Kolun rafının sağ yüzünde zincir: kolu çekmeden sağa inen (oradaki Umay
# ağacına dokunsa bile) rafa geri tırmanabilsin.
a.fill(250,8,250,16,'|')
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
# 3b) Terazi: Nuh'un eşleri. İki kefenin üstünde geyik gölgesi; ortadaki
# rafta geyik, fil, geyik. Eşler kefelere konunca kefeler hizalanır, kapı
# açılır; fil ağırdır, dengelemez. Sol rafın üstündeki kol teraziyi boşaltır.
n.put(176,25,'K'); n.put(178,22,'5')
n.put(177,25,'#'); n.fill(178,24,178,25,'#'); n.fill(179,23,180,25,'#')
n.put(179,22,'B')
n.put(181,25,'A'); n.put(181,24,'d'); n.fill(181,26,182,27,'.')
n.fill(183,23,188,25,'#')
n.put(184,22,'a'); n.put(186,22,'a'); n.put(188,22,'a')
n.put(189,25,'Y'); n.put(189,24,'d'); n.fill(189,26,190,27,'.')
n.fill(191,23,191,29,'#')
n.fill(192,3,192,18,'#'); n.fill(192,19,192,25,'H')
n.put(193,25,'K')                            # kaçıştan önce kontrol noktası
# 4) Ambar kuyusu: tufan geri döner, yukarı kaç
n.fill(192,0,229,2,'#')
n.put(193,3,'q'); n.put(229,25,'Q')
n.put(195,25,'o'); n.put(197,25,'p')
for i,r in enumerate(range(24,9,-2)):
    # Sıralar ortak sütun paylaşmaz: yoksa 205-206'da her satırda tahta
    # olur, kuyu dümdüz zıplanarak çıkılırdı.
    # Aralarında bir kare boşluk: her satıra yana sıçranır.
    if i % 2 == 0:
        n.fill(199,r,205,r,'=')
    else:
        n.fill(207,r,212,r,'=')
n.fill(218,3,218,11,'S')                     # sallanılan ip
n.fill(224,8,229,8,'=')
n.fill(230,9,299,25,'#')                     # üst güverte (buzula gömülü)
n.fill(230,8,236,8,'-')
n.fill(237,8,299,8,'#')                      # güverte yüzü: nesneler 7. satırda durur
# 5) Üst güverte: buz, Kandilci, sönmüş ışığın yeri
n.put(232,7,'K'); n.put(233,7,'p'); n.put(234,7,'6'); n.put(238,7,'B')
n.put(248,7,'G'); n.fill(244,7,245,7,'~'); n.put(258,7,'I'); n.put(262,7,'G')
n.fill(266,6,268,7,'#'); n.put(267,5,'M')    # sönmüş ışığın kaidesi
n.put(270,7,'7'); n.put(276,7,'K'); n.put(284,7,'B'); n.put(290,7,'E')
n.fill(252,7,256,7,'-')
# Uzatma (2026-10-25): iki ambar araya girer (GEMI_INS; sonrası sağa kayar).
# G1) Delikli Ambar: tabandaki deliklerden su fışkırır (levels.dart leaks);
# sandık deliğin üstüne sürülünce tıkanır; üçü tıkanınca kapı açılır.
a1=G(60,30)
a1.fill(0,0,59,18,'#'); a1.fill(0,26,59,29,'#')
a1.put(1,25,'p'); a1.put(2,25,'K'); a1.put(4,25,'8')
for c in (12,30,46): a1.put(c,25,'C')
a1.put(22,25,'F')
a1.fill(56,19,56,25,'H')
# G2) Yalpalayan Ambar: bölmelerde fıçılar yuvarlanır (levels.dart
# barrels); aralarda sandık yığınları (fıçı tırmanamaz, üstünde beklenir).
a2=G(64,30)
a2.fill(0,0,63,18,'#'); a2.fill(0,26,63,29,'#')
a2.put(1,25,'p'); a2.put(2,25,'K'); a2.put(4,25,'9')
for c in (7,22,37,52): a2.fill(c,23,c+2,25,'#')     # yığınlar (üstü 23)
a2.put(30,25,'F'); a2.put(60,25,'B')
GEMI_INS=[(176, a1.rows()), (193, a2.rows())]
rows=n.rows()
for at, ins in sorted(GEMI_INS, reverse=True):
    rows=[r[:at]+x+r[at:] for r,x in zip(rows,ins)]
lvl6=rows

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
m.fill(176,F-5,178,F-1,'#'); m.put(177,F-6,'g')
m.fill(172,F-2,173,F-1,'#'); m.fill(174,F-3,175,F-1,'#'); m.put(175,F-4,':')   # kartalın kaidesi: iki basamak
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
# 1) Tören yolu: şafakta Kandilciler, dikili taşlar, düşmüş başlar. Deprem
# yarıkları (üstünde çöken taşlar), sarkan kayanın altında bekçi ve
# depremde düşen taşlar, yolu kesen oturan tanrının omzunda Gözcü.
d.put(2,F-1,'P'); d.put(3,F-1,'p'); d.put(4,F-1,'1'); d.put(6,F-1,'B'); d.put(8,F-1,'F')
d.fill(11,F,15,25,'.'); d.put(13,F,'O')          # 1. yarık
d.put(17,F-1,';'); d.put(19,F-1,'I')
d.fill(21,F-7,29,F-6,'#')                                    # sarkan kaya
for c in (22,25,28):
    d.put(c,F-5,'%')
d.put(26,F-1,'G'); d.put(28,F-9,'N')
d.put(30,F-1,'2')
d.fill(32,F,35,25,'.'); d.put(33,F,'O')          # 2. yarık
d.put(37,F-1,';'); d.put(38,F-1,'I')
x=41                                                         # yolu kesen tanrı
d.put(x,F-10,'?'); d.fill(x,F-4,x+5,F-1,'#'); d.fill(x-1,F-2,x-1,F-1,'#'); d.fill(x+6,F-3,x+6,F-1,'#')
d.put(x+5,F-6,'#'); d.fill(x+1,F-8,x+4,F-8,'#'); d.put(x+2,F-9,'g')
d.put(48,F-1,'K'); d.put(49,F-1,'B'); d.put(50,F-1,'G')
# 2) Terasın kapısı: kol bir tanrının omzunda
d.put(51,F-1,'p'); d.put(52,F-1,'3')
x=55
d.put(x,F-10,'?'); d.fill(x,F-4,x+5,F-1,'#'); d.fill(x-1,F-2,x-1,F-1,'#'); d.fill(x+6,F-3,x+6,F-1,'#')
d.put(x+5,F-6,'#'); d.fill(x+1,F-8,x+4,F-8,'#'); d.put(x+2,F-9,'L'); d.put(x+3,F-9,'M')
d.fill(66,2,66,F-7,'#'); d.fill(66,F-6,66,F-1,'H')
# 3) Doğu Terası: taş dev Nemrud. Kulak hizasında raflar, ateşböcekleri
d.put(68,F-1,'K'); d.put(69,F-1,'p'); d.put(71,F-1,'4'); d.put(73,F-1,'B')
# Sarmaşıklar rafların dış yüzünde, raf hizasından yere iner: tırmanan
# rafın üstüne çıkar (rafın altına sarkınca kaya başını kesiyordu).
d.fill(76,F-5,79,F-5,'#'); d.fill(75,F-5,75,F-1,'|')     # sol raf ve sarmaşık
d.fill(100,F-5,103,F-5,'#'); d.fill(104,F-5,104,F-1,'|')  # sağ raf ve sarmaşık
d.put(74,F-1,'5')
d.put(78,F-6,'F'); d.put(101,F-6,'F'); d.put(112,F-1,'F')
d.put(70,F-1,'F')       # sol yerde: devin bu yanında ikinci sürü yeri (raf dibindeyken de dolsun)
d.put(82,F-1,'`')
d.fill(125,2,125,F-7,'#'); d.fill(125,F-6,125,F-1,'H')
# 4) Güneşin doğduğu yer: ayin, Kandilciler, ışık
d.put(127,F-1,'K'); d.put(128,F-1,'p'); d.put(130,F-1,'B')
d.fill(134,F-2,137,F-1,'#'); d.fill(140,F-4,143,F-1,'#'); d.fill(146,F-6,212-1,F-1,'#')
d.fill(144,F-2,145,F-1,'#')                 # basamak arası çukur sığ: düşen çıkar
d.put(150,F-7,'G'); d.fill(154,F-7,155,F-7,'~'); d.put(160,F-7,';'); d.put(161,F-7,'I')
d.put(166,F-7,'G'); d.fill(170,F-7,171,F-7,'~'); d.put(176,F-7,'G'); d.put(172,F-15,'N')
d.put(180,F-7,'6'); d.put(184,F-7,'M'); d.put(190,F-7,'K'); d.put(195,F-7,'B'); d.put(205,F-7,'E')
d.put(188,F-7,'?')
# Uzatma (2026-10-25): devin kapısından sonra iki yeni kesit araya girer
# (devin alanı yerinde kalır; sonrası sağa kayar, GUNDOGUMU_INS).
def statue(g,x):
    g.put(x,F-10,'?'); g.fill(x,F-4,x+5,F-1,'#'); g.fill(x-1,F-2,x-1,F-1,'#')
    g.fill(x+6,F-3,x+6,F-1,'#'); g.put(x+5,F-6,'#'); g.fill(x+1,F-8,x+4,F-8,'#')
# G1) Şafağın Gölgeleri: güneş doğudan doğar, oturan tanrıların uzun
# gölgeleri batıya düşer; Kandilciler yalnız gölgede yürür (levels.dart
# dawn). Güneş yükseldikçe gölgeler kısalır: güneşte bekle, gölgeyi
# Kandilci uzaktayken geç ya da tanrının omzundan aş.
g1=G(66,H)
g1.fill(0,F,65,H-1,'#')
g1.put(1,F-1,'p'); g1.put(2,F-1,'K'); g1.put(4,F-1,'7'); g1.put(6,F-1,'F')
for x in (12,32,52): statue(g1,x)
for x in (10,30,50): g1.put(x,F-1,'G')    # tanrının dibinde: en kısa gölgede de
g1.put(62,F-1,'B')
# G2) Düşmüş Başlar: depremle sarsılan, yuvarlanmış dev başların üstünden;
# yarıklarda çöken taşlar, kartal heykelinin kemerinden ip, kartalın
# tepesinde kol.
g2=G(72,H)
def g2r(c0,c1,top=F): g2.fill(c0,top,c1,H-1,'#')
g2r(0,7); g2.put(1,F-1,'p'); g2.put(2,F-1,'K'); g2.put(4,F-1,'8')
g2.put(10,F,'O')                                   # 1. yarık, ortada çöken taş
g2r(13,21,F-3); g2.fill(14,F-4,20,F-4,'#'); g2.put(17,F-5,';')   # düşmüş baş
g2.fill(12,F-1,12,F-1,'#')                         # başa basamak
g2r(22,33); g2.fill(23,F-8,30,F-7,'#')             # sarkan kaya
for c in (24,27,30): g2.put(c,F-6,'%')
g2.put(32,F-1,'F')
g2.fill(35,F-11,41,F-10,'#'); g2.fill(38,F-9,38,F-1,'S')   # kartalın kemeri, ip
g2r(44,71)
g2.fill(46,F-2,47,F-1,'#'); g2.fill(48,F-4,50,F-1,'#')    # kartal heykelinin basamakları
g2.fill(51,F-5,51,F-1,'#'); g2.fill(52,F-6,54,F-1,'#')
g2.fill(55,F-4,56,F-1,'#'); g2.fill(57,F-2,57,F-1,'#')    # sağdan inen geri çıkabilsin
g2.put(53,F-9,':'); g2.put(54,F-7,'L')
g2.put(59,F-1,';'); g2.put(61,F-1,'I')
g2.fill(66,2,66,F-7,'#'); g2.fill(66,F-6,66,F-1,'H')
g2.put(68,F-1,'M')
GUNDOGUMU_INS=[(126, g1.rows()), (126, g2.rows())]
rows=d.rows()
for at, ins in reversed(GUNDOGUMU_INS):
    rows=[r[:at]+x+r[at:] for r,x in zip(rows,ins)]
lvl8=rows

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
# Buzun üstünde alçak bir sal: buzdan sıçranır (eskiden 5 kare
# yukarıdaydı, ulaşılamıyordu).
k9.put(123,F-1,'b'); k9.put(160,F-3,'F'); k9.fill(158,F-2,162,F-2,'=')
k9.fill(191,F,199,25,'#'); k9.put(192,F-1,'K'); k9.put(194,F-1,'B')
# 4) Terk edilmiş han: Kandilciler, çan, kapı
k9.fill(200,F,262,25,'#'); k9.fill(203,F-9,252,F-8,'#')     # hanın çatısı
k9.fill(203,F-7,203,F-2,'#'); k9.put(201,F-1,'p'); k9.put(205,F-1,'6')
k9.put(212,F-1,'G'); k9.put(216,F-1,'I'); k9.put(222,F-1,'I'); k9.put(228,F-1,'G')
# Çan çatıdan zincirle sarkar: altından koşan çalar, zincire tırmanan da
# bilerek çalabilir (eskiden tavanda, yerden 6,5 kare yukarıdaydı; hiç
# çalmıyordu).
k9.put(234,F-1,'~'); k9.put(235,F-1,'~'); k9.fill(219,F-7,219,F-5,'|'); k9.put(219,F-4,'c')
k9.put(240,F-1,'M'); k9.fill(244,F-4,246,F-1,'#'); k9.put(245,F-5,'L')
k9.fill(242,F-2,243,F-1,'#')                     # kolun kayasına basamak
k9.fill(252,F-7,252,F-1,'H'); k9.put(258,F-1,'K'); k9.put(260,F-1,'B')
# 5) Ejder'in eteği: rüzgârlı tırmanış
k9.fill(263,F-2,267,25,'#'); k9.fill(268,F-4,272,25,'#'); k9.put(269,F-5,'p'); k9.put(270,F-5,'7')
# Karşıdan esen rüzgâr süzülmeyi kısar: boşluklar en çok iki kare.
k9.fill(275,F-6,278,25,'#'); k9.put(280,F-7,'O'); k9.put(283,F-8,'O')
k9.fill(286,F-9,296,25,'#'); k9.put(292,F-10,'K'); k9.fill(293,2,296,3,'#'); k9.put(294,4,'%')
k9.fill(297,F-11,302,25,'#'); k9.fill(303,F-13,319,25,'#')
k9.put(306,F-14,'8'); k9.put(310,F-14,'B'); k9.put(315,F-14,'E')
# Kolun rafının sağ yüzünde zincir: kapı ile raf arasında kalınmasın.
k9.fill(247,16,247,19,'|')
lvl9=k9.rows()

# ------------------------------------------------------------ kayak pisti
# Kayak fiziği (lib/game/player.dart _updateSki ile aynı sabitler).
SKI_G = 1500.0
SKI_JUMP = 560.0
SKI_VMAX = 640.0      # olağan en yüksek hız
SKI_KUT = 800.0       # takladan sonraki "kut" hızı
TILE = 32.0

class Ski:
    """Kayak yamacı: segmentlerle yükseklik dizisi kurar, işaretleri koyar,
    atlayışları fizikle sınar."""
    def __init__(s, start_row):
        s.y=[]; s.row=start_row; s.marks=[]; s.magnets=[]; s.gaps=[]; s.decor=[]
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
    def gap(s,n,drop_after,kind='normal'):
        s.gaps.append((s.x, s.x+n, kind))
        s.y += [-1]*n
        s.row += drop_after
    def magnet(s,n,rise):
        a=s.x
        s.kicker(n,rise)
        s.magnets.append((a,s.x-1))
    def mark(s,ch,dx=0,up=1):
        c=s.x+dx
        s.marks.append((c,ch,up))
    def deco(s,kind,dx=0):
        s.decor.append((kind,s.x+dx))
    def rail_over_gap(s,n,drop_after):
        # Kütük tam satır hizasında: önünde o satırda kısa bir düzlük, kar
        # kütüğün üstüyle aynı yükseklikte (kayakçı kayarak çıkar).
        r=int(math.floor(s.row+0.5))
        s.y += [(s.row+r)/2, r, r]; s.row=r
        c=s.x
        s.marks.append((c-1,'=',('rail',n+2,r)))
        s.gap(n,drop_after,'rail')
    # Alto'daki gibi: her uçurum olağan hızla (320-640), kenara 10-120
    # piksel kala basılan her zıplamayla aşılır. Takla yalnız ödüldür.
    GAP_V=(320,400,500,640)
    GAP_J=(10,40,80,120)
    def _gap_ok(s,gap,vs=None,js=None):
        g0,g1,_=gap
        edge=(g0-0.5)*TILE; far=(g1+0.5)*TILE
        for v in vs or s.GAP_V:
            for j in js or s.GAP_J:
                jx=edge-j
                if s.at(jx) is None: continue
                lx,diff,wall=s.fly(jx,v,True)
                # Erken zıplayan rampaya iner: oradan yeniden zıplar ya da
                # kenardan kendiliğinden uçar; ikisinden biri yeterse güvenli.
                if lx is not None and not wall and lx<edge:
                    if lx<edge-30: continue
                    l2,_,w2=s.fly(edge-1,v,False)
                    if l2 is not None and not w2 and l2>=far+8: continue
                if lx is None or wall or lx<far+8: return False
        return True
    def _fit(s,build,sizes,name):
        """build(n) ile kur, sınavı geçen ilk ölçüyü bırak."""
        x0=s.x; r0=s.row; g0=len(s.gaps)
        for n in sizes:
            del s.y[x0:]; s.row=r0; del s.gaps[g0:]
            build(n)
            # Sınav için yamaç geçici olarak uzatılır (pistin devamı henüz
            # kurulmadı; uzun uçuş oraya iner). Bütün pist check()'te
            # yeniden sınanır.
            end=len(s.y); last=s.y[-1]; d=s.y[-1]-s.y[-2] if s.y[-2]>=0 else 0.3
            s.y += [last+d*(k+1) for k in range(40)]
            ok=all(s._gap_ok(g) for g in s.gaps[g0:] if g[2]!='rail')
            del s.y[end:]
            if ok:
                return n
        raise AssertionError(f'{name} {x0}: uygun ölçü yok')
    def jump(s,kick_n,kick_rise,gap_n,land_drop,land_n):
        """Rampa, uçurum ve aşağı eğimli iniş yamacı."""
        # Rampadan önce kısa düzlük: yaklaşırken çukura düşülmez, zıplama
        # zamanı bağışlayıcı olur.
        def b(n):
            s.flat(3)
            s.kicker(kick_n,kick_rise)
            s.gap(n,land_drop*0.6)
            s.slope(land_n,land_drop*0.4)
        s._fit(b,range(gap_n,1,-1),'atlayış')
    def flip_ramp(s,land_n=26):
        """Takla rampası: dik bir yamaca uzun bir uçuş; zıplayan her hızda bir
        takla sığar (1,02 sn dönüş + pay). Derinlik bunu sağlayana dek artar."""
        x0=s.x; r0=s.row; g0=len(s.gaps)
        for dd in range(8,40):
            del s.y[x0:]; s.row=r0; del s.gaps[g0:]
            s.flat(3); s.kicker(5,2.5)
            s.gap(5,dd,'flip')
            s.slope(land_n,9)
            g=s.gaps[-1]; edge=(g[0]-0.5)*TILE; far=(g[1]+0.5)*TILE
            # Her olağan hızda aşılır; hızlı gelende bir takla sığar
            # (dönüş ~0,83 sn). Sınav için yamaç geçici uzatılır.
            end=len(s.y); d=s.y[-1]-s.y[-2]
            s.y += [s.y[-1]+d*(k+1) for k in range(40)]
            good=s._gap_ok(g)
            for v in (420,500,580,640):
                for j in (10,40,80):
                    lx,diff,wall=s.fly(edge-j,v,True)
                    if (lx is None or wall or lx<far+8 or s.last_t<1.0):
                        good=False
            del s.y[end:]
            if good:
                return
        raise AssertionError(f'takla rampası {x0} kurulamadı')
    def takla_gap(s,n=12,drop=7,land_n=24):
        """Büyük uçurum: rampadan uçulur; olağan hızla aşılır, sığabilen en
        geniş ölçü seçilir (takla buraya hız katar ama şart değil)."""
        def b(nn):
            s.flat(2); s.kicker(4,1.6)
            s.gap(nn,drop*0.8,'takla')
            s.slope(land_n,drop*0.4)
        s._fit(b,range(n,1,-1),'büyük uçurum')
    def drop_off(s,gap_n,drop,land_n,land_drop):
        """Rampasız uçurum: kenardan düşülür, dik bir yamaca inilir."""
        def b(n):
            s.flat(3)
            s.gap(n,drop)
            s.slope(land_n,land_drop)
        s._fit(b,range(gap_n,1,-1),'düşüş')
    def rollers(s,k,n,drop,rise):
        """Tümsek sırası: yumuşak dalgalar (kosinüs), aralarında sırtlar;
        hızlı gelen sırtlardan hafifçe havalanır."""
        for _ in range(k):
            L=n+max(3,n//2)
            net=drop-rise
            A=(drop+rise)/2
            for i in range(L):
                t=(i+1)/L
                s.y.append(s.row+net*t+A*(1-math.cos(2*math.pi*t))/2)
            s.row+=net

    # ---------------------------------------------- yüzey (Dart ile aynı)
    def at(s,x):
        f=x/TILE-0.5; i=math.floor(f); r=s.y
        if i<0: return None if r[0]<0 else r[0]*TILE
        if i+1>=len(r): return None
        a=r[i]; b=r[i+1]
        if a<0 or b<0: return None
        t=f-i
        p0=r[i-1] if i>0 and r[i-1]>=0 else 2*a-b
        p3=r[i+2] if i+2<len(r) and r[i+2]>=0 else 2*b-a
        v=0.5*(2*a+(-p0+b)*t+(2*p0-5*a+4*b-p3)*t*t+(-p0+3*a-3*b+p3)*t*t*t)
        return v*TILE
    def slope_at(s,x):
        y0=s.at(x-6); y1=s.at(x+6); y=s.at(x)
        if y0 is not None and y1 is not None: return math.atan2(y1-y0,12)
        if y is None: return 0.0
        if y0 is not None: return math.atan2(y-y0,6)
        if y1 is not None: return math.atan2(y1-y,6)
        return 0.0

    def fly(s,x,v,jump):
        """x'ten v hızla (zıplayarak ya da kenardan) uçuş: (iniş x'i, iniş
        açı farkı, karşı duvara çarptı mı)."""
        th=s.slope_at(x); y=s.at(x)
        vx=v*math.cos(th); vy=v*math.sin(th)
        if jump:
            vx+=math.sin(th)*60
            vy=(vy if vy<0 else vy*0.35)-SKI_JUMP
        dt=1/240; t=0
        while t<4:
            vy=min(vy+SKI_G*dt,900); x+=vx*dt; y+=vy*dt; t+=dt
            g=s.at(x)
            if g is not None and y>=g:
                prev=s.at(x-vx*dt)
                wall = prev is None and y-g>14
                diff=abs(math.atan2(vy,vx)*0.5-s.slope_at(x))
                s.last_t=t
                return x,diff,wall
        return None,0,False

    def check(s,name):
        """Atlayışları sınar; iniş bölgelerine ve rampaların önüne kaya
        koymaz (yakındaki uygun yere taşır)."""
        s.smooth()
        zones=[]
        for g0,g1,kind in s.gaps:
            if kind=='rail': continue
            edge=(g0-0.5)*TILE
            far=(g1+0.5)*TILE
            assert s._gap_ok((g0,g1,kind)), f'{name}: uçurum {g0} olağan hızla aşılamıyor'
            for v in range(400,661,20):
                for jx in [edge-1]+[edge-j for j in s.GAP_J]:
                    jump = jx<edge-1
                    if s.at(jx) is None: continue
                    lx,diff,wall=s.fly(jx,v,jump)
                    ok = lx is not None and lx>=far+8 and not wall
                    if ok:
                        zones.append((lx-24, lx+v*0.45))
        s.zones=zones
        out=[]
        s.rocks=[]
        for c,ch,up in s.marks:
            if ch=='%':
                for d in [0]+[k*sg for k in range(1,30) for sg in (1,-1)]:
                    if s.ok_rock(c+d):
                        c=c+d; s.rocks.append(c); break
                else:
                    print(f'{name}: kaya {c} kaldırıldı (yer yok)')
                    continue
            out.append((c,ch,up))
        s.marks=out

    def smooth(s,passes=3):
        """Yamacı yumuşatır (kırık köşeler kalmasın); uçurum kenarlarının
        3 karelik dudağına ve rampalara dokunmaz."""
        W=len(s.y)
        keep=[False]*W
        for g0,g1,kind in s.gaps:
            for c in range(max(0,g0-7),min(W,g1+3)): keep[c]=True
        for c,ch,up in s.marks:
            if isinstance(up,tuple):
                for k in range(-3,up[1]+3):
                    if 0<=c+k<W: keep[c+k]=True
        for _ in range(passes):
            y=s.y[:]
            for c in range(2,W-2):
                if keep[c] or min(y[c-2:c+3])<0: continue
                s.y[c]=(y[c-2]+2*y[c-1]+3*y[c]+2*y[c+1]+y[c+2])/9

    def ok_rock(s,c):
        """Kaya: iniş yerinde, uçurumun ardında, sırtın hemen arkasında
        olmaz; önünde uçurum olmaz; her olağan hızda ona 30-120 piksel kala
        zıplayan aşar (rock_clear)."""
        W=len(s.y)
        if not (2<=c<W-8) or s.y[c]<0: return False
        # Kayalar arası en az 24 kare: birinden zıplayan öbürüne inmesin.
        if any(abs(c-r)<24 for r in getattr(s,'rocks',[])): return False
        x=(c+0.5)*TILE
        for a,b in s.zones:
            if a-30<=x<=b+20: return False
        for g in range(max(1,c-14),c+1):
            if s.y[g]>=0 and s.y[g-1]<0: return False
        # Önde 22 kare uçurum yok: kayadan zıplayan bir rampaya ya da
        # uçurumun ağzına inmesin.
        for c2 in range(max(1,c-12),min(W,c+22)):
            if s.y[c2]<0: return False
        # Sırttan en az 12 kare sonra: hızlı gelen sırttan havalanıp havada
        # kayaya çarpmasın.
        for g in range(max(2,c-12),c+1):
            if (s.y[g-1]-s.y[g-2])-(s.y[g]-s.y[g-1])>0.2: return False
        return s.rock_clear(c)

    def rock_clear(s,c):
        """Kayaya 30-120 piksel kala, her olağan hızda zıplayan onun üstünden
        aşar ve güvenle iner (Dart: SkiRock ve kayanın sert çekirdeği)."""
        rx=(c+0.5)*TILE; gy=s.y[c]*TILE
        core_l=rx-7; core_r=rx+7; core_top=gy-14
        for v in (320,420,520,640):
            for d in (30,60,90,120):
                x=rx-14-d-7
                y=s.at(x)
                if y is None: return False
                th=s.slope_at(x)
                vx=v*math.cos(th)+math.sin(th)*60
                vy=v*math.sin(th); vy=(vy if vy<0 else vy*0.35)-SKI_JUMP
                dt=1/240; t=0; landed=False
                while t<4:
                    vy=min(vy+SKI_G*dt,900); x+=vx*dt; y+=vy*dt; t+=dt
                    if x+5>core_l and x-5<core_r and y-2>core_top:
                        return False
                    g=s.at(x)
                    # Uçuş yolu uçurumun üstünden geçmez (kayadan zıplayan
                    # uçuruma inmesin).
                    if g is None: return False
                    if y>=g:
                        if x<core_r+8: return False
                        landed=True; break
                if not landed: return False
        return True

    def build(s):
        """İşaretler (sütun, satır, harf) ve yükseklikler."""
        W=len(s.y)
        cells={}
        for c,ch,up in s.marks:
            if isinstance(up,tuple):
                _,n,r=up
                for k in range(n):
                    cells[(c+k,r-1)]='='
                continue
            base=s.y[c] if 0<=c<W and s.y[c]>=0 else s.row
            r=int(math.floor(base))-up
            cells.setdefault((c,r),ch)
        return sorted((c,r,ch) for (c,r),ch in cells.items()), [round(v,2) for v in s.y]

import math
# ------------------------------------------------------------ X · PALANDÖKEN
# Gün batımında başlar, geceden geçer, şafakta Erzurum'a iner. Uzun akışlı
# inişler, ormanlar, donmuş göl, rampalar ve takla uçurumları; engeller
# seyrek ama dikkat ister. Kayalar inişlerin hemen ardında olmaz.
sk=Ski(8)
# 1) Çoban Kulübesi
sk.deco('hut',2); sk.flat(4); sk.mark('P',0); sk.mark('p',1); sk.mark('1',2); sk.flat(8); sk.mark('B',0)
sk.deco('forest',0); sk.slope(44,8,0.8,15)
sk.mark('K',-6); sk.mark('2',-2)
sk.jump(3,1,4,6,18)
sk.slope(30,7,0.6,12); sk.deco('deer',-10)
sk.rollers(3,9,3,1.4); sk.mark('F',-6,4)
sk.slope(26,7); sk.mark('%',-8)
sk.deco('lake',0); sk.flat(14); sk.deco('lake_end',0)
sk.slope(24,7,0.5,10)
# 2) Ejder'in Sırtı
sk.mark('p'); sk.mark('3',3); sk.mark('K',2)
sk.deco('forest',0); sk.slope(70,18,1.4,14); sk.mark('M',-36,5); sk.mark('%',-14)
sk.jump(4,2,7,9,22); sk.deco('birds',-12)
sk.slope(30,8,0.7,12); sk.mark('%',-8)
sk.slope(10,3); sk.rail_over_gap(7,2); sk.slope(20,6)
sk.mark('K',-4); sk.rollers(4,10,3.4,1.5); sk.mark('F',-8,4)
sk.deco('arch',8); sk.slope(36,10,0.4,12)
sk.drop_off(4,5,18,6)
sk.slope(28,8,0.8,12); sk.mark('%',-10)
# Orman geçidi: çamların arasından kıvrılan uzun, yumuşak iniş; geyikler
sk.deco('forest',0); sk.slope(60,14,1.2,16); sk.deco('deer',-30)
sk.jump(3,1.5,5,8,20)
sk.rollers(3,12,3.6,1.4); sk.deco('birds',-10)
sk.slope(30,8,0.5,12); sk.mark('%',-10)
# 3) Kandil Balonları: gece iner
sk.mark('p',1); sk.mark('4',3); sk.mark('K',0)
sk.deco('forest',0)
sk.slope(90,22,1.0,15); sk.mark('N',-20,7); sk.mark('N',-46,7); sk.mark('N',-72,7)
sk.mark('%',-34); sk.mark('B',-2)
sk.rollers(4,10,3.6,1.6); sk.mark('F',-6,4); sk.mark('F',-28,4)
# Kayıt noktası takla rampasından 16 kare önce: yeniden doğan hızlanabilsin.
sk.mark('K',0); sk.slope(16,5)
sk.flip_ramp(); sk.slope(6,2); sk.takla_gap(); sk.deco('shooting',0)
sk.slope(30,8,0.9,11); sk.mark('%',-9)
sk.jump(3,1.5,6,8,20)
sk.slope(24,7,0.6,10)
# 4) Manyetik Tepe: ayın altında kar yokuş yukarı akar
sk.mark('p',2); sk.mark('5',3)
sk.slope(12,3); sk.magnet(28,6); sk.mark('F',-6,3); sk.slope(4,1)
sk.mark('6',0); sk.mark('K',2)
sk.deco('forest',0); sk.slope(40,12,0.6,14)
sk.jump(5,2.5,8,12,26); sk.deco('deer',-8)
sk.slope(30,8,0.8,12); sk.mark('%',-10)
sk.deco('lake',0); sk.flat(12); sk.deco('lake_end',0)
sk.slope(20,6)
# Donmuş şelale: buz sarkıtlı kayalıktan düşüş, altında uzun koşu
sk.deco('waterfall',2); sk.drop_off(5,10,22,8)
sk.slope(40,11,0.9,13); sk.mark('%',-14)
sk.jump(4,2,7,10,22)
sk.slope(24,7,0.6,10)
# 5) Ejder'in Sıçrayışı: en büyük atlayışlar
sk.mark('p',1); sk.mark('K',0); sk.mark('7',3)
sk.slope(30,9,0.5,10)
sk.flip_ramp(); sk.slope(6,2); sk.takla_gap(14,9,26)
sk.slope(24,7,0.6,10); sk.mark('%',-8)
sk.slope(10,3); sk.drop_off(6,9,20,8)
sk.mark('K',2); sk.slope(20,6)
for i in range(3):
    sk.slope(20,6,0.4,10); sk.mark('%',-9)
sk.slope(10,3); sk.rail_over_gap(5,2); sk.slope(10,3); sk.rail_over_gap(6,3); sk.slope(16,5); sk.mark('M',-6,1)
# 6) Şafak
sk.mark('K',2); sk.deco('forest',0); sk.slope(30,8,0.8,10)
sk.rollers(5,10,4,1.8); sk.mark('F',-8,4); sk.mark('F',-30,4)
sk.slope(16,5); sk.jump(4,2,8,11,24); sk.deco('birds',-6)
sk.slope(30,8,0.9,12); sk.mark('%',-10)
sk.flip_ramp(); sk.slope(6,2); sk.takla_gap(12,8,24)
sk.slope(30,8,0.6,12); sk.mark('%',-10)
sk.deco('arch',10); sk.slope(40,11,0.8,12)
sk.slope(10,3); sk.rail_over_gap(6,2); sk.slope(10,3); sk.rail_over_gap(6,2); sk.slope(14,4)
sk.rollers(4,11,3.8,1.6)
sk.slope(20,6); sk.mark('%',-8)
# 7) Erzurum'a İniş
sk.mark('p'); sk.mark('8',3); sk.mark('K',4)
sk.deco('village',40); sk.slope(90,20,1.2,14); sk.mark('F',-30,4); sk.mark('F',-60,4)
sk.jump(3,1,5,6,18)
sk.slope(30,6,0.5,12)
sk.flat(16); sk.mark('B',-6); sk.mark('E',-3)
sk.check('Palandöken')
pal_marks, pal_surface = sk.build()
lvl10 = ['.']
PAL_MAGNET = sk.magnets
PAL_DECOR = sk.decor

# ------------------------------------------------------------ XI · ÇIĞ
# Arkadan çığ: fırtınalı bir alacakaranlıkta uzun, dik bir kaçış. Sonunda
# bulutlar aralanır, şafak söker.
ck=Ski(8)
# 1) Ejder Uyanıyor
ck.flat(4); ck.mark('P',1); ck.mark('p',2); ck.mark('1',3); ck.flat(6); ck.mark('B',0); ck.mark('z',2)
ck.deco('forest',0); ck.slope(50,13,0.8,12); ck.mark('2',-16)
ck.jump(3,1,5,7,18); ck.mark('K',-2); ck.mark('F',-8,5)
ck.slope(30,8,0.6,10); ck.mark('%',-8)
ck.rollers(3,10,3.5,1.5)
ck.slope(20,6); ck.mark('%',-8)
# 2) Beyaz Nefes: uzun, hızlı iniş
ck.mark('p'); ck.mark('3',2)
ck.slope(70,20,1.3,12); ck.mark('M',-34,5); ck.mark('%',-16)
ck.rail_over_gap(6,3); ck.slope(18,5); ck.mark('K',-2); ck.mark('B',1)
ck.slope(24,7,0.6,9); ck.mark('%',-8)
ck.flip_ramp(); ck.slope(6,2); ck.takla_gap(); ck.deco('caravan',10)
ck.slope(30,8,0.6,10)
ck.deco('forest',0); ck.slope(50,14,1.0,12); ck.mark('%',-20)
ck.jump(3,1.5,6,9,20)
ck.rollers(3,10,3.6,1.5)
# 3) Kırık Sırt
ck.mark('p',2); ck.mark('4',3)
for i in range(4):
    ck.slope(14,4); ck.jump(2,1,4,7,16); ck.slope(18,5); ck.mark('%',-6)
ck.slope(16,4,0.6,8); ck.mark('K',-2)
ck.drop_off(5,8,18,7)
ck.slope(28,8,0.8,10); ck.mark('%',-8)
ck.deco('arch',8); ck.slope(36,10,0.6,12)
ck.rail_over_gap(6,3); ck.slope(16,5)
ck.flip_ramp(); ck.slope(6,2); ck.takla_gap()
ck.slope(26,7,0.6,10); ck.mark('%',-8)
ck.rollers(4,10,3.6,1.6)
ck.slope(20,6); ck.mark('%',-8)
# 4) Son Atlayış
ck.mark('p',1); ck.mark('5',2); ck.mark('K',0); ck.slope(16,5)
ck.flip_ramp(); ck.slope(6,2); ck.takla_gap(14,10,26)
ck.mark('F',-18,8); ck.mark('M',-6,1)
ck.rollers(3,10,4,1.6)
ck.jump(4,2,8,10,22)
ck.slope(60,16,1.0,13); ck.mark('%',-24); ck.mark('Z',-2)
# 5) Sığınak
ck.flat(16); ck.mark('p',-14); ck.mark('6',-12); ck.mark('K',-10); ck.mark('B',-6); ck.mark('E',-3)
ck.check('Çığ')
cig_marks, cig_surface = ck.build()
lvl11 = ['.']
CIG_DECOR = ck.decor

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
pb.fill(9,21,9,25,'|'); pb.fill(19,19,19,25,'|')     # evlerin oyma tutamakları: damlara tırmanılır
pb.put(17,25,'2'); pb.put(28,25,'F'); pb.put(32,25,'K'); pb.put(35,25,'M')
# 2) Peri bacaları: tutamaklarla tırmanış, peri halkalarıyla yükseliş
pb.fill(44,26,108,29,'#'); pb.put(45,25,'p'); pb.put(46,25,'3')
for x,top,ring in [(48,22,True),(54,19,False),(60,16,True),(67,13,False),(74,15,True),(81,10,False),(88,7,False),(95,12,True),(102,17,False)]:
    chimney(pb,x,top,ring)
pb.put(88,6,'M'); pb.put(81,9,'k'); pb.put(60,15,'F') if False else None
pb.put(72,25,'4'); pb.put(92,25,'F'); pb.put(105,25,'K'); pb.put(107,25,'B')
# 3) Güvercinlik vadisi: iki ipli geçiş (Ağrı'da denenmiş düzen), ortada güvercinlikli ada
pb.fill(108,18,108,25,'|')                  # çukurdan çıkış sarmaşığı
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
pb.put(210+PO,25,'G'); pb.put(234+PO,25,'G'); pb.put(222+PO,23,'M')
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
    # Dinlenme oyukları kayanın içinde (eskiden PO unutulmuştu: oyuk
    # yerine sarmaşık üç yerden kesiliyordu).
    pb.fill(338+PO,r-1,341+PO,r,'.')
pb.fill(338+PO,3,372+PO,3,'#')
pb.put(345+PO,2,'9'); pb.put(352+PO,2,'K'); pb.put(360+PO,2,'B'); pb.put(366+PO,2,'E')
pb.fill(373+PO,3,W-1,25,'#')                # çıkışın ötesi kaya: dibe düşülmez
lvl12=pb.rows()

# ------------------------------------------------------------ XIII · DERİNKUYU
W,H=362,48
dk=G(W,H,fill='#')
def carve(c0,r0,c1,r1): dk.fill(c0,r0,c1,r1,'.')
# 1) Mahzen
carve(1,10,22,15); dk.put(2,15,'P'); dk.put(3,15,'p'); dk.put(5,15,'1'); dk.put(7,15,'B'); dk.put(12,15,'F')
# 2) Ahırlar ve şarap evi: alçak geçit, Kandilciler, sürgü taşı
carve(22,12,94,15)
carve(30,9,45,11); dk.fill(36,9,36,14,'#');   # alçak kemer (tek kare): Sâye geçer, Kandilci geçemez
dk.put(34,15,'I'); dk.put(40,15,'K'); dk.put(42,15,'2')
dk.put(50,15,'G'); carve(44,16,44,16); carve(44,17,57,17); carve(57,16,57,16)   # alçak geçit
dk.put(52,17,'3'); dk.put(48,17,'M')
carve(60,10,74,11); dk.put(66,15,'I'); dk.put(80,15,'G'); dk.put(70,15,'F')
dk.put(86,15,'@'); dk.put(84,15,'K'); dk.put(85,15,'B')
carve(90,16,94,23); carve(80,17,94,23)          # aşağı kat (üst katın altına uzanır)
# Aşağı kat: şapel, karanlık; yüksek kapıya sürgü taşıyla çıkılır
carve(95,17,107,23); carve(98,14,104,16); dk.put(101,23,'p'); dk.put(99,23,'K'); dk.put(103,23,'4')
dk.put(105,23,'I')
# Şapelin tavanından sızan su: kanatlar ıslanır, üstünden süzülüp yüksek
# rafa geçilmez (sürgü taşıyla çıkılır).
dk.put(80,12,'<'); dk.put(107,22,'>')
# Yüksek raf şapelin tabanından 4 kare yukarıda: tutunarak çıkılmaz, sürgü
# taşı şapele itilip basamak yapılır.
carve(108,17,150,19); dk.put(109,19,'B'); dk.put(116,19,'G'); dk.put(124,19,'~'); dk.put(125,19,'~')
dk.put(128,17,'x'); dk.put(148,19,'X'); dk.put(132,19,'F'); dk.put(142,19,'F'); dk.put(138,18,'e')
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
# Dergâhın damı: minareden süzülüp buraya inen geri dönebilsin (yoksa
# iki yanı yüksek duvar, sıkışılır).
kn.fill(332,11,332,25,'|')
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

# ------------------------------------------------------------ XIV · ERLİK'İN KATI (Ötüken)
# Yerin altı: ışık yolu siler, karanlık yol açar. `b` Körmös, `a` kut kafesi,
# `W` Çalkuyruk, `z`/`Z` Çalkuyruk'a binince yükselen karanlık.
W,H=300,48
er=G(W,H,fill='#')
def ec(c0,r0,c1,r1): er.fill(c0,r0,c1,r1,'.')
F0=30                                   # ana zemin: 30. satırda durulur
# A) Kara Kapı: varış, Er Töştük'ün gölgesi
ec(1,21,40,F0)
er.put(2,F0,'P'); er.put(3,F0,'p'); er.put(5,F0,'1'); er.put(10,F0,'F'); er.put(14,F0,'F')
er.fill(24,F0-2,27,F0,'#'); er.put(25,F0-3,'F')              # alçak kaya basamak
er.put(34,F0,'K')
# B) Mürekkep köprüler: yeraltı ırmağının üstü
ec(41,21,98,40)
er.fill(41,37,98,40,'w')                                      # ırmak (boğar)
def pillar(c0,c1,top=F0+1): er.fill(c0,top,c1,40,'#')
er.fill(41,F0+1,52,F0+1,'n')                                  # 1. köprü: örtülü kavanozla
er.put(42,F0,'2')
pillar(53,55); er.put(54,F0,'p'); er.put(55,F0,'3')
# 2. köprü: tepede Erlik'in feneri dolaşır; sütunlarda gölge oyukları
er.fill(56,F0+1,60,F0+1,'n'); pillar(61,62); er.put(61,F0,'~'); er.put(62,F0,'~')
er.fill(63,F0+1,67,F0+1,'n'); pillar(68,69); er.put(68,F0,'~'); er.put(69,F0,'~')
er.fill(70,F0+1,74,F0+1,'n')
# Fener tahtalara ve köprüdekine yetecek alçaklıkta (eskiden ışığı
# köprüye inmiyordu); oyuklarda beklenip geçilir.
er.put(61,F0-4,'N')
pillar(75,77); er.put(76,F0,'4'); er.put(77,F0,'F')
# 3. köprü: ışık ve gölge tahtaları sırayla (kenarda dur, sonra değiştir)
er.fill(78,F0+1,81,F0+1,'l'); er.fill(82,F0+1,85,F0+1,'n')
er.fill(86,F0+1,89,F0+1,'l'); er.fill(90,F0+1,93,F0+1,'n')
er.fill(94,F0+1,95,F0+1,'l')
pillar(96,98); er.put(97,F0,'K')
# C) Körmös mağarası
ec(99,22,170,F0)
er.put(101,F0,'p'); er.put(102,F0,'5'); er.put(104,F0,'F'); er.put(106,F0,'F')
er.put(110,F0-3,'b')
ec(112,F0+1,116,34); er.fill(112,34,116,34,'^'); er.fill(112,F0+1,116,F0+1,'l')   # çukur, ışık tahtası
er.put(118,F0,'~'); er.put(119,F0,'~')
er.put(122,F0,'F')
er.put(128,F0-4,'b')
ec(130,F0+1,131,34); er.fill(130,34,131,34,'^')             # sıçranacak çukur (2 kare)
er.fill(136,F0-1,139,F0,'#'); er.fill(140,F0-3,143,F0-3,'#'); er.put(141,F0-4,'M')   # basamak ve yüksek oyuk: hatıra
er.put(137,F0-2,'~'); er.put(138,F0-2,'~')
er.put(146,F0-3,'b')
ec(148,F0+1,159,34); er.fill(148,34,159,34,'^')
er.fill(148,F0+1,155,F0+1,'n'); er.fill(156,F0+1,159,F0+1,'l')
er.put(162,F0,'~'); er.put(163,F0,'~'); er.put(165,F0,'K'); er.put(167,F0,'F')
# D) Kut zindanı: üç kafes, üç kapı
ec(171,20,262,F0)
er.put(172,F0,'p'); er.put(173,F0,'6')
er.put(177,F0,'a')
er.fill(182,F0-4,182,F0,'H'); er.fill(182,20,182,F0-5,'#')
er.put(186,F0,'K'); er.put(188,F0,'F')
er.put(195,F0-3,'b'); er.put(206,F0-4,'b')
er.fill(196,F0-1,199,F0,'#'); er.fill(200,F0-3,203,F0,'#')       # basamaklar: kafes yüksekte
er.fill(205,F0-5,214,F0-5,'#')
er.put(212,F0-6,'a'); er.put(208,F0-6,'M')
er.put(192,F0,'~'); er.put(193,F0,'~')
er.fill(217,F0-4,217,F0,'H'); er.fill(217,20,217,F0-5,'#')
er.put(220,F0,'K'); er.put(222,F0,'7'); er.put(224,F0,'F'); er.put(226,F0,'F')
# Son kafes: gölge tahtası zeminli oda, iki Körmös
ec(229,F0+1,246,34); er.fill(229,34,246,34,'^')
er.fill(229,F0+1,235,F0+1,'n'); er.fill(240,F0+1,246,F0+1,'n')
er.fill(236,F0+1,239,34,'#'); er.put(237,F0,'a')                  # kaya adacık: kafes üstünde
er.put(232,F0-5,'b'); er.put(244,F0-5,'b')
er.fill(250,F0-4,250,F0,'H'); er.fill(250,20,250,F0-5,'#')
er.put(255,F0,'p'); er.put(258,F0,'K'); er.put(259,F0,'8')
# E) Çalkuyruk kuyusu: atın sıçrayışıyla yukarı, yükselen karanlıktan kaçış
ec(263,3,277,F0)
er.put(266,F0,'W'); er.put(268,F0,'z')
for i,r in enumerate((25,20,15,10,5)):
    if i%2==0: er.fill(272,r+1,277,r+1,'#')
    else: er.fill(263,r+1,268,r+1,'#')
ec(278,3,298,5)
er.put(270,8,'Z'); er.put(280,5,'9'); er.put(286,5,'K'); er.put(290,5,'M'); er.put(296,5,'E')
# Son kafesin odası: aşağı düşen basamaklara geri tırmanabilsin.
er.fill(204,F0-4,204,F0,'|')
lvl_erlik=er.rows()

# ------------------------------------------------------------ XV · ERGENEKON (Ötüken)
# Dört yanı aşılmaz dağlarla çevrili vadi. `d` demir damarı (dikey), `u`
# akan demir (yatay dizi), `z`/`Z` eriyen dağdan yükselen akkor demir.
# Körükler, ocak biçimleri (ritim, kömür), Nevruz örsü ve sis LevelDef'te.
W,H=332,44
eg=G(W,H)
F=34                                     # zemin: 34. satırda durulur
eg.fill(0,F+1,W-1,H-1,'#')
def gc(c0,r0,c1,r1): eg.fill(c0,r0,c1,r1,'.')
def mountain(c0,c1,top): eg.fill(c0,top,c1,F,'#')
# A) Kıyan Boğazı
mountain(0,0,0)
eg.put(2,F,'P'); eg.put(3,F,'p'); eg.put(5,F,'1'); eg.put(12,F,'F'); eg.put(20,F,'F')
eg.fill(24,F-1,27,F,'#')
eg.put(32,F,'K')
# B) Odun ve kömür, yetmiş körük: üç kömür sandığı; ikisi ocağın önündeki
# çukura (yakıt), biri yüksek körük rafına basamak. Demirci örse vurur;
# körükler vuruşa denk basılır.
eg.put(42,F,'p'); eg.put(45,F,'2')
eg.fill(61,F-3,63,F-3,'#')                          # yüksek körük rafı
eg.put(56,F,'F'); eg.put(84,F,'F')
eg.put(72,F,'C'); eg.put(76,F,'C'); eg.put(80,F,'C')
gc(88,F+1,89,F+1)                                   # kömür çukuru
mountain(93,99,0); eg.fill(92,0,92,F-7,'#'); eg.fill(92,F-6,92,F,'d')
gc(93,F-6,99,F)                                     # damarın ardındaki tünel
# C) Akan demir: kanallar soldan sağa sırayla katılaşır (dalga)
eg.put(100,F,'3'); eg.put(101,F,'p')
x=104
for n in (6,6,7,6):
    gc(x,F+1,x+n-1,H-3); eg.fill(x,H-3,x+n-1,H-3,'^'); eg.fill(x,F+1,x+n-1,F+1,'u')
    x+=n+3
eg.put(146,F,'K'); eg.put(148,F,'F')
# D) Sisli çayır: geniş gizli çukurlar, ortalarında tek karelik adacık
# (kanat yok; Gökbörü'nün izleri adacıkları gösterir)
eg.put(151,F,'4'); eg.put(152,F,'p')
for c0 in (158,170,182,194,205):
    gc(c0,F+1,c0+4,H-3); eg.fill(c0,H-3,c0+4,H-3,'^')
    eg.fill(c0+2,F+1,c0+2,H-3,'#')
# Asena'nın mağarası: kaya tavan, Umay ağacı
eg.fill(214,F-6,234,F-6,'#'); eg.fill(214,F-5,214,F-3,'#'); eg.fill(234,F-5,234,F-2,'#')
eg.put(217,F,'5'); eg.put(218,F,'p'); eg.put(222,F,'K'); eg.put(229,F,'M')
# E) İkinci damar: üç körük (biri yukarıda, biri akan demirin ötesinde);
# süs körüklerine basmak ocağı söndürür
eg.put(236,F,'6'); eg.put(237,F,'p'); eg.put(244,F,'F')
eg.fill(256,F-7,264,F-7,'#'); eg.fill(255,F-6,255,F,'|'); eg.put(262,F-8,'M')
gc(266,F+1,272,H-3); eg.fill(266,H-3,272,H-3,'^'); eg.fill(266,F+1,272,F+1,'u')
eg.put(280,F,'F'); eg.put(282,F,'F')
mountain(287,293,0); eg.fill(286,0,286,F-9,'#'); eg.fill(286,F-8,286,F,'d')
gc(287,F-6,293,F)
# F) Demir dağın içi: dağ erir, akkor demir yükselir. Kat kat taban; her
# katın açıklığı bir sağda bir solda, aradaki yol alevli bacaların
# üstünden geçer. Bir katta tek sandık: iki bacadan birini tıkar (ateşin
# üstünde bir süre sonra tutuşur).
mountain(294,331,6)
gc(294,F-6,299,F); gc(300,6,310,F)
eg.put(294,F,'7'); eg.put(295,F,'p'); eg.put(296,F,'K'); eg.put(298,F,'z')
floors=[(31,'R'),(27,'L'),(23,'R'),(19,'L'),(15,'R'),(11,'L'),(7,'R')]
prev=F+1
for r,side in floors:
    eg.fill(300,r,310,r,'#')
    if side=='R': gc(309,r,310,r)
    else: gc(300,r,301,r)
    # Açıklıktan aşağıdaki kata sarkan zincir: tırmanılır, üstte kata inilir.
    ch=310 if side=='R' else 300
    eg.fill(ch,r-1,ch,prev-1,'|')
    prev=r
# Bacalar (katın üstünde durulan satıra) ve sandık: kat arası üç kare boş,
# sandığın üstünden atlanabilir.
for c,r in [(305,30),(305,26),(305,22),(302,22),(303,18),(307,18),
            (306,14),(303,14),(302,10),(305,10),(308,10)]:
    eg.put(c,r,'!')
eg.put(307,22,'C')
# Çıkış koridoru en üst katla aynı hizada.
gc(311,4,330,6); eg.fill(311,7,330,7,'#')
eg.put(309,8,'Z')
# G) Nevruz: örste demir dövülür, kapı açılır, ilk sabah
eg.put(313,6,'8'); eg.put(314,6,'K'); eg.fill(322,4,322,6,'H')
eg.put(326,5,'M'); eg.put(328,6,'E')
lvl_ergenekon=eg.rows()

# ------------------------------------------------------------ XVI · GÖĞÜN KATLARI (Ötüken)
# Bulut adaları; `u` davul bulutu (sütunu 4'e bölününce çift/tek takım),
# `l`/`n` ay katında ışık ve gölge tahtaları, `W` Tulpar, `z`/`Z` Erlik'in
# fırtınası (Tulpar'a binince soldan gelir, Z'nin sütununda dağılır).
# Yakıcı ışık (gün katı) LevelDef.scorch.
W,H=332,40
gk=G(W,H)
F=30
def island(c0,c1,top=F+1,bottom=F+2): gk.fill(c0,top,c1,bottom,'#')
# A) Bulut kapısı: Kam ve ilk davul bulutları
island(0,20)
gk.put(2,F,'P'); gk.put(3,F,'p'); gk.put(5,F,'1')
for c in (22,26,30): gk.fill(c,F+1,c+2,F+1,'u')
island(34,50); gk.put(36,F,'2'); gk.put(42,F,'K')
# B) Ay katı: davul merdiveni, ışık ve gölge tahtaları
island(51,60); gk.put(52,F,'p')
for i,(c,r) in enumerate(((62,F-1),(66,F-3),(70,F-5),(74,F-7))): gk.fill(c,r+1,c+2,r+1,'u')
island(78,90,F-7,F-6); gk.put(80,F-8,'M'); gk.put(84,F-8,'3')
gk.fill(91,F-7,93,F-7,'l'); gk.fill(94,F-7,97,F-7,'n'); gk.fill(98,F-7,100,F-7,'l'); gk.fill(101,F-7,104,F-7,'n')
island(105,120,F-7,F-6); gk.put(110,F-8,'K'); gk.put(112,F-8,'4')
# C) Gün katı: yakıcı ışık, Umay kuşunun gölgesi; çukurlar ve davul bulutları
island(121,139); island(142,157); island(161,175); island(178,185); island(196,200)
for c in (186,190): gk.fill(c,F+1,c+2,F+1,'u')
gk.put(122,F,'p'); gk.put(123,F,'5')
# D) Ülgen'in kapısı
island(201,236); gk.put(203,F,'6'); gk.put(206,F,'K'); gk.put(230,F,'M'); gk.put(233,F,'p')
# E) Tulpar: fırtınadan kaçış, bulut sütunları arasından uçuş
island(237,246); gk.put(240,F,'W'); gk.put(242,F,'z'); gk.put(238,F,'7')
for c,(t,b) in ((254,(0,18)),(264,(22,39)),(274,(0,15)),(284,(20,39)),(294,(0,19)),(304,(24,39))):
    gk.fill(c,t,c+2,b,'#')
island(266,268,F-11,F-10); island(288,290,12,12); gk.put(289,11,'M')
island(310,331); gk.put(316,F,'Z'); gk.put(318,F,'8'); gk.put(320,F,'K'); gk.put(328,F,'E')
lvl_gok_eski=gk.rows()

# --- Göğün Katları ikiye ayrılır (docs/UZATMA_PLANI.md).
# I: Bulut Kapısı, Ay Katı (eski haritanın 0-120. sütunları, üstte 8 satır
# boşluk) + Yıldız Katı + Yel Katı. Çarklar, Yedi Karakçı ve Yel Ana'nın
# soluğu LevelDef'te (wheels, karakci, yel); `c` yada taşı.
G1W,G1H=304,48
g1=G(G1W,G1H)
for r,row in enumerate(lvl_gok_eski):
    for c in range(121):
        ch=row[c]
        if ch=='4': ch='.'          # eski "gün katı" fısıltısı II'ye geçti
        if ch!='.': g1.g[r+8][c]=ch
def isl1(c0,c1,top,th=2): g1.fill(c0,top,c1,top+th-1,'#')
# Yıldız Katı: tek çark, ters dönen iki çark, Demir Kazık'ın atları.
isl1(121,126,31); g1.put(122,30,'p'); g1.put(123,30,'4'); g1.put(125,30,'K')
isl1(135,143,22); g1.put(137,21,'5')
isl1(159,167,9);  g1.put(160,8,'K'); g1.put(161,8,'6'); g1.put(164,8,'M')
isl1(182,192,9);  g1.put(184,8,'K')
# Yel Katı: arkadan soluk, önden soluk (çömel), yada taşıyla yön.
g1.put(188,8,'p'); g1.put(190,8,'7')
isl1(212,218,13); g1.put(214,12,'K')
for c0,c1 in ((222,227),(230,234),(237,242)): isl1(c0,c1,16,1)
isl1(244,248,16); g1.put(245,15,'K'); g1.put(246,15,'c'); g1.put(247,15,'8')
isl1(270,280,20); g1.put(276,19,'M')
isl1(282,303,24); g1.put(284,23,'K'); g1.put(286,23,'9'); g1.put(300,23,'E')
# Uzatma (2026-10-25): Kuş Yolu Katı araya girer (290. sütunda; çıkış
# sağa kayar). Işık nehri ve Ülker'in yedi yıldızı levels.dart'ta
# (starStreams, ulker).
ky=G(100,G1H)
ky.fill(0,24,5,25,'#'); ky.put(1,23,'p'); ky.put(2,23,'K'); ky.put(4,23,'(')
ky.fill(34,12,42,13,'#')                      # Ülker'in bulutu
ky.fill(67,12,71,13,'#'); ky.put(68,11,'K'); ky.put(69,11,')')
ky.fill(95,24,99,25,'#')
rows=g1.rows()
rows=[r[:290]+x+r[290:] for r,x in zip(rows,ky.rows())]
lvl_gok=rows

# II: Gün Katı (eski 121-200) + Şimşek Katı (yeni) + Ülgen'in Kapısı ve
# Tulpar (eski 201-331). Kara bulut basamakları ve yıldırımlar LevelDef'te
# (stormSteps, strikes).
SIM=60
G2W=10+80+SIM+131
g2=G(G2W,40)
F2=30
g2.fill(0,F2+1,9,F2+2,'#'); g2.put(2,F2,'P'); g2.put(3,F2,'1'); g2.put(6,F2,'K')
REN={'5':'2','6':'5','7':'6','8':'7'}       # eski fısıltılar bu bölümde
def cp(src0,src1,dst0):
    for r,row in enumerate(lvl_gok_eski):
        for k,c in enumerate(range(src0,src1+1)):
            ch=row[c]
            if ch=='P': ch='.'
            g2.g[r][dst0+k]=REN.get(ch,ch)
cp(121,200,10)
# Gün Katı'nın eski fısıltıları: 5 (Hüma) → 2; 4 → bu bölümün 1'i.
x0=10+80
# Şimşek Katı: yıldırımlar ve yalnızca şimşekte görünen kara bulut basamakları.
g2.fill(x0,F2+1,x0+7,F2+2,'#'); g2.put(x0+1,F2,'p'); g2.put(x0+2,F2,'K'); g2.put(x0+4,F2,'3')
g2.fill(x0+18,F2+1,x0+24,F2+2,'#'); g2.put(x0+20,F2,'4')
g2.fill(x0+34,F2-5,x0+40,F2-4,'#'); g2.put(x0+36,F2-6,'K'); g2.put(x0+38,F2-6,'M')
g2.fill(x0+52,F2+1,x0+SIM-1,F2+2,'#')
g2.put(x0,1,'<'); g2.put(x0+SIM-1,38,'>')       # sağanak: kanat ıslanır
cp(201,331,x0+SIM)
lvl_gok2=g2.rows()

# ------------------------------------------------------------ XIV · ÖTÜKEN ORMANI (Ötüken)
# Yeşil, kutlu orman. `c` yaprak arasından düşen ışık huzmesi (LevelDef.glades
# alanında: gölgede Karabasan bekler), `u` davul kökleri (Kam'ın davuluyla
# kalkar, iner), `a` Ak Geyik, `d` geyik kökü (Ak Geyik basınca en yakın
# kapıyı tutar), `z`/`Z` Kara Bataklık'ta Karabasan, tepede güneş kilidi.
# İpler 8 kare arayla, 8 kare boyunda (kanatsız sınandı: ip_olcum_test).
W,H=446,50
ot=G(W,H)
F=40
def og(c0,c1,top=F): ot.fill(c0,top,c1,H-1,'#')
def bog(c0,c1): ot.fill(c0,F+2,c1,H-1,'w')
def thorns(c0,c1): ot.fill(c0,H-2,c1,H-1,'^')
def ropes(cols,n=6):
    for c in cols: ot.fill(c,F-n-1,c,F-2,'S')
def roots(cols,r=F):
    for c in cols: ot.fill(c,r,c+2,r,'u')
# A) Orman Eşiği: ışık lekeleri (durgun), dere ve ilk ip, rüzgârlı lekeler
og(0,19); ot.put(2,F-1,'P'); ot.put(3,F-1,'p'); ot.put(4,F-1,'1')
og(11,12,F-1)                                   # yosunlu taş
ot.put(16,F-4,'e')                              # karanlıkta iki göz
og(20,60); ot.put(10,F-1,'2')
for c in (35,41,47,53,58): ot.put(c,F-1,'c')
og(35,36,F-2)                                   # devrik kütük
ot.fill(37,F-4,40,F-4,'='); ot.put(39,F-5,'M')  # kütükten dala: hatıra
bog(61,68); ropes((62,),8)                      # dere: ilk sarmaşık
og(69,104); ot.put(71,F-1,'3')
for c in (74,82,90,98): ot.put(c,F-1,'c')
og(84,86,F-2); ot.put(85,F-3,'F')
ot.put(102,F-1,'K')
# B) Kam'ın Korusu: davul kökleri, sarmaşık zinciri, kök merdiveni
og(105,111); ot.put(106,F-1,'p'); ot.put(108,F-1,'4')
bog(112,127); roots((112,116,120,124))
og(128,134); ot.put(130,F-1,'5')
thorns(135,149); ropes((136,141,146),8)         # dikenli yar: üç sarmaşık
og(150,170); ot.put(158,F-1,'K'); ot.put(162,F-1,'F')
ot.fill(160,F-3,161,F-3,'='); ot.fill(164,F-5,167,F-5,'='); ot.put(166,F-6,'M')
ot.put(168,F-1,'6')
bog(171,187)
for c,r in ((172,F),(176,F-2),(180,F-4),(184,F-6)): roots((c,),r)
og(188,200,F-7); ot.put(189,F-8,'K'); ot.put(191,F-8,'7')
for c in (190,195,199,203,207,211,216): ot.put(c,F-8,'c')
ot.fill(201,F-7,212,F-7,'.'); roots((201,205,209),F-7)   # kökler ve ışık birlikte
ot.fill(201,F-4,212,H-1,'w')                     # bataklık köklerin hemen altında
og(213,218,F-7)
# C) Ak Geyik
og(219,330); ot.put(220,F-1,'K'); ot.put(221,F-1,'p'); ot.put(223,F-1,'8')
ot.put(226,F-1,'a'); ot.put(230,F-1,'F'); ot.put(233,F-1,'F')
ot.put(237,F-1,'d')
ot.fill(242,F-14,242,F-5,'#'); ot.fill(242,F-4,242,F-1,'H')        # kök duvarı ve kapısı
# Üst yol (Sâye) ve alt geçit (geyik): yukarıdan ateşböceğiyle yol gösterilir.
ot.fill(250,F-6,296,F-5,'#'); ot.fill(249,F-6,249,F-1,'|'); ot.put(247,F-1,'9')
ot.put(252,F-7,'F')
ot.put(257,F-1,'d')
ot.fill(260,F-16,260,F-11,'#'); ot.fill(260,F-10,260,F-7,'H')     # üst kapı: geyik tutar
ot.put(276,F-7,'L')                                                # alt kapıyı açan kol
ot.fill(268,F-4,268,F-1,'H')                                       # alt geçidin kapısı
ot.fill(282,F-9,284,F-9,'='); ot.put(283,F-10,'M')
ot.fill(297,F-6,297,F-1,'|')                                       # üst yoldan iniş
# Işıksız yol: geyik karanlığa girmez; ateşböceği ışığı köprü olur.
ot.put(298,F-1,'K'); ot.put(300,F-1,'('); ot.put(301,F-1,'F')
for c in (302,310,318,325): ot.put(c,F-1,'c')      # her ara bir ateşböceği: üç yeter
ot.put(312,F-1,'F')
ot.put(326,F-1,'d')
ot.fill(330,F-14,330,F-5,'#'); ot.fill(330,F-4,330,F-1,'H')
# D) Kara Bataklık: Karabasan kovalar
og(331,338); ot.put(333,F-1,'K'); ot.put(335,F-1,'p'); ot.put(336,F-1,')'); ot.put(338,F-1,'z')
bog(339,340); og(341,345); bog(346,347); og(348,352,F-1)
ot.put(343,F-1,'F')
bog(353,364)
for c in (354,358,362): ot.put(c,F,'O')            # çöken kayalar: durma
og(365,370); thorns(371,381); ropes((372,378),8)
og(382,398); ot.put(396,F-1,'Z')
# E) Hayat Ağacı: ışık sırayla düşer; tepede güneş aynalarla indirilir.
ot.put(399,F-1,'K'); ot.put(401,F-1,'p'); ot.put(402,F-1,'[')
og(399,413)
Ft=17
og(414,421,Ft+1)                                # gövde
for i,r in enumerate(range(F-2,Ft,-2)):         # dallar: sağ ve sol sırayla
    c0 = 408 if i%2==0 else 403
    ot.fill(c0,r,c0+3,r,'=')
for c in (404,410): ot.put(c,F-1,'c')
ot.put(404,23,'M')
# Tepede ayna salonu (Kaf'taki düzenin aynısı; zemin dal, altı gövde).
x=413
ot.fill(x,Ft,x+25,Ft,'#')
ot.fill(x,Ft-16,x+25,Ft-15,'#')
ot.fill(x,Ft-8,x,Ft-5,'#')
ot.fill(x+1,Ft-2,x+1,Ft-1,'#')
ot.fill(x+2,Ft-4,x+13,Ft-4,'#')
ot.fill(x+15,Ft-4,x+16,Ft-4,'#')
ot.put(x+4,Ft-14,'j'); ot.put(x+4,Ft-5,'m'); ot.put(x+14,Ft-5,'m'); ot.put(x+14,Ft-1,'m')
ot.put(x+16,Ft-1,'C'); ot.put(x+17,Ft,'.',force=True)
ot.fill(x+17,Ft+1,x+17,Ft+1,'#')
ot.put(x+22,Ft-1,'t'); ot.put(x+6,Ft-1,']')
ot.fill(x+25,Ft-14,x+25,Ft-7,'#'); ot.fill(x+25,Ft-6,x+25,Ft-1,'H')
ot.fill(x+26,Ft,445,Ft,'#'); ot.put(x+27,Ft-1,'{'); ot.put(443,Ft-1,'E')
# --- Sarmaşık parkurları: eski haritanın arasına sütun olarak eklenir; böylece
# öbür bölümlerin yerleri değişmez, yalnız sağa kayar (OTUKEN_INS).
def parkour(w):
    g=G(w,H)
    def gr(c0,c1,top=F): g.fill(c0,top,c1,H-1,'#')
    def vine(c,base=F,n=8): g.fill(c,base-n-1,c,base-2,'S')
    return g,gr,vine
# Ölçü (tools/preview/ip_inis_test.dart): sarmaşıktan ilk salınışta bırakan
# 3-7, pompalayıp bırakan 7-11 kare ileri iner. Kolay atlayışta kütük ipten
# 4-8 kare, zorda 6-9 kare ileride; uzun salınım yalnız pompayla geçilir.
# S1) Geyiğin Yolu: geyiğin gösterdiği yol, dikenli yarın üstünde sarmaşıklar.
s1,gr,vine=parkour(112)
s1.fill(0,H-2,111,H-1,'^')                       # yarın dibi dikenli
gr(0,6); s1.put(1,F-1,'p'); s1.put(2,F-1,'K'); s1.put(4,F-1,'}'); s1.put(5,F-1,'F')
vine(8);  gr(12,16)                              # tek ip, karşıda kütük
vine(18); gr(24,27,F-1)                          # daha uzak, biraz yüksek kütük
vine(29,F-1); gr(35,44,F-3); s1.put(38,F-4,'K')  # yükseğe bırak: sahanlık
vine(46,F-3); vine(51,F-3); gr(55,59,F-2)        # iki sarmaşık zinciri
vine(61,F-2); vine(66,F-2); gr(70,76); s1.put(73,F-1,'F')
vine(78,F,11)                                    # uzun salınım: pompala
gr(83,84,F-4); s1.put(83,F-5,'M')                # erken bırakana kaya: hatıra
gr(87,111)
# S2) Ulu Dallar: Hayat Ağacı'na giden yüksek dallar; altı bataklık.
s2,gr,vine=parkour(72)
B=F-8                                            # dalların yüksekliği
gr(0,5); s2.put(1,F-1,'K'); s2.put(3,F-1,'p')
s2.fill(6,F+2,52,H-1,'w')                         # bataklık
s2.fill(6,B,9,B,'#'); s2.fill(5,B,5,F-1,'|')       # sarmaşıkla ilk dala
vine(11,B);   s2.fill(15,B-1,19,B-1,'=')
vine(21,B-1); s2.fill(27,B,30,B,'=')              # uzak dal
vine(32,B); vine(37,B); s2.fill(41,B-2,45,B-2,'='); s2.put(43,B-3,'F')
vine(47,B-2)
gr(53,71)                                        # ağacın dibine iniş
# S0) Sarmaşık Deresi: Orman Eşiği ile Kam'ın Korusu arasında, suyun üstünde.
s0,gr,vine=parkour(44)
gr(0,3)
s0.fill(4,F+2,34,H-1,'w')                         # dere
vine(5);  gr(9,13)
vine(15); gr(21,24,F-1)                          # uzak, biraz yüksek taş
vine(26,F-1); vine(31,F-1)
gr(35,43)
OTUKEN_INS = [(105, s0.rows()), (331, s1.rows()), (399, s2.rows())]
rows = ot.rows()
for at, ins in sorted(OTUKEN_INS, reverse=True):
    rows = [r[:at] + x + r[at:] for r, x in zip(rows, ins)]
lvl_otuken=rows

# ------------------------------------------------------------ XX · YEŞİL KUBBE (final)
# Dört alan: türbe avlusu (şadırvanın ayı, iki ayna), kandiller koridoru
# (kafesteki ışıklar, iki Kandilci, gölge taşı), kubbenin kaburgaları
# (fenerlerin taradığı tırmanış, çöken çiniler, ipler, ışık seli) ve
# ustanın kandili (Kandilci Başı; üç ayna, levels.dart'ta finale).
W,H=312,60
F=52
yk=G(W,H)
def yc(c0,r0,c1,r1): yk.fill(c0,r0,c1,r1,'.')
def yb(c0,r0,c1,r1): yk.fill(c0,r0,c1,r1,'#')
yb(0,F,99,H-1)
yb(0,0,0,H-1)
# 1) Türbe avlusu: karlı avlu, gül bahçesi; gökten havuza inen ay.
yk.put(2,F-1,'P'); yk.put(3,F-1,'p'); yk.put(5,F-1,'1'); yk.put(9,F-1,'B')
yk.put(14,F-1,'K'); yk.put(18,F-1,'M')
yb(26,F-8,27,F-4)                       # sol duvar: yanlış yöne giden ışık kesilir
yb(31,F-4,37,F-1)                       # şadırvanın taşı (aynanın sahanlığı)
yb(29,F-2,30,F-1)                       # basamak
yk.put(34,F-20,'j')                     # ay: kubbenin penceresinden
yk.put(34,F-5,'m')                      # ayna: başta sola (yanlış)
yk.put(40,F-1,'2')
yk.put(48,F-1,'G')                      # avluyu dolaşan Kandilci
yb(55,F-2,56,F-1); yb(58,F-4,59,F-1)    # basamaklar
yb(60,F-4,66,F-1)                       # ikinci aynanın sahanlığı
yb(67,F-2,68,F-1)                       # sağdan inen geri çıkabilsin
yk.put(64,F-5,'h')                      # ayna: başta aşağı (yanlış)
yk.put(64,F-12,'t')                     # türbenin gümüş kapısının kilidi
yb(63,F-14,65,F-13)                     # kilidin taşı
yk.put(70,F-1,'F')
yb(74,F-14,75,F-7); yk.fill(74,F-6,74,F-1,'H')   # türbenin kapısı
yb(74,0,75,F-15)
yk.put(72,F-1,'3')
# 2) Kandiller koridoru: türbenin içi; kafeslerde Kandilcilerin topladığı
# ışıklar (levels.dart'ta cages). Her kafes bir kapı açar.
yb(75,0,200,F-13)                       # tavan
yb(100,F,200,H-1)
yk.put(78,F-1,'K'); yk.put(79,F-1,'p'); yk.put(81,F-1,'4')
yk.put(86,F-1,'I')
yb(96,F-12,97,F-7); yk.fill(96,F-6,96,F-1,'H')   # ilk kafesin kapısı
yk.put(99,F-1,'I'); yk.put(104,F-1,'G'); yk.put(112,F-1,'I')
yk.put(119,F-1,'5'); yk.put(124,F-1,'G'); yk.put(131,F-1,'I')
yb(136,F-12,137,F-7); yk.fill(136,F-6,136,F-1,'H')   # ikinci kafesin kapısı
yk.put(139,F-1,'K'); yk.put(141,F-1,'F'); yk.put(143,F-1,'M')
yk.put(147,F-1,'I'); yk.put(152,F-1,'G'); yk.put(160,F-1,'I')
yb(156,F-3,157,F-1)                     # sanduka: üstüne çıkılır
yk.put(166,F-1,'6'); yk.put(170,F-1,'I'); yk.put(176,F-1,'G')
yb(186,F-12,187,F-7); yk.fill(186,F-6,186,F-1,'H')   # üçüncü kafesin kapısı
yk.put(190,F-1,'B')
# Koridorun sonu: türbenin arka kapısından kubbenin dibine.
yc(188,F-12,200,F-1)
# 3) Kubbenin kaburgaları: dışarıda, fenerlerin taradığı tırmanış.
yb(200,F,311,H-1)
yb(201,F-1,205,F-1)                     # kasnağın dibi
yk.put(195,F-1,'K'); yk.put(196,F-1,'p')
yk.put(202,F-2,'z')                     # ışık seli buradan sonra yükselir
# Kaburgalar: sağa sola dizilen basamaklar (her biri iki-üç kare yukarı).
steps=[(206,F-2,4),(211,F-4,3),(206,F-6,3),(211,F-8,3),(216,F-10,4),
       (221,F-12,3),(216,F-14,3),(211,F-16,3),(206,F-18,4)]
for c,r,n in steps: yk.fill(c,r,c+n-1,r,'=')
yk.put(222,F-13,'I'); yk.put(212,F-17,'I')
yk.put(207,F-19,'K'); yk.put(209,F-19,'7')
# Çöken çiniler, ip, yeniden kaburgalar.
for c,r in ((212,F-19),(215,F-20),(218,F-21)): yk.put(c,r,'O')
yb(219,F-31,225,F-31)                   # ipin bağlandığı kemer
yk.fill(222,F-30,222,F-22,'S')          # ip
yk.fill(228,F-22,231,F-22,'=')
yk.put(229,F-23,'I')
yk.fill(233,F-24,235,F-24,'='); yk.fill(237,F-26,239,F-26,'=')
yk.put(238,F-27,'8')
yk.fill(233,F-28,235,F-28,'='); yk.fill(237,F-30,240,F-30,'=')
yk.put(239,F-31,'K'); yk.put(240,F-31,'M')
for c,r in ((243,F-32),(246,F-33),(249,F-34)): yk.put(c,r,'O')
yk.fill(251,F-36,253,F-36,'='); yk.fill(255,F-38,257,F-38,'=')
yk.fill(252,F-40,254,F-40,'=')
yk.put(256,F-39,'Z')                    # sel burada durur
# Kasnağı dolaşan büyük fenerler.
yk.put(203,F-28,'0'); yk.put(232,F-38,'0')
# 4) Ustanın kandili: kubbenin alemi, Kandilci Başı.
yb(258,F-42,311,F-40)
yk.put(259,F-43,'p'); yk.put(260,F-43,'9')
yk.put(263,F-43,'I'); yk.put(276,F-43,'I'); yk.put(294,F-43,'I')
yk.put(266,F-50,'j'); yk.put(266,F-43,'m')        # birinci ayna
yb(270,F-44,274,F-44)                              # ikinci aynanın sahanlığı
yk.put(272,F-51,'j'); yk.put(272,F-45,'m')         # ikinci ayna (yukarıda)
yk.put(296,F-50,'j'); yk.put(296,F-43,'h')         # üçüncü ayna
yb(303,F-50,304,F-47); yk.fill(303,F-46,303,F-43,'H')   # çıkış kapısı
yk.put(307,F-43,'E')
yb(311,0,311,H-1)
lvl_yesil=yk.rows()

MAPS = [('kMapYerebatan', lvl1), ('kMapKule', lvl2), ('kMapGokyolu', lvl3), ('kMapKaf', lvl4), ('kMapAgri', lvl5), ('kMapGemi', lvl6), ('kMapNemrut', lvl7), ('kMapGunDogumu', lvl8), ('kMapKarYolu', lvl9), ('kMapPalandoken', lvl10), ('kMapCig', lvl11), ('kMapPeri', lvl12), ('kMapDerinkuyu', lvl13), ('kMapKonya', lvl14), ('kMapErlik', lvl_erlik), ('kMapErgenekon', lvl_ergenekon), ('kMapGok', lvl_gok), ('kMapOtuken', lvl_otuken), ('kMapGok2', lvl_gok2), ('kMapYesilKubbe', lvl_yesil)]

out = ['// Bu dosya tools/generate_maps.py ile üretilir; elle düzenleme.',
       '// Gösterim: lib/game/level.dart başındaki açıklamaya bakın.', '']
for name, rows in MAPS:
    widths = set(len(r) for r in rows)
    assert len(widths) == 1, (name, widths)
    out.append(f'const {name} = <String>[')
    # '$' Dart dizgisinde değişken eklemedir: kaçışla yazılır.
    out += ["  '" + r.replace('$', '\\$') + "'," for r in rows]
    out += ['];', '']
    print(name, len(rows), 'x', widths.pop())
SURFACES = [('kSkiPalandoken', pal_surface), ('kSkiCig', cig_surface)]
for name, marks in [('kSkiMarksPalandoken', pal_marks), ('kSkiMarksCig', cig_marks)]:
    out.append(f'const {name} = <(int, int, String)>[')
    for i in range(0, len(marks), 6):
        out.append('  ' + ' '.join(f"({c}, {r}, '{ch}')," for c,r,ch in marks[i:i+6]))
    out += ['];', '']
for name, dec in [('kSkiDecorPalandoken', PAL_DECOR), ('kSkiDecorCig', CIG_DECOR)]:
    out.append(f'const {name} = <(String, int)>[')
    out.append('  ' + ' '.join(f"('{k}', {c})," for k,c in dec))
    out += ['];', '']
for name, ys in SURFACES:
    out.append(f'const {name} = <double>[')
    for i in range(0, len(ys), 12):
        out.append('  ' + ', '.join(f'{v:.2f}' if v >= 0 else '-1' for v in ys[i:i+12]) + ',')
    out += ['];', '']
out.append('/// Palandöken Manyetik Tepe sütun aralıkları (ilk, son).')
out.append('const kSkiPalandokenMagnet = <(int, int)>[' + ', '.join(f'({a}, {b})' for a,b in PAL_MAGNET) + '];')
out.append('')
open('lib/game/maps.dart', 'w').write('\n'.join(out))
print('magnet', sk.magnets, 'palandöken', len(pal_surface), 'çığ', len(cig_surface))
