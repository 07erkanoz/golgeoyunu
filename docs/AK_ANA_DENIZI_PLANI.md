# Ak Ana'nın Denizi: su altı bölümünün kurgusu (25-26 Ekim 2026)

Durum: yapıldı (XV, bölüm kimliği 20; sıra 8. sürüm: Ötüken → Ak Ana'nın
Denizi → Erlik). Önizlemeler docs/onizleme/saye_yuzus.gif, deniz_*.png.

## Yapılanlar

- Yüzüş (player.dart): ataletli serbest yüzüş, yan kulaç (itiş bacakların
  kapandığı anda), suda dik durma, su yüzünde süzülme (baş dışarıda, nefes
  alır; kulaç sudan çıkış hamlesi), saç ve atkı suda, kabarcıklar, nefes
  halkası.
- Nefes (golge_game.dart): 25 sn; hava cebi, açık su yüzü ve kabarcık
  sütunlarında dolar; bitince 3 sn sonra bayılma (son Umay köküne dönüş).
- Canlılar ve düzenekler (deniz.dart): yosun (öndeki saklar), balık
  sürüleri, denizanası (sokar, savurur, nefesten alır), fenerbalığı (yeminin
  ışığına gireni yutar; ateşböceğini kovalar), ahtapot (mürekkep saklar),
  akıntı, kabarcık sütunu, su kaplumbağası, Kandilci sandalları, Ak Ana
  (ak nefes, Körmösler dağılır). Körmösler erlik.dart'tan.
- Harita (tools/generate_maps.py, 420×78) ve nefes denetimi
  (tools/audit_deniz.py: dolu nefesin payla yettiği yol 54 kare).
- Perde: Ak Ana sahnesi bu bölümün; Erlik perdesi onun devamından açılır.
  Köprü sahnesi (perde_kopru.dart). Türkçe/İngilizce seslendirme.
- Ortam sesi assets/audio/amb_sea.ogg (sentez; aslı assets_src/audio).
- Kural testleri: test/deniz_test.dart.

## Efsane (özgün anlatıya sadık)

Altay yaratılış anlatısı (Radloff derlemesi):

- Başta yalnız su ve Kayra (Kara) Han vardı. Kayra Han ile ilk yarattığı
  Kişi, suyun üstünde iki kara kaz gibi uçuyorlardı.
- Su dalgalandı, içinden Ak Ana yükseldi: "Yarat," dedi ve suya döndü.
- Kişi, Kayra Han'dan yükseğe çıkmak istedi, suya düştü, boğulurken
  yardım diledi. Kayra Han sudan bir taş yükseltti, Kişi taşa tutundu.
- Kayra Han, Kişi'ye suyun dibine dalıp toprak getirmesini buyurdu. Kişi
  getirdi ama bir parçasını ağzında sakladı. Avuçtaki toprakla yeryüzü
  yaratıldı; ağızdaki toprak şişip Kişi'yi boğacak oldu. "Tükür," denince
  tükürdü; tükürdüğü yerde bataklık tepeler oldu.
- Bu hile yüzünden Kişi ışıktan kovuldu, karanlığın efendisi oldu: Erlik.

Oyunda yeri: Ötüken ile Erlik arasında. Erlik perdesi zaten "Hayat
Ağacı'nın kökleri yerin en dibine iner... en dipte bir ses vardı: su sesi"
diye açılıyor. Sâye köklerden inip ilk suya varır; denizin dibinden
Erlik'in katına geçer. Ak Ana satırları Erlik perdesinden bu bölümün
perdesine taşınır; Erlik perdesi Erlik'i ve Er Töştük'ü anlatır.

Sıra: ... Peri Bacaları, Derinkuyu, Ötüken, **Ak Ana'nın Denizi**, Erlik,
Ergenekon, Göğün Katları, Ülgen'in Kapısı, Konya, Yeşil Kubbe.

## Oynanışın özü: yüzmek, zıplamak değil

Tulpar'daki gibi sürekli dokunarak yükselme yok. Yüzüş serbest ve
ataletli; Hungry Shark'ın akıcılığı, ama yemek yok:

- **Yön:** Sol yarıda parmağı sürükle: Sâye o yöne yüzer (360°). Parmak
  ne kadar uzaksa o kadar hızlı. Klavyede oklar.
- **Atılış:** Sağ yarıya dokun: kısa, güçlü bir kulaç (0,6 sn dolum).
  Arkada kabarcık izi; balık sürüleri dağılır. Basılı tutmak bir şey
  yapmaz.
- **Atalet ve kaldırma:** Bırakınca süzülür, yavaşça yavaşlar; su onu
  hafifçe yukarı iter. Saç ve atkı suyun içinde dalgalanır.
- **Yüzeye çıkış:** Hızla yüzeye vuran Sâye yunus gibi sudan fırlar, bir
  an havada süzülüp geri dalar. Bölümün neşe anı.
- **Akıntılar:** Kuş Yolu'ndaki ışık nehrinin sudaki karşılığı: içine
  giren taşınır, atılışla akıntıyı kesip çıkılır.

## Nefes: gerilim var, ceza yumuşak

- Nefes, Sâye'nin ağzından yükselen kabarcıklarla ve etrafındaki ince bir
  halkayla gösterilir (köşede gösterge yok, yazı yok).
- Dolu nefes ~25 saniye. %30'un altında ekranın kenarları kararır, kalp
  atışı duyulur, kabarcıklar seyrekleşir.
- Bitince hemen ölüm yok: 3 saniye bulanıklık. Sonra Sâye bayılır ve son
  hava cebinden devam eder.
- **Nefes alınan yerler:**
  - **Hava cepleri:** Kayaların altında sıkışmış hava. Umay ağacının
    (Hayat Ağacı'nın) kökleri bu ceplere sarkar; kontrol noktaları buradadır.
  - **Kabarcık sütunları:** Dipteki sıcak kaynaklardan yükselir. İçinden
    geçen nefes tazeler, yukarı taşınır.
  - **Kişi'nin taşı:** Efsanedeki taş. Bölümün ortasında dipten yükselen
    bir kaya, üstünde hava, bir Umay kökü.

## Düşmanlar ve tehlikeler (Kandilci aşağıda yok)

Kandilciler suya giremez; kandilleri söner. Işık teması başka biçimlerde
sürer:

| Ne | Nasıl | Nasıl kurtulunur |
|---|---|---|
| **Kandilci sandalları** (yalnız ilk kesit) | Yüzeydeki sandallardan fener ışığı suya iner, ağır ağır tarar | Işığın altından derinde geç, yosunda bekle |
| **Fenerbalığı** | Derinin bekçisi: alnındaki fenerle yemler; ışığına giren yutulur (perde kararır, kan yok) | Karanlıkta kal, yosuna gizlen, ateşböceği salıp yemini çek |
| **Denizanaları** | Nefes alır gibi kasılıp yükselip alçalır. Dokunan geri savrulur, nefesinden gider. Karanlıkta ışık da verir. | Ritmini bekle, arasından geç; onların ışığıyla karanlığı oku |
| **Körmösler** (yalnız dipte) | Erlik'in gölgeleri; Erlik bölümündeki gibi ışığa gelirler | Kavanozu kıs (karanlık ama güvenli), ateşböceğiyle başka yöne çek |
| **Girdaplar ve akıntılar** | Yanlış akıntı geri taşır, girdap içine çeker | Atılışla kes, kayanın ardında akıntının durmasını bekle |

## Dostlar ve düzenekler

- **Balık sürüleri:** Yaklaşınca dönüp bir yöne akarlar; karanlık
  koridorda yolu gösterirler. Atılışla içinden geçince dağılırlar.
- **Ahtapot:** Dokununca mürekkep bulutu bırakır. Mürekkep, suyun içinde
  gölgedir: Sâye birkaç saniye fenerbalığına görünmez. Hayal perdesine
  yakışan düzenek.
- **Yosun ormanı:** Sallanan uzun yosunlar gölge gibi saklar. Yosuna
  giren Sâye kararır (karadaki gölgede saklanmanın karşılığı).
- **Su kaplumbağası:** Akıntı koridorunda sırtına binilir; uzun, hızlı,
  keyifli bir geçiş (Tulpar ve Çalkuyruk gibi bir binek anı).
- **Ateşböcekleri:** Kavanoz suyun altında da yanar, derinlik arttıkça
  çevre kararır. Salınan ateşböceği bir ışık kabarcığı olup yükselir;
  fenerbalığını ve Körmösleri çeker.
- **Su İyesi:** Yerebatan'daki gibi bir an belirir, bir kapağı gösterir.

## Kesitler (hedef 12-15 dakika)

1. **Köklerin Ucu ve Sığlık** (~2 dk). Hayat Ağacı'nın kökleri suya
   iner; ilk dalış, ilk hava cebi. Yüzmeyi, atılışı ve yüzeyden fırlamayı
   öğretir. Yukarıda Kandilci sandallarının feneri.
2. **Yosun Ormanı** (~3 dk). Balık sürüleri, ilk fenerbalığı, yosunda
   saklanma, ahtapotun mürekkebi.
3. **Denizanası Mağaraları** (~3 dk). Karanlık mağaralar; yolu yalnız
   denizanalarının ışığı gösterir. Ritimle geçiş, seyrek hava cepleri.
4. **Akıntı Koridorları** (~3 dk). Kaya koridorlarında akıntılar ve
   girdaplar. Kayayı itip bir akıntıyı kapat, öbürünü aç; sonunda
   kaplumbağanın sırtında uzun akıntı.
5. **Kişi'nin Taşı ve Karanlık Dip** (~3 dk). Ortada dipten yükselen taş
   (hava, Umay kökü). Sonra en dip: Körmösler, fenerbalıkları, kabarcık
   sütunları, gerilimli nefes.
6. **Final: Ak Ana.** Dipte Kandilcilerin çaldığı ışıklar bir yarıktan
   aşağı akmaktadır: Erlik'in kapısı. Körmösler yaklaşır, nefes biterken
   suyun kendisi ak bir ışıkla kıpırdar: Ak Ana yükselir, tanıtım kartı
   belirir. Sâye'ye ak bir nefes verir (nefes halkası beyazlaşır, uzun
   süre dolu kalır), Körmösler dağılır. Sâye yarıktan aşağı, Erlik'in
   katına iner.

## Perde ve anlatım

- Bölüm perdesi: ilk su, iki kara kaz, Ak Ana'nın yükselişi, Kişi'nin
  düşüşü ve taş, dalış ve ağızdaki toprak, Erlik'in sürülüşü. Tanıtım
  kartları: Ak Ana, Kişi. Türkçe ve İngilizce seslendirilir (Gemini,
  Charon).
- Umay köklerinde iki-üç fısıltı (seslendirilir), birkaç hatıra (yazı).
- Her düzeneğe ilk karşılaşmada ipucu: yüzme, atılış, nefes, hava cebi,
  kabarcık sütunu, yosun, fenerbalığı, denizanası, ahtapot, akıntı,
  kaplumbağa, Körmös.

## Görünüş

- Hayal perdesi: mürekkep siluetler. Yukarıda açık, aşağıda koyu bir
  derinlik geçişi.
- Yüzeyden inen ışık huzmeleri hazır çizilir; her karede bulanıklık yok
  (Android'de Impeller).
- Kayalar, yosunlar, balıklar siluet. Yalnız denizanaları, fenerbalığının
  yemi, kavanoz ve Ak Ana ışık verir.
- Balık sürüsü en çok 60 balık, tek yolda toplu çizim.

## Yapım notları

- Oyuncuya yeni bir yüzme kipi (kayaktaki gibi ayrı kip): ataletli serbest
  hareket, kaldırma kuvveti, atılış, yüzeyden fırlama. Bölümde su ölüm
  değildir.
- Harita: tools/generate_maps.py ile yeni harita; audit.py'ye yüzme
  kipinde erişim denetimi (nefes süresiyle iki hava cebi arası en uzun
  yol).
- Kural testleri: nefes biter ve kontrol noktasından dönülür, hava cebi
  nefesi doldurur, akıntı taşır, mürekkep fenerbalığından saklar,
  denizanası savurur.
- Önce önizleme: sığlık ve yosun ormanından bir kare ile karanlık dipten
  bir kare.
