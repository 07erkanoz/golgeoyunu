# Anlatım düzeni: fısıltılar, ipuçları, perdeler

Oyunda dört ayrı ses konuşur. Her biri kendi işini yapar, birbirinin işine
karışmaz.

| Ses | Nerede | Ne söyler | Ne söylemez |
|---|---|---|---|
| **Perde** (bölümden önce) | Tam ekran, gölge oyunu | Efsane, yolculuğun nedeni, sıradaki tehlike | Tuş, düzenek |
| **Fısıltı** (`1`-`9`, `()[]{}`) | Üst şerit | Yerin hikâyesi, efsane, Sâye'nin duygusu; kural ancak efsanenin diliyle ("Karabasan ışığa giremez") | Tuş adı, "şuna bas" |
| **İpucu** (`hints.dart`) | Sâye'nin başının üstünde etiket | Düzeneğin ne olduğu ve nasıl kullanıldığı: `Ne · nasıl ({tuş})` | Hikâye |
| **Efsane kartı** | Ayrı şerit, ilk karşılaşmada | Varlığın adı, tek cümle kim olduğu; Defter'e yazılır | Talimat |

## Kurallar

1. **İlk karşılaşmada ipucu.** Her düzenek, bölümde ilk görüldüğü yerde
   ipucunu verir (yakınlık taraması). Yeni bir düzenek ipucusuz eklenmez.
2. **İpucu kalıbı.** `Ne · nasıl · ({tuş})`, en çok üç parça. Tuşlar yer
   tutucuyla yazılır (`{jump}`, `{firefly}`); cihaz kendisi doldurur.
3. **Basamaklar.** Aynı düzenekte ikinci ölümde *ilişki* (kural neden
   böyle), üçüncüde *çözüm* ("Az önce" panelinde, istenince açılır). Her
   yeni düzenek için üçü birlikte yazılır.
4. **Fısıltı hikâyedir.** Düzeneği ancak efsane olarak anlatır; talimat
   ipucunun işidir. İkisi aynı şeyi iki kez söylemez.
5. **Fısıltı düzeneğin önünde.** Bir yeri anlatan fısıltı, o yere girmeden
   önce, ilk düzenekten en az 4 kare önce tetiklenir; iki fısıltı arası en
   az 6 kare.
6. **Fısıltı sırası ilerleyiş sırasıdır.** Haritada `1`, `2`, `3`… oyuncunun
   karşılaştığı sırayla dizilir; bölümün son fısıltısı sıradaki perdeye
   bağlanır (bir sonraki yerin kokusu, sesi).
7. **Efsane kartı ilk görüldüğü an.** Kart, varlığa ilk yaklaşıldığında açılır
   (`meetMyth`); perde ve bölüm başlığı dışında bir şeyi beklemez.
8. **Görev satırı.** Çok adımlı düzeneklerde sol üstte o anki adım yazar ve
   ilerledikçe değişir (Ergenekon'un körükleri gibi).

## Bölüm başına denetim

- `tools/audit.py`: haritanın geçilebilirliği.
- Bölümün bot testi (`test/<bölüm>_test.dart`): her düzenek baştan sona
  oynanır; ölünce zor yere dönüş 20-30 saniyeyi geçmez.
- Fısıltı sırası ve aralığı (kural 5-6) bölüm eklenirken elle bakılır.

## Uygulama

- Ötüken Ormanı bu düzene göre yazıldı (2026-10-23).
- Var olan bölümler sırayla bu düzene getirilecek: fısıltıların sırası
  (Kule, Gökyolu, Kaf, Ağrı'da sıra bozuk), talimat içeren fısıltılar,
  ipucusuz kalan düzenekler, kayıt noktaları (4-6).
