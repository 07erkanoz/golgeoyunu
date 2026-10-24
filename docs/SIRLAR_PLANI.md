# Sırlar ve sürprizler planı

24 Ekim 2026. Oyuncunun temel motivasyonu yolculuğu bitirmek; bu plan ikinci
bir motivasyon ekler: "Acaba burada ne saklı?" Karagöz hem hayal perdesi hem
güldürüdür. Oyun şimdiye dek perdenin mistik, gerilimli yüzünü kullandı; bu
plan öteki yüzünü, sıcak ve komik keşifleri geri getirir.

Durum: ✅ yapıldı · 🔶 kısmen · ⏳ sırada

## İlkeler

1. **Ton:** şaka tehlikenin hemen ardında değil, güvenli anlarda gelir:
   kontrol noktası, Umay ağacı, bölüm sonu, gizli odanın içi. Kandilci kovalarken,
   Karabasan yaklaşırken sürpriz yok.
2. **Adil gizleme:** oyuncu rastgele duvarlara çarpmaz; bir tutarsızlık fark eder:
   - ters akan su,
   - yansımada görünen ama gerçekte olmayan kemer,
   - aralıktan gelen kuş sesi,
   - duvarın ardından sızan sıcak ışık,
   - ötekilerden farklı sallanan sarmaşık ya da perde.
3. **Öğret, sonra zorlaştır:** ilk sır (Yerebatan) neredeyse herkesin bulacağı
   kadar belli; sonrakiler giderek gizli.
4. **Ödül bazen yalnız bir an:** her sürpriz eşya vermez; beklenmedik bir şey
   görmek de ödüldür. Gizli odalar ise kalıcı bir şey bırakır (tasvir parçası).
5. **Ana yol bozulmaz:** gizli alanlar ana yoldan ayrılır, girip çıkmak sıkışma
   yaratmaz; bölüm denetimi (`tools/audit.py`) her değişiklikte temiz kalır.
6. **Ses ve yazı az:** sürprizler sözsüz anlatılır (hareket, ışık, kısa ses).
   Gizli odalarda en çok bir kısa satır.
7. **Kayıt:** bulunan sırlar `Settings.secrets` kümesinde (`bölüm:ad`); Defter'de
   "Sırlar n · daha fazlası saklı" (ilk sırdan sonra görünür; yer ve toplam
   söylenmez) ✅.

## Paket S1 · Küçük sürprizler (dünya karşılık verir) 🔶 (a, b, c ✅)

Birkaç saniyelik, gülümseten anlar. Hepsi bir kez olur (kayıtla), tekrar
denenince hiçbir şey olmaz; şakanın tadı buradan gelir.

| # | Sürpriz | Yer ve tetik | Ne olur | Altyapı | Emek |
|---|---|---|---|---|---|
| S1a | Söz dinlemeyen gölge | Yerebatan, ilk kontrol noktasından sonra; Sâye koşarken birden durur (önü üç kare açıksa, sakin anda) | Gölge iki adım daha gider, durur, Sâye'ye döner, utangaçça geri koşup yerine girer | Gölgenin ayrılıp dönmesi zaten var (`_ShadowMood.astray`); yeni bir "utangaç" hâli | ✅ |
| S1b | Taş bekçi | Nemrut, ilk kontrol noktasının yanında (26. sütun): ölüp dönen oyuncu her seferinde başka pozda bulur | Sâye arkasını dönünce figür poz değiştirir; üçüncü bakışta Sâye'nin duruşunu taklit eder (kavanoz tutan el) | Yeni küçük figür; Sâye'nin yönüne göre durum | ✅ |
| S1c | Gizli alkış | Oyunda tek dev perde var (Yerebatan); bulmaca çözülünce sahne boşalır: perdenin önünde zıpla, sonra çömel (seyirciye selam) | Perdenin ardında kavuklu, fesli seyirci gölgeleri belirir, alkışlar (`clap.wav`), kaybolur | `GiantPerde` | ✅ |
| S1d | Meraklı kedi (sonra) | Yerebatan, bir oyukta iki göz | Ateşböceği bırakılırsa kedi çıkar, ışığı kovalar, erişilmesi zor bir yere oturur (orada küçük bir hatıra) | Yeni hayvan çizimi ve kısa yol izleme | Orta |

## Paket S2 · Gizli odalar (içeride başka bir keyif)

Her oda ana parkurdan farklı bir duygu verir: oyuncak, müzik, rahat hareket,
hafıza. Her birinde bir **tasvir parçası** bulunur (S3).

### S2a · Yerebatan · Unutulmuş Gölgehane (ilk deneme) ✅

Uygulanan (`lib/game/golgehane.dart`, haritada sütun 45–62, satır 15–18):

- Yürüme yolunun sonundaki iki karelik boşluğun dibi taş değil, taş gibi
  boyanmış bir perde. Eskiden boşluğa düşen suda ölürdü; şimdi sahanlığa
  konar, perde aralanır. Suyun kendisi yine öldürür.
- Su, sahanlığın altında gerçekte olmayan kemeri ve içindeki kandil alevini
  dalgalanarak gösterir (gerçekçilik kapalıyken de).
- Yaklaşana (4,5 kare) içeriden kısık bir çan, dikişte bir parıltı: en çok
  15 saniyede bir, tehlike yokken.
- Aralanana dek oda dışarıdan taş görünür; ışığı sızmaz.
- İçeride: itilen kandil (yakın: dev gölge, uzak: küçük), rafta kuş, at,
  ejder; ↑ ile perdede canlanır. Üçü oynayınca ustanın tasvirinden parça
  belirir; alınınca sır ve hatıra satırı.
- Testler: `test/golgehane_test.dart`; önizleme
  `tools/preview/golgehane_test.dart`.

Özgün plan:


- **Keşif:** su yansıması, duvarda gerçekte görünmeyen bir kemeri gösterir.
  Yansıma zaten çiziliyor; kemer yalnız yansımada çizilir ("gölgede görünen ama
  gerçekte olmayan"). Kemerin önüne gelince duvar bir perde gibi aralanır. İlk
  sır olduğu için yansıma parlak ve kalıcı: herkes fark etsin.
- **İçeride:**
  - Ustanın eski çalışma odası: küçük bir hayal perdesi, raylı bir kandil,
    yerde üç küçük tasvir (kuş, at, ejder).
  - Kandili iterek Sâye'nin gölgesini devleştirir ya da küçültürsün.
  - Tasvirlere dokununca perdede canlanırlar; kuş uçar, at koşar, ejder kendi
    kuyruğunu kovalar.
- **Ödül:** ilk tasvir parçası ve bir hatıra satırı ("Ustam burada bana ilk
  tasvirimi kestirmişti…").
- **Altyazı:** `GiantPerde` ve `PerdeCord` (izdüşüm, kandil durakları), su
  yansıması (`terrain.dart _reflect`), tasvir çizimleri (`perde_kisi.dart`,
  `myth_shapes.dart`).
- **Emek:** orta.

### S2b · Ötüken · Kuş Meclisi

- **Keşif:** ana yoldan ters yöne uçan kuşlar ve yan dallardan gelen hafif ötüş.
- **İçeride:** dallar basılınca birer nota söyleyen kuşlar (hicaz dizisi).
  Bir kuşun söylediği kısa melodiyi tekrar edince bütün meclis birlikte öter,
  dallar çiçek açar.
- **Ödül:** ikinci tasvir parçası.
- **Altyapı:** nota sentezi (`tools/synth_ney.py`, `synth_solve.py`, hicaz
  dizisi), dal platformları (Ötüken'de yeni filizli dal çizimi).
- **Emek:** orta.

### S2c · Palandöken · Ayaz'ın Kaydırağı

- **Keşif:** karlı bir kemerin ardından sızan sıcak ışık.
- **İçeride:** ölüm cezası olmayan kısa bir kaydırak; havada dönüşler, kar
  bulutları, yumuşak iniş. Düşersen kaydırağın başına döner, ceza yok.
- **Ödül:** üçüncü tasvir parçası.
- **Altyapı:** kayak sistemi (`ski.dart`, yamaç verisi `kSkiPalandoken`); ayrı,
  kısa bir yamaç parçası.
- **Emek:** orta–yüksek (kayak yamaçları ayrı veriyle kurulu).

### Sonra (ilk üçün karşılanışına göre)

- **Kapadokya · Perilerin Oyunu:** bacanın penceresinde ışıklar sırayla yanar;
  perilerin hareketini taklit ettiğin kısa hafıza oyunu.
- **Konya · Küçük Sahne:** rüzgârda farklı sallanan perdenin ardında, gördüğün
  karakterlerin tasvirleriyle kendi kısa gölge oyununu kurarsın. Bu oda S3'ün
  oyun içindeki eşi olabilir.

## Paket S3 · Büyük sır · Kayıp tasvirler

- Gizli odalarda kaybolmuş tasvir parçaları bulunur. Her parça menüdeki
  **Küçük Sahne**ye (Hikâye'nin yanında) yeni bir figür getirir.
- Üç parça toplanınca figürler birlikte kısa, komik bir perde oynar:
  - Kandilci kendi gölgesinden korkar,
  - Hüdhüd ustanın sözünü keser,
  - Sâye perdeyi yanlış taraftan açar.
- Böylece keşfin ödülü yalnız sayaç artışı olmaz; oyuncunun dönüp bakmak
  isteyeceği bir şey büyür.
- **Altyapı:** perde çizimi (`perde.dart`, `perde_tasvir.dart`), Hikâye
  tiyatrosu (`story_theater.dart`) menü ekranı olarak örnek.
- **Emek:** orta (sahne ve kısa senaryo).

## Paket S4 · Kişisel ödüller (sonra)

Hatıra metninin yanında görünür küçük ödüller:

- Atkı rengi.
- Kavanozdaki ışığın görünüşü (ateşböceği yeşili, ay gümüşü).
- Özel bir selamlaşma hareketi (Sâye eğilir, tasviri gibi).

Bunlar için Ayarlar'da küçük bir "Sâye" sekmesi gerekir; S1–S3 karşılandıktan
sonra.

## Sıra ve doğrulama

1. **S1a, S1b, S1c:** hızlı, sevimli; keşif dilini öğretir. Önizleme, sonra
   oyunda.
2. **S2a Gölgehane:** girişin herkesçe bulunup bulunmadığı ilk denemede sorulur.
3. **S2b Kuş Meclisi.**
4. **S2c Ayaz'ın Kaydırağı.**
5. **S3 Küçük Sahne ve komik perde:** üç parça oyuna girince.
6. **S4 ve öteki odalar:** oyuncuların hangi odayı sevdiğine göre.

Her adımda:

- Telefon boyunda önizleme (yazı tipi yüklü).
- Bölüm denetimi temiz (ana yol bozulmaz, gizli oda sıkışma yaratmaz).
- Kayıt–yükleme: sır bir kez olur, yeniden doğunca tekrar etmez.
- Sürprizin tehlike anında tetiklenmediğini sınayan test.

## Bekleyen küçük düzeltmeler (ikinci incelemeden)

- **Kamera odağı:** odak sürerken tehlike doğarsa (kovalamaca, Karabasan) odak
  hemen bırakılsın.
- **Kandilci köprüsü:** sönmeden önce kısa titreme uyarısı ve yarım saniye pay.
- **Önizlemeler:** yazı tipi yüklenmeyen önizleme araçlarına yazı tipi eklensin.
