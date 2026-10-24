# Geliştirme planı (GELISTIRME_ONERILERI raporundan)

24 Ekim 2026. Rapordaki her öneri burada bir iş olarak duruyor: sırası, durumu
ve nasıl yapılacağı. İlke: önce küçük bir örnek ve önizleme, beğenilen yol
öteki bölümlere yayılır. Tehlike, düzenek ve bulmaca bilgisi her kalite
düzeyinde görünür; azaltılan yalnız süstür. Süre boş yürüyüşle değil kararla
uzar.

Durum: ✅ yapıldı · 🔶 kısmen · ⏳ sırada

## Paket 1 · Okunabilirlik ve tepkiler (bütün bölümler)

| # | Öneri | Uygulama | Durum |
|---|---|---|---|
| E2 | Düzenek çalışıyor: koldan kapıya bağ | Koldan kapıya kavisli ışık akışı, kapıda parıltı; kamera kapıya bakıp döner | ✅ |
| E2b | Başarıda tek, tanınabilir ses | Kapı tam açılınca hicaz dizisinden yükselen üç nota (`solve`), her düzenekte aynı | ✅ |
| E1 | Tehlike hazırlanıyor | Çürük tahtada büyüyen çatlak ve talaş; kopacak kayadan kırıntı; Yel'in uyarı evresi (çizgiler, uğultu) zaten var; güneş/şimşek uyarıları var | ✅ |
| E3 | Ateşböceği hedef buluyor | Uçuş izi; hedefe ulaşınca ışık halkası ve içe çekilen kıvılcımlar (dev, ocak); Kandilci fark edince fenerinden ışığa kesik bakış çizgisi | ✅ |
| E4 | Zemin teması | Taşta toz, karda kar tozu, sarnıcın ıslak taşında damla; karda solan ayak izleri | ✅ |
| E5 | Karabasan yaklaşıyor | Zerreler ona dönerek çekilir; ekranın onun yanı ve üst/alt kenarlar mesafeyle kararır; sarsıntı yalnız çok yakında ve hafif | ✅ |
| E6 | Yeni yol açılıyor | Kapı açılınca çözüldü sesi ve açılan yol boyunca ileri akan ışık | ✅ |
| V1 | Karakter–zemin ayrımı | Ayak altında ılık ışık; uçurum ve mağara temalarında (Kule, Derinkuyu…) basılabilir yüzeyin üst kenarı; öteki temalarda kenar zaten seçiliyordu (tarandı) | ✅ |
| E1b | Rüzgâr geliyor | Yel'in uyarı evresinde otlar soluğun yönüne eğilmeye başlar, eserken yatar ve titrer (Göğün Katları) | ✅ |
| E2c | Kol ile kapı bağlı | Kapının üstünde makaraya çıkan zincir: kol çekilince gerilir, titrer, lentodan toz dökülür; kapı kalkarken zincir sarılır, makara döner | ✅ |
| L1 | Yumuşak ışık | Sâye'nin ışığı kayada yarı gölgeyle kesilir; fenerci, gözcü, Medusa huzmeleri uzaklıkla söner, kenarları kademeli | ✅ |
| E7 | Ne yapılacağı belli olsun | Kullanılabilen nesnenin (ip, kol, vana, körük…) önüne gelince Sâye'nin başı hizasında, nesnenin üstünde "↑" işareti; Yerebatan perde ipi ilk çekilene dek turuncu püskül ve ipten süzülen ışık tanesiyle kendini gösterir | ✅ |
| K1 | Kamera odağı: ne yaptım, ne değişti | Sebep ve sonuç bir ekrana sığıyorsa kamera aralarına geçip hafifçe açılır (ip–perde, kol–kapı); sığmıyorsa sonuca gider, kapı açılıp yolda ışık akana dek bekler, döner; vana hazneyi gösterir; gölgeyi gören Kandilci ile gölge birlikte; manzara anları (V6); kovalamacada odak yok | ✅ |
| Y1 | Yazı yer kaplamasın | Uzun yazı cümle cümle akar, ekranda en çok iki satır; olay sözleri tek kısa satır (ayrıntı efsane kartında); düzenek şiirleri oyun ekranından kalktı; ipucu simgesi küçük, uzaklaşınca söner | ✅ |
| S1 | Ses ve his | Ölümde hüzünlü kısa ney cümlesi (hicaz, karara iner); fener ışığında cam tek çatlakla kırılır; saklanınca ekran kararır (gri değil); Kandilci kâğıt gibi değil, ortada yön değiştirerek döner; toz yalnız yüksekten inişte, ayrı zerreler | ✅ |

## Paket 2 · Gölgeyi göndermek (yeni mekanik A) ✅

Gölge taşında (yere gömülü, tasvir oyulmuş taş; gönderilebilirken ışır) ↑:
Sâye'nin gölgesi ondan ayrılır, baktığı yöne yürür (parmaklıktan geçer;
duvarda, uçurumda, suda durur), oyalanır, döner; bu arada Sâye'nin gölgesi
yoktur. Kandilci gölgeyi fenerinin baktığı yerde görürse ona yürür, gölge
yürüdükçe peşinden gider ve gölgeye dalmışken çocuğu görmez. Kamera
Kandilci ile gölgeyi birlikte gösterir. İlk karşılaşmada ipucu.

- Derinkuyu: iki Kandilcinin tek saklanma sütunlu koridoru (tanışma).
- Şeb-i Arûs (Konya): iki Kandilcili koridor (yineleme; saklanarak da geçilir).
- Testler: her iki bölümde gölge Kandilciyi oyalar, Sâye yakalanmadan geçer,
  gölge döner (`test/golge_gonder_test.dart`).
- Sonra düşünülebilir: gölgenin bir basınç taşına basıp kapı açması (Sâye'nin
  giremediği parmaklık ardında); bunun için yeni bir oda gerekir.

## Paket 3 · Kandilci yolu (yeni mekanik B) ✅

Soğuk ışık tahtaları yalnız Kandilcinin feneriyle (hale ve koni) belirir;
Sâye'nin sıcak ışığı göstermez. Gökyolu'nun Kandilcilerin gök kampında 8
karelik boşluk: ateşböceği atılınca Kandilci kenarda ona dalar, feneri yolu
gösterir, Sâye onun ışığında geçer. Sağanak boşluğun üstünde (kanat ıslanır,
süzülerek aşılmaz); önünde kontrol noktası ve ateşböceği; yolun ucunda
dinlenme otu. Karşı yakadaki Kandilci kaldırıldı (köprüde saklanacak yer
yoktu). Testler: sıcak ışık yolu yakmaz; ateşböceğiyle geçilir
(`test/kandilci_yolu_test.dart`).

## Paket 4 · Kurtarılan ışığın dünyada izi (D) ve görsel kimlik

| # | Öneri | Uygulama | Durum |
|---|---|---|---|
| D | Kurtarılan ışık | Açılan her kapının iki yanındaki kandiller sırayla tutuşur, yanık kalır, çevresini aydınlatır; kayıtla açık gelen kapıda da yanık. (Dal yeşermesi, uzak siluet: sonra) | 🔶 |
| V2 | Bölümün görsel imzası | Temalar zaten ayrık (Yerebatan bakır/kehribar, Nemrut gece moru, Ötüken yeşil, Erlik mor); manzara anları imzayı güçlendirir | ✅ |
| V5 | Oyuncu ölçeğinde hareket | Ak Geyik dururken ara sıra kulağını sese çevirir; Kandilci durunca ya da ararken fenerini kaldırıp yoklar; Sâye yüksekten inişte daha derin çöküp toparlanır | ✅ |
| V6 | Büyük manzara anları | Kule'nin tepesinde Haliç (kubbeler, minareler, yangın ışığı, suda titreyen kandiller, hilal); Gün Doğumu'nun son terasında tanrı başları arasından yükselen güneş; Ötüken'in yüksek kayasında açılan vadi ve ırmak. Kamera açılır, yukarı bakar, yer adı yazılır; bir kez | ✅ |
| V4 | Mekâna özgü platformlar | Gökte bulut (vardı); Ötüken'de filizli, kabuklu dal; Nemrut'ta kırık kaide taşı (tahta olan yerde); basılan üst kenar aynı yerde | ✅ |
| V3 | Hayal perdesi malzemesi | Önemli karakterlerde deri tasvir hissi, eklem bağlantıları, ışık geçiren bezemeler; ortak çizgi kalınlığı | ⏳ |
| R | Renk tek başına kural anlatmasın | Tehlikeli ışıkta (Kandilci, gözcü) fenerden dışa akan tarama halkaları; sıcak güvenli ışıkta desen yok. (Ötüken/Erlik giriş karşılaştırması: sonra) | 🔶 |

## Paket 5 · Parkur yenilemeleri (eski bölümler)

Her mekanik: güvenli tanışma → başka mekanikle birleşme → kısa baskı altında
uygulama. Kanat, sarmaşık ve atlayış sınırları her kesitte denetlenir;
istemsiz süzülme kestirmesi kapatılır; kanadın kapandığı yerin nedeni önceden
gösterilir. Seçilmiş alanlarda iki anlaşılır çözüm.

| Bölüm | Yenileme | Durum |
|---|---|---|
| Yerebatan | Suyu yükseltince üst geçit açılır, alt saklanma cepleri kapanır | ⏳ |
| Kule | Uzun zincir tırmanışlarına üç dinlenme balkonu (yalnız ekleme). Çan sarkaçları yok: çan sesi Kandilciyi çağırıyor, dinlenme yerini tuzağa çevirirdi | 🔶 |
| Kaf / Peri | Ayna hem kapıyı açar hem geçici basamağı aydınlatır; küçük döngü | ⏳ |
| Nemrut | Devin hareketi bir taşın dengesini değiştirir; önce izlenir, sonra geçici yol | ⏳ |
| Palandöken / Çığ | Güvenli ana hat ve hatıralı zor yan hat; ileride birleşir | ⏳ |
| Ötüken | Geyiğin bekleyeceği güvenli duraklar; aynı sarmaşık dizilimi azalır | ⏳ |
| Göğün Katları | İki kuralı birleştiren kısa geçişler; her katta dinlenme terası | ⏳ |

Kalanlar bölümlerin akışını ve zorluğunu değiştirir (yeni oda, kaldırılan ya
da taşınan engel): önce oynanarak ölçülmeli. Her biri için önizleme ve
oynanış testiyle tek tek ele alınacak.

## Paket 6 · Yeni bölümler ve final

Her biri tam bir bölüm (10–15 dk): harita, perde, anlatım ve seslendirme,
efsane kartları. Paket 5'ten sonra, bölüm bölüm.

- **Tulpar'ın Yolu:** bulut koridoru → Anadolu üzerinde sakin süzülüş → kontrollü iniş; kendi ritmi ve görüş mesafesi. ⏳
- **Tuz Gölü (C):** gece gölündeki yansıma görünmeyen basamakları gösterir; rüzgâr kesilince su durulur; ilk sürümde yalnız gösterir. Tulpar yoldaş. ⏳
- **Yeşil Kubbe:** Kandilcilerin arasından geçiş → ışık ve gölgeyle halka düzenini bozma → öğrenilmiş mekaniklerle son tırmanış; Konya bitişinden geçiş yazılır. ⏳

## Doğrulama (her paket)

- Önizleme kareleri (telefon boyu) ve testler; kaydet–yükle, 60/120/144 Hz.
- Ölümden sonra zor noktaya 20–30 sn'de dönüş; zor kesitlerde ölçülür.
- Düşük grafikte tehlike/bulmaca bilgisi korunur; kare süresi ölçülür.
