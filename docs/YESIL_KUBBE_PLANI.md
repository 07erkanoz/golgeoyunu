# XX · Yeşil Kubbe: oyunun finali (tasarım, 25 Ekim 2026)

Telefon geri bildirimi: Konya çok çabuk bitiyor, final sıradan. Şeb-i Arûs
on alanı tek bölüme sığdırıyor; son alan (Kubbe-i Hadrâ) kırk karelik bir
tırmanış. Uzatma planındaki karar: **ayrı, zor bir final bölümü**.

Şeb-i Arûs Konya'nın şehir bölümü olarak kalır, kubbenin dibinde biter.
Final yeni bir bölüm: **XX · Yeşil Kubbe** (kimlik 19, sırada Şeb-i
Arûs'tan sonra). Süre hedefi 12-15 dakika. Öğrenilen düzenekler bir arada,
ama her perdenin kendi fikri var.

## Hikâye

Düğün gecesi. Kandilciler ustayı Yeşil Kubbe'nin tepesine, yüzyıllardır
topladıkları bütün ışığın yanına çıkarmış. Ustanın kandili sönmek üzere.
Sâye'nin sorusu (Kaf'tan beri): ben kimim? Cevap (KURGU.md): Sâye ustanın
gölgesi değil, duasıdır. Kandilciler ışığı sakladıkça gölgelerini
kaybettiler; finalde Kandilci Başı yüzyıllar sonra ilk kez kendi gölgesini
görür ve ağlar. Işık göğe döner, usta gider, Sâye ışığa karışır.

## Dört alan

| Alan | Düzenek | Üç adım |
|---|---|---|
| 1 · Türbe Avlusu | **Şadırvanın ayı:** karlı avlu, gül bahçesi. Havuza düşen ay ışığı aynalarla türbenin gümüş kapısındaki ışık kilidine taşınır | Tek ayna → iki ayna ve sıra → bir ayna Kandilcinin yolunda |
| 2 · Kandiller Koridoru | **Kafesteki ışıklar:** türbenin içinde Kandilcilerin topladığı ışıklar gümüş kafeslerde asılı. Kafes açılınca ışık kavanoza girer, bir kapı açılır. Kandilciler dolaşır; gölge taşıyla gölge önden gönderilir | Tek kafes → iki Kandilci ve gölge → kafes Kandilcinin tam önünde |
| 3 · Kubbenin Kaburgaları | **Kandilcilerin halkası:** kubbenin dışında, on altı yeşil kaburga boyunca tırmanış. Kasnağı dolaşan fenerler kaburgaları tarar; çiniler çöker; ipler; aşağıdan ışık seli yükselir | Fener halkası → çöken çiniler ve ipler → ışık seliyle son tırmanış |
| 4 · Ustanın Kandili | **Kandilci Başı:** kubbenin alemi, dev kandil, içinde ustanın gölgesi. Kandilci Başı'nın büyük feneri sahanlığı tarar (yakalanan ölür, sütunların gölgesinde saklanılır). Üç gümüş ayna çevrilip ayın ışığı Kandilci Başı'na düşürülünce ardındaki dev perdede kendi gölgesi belirir: her ayna gölgeyi büyütür. Üçüncüsünde gölgesini görür, fenerini bırakır, diz çöker | Bir ayna (fener uzaktayken) → iki ayna, fener arası → üçüncü ayna fenerin tam önünde |

Son: ışıklar kafeslerinden göğe yükselir, ustanın kandili söner, Sâye
ışığa karışır. Son perde (atlanmaz).

## Yeni kodlanacaklar

- Harita (tools/generate_maps.py, `kMapYesilKubbe`).
- `KandilciBasi`: dev fener taraması (yakalar), ışık kilidiyle gölgenin
  büyümesi, diz çöküş ve finalin sahnesi.
- Dev perde: Kandilci Başı'nın arkasında; gölgesi ayna sayısıyla büyür.
- Gümüş kafes görünüşü (Erlik'in kut kafesi düzeneği).
- Fısıltılar, ozan, köprü perdesi (TR/EN); sesler sonra.
- İpucu: her yeni düzeneğe (hints.dart).
- Testler: harita denetimi (tools/audit.py), kural testleri, bot geçişi.
