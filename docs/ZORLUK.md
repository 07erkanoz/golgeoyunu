# Zorluk Taraması (22 Ekim 2026)

On yedi bölümün haritası, düzenekleri ve testleri tek tek okundu, sıçrama ve hız
sınırları fizik sabitlerinden hesaplandı. Puanlar 1 (çok kolay) – 5 (çok zor).

## 1. Düzeltilenler (karar gerektirmeyen mantık hataları)

| Bölüm | Hata | Düzeltme |
|---|---|---|
| Yerebatan | Hazne boşaltıldıktan sonra beklenince Su İyesi dipten, ekranın dışından çıkıyordu; yalnızca yazı görünüyordu | Yalnızca hazne doluyken ve su yüzü ekrandayken çıkar |
| Hepsi | İpten atlayınca aynı ipe geri tutunuluyordu | Bırakılan ip 1,2 sn (ya da yere basana dek) tutulmaz |
| Nemrut, Gün Doğumu, Kar Yolu | Gevşek kayaların hepsi bölümün 5. saniyesindeki ilk depremde birden düşüyordu; oyuncu vardığında tepede taş kalmıyordu | Deprem yalnızca yakındaki kayaları düşürür |
| Gün Doğumu | Üç ateşböceği havada bekletilip dev sendeleyince hep birden kulağa giriyordu; aynı karede iki vuruş çift köprü kuruyordu | Sendelerken kulağına geleni savurur, karede tek vuruş |
| Nuh'un Gemisi | Ambar kuyusundaki tahtalar iki sütunda üst üste biniyordu: kuyu dümdüz zıplanarak çıkılıyordu | Zikzak; her satıra yana sıçranır |
| Kar Yolu | Handaki çan tavanda, yerden 6,5 kare yukarıdaydı: hiç çalmıyordu | Zincirle sarkar, altından koşan çalar |
| Kar Yolu | Göldeki ateşböceği rafı 5 kare yukarıda, ulaşılamaz | Alçaldı |
| Gökyolu | Yan raftaki ateşböceği akımın 10 kare üstünde, ulaşılamaz | Raf akımın tepesine alındı |
| Kaf | Aynanın ışığı üç Gözcü'yü birden, kalıcı kör ediyordu | Asılı kristal ışığı ilk Gözcü'de durdurur |
| Kaf | "İki Gözcü'nün süpürdüğü köprü"de ikisi de sola bakıyordu | Yakın iki Gözcü birbirine, aradaki köprüye bakar (geçiş penceresi ~%40) |
| Erlik | Fener balonunun ışığı köprüye inmiyordu; "Işık köprüyü de seni de bulur" yanlıştı | Fener alçaldı; oyuklarda beklenip zamanlamayla geçilir |
| Göğün Katları | Hüma bölüm açılınca uçmaya başlıyordu; varınca 20 sn beklemek gerekebiliyordu | Sâye yaklaşınca uçar |
| Derinkuyu | "Kandilci geçemez" alçak kemer iki kare açıktı | Tek kare |
| Peri Bacaları | Uçhisar'ın dinlenme oyukları yanlış sütundaydı, sarmaşığı üç yerden kesiyordu | Oyuklar kayanın içinde |
| Şeb-i Arûs | Avluda hiçbir yere varmayan zincir | Kaldırıldı |

## 2. Neden her şey kolay geliyor: genel sebepler (karar bekliyor)

Bölümler tek tek kolay değil; birkaç genel kural her bölümü kolaylaştırıyor:

1. **Kanatlar her yerde açık.** Kule'den sonra her bölümde (yeraltı hariç) süzülme var:
   rüzgârsız havada ~9 kare. Atlama boşluklarının çoğu 2–7 kare, yani hepsi süzülerek
   geçiliyor. Derinkuyu bir mağara olduğu hâlde orada da kanat açılıyor.
   - Seçenekler: (a) bazı bölümlerde kanatları kapatmak (Derinkuyu, Ergenekon, Göğün
     Katları'nın yürüme kısımları); (b) yalnızca belirli boşlukların üstüne "sağanak"
     (kanatları ıslatan, zaten var olan bölge) koymak; (c) bölüme karşı rüzgâr.
   - Önerim: (b) + Derinkuyu için (a). Boşluk tasarımları ancak böyle anlam kazanır.
2. **Kandilciler Sâye'den yavaş ve kısa.** Kovalama hızı 130, Sâye 160; boyları 50 px,
   zıplayış 88 px. Kaçmak ya da üstünden atlamak her zaman işe yarıyor; gizlenmek
   gereksiz.
   - Öneri: gizlenmenin şart olduğu koridorlara iki karelik tavan (Kandilci atlanamaz),
     kovalama hızı ~170 (kaçış artık her zaman kurtarmaz). Kurtlar da (150) Sâye'den
     yavaş: ~175.
3. **İpuçları çözümü söylüyor.** "Kefeye sandık koy, öbürü yükselir", "kulağına üç
   kez ateşböceği sal" gibi. Bulmacalar öğretici bölüm gibi oluyor.
   - Öneri: ipucu düzeneği tanıtsın, çözümü söylemesin ("Kefeler birbirine bağlı"
     gibi). İlk karşılaşmada ipucu kuralı korunur.
4. **Tehlikeler yalnızca durana zarar veriyor.** Çöken kaya 0,55 sn, ince buz 0,7 sn,
   sarkıt ve gevşek kaya altında beklemek gerekiyor. Koşan hiçbirine yakalanmıyor.
   Karanlık bölgeler de koşana hiç zarar vermiyor.
   - Öneri: ince buz 0,25 sn, çöken kaya 0,35 sn; karanlık bölgelerde ateşböceği
     azaltmak.
5. **Bölümler kısa.** Temiz bir oyun çoğu bölümde 2–6 dakika (hedef 10–15).
6. **Aynı düzenek tekrar ediyor.** Peri Bacaları'nda 17 baca aynı sarmaşıkla, 9 ip aynı
   aralıkla; Nemrut sonunda üç aynı Kandilci + ot düzeni.

## 3. Bölüm bölüm

| Bölüm | Bulmaca | Atlama | En zayıf yer | Önerilen ilk iş |
|---|---|---|---|---|
| I Yerebatan | 2 | 1–2 | Sütun ormanının çatısı gizlenmeyi atlatıyor; sal kanalı manzara | Orman ve dar geçide alçak tavan (Kandilci atlanamaz, ateşböceği şart) |
| II Kule | 2 | 1–2 | ~100 kare düşünmeden zincir tırmanışı; çan katı süzülerek atlanıyor | Zinciri sıçramayla bölmek; çan katına sağanak |
| III Gökyolu | 1–3 | 1 | Balon geçidi süzülerek geçiliyor | Karşı rüzgâr ~90; Güneş Kapısı'na alçak tavan |
| IV Kaf | 2 | 1–2 | Ayna salonu "üç aynayı çevir" ile kaba kuvvetle çözülüyor | Bir aynayı ters başlatmak; Gök Postası'na tavan |
| V Ağrı | 1 | 2–3 | Bulmaca yok; ipler tek beceri | İplere tipide yan rüzgâr; ağılda alçak tavan; çanın sesi sarkıtları sarssın |
| VI Nuh'un Gemisi | 2 | 1–2 | Tufan kuyusu (düzeldi), karanlık bölge zararsız | Tufanı hızlandırmak (30→50 px/sn); terazide "kendi ağırlığın da sayılır" |
| VII Nemrut | 2 | 1–2 | Horoskop taşları tek tek parlıyor: kabartmaya bakmadan deneme yanılmayla çözülüyor | Parlama yalnızca hepsi doğru olunca; kabartma ipucu olsun |
| VIII Gün Doğumu | 1 | 1 | Taş devi | Aşağıdaki Taş Devi tasarımı |
| IX Kar Yolu | 2 | 1–2 | Kurtlar ve ince buz koşana zararsız | Kurt hızı 175, ince buz 0,25 sn, çan şimdi işliyor: Kandilcileri kola çeksin |
| X–XI Kayak | — | 2 | Çığ temiz kayana hiç yetişmiyor; kayalar inişlerden uzak | Çığ tavanı 540; arka arkaya iki takla uçurumu |
| XII Peri Bacaları | 2 | 1–3 | 17 baca aynı, altta çukur yok | Bazı bacalarda sarmaşığı kaldırıp halkayı şart koşmak, altlarına çukur; vadiye sağanak |
| XIII Derinkuyu | 2 | 1–2 | Sürgü taşı atlanabiliyor; havalandırma bacasında düşmek zararsız | Şapeli bir sıra derinleştirip taşı şart koşmak; baca dibine diken |
| XIV Erlik | 1–3 | 1 | Körmösler yalnızca hiç kıpırdamayanı yakalıyor | Yakın mesafede çömelene de baksın, hız 84→125; ateşböceği şart olsun |
| XV Ergenekon | 2–3 | 1 | Kanatla eriyik kanalları süzülüp geçiliyor; sahte körükler zararsız | Kanat kapalı; yanlış körük zinciri bozsun |
| XVI Göğün Katları | 1–2 | 1–2 | Ay tahtaları ve Tulpar uçuşu düz bir çizgiyle geçiliyor | Ay tahtalarına fener; Ülgen'in kapısına ayna kilidi; fırtınayı hızlandırmak |
| XVII Şeb-i Arûs | 2–3 | 1–2 | Kol kapısı sandıksız da tutunarak açılıyor | Rafları bir sıra yükseltmek (sandık şart); ışık seli zaten iyi |

En iyi işleyen yerler (korunmalı): Gökyolu'nun gölge köprüsü, Ergenekon'un ikinci
ocağı, Konya'daki ışık seli ve semâhane, Erlik'in fenerli köprüsü (yeni hâli).

## 4. Taş Devi (Gün Doğumu) — sahne değişmeden

Senin yönün: dev taş atsın, kaçmak gereksin; üç ateşböceği zor ama imkânsız değil.
Arena aynı kalır (iki raf, sarmaşıklar, kapılar). Önerilen döngü:

1. **Yürür** (~3,5 sn): Sâye'nin bulunduğu rafa doğru gelir, ~6 kare önünde durur.
2. **Taş kaldırır** (1,5 sn): yere düşeceği yer halka olarak belirir, atıştan ~0,6 sn
   önce Sâye'nin yerine kilitlenir. Taş halkaya düşer; rafın bir karesini kırabilir.
3. **Toparlanır** (1,4 sn): kulağı ancak bu sırada açıktır. Önceden atılan ateşböceği
   savrulur. Böcek uçuşu ~0,9 sn olduğundan atış, taş havadayken yapılmalı: önce at,
   sonra halkadan kaç.
4. **Her vuruştan sonra öfkelenir:** 2. evrede iki taş, 3. evrede üç taş ve daha kısa
   pencere; adımları raf üstündeki kayaları düşürür.
5. **Ateşböceği kıt:** arenada başta 2, raflarda yavaş dolan birer kaynak. Kaçan
   böcek bir kayıp.

Ayrıca: ezme alanı bacaklar kadar daraltılır; ipucu "kulağına üç kez sal" yerine
"Dev'in kulağı yalnız bir an açık" gibi olur.

## 5. Alevli baca + sandık düzeneğinin ileri biçimleri

Kule'deki baca–sandık fikri sonraki bölümlerde daha karışık kullanılabilir:

- **Ergenekon tırmanışı:** eriyik yükselirken kat kat bacalar; tek sandık var, hangi
  bacayı tıkayacağını seçmek gerekiyor (biri yolu açar, biri körüğe sıcak verir).
- **Derinkuyu havalandırma bacası:** sandığı yukarıdan bırakınca aşağıdaki bacayı
  tıkar; yanlış bacaya düşerse sandık yanar ve yeniden gelir (zaman kaybı).
- **Erlik:** baca ateşi ışıktır; gölge tahtalarını siler. Bacayı tıkamak köprüyü
  kurar, açık bırakmak Körmösü uzak tutar: ikisi birden olmaz.
- **Sandık ısınır:** uzun süre bacanın üstünde kalan sandık tutuşur; tıkama geçicidir,
  arkasından koşmak gerekir.

## 6. Senden beklenen kararlar

1. Kanatlar: sağanak bölgeleri mi, bölüm bölüm kapatmak mı (önerim: sağanak +
   Derinkuyu'da kapalı)?
2. Kandilci ve kurt hızlarını artırıp gizlenme koridorlarına tavan koyalım mı?
3. İpuçlarını "çözümü söylemeyen" biçime çevirelim mi?
4. Taş devi için yukarıdaki döngüyle başlayalım mı?
5. Bölüm bölüm önerilerde hangi sırayla ilerleyelim (önerim: genel kurallar → taş
   devi → en zayıf bölümler: Gün Doğumu, Ağrı, Erlik, Peri Bacaları)?
