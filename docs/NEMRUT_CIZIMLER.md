# Nemrut heykel çizimleri: kaynak ve lisans

assets/images/nemrut altındaki görseller, kullanıcının sağladığı SVG paketinden tools/import_nemrut_svg.py ile üretilmiştir. Paketin özgün kullanım ve atıf notu aşağıda aynen korunmuştur (atıf bilgileri bu notla korunmalıdır).

---

# Nemrut SVG çizim paketi

Üç saydam SVG ve yüksek çözünürlüklü PNG karşılıkları:
- `nemrut_zeus_head.svg`: Nemrut Zeus başından esinlenen stilize çizim; 540 × 720 viewBox.
- `nemrut_eagle_head.svg`: koruyucu kartal başı; 540 × 680 viewBox.
- `nemrut_stone_giant.svg`: özgün Nemrut muhafızı; 640 × 840 viewBox.

SVG'ler raster fotoğraf içermez. Yüzeyler, gözler, çatlaklar ve taş dokuları vektördür. İnce doku `*-texture` grupları kaldırılarak sadeleştirilebilir. Zeus dosyasındaki `snow` grubu başlangıçta görünmezdir (opacity=0). Çizimler, arkeolojik ölçüm veya restitüsyon olarak sunulmaz.

## Taş dev ve animasyon

Taş devin baş, gövde, el, kol ve bacak grupları ayrıdır. `rig.json` nötr pozdaki dönüş merkezlerini, zemin ve kulak hedeflerini tanımlar. SVG sabit bir çizimdir; yürüyüş veya saldırı animasyonu henüz uygulanmamıştır. Düz SVG grupları, tek başına hiyerarşik iskelet oluşturmaz. Oyun entegrasyonunda omuz-dirsek-bilek ve kalça-diz-ayak dönüşleri birlikte hesaplanmalıdır. Omuz plakaları ilgili üst kolla birlikte taşınmalıdır.

Önerilen hareket: destek ayağını zeminde sabitle; diğer ayağı kaldırıp öne taşı; kalçayı destek ayağına kaydır; gövdeye gecikmeli ağırlık ver. Ses ve sarsıntıyı aynı ayak temas anından tetikle. İlk hedefler: bekleme, ağır yürüyüş, sendeleme, düşüş.

Kulak hedefi çizimde (390,183), yer teması (320,801). Dünya konumu ayak hizasındaysa yerel çizim, ölçeklendirmeden önce bu zemin noktasına göre kaydırılmalıdır. Kulak dünya koordinatı aynı dönüş zincirinden hesaplanmalıdır. Mevcut oyunda `StoneGiant.render()` pozitif y'de çizerken `ear` hedefi negatif y'de hesaplanıyor; yalnızca görseli değiştirmek bu uyuşmazlığı çözmez.

## Entegrasyon ve performans

Bu paket oyun deposunu değiştirmez. Oyunda görsel kontrol ve cihaz performans testi yapılmamıştır. Inkscape ile SVG→PNG çıktıları alındı; XML yapısı ve saydamlık kontrol edildi. SVG renderer uyumluluğu kullanılan pakete göre ayrıca doğrulanmalıdır.

Sabit heykelleri her karede yeniden ayrıştırmayın. Oyundaki gerçek boyutuna uygun PNG atlası veya önbelleğe alınmış çizim kullanın. Dev için hareketli parçalar ayrı raster varlıklar olarak dışa aktarılabilir; karakter uzuvlarının ortak ölçek ve dönüş merkezleri korunmalıdır. 1200 piksel genişlikteki PNG'ler inceleme/ana kaynak içindir; mobilde görünen boyuta göre daha küçük atlas üretin.

## Referans ve kaynak notları

Heykel başının oranları ve taş biçimleri için T.C. Kültür ve Turizm Bakanlığı Kültür Portalı, Nemrut Ören Yeri sayfasındaki fotoğraflar görsel referans olarak incelendi. Fotoğraflar pakete gömülmedi veya dağıtılmadı. Çizim fotoğrafın otomatik izlenmesi değildir; elle kodlanmış stilize yorumdur.
https://www.kulturportali.gov.tr/turkiye/adiyaman/gezilecekyer/nemrut-dagi
https://www.kulturportali.gov.tr/contents/images/_R1A1055%20kopya.jpg

Kartal için ek görsel referans: Vincent Vega, “NemrutEagle.jpg”, 24 Temmuz 2022, Wikimedia Commons, CC BY-SA 4.0. Kartalın SVG/PNG yorumu ve bunları içeren önizleme, bu referansla bağlantılı olarak CC BY-SA 4.0 koşullarıyla sunulur; değişiklik: yeniden çizilmiş, sadeleştirilmiş vektör ve farklı renk düzeni. Fotoğrafın kendisi pakete dahil değildir.
https://commons.wikimedia.org/wiki/File:NemrutEagle.jpg
https://creativecommons.org/licenses/by-sa/4.0/

Taş dev, tarihî bir Nemrut heykelinin birebir kopyası değildir; oyun için özgün bir yorumdur.


## Genişletilmiş paket — beş yeni heykel başı

- `nemrut_antiochos_head.svg`: sakalsız kral başı; geniş başlık ve yan örtüler.
- `nemrut_kommagene_head.svg`: meyveli taç, örgülü bant ve örtü.
- `nemrut_apollon_head.svg`: sivri başlık, uzun burun, sakalsız yüz.
- `nemrut_herakles_head.svg`: ağır kaş, yoğun taş sakal kıvrımları, kabartmalı başlık.
- `nemrut_lion_head.svg`: geniş alın, yuvarlak kulaklar, aşınmış burun ve kırık ağız.

Hepsi 540 × 720 viewBox kullanır ve arka planları saydamdır. Başlık, yüzey, göz, burun, ağız, çatlak ve ince doku grupları ayrı düzenlenebilir. Bunlar tamamı yeni çizilmiş stilize baş varlıklarıdır; oturan tam gövdelerin ölçülü rekonstrüksiyonları değildir. Farklı fotoğraflardaki ışık ve perspektif, ortak oyun paletine uyarlandı. Yüzlerdeki bazı kırıklar oyun okunabilirliği için sadeleştirildi. Tarihî fotoğraf arşivlerinde özellikle Apollon/Antiochos adlandırmaları değişebildiğinden çizimler kesin arkeolojik teşhis belgesi olarak kullanılmamalıdır.

Ek görsel referanslar (fotoğraflar dağıtılmıyor):

1. Antiochos: Dosseman, “Nemrut Head of Antiochus I in 2006 1556.jpg”, “...1553.jpg” ve “Nemrut Head of Antiochus I and others on east terrace in 2006 1434.jpg”, CC BY-SA 4.0.
https://commons.wikimedia.org/wiki/File:Nemrut_Head_of_Antiochus_I_in_2006_1556.jpg
https://commons.wikimedia.org/wiki/File:Nemrut_Head_of_Antiochus_I_in_2006_1553.jpg
https://commons.wikimedia.org/wiki/File:Nemrut_Head_of_Antiochus_I_and_others_on_east_terrace_in_2006_1434.jpg

2. Kommagene: Dosseman, “Nemrut Head of Comagene goddess Tyche in 2006 1564.jpg” ve “...1568.jpg”, CC BY-SA 4.0.
https://commons.wikimedia.org/wiki/File:Nemrut_Head_of_Comagene_goddess_Tyche_in_2006_1564.jpg
https://commons.wikimedia.org/wiki/File:Nemrut_Head_of_Comagene_goddess_Tyche_in_2006_1568.jpg

3. Apollon: Bernard Gagnon, “Nemrut Dağı 09.jpg”, CC BY-SA 3.0 (sunulan alternatif lisanslardan biri).
https://commons.wikimedia.org/wiki/File:Nemrut_Dağı_09.jpg

4. Herakles: Carole Raddato, “Head of Heracles Artagnes Ares on the West terrace of Nemrut Dagı, the tomb of king Antiochus I Theos of Commagene (ruled 70-31 BCE), Turkey (35214876973).jpg”, CC BY-SA 2.0.
https://commons.wikimedia.org/wiki/File:Head_of_Heracles_Artagnes_Ares_on_the_West_terrace_of_Nemrut_Dagı,_the_tomb_of_king_Antiochus_I_Theos_of_Commagene_(ruled_70-31_BCE),_Turkey_(35214876973).jpg

5. Aslan: Bernard Gagnon, “Nemrut Dağı 05.jpg”, CC BY-SA 3.0 (sunulan alternatif lisanslardan biri).
https://commons.wikimedia.org/wiki/File:Nemrut_Dağı_05.jpg

Bu beş stilize SVG/PNG yorumu ve tümünü gösteren yeni önizleme, yukarıdaki referanslara bağlı atıf ve paylaşım koşulları gözetilerek CC BY-SA 4.0 altında sunulmaktadır. Değişiklikler: fotoğrafı otomatik izlemeksizin vektörle yeniden çizim, sadeleştirme, ortak renk paleti, oyun ölçeğine uyarlama. Atıf bilgileri bu notla korunmalıdır.
https://creativecommons.org/licenses/by-sa/4.0/
https://creativecommons.org/licenses/by-sa/3.0/
https://creativecommons.org/licenses/by-sa/2.0/
