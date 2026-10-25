# Neşe paketi: gölge oyununun güldüren yüzü

25 Ekim 2026. Oyun şimdiye dek perdenin gerilimli, gizemli yüzünü kullandı.
Karagöz ise hem hayal hem güldürüdür; Sâye de dünyayı ilk kez gören bir
çocuk. Bu paket ikisini birleştirir: korku ve gerilim yerinde kalır, aralara
güldüren, şaşırtan, çocuğun merakını gösteren anlar girer. Eğlence ile gizem
bir aradadır: bazı şakaların içinde bir sır saklıdır.

Durum: ✅ yapıldı · ⏳ sırada

## İlkeler

1. **Tehlikede yok.** Hepsi sakin anlarda olur (Kandilci kovalarken, Karabasan
   yaklaşırken değil).
2. **Sözsüz.** Hareket, ışık, kısa ses. Yazı yok (zıpzıpın ilk ipucu dışında).
3. **Oyunu bozmaz.** Hiçbiri yolu kapatmaz, zorunlu değildir; kaçıran bir şey
   kaybetmez, bulan gülümser.
4. **Her bölümde bir şey.** Neşe bir bölüme sıkışmaz.

## N1 · Gölge oyunları ✅

Sâye sakin bir yerde 15 saniye durunca (bir düzeneğin başında değilse; iki oyun arası en az iki dakika) gölgesi kendi kendine bir hayvana
dönüşür, oynar, sonra yine Sâye olur (kıpırdarsa hemen döner). Bölüme göre:
sarnıçta tavşan ve kuş, mağarada tilki, karda uluyan kurt, Nemrut'ta kükreyen
aslan, gemide at, aslan, geyik, tavşan; Kapadokya'da şaha kalkan at; ormanda
otlayan geyik. Siluetler PhyloPic'ten kamu malı (CC0): Ferran Sayol (tavşan,
tilki, geyik), Margot Michaud (aslan). İlk görüşte sır sayacına eklenir.
Kod: `player.dart` (`_ShadowMood.play`), `golge_game.dart`
(`_updateShadowPlay`).

## N2 · Meraklı Sâye: kuşlar ✅

Umay ağacının (kontrol noktası) yanında durunca dallardan kuşlar iner: biri
Sâye'nin başına konar, biri kavanozunun kenarına; gagalar, başını çevirir.
Sâye kıpırdayınca cıvıldayıp uçarlar. Kod: `joy.dart` (`UmayBirds`).

## N3 · Neşe parkuru ✅

Bölümün sakin, düz, üstü açık bir yerinde iki zıpzıp (temaya göre davul,
perde bezi, mantar, bulut) ve zıplayışın yolunu çizen ışık dizisi. İlk
zıpzıp ikinciye atar, ikincisi daha yükseğe. İlk ışığa dokununca dizi altı
saniye yanar (son iki saniye titrer); hepsi toplanırsa perdenin ardındaki
seyirci alkışlar, Sâye'nin üstüne ışık yağar (sır). Toplanamazsa ışıklar
birazdan yeniden belirir. Yer haritaya elle konmaz: bölüm kurulurken düz,
geniş, tehlikesiz ve düzeneklerden uzak bir zemin aranır; zıpzıpın gücü
tavanın yüksekliğine göre ayarlanır. 10 bölümde parkur var.
Kod: `joy.dart` (`Bouncer`, `JoyLights`, `findJoySpots`).

## N4 · Karagöz ile Hacivat ✅

Küçük bir Karagöz perdesi: önünde durunca kandil parlar, Hacivat eğilip selam
verir, söze başlar; Karagöz sözünü keser, kafa atar, Hacivat fırıl fırıl
döner, Karagöz hoplayıp güler. Sonunda ikisi birden bir yeri gösterir, kamera
oraya bakar: Yerebatan'da Gölgehane'nin yolu, öteki bölümlerde ilerideki
neşe parkuru. Seyirci alkışlar (sır). 14 bölümde perde var.
Kod: `joy.dart` (`KaragozSahne`), `perde_kisi.dart`
(`paintKaragozHacivat`).

## G1 · Gemi: heykeller nereye? ✅

Telefon geri bildirimi: hangi heykelin hangi gölgeye gideceği belli değildi.
Artık hedef gölgeler duvarda aydınlık, çerçeveli birer perde. Heykel ilk
itildiğinde kamera eşinin gölgesini gösterir; eşi yaklaştıkça gölgenin kenarı
ışır; yanlış heykel gelince gölge "hayır" der gibi sallanır. Duvardaki süs
hayvan geçidi soluklaştırıldı (hedeflerle karışıyordu).

## Sonra

- **Kar tanesi:** karda durunca Sâye başını kaldırır, dilini çıkarır.
- **Kelebek ve ateşböceği dansı:** ormanda kavanozun ışığına gelenler.
- **Elle ayarlanmış parkurlar:** parkuru olmayan bölümler (Yerebatan, Kaf,
  Nemrut, Gün Doğumu, Derinkuyu, Erlik) için haritaya özel, bölümün
  düzeneğiyle oynayan parkurlar.
