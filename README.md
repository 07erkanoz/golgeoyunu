# Gölge Oyunu

İstanbul'da geçen, hikâyeli, karanlık bir 2D platform oyunu prototipi (Flutter + Flame).

## Hikâye

İstanbul, 1660. Şehir üç gündür yanıyor. Kandilciler Loncası küllerin arasından
şehrin bütün ışığını topluyor ve perdeye ışık tutan Hayali Usta'yı da kaçırıyor.
Elinde ateşböceği kavanozu taşıyan küçük bir çocuk, ak bir kuşun peşinden
ustasını aramaya çıkıyor. Yolda bulduğu hatıra parçaları geçmişi yavaş yavaş
açığa çıkarıyor.

| Bölüm | Mekân | Öne çıkan mekanik |
|---|---|---|
| I · Yerebatan | Yerebatan Sarnıcı | Sütun ardında saklanma, Kandilci'den kaçma, iskelede atlama |
| II · Kayalıklar | Dikey uçurum (Galata Kulesi olacak) | Kenara tutunma, sarmaşık tırmanma |
| III · Gökyolu | Bulutlar (Boğaz üstü olacak) | Bulutlar arası atlama |

Görsel dil "Kızıl kül": kömür siluetler ve pas tonlu dünya. Sıcak ışık güvenli
demek, Kandilcilerin camgöbeği ışığı tehlike.

Karakter geçicidir; ileride profesyonel çizimle değiştirilecek.

## Kontroller

| Tuş | İşlev |
|---|---|
| ← → / A D | Yürü, koş (ağırlıklı, ataletli hareket) |
| Boşluk / Z | Zıpla (basılı tutunca daha yükseğe) |
| ↑ / W | Kenardan yukarı çık, zincire/sarmaşığa tırman, **kolu çek** |
| ↓ / S | Çömel ve kavanozu ört; kenardan bırak; zıplamayla birlikte platformdan aşağı in |
| Shift / Q (basılı) | **Parmak ucunda yürü**: sessiz ve yavaş, uzaktan zor görülürsün |
| F / X | **Ateşböceği sal**: Kandilci ışığa dalar; o sırada ona değsen bile seni yakalamaz. Kavanoz en çok 5 alır; yeni ateşböceklerini yoldaki sürülerden toplarsın |
| → (sandığa dayanınca) | Sandığı it |
| Enter / Boşluk | Ara sahnedeki metni geç |
| R | Son kontrol noktasından yeniden başla |

## Ak kuş

Ak kuş bölümdeki önemli yerlere (zincir, sandık, kol…) sırayla uçup seni
bekler. Yolunu kaybedersen ona bak.

## Kandilci'yi geçmenin yolları

- **Saklan:** Sütunun ardında dur ya da çömel. Kandilci önünden geçip gider.
- **Sessiz ol:** Tahta iskelede koşmak gıcırdar, Kandilci sesi duyup döner.
  Parmak ucunda yürü.
- **Oyala:** Ateşböceği sal; Kandilci ışığa dalınca yanından geç.
- **Başka yoldan git:** Zincire tırman, kemerlerin üstündeki kirişlerden geç.

Kandilci seni görünce hemen saldırmaz: başında "?" belirir ve şüphelenir.
Hemen gözden kaybolursan şüphesi söner; bakmaya devam ederse "!" ile kovalar.

Mobilde ekranda dokunmatik düğmeler çıkar.

## Windows'ta oynamak

[Releases](https://github.com/07erkanoz/golgeoyunu/releases) sayfasından en son
`GolgeOyunu-windows.zip` dosyasını indir, bir klasöre çıkar ve `golge.exe`'yi
çalıştır. `main` dalına yapılan her gönderimde GitHub Actions yeni bir Windows
sürümü derleyip buraya ekler.

## Çalıştırma

```bash
flutter run -d linux
```

Geliştirme sırasında `--dart-define=DEV=true` ile açarsan:

- **N** bir sonraki bölüme atlar
- **T** sıradaki hikâye noktasına ışınlar
- **C** yakın plan kamerayı açıp kapatır
- **V** geçici karakter stilini değiştirir (kavanozlu çocuk / ışığı gözünde)

## Yeni bölüm eklemek

Bölümler [lib/game/levels.dart](lib/game/levels.dart) içinde ASCII harita olarak
tanımlıdır; lejant dosyanın başında yazıyor. Fısıltılar (`1`–`9`) ve hatıralar
(`M`) bölümün `whispers` / `memories` listelerine bağlanır.
