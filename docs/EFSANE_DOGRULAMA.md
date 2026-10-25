# Efsane ve Tarih Doğrulaması

Tarih: 2026-10-25. Bakılan dosyalar: `lib/game/levels.dart` (giriş/son, perdeler, köprüler, bölüm fısıltıları, hatıralar, ozan dizeleri, yer/zaman satırları, yeni XX · Yeşil Kubbe dâhil), `lib/game/myth_cards.dart`, `lib/game/strings.dart`, `lib/game/perde*.dart` (yalnızca tasvir adları var, anlatı metni yok), `docs/MITOLOJI.md`, `docs/KURGU.md`.

> **Not:** Bu inceleme sürerken `levels.dart` başka bir oturumda değişti (XX · Yeşil Kubbe eklendi, satırlar ~15 kaydı). Satır numaraları dosyanın **2026-10-25 öğleden sonraki** hâline göredir; düzeltmeden önce metni aratın.

Sınıflar: **DOĞRU** · **RİVAYET** (gerçek bir gelenek; oyunun onu rivayet diye mi, bilgi diye mi sunduğu belirtildi) · **TARTIŞMALI** (kaynaklar ayrışıyor ya da tarihsellik kuşkulu) · **YANLIŞ** · **UYDURMA** (hiçbir gelenekte bulunamadı ama gelenekmiş gibi sunuluyor) · **DOĞRULANAMADI**.

---

## 0. Özet

- Bölüm tablosunda **171 iddia** var (ayrıca docs/ notlarından 8 satır).
- Sonuç (yaklaşık; bazı satırlar karma): **~110 DOĞRU**, **26 RİVAYET** (çoğu doğru çerçevelenmiş), **13 TARTIŞMALI**, **5 YANLIŞ** (aynı iki hatanın tekrarları: Şeb-i Arûs takvimi, Hezarfen ayrıntısı, Yeşil Kubbe beyti, peri bacası ölçeği), **9 UYDURMA** (çoğu hafif), **3 DOĞRULANAMADI**, 6 kurgu (oyunun açıkça kendi kurgusu).
- Oyun genel olarak iyi durumda: efsanelerin çoğu "derler", "rivayet ederler", "-mış" kipiyle anlatılıyor, Defter kartlarının neredeyse hepsi kaynaklara uyuyor. Sorunlar birkaç yerde toplanıyor: Şeb-i Arûs'un tarihi, Lagari'nin "kardeşliği", Erzurum'a mal edilen ejder efsanesi, Yeşil Kubbe kapısındaki beyit.

### 0.1 Hezarfen Ahmed Çelebi (ve Lagari Hasan Çelebi): kesin cevap

**Evliya Çelebi ne diyor?** (Seyahatnâme I. kitap, İstanbul'daki ehl-i hiref anlatımı; eski baskıda I, 670-671. Dankoff'un çevirisi ve TDV özetiyle uyuşan içerik:)
1. Ahmed Çelebi'ye çok fen bildiği için *Hezârfen* denir.
2. **Önce Okmeydanı'nda minberin üstünden, rüzgâr şiddetliyken, kartal kanatlarıyla sekiz dokuz kez havada uçar** (rüzgâra karşı uçmanın kaldırdığını öğrenir). "Düştü" denmez.
3. Sonra **IV. Murad Sarayburnu'ndaki Sinan Paşa Köşkü'nden seyrederken**, Galata Kulesi'nin tepesinden **lodosla** uçup **Üsküdar'da Doğancılar Meydanı'na** iner.
4. Padişah ona **bir kese altın** verir ve şöyle der (TDV'deki biçimiyle): *"Bu âdem pek havf edilecek bir âdemdir; her ne murad ederse elinden gelir. Böyle âdemlerin bekası caiz değildir."*
5. **Cezayir'e sürer; Evliya'ya göre orada ölür.**

**Tarih:** Evliya yıl vermez. 1630, 1632, 1638 gibi yıllar sonraki yazarların tahminidir. Kesin olan tek çerçeve IV. Murad'ın saltanatı (1623–1640). Oyundaki "Otuz yıl önce" (1660'tan geriye ~1630) bu aralığa düşer: kabul edilebilir.

**Başka çağdaş kaynak var mı?** Yok. TDV İslâm Ansiklopedisi: "Ahmed Çelebi hakkındaki bilgiler sadece Evliya Çelebi'nin Seyahatnâme'sine dayanmaktadır." Dönemin kronikleri (Kâtib Çelebi, Naîmâ, Peçevî) bu olayı anmaz. (Bu kroniklerin metnini ayrıca taramadım; ama hiçbir ikincil kaynak onlarda bir iz göstermiyor.)

**Tarihçiler nasıl değerlendiriyor?** Olay *rivayet* olarak ele alınır. TDV'ye göre ~3.200 m'lik bir uçuş kuş gibi kanat çırparak imkânsızdır, ancak hava akımlarıyla süzülen sert kanatlı basit bir planörle düşünülebilir. Wikipedia "purported" (iddia edilen) der. Evliya'nın abartılı ve masalsı anlatımı da biliniyor. Doğru ifade şu: **"Evliya Çelebi anlatır"**; "tarihte şu oldu" değil.

**Lagari Hasan Çelebi (Evliya, I, 670-671; TDV "Hasan Çelebi, Lâgarî"):** 1042 (1632-33) yılında, IV. Murad'ın kızı Kaya Sultan'ın doğum şenliğinde, Sarayburnu'nda, padişahın önünde, 50 okka barut macunuyla yapılmış **yedi kollu bir fişeğe** biner. Binmeden "Padişahım, seni Hudâ'ya ısmarladım, Îsâ Nebî ile konuşmaya gidiyorum" der. Havada başka fişekler de yakar, kartal kanadı biçimli aletlerle Sinan Paşa Köşkü önünde denize iner, yüzerek gelir ve **İsa'nın ona selam söylediğini** şakayla bildirir. Bir kese akçe ve 70 akçe dirlikle sipahi yapılır. Sonra Kırım'a, Selâmet Giray Han'ın yanına gider ve orada ölür. Evliya ona "yâr-ı gâr-ı sâdıkımız" (sadık dostumuz) der. **Hezarfen'in kardeşi olduğu Evliya'da da TDV'de de yok.** Bu iddia 1996 yapımı *Istanbul Beneath My Wings* filminden ve kaynaksız ansiklopedi maddelerinden yayılmış görünüyor.

**Oyunun şimdiki ifadesi:**

| Yer | Şimdiki metin | Hüküm |
|---|---|---|
| levels.dart:455 | "...Galata Kulesi yükseliyordu: Cenevizlilerin İsa Kulesi..." | DOĞRU (Christea Turris, 1348) |
| levels.dart:456 / 610 | "Otuz yıl önce, Sultan Murad'ın zamanında, bu kulede bir adam göğe bakmıştı. Adı Hezarfen Ahmed Çelebi'ydi: bin fen bilen." | Güvenli. İsterseniz "Otuz yıl kadar önce". |
| **levels.dart:457 / 611** | "Önce Okmeydanı'nda, kartal kanadına benzeyen kanatlarla rüzgârı sınadı; **dokuz kez düştü, dokuz kez kalktı.**" | **Değiştirin.** Evliya "sekiz dokuz kez uçtu" der, "düştü" demez. |
| levels.dart:458 / 612 | "...Evliya Çelebi anlatır: Boğaz'ın üstünden süzüldü, Üsküdar'da Doğancılar Meydanı'na indi..." | Güvenli; doğru çerçeve. |
| levels.dart:459 / 613 | "Sultan ona bir kese altın verdi... 'Bu adam korkulacak adamdır; ne dilerse elinden gelir.' Hezarfen'i Cezayir'e sürdüler. Göğü bir kez gördü; gurbette öldü." | Evliya'ya uyuyor. Satırlar tek tek gösterildiği için çerçeveyi bu satırda da tekrarlamak daha güvenli olur (öneri aşağıda). |
| levels.dart:460 / 614 | "Derler ki kanatlarını kulenin en üst katına saklamıştı..." | UYDURMA (oyunun kendi kurgusu, "derler ki" ile gelenekmiş gibi duruyor). Düşük risk. |
| **levels.dart:464 / 618** | "**Hezarfen'in kardeşi olduğu söylenen** Lagari Hasan Çelebi..." | **Değiştirin.** Kardeşlik Evliya'da yok. |
| levels.dart:465 / 619 | "Ateş bitince denize düştü, yüzerek padişahın önüne çıktı ve güldü: 'İsa Peygamber sana selam söyledi.'" | DOĞRU (Evliya'ya uygun) |
| myth_cards.dart:146-151 | Kart: "Evliya Çelebi'nin Seyahatname'sine göre... Anlatının tek kaynağı Evliya Çelebi'dir." | Güvenli ve doğru. İsteğe bağlı bir cümle eklenebilir (aşağıda). |
| levels.dart:1148 | Hatıra: Ustam o gün Doğancılar'daki kalabalıkta bir çocukmuş... | Kurgu, sorun yok. |

**Önerilen metinler:**
- levels.dart:457 → `'Önce Okmeydanı\'nda, kartal kanadına benzeyen kanatlarla rüzgâra karşı sekiz dokuz kez havalandı.'`
  EN 611 → `'First, at Okmeydani, with wings like an eagle\'s, he rose against the wind eight or nine times.'`
- levels.dart:459 (isteğe bağlı) → `'Evliya\'ya göre Sultan ona bir kese altın verdi, sonra şöyle dedi: "Bu adam korkulacak adamdır; ne dilerse elinden gelir." Hezarfen\'i Cezayir\'e sürdüler. Göğü bir kez gördü; gurbette öldü.'`
  EN 613 → `'Evliya says the sultan gave him a purse of gold, then said: "This man is to be feared; he can do whatever he wishes." They exiled Hezarfen to Algiers. He saw the sky once, and died far from home.'`
- levels.dart:464 → `'Evliya Çelebi\'nin dostu Lagari Hasan Çelebi de bir zamanlar göğe çıkmıştı: Sarayburnu\'nda yedi kollu bir fişeğe bindi, barutun ateşi onu göğe fırlattı.'`
  EN 618 → `'Evliya Celebi\'s friend Lagari Hasan Celebi once rose into the sky as well: at Sarayburnu he mounted a seven-branched rocket, and the fire of the powder hurled him skyward.'`
- levels.dart:460 (isteğe bağlı) → `'Belki kanatlarını kulenin en üst katına saklamıştı, düşmekten korkmayan birine. Uçanlar sürgün edilir, Sâye. Yine de uç.'`
- myth_cards.dart:148 sonuna (isteğe bağlı) → `Başka bir çağdaş kaynakta geçmediği için tarihçiler olayı Evliya\'nın rivayeti sayar.` / EN 149: `No other contemporary source mentions it, so historians treat it as Evliya's account rather than established fact.`

Kaynaklar: [TDV, Hezârfen Ahmed Çelebi](https://islamansiklopedisi.org.tr/hezarfen-ahmed-celebi) · [TDV, Hasan Çelebi, Lâgarî](https://islamansiklopedisi.org.tr/hasan-celebi-lagari) · [Wikipedia, Hezârfen Ahmed Çelebi](https://en.wikipedia.org/wiki/Hez%C3%A2rfen_Ahmed_%C3%87elebi) (Dankoff çevirisinden alıntı; kardeşlik iddiası kaynaksız) · [Istanbul Beneath My Wings](https://en.wikipedia.org/wiki/Istanbul_Beneath_My_Wings)

---

### 0.2 Düzeltilmesi gerekenler (önem sırasıyla)

**1. Şeb-i Arûs "17 Aralık 1660" olamaz (YANLIŞ / zaman hatası).**
- Yerler: levels.dart:550 ("O gece on yedi Aralık'tı..."), :1890 (`place: 'Konya · 17 Aralık 1660, Şeb-i Arûs gecesi'`), :1928 ("Bu gece on yedi Aralık, Şeb-i Arûs"), :2335 (`place: 'Konya · Yeşil Kubbe, 17 Aralık 1660 gecesi'`); strings.dart:210 (`storyAct4Text`); İngilizceleri levels.dart:704, :1891, :1944, :2336, strings.dart:424; KURGU.md "Zaman çizgisi".
- Sorun: Mevlânâ 5 Cemâziyelâhir 672'de öldü. Bu, **Jülyen** takvimiyle 17 Aralık 1273 (Gregoryen takvim 1582'de çıktı; aynı gün Gregoryen'e göre 24 Aralık 1273 eder). 17 Aralık'ta yapılan anma, Cumhuriyet döneminde (1950'lerden itibaren) güneş takvimine sabitlenmiş bir gelenek. 1660'ta Mevlevîler anmayı **hicrî** tarihte yaparlardı. Hicrî 5 Cemâziyelâhir, Gregoryen takvimde **17 Şubat 1660**'a (yangından önce) ve **5 Şubat 1661**'e denk gelir (tablo hesabı, ±1 gün). Yani 17 Aralık 1660 Şeb-i Arûs değildi. Konya'nın 1660 Aralık'ına bakan biri bunu fark eder.
- Öneri (A, tarihsel doğru): yer satırı `'Konya · Şubat 1661, Şeb-i Arûs gecesi'` / `'Konya · February 1661, the night of Sheb-i Arus'`; XX için `'Konya · Yeşil Kubbe, Şeb-i Arûs gecesi'`. Kar, Kapadokya ve Derinkuyu "Aralık 1660"da kalabilir, kış sürüyor.
  - :550 → `'O gece Şeb-i Arûs\'tu: Mevlânâ\'nın vefat gecesi, düğün gecesi.'` / EN 704 → `'That night was Sheb-i Arus: the night Mevlana died, the wedding night.'`
  - :1928 → `"... Bu gece Şeb-i Arûs: Mevlânâ'nın vefat gecesi..."` ("on yedi Aralık" çıkar) / EN 1944 aynı biçimde.
  - strings.dart:210 → `'Konya, Şeb-i Arûs gecesi. Kandilciler ustayı Mevlânâ\'nın düğün gecesine getirdi...'`
  - (B) 17 Aralık'ta ısrar edilecekse yıl yazılmamalı ve bunun bugünkü anma günü olduğu bilinmeli. Yine de 1660'ta geçen bir hikâye için zaman hatası olarak kalır.
- myth_cards.dart:581'deki "17 Aralık 1273" bugün yaygın kullanılan tarih, kalabilir. İsterseniz "(hicrî 5 Cemâziyelâhir 672)" eklenebilir.
- Kaynak: [TDV, Mevlânâ](https://islamansiklopedisi.org.tr/mevlana-celaleddin-i-rumi) (5 Cemâziyelâhir 672 / 17 Aralık 1273) · [TDV, Şeb-i Arûs](https://islamansiklopedisi.org.tr/seb-i-arus) · [Kür Ansiklopedi, Şeb-i Arus](https://kureansiklopedi.com/tr/detay/seb-i-arus-d51ac) · [Hürriyet, Konya'da 1950'lerden beri yapılan törenler](https://www.hurriyet.com.tr/yerel-haberler/konya/chp-konya-milletvekili-kart-37012781)

**2. Yeşil Kubbe: "Kapının üstünde Mesnevî'nin ilk beyti" (YANLIŞ).**
- Yer: levels.dart:2352 / EN :2363 (yeni XX bölümü).
- Sorun: Türbenin Gümüşlü Kapısı'nın üstünde Molla Câmî'nin Farsça beyti yazılıdır: *"Kâbetü'l-uşşâk bâşed în makâm / Her ki nâkıs âmed înca şod temâm"* (Burası âşıkların Kâbesidir; buraya eksik gelen tamamlanır). Mesnevî'nin "Bişnev" beyti kapı yazısı değildir.
- Öneri: `'Gümüş kapının üstünde Câmî\'nin beyti: "Burası âşıkların Kâbesidir; buraya eksik gelen tamamlanır."'` / EN: `'Above the silver door, Jami\'s couplet: "This is the Kaaba of lovers; whoever comes here incomplete is made whole."'`
  Ney beyti kalsın isteniyorsa yer değişmeli: `'Semâhaneden Mesnevî\'nin ilk beyti duyuluyor: "Dinle, bu ney nasıl şikâyet ediyor; ayrılıkları anlatıyor."'`
- Kaynak: [TDV, Mevlânâ Külliyesi](https://islamansiklopedisi.org.tr/mevlana-kulliyesi) (gümüş kapı, Dâhil-i Uşşâk) · [Wikipedia, Mevlâna Museum](https://en.wikipedia.org/wiki/Mevl%C3%A2na_Museum) (kapılardaki Câmî metni). Beytin kapı üstündeki yerini ikincil kaynaklar doğruluyor; müzenin yayınından bir kez bakmak iyi olur.

**3. Lagari "Hezarfen'in kardeşi" (TARTIŞMALI, Evliya'da yok).** levels.dart:464 / 618. Bkz. 0.1.

**4. Hezarfen "dokuz kez düştü" (YANLIŞ ayrıntı).** levels.dart:457 / 611. Bkz. 0.1.

**5. Erzurum'a mal edilen ejder efsanesi (UYDURMA, "Erzurum'un yaşlıları anlatır" diye sunuluyor).**
- Yerler: levels.dart:520 / EN 674 ("Erzurum'un yaşlıları anlatır: dünya yeniyken bu doruklarda iki ejder kardeş..."; devamı :521-522), :527 / EN 681 ("Erzurum'un yaşlıları der ki Ejder uyurken dağ susar"), :1725 / EN 1733 ("Erzurum'un yaşlıları anlatır: bir kervan... develeri ayakta, donmuş bulmuşlar").
- Sorun: Büyük Ejder doruğu gerçek (Palandöken'in en yüksek tepesi, ~3.176 m). Ama iki ejder kardeşi, onları uyutan derviş ve donmuş kervan hikâyeleri hiçbir kaynakta bulunamadı. "Küçük Ejder" adlı ayrı bir doruk da doğrulanamadı. Erzurumlu bir oyuncu "biz böyle bir şey anlatmayız" diyebilir.
- Öneri: hikâyeyi oyunun kendi ozanına bağlayın:
  - :520 → `'Ozan der ki: dünya yeniyken bu doruklarda iki ejder kardeş yaşarmış. Kışın ovaya inip sürüleri, kervanları yutarlarmış.'` / EN: `'The bard says: when the world was young, two dragon brothers lived on these peaks...'`
  - :527 → `'Uyuyan ejder ışığı sevmez. Ozan der ki ejder uyurken dağ susar; uyandığında kar akar.'`
  - :1725 → `'Ozan anlatır: bir kervan bir gece çığa yakalanmış...'`
  - :1666'daki "Eski inanışta dağların doruğu kutsaldır; orada koruyucu ruhlar, dev ejderler yaşar" → `'...Eski inanışta dağların doruğu kutsaldır, dağın da bir iyesi vardır. Ozan der ki bu doruklarda iki ejder uyur...'` (Dağ iyesi ve kutlu dağ inancı gerçek; doruklarda ejder yaşadığı inancı genel bir Türk inancı olarak gösterilemez.)
  - "Küçük Ejder" haritada doğrulanamadı. Kurgu olarak kalabilir, ama yer satırında (:1706 civarı, `'Küçük Ejder Yamacı · Erzurum'`) gerçek bir doruk gibi duruyor.
- Kaynak: [Hürriyet Daily News, Palandöken (Ejder 3.176 m)](https://hurriyetdailynews.com/palandoken-at-the-peak-of-anatolia-151365) · Ejder efsanesi aramalarında sonuç çıkmadı.

**6. Ergenekon "Türklerin ataları" ve "Bu güne Nevruz derler" (TARTIŞMALI).**
- Yerler: levels.dart:566 / EN 720; :2086 / EN 2096; myth_cards.dart:292-294 (Gökbörü kartı: "Ergenekon anlatısında da... yolu bir kurt gösterir"); MITOLOJI.md §3 ve §5.
- Sorun: Kartın da gösterdiği iki ana kaynakta (Reşîdüddîn, *Câmiu't-tevârîh*; Ebülgâzî, *Şecere-i Türk*) Ergenekon'a sığınanlar **Moğolların** ataları Nüküz ile Kıyan'dır. Türk destanı olarak okunması Göktürk türeyiş efsanesiyle birleşmesinden ve 19.-20. yüzyıl yorumlarından gelir (Ziya Gökalp, 1930'lar ders kitapları). **Yol gösteren kurt** bu iki kaynakta yok, sonraki anlatılarda var. Çıkış gününün **Nevruz** olduğu da erken kaynaklarda bulunamadı; çağdaş Türkiye'deki kutlamalarda yaygınlaştı. Oyunun :570'teki "Kimi anlatılar, yolu bir boz kurdun gösterdiğini söyler" ifadesi doğru ve güvenli. Her yıl demirin kızdırılıp dövüldüğü (:571) Reşîdüddîn'de var: DOĞRU.
- Öneri:
  - :566 → `'Ozan der ki: Bir zaman bir boyun ataları büyük bir savaşta yenildi; yalnız iki yiğit, Kıyan ile Nüküz, eşleriyle kurtuldu.'` / EN: `'The bard says: once the forefathers of a people were defeated in a great war...'` (Hemen ardından bir cümle istenirse: `Reşîdüddîn bunu Moğolların, sonraki anlatılar Türklerin destanı diye yazar.`)
  - :2086 → `'Vadiden çıkış: ilk sabah. Bu gün kutlu sayılır; her yıl bir demir ateşte kızdırılır, örste dövülür. Bugün Nevruz\'da da anılır.'` (ya da Nevruz'u çıkarın)
  - myth_cards.dart:292-294 → `'... Sonraki Ergenekon anlatılarında da dağlarla çevrili vadiden çıkış yolunu bir kurt gösterir.'`
- Kaynak: [Wikipedia, Epic of Ergenekon](https://en.wikipedia.org/wiki/Epic_of_Ergenekon) (Moğol sürümü, kurt motifinin sonradan eklenmesi) · [Zoriktuev, Ergene-Kun'un Türk sürümü üzerine](https://archaeology.nsc.ru/en/publications/jr-aeae-en/15-43-3/annot-09/)

**7. Ağrı: "Masis der, dünyanın anası" (TARTIŞMALI).** levels.dart:481 / EN 635.
- "Masis" doğru. "Dünyanın anası" yerleşik bir anlam değil; birçok halk etimolojisinden biridir ("Ma-sis": ana Sis, ya da Ma tanrıçasının dağı). "Çiyayê Agirî = ateşli dağ" yaygın ama kökeni belirsiz. Türkçe "Ağrı"nın "Ağır Dağ"dan geldiği de söylenir.
- Öneri: `'Ermeniler bu dağa Masis der; Kürt çobanlar Çiyayê Agirî, ateşli dağ derler. Tufandan sonra gemi onun omzuna oturmuş, insanlık orada yeniden doğmuş.'` / EN: `'The Armenians call this mountain Masis; the Kurdish shepherds call it Ciyaye Agiri, the fiery mountain, they say. After the Flood...'`
- Kaynak: [Wikipedia, Mount Ararat (ad ve köken)](https://en.wikipedia.org/wiki/Mount_Ararat)

**8. Konya metinleri.**
- levels.dart:1924 / EN 1940 "Belh'ten bir âlim, ailesini alıp **Moğollardan kaçmış**." **TARTIŞMALI.** TDV'ye göre Bahâeddin Veled'in Belh'ten ayrılması Harezmşah'la anlaşmazlığa ya da manevî bir işarete bağlanır; "Moğollardan kaçtığını kaydeden bir kaynak yoktur" (bu görüş Nicholson ile Ritter'e aittir). Attâr görüşmesi ve kehaneti Câmî ile Devletşah'tan gelen bir **rivayettir** (-mış kipi doğru). → `'Belh\'ten bir âlim ailesini alıp yola çıkmış. Rivayete göre Nişabur\'da yaşlı bir şaire uğramışlar: Attâr\'a...'` / EN: `'A scholar of Balkh set out with his family. The tale goes that in Nishapur they visited an old poet...'`
- levels.dart:1928 / EN 1944 "Güneşini kaybeden adam bir direğin çevresinde dönmeye başladı. **Semâ böyle doğdu**." **RİVAYET, ama bilgi gibi sunuluyor.** Eflâkî semânın Şems'in ilk gidişinden sonra başladığını yazar. Direğin çevresinde dönme sahnesi menkıbedir. → `'Derler ki güneşini kaybeden adam bir direğin çevresinde dönmeye başladı; semâ böyle doğdu: arayanın dönüşü.'` (Ayrıca "on yedi Aralık" çıkar; bkz. 1.)
- levels.dart:1923 / EN 1939 "Konya **bütün Anadolu'nun** başkentiydi." **Abartı.** Konya, Anadolu Selçuklularının başkentiydi. → `'...Konya Anadolu Selçuklularının başkentiydi.'` / EN `'Konya was the capital of the Anatolian Seljuks.'`
- levels.dart:1921 / EN 1937 "...Ama cilalı bir kalkanda **kendi yüzünü görürse kendisi taşa döner**." **UYDURMA** (antik mitte yok: Perseus kalkanı yalnızca ona doğrudan bakmamak için kullanır; Medusa'nın kendi yansımasıyla taşa dönmesi sonraki dönemin bir yorumudur). Bulmaca buna dayandığı için perdenin kuralı olarak söyleyin: → `'... Yerebatan\'daki başları hatırla: bakışı taşa çevirir. Perde der ki cilalı bir kalkanda kendi bakışıyla karşılaşırsa kendisi taşa döner.'`

**9. Kapadokya: "Katpatuka: güzel atlar ülkesi" ve "rüzgâr bin yıl oydu" (TARTIŞMALI).** levels.dart:534 / EN 688; :1777 / EN 1788.
- "Güzel atlar ülkesi" eski bir İranca etimoloji. Bugün çoğu bilim insanı ses bilgisi gerekçesiyle bunu zayıf buluyor, Hititçe "katta" (aşağı ülke) önerisi öne çıkıyor. Ayrıca peri bacaları yağmurla ve rüzgârla milyonlarca yılda oluştu. "Bin yıl" bilgi gibi okunuyor.
- Öneri: `'Eskiler bu ülkeye Katpatuka derdi; kimi "güzel atlar ülkesi" diye çevirir. Erciyes\'in ve Hasan Dağı\'nın küllerini yağmur ve rüzgâr çağlar boyu oydu; kayalar başlıklı devler gibi göğe yükseldi.'` / :1777 → `'Eskiler bu ülkeye Katpatuka derdi; kimi "güzel atlar ülkesi" der. Ama atlardan önce burada periler vardı.'`
- Kaynak: [Wikipedia, Cappadocia (etimoloji)](https://en.wikipedia.org/wiki/Cappadocia) · [Hürriyet Daily News, "Does Cappadocia mean the land of beautiful horses?"](https://hurriyetdailynews.com/does-cappadocia-mean-the-land-of-beautiful-horses--87789)

**10. Göğün Katları: "En yüksek katta Ülgen oturur" (TARTIŞMALI).** levels.dart:576 / EN 730.
- Altay anlatılarında (Anohin, Radloff; Ögel'in aktarımı) gök 17 kattır. Ülgen **16.** katta, Kayra Han 17.'de oturur. → `'Göğün on altıncı katında Ülgen oturur: iyiliğin ve aydınlığın kaynağı. Erlik onun karşıtıdır.'` / EN `'On the sixteenth layer of the sky dwells Ülgen...'` (Kart myth_cards.dart:562 "yüksek katlarında" diyor: doğru.)
- Kaynak: [turkedebiyati.org, Türk mitolojisinde gök katları](https://www.turkedebiyati.org/?p=22683) (popüler kaynak; Ögel, *Türk Mitolojisi*'nden de bakılmalı).

**11. Albastı kartı: "kızıl saçlı" (TARTIŞMALI).** myth_cards.dart:333-334.
- TDV: "Çoğunlukla **al gömlekli**, yaşlı ve son derece çirkin bir cadı şeklinde" düşünülür. Korunmak için yastık altına bıçak, makas gibi demir şeyler konur, demirle gürültü yapılır. Nal TDV'de geçmiyor. "Işığını çalan" oyunun eklemesi.
- Öneri: `'Anadolu\'dan Orta Asya\'ya yaygın halk inancında Albastı, çoğu zaman al gömlekli bir cadı kılığında düşünülen, insanın gücünü çalan karanlık bir varlıktır. Ondan korunmak için yanda demir bir şey bulundurulur: demirden korktuğuna inanılır.'`
- Kaynak: [TDV, Alkarısı](https://islamansiklopedisi.org.tr/alkarisi)

**12. Asena kartı: kurdun adı (TARTIŞMALI).** myth_cards.dart:480-496; levels.dart:2065 "Asena'nın Mağarası".
- Çin kaynaklarındaki (*Zhoushu*) Göktürk efsanesinde dişi kurdun adı geçmez. "Aşina" hanedanın adıdır. Kurda "Asena" denmesi 20. yüzyıl Türkçesinin bir yorumudur. Kartın hikâye metni doğru (hanedanın adı bu soydan gelir).
- Öneri (whoTr): `'Göktürk türeyiş efsanesinde çocuğu kurtarıp büyüten dişi kurt; bugün Asena diye anılır.'` storyTr sonuna: `Kaynaklarda kurdun adı geçmez; Asena adı hanedanın adından türetilmiştir.`

### 0.3 Küçük, düşük riskli düzeltmeler (isteğe bağlı)

| Yer | Metin | Sorun | Öneri |
|---|---|---|---|
| levels.dart:478 / EN 632 | "Simurg, eski dilde 'otuz kuş' demektir." | Attâr'ın Farsça sözcük oyunu (sî murg). Adın asıl kökeni Avestaca *saēna* kuşudur. | `Farsçada sî murg, "otuz kuş" demektir.` |
| levels.dart:513 / EN 667 | "...yolcular ona 'kışın kapısı' der." | Böyle bir lakap bulunamadı (UYDURMA). | `...Kışı öyle sert gelir ki yolcular onu kışın kapısı sayar.` ya da tırnağı kaldırın. |
| levels.dart:502 / EN 656 | "Nemrut'ta güneş iki kez doğar, derler" | Bilinen bir söz değil (UYDURMA, "derler" ile). | `Nemrut'ta güneş iki kez doğar gibidir: bir kez gökte, bir kez taş tanrıların yüzünde.` |
| levels.dart:2223 / EN 2240 | "Ak bir geyik: Umay'ın habercisi." | Geyiğin Umay'ın habercisi olduğu bulunamadı. Jordanes'teki geyik de "ak" değil. | `Ağaçların arasında ak bir geyik. Jordanes anlatır: Hun avcılarını bataklıktan bir geyik geçirmişti.` |
| levels.dart:1784 / EN 1795 | "Çobanlar onlara peri halkası der; üstüne basan göğe çıkar" | "Peri halkası" Avrupa folkloru. Kapadokya'da bulunamadı. | `...Çobanlar perilerin dansıdır der; o ışığa yaklaşan geri dönmez.` |
| levels.dart:1030 / EN 1044 | "...birini ters, birini yan koymuşlar; kimse taşa dönmesin diye." | Gerçek neden bilinmez (bakışı etkisiz kılmak bir yorum; ölçüye uydurmak da olası). | Başa `Derler ki` ekleyin. |
| levels.dart:1666 | "orada koruyucu ruhlar, dev ejderler yaşar" | Bkz. 0.2/5 | Bkz. 0.2/5 |
| myth_cards.dart:212-220 (Ayaz Ata) | "Türk halk anlatılarında Ayaz Ata, ayazın... kişileşmiş hâlidir" | Ayaz Ata bugün Kazak ve Kırgızların yılbaşı ihtiyarı. Eski bir mit varlığı olarak kaynağı zayıf (Sovyet döneminde Ded Moroz'un karşılığı olarak yaygınlaştı). | `Kazak ve Kırgız geleneğinde kışın ve yeni yılın ak sakallı ihtiyarı; ayazın kişileşmiş hâli sayılır.` |
| myth_cards.dart:95-128 (Su İyesi) | Hakas su iyesi: ak giysili, balık kuyruklu, boynuzlu, mavi balıklar | **DOĞRULANAMADI.** Akademik bir kaynakta bu tasvir bulunamadı. Türkçe Vikipedi'deki mitoloji maddelerine benziyor; o maddeler çoğu zaman kaynaksız. | Kaynağınızı gösterin ya da genel tutun: `Eski Türk inancında suyun da iyesi vardır; Hakas ve Altay anlatılarında çoğu zaman dişi düşünülür. Kazan Tatarlarında Su Anası kıyıda altın tarağıyla saçlarını tarar (Tukay).` |
| myth_cards.dart:637 (Yel Ana) | "Kaşgarlı... bir savaşta onunla kar ve fırtına kopartıldığını anlatır" | **DOĞRULANAMADI.** Divan'daki bilinen örnek, Kaşgarlı'nın Yağma ülkesinde yaz ortasında kar yağdırılıp bir yangının söndürüldüğünü kendi gözüyle görmesidir (hafızadan; metinden kontrol edin). | `...bu büyüye "yat" der ve onu kendi gözüyle gördüğünü anlatır.` |
| levels.dart:460 | "Derler ki kanatlarını kulenin en üst katına saklamıştı" | Oyunun kurgusu, gelenek gibi duruyor. | Bkz. 0.1 |

---

## 1. Bütün iddialar, bölüm bölüm

### Giriş (levels.dart:380-392; strings.dart:196-198)
| # | İddia | Hüküm | Not / kaynak |
|---|---|---|---|
| 1 | İstanbul, Temmuz 1660; şehir iki gündür yanıyor | DOĞRU | Büyük yangın 24 Temmuz 1660'ta başladı, Abdi Paşa'ya göre ~49 saat sürdü. [Wikipedia](https://en.wikipedia.org/wiki/Great_Fire_of_1660) · [Baer, IJMES 2004](https://www.cambridge.org/core/journals/international-journal-of-middle-east-studies/article/abs/great-fire-of-1660-and-the-islamization-of-christian-and-jewish-space-in-istanbul/3256EB15CEB762616CB0AB1270102EBD) · [İstanbul Tarihi](https://istanbultarihi.ist/394-the-great-istanbul-fire-of-1660) |
| 2 | Umay düşen her çocuğun yanındadır | DOĞRU (şiirsel) | Umay çocukları ve doğumu koruyan ana tanrıça. |
| 3 | Justinianus sarnıcı "bin yılı aşkın" önce kazdırdı (:388) | DOĞRU | Yapımı 6. yüzyıl, ~532. 1660'tan ~1.128 yıl önce. |
| 4 | 336 sütun | DOĞRU | |
| 5 | Ağlayan Sütun: ölen kölelerin gözyaşı (:389) | RİVAYET ("Derler ki") | Rehberlerin anlattığı halk rivayeti. |
| 6 | Halk sarnıcı unuttu; tabandan kova sarkıtıp su çekti, balık tuttu | DOĞRU | Petrus Gyllius 1544-1545'te böyle bulduğunu anlatır. |
| 7 | Karagöz/hayal perdesi, tasvirler deve ya da manda derisinden, perdeye "ayna" denir, oynatana hayalî (myth_cards.dart:54) | DOĞRU | UNESCO 2009 de doğru. [UNESCO](https://ich.unesco.org/en/RL/karagoz-00180) |

### I · Yerebatan (levels.dart:1010-1060)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 8 | İki Medusa başı, biri ters biri yan; Roma dönemi; nereden geldikleri bilinmez (kart 137) | DOĞRU | |
| 9 | Ters/yan konmalarının nedeni "kimse taşa dönmesin" (:1030) | RİVAYET, bilgi gibi sunuluyor | Başına "Derler ki" ekleyin. Oyundaki "düz bırakılan iki baş" kurgu. |
| 10 | Perseus Medusa'ya cilalı kalkanından baktı (:1031, kart 137) | DOĞRU | Yunan miti. |
| 11 | Su İyesi (cameo, kart) | DOĞRULANAMADI (ayrıntılar) | Bkz. 0.3 |
| 12 | Hüdhüd: Neml suresinde Süleyman'a Sebe haberini getirir; Attâr'da kuşlara yol gösterir (kart 65) | DOĞRU | |
| 13 | 1660'ta Medusa başlarının görülmesi | Kurgu | Başlar 1985 temizliğinde ortaya çıktı; perde rüyası olarak sorun değil. |

### II · Kule / Galata (levels.dart:455-461, 1120-1170)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 14 | Galata Kulesi = Cenevizlilerin İsa Kulesi | DOĞRU | Christea Turris, 1348. |
| 15 | Hezarfen = "bin fen bilen" | DOĞRU | Hezâr (bin) + fen. |
| 16 | IV. Murad döneminde | DOĞRU (Evliya'ya göre) | |
| 17 | "Otuz yıl önce" | Kabul edilebilir | Evliya tarih vermez; 1623-1640 aralığı. |
| 18 | Okmeydanı'nda kartal kanatlarıyla denemeler | DOĞRU (Evliya) | |
| 19 | "dokuz kez düştü, dokuz kez kalktı" | YANLIŞ ayrıntı | Bkz. 0.1 |
| 20 | Lodosla Galata'dan Üsküdar Doğancılar'a | DOĞRU (Evliya'ya göre, "Evliya Çelebi anlatır" çerçevesiyle) | |
| 21 | Bir kese altın + "korkulacak adam" sözü + Cezayir sürgünü | DOĞRU (Evliya'ya göre) | |
| 22 | Gurbette öldü | DOĞRU (Evliya'ya göre) | |
| 23 | Kanatları kulenin en üst katına sakladı ("Derler ki") | UYDURMA (kurgu) | Düşük risk |
| 24 | Kart: tek kaynak Evliya | DOĞRU | |

### III · Gökyolu (levels.dart:462-469)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 25 | Lagari "Hezarfen'in kardeşi olduğu söylenen" | TARTIŞMALI (Evliya'da yok) | Bkz. 0.1 |
| 26 | Sarayburnu'nda yedi kollu fişek | DOĞRU (Evliya) | 1632-33, Kaya Sultan'ın doğum şenliği. |
| 27 | Denize düştü, yüzdü, "İsa sana selam söyledi" | DOĞRU (Evliya) | |
| 28 | Gökyolu kuşların ve ölülerin köprüsü ("Eskiler... söyler") | RİVAYET | Türk dillerinde Samanyolu'nun adı "Kuş Yolu"; ruhların yolu inancı da var. Uygun. |
| 29 | Tulpar, yiğidin kanatlı atı | DOĞRU | Kazak ve Kırgız. |

### IV · Kaf (levels.dart:470-476, 1280-1320)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 30 | Kaf dünyayı yüzük gibi sarar, zümrüttendir | DOĞRU | İslam kozmolojisi. |
| 31 | "Ardında ne gece vardır ne gündüz" | RİVAYET (kaynağı doğrulanamadı) | "Eskiler derdi ki" çerçevesi yeterli. |
| 32 | Simurg kuşların padişahı, Kaf'ta | DOĞRU | |
| 33 | Hüdhüd Süleyman'ın habercisi, yolu bilen kuş | DOĞRU | |
| 34 | Yedi vadi: talep, aşk, marifet, istiğna, tevhid, hayret, fakr ü fenâ | DOĞRU | "Yokluk" = fakr ü fenâ. |
| 35 | Yalnız otuz kuş vardı; aynada kendilerini gördüler | DOĞRU | |
| 36 | "Simurg eski dilde otuz kuş demektir" | TARTIŞMALI (sözcük oyunu) | Bkz. 0.3 |
| 37 | "Sâye eski dilde gölge" | DOĞRU | Farsça *sâye*. |
| 38 | Şehname'de Simurg Zal'i büyütür (kart 201) | DOĞRU | |
| 39 | Üç tüy, ayna salonu | Kurgu | |

### V · Ağrı (levels.dart:477-485, 1330-1390)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 40 | Ermeniler Masis der | DOĞRU | |
| 41 | "dünyanın anası" | TARTIŞMALI | Bkz. 0.2/7 |
| 42 | Kürtçe Çiyayê Agirî = ateşli dağ | RİVAYET (halk etimolojisi) | "derler" ekleyin. |
| 43 | Zirvesine çıkılmaz | DOĞRU (1660 için) | İlk tırmanış 1829 (Parrot). Ermeni kilisesi zirveye çıkılamayacağını öğretirdi. |
| 44 | Aziz Hakob gemiyi görmek için tırmandı, uyuyunca hep başladığı yerde uyandı, bir melek ona gemiden bir tahta getirdi | RİVAYET, doğru aktarılmış | Bizanslı Faustus'un anlattığı Nusaybinli Yakup efsanesi. Tahta Eçmiadzin'de. |
| 45 | Akori: Nuh ilk asmayı burada dikti ("derler ki") | RİVAYET, doğru çerçeve | Ermenice "Arkuri" halk etimolojisi. |
| 46 | Aziz Hakob Manastırı (Akori) 1660'ta ayakta | DOĞRU | 1840 depremi ve heyelanında yıkıldı. |
| 47 | "Ağrı Dağı · Bayezid, Ekim 1660" | DOĞRU | Doğubayazıt'ın eski adı. |
| 48 | Ayaz Ata | TARTIŞMALI (kart) | Bkz. 0.3 |

### VI · Nuh'un Gemisi (levels.dart:486-493, 1395-1440)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 49 | Kırk gün kırk gece yağmur | DOĞRU | Tekvin 7:12 |
| 50 | Gemi aylarca sürüklendi | DOĞRU | 150 gün |
| 51 | Önce kuzgun (dönmedi), sonra zeytin dalıyla dönen güvercin | DOĞRU (sadeleştirilmiş) | Tekvin 8: güvercin ilk seferde boş döner, ikincisinde zeytin yaprağıyla. |
| 52 | Her canlıdan bir çift | DOĞRU | Temiz hayvanlardan yedişer çift ayrıntısı atlanmış; sorun değil. |
| 53 | Tevrat "Ararat dağları", Kur'an Cudi (Hûd 44) (kart 229) | DOĞRU | |
| 54 | Hiç sönmeyen ışık | Kurgu | Yahudi midraşında gemiyi aydınlatan parlak bir taş (*tzohar*) anlatılır; ilginç bir dayanak. |
| 55 | Ak Ana (cameo) | RİVAYET | Bkz. 113 |

### VII · Nemrut (levels.dart:494-500, 1460-1500)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 56 | Kommagene, Fırat'ın ötesi, Kâhta | DOĞRU | |
| 57 | Antiokhos'un babası Pers, annesi Yunan | DOĞRU | Baba I. Mithridates Kallinikos (Pers/Orontid soyunu öne çıkarır), anne Seleukos prensesi Laodike. |
| 58 | Zeus-Oromasdes, Apollon-Mithras, Herakles-Artagnes; arada kendi tahtı | DOĞRU | Ayrıca Kommagene tanrıçası. |
| 59 | Taştan tümülüs, altına gömülü | DOĞRU (geleneksel kabul) | Mezar odası bulunamadı. |
| 60 | Vasiyet: "ruhum tanrıların katına..." (şiirsel aktarım) | DOĞRU (anlam olarak) | |
| 61 | 237 satırlık yazıt (:1482) | DOĞRU | Kültür Varlıkları ve Müzeler GM. Kimi rehber 234 der. [Google Arts & Culture](https://artsandculture.google.com/story/qAXhBnA8A6xqyg) |
| 62 | Depremler başları düşürdü | DOĞRU (yaygın kabul) | Kasıtlı tahribat da tartışılır. |
| 63 | "Bu dağı bugün kimse bilmiyor" (1660) | DOĞRU | 1881'de Karl Sester buldu. |
| 64 | Kral tanrılarla el sıkışırken (dexiosis kabartmaları) | DOĞRU | |
| 65 | UNESCO 1987 (kart) | DOĞRU | |

### VIII · Gün Doğumu (levels.dart:501-508, 1530-1560)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 66 | Halk dağa Nemrud'un adını verdi | DOĞRU (halk bağlantısı) | |
| 67 | Nemrud dört kartallı sandıkla göğe çıktı; ok kanlı döndü | RİVAYET, doğru | İslami kısas-ı enbiyâ. |
| 68 | İbrahim ateşe atıldı, ateş gül bahçesine döndü | RİVAYET, doğru | Enbiyâ 69 (ateş "serin" olur); gül bahçesi Urfa geleneği. |
| 69 | Sivrisinek burnundan beynine girdi, başına tokmak vurduruldu | RİVAYET, doğru | |
| 70 | "Güneş iki kez doğar, derler" | UYDURMA (hafif) | Bkz. 0.3 |
| 71 | Tepegöz; aslanlar arasında büyüyen Basat; kızgın şişle kör eder, devin kılıcıyla başını keser (kart 268) | DOĞRU | Dede Korkut |

### IX-XI · Kar Yolu, Palandöken, Çığ (levels.dart:509-531, 1590-1745)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 72 | Erzurum = Theodosiopolis | DOĞRU | II. Theodosius |
| 73 | "Selçukluların Erzen-i Rum'u" | DOĞRU (aşağı yukarı) | Ad, 1049'da yıkılan Erzen halkının taşınmasından gelir; İslam kaynaklarında "Erzen-i Rûm". |
| 74 | "kışın kapısı" lakabı | UYDURMA (hafif) | Bkz. 0.3 |
| 75 | Palandöken = palan döken (kervanların semeri kayar) | RİVAYET, doğru çerçeve (derler, -mış) | Yaygın halk etimolojisi. [Sabah](https://www.sabah.com.tr/palandoken) |
| 76 | Evliya: Erzurum'da damdan dama atlayan kedi havada donar (:1600) | DOĞRU (yaygın aktarım) | Seyahatnâme II, Erzurum. Asıl ibareyi bu incelemede görmedim. |
| 77 | Büyük Ejder doruğu | DOĞRU | ~3.176 m |
| 78 | Küçük Ejder doruğu | DOĞRULANAMADI | |
| 79 | İki ejder kardeş, derviş, yedi gün kar ("Erzurum'un yaşlıları anlatır") | UYDURMA | Bkz. 0.2/5 |
| 80 | "Erzurum'un yaşlıları der ki Ejder uyurken dağ susar" | UYDURMA | Bkz. 0.2/5 |
| 81 | Donmuş kervan efsanesi ("Erzurum'un yaşlıları anlatır") | UYDURMA | Bkz. 0.2/5 |
| 82 | Dağ doruğu kutsaldır (eski inanç) | DOĞRU | Iduk yer-sub, dağ iyesi |
| 83 | Gökbörü Oğuz'un ordusuna yol gösterdi | DOĞRU | Oğuz Kağan (Uygur harfli nüsha): "gök tüklüg gök yallıg erkek böri". |
| 84 | Manyetik Tepe | Kurgu (göz yanılması) | Sorun yok |
| 85 | KURGU.md: "Tabyalar 1884-1896" | DOĞRULANAMADI | Erzurum tabyalarının çoğu 1850'ler-1870'lerde yapıldı (ör. Aziziye). Yalnızca not dosyası. |

### XII · Peri Bacaları (levels.dart:532-539, 1760-1810)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 86 | Katpatuka = güzel atlar ülkesi | TARTIŞMALI | Bkz. 0.2/9 |
| 87 | Erciyes ve Hasan Dağı'nın külleri aşındı | DOĞRU | Göllüdağ da var. |
| 88 | "Rüzgâr bin yıl oydu" | YANLIŞ (ölçek) | Milyonlarca yıl; yağmur ve rüzgâr. Bkz. 0.2/9 |
| 89 | Muşkara = bugünkü Nevşehir; 1660'ta köy | DOĞRU | 1720'lerde Damat İbrahim Paşa şehre çevirdi. |
| 90 | Devler, Peri Padişahı (Sultanı), devler yeraltına; insanlar aşağıda, periler yukarıda | RİVAYET (turizm anlatısı) | Bir halk derlemesinde bulamadım; popüler kaynaklarda aynı çizgide anlatılıyor ([Pegasus blog](https://www.flypgs.com/blog/?p=6710)). "Kar ve buz", "küllerden yükselen bacalar" oyunun eklemesi. "Eskiler/derler" ile sunulduğu için kabul edilebilir. |
| 91 | Peri bacalarının jeolojisi (kart 321) | DOĞRU | |
| 92 | Hemzat: her insanla doğan peri eşi | RİVAYET, doğru | Farsça *hemzâd*, Anadolu inancı. |
| 93 | Güvercin gübresi bağlar için | DOĞRU | |
| 94 | Kaya kilisesindeki tasvirlerin gözleri kazınmış (iki açıklama) | DOĞRU | "kimi der" çerçevesi iyi. |
| 95 | Peri halkası | UYDURMA (hafif) | Bkz. 0.3 |
| 96 | Albastı kızıl, demirden korkar | DOĞRU (demir) / TARTIŞMALI ("kızıl saçlı") | Bkz. 0.2/11 |
| 97 | Uçhisar | DOĞRU | |

### XIII · Derinkuyu (levels.dart:540-546, 1840-1870)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 98 | Sekiz kat | DOĞRU | ~85 m; ziyarete açık sekiz kat |
| 99 | Ahırlar, şaraphaneler, şapel, kuyular, havalandırma bacaları | DOĞRU | |
| 100 | Yuvarlak taş kapılar yalnız içeriden açılır | DOĞRU | |
| 101 | 20.000 kişi ("Derler ki") | RİVAYET, doğru çerçeve | Yaygın tahmin |
| 102 | Kimi Friglere der; Bizans'ta genişletildi; 1963'te bir ev onarımında bulundu (kart) | DOĞRU | |
| 103 | Alçak geçitler düşman eğilsin diye | DOĞRU (yaygın açıklama) | |

### XIX · Şeb-i Arûs / Konya (levels.dart:547-555, 1885-1960) ve XX · Yeşil Kubbe (598-603, 2330-2390)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 104 | "Kon ya!" uçan dervişler ("Rivayet ederler") | RİVAYET, doğru çerçeve | Bilinen halk etimolojisi |
| 105 | Höyükteki eski şehir: kapısız evler, damdan merdivenle girilir, ölüler tabana gömülür, boğa boynuzları, iki pars arasında oturan ana tanrıça, ~9.000 yıl | DOĞRU | Çatalhöyük (Çumra, Konya Ovası). "Ana tanrıça" yorumu tartışılır ama yaygın. 1660'ta bilinmiyordu (1958'de bulundu); anlatıcının sesi olarak sorun değil. |
| 106 | Nannakos: tufan öncesi kral, kâhin, "Nannakos gibi ağlamak", 300 yıl yaşadı | RİVAYET, doğru | Bizanslı Stephanos, *Ethnika*; Suda. [Wikipedia, Nannacus](https://en.wikipedia.org/wiki/Nannacus) |
| 107 | Tufandan sonra Prometheus ve Athena çamurdan suretler yaptı, rüzgârlar can verdi → İkonion; "Frigler derdi ki" | RİVAYET, doğru | Stephanos'ta rüzgârların can üflemesi de geçer (asıl metinden bakmadım). Anlatı Frig kralına dair; "Frigler derdi" kabul edilebilir. |
| 108 | Perseus Medusa'nın başıyla şehri kurdu, ad "ikon"dan | RİVAYET, doğru ("Bir başka rivayete göre") | Bizans dönemi etimolojisi (Eustathios). |
| 109 | Medusa kendi yansımasıyla taşa döner | UYDURMA | Bkz. 0.2/8 |
| 110 | Alâeddin Tepesi, sultanların köşkü; çinilerde kanatlı figürler, çift başlı kartal, ay yüzlüler | DOĞRU | II. Kılıç Arslan Köşkü çinileri; çift başlı kartal Konya surlarında da var. |
| 111 | "Konya bütün Anadolu'nun başkenti" | TARTIŞMALI (abartı) | Bkz. 0.2/8 |
| 112 | Belh'ten Moğollardan kaçış | TARTIŞMALI | Bkz. 0.2/8 |
| 113 | Nişabur'da Attâr, kitap, kehanet | RİVAYET (-mış ile doğru) | Câmî, Devletşah. Ritter'e göre kuşkulu. |
| 114 | Mevlânâ = "efendimiz" | DOĞRU | |
| 115 | Karatay: kubbe gök gibi çinili, tepe açıklığı ve havuz | DOĞRU | 1251. Talebelerin göğü suda okuduğu kısmı RİVAYET (-mış ile doğru). |
| 116 | İnce Minare, şerefeli | DOĞRU | 1279, Sahib Ata. Üst kısmı 1901'de yıldırımla yıkıldı; 1660'ta tamdı. |
| 117 | Şems Konya'ya geldi (1244), Mevlânâ kitaplarını bıraktı, "Şems = güneş" | DOĞRU (karşılaşma ayrıntısı menkıbe) | TDV |
| 118 | Şems kayboldu: kimi gitti der, kimi öldürülüp kuyuya atıldı der | RİVAYET, doğru çerçeve | Eflâkî'de kuyu anlatısı var. |
| 119 | Mevlânâ onu Şam'a kadar aradı | DOĞRU | En az iki Şam yolculuğu. |
| 120 | "Aradığımı kendimde buldum" | RİVAYET (yaygın özet) | Divan'daki duyguya uyan bir aktarım; birebir söz değil. |
| 121 | Direğin çevresinde dönüş, semânın doğuşu | RİVAYET, bilgi gibi sunuluyor | Bkz. 0.2/8 |
| 122 | Mevlânâ 17 Aralık 1273'te öldü; "Ağlamayın, bu benim düğünümdür" | DOĞRU (tarih Jülyen) / RİVAYET (söz) | TDV: cenazesinde ağlanmamasını istedi, ölümü kavuşma saydı. |
| 123 | 17 Aralık 1660 Şeb-i Arûs | YANLIŞ (takvim) | Bkz. 0.2/1 |
| 124 | Sikke nefsin mezar taşı, tennure kefeni; sağ el göğe, sol el yere: Hak'tan alır halka verir | DOĞRU | Mevlevî sembolizmi |
| 125 | Neyin kamışlıktan ayrılık şikâyeti | DOĞRU | Mesnevî'nin girişi |
| 126 | Kubbe-i Hadrâ = Yeşil Kubbe, Mevlânâ'nın türbesi | DOĞRU | |
| 127 | Mevlevî semâsı UNESCO 2008 (kart 581) | DOĞRU | 2005'te ilan edildi, 2008'de listeye girdi. |
| 128 | (XX) Gümüş kapı, şadırvan, sandukalarda sikke | DOĞRU | Gümüşlü Kapı 1599, Hasan Paşa'nın armağanı. |
| 129 | (XX) Kapının üstünde Mesnevî'nin ilk beyti | YANLIŞ | Bkz. 0.2/2 |

### XV · Erlik'in Katı (levels.dart:556-564, 1965-2010)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 130 | Başlangıçta yalnız su; Kayra Han; sudan Ak Ana çıkıp "Yarat" der | RİVAYET, doğru ("Ozan der ki") | Radloff'un Altay derlemesi (Türkçede Ögel aracılığıyla yayıldı). |
| 131 | Erlik kendini büyük sandı, yerin altına sürüldü | RİVAYET, doğru | |
| 132 | Er Töştük yerin altına düşer, konuşan atı Çalkuyruk yol gösterir | DOĞRU | Kırgız destanı (Radloff derlemesi). |
| 133 | Körmösler Erlik'e bağlı yeraltı ruhları | DOĞRU | |
| 134 | Kut, Gök Tengri'nin verdiği kutsal güç; Orhun Yazıtları'nda anılır | DOĞRU | |
| 135 | Kutların kafeslerde tutulması | Kurgu | |

### XVI · Ergenekon (levels.dart:565-573, 2050-2110)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 136 | "Türklerin ataları" | TARTIŞMALI | Bkz. 0.2/6 |
| 137 | Kıyan ile Nüküz eşleriyle kurtuldu | DOĞRU (kaynağa uygun) | |
| 138 | Keçi yolundan dar yol; çayırlı, ırmaklı, meyveli vadi | DOĞRU | Ebülgâzî |
| 139 | Dört yüz yıl | DOĞRU | |
| 140 | Bir demircinin önerisi, odun ve kömür, yetmiş deri körük | DOĞRU | |
| 141 | Yüklü bir devenin geçeceği yol | DOĞRU | |
| 142 | "Kimi anlatılar, yolu bir boz kurdun gösterdiğini söyler" (:570) | DOĞRU çerçeve | Kurt sonraki anlatılarda var. |
| 143 | Her yıl demir kızdırılıp dövülür | DOĞRU | Reşîdüddîn (Moğol hanlarının töreni) |
| 144 | "Bu güne Nevruz derler" (:2086) | TARTIŞMALI | Bkz. 0.2/6 |
| 145 | Göktürk efsanesi: dişi kurt, son çocuk, dağlarla çevrili ovaya açılan mağara, Aşina (kart 485-488; :2083) | DOĞRU | *Zhoushu* |
| 146 | Kurdun adı Asena | TARTIŞMALI | Bkz. 0.2/12 |
| 147 | Gökbörü kartı: "Ergenekon anlatısında da... kurt gösterir" | TARTIŞMALI | Bkz. 0.2/6 |

### XVII · Göğün Katları (levels.dart:574-580, 2130-2170)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 148 | Altay kamları göğün katlı olduğunu anlatır | DOĞRU | 17 kat (Altay) |
| 149 | "En yüksek katta Ülgen" | TARTIŞMALI | Bkz. 0.2/10 |
| 150 | Gök bir çadır, yıldızlar delikleri | DOĞRU | Ögel |
| 151 | Demir Kazık = Kutup Yıldızı; Ak Boz At ile Kök Boz At; Yedi Karakçı (Büyük Ayı) atları çalmak ister; çalınırsa dünyanın sonu | DOĞRU | Kazak/Kırgız: Temirkazık, Jeti Karakşı. |
| 152 | Yel Ana | DOĞRU | Ögel |
| 153 | Yada taşı ile yağmur, kar, rüzgâr | DOĞRU | DLT'de "yat". Kartın savaş anekdotu doğrulanamadı (bkz. 0.3). |
| 154 | Kam davulu bineği; derisinde gök, yer, hayat ağacı (kart) | DOĞRU | |

### XVIII · Ötüken (levels.dart:581-590, 2210-2260)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 155 | Kül Tigin: ili tutacak yer Ötüken ormanı, ondan iyisi yok | DOĞRU | "Ötüken yışda yig idi yok ermiş" |
| 156 | Ötüken Yış, Hangay dağları; ıduk yer-sub (kart) | DOĞRU | |
| 157 | Kül Tigin'in annesi "Umay gibi" (kart) | DOĞRU | "Umay teg ögüm katun kutıña" |
| 158 | Hayat Ağacı; Yakutça Aal Luuk Mas; çocuk canları kuş olup dallara konar | DOĞRU | Yakut ve Altay |
| 159 | Umay dallarda oturur | RİVAYET (birleştirme) | Kuş-ruhlar ve ağaç Yakut inancı, Umay Altay/Göktürk. Şiirsel birleştirme, kabul edilebilir. |
| 160 | Karabasan: uyku felci, yastık altına demir ya da Kur'an | DOĞRU | |
| 161 | Hun avcılarını Meotis bataklığından geyik geçirdi (Jordanes/Priskos) | DOĞRU | Jordanes'te geyik "ak" değil. |
| 162 | Kırgız Bugu boyu ve Boynuzlu Geyik Ana | DOĞRU | |
| 163 | Ak geyik "Umay'ın habercisi" | UYDURMA (hafif) | Bkz. 0.3 |
| 164 | Çaput bağlama geleneği | DOĞRU | |

### XIX (sıra) · Gün Katı / Ülgen'in Kapısı (levels.dart:591-597, 2290-2310)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 165 | Hüma: gölgesi düştüğü kişiye talih ve hükümdarlık getirir, hiç konmaz, "devlet kuşu" | DOĞRU | Fars-Türk geleneği |
| 166 | Hüma ile Umay'ın birlikte anılması (kart adı "Umay kuşu") | TARTIŞMALI (hafif) | Ögel gibi yazarların yorumu; kabul edilebilir. |
| 167 | Süge Toyon: Yakut gök gürültüsü tanrısı, adı "balta efendi", kötü ruhlara yıldırım indirir; yıldırımın çarptığı ağaç kutsal | DOĞRU (büyük ölçüde) | *Süge* Sahaca balta ([WOLD](https://wold.clld.org/word/71312353832570322)), *toyon* efendi. Tanrının işlevi Rus etnografyasında (*Mify narodov mira*) böyle anlatılır; bu incelemede birincil kaynağa ulaşamadım. |
| 168 | Ay Ata, Gün Ana; Oğuz'un oğullarından ikisi Gün ve Ay (kart) | DOĞRU ("kimi anlatılarda" çerçevesi) | |

### Son (levels.dart:410-427) ve Hakkında / Hikâye (strings.dart:196-218)
| # | İddia | Hüküm | Not |
|---|---|---|---|
| 169 | "Mevlânâ'nın düğün gecesi" | DOĞRU | |
| 170 | Semâhanede ney | DOĞRU | |
| 171 | storyAct4Text "Konya, 17 Aralık 1660" | YANLIŞ (takvim) | Bkz. 0.2/1 |

### docs/ notları
| Yer | İddia | Hüküm |
|---|---|---|
| KURGU.md "Zaman çizgisi" | 24 Temmuz 1660, ~iki gün | DOĞRU |
| KURGU.md | 17 Aralık 1660 = vefatın 387. yılı; 1660'ta semâhanede sade bir gece | YANLIŞ (takvim): 1660'ta anma hicrî tarihteydi (bkz. 0.2/1) |
| KURGU.md | 1660'ta Nevşehir henüz Muşkara | DOĞRU |
| KURGU.md | Tabyalar 1884-1896 | DOĞRULANAMADI (bkz. 85) |
| MITOLOJI.md §3 | Ergenekon'da çıkış yolunu bir kurt bulur | TARTIŞMALI (sonraki anlatılarda) |
| MITOLOJI.md §5 | Çıkış günü Nevruz olarak anılır | TARTIŞMALI |
| MITOLOJI.md §1 | Eski Türkçede kurt "börü" | DOĞRU |
| MITOLOJI.md §9 | Kaynak listesi (Ögel, Oğuz Kağan, Reşîdüddîn, Ebülgâzî, Zhoushu, Dede Korkut, Er Töştük, Radloff) | Uygun. Ergenekon'un Moğol çerçevesi ve Asena adı için not eklenmeli. |

---

## 2. Kullanılan başlıca kaynaklar

- TDV İslâm Ansiklopedisi: [Hezârfen Ahmed Çelebi](https://islamansiklopedisi.org.tr/hezarfen-ahmed-celebi) · [Hasan Çelebi, Lâgarî](https://islamansiklopedisi.org.tr/hasan-celebi-lagari) · [Mevlânâ Celâleddîn-i Rûmî](https://islamansiklopedisi.org.tr/mevlana-celaleddin-i-rumi) · [Şeb-i Arûs](https://islamansiklopedisi.org.tr/seb-i-arus) · [Mevlânâ Külliyesi](https://islamansiklopedisi.org.tr/mevlana-kulliyesi) · [Alkarısı](https://islamansiklopedisi.org.tr/alkarisi)
- 1660 yangını: [Wikipedia](https://en.wikipedia.org/wiki/Great_Fire_of_1660) · [Baer 2004, IJMES](https://www.cambridge.org/core/journals/international-journal-of-middle-east-studies/article/abs/great-fire-of-1660-and-the-islamization-of-christian-and-jewish-space-in-istanbul/3256EB15CEB762616CB0AB1270102EBD) · [istanbultarihi.ist](https://istanbultarihi.ist/394-the-great-istanbul-fire-of-1660)
- [Wikipedia, Hezârfen](https://en.wikipedia.org/wiki/Hez%C3%A2rfen_Ahmed_%C3%87elebi) · [Istanbul Beneath My Wings](https://en.wikipedia.org/wiki/Istanbul_Beneath_My_Wings)
- [Wikipedia, Mount Ararat](https://en.wikipedia.org/wiki/Mount_Ararat) · [Wikipedia, Cappadocia](https://en.wikipedia.org/wiki/Cappadocia) · [Hürriyet DN, Kapadokya adı](https://hurriyetdailynews.com/does-cappadocia-mean-the-land-of-beautiful-horses--87789)
- [Wikipedia, Nannacus](https://en.wikipedia.org/wiki/Nannacus) · [Wikipedia, Epic of Ergenekon](https://en.wikipedia.org/wiki/Epic_of_Ergenekon) · [Zoriktuev (Ergene-Kun)](https://archaeology.nsc.ru/en/publications/jr-aeae-en/15-43-3/annot-09/)
- [Google Arts & Culture / KVMGM, Nemrut](https://artsandculture.google.com/story/qAXhBnA8A6xqyg) · [Wikipedia, Mevlâna Museum](https://en.wikipedia.org/wiki/Mevl%C3%A2na_Museum)
- [Kür Ansiklopedi, Şeb-i Arus](https://kureansiklopedi.com/tr/detay/seb-i-arus-d51ac) · [Sabah, Palandöken](https://www.sabah.com.tr/palandoken) · [Hürriyet DN, Palandöken](https://hurriyetdailynews.com/palandoken-at-the-peak-of-anatolia-151365) · [Pegasus blog, peri efsanesi](https://www.flypgs.com/blog/?p=6710) · [WOLD, Sahaca süge](https://wold.clld.org/word/71312353832570322)
- Hicrî-Gregoryen dönüşümleri tablo (aritmetik) takvimle hesaplandı. Gerçek hilal gözlemiyle ±1-2 gün sapabilir.

**Bu incelemede birincil metninden görülemeyenler:** Seyahatnâme'nin Osmanlıca ibaresi (TDV ve Dankoff aktarımına dayanıldı), Stephanos'un İkonion maddesi, DLT'nin "yat" maddesi, Süge Toyon için Rusça etnografya, Su İyesi'nin Hakas tasviri. Bunlar için Ögel'in *Türk Mitolojisi* ve Dankoff-Kahraman-Dağlı'nın Seyahatnâme baskısı (YKY) en hızlı kontrol yolu.
