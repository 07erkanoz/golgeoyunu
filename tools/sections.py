"""Bölüm parçaları: testlerle doğrulanmış yapıların yeniden kullanılabilir hâli.

Her parça `x` sütunundan başlar, zemin satırı `F` (oyuncu F-1'de durur) ve
bittiği yerin bir sonraki sütununu döndürür. Parçalar zeminde başlayıp zeminde
biter; böylece art arda dizilebilir. Haritanın yüksekliği en az F+10 olmalı.
"""


def ground(g, x, F, n, *, fill_to=None):
    """n kare düz zemin."""
    bottom = g.H - 1 if fill_to is None else fill_to
    g.fill(x, F, x + n - 1, bottom, '#')
    return x + n


def pit(g, x, F, n, *, water=True):
    """n kare uçurum; dibinde su (değince boğar) ya da boşluk (düşen ölür)."""
    if water:
        g.fill(x, g.H - 2, x + n - 1, g.H - 1, 'w')
    return x + n


def mark(g, x, r, ch):
    """Boşsa bir işaret koyar (fısıltı, kuş, kontrol noktası...)."""
    if g.g[r][x] == '.':
        g.g[r][x] = ch


# ------------------------------------------------------------- geçitler

def rope_chasm(g, x, F, n=3):
    """n iple uçurum (Ağrı'da test edildi: ipler 7 kare arayla, uzunluk 10)."""
    ground(g, x, F, 5)
    g.fill(x + 5, F - 11, x + 6 + 7 * (n - 1) + 7, F - 10, '#')   # taş kemer
    for i in range(n):
        g.fill(x + 6 + 7 * i, F - 9, x + 6 + 7 * i, F, 'S')
    end = x + 6 + 7 * (n - 1) + 8
    return ground(g, end, F, 3)


def light_shadow(g, x, F):
    """Işık tahtası, taş ayak, gölge tahtası (Yerebatan'da test edildi)."""
    ground(g, x, F, 2)
    g.fill(x + 2, g.H - 2, x + 7, g.H - 1, 'w')
    g.fill(x + 2, F, x + 7, F, 'l')
    ground(g, x + 8, F, 2)
    mark(g, x + 8, F - 1, 'F')
    g.fill(x + 10, g.H - 2, x + 15, g.H - 1, 'w')
    g.fill(x + 10, F, x + 15, F, 'n')
    return ground(g, x + 16, F, 2)


def rotten_guard(g, x, F, *, ceiling=True):
    """Sahanlık, çürük köprü, Kandilci'nin dar geçidi (Yerebatan'da test
    edildi: sahanlığın başından salınan ateşböceği Kandilci'yi köprüye çeker).
    """
    ground(g, x, F, 6)
    mark(g, x + 1, F - 1, 'I')
    g.fill(x + 6, g.H - 2, x + 8, g.H - 1, 'w')
    g.fill(x + 6, F, x + 8, F, 'u')
    ground(g, x + 9, F, 10)
    if ceiling:
        g.fill(x + 9, F - 8, x + 18, F - 4, '#')
    mark(g, x + 14, F - 1, 'G')
    return x + 19


def water_basin(g, x, F):
    """Boşalt-in-doldur-çık su haznesi (Yerebatan'da test edildi).

    Giriş zemininin son karesinde boşaltan vana; hazne 8 kare; çıkış rafı
    F-4 satırında. Dönüş: çıkış rafından sonraki sütun (zemin F-4'te).
    """
    ground(g, x, F, 3)
    mark(g, x + 2, F - 1, 'v')
    b = x + 3
    g.put(b, F - 5, 'q')
    g.put(b + 7, F + 8, 'Q')
    g.fill(b, F + 9, b + 7, g.H - 1, '#')
    g.put(b + 2, F + 8, 'y')
    g.put(b + 5, F + 1, 'f')
    g.fill(b + 8, F - 4, b + 11, g.H - 1, '#')
    return b + 12


def step_down(g, x, F_from, F_to, n=3):
    """Yüksekten alçağa inen zemin (düşüş zararsız)."""
    g.fill(x, F_to, x + n - 1, g.H - 1, '#')
    return x + n


def stairs_up(g, x, F_from, F_to):
    """En fazla 2 karelik basamaklarla yukarı çıkar."""
    F = F_from
    while F > F_to:
        F = max(F_to, F - 2)
        ground(g, x, F, 3)
        x += 3
    return x


def crumble_run(g, x, F, n=3):
    """Uçurumun üstünde çöken kayalar (2 kare genişlik, 2 kare boşluk)."""
    ground(g, x, F, 2)
    x += 2
    for i in range(n):
        g.put(x + 1 + 4 * i, F - (i % 2), 'O')
    x += 4 * n + 1
    return ground(g, x, F, 3)


def stealth_hall(g, x, F, n=24, guards=2, ceiling=True):
    """Uzun bir salon: Kandilciler, aralarda saklanma sütunları ve otlar."""
    ground(g, x, F, n)
    if ceiling:
        g.fill(x, F - 9, x + n - 1, F - 6, '#')
    spacing = n // (guards + 1)
    for i in range(guards):
        mark(g, x + spacing * (i + 1), F - 1, 'G')
        mark(g, x + spacing * (i + 1) - 4, F - 1, 'I')
        mark(g, x + spacing * (i + 1) + 4, F - 1, '~')
        mark(g, x + spacing * (i + 1) + 5, F - 1, '~')
    mark(g, x + 2, F - 1, 'F')
    return x + n


def bat_dark(g, x, F, n=22):
    """Alçak tavanlı, ışığı yiyen yarasa galerisi."""
    ground(g, x, F, n)
    g.fill(x, F - 12, x + n - 1, F - 6, '#')
    for i in range(3):
        mark(g, x + 4 + i * 7, F - 5, 'b')
    g.put(x + 2, F - 5, 'x')
    g.put(x + n - 3, F - 1, 'X')
    mark(g, x + 1, F - 1, 'F')
    mark(g, x + n // 2, F - 1, 'F')
    mark(g, x + n // 2 + 3, F - 1, 'I')
    return x + n


def lever_gate(g, x, F):
    """Kapı yolu keser; kolu yukarıdaki raftan çekmek gerekir."""
    ground(g, x, F, 14)
    g.fill(x + 10, F - 4, x + 10, F - 1, 'H')
    g.fill(x + 10, 0, x + 10, F - 5, '#')
    g.fill(x + 3, F - 4, x + 7, F - 4, '=')
    g.fill(x + 1, F - 8, x + 2, F - 8, '=')
    g.put(x + 2, F - 9, 'L')
    g.put(x + 6, F - 1, 'C')
    return x + 14


def mirror_lock(g, x, F):
    """Kaf'taki ayna salonunun aynısı (testli): huzme, üç ayna, sandık,
    ışık kilidi ve kapı. F >= 16 olmalı (huzmenin kaynağı F-14'te)."""
    ground(g, x, F, 26)
    g.fill(x, F - 16, x + 25, F - 15, '#')         # tavan
    g.fill(x, F - 8, x, F - 5, '#')                # soldan kaçan ışığı tutar
    g.fill(x + 1, F - 2, x + 1, F - 1, '#')        # basamak
    g.fill(x + 2, F - 4, x + 13, F - 4, '#')       # orta raf
    g.fill(x + 15, F - 4, x + 16, F - 4, '#')
    g.put(x + 4, F - 14, 'j')
    g.put(x + 4, F - 5, 'm')
    g.put(x + 14, F - 5, 'm')
    g.put(x + 14, F - 1, 'm')
    g.put(x + 16, F - 1, 'C')
    g.put(x + 17, F, '.', force=True)               # sandığın düşeceği çukur
    g.put(x + 22, F - 1, 't')
    g.fill(x + 25, F - 14, x + 25, F - 7, '#')
    g.fill(x + 25, F - 6, x + 25, F - 1, 'H')
    return ground(g, x + 26, F, 2)
