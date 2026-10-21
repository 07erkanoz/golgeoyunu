# Gölge Oyunu

İstanbul'da geçen, hikâyeli, karanlık bir 2D platform oyunu prototipi (Flutter + Flame).

## Hikâye

İstanbul, 1660. Şehir üç gündür yanıyor. Kandilciler Loncası küllerin arasından
şehrin bütün ışığını topluyor ve gölge oyunu ustası Hayali Usta'yı kaçırıyor.
Elinde ateşböceği kavanozu taşıyan küçük çırağı, ak kuşun peşinden ustasını
aramaya çıkıyor. Ayrıntılı kurgu: [docs/KURGU.md](docs/KURGU.md).

| Bölüm | Mekân | Öne çıkanlar |
|---|---|---|
| I · Yerebatan | Yerebatan Sarnıcı | Kandilci iskelesi, kemer üstü yol, sandık-kol-kapı, yarasa galerisi, karşı ağırlıklı asansör, Karabasan kovalamacası |
| II · Kule | Haliç kayalıklarından Galata Kulesi'ne | Hareketli ve kopan kayalar, kargalar, çatı Kandilcisi, asansör, Gözcü, Hezarfen'in kanatları |
| III · Gökyolu | Bulutlar | Kanatlarla süzülme, rüzgâr akımları, hareketli adalar, Gözcü |

Oyun Türkçe ve İngilizce (*Shadow Play*) oynanabilir; dil ana menüden ya da
ayarlardan seçilir.

## Menü, ayarlar, kayıt

- **Ana menü:** Kaldığın yerden devam et, Yeni oyun, Ayarlar, Çıkış.
  Arkada oyunun dünyası akar.
- **Ayarlar (Esc ya da sağ üstteki dişli):** Müzik, ortam ve efekt sesi,
  dil, grafik kalitesi, masaüstünde tam ekran (F11).
- **Grafik: Düşük** seçeneği dahili ekran kartları (Intel vb.) için: sis, film
  greni, titreme ve ağır ışık katmanı kapanır.
- **Kayıt:** Her bölüm başında ve kontrol noktasında otomatik kaydedilir.

## Ses

Ortam sesleri ve efektler `tools/synth_sounds.py` ile sentezlenmiştir (dış
kaynak yok). Menü müziği: *Turkish Maqam Soundscape*, vjgalaxy (Pixabay).

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
| Esc | Ayarlar / duraklat |
| F11 | Tam ekran (masaüstü) |

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

### Telefon ve tablet

Ayarlar → **Dokunmatik** ile iki düzen arasında seçim yapılır:

- **Düğmeler:** Solda ◀ ▶, sağda büyük zıpla, ↑ tırman, ↓ çömel, ateşböceği;
  parmak ucu açılıp kapanır. **Düğme görünürlüğü** ile saydamlaştırılabilir.
- **Hareket (düğmesiz):** Sol yarıda sürükle → yürü (yukarı: tırman/kol, aşağı:
  çömel). Sağ yarıya dokun → zıpla (basılı tut: süzül). Ateşböceği köşedeki
  ✨ simgesiyle salınır. Köşelerde yalnızca parmak ucu ve ateşböceği simgeleri
  kalır.

Telefonda kamera biraz daha yakındır ve grafik varsayılan olarak Düşük'tür.

## İndir ve oyna

[Releases](https://github.com/07erkanoz/golgeoyunu/releases) sayfasındaki en son
derlemede üç dosya bulunur. `main` dalına yapılan her gönderimde GitHub Actions
üçünü birden derleyip yayımlar.

| Platform | Dosya | Kurulum |
|---|---|---|
| Windows | `GolgeOyunu-windows.zip` | Bir klasöre çıkar, `golge.exe`'yi çalıştır |
| Android (arm64) | `GolgeOyunu-android-arm64.apk` | Telefona indir, aç; "bilinmeyen kaynaklar" izni istenirse ver |
| Linux (Arch) | `GolgeOyunu-linux-x64.tar.gz` | Aşağıya bak |

Arch Linux:

```bash
sudo pacman -S --needed gtk3 gstreamer gst-plugins-base gst-plugins-good gst-libav
tar -xzf GolgeOyunu-linux-x64.tar.gz
./GolgeOyunu/golge
```

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
