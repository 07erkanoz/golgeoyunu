# Gölge Oyunu — Çizgi Film Doku, Işık ve Karakter Görünümü Belgesi (`doku.md`)

Bu belge; oyuna **2D animasyon film / çizgi film (cel-shaded & el çizimi illüstrasyon)** hissi kazandırmak, **Sâye** karakterinin karanlıkta kaybolmasını önleyip mat-kadifemsi bir karakter dokusuna kavuşturmak ve çevre/zemin/atmosfer katmanlarını zenginleştirmek için yapılan tüm teknik değişiklikleri ayrıntılı olarak açıklar.

---

## 1. Sâye Karakter Görünümü ve Mat Dokulama (`lib/game/kukla.dart`, `lib/game/player.dart`)

### 1.1. Simsiyah Siluetten Doğal Mat İs-Antrasit (Matte Charcoal-Soot) Tonlamaya Geçiş
Önceki durumda Sâye'nin tüm ana uzuvları (`bas`, `govde`, `kolF`, `bacakF`, `orgu`) `0xFF07050F` (`RGB(7, 5, 15)`) gibi soğuk/zifiri siyah bir renkle boyanıyordu. Bu durum Sâye'nin sıcak taş/sarnıç dokusu önünde keskin bir siyah delik gibi görünmesine yol açıyordu.

Yapılan değişiklikle (hiçbir morumsu/mavi alt ton olmadan, tıpkı duvardaki gölgenin doğal mat is tonu gibi):
- **Ana Mat Baz Tonları (`SayeKukla`):**
  - `ink`: `0xFF07050F` yerine doğal mat is-antrasit siyahı (`0xFF181514`).
  - `far` (arka kol ve arka bacak): İki bacağın ve kolun birbirine karışmaması için bir ton açık mat antrasit (`0xFF24201E`).
  - `red` (atkı, düğüm ve saç kurdelesi): Sıcak kiremit-kızıl (`0xFFC2402E`).
- **Parça Bazlı Mat Işık Geçişi (`SayeKukla.paint`):**
  - Sâye'nin elbisesi (`govde`), başı (`bas`), ön kolu (`kolF`), ön bacağı (`bacakF`) ve saç örgüsü (`orgu`) düz zifiri siyah yerine, kavanoz ışığının geldiği sağ-ön yöne doğru hafifçe ısınan **doğal mat is-kömür gradyanı (`ui.Gradient.linear`)** ile boyanır:
    - `govde`: `0xFF1A1715` → `0xFF26201C`
    - `kolF` / `bacakF`: `0xFF1D1917` → `0xFF29231E`
    - `bas` / `orgu`: `0xFF171413` → `0xFF211C19`
  - Çömelme/saklanma (`_hide`) durumunda bu sıcak mat aydınlanma doğal biçimde kısılır.

### 1.2. Elbise Dolgusu ve Çiçek İşlemeleri (`govde`)
- `saye_a1.json` içindeki `govde` katmanı 27 halkadan (1 dış elbise konturu + 26 iç çiçek/yaprak oyması) oluşur.
- Gölge çiziminde (`paintSolid`) ve normal çizimde (`paint`) `PathFillType.nonZero` kullanılarak elbisenin iç dolgusu tam ve kesintisiz hale getirildi.
- Elbisenin göğsündeki ve etek ucundaki 26 iç çiçek/yaprak motifi (`Layer.innerPath`), kavanoz ışığıyla parlayan **sıcak fildişi-altın (`rgba(255, 236, 184, 0.82)`)** renginde ayrıca çizilir.

### 1.3. Çizgi Film Cel-Shading Konturları
- **Ön Kol, Ön Çizme ve Saç Örgüsü (`kolF`, `bacakF`, `orgu`):** Gövdenin önünde kaybolmamaları için kendi geometrileri içinde kırpılmış (`clipPath`) `0.42px` kalınlığında sıcak altın (`0xFFFFD88A`) iç kenar ışığı alır.
- **Atkı ve Kurdele (`atki`, `dugum`, `kurdele`):** Üst kenarlarında `0.45px` sıcak mercan (`0xFFFF8A6A`) çizgi film konturu taşır.
- **Sıcak Arka Kontur (`rim`):** Kavanoz yönüne bakan ön yüzeyde `0xFFFFE49C`, sırt tarafında `0xFFFFD280` ince kontur ile Sâye'nin yüz profili (burun, çene, kirpik/göz) arka plandan net biçimde ayrılır.

### 1.4. Ateş Böceği Kavanozu ve Yörüngedeki Ateş Böcekleri (`_paintJar`)
- **Ölçek ve Detay:** Kavanoz ölçeği `1.92x` olarak büyütüldü; sol yanına parlak cam yansıması (`strokeCap: StrokeCap.round`), üstüne ise iki kademeli metal kapak ve 3 dikey kapak tırtığı eklendi.
- **Çift Katmanlı Sıcak Hale:** Kavanozun arkasında `42` ve `18` yarıçaplı iki sıcak kehribar-altın radyal ışık halesi ve Sâye'nin baş/gövde arkasında `30` yarıçaplı arka aydınlatma (`bodyBack`) oluşturuldu.
- **Uçuşan Canlı Ateş Böcekleri:** Kavanozun içindeki 2 ateş böceğine ek olarak, kavanozun hemen dışında eliptik yörüngede (`math.cos` / `math.sin`) dönen ve yanıp sönen **3 canlı ateş böceği parıltısı** eklendi.

### 1.5. Sâye ve Duvar Gölgesi Oranları (`lib/game/player.dart`)
- Sâye'nin görsel kukla ölçeği `_kuklaVisScale = 1.06` olarak çocuk oranlarında tutuldu.
- Duvardaki gölgesinin (`_wallShadow`) ölçeği `(1.45, 1.70)` değerinden `(1.18, 1.30)` değerine çekilerek Sâye'yi ezmemesi, ancak arkasında zarif bir sarnıç gölgesi olarak kalması sağlandı.

---

## 2. Çizgi Film Zemin, Tuğla ve Sütun Dokuları (`lib/game/terrain.dart`)

### 2.1. Bombeli Kaldırım Taşları ve Renkli Tuğla Örgüsü (`_cartoonStone`)
Önceki durumda `Cartoon.on` açıkken zemin yüzeyi cetvelle çizilmiş düz beyaz/bej bir şerit (`Rect`) ve altındaki tuğlalar tek renk düz bir ızgara olarak çiziliyordu; ayrıca `depth >= 3` sonrasında çizim kesildiği için ekranın alt kısmında düz siyah/lacivert bir boşluk oluşuyordu.

Yapılan değişiklikler:
1. **Yuvarlatılmış Kaldırım Taşları (Flagstones):**
   - Üst yüzey (`top == true`) karolarında düz şerit yerine her karoda 2 adet yuvarlatılmış köşeli (`RRect`, `Radius.circular(3.2)`) bombeli kaldırım taşı çizilir.
   - Her taşın kendi sıcak ton varyasyonu (`Cartoon.lip` ↔ `Cartoon.lipHot` / `Cartoon.stone`), üst kubbe parıltısı, alt gölge kesiği ve koyu dış çizgi film konturu vardır.
   - Taşların birleşim derzlerine `%58` olasılıkla **minik yeşil-altın sarnıç yosunu (`0xFF7CA850`)** kümeleri eklendi.
2. **Derinlikli ve Ton Farklılıklı Çizgi Film Tuğlaları:**
   - Tuğla örgüsü `depth < 5` derinliğe kadar uzatıldı.
   - Her tuğla düz çizgiyle bölünmüş tek renk zemin yerine, kendi `RRect` (`Radius.circular(2.6)`) dolgusu, sıcak pişmiş toprak / kehribar / koyu derz ton kayması (`warmShift`) ve üst kenar pah ışığı (`Cartoon.lip`) ile ayrı ayrı çizilir.

### 2.2. İşlemeli Sütunlar ve Kemer Kilit Taşları (`_cartoonColumn`, `_cisternVaults`)
- **Tavan Kemerleri (`_cisternVaults`):**
  - Kemer yaylarına çift katmanlı sıcak ışık kenarı (`Cartoon.archRim` + `Cartoon.lipHot`) ve kemer boyunca dizilmiş **7 adet radyal kemer taşı derzi (voussoir / kilit taşı)** eklendi.
- **Sütunlar (`_cartoonColumn`):**
  - Başlıklara **kıvrımlı Bizans volüt halkaları** eklendi.
  - Sütun gövdesine her `80px` aralıkla yatay **taş tambur birleşim derzleri** ve üst ışık çizgileri eklendi.
  - Yerebatan sütunlarındaki **tavus gözü (gözyaşı) madalyonlarına** koyu iç dolgu (`eyeFill`) ve iç sıcak altın parıltı beneği (`Cartoon.lipHot`) eklendi.

### 2.3. Su Yüzeyinde Kavanoz Yansıması (`WaterSurface._reflect`)
- Sâye su kenarında yürürken veya suyun üstünden geçerken, ateş böceği kavanozunun sıcak altın ışığı (`0xFFFFC868`) su yüzeyinde 5 kademeli dalgalanan yatay ışık şeridi olarak yansır.

---

## 3. Atmosfer, Arka Plan Kemerleri ve Hacimsel Işık (`lib/game/atmosphere.dart`, `lib/game/realism.dart`, `lib/game/lighting.dart`)

### 3.1. Arka Plan Sarnıç Kemerleri (`_cartoonCistern` — `lib/game/atmosphere.dart`)
Arka plandaki 3 paralaks kemer katmanı düz mor-kahve dikdörtgenlerden zengin bir çizgi film sahnesine dönüştürüldü:
- **Sütun Işık Şeridi ve Tambur Halkaları:** Her arka plan sütununun sol kenarına ışık şeridi (`colEdge`), gövdesine yatay taş halkaları, üst ve altına yuvarlatılmış (`RRect`) kademeli başlık ve kaide eklendi.
- **Titreyen Sıcak Duvar Kandilleri:** Orta ve yakın arka plan katmanlarındaki (`layer >= 1`) sütunlara zamana bağlı titreyen (`flicker`) sıcak kehribar duvar kandilleri (`0xFFFFB858` hale + `0xFFFFF2B8` alev çekirdeği) yerleştirildi.
- **Sarkan Sarmaşık ve Yosun Filizleri:** Kemer yaylarından aşağı sarkan ve hafifçe salınan (`math.sin(_t * 1.6 + ...)`) kıvrımlı sarmaşık/yosun çizgileri eklendi.
- **Katmanlar Arası Sıcak Sis Kuşağı:** Her kemer sırasının tabanına 3 renkli (`colorStops: const [0.0, 0.5, 1.0]`) yumuşak kehribar sis geçişi eklendi.

### 3.2. Çok Telli Hacimsel Işık Perdeleri ve Parıldayan Tozlar (`RealismLayer._drawGodRays` — `lib/game/realism.dart`)
- `RealismLayer` (`priority: 42`), `LightingLayer` (`priority: 40`) karanlık örtüsünün üzerinde çalışır.
- Her ışık demeti tek bir kaba yamuk yerine, **3 ince ışık telinden oluşan (`BlendMode.screen`) yumuşak bir ışık perdesi** olarak çizilir.
- Işık perdelerinin içinde yukarı-aşağı süzülen ve ışığın ortasından geçerken parıldayan (`BlendMode.plus`) **altın toz zerreleri** bulunur.
- Sâye'nin kendi kavanoz ışığı `isPlayer = true` olarak işaretlenerek, Sâye'nin tam üstüne binen `BlendMode.plus` sis topu atlandı; böylece Sâye'nin mat renkleri ve elbise işlemeleri puslanmadan net kalır.

### 3.3. Karanlık Katmanı Merkez Açıklığı (`LightingLayer._occluded` — `lib/game/lighting.dart`)
- Yumuşak gölge (`SoftEdge.on`) açıkken 6 çevre noktasından yapılan taramaya ek olarak, tam merkezde `0.72 * radius` yarıçaplı güçlü bir `dstOut` kesimi uygulanır; böylece karanlık örtü Sâye'nin ve kavanozunun üstünü karartmazken duvar kenarlarındaki yumuşak yarı-gölge (penumbra) korunur.

---

## 4. Hareket Dinamikleri ve Kamera (`lib/game/player.dart`, `lib/game/golge_game.dart`)

- **Squash & Stretch (Esneme ve Basılma):** Zıplama anında dikey uzama (`+13%` boy, `-8%` en) ve yere inişte (`_landDip`) yumuşak basılma (`-14%` boy, `+11%` en).
- **Yön Değiştirme (Turnaround) Yaylanması:** Sâye sağa/sola dönerken `85ms` süren hızlı yatay perspektif geçişi (`_turnT`).
- **Ayak Tozu ve Ateş Böceği İzi:** Koşarken, zıplarken ve yere inerken ayak altından çıkan çizgi film toz bulutçukları (`_dust`) ve hızlı harekette kavanozun arkasında süzülen sıcak altın ışık izi (`_jarTrail`).
- **Dinamik Kamera (`GolgeGame._updateCamera`):** Koşu yönüne doğru yumuşak kamera öngörüsü (`look-ahead`) ve dururken `1.04x`, koşarken `0.985x` nefes alan sinematik yakınlaştırma (`zoom`).

---

## 5. Ayarlar ile Etkileşim (`lib/settings.dart`)

| Ayar | Kod Karşılığı | Görsel Etkisi |
| :--- | :--- | :--- |
| **Renk ve doku** | `Cartoon.on` (`Settings.texture`) | Bombeli kaldırım taşları, renkli tuğla örgüsü, işlemeli sütunlar, arka plan kandilleri/sarmaşıkları ve Sâye'nin sıcak sahne uyumunu açar/kapatır. |
| **Işık ve derinlik** | `Realism.on` (`Settings.realism`) | Çok telli ışık perdeleri (`God rays`), ışık içi altın tozlar, sütun/zemin kenar ışıkları (`rim light`), su üstü kavanoz yansıması ve paralaks derinlik katmanlarını açar/kapatır. |
| **Ton** | `Cartoon.tone` (`Settings.tone`) | Tuğla, kaldırım taşı, kemer ve arka plan sarnıç renklerinin sıcaklığını/tonunu canlı olarak kaydırır. |
| **Parlaklık** | `Settings.brightness` | `LightingLayer` karanlık örtüsünün yoğunluğunu ayarlar. |
| **Grafik (Düşük/Yüksek)** | `Settings.lowGraphics` | Düşük grafik seçildiğinde performans için parçacık izleri, kandil parıltıları ve çoklu ışık taramaları otomatik olarak sadeleştirilir. |

---

## 6. Değiştirilen Dosyalar Özeti

- `lib/game/kukla.dart` — Sâye mat-kadife renk paleti, yönlü mat gradyan, elbise çiçek işlemeleri, cel-shading konturları, büyütülmüş ateş böceği kavanozu ve kavanoz çevresinde uçuşan 3 ateş böceği.
- `lib/game/player.dart` — Sâye ve duvar gölgesi ölçek dengesi, squash & stretch, dönüş yaylanması, ayak tozu ve kavanoz ışık izi.
- `lib/game/terrain.dart` — Bombeli kaldırım taşları, taş arası yosunlar, ton farklılıklı yuvarlatılmış tuğlalar, Bizans sütun volütleri/madalyonları, kemer taşları ve su üstü kavanoz yansıması.
- `lib/game/atmosphere.dart` — Arka plan kemerlerinde titreyen duvar kandilleri, sarkan sarmaşıklar, taş halkalı sütunlar ve katmanlar arası sıcak sis kuşakları.
- `lib/game/realism.dart` — Çok telli hacimsel ışık perdeleri (`_drawGodRays`), parıldayan altın toz zerreleri ve Sâye ışık merkezi koruması.
- `lib/game/lighting.dart` — Sâye ve kavanoz çevresinde merkez karanlık örtüsünün tamamen açılması.
- `lib/game/golge_game.dart` — Hıza duyarlı dinamik kamera zoom ve bakış yönü öngörüsü.
- `lib/settings.dart` — Varsayılan doku/derinlik ayarları ve eski kayıt taşıması (`_version = 4`).
