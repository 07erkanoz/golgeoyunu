// Bölüm haritaları ve hikâye metinleri.
//
// Harita gösterimi: lib/game/level.dart başındaki açıklamaya bakın.

import 'maps.dart';
import 'strings.dart';

/// Hareketli kayanın ayarı (haritadaki `V`/`R` kayasına sütun ve satırla
/// bağlanır): yol uzunluğu, dönem, başlangıç anı, uçlarda bekleme, basınca
/// çalışma ve genişlik. Verilmeyen kayalar eski davranışı korur.
class RockProfile {
  const RockProfile({
    this.range = 4,
    this.period = 5.5,
    this.phase,
    this.pause = 0,
    this.onStep = false,
    this.width = 2,
  });

  /// Kare olarak yol (dikey kaya yukarı, yatay kaya sağa).
  final double range;

  /// Bir gidiş-dönüşün saniyesi (uçlardaki bekleme dâhil).
  final double period;

  /// Başlangıç anı (0-1, dönemin kesri); verilmezse konuma bağlı.
  final double? phase;

  /// Her uçta bekleme (saniye).
  final double pause;

  /// Üstüne basılınca yola çıkar, dönüp başlangıçta bekler.
  final bool onStep;

  /// Kare olarak genişlik.
  final int width;
}

/// Gözcü'nün tarama ayarı (haritadaki `g`ye sütun ve satırla bağlanır):
/// baktığı yön, taramanın ortası ve genişliği (radyan, aşağı doğru artı),
/// hızı ve başlangıç anı. Verilmeyen Gözcüler eski davranışı korur.
class WatcherProfile {
  const WatcherProfile({
    this.facing,
    this.center = 0.6,
    this.sweep = 0.55,
    this.speed = 0.7,
    this.phase = 0,
  });

  final int? facing;
  final double center;
  final double sweep;
  final double speed;

  /// Dönemin kesri olarak başlangıç anı (0-1): iki Gözcü sırayla tarasın.
  final double phase;
}

/// Bölümün mekânı: gökyüzü, arazi süsleri, ışık, sis ve sesler buna göre.
enum LevelTheme {
  cistern,
  cave,
  cliffs,
  sky,

  /// Kaf Dağı: zümrüt kayalar, Simurg'un tüyleri.
  kaf,

  /// Ağrı ve Palandöken: kar, tipi, buz.
  snow,

  /// Nuh'un Gemisi: taşlaşmış ahşap gövdenin içi.
  ark,

  /// Nemrut: kışın taş tanrılar ve düşmüş dev başlar.
  nemrut,

  /// Kapadokya: peri bacaları.
  peri,

  /// Konya: karlı gece, dergâh.
  konya,

  /// Erlik'in katı: yerin altı, kara kayalar, yeraltı ırmakları.
  underworld,

  /// Ergenekon: dört yanı aşılmaz dağlarla çevrili yeşil vadi, demir dağ.
  ergenekon,

  /// Göğün katları: ay katı, gün katı, Ülgen'in kapısı; bulutlar.
  heavens,

  /// Ötüken Ormanı: kutlu ormanlı dağ; ak kayınlar, yaprak arasından süzülen
  /// ışık, yosun. Oyunun tek yeşil yeri.
  forest,

  /// Ak Ana'nın Denizi: Altay anlatısındaki ilk su; serin, derinleştikçe
  /// kararan su, yosun ormanları, siluet kayalar.
  sea;

  /// Kapalı mekân: tavanın üstü kaya, uzaktan zincir sesleri.
  bool get indoor =>
      this == cistern || this == cave || this == ark || this == underworld;

  /// Gökte: haritanın dışı boşluk, tahtalar bulut, rüzgâr akımları parlak.
  bool get airy => this == sky || this == kaf || this == heavens;

  /// Kar yağar, kayaların üstü karla örtülü.
  bool get snowy => this == snow || this == nemrut || this == konya;
}

class LevelDef {
  const LevelDef({
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.map,
    this.whispers = const [],
    this.memories = const [],
    this.wings = false,
    this.variant = 0,
    this.headwind = 0,
    this.storm = false,
    this.quakes = false,
    this.skiSurface,
    this.skiMarks,
    this.skiDecor = const [],
    this.magnet = const [],
    this.echoes = const [],
    this.animalKinds = const [],
    this.shadowKinds = const [],
    this.titleEn = '',
    this.subtitleEn = '',
    this.whispersEn = const [],
    this.memoriesEn = const [],
    this.place = '',
    this.placeEn = '',
    this.areas = const [],
    this.areasEn = const [],
    this.pawTrails = const [],
    this.gokboruWatch = const [],
    this.gokboruGuard = false,
    this.gokboruHelp = false,
    this.gokboruLead,
    this.cameos = const [],
    this.bard = '',
    this.bardEn = '',
    this.bellows = const [],
    this.rocks = const [],
    this.watchers = const [],
    this.mists = const [],
    this.forges = const [],
    this.nevruz,
    this.interiors = const [],
    this.noWings = false,
    this.scorch = const [],
    this.glades = const [],
    this.wheels = const [],
    this.skies = const [],
    this.yel = const [],
    this.stormSteps = const [],
    this.strikes = const [],
    this.karakci = const [],
    this.lifeTree,
    this.legends = const [],
    this.gokboruRun = false,
    this.shadowStones = const [],
    this.coldRuns = const [],
    this.vistas = const [],
    this.surprises = const [],
    this.cages = const [],
    this.finale,
    this.finaleLocks = const [],
    this.floodSpeed,
    this.dawn,
    this.lake,
    this.mirrorSteps = const [],
    this.birdBridges = const [],
    this.leaks = const [],
    this.barrels = const [],
    this.starStreams = const [],
    this.ulker,
    this.kites = const [],
    this.seaSurface,
    this.airPockets = const [],
    this.kelpBeds = const [],
    this.fishSchools = const [],
    this.jellies = const [],
    this.anglers = const [],
    this.octopi = const [],
    this.currents = const [],
    this.bubbleVents = const [],
    this.turtle = const [],
    this.boats = const [],
    this.akAna,
  });

  /// Ak Ana'nın Denizi: suyun yüzeyinin satırı (bu satırdan aşağısı su;
  /// yoksa bölümde deniz yok). Sâye suda yüzer, nefesi azalır.
  final int? seaSurface;

  /// Suyun içinde hava cepleri (ilk sütun, ilk satır, son sütun, son
  /// satır): nefes burada dolar.
  final List<(int, int, int, int)> airPockets;

  /// Yosun ormanları (ilk sütun, son sütun): dibe dikilir; öndeki yosunlar
  /// Sâye'yi saklar.
  final List<(int, int)> kelpBeds;

  /// Balık sürüleri (sütun, satır, sayı).
  final List<(int, int, int)> fishSchools;

  /// Denizanaları (sütun, satır, inip çıktığı yol karesi).
  final List<(int, int, int)> jellies;

  /// Fenerbalıkları (sütun, satır, gezindiği yarı genişlik karesi).
  final List<(int, int, int)> anglers;

  /// Ahtapotlar (sütun, satır): dokununca mürekkep bırakır.
  final List<(int, int)> octopi;

  /// Akıntılar (hücre noktaları; içindekini akış yönünde iter).
  final List<List<(int, int)>> currents;

  /// Dipteki kaynaklar (sütun, satır): kabarcık sütunu nefes verir, yukarı
  /// taşır.
  final List<(int, int)> bubbleVents;

  /// Su kaplumbağasının yolu (hücre noktaları): başına dokunan sırtında
  /// taşınır.
  final List<(int, int)> turtle;

  /// Yüzeydeki Kandilci sandalları (ilk sütun, son sütun): fenerin ışığı
  /// suya iner.
  final List<(int, int)> boats;

  /// Ak Ana'nın belirdiği yer (sütun, satır): dipteki yarığın ağzı.
  final (int, int)? akAna;

  /// Gökyolu: rüzgârda salınan uçurtmalar (sütun, satır, evre).
  final List<(int, int, double)> kites;

  /// Kuş Yolu: ışık nehirleri (hücre noktaları; içine gireni taşır) ve
  /// Ülker'in yedi yıldızı ile yanınca beliren köprü (ilk sütun, son
  /// sütun, satır).
  final List<List<(int, int)>> starStreams;
  final (List<(int, int)>, (int, int, int))? ulker;

  /// Gemi: tabanında su fışkıran delikler (sütun, zemin satırı) ve
  /// yalpayla yuvarlanan fıçıların bölmeleri (ilk sütun, son sütun, zemin
  /// satırı, evre).
  final List<(int, int)> leaks;
  final List<(int, int, int, double)> barrels;

  /// Aynalı göl (ilk sütun, son sütun, yüzeyin satırı) ve yalnız yansımada
  /// görünen basamaklar (sütun, satır, uzunluk): Kaf'ın Hayret Vadisi.
  final (int, int, int)? lake;
  final List<(int, int, int)> mirrorSteps;

  /// Kuşlardan köprüler (ilk sütun, son sütun, uçuş satırı): Otuz Kuş.
  final List<(int, int, int)> birdBridges;

  /// Şafak (sütun aralığı): oturan tanrıların gölgeleri güneş yükseldikçe
  /// kısalır; Kandilciler güneşe çıkmaz, güneşteki Sâye'yi görmez.
  final (int, int)? dawn;

  /// Kafesteki ışıklar (sütun, satır): Kandilcilerin topladığı ışıklar;
  /// açılınca kavanoza girer, en yakın kapıyı açar (Erlik'in kut kafesi).
  final List<(int, int)> cages;

  /// Final: Kandilci Başı'nın durduğu hücre ve çevresindeki ay kilitleri.
  final (int, int)? finale;
  final List<(int, int)> finaleLocks;

  /// Işık selinin en yüksek hızı (piksel/sn; verilmezse 72).
  final double? floodSpeed;

  /// Küçük sürprizler (ad, sütun, satır): bkz. surprises.dart.
  final List<(String, int, int)> surprises;

  /// Manzara anları (sütun, satır, tür): Sâye oraya ilk gelince.
  final List<(int, int, String)> vistas;

  /// Kandilci yolu (sütun, satır, uzunluk): soğuk ışık tahtaları.
  final List<(int, int, int)> coldRuns;

  /// Gölge taşları (sütun, satır): üstünde ↑ ile gölge önden gönderilir.
  final List<(int, int)> shadowStones;

  /// Kayak bölümünde çığ uyanınca Gökbörü önde koşup güvenli hattı gösterir.
  final bool gokboruRun;

  /// Bölüm başında (ozan dizesinden sonra) Defter'e yazılan efsaneler.
  final List<String> legends;

  /// Gün katı: yakıcı ışık alanları (sol, üst, sağ, alt); Umay kuşunun
  /// gölgesinde yürünür.
  final List<(int, int, int, int)> scorch;

  /// Ötüken: yaprak arasından ışık düşen orman alanları (sol, üst, sağ,
  /// alt, rüzgâr). Huzmeler alandaki `c` işaretlerinden iner; gölgede
  /// Karabasan bekler. Rüzgâr: 0 durgun, 1 huzmeler kayar, 2 huzmeler
  /// sırayla söner.
  final List<(int, int, int, int, int)> glades;

  /// Yıldız Katı: dönen yıldız çarkları (kazık sütunu, satırı, yarıçap
  /// (kare), yıldız sayısı, bir tur (sn; eksi: ters yön), tür: 0 yıldız,
  /// 1 Demir Kazık'a bağlı iki at).
  final List<(int, int, double, int, double, int)> wheels;

  /// Göğün katlarının gökleri: (sütun, tür) sırayla; kamera o sütuna
  /// gelince gök o türe döner. Tür: 0 ay gecesi, 1 yıldız gecesi, 2 yel
  /// (gümüşi sabah), 3 gün, 4 kırık güneşli gün, 5 fırtına. Boşsa gök
  /// bölümün yüzdesine göre değişir.
  final List<(int, int)> skies;

  /// Yel Katı: Yel Ana'nın soluğu esen alanlar (sol, üst, sağ, alt,
  /// yön: +1 sağa, -1 sola). Haritadaki `c` göklerde yada taşıdır.
  final List<(int, int, int, int, int)> yel;

  /// Şimşek Katı: yalnızca şimşek çakınca görünen kara bulut basamakları
  /// (sütun, satır, genişlik) ve yıldırımın düştüğü yerler (sütun, satır,
  /// evre (sn)). Her yıldırım göğü aydınlatıp basamakları gösterir.
  final List<(int, int, int)> stormSteps;
  final List<(int, int, double)> strikes;

  /// Yedi Karakçı: kazığın çevresinde dönen Büyük Ayı (kazık sütunu,
  /// satırı, uzaklık (kare), bir tur (sn)).
  final List<(int, int, double, double)> karakci;

  /// Ötüken: Hayat Ağacı'nın gövdesi (sol, üst, sağ, alt sütun/satır); ak
  /// kayın olarak çizilir, tacı üstünde açılır.
  final (int, int, int, int)? lifeTree;

  /// Ergenekon: deri körükler (sütun, satır, sıra); her biri en yakın demir
  /// damarına bağlanır, sırası üstündeki çentiklerle gösterilir.
  final List<(int, int, int)> bellows;

  /// Hareketli kayaların ayarları (sütun, satır, ayar).
  final List<(int, int, RockProfile)> rocks;

  /// Gözcülerin tarama ayarları (sütun, satır, ayar).
  final List<(int, int, WatcherProfile)> watchers;

  /// Yolu gizleyen sis alanları (sol, üst, sağ, alt sütun/satır).
  final List<(int, int, int, int)> mists;

  /// Ergenekon: soldan sağa her demir damarının biçimi: (ritim mi,
  /// ocağa itilmesi gereken kömür sandığı sayısı). Ritimli damarda
  /// körükler Demirci'nin örs vuruşuna denk basılır.
  final List<(bool, int)> forges;

  /// Ergenekon'un çıkışındaki Nevruz örsü (sütun, durulan satır): üç kez
  /// vurulunca en yakın kapı açılır.
  final (int, int)? nevruz;

  /// Dağın içi (c0, r0, c1, r1): açık havanın yerine koyu kaya duvar,
  /// içinde kızıl demir damarları.
  final List<(int, int, int, int)> interiors;

  /// Bu bölümde kanatlar açılmaz (boşluklar süzülerek geçilmesin).
  final bool noWings;

  /// Bölüm başında, başlıktan sonra ozanın tek dizesi (Dede Korkut
  /// havasında; bir kez).
  final String bard;
  final String bardEn;
  String get bardText => S.en && bardEn.isNotEmpty ? bardEn : bard;

  /// Bölüme serpiştirilen kısa efsane görünüşleri: (tür, sütun, satır).
  /// Türler lib/game/cameos.dart'ta.
  final List<(String, int, int)> cameos;

  /// Gökbörü'nün pençe izleri: (ilk sütun, son sütun, satır). Yalnızca
  /// kavanoz örtülüyken ya da karanlıkta parlar; ince buza ve dikene iz
  /// düşmez (izler güvenli yolu gösterir).
  final List<(int, int, int)> pawTrails;

  /// Gökbörü'nün uzaktan bir an belirip uluduğu hücreler (sezilir).
  final List<(int, int)> gokboruWatch;

  /// Aç kurtlar Sâye'yi sıkıştırınca Gökbörü bir kez araya girer.
  final bool gokboruGuard;

  /// Uzun süre ilerlenemezse Gökbörü yolun ilerisinde uluyup yönü gösterir.
  final bool gokboruHelp;

  /// Araya girdikten sonra yürüyüp Sâye'yi beklediği sütun.
  final int? gokboruLead;

  /// Başlığın altında: yer ve zaman (ör. "Yerebatan Sarnıcı · İstanbul,
  /// Temmuz 1660").
  final String place;
  final String placeEn;

  /// Bölümün içindeki yerlerin adları: haritadaki `p` işaretleri ilerleyiş
  /// sırasıyla bunları gösterir.
  final List<String> areas;
  final List<String> areasEn;

  String get placeText => S.en && placeEn.isNotEmpty ? placeEn : place;
  List<String> get areaTexts => S.en && areasEn.isNotEmpty ? areasEn : areas;

  final String titleEn;
  final String subtitleEn;
  final List<String> whispersEn;
  final List<String> memoriesEn;

  /// Seçili dildeki metinler.
  String get titleText => S.en && titleEn.isNotEmpty ? titleEn : title;
  String get subtitleText =>
      S.en && subtitleEn.isNotEmpty ? subtitleEn : subtitle;
  List<String> get whisperTexts =>
      S.en && whispersEn.isNotEmpty ? whispersEn : whispers;
  List<String> get memoryTexts =>
      S.en && memoriesEn.isNotEmpty ? memoriesEn : memories;

  /// Bölüm kanatlarla başlar (süzülme açık).
  final bool wings;

  /// Tipi: süzülürken yüze esen rüzgâr (px/sn). Uzun uçurumlar ancak
  /// iple sallanarak geçilir.
  final double headwind;

  /// Ara ara tipi bastırır: ekran beyaza boğulur; Kandilciler az görür,
  /// hiç duymaz.
  final bool storm;

  /// Kayak bölümü: sütun başına kar yamacının yüksekliği (kare). Negatif
  /// değer uçurumdur. Verilirse oyuncu kayakla iner.
  final List<double>? skiSurface;

  /// Manyetik Tepe bölgeleri (sütun aralıkları): kar yokuş yukarı akar.
  final List<(int, int)> magnet;

  /// Geciken ayak sesi olaylarının sütun aralıkları (sırayla yükselir: ilki
  /// yalnızca ses, ikincisi gölgeyle birlikte). Kayıt başına bir kez.
  final List<(int, int)> echoes;

  /// Hayvan sandıklarının (`a`) ve gölgelerinin (`d`) türleri, ilerleyiş
  /// sırasıyla (AnimalKind sırası: aslan, fil, zürafa, geyik). Boşsa türler
  /// sırayla dönerek verilir.
  final List<int> animalKinds;
  final List<int> shadowKinds;

  /// Ara ara deprem olur: yer sarsılır, gevşek kayalar düşer.
  final bool quakes;

  /// Aynı temanın farklı görünümü (ör. kar: 0 Ağrı, 1 Palandöken, 2 çığ;
  /// Nemrut: 0 taş tanrılar, 1 gün doğumu).
  final int variant;

  final String title;
  final String subtitle;
  final LevelTheme theme;
  final List<String> map;

  /// Kayak bölümünde haritanın işaretleri (sütun, satır, harf): ızgara
  /// bunlardan ve yamaçtan kurulur (geniş, çoğu boş bir harita yerine).
  final List<(int, int, String)>? skiMarks;

  /// Kayak yamacının süsleri (tür, sütun): orman, göl, kemer, geyik...
  final List<(String, int)> skiDecor;

  /// Rakam tetikleyicilerinde gösterilen anlatım satırları.
  final List<String> whispers;

  /// Haritada yukarıdan aşağıya, soldan sağa okunan `M` sırasına göre.
  final List<String> memories;
}

const prologue = [
  'Bin altı yüz altmış yazıydı. İstanbul iki gündür yanıyordu. Duman göğü örtmüş, geceyle gündüz birbirine karışmıştı.',
  'Alevler dinerken Kandilciler sokaklara indi. Küllerin arasında ev ev dolaştılar. Ne bir kandil bıraktılar ne bir mum; insanların gözlerindeki ışığı bile topladılar.',
  'Sonunda Hayalî Usta\'nın kapısına dayandılar. Önce perdeyi aydınlatan kandili aldılar. Ardından ustayı karanlığa sürüklediler.',
  'Perde karardı. Ama kandilin son ışığında, küçük bir gölge perdeden ayrılıp yere düştü.',
  'Düştüğü yerde küller yarıldı, bir kayın fidanı filizlendi. Dalında tek bir ak çaput sallanıyordu. Derler ki Umay, düşen her çocuğun başında bekler.',
  'GÖLGE OYUNU',
  'Küçük gölge gözlerini suyun altında açtı. Yerin derininde, unutulmuş bir saraydaydı: Yerebatan Sarnıcı\'nda.',
  'Bin yıl önce İmparator Justinianus, İstanbul susuz kalmasın diye bu sarayı toprağın altına kazdırmıştı. Üç yüz otuz altı sütun, karanlıkta bir orman gibi yükseliyordu.',
  'İçlerinden biri hiç kurumazdı. Ona Ağlayan Sütun derlerdi. Sarnıcı kazanların orada can verdiği, gözyaşlarının hâlâ o taştan süzüldüğü söylenirdi.',
  'Zaman geçmiş, şehir sarnıcı unutmuştu. İnsanlar evlerinin tabanından kovalar sarkıtıp balık tutmuşlardı; ayaklarının altında bir sarayın uyuduğunu bilmeden.',
  'Şimdi o sessiz sularda küçük bir gölge yürüyordu. Ustası ona Sâye derdi. Ustası karanlıkta bir yerdeydi. Onu bekliyordu.',
];

const prologueEn = [
  'It was the summer of sixteen sixty. Istanbul had been burning for two days. Smoke covered the sky, and no one could tell where night ended and day began.',
  'As the flames died down, the Lamplighters came into the streets. They went from house to house among the ashes. They left no lamp, no candle. They took even the light from people\'s eyes.',
  'At last they came to Master Hayalî\'s door. First they took the lamp that lit his shadow screen. Then they dragged the master into the dark.',
  'The screen went black. But in the lamp\'s last light, a small shadow slipped from the screen and fell to the ground.',
  'Where it fell, the ashes parted and a birch sapling grew. A single white cloth fluttered from its branch. They say Umay keeps watch beside every fallen child.',
  'SHADOW PLAY',
  'The little shadow opened her eyes beneath the water. Deep under the earth, she lay in a forgotten palace: the Basilica Cistern.',
  'A thousand years before, Emperor Justinian had ordered this palace dug beneath the city, so Istanbul would never go thirsty. Three hundred and thirty-six columns rose through the darkness like a forest.',
  'One column never dried. They called it the Weeping Column. Those who dug the cistern had died there, people said, and their tears still trickled down its stone.',
  'The years passed, and the city forgot. People lowered buckets through the floors of their houses and caught fish, never knowing a palace slept beneath their feet.',
  'Now a small shadow walked those silent waters. Her master called her Saye. Somewhere in the darkness, he was waiting for her.',
];

List<String> get prologueText => S.en ? prologueEn : prologue;

const epilogue = [
  'Yeşil Kubbe\'nin tepesinde, yağan karın altında bir kandil titriyordu.',
  'Ustası oradaydı. Yaşlanmış, küçülmüştü. Kandilciler çevresinde bir halka kurmuş, fenerlerini onun kandiline tutuyordu.',
  '“Geldin,” dedi usta. “Geleceğini biliyordum. Dua karşılıksız kalmaz.”',
  'Kandilciler bütün ışığı toplamış, kendi gölgelerini yitirmişti. Gölgelere can verebilen tek ışık, ustanın kandilinde kalmıştı. Bir zaman güneşi yalnız kendileri için istemiş, onu kırmışlardı. Şimdi bu kandille yeniden yakacaklardı.',
  '“Kandilim sönmesin diye getirdiler beni,” dedi usta. “Mevlânâ\'nın düğün gecesine yetiştirdiler. Sanıyorlar ki bu gece ışık ölmez.”',
  '“Haklılar, Sâye. Bu gece ışık ölmez. Yalnızca kavuşur.”',
  'Semâhaneden bir ney sesi yükseldi. Usta, kandili Sâye\'nin avuçlarına bıraktı.',
  '“Sen benim gölgem değildin, Sâye. Duamdın. Bunca yolu yürüyüp bana gelen duam. Şimdi ışığı tutma sırası sende.”',
  'Kandil söndü.',
  'Perde karardı. Bir an ne usta kaldı ne gölge.',
  'Sonra Sâye\'nin içinden bir ışık doğdu. Gölge kaybolmamıştı. Işığa karışmıştı.',
  'Kandilcilerin yüzyıllardır sakladığı bütün ışık, Sâye\'de doğan ışığa yöneldi. Birlikte göğe yükseldiler. Kandilciler karın üstüne baktı. Gölgeleri geri gelmişti. Ağladılar.',
  'Hüdhüd, Sâye\'nin omzuna kondu. “Kırık güneşin yalnız bir parçası buradaydı,” dedi. “Ötekiler hâlâ dünyanın dört bir yanında.”',
  'Sâye perdenin ardına baktı. Önünde, yeni yağmış karların üstünde bir yol uzanıyordu.',
  'Rüzgârın içinden ustasının sesi geldi: “Yürü, Sâye. Yol bitmez; yürüyen değişir.”',
  'SÂYE\'NİN YOLCULUĞU SÜRECEK',
];

const epilogueEn = [
  'At the top of the Green Dome, beneath the falling snow, a lamp trembled.',
  'Her master was there. He had grown old, and small. The Lamplighters stood in a ring around him, their lanterns held toward his lamp.',
  '“You came,” said the master. “I knew you would. No prayer goes unanswered.”',
  'The Lamplighters had gathered all the light and lost their own shadows. Only the master\'s lamp could still give shadows life. Once, they had wanted the sun for themselves and broken it. Now they meant to kindle it again with this lamp.',
  '“They brought me here to keep my lamp from going out,” said the master. “In time for Mevlânâ\'s wedding night. They believe that tonight, light cannot die.”',
  '“And they are right, Saye. Tonight, light does not die. It only returns to what it loves.”',
  'The sound of a ney rose from the semahane. The master placed the lamp in Saye\'s hands.',
  '“You were never my shadow, Saye. You were my prayer. The prayer that walked all this way to find me. Now it is your turn to hold the light.”',
  'The lamp went out.',
  'The screen went dark. For a moment, there was neither master nor shadow.',
  'Then a light was born within Saye. The shadow had not vanished. She had become part of the light.',
  'All the light the Lamplighters had hoarded for centuries turned toward the light within her. Together, they rose into the sky. The Lamplighters looked down at the snow. Their shadows had returned. And they wept.',
  'The Hoopoe settled on Saye\'s shoulder. “Only one fragment of the broken sun was here,” he said. “The others are still scattered across the world.”',
  'Saye looked beyond the screen. Ahead, a road stretched over the newly fallen snow.',
  'Her master\'s voice came on the wind. “Walk on, Saye. The road does not end. The one who walks it changes.”',
  'SAYE\'S JOURNEY WILL CONTINUE',
];

List<String> get epilogueText => S.en ? epilogueEn : epilogue;

/// Bölüm aralarında perdede oynanan gölge oyunu sahneleri: her bölümden
/// önce (indeks = bölüm). Satırlar sırayla, perdedeki tasvirlerle birlikte.
const interludes = <List<String>>[
  [],
  [
    'Sâye sarnıçtan çıktığında İstanbul hâlâ tütüyordu. Dumanların arasından Galata Kulesi yükseliyordu; şehrin en yüksek gözü.',
    'Otuz yıl önce bir adam, bu kuleden göğe bakmıştı. Adı Hezarfen Ahmed Çelebi\'ydi. Bildiği onca hünerden ötürü ona “bin fen bilen” derlerdi.',
    'Önce Okmeydanı\'nda denemiş kanatlarını. Kartalınkine benzeyen o kanatlarla sekiz dokuz kez havalanmış, rüzgârı tanımış.',
    'Sonra bir lodos sabahı, kulenin tepesinden kendini boşluğa bırakmış. Boğaz\'ı aşıp Üsküdar\'a konmuş. O gün İstanbul, bir insanın kuş oluşunu seyretmiş.',
    'Sultan ona bir kese altın vermiş. Ardından, “Bu adamdan korkulur,” demiş. Hezarfen\'i uzak diyarlara sürmüşler. İstanbul\'un üstünde kanat açan adam, gurbette ölmüş.',
    'Derler ki gitmeden önce kanatlarını kulenin en üst katına saklamış; bir gün düşmekten korkmayan biri bulsun diye. Uçanlar sürgün edilir, Sâye. Yine de uç.',
  ],
  [
    'Kanatlar Sâye\'yi kulenin tepesinden alıp bulutlara taşıdı. Yanan İstanbul ayaklarının altında küçüldü. Şehrin uğultusu yavaş yavaş sustu.',
    'Bu göğe uzanan bir başkası da vardı: Lagari Hasan Çelebi. Sarayburnu\'nda yedi kollu bir fişeğe binmiş, barutun ateşiyle bulutlara yükselmişti.',
    'Ateş tükenince denize düşmüş. Yüzerek padişahın önüne çıkmış da gülerek, “İsa Peygamber sana selam söyledi,” demiş.',
    'Eskiler, gökte yalnız kuşların görebildiği bir köprüden söz eder. O köprünün ucunda dünyanın kıyısı, dünyanın kıyısında Kaf Dağı vardır.',
    'Sâye\'nin yanında ibikli, alaca kanatlı bir kuş belirdi: Hüdhüd. “Bir zamanlar gökte bütün bir güneş yanardı,” dedi. “Kandilciler onu yalnız kendileri için asmak istedi. Güneş kırıldı.”',
    '“O günden beri buldukları her ışığı toplarlar. Ustanı da bu yoldan götürdüler.” O sırada bulutların ardında kanatlı bir at dörtnala geçti. Yiğitlerin yoldaşı Tulpar\'dı bu.',
  ],
  [
    'Bulutlar çekildi. Önlerinde zümrüt kayalardan bir dağ yükseldi. Dünya orada bitiyordu. Dağın adı Kaf\'tı.',
    'Derler ki Kaf, dünyayı bir yüzük gibi sarar. Ardında ne gece vardır ne gündüz. En yüksek tepesinde kuşların padişahı Simurg yaşar.',
    'Vaktiyle bütün kuşlar, Simurg\'u bulmak için yola düşmüş. Önlerine Süleyman Peygamber\'in habercisi Hüdhüd geçmiş. Şimdi Sâye\'ye yol gösteren de aynı kuştu.',
    'Yedi vadi aşmışlar: talep, aşk, marifet, istiğna, tevhid, hayret ve yokluk. Kimi korkusuna yenilmiş, kimi yorgun düşmüş. Kimi de bir dala konmuş, bir daha kalkamamış. Dağa varan yalnız otuz kuş olmuş.',
    'Simurg\'un üç tüyü bu dağda saklıydı. Hüdhüd, “Üçünü de bulursan tepedeki aynaya varırsın,” diye fısıldadı. “Orada ne görürsen, gerçek odur.”',
  ],
  [
    'Otuz kuş, aynada Simurg\'u aramış. Baktıklarında karşılarında kendilerini görmüşler. Meğer Simurg, eski dilde “otuz kuş” demekmiş.',
    'Sâye de aynaya baktı. Karşısında bir çocuk yoktu. Bir gölge duruyordu. Kendi adı da eski dilde gölge demekti. Ustası ona Sâye derken bunu biliyordu.',
    'Ama ustasının kandili Kaf\'ta değildi. Kandilciler onu doğuya götürmüştü. Tufandan beri sönmeyen bir ışığın saklandığı dağa: Ağrı\'ya.',
    'Eteklerinde yaşayanlar ona Masis der, Çiyayê Agirî der; ateşli dağ diye seslenir. Anlatılır ki tufan çekilince büyük gemi gelip onun omzuna oturmuş.',
    'Zirvesine kimse varamazmış. Aziz Hakob, gemiyi görmek için yıllarca tırmanmış. Her sabah gözlerini yine dağın eteğinde açmış. Sonunda bir melek, ona gemiden bir tahta parçası getirmiş.',
    'Tipinin içinde ak sakallı bir ihtiyar göründü. Ayaz Ata\'ydı bu; kış onunla gelirdi. Sâye\'nin kavanozundaki ışık titredi.',
    'İKİNCİ PERDE · DAĞ',
  ],
  [
    'Ağrı\'nın buzulları altında, taşa dönmüş büyük bir gemi yatıyordu. Nuh\'un Gemisi\'ydi bu.',
    'Derler ki yağmur kırk gün kırk gece dinmemiş. Gemi aylarca karanlık sularda sürüklenmiş. Sular çekildiğinde gelip bu dağın omzuna oturmuş.',
    'Nuh Peygamber önce bir kuzgun salmış. Kuzgun geri dönmemiş. Sonra bir güvercin göndermiş; o, gagasında bir zeytin dalıyla gelmiş. Dünya yeniden yeşeriyormuş.',
    'Gemide her canlıdan bir çift varmış. Bir de hiç sönmeyen bir ışık. Kandilciler o ışığın peşinden gemiye girmiş; hayvanların gölgelerini eşlerinden koparıp ambarlara kapatmıştı.',
    'Ayrı düşen gölgeler karanlıkta birbirini arıyordu. Sâye onları gördü. Her biri bir başkasını arıyordu; tıpkı kendisi gibi.',
    'Tufandan kalan su kıpırdadı. İçinden ak bir ışık yükseldi: Ak Ana. Derler ki dünyanın ilk suyu da bir zaman böyle kıpırdamış.',
  ],
  [
    'Geminin ışığı da gitmişti. Sâye izini sürerek güneye uçtu. Fırat\'ı aştı, Nemrut Dağı\'nın zirvesine vardı.',
    'Vaktiyle bu dağda Antiochos adında bir kral yaşamış. Doğunun ve batının tanrılarını burada buluşturmuş. Kendi tahtını da aralarına koymuş.',
    'Zirveye taş üstüne taş yığdırmış, mezarını o tepenin altına yaptırmış. Üzerine şu sözü yazdırmış: “Ruhum tanrıların katına çıkınca, bedenim burada sonsuza dek uyusun.”',
    'Ama dağ kibri sevmez. Yer sarsılmış, taş başlar gövdelerinden kopmuş. Şimdi karların arasından, güneşin doğacağı yere bakıyorlardı.',
    'Kandilciler gemiden aldıkları ışığı bu taş tanrıların arasından geçiriyordu. Doğu terasına götürecek, güneş doğarken yakacaklardı.',
  ],
  [
    'Derler ki Nemrut\'ta güneş iki kez doğar. Önce gökte, sonra taş tanrıların yüzünde. Halk bu dağa bir başka kralın adını da verir: Nemrud.',
    'Nemrud, göğe hükmetmek istermiş. Dört kartalı bir sandığa bağlamış, önlerine et asmış. Kartallar ete uzandıkça sandık yükselmiş.',
    'Göğe bir ok atmış. Ok kanlı dönünce, “Tanrı\'yı vurdum,” demiş. İbrahim Peygamber\'i ateşe attırmış; ama o ateş bir gül bahçesine dönmüş.',
    'Sonunda küçücük bir sivrisinek çıkmış karşısına. Burnundan girip başına yerleşmiş. Göğe meydan okuyan kral, bir sinekle baş edememiş.',
    'Şimdi doğu terasında taştan bir dev uyanıyordu. Şafaktan önce yetiş, Sâye. Küçük bir ışık da büyük bir kibri yıkabilir.',
    'Ozanlar bir başka devi, tek gözlü Tepegöz\'ü de anlatır. O da taştan bir dev kadar korkunçmuş. Onu yenen, aslanların arasında büyümüş küçük Basat\'mış.',
  ],
  [
    'Sâye ışığa dokundu. Ustası bir an gözlerinin önünde belirdi.',
    'Karda yürüyordu. Bir kervanın ortasında, zincirler içindeydi. Kandilini göğsünde taşıyordu; içinde bir mum alevi kadar ışık kalmıştı.',
    'Kandilciler, kırık güneşin her parçasını ustanın kandilinden aldıkları ışıkla yakıyordu. Her yeni alevde usta biraz daha sönüyordu.',
    'Kervan kuzeye, Erzurum\'un karlarına gidiyordu. Doğunun bu kalesine kış öyle sert gelirdi ki yolcular ona “kışın kapısı” derdi.',
    'Şehrin güneyinde Palandöken yükseliyordu. Kervancılar, o dik yokuşlarda hayvanların palanlarının kaydığını, yüklerin uçuruma döküldüğünü anlatırdı.',
    'Kervanın önünde gök yeleli bir kurt yürüyordu: Gökbörü. Derler ki çok eski zamanlarda Oğuz\'un ordusuna da o yol göstermiş.',
    'ÜÇÜNCÜ PERDE · KAR',
  ],
  [
    'Sâye başını kaldırdı. Önünde iki beyaz doruk vardı: Büyük Ejder ile Küçük Ejder.',
    'Ozanlar anlatır: Dünya daha gençken bu doruklarda iki ejder kardeş yaşarmış. Kış geldi mi ovaya iner, sürüleri de kervanları da yutarlarmış.',
    'Bir kış gecesi bir derviş zirveye çıkmış, dua etmiş. Ardından kar başlamış. Yedi gün yedi gece dinmemiş.',
    'Ejderler o karın altında uykuya dalmış, sonunda iki doruğa dönüşmüşler. O günden beri fırtına onların nefesi, sis onların uykusudur. Uykularını bozanı kar yutar.',
    'Kandilcilerin kervanı karşı yamaçtan iniyordu. Sâye yürüyerek yetişemezdi. Önünde tek yol kalmıştı: ejderin sırtından aşağı kaymak.',
  ],
  [
    'Küçük Ejder\'in yamacında Kandilciler durdu. Fenerlerini kaldırıp dağın burnuna tuttular.',
    'Uyuyan ejder ışığı sevmez. Ozan der ki ejder uyurken dağ susar; uyandığında kar akar.',
    'Dağ derin bir nefes aldı.',
    'Ve kar aktı.',
    'Beyazlığın önünde gök yeleli kurt koşuyordu. Güvenli yolu yalnız o biliyordu.',
  ],
  [
    'Çığ dindiğinde kervan batıya dönmüştü. Sâye karları geride bırakıp Kapadokya\'ya indi. Küçük Muşkara köyünün üstünde ay yükseliyordu.',
    'Bu diyarın taşlarını çağlar boyunca yağmurla rüzgâr oymuştu. Yanardağların külünden doğan bacalar, başlıklı devler gibi göğe uzanıyordu.',
    'Muşkara\'nın çobanları geceleri tepelerde ışıklar görürmüş. “Periler,” derlermiş. Bacaların tepesinde yaşayan, vaktiyle devlerle savaşan periler.',
    'Periler gölge bırakmazdı. Ama bir gölgeyi gördüklerinde tanırlardı. O gece içlerinden biri Sâye\'ye uzun uzun baktı. Sanki onu çok eskiden biliyordu.',
    'Bacaların dibinde başka bir gölge dolaşırdı; kızıl, ışığa aç bir gölge. Adı Albastı\'ydı. Korktuğu tek şey demirdi.',
    'DÖRDÜNCÜ PERDE · PERİLER',
  ],
  [
    'Uçhisar\'dan ovaya baktığında bir kuyu ağzı gördü. Kandilcilerin fenerleri birer birer orada kayboluyordu. Yol, Derinkuyu\'ya iniyordu.',
    'Toprağın altında bir şehir vardı. Ahırları, mutfakları, kuyuları; dışarıdan nefes taşıyan bacaları vardı. Derler ki binlerce insan, düşman geçip gidene dek oraya sığınırmış.',
    'Masallar daha da eskisini söyler. Peri Padişahı, ateşli devleri yerin altına sürmüş. Sonra insanlar gelmiş, uyuyan devlerin üstüne bir şehir kazmış.',
    'Yuvarlak taş kapılar yalnız içeriden açılırdı. İçeride kalan, hayatta kalırdı. Aşağı in, Sâye. Ama uyuyanı uyandırma.',
    'En derinden boğuk bir ses yükseliyordu. Derler ki Erlik\'in katı, o derinliğin bile altındadır.',
  ],
  [
    'Tulpar bulutların arasından indi. Gökte ay, aşağıda uçsuz bucaksız bir kar ovası vardı.',
    'Batıda bir şehrin kubbeleri parlıyordu. Konya\'ydı bu; bir zamanlar Selçukluların başkenti. Kandilciler ustayı oraya götürmüştü.',
    'O gece Şeb-i Arûs\'tu. Düğün gecesi.',
    'Yüzyıllar önce bu şehirde Mevlânâ adında bir şair ölmüştü. Giderken, “Ağlamayın,” demişti. “Bu benim düğün gecemdir.”',
    'Kandilciler, o gece ışığın ölmeyeceğine inanıyordu. Ustanın kandili hiç sönmesin diye bu geceyi beklemişlerdi.',
    'Ovada, bir tepenin üstünde gök yeleli bir kurt duruyordu. Yüzünü şehre dönmüştü.',
    'SON PERDE · DÜĞÜN',
  ],
  [
    'Ağzında toprak saklayan Kişi, ışıktan kovulmuş. Yerin altına sürülmüş. Zamanla oranın efendisi olmuş; adına Erlik demişler.',
    'Çalınan ışıklar onun katına akıyordu. Ustayı da buradan geçirmişlerdi. Sâye, taşlarda ondan kalan bir iz sezdi.',
    'Ozanlar, bir zaman Er Töştük adında bir yiğidin de yerin altına düştüğünü anlatır. Konuşan atı Çalkuyruk, ona yukarıya dönen yolu göstermiş.',
    'Burada Erlik\'in gölgeleri dolaşırdı: Körmösler. Işığa üşüşür, çaldıkları canları kafeslere kapatırlardı.',
  ],
  [
    'Ozan der ki bir zamanlar bir boy, büyük bir savaşta yenilmiş. Yalnız iki yiğit, Kıyan ile Nüküz, eşleriyle birlikte kurtulmuş.',
    'Dağlar arasında gizli bir vadiye sığınmışlar: Ergenekon\'a. Oraya varan yol, keçi yolundan bile darmış. İçerideyse çayırlar, ırmaklar, meyve ağaçları ve bol av varmış.',
    'Dört yüz yıl geçmiş. Boy çoğalmış, vadi onlara dar gelmiş. Çıkıp gitmek istemişler; ama dört yanlarında aşılmaz dağlar varmış.',
    'Bir demirci, “Şu dağ demirdir,” demiş. “Odunla kömür yığalım. Körük kurup dağı eritelim.” Deriden yetmiş körük yapmışlar.',
    'Demir erimiş. Dağda, yüklü bir devenin geçebileceği kadar yol açılmış. Kimi anlatılar, çıkışı onlara bir boz kurdun gösterdiğini söyler.',
    'O günü bayram bilmişler. Her yıl ateşte bir parça demir kızdırır, örsün üstünde döverlermiş.',
    'Şimdi vadinin ocağı sönüktü. Kandilciler onun ateşini de almıştı. Körükler susuyordu. Sâye\'nin yukarıya çıkabilmesi için bu demir dağdan geçmesi gerekiyordu.',
  ],
  [
    'Ozanlar anlatır: Altay\'da kamlar davullarını çalınca canları göğe yükselirmiş. Göğün kat kat olduğunu onlar görmüş, onlar söylemiş.',
    'En yüksek katta aydınlığın kaynağı Ülgen otururmuş. Yerin dibinde Erlik\'in hükmü geçer; göğün tepesinde Ülgen\'in.',
    'Bir katta ay, soğuk ve yumuşak bir ışıkla yanarmış. Bir başkasında yıldızlar, Demir Kazık\'ın çevresinde dönermiş.',
    'O kazığa iki at bağlıymış. Yedi Karakçı onları çalmaya çalışırmış. Katların arasında ise Yel Ana esermiş.',
    'Kandilciler, kırık güneşin bir parçasını göğün en yüksek katına taşımıştı. Bir kam davuluna vurdu. Sâye, davulun sesiyle bulutların üstüne yükseldi.',
  ],
  [
    'Derinkuyu\'nun dibinde Sâye, taşların arasından sarkan bir köke tutundu. Kök kıpırdadı. Onu yukarıya, ışığa doğru çekti.',
    'Topraktan çıktığında gün ağarıyordu. Önünde uçsuz bucaksız bir orman uzanıyordu. Kayınlar, çamlar, yosun kokusu. Her yandan kuş sesleri geliyordu.',
    'Atalar bu ormanın adını taşlara yazmıştı: Ötüken. Bir yurdu tutmak için ondan iyi yer olmadığını söylemişlerdi.',
    'Ormanın ortasında Hayat Ağacı göğe yükseliyordu. Derler ki Umay onun dallarında oturur; doğacak çocukların canları kuş olup yanına konar.',
    'Ama Sâye\'yle birlikte başka bir şey de yukarı çıkmıştı. Onu sarnıçta gören, Derinkuyu\'nun karanlığında ardından sürünen şey: Karabasan.',
    'Karabasan, sahipsiz gölgeyi sezerdi. Uyuyanın göğsüne çöker gibi üstüne çökerdi. Ustasını yitirmiş bir gölge, onun için en tatlı lokmaydı.',
    'Işığa ise adım atamazdı. Yaprakların arasından süzülen her huzme, Sâye\'nin sığınabileceği bir yerdi.',
    'BEŞİNCİ PERDE · ÖTÜKEN',
  ],
  [
    'Yel Ana, Sâye\'yi gün katının eşiğine bıraktı. Kamın davulu artık duyulmuyordu. Sâye çok yükselmişti.',
    'Bu katın ötesinde Ülgen\'in kapısı vardı. Kırık güneşin parçası orada bekliyordu.',
    'Gün katında güneş yakardı. Ama burada, göğün en yükseklerinde bile Erlik\'in fırtınası dinmiyordu.',
    'Derler ki Hüma\'nın gölgesi kimin başına düşerse ona kut getirir. Tulpar da yiğitleri göğün bir katından ötekine taşır.',
    'Yakutlar gök gürültüsünde Süge Toyon\'un sesini duyar; yıldırımını kötü ruhlara indirdiğini söyler. O gece gök hiç susmadı.',
  ],
  [
    'Semâhanenin damından Yeşil Kubbe\'ye baktı. İçeride yüzyıllardır biriktirilen ışık, kubbeden dışarı taşıyordu.',
    'Kandilciler ustayı en tepeye, alemin dibine çıkarmıştı. Yanında en yaşlıları duruyordu: Kandilci Başı.',
    'Derler ki Kandilci Başı da bir zamanlar hayalîymiş. Işığını kimseyle bölüşmemek için kandilini kapatmış. Gölgesini o gün yitirmiş.',
    'Ustanın kandili titriyordu. Gece yarısına az kalmıştı.',
  ],
  [
    'Hayat Ağacı\'nın kökleri yerin en dibine uzanırdı. Sâye onların arasından aşağı süzüldü. Derinlerden su sesi geliyordu.',
    'Ozan der ki başlangıçta yalnız su vardı. Kayra Han ile ilk yarattığı Kişi, o uçsuz bucaksız suyun üstünde iki kara kaz gibi uçardı.',
    'Bir gün sudan ak bir ana yükselmiş. Ak Ana, “Yarat,” demiş. Sonra yeniden suya dönmüş.',
    'Kişi, Kayra Han\'dan daha yükseğe çıkmak istemiş. Ama suya düşmüş. Ondan dibe dalıp toprak getirmesi istenmiş. Kişi o toprağın bir avucunu ağzında saklamış.',
    'Şimdi Kandilcilerin çaldığı ışıklar bu suyun dibine akıyordu. Sâye derin bir nefes aldı. Kendini dünyanın ilk suyuna bıraktı.',
  ],
];

const interludesEn = <List<String>>[
  [],
  [
    'Istanbul was still smouldering when Saye emerged from the cistern. Above the smoke stood Galata Tower, the city\'s highest eye.',
    'Thirty years before, a man had stood in this tower and looked to the sky. His name was Hezarfen Ahmed Çelebi. For all his learning and his many arts, they called him the master of a thousand sciences.',
    'He first tried his wings at Okmeydanı. Shaped like an eagle\'s, they lifted him eight or nine times as he learned the ways of the wind.',
    'Then, one morning on a southerly wind, he stepped from the top of the tower. He crossed the Bosphorus and came to rest in Üsküdar. That day, Istanbul watched a man become a bird.',
    'The sultan gave him a purse of gold. Then he said, “This is a man to be feared.” They sent Hezarfen into exile. The man who had flown above Istanbul died far from home.',
    'They say he hid his wings at the top of the tower before he left, for someone who would not be afraid to fall. Those who fly are sent into exile, Saye. Fly anyway.',
  ],
  [
    'The wings lifted Saye from the tower into the clouds. Burning Istanbul dwindled beneath her. Slowly, the city\'s clamour fell silent.',
    'Another had reached for this sky: Lagari Hasan Çelebi. At Sarayburnu, he had mounted a seven-branched rocket and risen into the clouds on a burst of gunpowder.',
    'When the fire ran out, he fell into the sea. He swam ashore to the sultan and laughed. “The Prophet Jesus sends you his greetings.”',
    'The old tales speak of a bridge in the sky that only birds can see. At its end lies the edge of the world. And there stands Mount Qaf.',
    'A crested bird with mottled wings appeared beside Saye: the Hoopoe. “Once, a whole sun burned in the sky,” he said. “The Lamplighters wanted to hang it for themselves alone. And the sun broke.”',
    '“They have gathered every light they could find ever since. They brought your master this way, too.” Beyond the clouds, a winged horse galloped past. It was Tulpar, companion of heroes.',
  ],
  [
    'The clouds drew back. A mountain of emerald stone rose before them. Here the world came to an end. The mountain was called Qaf.',
    'They say Qaf circles the world like a ring. Beyond it there is neither night nor day. On its highest summit lives the Simurgh, sovereign of the birds.',
    'Long ago, all the birds set out to find the Simurgh. The Hoopoe, messenger of the Prophet Solomon, led the way. The very same bird now flew before Saye.',
    'They crossed seven valleys: longing, love, knowledge, detachment, unity, wonder and nothingness. Some gave in to fear. Some grew weary. Some settled on a branch and never rose again. Only thirty birds reached the mountain.',
    'Three of the Simurgh\'s feathers lay hidden here. “Find all three, and you will reach the mirror at the summit,” the Hoopoe whispered. “What you see there is the truth.”',
  ],
  [
    'The thirty birds had looked into the mirror for the Simurgh. They saw themselves. In the old tongue, the tale says, Simurgh meant “thirty birds.”',
    'Saye looked too. No child stood before her. Only a shadow. Her own name meant shadow in the old tongue. Her master had known that when he named her.',
    'But her master\'s lamp was not on Qaf. The Lamplighters had taken it east, to a mountain where a light had burned since the Flood: Mount Ağrı.',
    'Those who live at its foot call it Masis, or Çiyayê Agirî, the mountain of fire. They tell of a great ship that came to rest upon its shoulder when the Flood withdrew.',
    'No one could reach the summit. Saint Hakob climbed for years in search of the ship. Each morning, he awoke at the mountain\'s foot once more. At last, an angel brought him a piece of its timber.',
    'A white-bearded old man appeared in the blizzard. Ayaz Ata. Winter came with him. The light in Saye\'s jar trembled.',
    'ACT TWO · THE MOUNTAIN',
  ],
  [
    'Beneath the glaciers of Ağrı lay a great ship turned to stone. It was Noah\'s Ark.',
    'They say the rain fell for forty days and forty nights. For months, the ship drifted over dark waters. When the Flood withdrew, it settled on the mountain\'s shoulder.',
    'The Prophet Noah first sent out a raven. It did not return. Then he sent a dove, and the dove came back with an olive branch in its beak. The world was growing green again.',
    'A pair of every creature had sailed aboard the Ark. And with them, a light that never went out. The Lamplighters had entered the ship in search of it. They had torn the animals\' shadows from their mates and shut them in the holds.',
    'The parted shadows searched for one another in the dark. Saye watched them. Each was looking for someone, just as she was.',
    'The water left by the Flood began to stir. A white light rose from it: Ak Ana, the White Mother. They say the world\'s first water stirred just so.',
  ],
  [
    'The Ark\'s light was gone as well. Saye followed its trail south, across the Euphrates, to the summit of Mount Nemrut.',
    'Long ago, a king named Antiochus had lived here. He brought the gods of east and west together on this mountain and placed his own throne among them.',
    'He had stone heaped upon stone at the summit, with his tomb beneath. On it he ordered these words inscribed: “When my soul rises to the gods, let my body sleep here forever.”',
    'But the mountain has no love for pride. The earth shook, and the stone heads fell from their bodies. Now they gazed out from the snow, waiting for the sun to rise.',
    'Through these stone gods, the Lamplighters carried the light they had taken from the Ark. They would bring it to the eastern terrace and kindle it at sunrise.',
  ],
  [
    'They say the sun rises twice on Nemrut. Once in the sky, and once upon the faces of the stone gods. The people also give this mountain another king\'s name: Nimrod.',
    'Nimrod wished to rule the heavens. He bound four eagles to a chest and hung meat before them. As they reached for it, the chest rose into the sky.',
    'He loosed an arrow into the heavens. When it returned bloodied, he said, “I have struck God.” He ordered the Prophet Abraham cast into a fire. But the fire became a garden of roses.',
    'In the end, a tiny gnat came against him. It entered through his nose and settled in his head. The king who had challenged heaven could not defeat a gnat.',
    'Now a giant of stone was waking on the eastern terrace. Reach it before dawn, Saye. Even a small light can bring down the proudest of all.',
    'The bards tell of another giant, the one-eyed Tepegöz, as terrible as any giant of stone. Yet young Basat, raised among lions, defeated him.',
  ],
  [
    'Saye touched the light. For a heartbeat, she saw her master.',
    'He was walking through snow, in chains, at the heart of a caravan. He held his lamp against his breast. Barely a candle\'s flame remained inside.',
    'The Lamplighters were kindling each fragment of the broken sun with light drawn from his lamp. With every new flame, the master faded a little more.',
    'The caravan was heading north, into the snows of Erzurum. Winter came so fiercely to this fortress of the east that travellers called it the gate of winter.',
    'South of the city stood Palandöken. Caravan drivers told of its steep paths, where packsaddles slipped from the animals\' backs and loads tumbled into the abyss.',
    'A wolf with a sky-blue mane walked before the caravan: Gökbörü. They say he had once led the army of Oghuz, long ages before.',
    'ACT THREE · THE SNOW',
  ],
  [
    'Saye looked up. Two white summits stood before her: the Great Dragon and the Little Dragon.',
    'The bards tell this tale: when the world was young, two dragon brothers lived on these peaks. Each winter, they descended to the plain and swallowed flocks and caravans alike.',
    'One winter night, a dervish climbed to the summit and prayed. Then the snow began. It fell for seven days and seven nights.',
    'Beneath that snow, the dragons fell asleep and became two mountain peaks. Ever since, the storm has been their breath, the mist their slumber. Wake them, and the snow will swallow you.',
    'The Lamplighters\' caravan was descending the far slope. Saye could never catch it on foot. There was only one way: down the dragon\'s back.',
  ],
  [
    'On the Little Dragon\'s slope, the Lamplighters stopped. They raised their lanterns to the mountain\'s nose.',
    'A sleeping dragon has no love for light. The bard says: while the dragon sleeps, the mountain is silent. When it wakes, the snow runs.',
    'The mountain drew a deep breath.',
    'And the snow came down.',
    'Ahead of the white torrent ran the wolf with the sky-blue mane. He alone knew the safe way through.',
  ],
  [
    'By the time the avalanche settled, the caravan had turned west. Saye left the snows behind and descended into Cappadocia. The moon was rising above the little village of Muşkara.',
    'Rain and wind had carved this land for ages. From the ash of ancient volcanoes rose stone chimneys, tall as hooded giants.',
    'At night, the shepherds of Muşkara would see lights on the hilltops. “Fairies,” they would say. Fairies who lived atop the chimneys and had once fought the giants.',
    'The fairy folk cast no shadows. But they knew a shadow when they saw one. That night, one of them gazed at Saye for a long time, as though she had known her long ago.',
    'Another shadow prowled at the foot of the chimneys. Crimson, and hungry for light. Her name was Albastı. Iron was the only thing she feared.',
    'ACT FOUR · THE FAIRIES',
  ],
  [
    'From Uçhisar, she saw the mouth of a well in the plain below. One by one, the Lamplighters\' lanterns disappeared into it. The way led down to Derinkuyu.',
    'A city lay beneath the earth. It had stables, kitchens, wells, and shafts that brought it breath from the world above. They say thousands once sheltered there until their enemies had passed.',
    'The tales reach further back. The Fairy King had driven the fiery giants underground. Then people came and carved a city above their sleeping bodies.',
    'The round stone doors opened only from within. Those inside could live. Go down, Saye. But do not wake what sleeps below.',
    'A muffled sound rose from the deepest earth. They say Erlik\'s realm lies deeper still.',
  ],
  [
    'Tulpar descended through the clouds. Above was the moon; below, an endless plain of snow.',
    'To the west, the domes of a city shone. Konya, once the Seljuk capital. The Lamplighters had taken her master there.',
    'It was Şeb-i Arûs. The wedding night.',
    'Centuries before, a poet named Mevlânâ had died in this city. As he was leaving, he had said, “Do not weep. This is my wedding night.”',
    'The Lamplighters believed that on this night, light could not die. They had waited for it so the master\'s lamp would never go out.',
    'On a hill above the plain stood a wolf with a sky-blue mane, his face turned toward the city.',
    'FINAL ACT · THE WEDDING',
  ],
  [
    'For hiding earth in his mouth, Kişi was driven from the light. He was cast beneath the earth. In time, he became its lord, and they called him Erlik.',
    'The stolen lights were flowing into his realm. The master had been brought this way as well. Saye could sense a trace of him in the stones.',
    'The bards tell of a hero named Er Töştük who once fell beneath the earth. His speaking horse, Çalkuyruk, showed him the road back to the world above.',
    'Here roamed Erlik\'s shadows: the Körmös. They flocked to light and shut the souls they stole in cages.',
  ],
  [
    'The bard says a people once fell in a great war. Only two warriors, Kıyan and Nüküz, escaped with their wives.',
    'They took refuge in a hidden valley among the mountains: Ergenekon. The way in was narrower than a goat track. Within lay meadows, rivers, fruit trees and plentiful game.',
    'Four hundred years passed. Their people grew until the valley could no longer hold them. They wished to leave, but impassable mountains hemmed them in on every side.',
    'A blacksmith said, “That mountain is iron. Let us heap wood and charcoal against it. With bellows, we can melt a way through.” They made seventy bellows of hide.',
    'The iron melted. A passage opened, wide enough for a laden camel. Some tellings say a grey wolf showed them the way out.',
    'They made that day a feast. Each year, they heated a piece of iron in the fire and struck it on the anvil.',
    'Now the valley\'s forge was cold. The Lamplighters had taken its fire too. The bellows lay silent. To return to the world above, Saye would have to pass through this mountain of iron.',
  ],
  [
    'The bards tell of shamans in the Altai whose souls rose into the heavens when they beat their drums. They saw the many layers of the sky and returned to tell of them.',
    'On the highest sat Ülgen, the source of light. As Erlik ruled the depths of the earth, so Ülgen ruled the heights of heaven.',
    'On one layer, the moon burned with a soft, cold light. On another, the stars circled the Iron Stake.',
    'Two horses were tethered to that stake. The Seven Thieves tried to steal them. Between the layers blew Yel Ana, the Wind Mother.',
    'The Lamplighters had carried a fragment of the broken sun to the highest heaven. A shaman struck his drum. With its sound, Saye rose above the clouds.',
  ],
  [
    'At the bottom of Derinkuyu, Saye caught hold of a root hanging between the stones. It stirred, then drew her upward, toward the light.',
    'Dawn was breaking when she emerged. Before her stretched a forest without end. Birch and pine, the scent of moss. Birdsong came from every side.',
    'The ancestors had carved this forest\'s name in stone: Ötüken. There was no better place, they said, to make a homeland endure.',
    'At its heart, the Tree of Life rose into the sky. They say Umay sits among its branches, where the souls of children yet unborn gather as birds.',
    'But something else had risen with Saye. The thing that had seen her in the cistern and crept behind her through Derinkuyu: the Karabasan.',
    'The Karabasan could sense a shadow without a keeper. It would bear down upon one as it bears down on a sleeper\'s chest. A shadow that had lost her master was its sweetest morsel.',
    'But it could not step into the light. Every shaft of sunlight between the leaves was a place where Saye could take shelter.',
    'ACT FIVE · ÖTÜKEN',
  ],
  [
    'Yel Ana set Saye down at the threshold of the sun\'s realm. The shaman\'s drum could no longer be heard. She had climbed very high.',
    'Beyond this realm stood Ülgen\'s gate. The fragment of the broken sun was waiting there.',
    'In the sun\'s realm, the light could burn. Yet even here, at the heights of heaven, Erlik\'s storm would not relent.',
    'They say the shadow of the Huma bird brings good fortune to whomever it falls upon. And Tulpar carries heroes from one heaven to the next.',
    'The Yakuts hear Süge Toyon\'s voice in thunder and say he casts his lightning at evil spirits. That night, the sky was never silent.',
  ],
  [
    'From the roof of the semahane, she looked toward the Green Dome. Light hoarded for centuries was spilling from within.',
    'The Lamplighters had brought the master to its highest point, beneath the finial. Beside him stood the oldest of them: the Chief Lamplighter.',
    'They say the Chief Lamplighter had once been a shadow player too. He closed his lamp rather than share its light. That was the day he lost his shadow.',
    'The master\'s lamp was flickering. Midnight was near.',
  ],
  [
    'The roots of the Tree of Life reached to the bottom of the earth. Saye slipped down between them. From the depths came the sound of water.',
    'The bard says that in the beginning, there was only water. Above that boundless water flew Kayra Han and Kişi, the first being he had made, like two black geese.',
    'One day, a white mother rose from the water. “Create,” said Ak Ana. Then she sank beneath the surface once more.',
    'Kişi wished to rise higher than Kayra Han. Instead, he fell into the water. He was told to dive to the bottom and bring back earth. But he kept a handful hidden in his mouth.',
    'Now the lights stolen by the Lamplighters were flowing to the bottom of this sea. Saye drew a deep breath and let herself fall into the world\'s first water.',
  ],
];

/// Oynanış sırası. Bölümün kimliği `levels` listesindeki yeridir ve hiç
/// değişmez (kayıt, hatıralar, görülen olaylar bu kimlikle tutulur); yeni
/// bölümler listenin sonuna eklenir, oynanıştaki yerlerine bu sırada girer.
const levelOrder = <int>[
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 20, 14, 15, 16, 18, 13, 19, //
];

/// Sıra değişince artar: kayıttaki "açılan en ileri bölüm" (sıradaki yer)
/// eski sıradan yenisine çevrilir.
const levelOrderVersion = 8;

/// Eski sıra sürümlerinde her yerdeki bölüm kimliği (1. sürüm: kimlik =
/// yer).
const _levelOrderHistory = <int, List<int>>{
  1: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
  2: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 13],
  3: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 13],
  4: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 13],
  5: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 14, 15, 16, 13],
  6: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 14, 15, 16, 18, 13],
  7: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 14, 15, 16, 18, 13, 19],
  8: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 20, 14, 15, 16, 18, 13, 19],
};

/// Bölümün oynanış sırasındaki yeri (yoksa -1).
int orderOf(int level) => levelOrder.indexOf(level);

/// Sıradaki bölüm (son bölümse null).
int? nextLevel(int level) {
  final i = orderOf(level);
  return i >= 0 && i + 1 < levelOrder.length ? levelOrder[i + 1] : null;
}

/// Eski bir sıra sürümündeki yeri bugünkü sıradaki yere çevirir.
int migrateOrderPosition(int position, int fromVersion) {
  final old = _levelOrderHistory[fromVersion] ?? _levelOrderHistory[1]!;
  if (position < 0) return 0;
  final level = old[position.clamp(0, old.length - 1)];
  final now = orderOf(level);
  return now < 0 ? 0 : now;
}

List<String> interludeText(int level) {
  final all = S.en ? interludesEn : interludes;
  return level < all.length ? all[level] : const [];
}

/// Bölüm içi köprüler: Hikâye tiyatrosunda her bölümün perdesinden sonra,
/// Sâye'nin o bölümde yaşadıkları (indeks = bölüm). Oyunda oynanan yol
/// perdede kısaca anlatılır; böylece perdeler birbirine bağlanır.
const bridges = <List<String>>[
  [
    'Sâye, sütunların arasında yol aradı. Karanlık su kıpırdadı; içinden bir su iyesi belirdi. İnce eliyle paslı bir vanayı gösteriyordu.',
    'Sütunların dibinde Medusa\'nın taş başları yatıyordu. Biri baş aşağıydı, öteki yana dönüktü. Sâye, gölgesini o bakışlara değdirmeden aralarından geçti.',
    'Bir sala binip karanlık kanallarda süzüldü. Suyun bittiği yerde bir merdiven yükseliyordu. Basamaklar onu yukarıya, yanan şehre çağırıyordu.',
  ],
  [
    'Sâye, kulenin zindanından yukarı tırmandı. Her katta Kandilcilerin gözcüleri vardı. Soğuk fenerler duvarları tararken o, bir gölgeden ötekine sığındı.',
    'Hezarfen\'in eski atölyesinde tozlu bir sandık buldu. İçinde kartal tüyünden iki kanat yatıyordu. Sanki bunca yıl onun gelmesini beklemişlerdi.',
    'Çan katını aştı, kulenin sivri çatısının tepesine çıktı. Aşağıda Haliç bir ayna gibi parlıyordu. Sâye gözlerini kapadı. Kendini rüzgâra bıraktı.',
  ],
  [
    'Sâye, rüzgâr yolunda kanatlarını açtı. Kargaların adaları, ardından Kandilcilerin bulut kampı geride kaldı.',
    'Fırtına adalarında bir şimşek çaktı; perde bir an ışığa boğuldu. Sâye, gölgeden örülmüş bir köprünün üstünden uçtu.',
    'Bulutların arasında Tulpar\'ın yelesi bir an parlayıp kayboldu. İleride zümrüt bir dağ yükseliyordu. Dünyanın kıyısına varmışlardı.',
  ],
  [
    'Sâye zümrüt köprüyü aştı. Kandilcilerin gök karakoluna varınca gölgesini rüzgâra bıraktı, önlerinden süzülüp geçti.',
    'Simurg\'un üç tüyünü birer birer buldu. Dokunduğu her tüyde, dağın başka bir yerinden bir kuş sesi yükseldi.',
    'Üçüncü tüyü bulduğunda ayna salonunun kapısı açıldı. İçerisi karanlıktı. Karanlığın içinde bir ayna onu bekliyordu.',
  ],
  [
    'Sâye, iplere tutunarak dağın yamacına tırmandı. Tipi yüzüne vuruyordu. Terk edilmiş bir ağıla sığındığında ancak soluklanabildi.',
    'Akori köyünde eski bir bağın yanından geçti. Tufandan sonra dikildiği söylenirdi. Yol onu bir manastıra götürdü; içeride Ayaz Ata\'nın ak gölgesi vardı.',
    'Buz mağarasının dibine vardığında durdu. Buzun ardında kocaman, kararmış bir gemi gövdesi yatıyordu.',
  ],
  [
    'Ambarlarda aslanların, atların, kuşların gölgeleri dolaşıyordu. Sâye kilitleri birer birer açtı. Ayrı düşen eşler yeniden birbirine kavuştu.',
    'Ambar kuyusunun dibinde Ak Ana, suyun içinden ona baktı. Ardından su yükselmeye başladı; Sâye\'yi alıp güverteye taşıdı.',
    'Ama güvertedeki ışık yerinde değildi. Kandilciler onu çoktan götürmüştü. Sâye yine geride kalmıştı.',
  ],
  [
    'Sâye, batı terasında başsız tanrıların arasına girdi. Ayağının altında deprem yarıkları açılıyor, ardından yeniden kapanıyordu.',
    'Kartalın gözünden geçip tümülüsün taşları arasına girdi. Oradan doğu terasına uzanan bir yol buldu.',
  ],
  [
    'Doğu terasında taştan dev ayağa kalktı. Her adımında dağ sarsılıyordu. Sâye, onun düşen gölgelerine sığınarak kaçtı.',
    'Güneşin ilk ışığı taş yüzlere değdiğinde Sâye elini uzattı. Kandilcilerin yakmak üzere olduğu ışığa dokundu.',
  ],
  [
    'Gökbörü, kervan yolunda önden yürüdü. Sâye onun karda bıraktığı izlere basarak kurtların ormanını geçti.',
    'Ardından donmuş gölü aştı. Ocağı sönmüş bir hanı geride bıraktığında, ejderin eteğine varmıştı.',
  ],
  [
    'Çoban kulübesinde tahta bir kızak buldu. Aşağıda kervan uzaklaşıyordu. Sâye kızağa oturdu, kendini ejderin sırtından aşağı bıraktı.',
    'Kandil balonlarının altından, manyetik tepenin üstünden kaydı. Ejderin sıçrayışında yerden kesildi; Erzurum\'a doğru süzülerek indi.',
  ],
  [
    'Ejder uyanmıştı. Beyaz nefesi, Sâye\'nin ardından yamacı kaplayarak geliyordu.',
    'Gökbörü önden koştu. Sâye kırık sırttan son kez atlayıp bir sığınağa girdi. Çığ, başının üstünden geçip gitti.',
  ],
  [
    'Sâye, Muşkara\'dan yukarı, peri bacalarına tırmandı. Güvercinliklerin ve kaya kiliselerinin arasında periler dans ediyordu.',
    'Albastı, kızıl gölgesini uzatıp ışığını almaya geldi. Sâye demirin ardına sığındı. Albastı oraya yaklaşamadı.',
    'Ay yükselirken Sâye, Uçhisar\'ın tepesine vardı.',
  ],
  [
    'Mahzenleri, şapeli ve havalandırma bacalarını geçerek derin kuyuya indi. Yuvarlak taş kapılar, içeriden açılıp ona yol verdi.',
    'Devlerin kapısına vardığında uyuyan dev gözlerini açtı. Sâye kaçtı; karanlıkta Gökbörü\'nün parlayan gözleri ona yol gösteriyordu.',
    'En dipte taşların arasından kökler sarkıyordu. Sâye yukarıdan gelen yaprak kokusunu duydu.',
  ],
  [
    'Sâye, Konya ovasından eski höyüğe yürüdü. İkonion kapısını geçip Alâeddin Tepesi\'ne vardı.',
    'Karatay\'ın yıldızlı kubbesinin altından geçti. İnce Minare\'yi, Şems\'in kuyusunu geride bıraktı. Semâhaneye vardığında semâzenler dönüyordu.',
    'Kar yağıyordu. Sâye, Yeşil Kubbe\'ye tırmandı.',
  ],
  [
    'Sâye kara kapıdan geçti. Mürekkep köprülerde Körmösler ışığının kokusunu aldı. O da karanlığın içine saklandı.',
    'Kut zindanında kafesleri açtı. Çalınan canlar birer kuşa dönüştü; kanat çırpıp yukarı uçtu.',
    'Çalkuyruk kuyusunun dibinde bir at başını kaldırdı. Er Töştük\'ün atıydı bu. Sâye\'ye yukarı çıkan yolu gösterdi.',
  ],
  [
    'Kıyan Boğazı\'ndan demir dağın dibine indi. Kömür sandıklarını ocağa sürdü, körükleri ritim tutarak bastı. Ocakta yeniden ateş yükseldi.',
    'Erimiş demir dalga dalga aktı. Sâye, sisli çayırın adacıklarını aştı. Asena\'nın mağarasına vardığında boz kurdun gözleri parladı.',
    'Demir dağın içinden bir yol açtı. Nevruz örsüne üç kez vurdu. Kapı açıldı.',
  ],
  [
    'Davulun her vuruşunda biraz daha yükseldi. Bulut kapısını aştı; ay katından yıldız katına geçti.',
    'Demir Kazık\'ın atlarına tutunup Yedi Karakçı\'nın arasından sıyrıldı. Yada taşını kullanarak Yel Ana\'nın esişine yön verdi.',
  ],
  [
    'Kökler Sâye\'yi Ötüken\'in yeşiline çıkardı. O, yaprakların arasından düşen ışıkta yürüdü. Karabasan\'ın gözleri gölgelerin içinde açılıp kapanıyordu.',
    'Kamın davulu vurdukça kökler kalktı. Sâye sarmaşıklara tutunup dikenli yarları aştı. Ak bir geyik, ateşböceklerinin ışığını izledi; kök kapılarını ona açtı.',
    'Kara Bataklık\'ta Karabasan bütün gücüyle üstüne geldi. Sâye Hayat Ağacı\'na tırmandı, aynalarla güneşi aşağıya taşıdı. Işık köklere aktığında Karabasan dağıldı.',
  ],
  [
    'Hüma\'nın gölgesi Sâye\'nin başına düştü. Süge Toyon\'un yıldırımları göğü aydınlatırken o, kara bulutların üstüne bastı.',
    'Ülgen\'in kapısına vardığında Tulpar oradaydı. Onu bekliyordu.',
  ],
  [
    'Sâye, şadırvanın havuzundaki ay ışığını aynalara aldı. Işığı türbenin gümüş kapısına taşıdı.',
    'Kandiller koridorunda kafesleri açtı. Çalınan ışıklar sahiplerini hatırladı; ardından kavanozuna doldu.',
    'Kubbenin yeşil kaburgalarına tutunarak tırmandı. Aşağıda biriken ışık artık dışarı taşıyordu.',
    'Tepede üç aynayı çevirdi. Kandilci Başı baktı. Yüzyıllar sonra ilk kez kendi gölgesini görüyordu.',
  ],
  [
    'Kandilcilerin sandalları suyun üstünde dolaşıyordu. Sâye, aşağıda yosunların arasından yüzdü. Fenerlerinin altından geçti; fenerbalığının yeminden uzak durdu.',
    'Denizanaları karanlık mağaralarda ona ışık oldu. Akıntıya karşı yüzdü. Bir su kaplumbağası onu alıp Kişi\'nin taşına taşıdı.',
    'Dipte Körmösler yaklaşırken su kıpırdadı. Ak Ana yükseldi, Sâye\'ye ak bir nefes verdi. Sâye yarıktan aşağı süzüldü; Erlik\'in katına iniyordu.',
  ],
];

const bridgesEn = <List<String>>[
  [
    'Saye searched for a way through the columns. The dark water stirred, and a water spirit rose from it. Her slender hand pointed to a rusted valve.',
    'Medusa\'s stone heads lay at the foot of the columns. One was upside down; the other lay on its side. Saye slipped between them, keeping her shadow clear of their gaze.',
    'She boarded a raft and drifted through the dark channels. Where the water ended, a stairway rose. Its steps led upward, toward the burning city.',
  ],
  [
    'Saye climbed out of the tower\'s dungeon. The Lamplighters\' watchers stood on every floor. As their cold lanterns swept the walls, she slipped from one shadow to the next.',
    'In Hezarfen\'s old workshop, she found a dusty chest. Inside lay two wings of eagle feathers. They seemed to have waited all those years for her.',
    'She passed the bells and climbed to the tip of the tower\'s pointed roof. Far below, the Golden Horn shone like a mirror. Saye closed her eyes and gave herself to the wind.',
  ],
  [
    'Saye spread her wings along the wind road. The islands of crows fell behind her, then the Lamplighters\' camp among the clouds.',
    'Lightning struck over the storm islands, flooding the screen with light. Saye flew above a bridge woven from shadow.',
    'Tulpar\'s mane flashed once between the clouds and vanished. Ahead, an emerald mountain rose. They had reached the edge of the world.',
  ],
  [
    'Saye crossed the emerald bridge. At the Lamplighters\' sky outpost, she gave her shadow to the wind and glided past.',
    'One by one, she found the Simurgh\'s three feathers. Each time she touched one, a bird called from somewhere on the mountain.',
    'With the third feather, the door to the mirror hall opened. All was dark within. And in that darkness, a mirror waited for her.',
  ],
  [
    'Saye hauled herself up the ropes along the mountainside. The blizzard struck her face. Only in an abandoned sheepfold could she stop to catch her breath.',
    'In the village of Akori, she passed an old vineyard said to have been planted after the Flood. The path led to a monastery. Inside stood the white shadow of Ayaz Ata.',
    'At the bottom of the ice cave, she stopped. Beyond the ice lay the vast, darkened hull of a ship.',
  ],
  [
    'The shadows of lions, horses and birds wandered through the holds. Saye opened the locks, one by one. Those who had been parted found each other again.',
    'At the bottom of the hold\'s well, Ak Ana looked up from the water. Then the water began to rise, carrying Saye to the deck.',
    'But the light was gone. The Lamplighters had taken it long before. Once again, Saye had come too late.',
  ],
  [
    'Saye entered the western terrace among the headless gods. Earthquake fissures opened beneath her feet, then closed again.',
    'She passed through the eagle\'s eye and into the stones of the burial mound. There she found a way to the eastern terrace.',
  ],
  [
    'The stone giant rose on the eastern terrace. The mountain shook with every step. Saye fled, taking shelter in the shadows it cast.',
    'As the first sunlight touched the stone faces, Saye reached out. Her hand found the light the Lamplighters were about to kindle.',
  ],
  [
    'Gökbörü went ahead along the caravan road. Saye followed his tracks through the forest of wolves.',
    'She crossed the frozen lake. Beyond an inn with a cold hearth, she reached the foot of the dragon.',
  ],
  [
    'She found a wooden sled in a shepherd\'s hut. Below, the caravan was drawing away. Saye climbed aboard and let herself go down the dragon\'s back.',
    'She slid beneath the lantern balloons and over the magnetic hill. At the dragon\'s leap, she left the ground and sailed down toward Erzurum.',
  ],
  [
    'The dragon had woken. Its white breath swept down the slope behind Saye.',
    'Gökbörü ran ahead. Saye leapt from the broken ridge one last time and slipped into shelter. The avalanche thundered over her head.',
  ],
  [
    'Saye climbed from Muşkara into the fairy chimneys. Among the dovecotes and rock churches, the fairies were dancing.',
    'Albastı stretched out her crimson shadow to take Saye\'s light. Saye took shelter behind iron. Albastı could come no closer.',
    'As the moon rose, Saye reached the top of Uçhisar.',
  ],
  [
    'Through cellars, past the chapel and down the air shafts, she descended to the deep well. The round stone doors opened from within and let her through.',
    'At the giants\' gate, the sleeping giant opened its eyes. Saye ran. In the darkness, Gökbörü\'s shining eyes showed her the way.',
    'At the very bottom, roots hung between the stones. From somewhere above came the scent of leaves.',
  ],
  [
    'Saye walked from the plain of Konya to the old mound. Through the gate of Iconium, she reached the Hill of Alâeddin.',
    'She passed beneath Karatay\'s starry dome, beyond the Slender Minaret and the well of Shams. In the semahane, the hall of the whirling dervishes, they were already turning.',
    'Snow was falling. Saye climbed the Green Dome.',
  ],
  [
    'Saye passed through the black gate. On the bridges of ink, the Körmös caught the scent of her light. She hid in the dark.',
    'In the prison of kut, where souls were held, she opened the cages. The stolen souls became birds and beat their wings toward the world above.',
    'At the bottom of Çalkuyruk\'s well, a horse raised its head. It was Er Töştük\'s horse. He showed Saye the way up.',
  ],
  [
    'Through Kıyan Gorge, she descended to the foot of the iron mountain. She pushed the coal crates into the forge and worked the bellows in rhythm. Fire rose in the hearth once more.',
    'Molten iron flowed in waves. Saye crossed the islets of the misty meadow. At Asena\'s cave, the grey wolf\'s eyes shone.',
    'She opened a way through the iron mountain. Three times she struck the Nevruz anvil. The gate opened.',
  ],
  [
    'With every beat of the drum, she rose a little higher. Through the cloud gate, past the moon, she climbed to the layer of stars.',
    'Holding fast to the horses of the Iron Stake, she slipped past the Seven Thieves. With the yada stone, she guided the breath of Yel Ana.',
  ],
  [
    'The roots brought Saye into the green of Ötüken. She walked in the light falling through the leaves. In the shadows, the Karabasan\'s eyes opened and closed.',
    'At each beat of the shaman\'s drum, the roots rose. Saye swung on vines across thorny ravines. A white deer followed the glow of her fireflies and opened the gates of root for her.',
    'In the Black Marsh, the Karabasan came at her with all its strength. Saye climbed the Tree of Life and turned the mirrors, bringing sunlight down. Light flowed into the roots, and the Karabasan scattered.',
  ],
  [
    'The Huma\'s shadow fell upon Saye. As Süge Toyon\'s lightning lit the heavens, she stepped onto the black clouds.',
    'At Ülgen\'s gate, Tulpar was waiting for her.',
  ],
  [
    'Saye caught the moonlight in the fountain\'s pool with her mirrors and carried it to the tomb\'s silver door.',
    'In the corridor of lamps, she opened the cages. The stolen lights remembered those they belonged to, then poured into her jar.',
    'She climbed the green ribs of the dome. Below her, the gathered light was spilling out.',
    'At the summit, she turned three mirrors. The Chief Lamplighter looked down. For the first time in centuries, he saw his own shadow.',
  ],
  [
    'The Lamplighters\' boats moved overhead as Saye swam through the kelp. She passed beneath their lanterns and kept clear of the anglerfish\'s lure.',
    'Jellyfish lit her way through the dark caves. She swam against the current. A sea turtle carried her to Kişi\'s stone.',
    'In the depths, the Körmös drew near. The water stirred. Ak Ana rose and gave Saye a breath of white light. Saye slipped down through the rift, into Erlik\'s realm.',
  ],
];

/// Bölümün köprü satırları (tiyatro).
List<String> bridgeText(int level) {
  final all = S.en ? bridgesEn : bridges;
  return level < all.length ? all[level] : const [];
}

const levels = <LevelDef>[
  LevelDef(
    title: 'I · YEREBATAN',
    legends: ['hayal', 'hudhud'],
    bard: 'Ozan der ki: Suyun altında şehir uyur; uyanık kalanı Umay korur.',
    bardEn: 'The bard says: a city sleeps beneath the water; Umay guards the one who stays awake.',
    cameos: [('suIyesi', 0, 0)],
    subtitle: 'Suyun altında bir şehir uyur.',
    theme: LevelTheme.cistern,
    titleEn: 'I · THE CISTERN',
    subtitleEn: 'Beneath the water, a city sleeps.',
    whispers: [
      'Sâye… Bu ustanın sesi mi, suyun mu?',
      'Fener neye değerse onu alır. Karanlıkta kal.',
      'Taşa dönmesin diye başını çevirmişler. Bakmadan görmeyi öğren.',
      'Kapılar zorla değil, sabırla açılır.',
      'Tavanda uyuyanları uyandırma. Her ses bir ihbardır.',
      'Biri iner ki öbürü yükselsin. Âlemin terazisi böyle kurulmuş.',
      'Bazı yollar yalnızca ışığa görünür. Bazıları yalnızca karanlığa.',
      'Çürümüş tahta seni taşır. Senden ağır olanı taşımaz.',
      'Su da bir kapıdır: önce boşalır, sonra yükseltir.',
      'Sarnıcın dibindeki iki Medusa başından birini ters, birini yan koymuşlar; kimse taşa dönmesin diye. Bu ikisini düz bırakmışlar.',
      'Perseus ona hiç doğrudan bakmadı. Cilalı kalkanında gördü ve yürüdü.',
      'Bu sular bin yıl şehre su taşıdı. Şimdi bir gölge taşıyor.',
    ],
    whispersEn: [
      'Saye… Is that the master\'s voice, or the water\'s?',
      'Whatever the lantern touches, it takes. Keep to the dark.',
      'They turned her head so no one would become stone. Learn to see without looking.',
      'Doors open to patience, not to force.',
      'Do not wake those who sleep above. Every sound gives you away.',
      'One must sink so the other may rise. So the scales of the world were set.',
      'Some paths show themselves only to the light. Some, only to the dark.',
      'Rotten wood will bear you. It will not bear one heavier.',
      'Water too is a door: first it empties, then it lifts.',
      'At the bottom of the cistern they laid one Medusa head upside down and one on its side, so no one would turn to stone. These two they left upright.',
      'Perseus never looked at her directly. He saw her in his polished shield, and walked.',
      'For a thousand years these waters carried water to the city. Now they carry a shadow.',
    ],
    memories: [
      'Hatıra · Perdeye ışık tutarken elleri hiç titremezdi. "Gölge, ışığın sözüdür Sâye," derdi.',
      'Hatıra · Gösteri bitince kandili hiç üflemezdi. "Gölgeler korkar," derdi.',
      'Hatıra · Bir gece perdenin arkasına geçmeme izin vermedi. "Gölge arkayı görmemeli," dedi.',
      'Hatıra · Perdenin önünde ilk adımımı attığımda gülmüştü: "Gölgen senden önce yürüyor."',
      'Hatıra · Ustam taş başları perdede hiç oynatmazdı. "Taşa dönen, gölge bile bırakmaz," derdi.',
      'Hatıra · Bir gece Haliç\'e sandalla açıldık. Suya düşmüş bir kandilin ışığını uzun uzun seyretti.',
    ],
    memoriesEn: [
      'Memory · His hands never trembled as he held the light to the screen. "A shadow is the light\'s word, Saye," he said.',
      'Memory · When the show ended, he never blew out the lamp. "The shadows would be afraid," he said.',
      'Memory · One night he would not let me behind the screen. "A shadow must not see what is behind it," he said.',
      'Memory · When I took my first step before the screen, he laughed: "Your shadow walks ahead of you."',
      'Memory · My master never played the stone heads on the screen. "Whoever turns to stone leaves not even a shadow," he said.',
      'Memory · One night we rowed out onto the Golden Horn. He watched the light of a fallen lamp under the water for a long time.',
    ],
    place: 'Yerebatan Sarnıcı · İstanbul, Temmuz 1660',
    placeEn: 'The Basilica Cistern · Istanbul, July 1660',
    areas: [
      'Sütunlar Ormanı',
      'Medusa\'nın Başları',
      'Paslı Kapı',
      'Yarasa Galerisi',
      'Terazi',
      'Yırtık Perde',
      'Işıkla Gölgenin Köprüsü',
      'Dar Geçit',
      'Su Haznesi',
      'Medusa Salonu',
      'Sal Kanalı',
      'Karanlık Kanallar',
    ],
    areasEn: [
      'The Forest of Columns',
      'The Heads of Medusa',
      'The Rusted Gate',
      'The Bat Gallery',
      'The Scales',
      'The Torn Veil',
      'The Bridge of Light and Shadow',
      'The Narrow Passage',
      'The Water Basin',
      'The Hall of Medusa',
      'The Raft Channel',
      'The Dark Channels',
    ],
    map: kMapYerebatan,
    echoes: [(20, 31), (72, 89)],
    // Su haznesinin çıkışında isteğe bağlı ritim yolu: basınca kalkan geniş
    // kaya, sonra biri yükselirken öbürü inen iki kaya; uçta bir ateşböceği.
    // Yarasa Galerisi'nin çıkışında sola bakan Gözcü: son sütunlarla çıkış
    // arasını tarar; bekçiyi çana çekip onun dönüşünü bekleyen geçer.
    watchers: [
      (
        95,
        11,
        WatcherProfile(facing: -1, center: 0.42, sweep: 0.3, speed: 0.9),
      ),
    ],
    rocks: [
      (173, 10, RockProfile(onStep: true, width: 3, pause: 1.2, period: 6)),
      (177, 10, RockProfile(period: 5, pause: 1.2, phase: 0)),
      (180, 10, RockProfile(period: 5, pause: 1.2, phase: 0.5)),
    ],
    // S2a · Unutulmuş Gölgehane: yolun sonundaki boşluğun dibinde taş gibi
    // boyanmış perde (sahanlığın sol üst hücresi); ardında ustanın odası.
    surprises: [('golgehane', 45, 15), ('karagoz', 44, 13)],
  ),
  LevelDef(
    title: 'II · KULE',
    bard: 'Ozan der ki: Yükselen merdiven göğe varmaz; varan, gölgesini yerde bırakandır.',
    bardEn: 'The bard says: no stair reaches the sky; only one who leaves the shadow on the ground arrives.',
    subtitle: 'Yükseldikçe ışık soğur.',
    theme: LevelTheme.cliffs,
    titleEn: 'II · THE TOWER',
    subtitleEn: 'The higher you climb, the colder the light.',
    whispers: [
      'Haliç\'in suları her şeyi hatırlar; düşenleri de.',
      'Basınca kopan taşlar var. Hiçbir yer seni uzun süre taşımaz.',
      'Damlarda bir Kandilci dolaşıyor. Kargalar onun gözleridir.',
      'Kanatlar otuz yıldır burada bekliyordu. Hezarfen gibi rüzgâra teslim ol: lodos seni de taşır.',
      'Hezarfen bin fen bilirdi; ışığı toplayan camını da kulede bıraktı. Bir aynayla ışığı dilediğin göze çevir.',
      'Galata\'nın altında mahzenler yanıyor. Alevin de bir nefesi var; dinle.',
      'Bir sandık bir alevi susturur. Hangisini susturacağını iyi seç.',
      'Kulenin çanı rüzgârda inler. Yanında yukarı basıp bir kez sen çal: Kandilciler sese gelir.',
      'Kulenin dibi zindandır. Kanuni zamanında tersanede çalıştırılan esirler burada yatarmış. Karanlık ışığını yer; zindancının fenerinden uzak dur, zincire tutun.',
    ],
    whispersEn: [
      'The waters of the Horn remember everything, even those who fall.',
      'Some stones break beneath you. Nothing holds you for long.',
      'A Lamplighter walks the rooftops. The crows are his eyes.',
      'The wings have waited here for thirty years. Surrender to the wind as Hezarfen did: the south wind will carry you too.',
      'Hezarfen knew a thousand sciences; he left his light-gathering glass in the tower. With a mirror, turn its light on any eye you choose.',
      'Beneath Galata the cellars are burning. Fire breathes too; listen.',
      'One crate can silence one flame. Choose well which.',
      'The tower bell moans in the wind. Press up beside it and ring it once yourself: the Lamplighters come to its voice.',
      'The foot of the tower is a dungeon. In Suleiman\'s time the captives who laboured in the shipyard slept here. The dark eats your light; keep away from the jailer\'s lantern and hold on to the chain.',
    ],
    memories: [
      'Hatıra · Ustam zindandan kurtulan bir esirin gölgesini perdeye çıkarırdı. "Zincir kırılır, Sâye," derdi. "Gölge zaten hiç bağlanmamıştı."',
      'Hatıra · "Haliç bir aynadır," derdi ustam. "Şehir kendine orada bakar."',
      'Hatıra · Kulenin tepesini gösterip "Bir gün oradan bütün perdeyi göreceksin," demişti.',
      'Hatıra · Gözcülerin ışığı soğuktur; çünkü onlar ışığı sevmez, sayar.',
      'Hatıra · Ustam o gün Doğancılar\'daki kalabalığın içinde bir çocukmuş. "Herkes kanatlara baktı," derdi, "ben onun yüzüne baktım. Korkmuyordu. Gölgesi denizin üstünde bir kuş gibi kayıp gidiyordu."',
      'Hatıra · Kuleden şehre bakarken sorardı: "Bunca ışığın gölgesi nereye düşer?"',
    ],
    memoriesEn: [
      'Memory · My master used to bring the shadow of a captive who escaped the dungeon onto the screen. "Chains break, Saye," he said. "The shadow was never bound."',
      'Memory · "The Horn is a mirror," he said. "The city looks at itself there."',
      'Memory · He pointed at the top of the tower: "One day you will see the whole screen from there."',
      'Memory · The Watchers\' light is cold, for they do not love the light; they count it.',
      'Memory · That day my master was a child in the crowd at the Square of the Falconers. "Everyone looked at the wings," he said, "I looked at his face. He was not afraid. His shadow slid over the sea like a bird."',
      'Memory · Looking down at the city from the tower he would ask: "Where do the shadows of all these lights fall?"',
    ],
    place: 'Galata Kulesi · İstanbul, Temmuz 1660',
    placeEn: 'Galata Tower · Istanbul, July 1660',
    areas: [
      'Kulenin Zindanı',
      'Yanan Mahzen',
      'Haliç Kıyısı',
      'Kargaların Yuvası',
      'Kandilci Rafı',
      'Terazi Asansörü',
      'Gözcü Katı',
      'Hezarfen\'in Atölyesi',
      'Çan Katı',
      'Külahın Tepesi',
    ],
    areasEn: [
      'The Tower Dungeon',
      'The Burning Cellar',
      'The Golden Horn Shore',
      'The Crows\' Nest',
      'The Lamplighter\'s Ledge',
      'The Balance Lift',
      'The Watcher\'s Floor',
      'Hezarfen\'s Workshop',
      'The Bell Floor',
      'The Top of the Cone',
    ],
    map: kMapKule,
    vistas: [(12, 3, 'halic')],
  ),
  LevelDef(
    title: 'III · GÖKYOLU',
    bard: 'Ozan der ki: Bulut yol olur, yiğit yolcu; kanatlı at yolu önden bilir.',
    bardEn: 'The bard says: the cloud becomes a road, the brave its traveller; the winged horse knows the way ahead.',
    cameos: [('tulpar', 140, 8)],
    // Uzatma: lodos (arkadan), poyraz (önden) ve uçurtmalar.
    yel: [(290, 0, 299, 12, 1), (300, 0, 314, 12, -1), (318, 0, 331, 12, 1)],
    kites: [
      (353, 9, 0),
      (361, 8, 1.2),
      (369, 10, 2.4),
      (377, 8, 3.4),
      (385, 9, 0.6),
      (393, 8, 1.8),
    ],
    subtitle: 'Kaf\'a giden yol buluttandır.',
    theme: LevelTheme.sky,
    wings: true,
    storm: true,
    titleEn: 'III · THE SKY ROAD',
    subtitleEn: 'The road to Qaf is made of cloud.',
    whispers: [
      'Kırık güneşin bir parçası… Sıcaklığı tanıdık.',
      'Burada da Kandilciler var. Gök bile onların.',
      'Gök sandığın kadar boş değil.',
      'Rüzgâr seni taşır; yeter ki bırakma.',
      'Kandilciler fenerlerini balonlara asmış. Gökte de gözleri var.',
      'Gölgeden bir köprü: ışık değerse dağılır. Karanlığını kolla.',
      'Şimşek çakınca bir an her şey görünür: önündeki yol da.',
      'Kırık güneşin kapısı. Kandilciler onu kimseye açmaz.',
      'Evliya Çelebi anlatır: Hezarfen lodosla uçtu. Arkadan esen lodos seni ileri taşır; önden esen poyrazda çömel, taşın ardına sığın.',
      'Aşağıdaki damlarda çocuklar uçurtma uçuruyor. Uçurtmalar rüzgârda salınır; birinden ötekine atla.',
    ],
    whispersEn: [
      'A shard of the broken sun… Its warmth is familiar.',
      'Lamplighters here too. Even the sky is theirs.',
      'The sky is not as empty as you thought.',
      'The wind will carry you, so long as you do not let go.',
      'The Lamplighters hung their lanterns from balloons. They have eyes in the sky as well.',
      'A bridge made of shadow: touch it with light and it scatters. Guard its darkness.',
      'When the lightning strikes, for a moment everything is seen: the road ahead too.',
      'The gate of the broken sun. The Lamplighters open it for no one.',
      'Evliya Celebi tells that Hezarfen flew with the lodos. The lodos at your back carries you on; when the poyraz blows in your face, crouch behind a stone.',
      'On the roofs below, children are flying kites. The kites sway in the wind; leap from one to the next.',
    ],
    memories: [
      'Hatıra · Perdenin köşesine bir hüdhüd işlemişti. "Yol gösterene borçlusun," derdi.',
      'Hatıra · "Bir gün güneşi perdeye geri getireceğiz," demişti. O gün gölgemin ilk kez titrediğini gördüm.',
      'Hatıra · Fırtınalı gecelerde perdeyi hiç kapatmazdı. "Şimşek de bir kandildir," derdi.',
      'Hatıra · Bulutları perdede pamukla yapardı. Ben her seferinde birini çalıp cebime koyardım.',
    ],
    memoriesEn: [
      'Memory · He had stitched a hoopoe into the corner of the screen. "You owe the one who shows the way," he said.',
      'Memory · "One day we will bring the sun back to the screen," he said. That day I saw my shadow tremble for the first time.',
      'Memory · On stormy nights he never closed the screen. "Lightning is a lamp too," he said.',
      'Memory · He made clouds on the screen out of cotton. Each time, I stole one and kept it in my pocket.',
    ],
    place: 'Gökyolu · İstanbul\'un üstünde, Ağustos 1660',
    placeEn: 'The Sky Road · Above Istanbul, August 1660',
    areas: [
      'Bulutların Eşiği',
      'Kandilcilerin Bulut Kampı',
      'Gözcü Kayası',
      'Rüzgâr Yolu',
      'Kargaların Adası',
      'Kırık Güneşin Altında',
      'Balon Geçidi',
      'Gölgeden Köprü',
      'Fırtına Adaları',
      'Lodos ile Poyraz',
      'Uçurtmalar',
      'Güneşin Kapısı',
    ],
    areasEn: [
      'The Threshold of Clouds',
      'The Lamplighters\' Cloud Camp',
      'The Watcher\'s Rock',
      'The Wind Road',
      'The Isle of Crows',
      'Beneath the Broken Sun',
      'The Balloon Pass',
      'The Bridge of Shadow',
      'The Storm Isles',
      'Lodos and Poyraz',
      'The Kites',
      'The Gate of the Sun',
    ],
    map: kMapGokyolu,
    // Kandilcilerin gök kampında boşluk: yol fenerle belirir.
    coldRuns: [(446, 8, 8)],
  ),
  LevelDef(
    title: 'IV · KAF',
    legends: ['kaf'],
    bard: 'Ozan der ki: Dünyanın kıyısında zümrüt bir dağ; büyük kuşun gölgesi orada dinlenir.',
    bardEn: "The bard says: an emerald mountain at the edge of the world; the great bird's shadow rests there.",
    subtitle: 'Dünyanın kıyısında zümrüt bir dağ.',
    theme: LevelTheme.kaf,
    wings: true,
    titleEn: 'IV · QAF',
    subtitleEn: 'An emerald mountain at the edge of the world.',
    place: 'Kaf Dağı · Dünyanın kıyısı, Eylül 1660',
    placeEn: 'Mount Qaf · The edge of the world, September 1660',
    areas: [
      'Zümrüt Köprü',
      'Kandilcilerin Gök Karakolu',
      'Gölge Köprüsü',
      'Rüzgârın Sırtı',
      'Hayret Vadisi',
      'Simurg\'un Tüyleri',
      'Otuz Kuş',
      'Simurg\'un Ayna Salonu',
    ],
    areasEn: [
      'The Emerald Bridge',
      'The Lamplighters\' Sky Post',
      'The Shadow Bridge',
      'The Back of the Wind',
      'The Valley of Bewilderment',
      'The Feathers of the Simurgh',
      'Thirty Birds',
      'The Simurgh\'s Hall of Mirrors',
    ],
    whispers: [
      'Burası Kaf. Kuşlar bin yıl uçtu, otuzu vardı.',
      'Kandilciler göğe de nöbetçi dikmiş. Işığı kimseyle bölüşmezler.',
      'Gölgeden köprü ışığa dayanmaz. Ay ışığı da aynaya düşer.',
      'Rüzgâr da bir yolcudur. Ona yaslanan düşmez.',
      'Üç ayna, bir ışık. Aradığın, onun yolunun sonunda.',
      'Simurg buraya üç tüy bırakmış. Üçünü bulmayan aynayı göremez.',
      'Gölgeden köprüyü iki göz bekler. Birinin baktığı yer, öbürünün kör noktası.',
      'Kayalar da nefes alır; inip kalkarlar. Onlarla birlikte yüksel.',
      'Hayret Vadisi. Attâr der ki kuşlar yedi vadiden geçti; birinde şaşkınlıktan yolu göremediler. Burada yol havada görünmez, suda görünür. Aşağı bak.',
      'Otuz kuş Hüdhüd\'ün peşinde uçar. Sırtlarına güven, Sâye; onlar da Simurg\'u arıyor.',
    ],
    whispersEn: [
      'This is Qaf. The birds flew a thousand years, and thirty arrived.',
      'The Lamplighters set watchmen even in the sky. They share their light with no one.',
      'A bridge of shadow cannot bear the light. Moonlight, too, falls into mirrors.',
      'The wind is a traveler too. Whoever leans on it does not fall.',
      'Three mirrors, one light. What you seek waits at the end of its road.',
      'The Simurgh left three feathers here. Whoever does not find all three will never see the mirror.',
      'Two eyes guard the bridge of shadow. Where one looks, the other is blind.',
      'Rocks breathe too; they rise and fall. Rise with them.',
      'The Valley of Bewilderment. Attar says the birds crossed seven valleys; in one, bewilderment hid the way. Here the road cannot be seen in the air, only in the water. Look down.',
      'Thirty birds fly after the Hoopoe. Trust their backs, Saye; they too are seeking the Simurgh.',
    ],
    memories: [
      'Hatıra · "Simurg diye bir kuş yoktur," derdi ustam. "Otuz kuş vardır. Ama bunu ancak varan bilir."',
      'Hatıra · Kandili yakarken hep aynı duayı mırıldanırdı. Sözlerini hiç anlamadım; ışığı anladım.',
      'Hatıra · "Aynaya bakan kendini gördüğünü sanır," derdi. "Oysa ayna ışığı gösterir."',
      'Hatıra · Bir gün perdeye otuz kuş çizdi. Sonra hepsini tek bir tasvirde birleştirdi: "İşte Simurg."',
    ],
    memoriesEn: [
      'Memory · "There is no bird called the Simurgh," my master said. "There are thirty birds. But only those who arrive know it."',
      'Memory · He murmured the same prayer each time he lit the lamp. I never understood the words; I understood the light.',
      'Memory · "Whoever looks in a mirror thinks he sees himself," he said. "But a mirror shows the light."',
      'Memory · One day he drew thirty birds on the screen. Then he joined them all into a single figure: "There. The Simurgh."',
    ],
    map: kMapKaf,
    lake: (128, 183, 20),
    mirrorSteps: [
      (130, 17, 2),
      (134, 16, 2),
      (138, 17, 2),
      (148, 16, 2),
      (152, 16, 2),
      (156, 17, 2),
      (160, 17, 2),
      (168, 16, 2),
      (172, 16, 2),
      (176, 17, 2),
      (180, 17, 2),
    ],
    birdBridges: [(273, 325, 16)],
  ),
  LevelDef(
    title: 'V · AĞRI',
    bard: 'Ozan der ki: Karlı dağ sırrını söylemez; sabredene bir çan çalar.',
    bardEn: 'The bard says: the snowy mountain keeps its secret; for the patient, a bell rings.',
    cameos: [('ayazAta', 243, 15)],
    gokboruWatch: [(218, 10)],
    subtitle: 'Tufandan beri karla örtülü bir sır.',
    theme: LevelTheme.snow,
    wings: true,
    headwind: 140,
    storm: true,
    titleEn: 'V · ARARAT',
    subtitleEn: 'A secret wrapped in snow since the Flood.',
    place: 'Ağrı Dağı · Bayezid, Ekim 1660',
    placeEn: 'Mount Ararat · Bayezid, October 1660',
    areas: [
      'Dağın Eteği',
      'İplerin Geçidi',
      'Terk Edilmiş Ağıl',
      'Buz Mağarası',
      'Akori: Nuh\'un Bağı',
      'Aziz Hakob Manastırı',
      'Tufanın Eşiği',
    ],
    areasEn: [
      'The Foot of the Mountain',
      'The Pass of Ropes',
      'The Abandoned Fold',
      'The Ice Cave',
      'Akori: Noah\'s Vineyard',
      'The Monastery of Saint Hakob',
      'The Threshold of the Flood',
    ],
    whispers: [
      'Bir keşiş zirveye çıkmak istemiş. Her sabah yeniden dağın eteğinde uyanmış.',
      'Rüzgâr kanatlarını geri iter. Burada ip, kanattan sadıktır.',
      'Çobanlar sürülerini bırakıp gitmiş. Kandilciler gelince kuzular bile susar.',
      'Bir gece keşişe bir melek görünmüş, eline gemiden bir tahta vermiş: "Daha yukarı çıkma," demiş.',
      'Yukarıda, buzun içinde, tahtadan bir gövde uyuyor.',
      'Akori\'de derler ki Nuh gemiden inince ilk asmayı buraya dikmiş. Asmalar donmuş, kökleri hâlâ sıcak.',
      'Aziz Hakob\'un manastırı. Çanı rüzgârda inler; yanından koşarsan çalar ve Kandilciler sese gelir.',
    ],
    whispersEn: [
      'A monk once set out for the summit. Every morning he woke again at the mountain\'s foot.',
      'The wind pushes your wings back. Here a rope is more faithful than wings.',
      'The shepherds left their flocks behind. When the Lamplighters come, even the lambs fall silent.',
      'One night an angel came to the monk and put a plank of the Ark in his hand: "Climb no higher," it said.',
      'Up above, inside the ice, a body made of wood is sleeping.',
      'In Akori they say Noah, stepping from the Ark, planted the first vine here. The vines are frozen; their roots are still warm.',
      'The monastery of Saint Hakob. Its bell moans in the wind; run past it and it rings, and the Lamplighters come to its voice.',
    ],
    memories: [
      'Hatıra · Kışın ustam perdeye kar yağdırırdı: kandilin önüne un serperdi. Karı ilk orada gördüm.',
      'Hatıra · "Dağlar da yolcudur," derdi. "Yalnızca çok yavaş yürürler."',
      'Hatıra · Bir gece Nuh\'un gemisini oynattık. Hayvanları ikişer ikişer perdeye çıkardı; ben gölgelerini saydım.',
      'Hatıra · Ustam üzüm salkımı tasvirini hep sona saklardı. "Tufandan sonra ilk sevinç," derdi.',
      'Hatıra · Bir keşişin gölgesini perdeye çıkardığında sesini hep alçaltırdı. "Dua eden gölgeye saygı gerek," derdi.',
    ],
    memoriesEn: [
      'Memory · In winter my master made it snow on the screen: he sifted flour before the lamp. That was where I first saw snow.',
      'Memory · "Mountains are travelers too," he said. "They just walk very slowly."',
      'Memory · One night we played Noah\'s Ark. He brought the animals onto the screen two by two; I counted their shadows.',
      'Memory · My master always saved the bunch of grapes for the end. "The first joy after the Flood," he said.',
      'Memory · Whenever he brought a monk\'s shadow onto the screen, he lowered his voice. "A praying shadow deserves respect," he said.',
    ],
    map: kMapAgri,
  ),
  LevelDef(
    title: 'VI · NUH\'UN GEMİSİ',
    legends: ['nuh'],
    bard:
        'Ozan der ki: Su yükselir, gemi kalkar; ilk suyun anası da bunu bilir.',
    bardEn: 'The bard says: the water rises, the ark lifts; the mother of the first water knows this too.',
    cameos: [('akAna', 324, 25)],
    subtitle: 'Kırk gün kırk gece. Sonra bir dal, bir güvercin.',
    theme: LevelTheme.ark,
    wings: true,
    titleEn: 'VI · NOAH\'S ARK',
    subtitleEn: 'Forty days and forty nights. Then a branch, a dove.',
    place: 'Nuh\'un Gemisi · Ağrı Dağı, Ekim 1660',
    placeEn: 'Noah\'s Ark · Mount Ararat, October 1660',
    areas: [
      'Aslanların Ambarı',
      'Eşini Bekleyenler',
      'Kandillerin Ambarı',
      'Delikli Ambar',
      'Yalpalayan Ambar',
      'Ambar Kuyusu',
      'Güverte',
    ],
    areasEn: [
      'The Lions\' Hold',
      'Those Who Wait for Their Mates',
      'The Hold of Lamps',
      'The Leaking Hold',
      'The Rolling Hold',
      'The Hold Shaft',
      'The Deck',
    ],
    whispers: [
      'Bu gemi aylarca karanlık sularda sürüklendi. İçinde hiç sönmeyen bir ışık vardı.',
      'Her canlı eşiyle bindi. Eşini yitirenin gölgesi hâlâ onu bekliyor.',
      'Önce yolu aç, sonra yürüt. Sırayı şaşıran geri dönemez.',
      'Kandiller burada asılıydı. Kandilciler onları da toplamış.',
      'Su hatırlar. Bir kere yükseldi; bir daha yükselir.',
      'Güvercin buradan uçtu, ağzında bir zeytin dalıyla döndü. Hüdhüd onu tanıdı.',
      'Işık burada değil. Kandilciler onu güneşin doğduğu dağa, Nemrut\'a taşımış.',
      'Anadolu\'da anlatılır: tufanda gemiyi bir fare deldi, su doldu; yılan deliği kuyruğuyla tıkadı. Sen de bir sandıkla tıka; ardına sığın, suya doğru it.',
      'Gemi dalgada yalpalar; bağı kopmuş fıçılar ambarda bir o yana bir bu yana yuvarlanır. Yığınların üstünde bekle, fıçı geçince koş.',
    ],
    whispersEn: [
      'This ark drifted for months on dark waters. Inside it was a light that never went out.',
      'Every creature boarded with its mate. The shadow of one who lost its mate is still waiting.',
      'First open the way, then lead them on. Whoever confuses the order cannot turn back.',
      'The lamps hung here. The Lamplighters gathered them too.',
      'Water remembers. It rose once; it will rise again.',
      'The dove flew from here and came back with an olive branch in its beak. The Hoopoe knew it.',
      'The light is not here. The Lamplighters have carried it to the mountain where the sun rises: Nemrut.',
      'They tell it in Anatolia: in the Flood a mouse gnawed a hole in the ark and the water poured in; the snake plugged the hole with its tail. Plug it with a crate: hide behind it and push it toward the water.',
      'The ark rolls on the waves; barrels torn loose roll from side to side in the hold. Wait on top of the stacks, and run when a barrel has passed.',
    ],
    memories: [
      'Hatıra · Tufan sahnesinde ustam perdeyi yavaşça sallardı. "Su da bir gölgedir," derdi, "en büyüğü."',
      'Hatıra · Geminin tasvirini hiç bitirmedi. "Kimse onun tamamını görmedi," derdi.',
      'Hatıra · "Işığı saklamak için kandil gerekmez," demişti bir gece. "Bir kalp yeter."',
    ],
    memoriesEn: [
      'Memory · In the Flood scene my master gently rocked the screen. "Water is a shadow too," he said, "the greatest one."',
      'Memory · He never finished the figure of the Ark. "No one has ever seen it whole," he said.',
      'Memory · "You do not need a lamp to keep a light," he said one night. "A heart is enough."',
    ],
    map: kMapGemi,
    // Aslan, fil, zürafa eşlerinin gölgelerine; terazide iki geyik (fil tuzak).
    animalKinds: [0, 1, 2, 3, 1, 3],
    shadowKinds: [0, 1, 2, 3, 3],
    leaks: [(191, 26), (209, 26), (225, 26)],
    barrels: [
      (263, 274, 26, 0),
      (278, 289, 26, 1.6),
      (293, 304, 26, 3.2),
      (308, 314, 26, 0.8),
    ],
  ),
  LevelDef(
    title: 'VII · NEMRUT',
    legends: ['nemrut'],
    bard: 'Ozan der ki: Tanrılarla oturmak isteyen kralın başı, taşın dibinde yatar.',
    bardEn: 'The bard says: the king who would sit with gods lies with his head at the foot of the stone.',
    subtitle: 'Tanrılarla yan yana oturmak isteyen bir kralın dağı.',
    theme: LevelTheme.nemrut,
    wings: true,
    headwind: 80,
    storm: true,
    quakes: true,
    titleEn: 'VII · NEMRUT',
    subtitleEn: 'The mountain of a king who wished to sit beside the gods.',
    place: 'Nemrut Dağı · Kâhta, Kasım 1660',
    placeEn: 'Mount Nemrut · Kahta, November 1660',
    areas: [
      'Bilinmeyen Dağ',
      'Batı Terası',
      'Deprem Yarığı',
      'Kartalın Gözü',
      'Tümülüs',
      'Doğuya Geçit',
    ],
    areasEn: [
      'The Unknown Mountain',
      'The West Terrace',
      'The Earthquake Rift',
      'The Eagle\'s Eye',
      'The Tumulus',
      'The Pass to the East',
    ],
    whispers: [
      'Bu dağı bugün kimse bilmiyor. Bir kartallar biliyor, bir de kar.',
      'Kral Antiochos tanrılarla yan yana oturmak için dağın tepesine taş tanrılar dikti.',
      'Tahtların ardına vasiyetini kazıttı: iki yüz otuz yedi satır. Taşa yazılan söz unutulmaz sandı.',
      'Depremler tanrıların başlarını yere indirdi. Dağ kibri hiç sevmez.',
      'Başlar hâlâ güneşin doğduğu yere bakar. Gözlerinin önünde saklanabilirsin.',
      'Halk bu dağa Nemrut der: göğe ok atıp Tanrı\'yla savaşmaya kalkan kralın adıyla.',
      'Tümülüsün altında bir kral uyur. Taşlarını oynatma; uyanmasın.',
      'Kandilciler ışığı doğu terasına taşıyor. Güneş doğunca yakacaklar.',
    ],
    whispersEn: [
      'No one knows this mountain today. Only the eagles know it, and the snow.',
      'King Antiochos raised stone gods on the summit so he could sit beside them.',
      'Behind the thrones he had his testament carved: two hundred and thirty-seven lines. He thought words cut in stone are never forgotten.',
      'Earthquakes brought the gods\' heads down to the ground. The mountain has never liked pride.',
      'The heads still face the rising sun. You can hide right before their eyes.',
      'The people call this mountain Nemrut, after the king who shot arrows at the sky to make war on God.',
      'Beneath the tumulus a king is sleeping. Do not shift its stones; let him not wake.',
      'The Lamplighters are carrying the light to the eastern terrace. They will kindle it when the sun rises.',
    ],
    memories: [
      'Hatıra · Ustam taş tasvirleri sevmezdi. "Gölge kımıldar," derdi, "taş kımıldamaz; o yüzden ölüdür."',
      'Hatıra · Bir gece bana yıldızları gösterdi: "Her biri bir kandil. Kimse onları toplayamaz."',
      'Hatıra · Nemrud\'un hikâyesini anlatırken hep gülerdi: "Koca kralı bir sivrisinek yendi. Küçük olan büyüğü hep şaşırtır."',
    ],
    memoriesEn: [
      'Memory · My master did not like stone figures. "A shadow moves," he said. "Stone does not; that is why it is dead."',
      'Memory · One night he showed me the stars: "Each one is a lamp. No one can gather them."',
      'Memory · Whenever he told the tale of Nemrud, he laughed: "The great king was beaten by a gnat. The small always surprise the great."',
    ],
    map: kMapNemrut,
    surprises: [('tasBekci', 26, 19)],
  ),
  LevelDef(
    title: 'VIII · GÜN DOĞUMU',
    bard: 'Ozan der ki: Gün doğar, dev uyanır; aslanlar arasında büyüyen yiğit korkmaz.',
    bardEn: 'The bard says: the sun rises, the giant wakes; the hero raised among lions is not afraid.',
    cameos: [('basat', 0, 0)],
    subtitle: 'Güneş doğarken taşlar da gölge düşürür.',
    theme: LevelTheme.nemrut,
    variant: 1,
    wings: true,
    quakes: true,
    titleEn: 'VIII · SUNRISE',
    subtitleEn: 'At sunrise even stones cast shadows.',
    place: 'Nemrut Dağı, Doğu Terası · Kasım 1660',
    placeEn: 'Mount Nemrut, the East Terrace · November 1660',
    areas: [
      'Tören Yolu',
      'Terasın Kapısı',
      'Doğu Terası',
      'Şafağın Gölgeleri',
      'Düşmüş Başlar',
      'Güneşin Doğduğu Yer',
    ],
    areasEn: [
      'The Processional Way',
      'The Terrace Gate',
      'The East Terrace',
      'The Shadows of Dawn',
      'The Fallen Heads',
      'Where the Sun Rises',
    ],
    whispers: [
      'Doğu terası. Kral burada tanrılarla el sıkışırken kazıttı kendini.',
      'Kandilcilerin fenerleri şafakta soluklaşır. Güneşten korkarlar.',
      'Tanrının omzundaki kolu çek. Kapı taşın sözünü dinler.',
      'Kandilciler taşa can vermiş: Nemrud gibi göğe başkaldıran bir dev.',
      'Nemrud\'u bir sivrisinek yendi; başına yıllarca tokmak indi. Taş devi de üç küçük ışık yıkar: kulağına üç kez bırak.',
      'Işık orada, güneşin doğduğu yerde. Sâye, ona dokun.',
      'Şafak. Tanrıların gölgeleri batıya uzanır; Kandilciler yalnız gölgede yürür, güneşe adım atmazlar. Güneş yükseldikçe gölge kısalır: sabret.',
      'Deprem dev başları yuvarlamış. Kartalın tepesindeki kol son kapıyı açar.',
    ],
    whispersEn: [
      'The eastern terrace. Here the king had himself carved shaking hands with the gods.',
      'At dawn the Lamplighters\' lanterns grow pale. They fear the sun.',
      'Pull the lever on the god\'s shoulder. The gate listens to the stone.',
      'The Lamplighters have breathed life into stone: a giant who rebels against the sky, like Nemrud.',
      'Nemrud was beaten by a gnat; for years a mallet struck his head. Three small lights will fell the stone giant too: leave one at his ear three times.',
      'The light is there, where the sun rises. Saye, touch it.',
      'Dawn. The shadows of the gods stretch west; the Lamplighters walk only in shadow and never step into the sun. As the sun climbs the shadows shorten: be patient.',
      'The earthquake has rolled the giant heads. The lever atop the eagle opens the last gate.',
    ],
    memories: [
      'Hatıra · Ustam el sıkışan iki tasviri hep yan yana koyardı. "Gölgeler de barışır," derdi.',
      'Hatıra · Bir deprem gecesi ustam perdeye yıkık başları çıkardı. "Baş yere düşer, Sâye," dedi. "Bakış göğe kalır."',
      'Hatıra · Güneş doğarken perdeyi indirirdik. "Artık gölge oyunu yok," derdi. "Şimdi asıl oyun başlıyor."',
    ],
    memoriesEn: [
      'Memory · My master always set two figures shaking hands side by side. "Shadows make peace too," he said.',
      'Memory · One night of earthquakes my master brought fallen heads onto the screen. "The head falls to the ground, Saye," he said. "The gaze stays with the sky."',
      'Memory · At sunrise we took down the screen. "No more shadow play," he said. "Now the real play begins."',
    ],
    map: kMapGunDogumu,
    vistas: [(330, 13, 'sunrise')],
    dawn: (126, 191),
  ),
  LevelDef(
    title: 'IX · KAR YOLU',
    bard:
        'Ozan der ki: Kervanın palanı yolda kalır; gök yeleli kurt yolu bilir.',
    bardEn: "The bard says: the caravan's saddles are left on the road; the sky-maned wolf knows the way.",
    pawTrails: [(133, 190, 19)],
    gokboruGuard: true,
    gokboruHelp: true,
    gokboruLead: 131,
    subtitle: 'Palanlarını döken kervanların yolu.',
    theme: LevelTheme.snow,
    variant: 1,
    wings: true,
    storm: true,
    headwind: 120,
    titleEn: 'IX · THE SNOW ROAD',
    subtitleEn: 'The road where caravans lost their saddles.',
    place: 'Palandöken\'in Eteği · Erzurum, Aralık 1660',
    placeEn: 'The Foot of Palandöken · Erzurum, December 1660',
    areas: [
      'Kervan Yolu',
      'Kurtların Ormanı',
      'Donmuş Göl',
      'Terk Edilmiş Han',
      'Ejder\'in Eteği',
    ],
    areasEn: [
      'The Caravan Road',
      'The Wolves\' Forest',
      'The Frozen Lake',
      'The Abandoned Inn',
      'The Foot of the Dragon',
    ],
    whispers: [
      'Bu dağa Palandöken derler: yokuşları öyle diktir ki kervanların palanları kayıp düşermiş.',
      'Evliya Çelebi anlatır: Erzurum\'da kış öyle sert gelir ki damdan dama atlayan kedi havada donar.',
      'Kurtlar seni gözle değil, kokuyla bulur. Saklanmak yetmez; yüksel ya da ışığını göster.',
      'Ağaçlar kurtların ulaşamadığı yerdir. Daldan dala, kardan uzak.',
      'Göl ince buzla örtülü. Hafif olan geçer, ağır olan düşer.',
      'Kervanlar burada geceyi geçirirdi. Şimdi hanın ocağı Kandilcilerin fenerleriyle yanıyor.',
      'Yukarıda iki tepe var: Büyük Ejder ve Küçük Ejder. Derler ki kışın zirvelerde ejderler uyur.',
      'Dağdan inmenin tek yolu kaymak. Rüzgâra değil, kara güven.',
    ],
    whispersEn: [
      'They call this mountain Palandöken: its slopes are so steep that the caravans\' pack saddles slipped off and fell.',
      'Evliya Celebi tells that winter in Erzurum is so harsh a cat leaping from roof to roof freezes in mid-air.',
      'Wolves find you not by sight but by scent. Hiding is not enough; climb high, or show them your light.',
      'Trees are where the wolves cannot reach. Branch to branch, away from the snow.',
      'The lake is sheathed in thin ice. The light cross over; the heavy fall through.',
      'Caravans once spent the night here. Now the inn\'s hearth burns with the Lamplighters\' lanterns.',
      'Above are two peaks: the Great Dragon and the Little Dragon. They say dragons sleep on the summits in winter.',
      'The only way down the mountain is to slide. Trust the snow, not the wind.',
    ],
    memories: [
      'Hatıra · Kışın ustam kervan tasvirlerini oynatırdı. Develerin boynundaki çanları ağzıyla çalardı.',
      'Hatıra · Bir gece kurt tasviri yapmıştı, korkup ağladım. Kurdu kırdı, bana bir kuzu yaptı.',
      'Hatıra · "Han yolcunun kalbidir," derdi. "Ocağı sönmüş hana, kapısı açık olsa da kimse girmez."',
    ],
    memoriesEn: [
      'Memory · In winter my master played the caravan figures. He made the bells on the camels\' necks ring with his own voice.',
      'Memory · One night he made a wolf figure and I cried in fear. He broke the wolf and made me a lamb.',
      'Memory · "An inn is the traveler\'s heart," he said. "No one enters an inn whose hearth is cold, even if the door is open."',
    ],
    map: kMapKarYolu,
  ),
  LevelDef(
    title: 'X · PALANDÖKEN',
    gokboruRun: true,
    legends: ['ejder'],
    bard: 'Ozan der ki: Dağdan inen rüzgârı geçemezsin; rüzgârla inersin.',
    bardEn: 'The bard says: you cannot outrun the wind from the mountain; you ride down with it.',
    subtitle: 'Ejderlerin uyuduğu dağdan aşağı.',
    theme: LevelTheme.snow,
    variant: 1,
    skiSurface: kSkiPalandoken,
    skiMarks: kSkiMarksPalandoken,
    skiDecor: kSkiDecorPalandoken,
    magnet: kSkiPalandokenMagnet,
    titleEn: 'X · PALANDÖKEN',
    subtitleEn: 'Down from the mountain where the dragons sleep.',
    place: 'Palandöken Dağı · Erzurum, Aralık 1660',
    placeEn: 'Mount Palandöken · Erzurum, December 1660',
    areas: [
      'Çoban Kulübesi',
      'Ejder\'in Sırtı',
      'Kandil Balonları',
      'Manyetik Tepe',
      'Ejder\'in Sıçrayışı',
      'Erzurum\'a İniş',
    ],
    areasEn: [
      'The Shepherd\'s Hut',
      'The Dragon\'s Back',
      'The Lantern Balloons',
      'The Magnetic Hill',
      'The Dragon\'s Leap',
      'The Descent to Erzurum',
    ],
    whispers: [
      'Bu dağa Palandöken derler. Yokuşları öyle dikmiş ki kervanların sırtındaki palanlar kayıp dökülürmüş; adı da oradan kalmış.',
      'Kar seni taşımak ister. Sırtından havalan, dönerek in; ayakların yere doğru gelsin.',
      'İki zirvenin adı Büyük Ejder ile Küçük Ejder. Eski inanışta dağların doruğu kutsaldır, dağın da bir iyesi vardır. Ozan der ki bu doruklarda iki ejder uyur: fırtına onların nefesi, sis onların uykusudur.',
      'Kandilciler fenerlerini balonlara asmış, yamacı tarıyor. Işıklarında oyalanma; hız, gölgenin kalkanıdır.',
      'Burada kar yokuş yukarı akar. Çobanlar bunun bir göz aldanması mı, yoksa dağın seni geri çağırması mı olduğunu hiç bilememiş.',
      'Dağ çağırırsa direnme. Seni sırtına kadar taşır; oradan uçarsın.',
      'Ejder\'in Sıçrayışı. Buradan atlayan rüzgârın kanadına biner. Korkan düşer, inanan uçar.',
      'Aşağıda Erzurum\'un kandilleri titriyor. Dağın sırtında bir gürültü uyanıyor.',
    ],
    whispersEn: [
      'They call this mountain Palandöken. Its slopes were so steep that the pack saddles slid off the caravans\' backs and fell, and so it got its name.',
      'The snow wants to carry you. Lift off its ridges, land turning; let your feet come down to the ground.',
      'The two summits are the Great Dragon and the Little Dragon. In the old belief mountaintops are sacred, and every mountain has its iye, its spirit. The bard says two dragons sleep on these peaks: the storm is their breath, the fog their sleep.',
      'The Lamplighters have hung their lanterns on balloons and sweep the slope. Do not linger in their light; speed is a shadow\'s shield.',
      'Here the snow flows uphill. The shepherds never knew whether it was a trick of the eye or the mountain calling you back.',
      'If the mountain calls, do not resist. It carries you up to its crest; from there you fly.',
      'The Dragon\'s Leap. Whoever jumps from here rides the wing of the wind. Those who fear fall; those who believe fly.',
      'Below, the lamps of Erzurum flicker. On the mountain\'s back, a rumbling wakes.',
    ],
    memories: [
      'Hatıra · Bir kış ustam bana tahtadan bir kızak yaptı. "Kaymayı bilen düşmeyi de bilir," dedi. Düşe kalka öğrendim.',
      'Hatıra · Perdeye bir ejder çizmişti; ağzından ateş değil, kar çıkıyordu. "Her ejder ateş püskürmez," dedi.',
    ],
    memoriesEn: [
      'Memory · One winter my master made me a wooden sled. "Whoever knows how to slide knows how to fall," he said. I learned by falling.',
      'Memory · He once drew a dragon on the screen that breathed snow, not fire. "Not every dragon breathes fire," he said.',
    ],
    map: kMapPalandoken,
  ),
  LevelDef(
    title: 'XI · ÇIĞ',
    gokboruRun: true,
    bard: 'Ozan der ki: Ak dağ yürür, yer titrer; koşan, önündeki ışığa bakar.',
    bardEn: 'The bard says: the white mountain walks, the earth shakes; the runner looks to the light ahead.',
    subtitle: 'Ejder uyandı. Beyaz bir nefes peşinde.',
    theme: LevelTheme.snow,
    variant: 2,
    skiSurface: kSkiCig,
    skiMarks: kSkiMarksCig,
    skiDecor: kSkiDecorCig,
    titleEn: 'XI · THE AVALANCHE',
    subtitleEn: 'The dragon has woken. A white breath at your heels.',
    place: 'Küçük Ejder Yamacı · Erzurum, Aralık 1660',
    placeEn: 'The Slopes of the Little Dragon · Erzurum, December 1660',
    areas: [
      'Ejder Uyanıyor',
      'Beyaz Nefes',
      'Kırık Sırt',
      'Son Atlayış',
      'Sığınak',
    ],
    areasEn: [
      'The Dragon Wakes',
      'The White Breath',
      'The Broken Ridge',
      'The Last Leap',
      'The Shelter',
    ],
    whispers: [
      'Derler ki Küçük Ejder uyurken dağ susar; uyanınca kar akar. Bu gece Kandilcilerin fenerleri onu uyandırdı.',
      'Çığdan kaçılmaz, onunla yarışılır. Yavaşlayan kar olur.',
      'Ozan anlatır: bir kervan bir gece çığa yakalanmış. Baharda karlar eriyince develeri ayakta, donmuş bulmuşlar; boyunlarındaki çanlar rüzgârda hâlâ çalıyormuş.',
      'Kırık sırt. Kayalar çığdan önce düşer; gözünü yoldan ayırma.',
      'Son atlayış. Ejderin nefesi sırtında: ya uçarsın, ya kar olursun.',
      'Çığ dağın dibinde durdu, Ejder yeniden uykuya daldı. Batıda, peri bacalarının ülkesinde bir kandil yanıp sönüyor.',
    ],
    whispersEn: [
      'They say when the Little Dragon sleeps, the mountain is silent; when it wakes, the snow flows. Tonight the Lamplighters\' lanterns woke it.',
      'There is no fleeing an avalanche, only racing it. Whoever slows becomes snow.',
      'The bard tells of a caravan caught by an avalanche one night. When the snow melted in spring, they found the camels standing, frozen; the bells on their necks still rang in the wind.',
      'The broken ridge. The rocks fall before the snow; keep your eyes on the path.',
      'The last leap. The dragon\'s breath at your back: you fly, or you become snow.',
      'The avalanche stopped at the mountain\'s foot, and the dragon sank back into sleep. In the west, in the land of the fairy chimneys, a lamp flickers.',
    ],
    memories: [
      'Hatıra · Bir kış ustam perdeyi titreterek çığ yapmıştı. Sonra kandili kıstı: "Dağ da yorulur," dedi.',
      'Hatıra · "Korkudan kaçılmaz," derdi, "korkuyla birlikte koşulur. Bir gün önüne geçersin."',
    ],
    memoriesEn: [
      'Memory · One winter my master made an avalanche by shaking the screen. Then he dimmed the lamp: "Mountains get tired too," he said.',
      'Memory · "You cannot flee fear," he said. "You run alongside it. One day you get ahead of it."',
    ],
    map: kMapCig,
  ),
  LevelDef(
    title: 'XII · PERİ BACALARI',
    bard: 'Ozan der ki: Peri bacası gölgede uzar; kızıl gölge ışığını ister, demirden korkar.',
    bardEn: 'The bard says: the fairy chimneys stretch in shadow; the red shade wants your light and fears iron.',
    cameos: [('albasti', 207, 25)],
    subtitle: 'İnsanlar aşağıda, periler yukarıda yaşardı.',
    theme: LevelTheme.peri,
    wings: true,
    titleEn: 'XII · THE FAIRY CHIMNEYS',
    subtitleEn: 'People lived below, fairies above.',
    place: 'Muşkara (bugünkü Nevşehir) · Kapadokya, Aralık 1660',
    placeEn: 'Muşkara (today\'s Nevşehir) · Cappadocia, December 1660',
    areas: [
      'Muşkara',
      'Peri Bacaları',
      'Güvercinlik Vadisi',
      'Kaya Kilisesi',
      'Perilerin Dansı',
      'Uçhisar',
    ],
    areasEn: [
      'Muşkara',
      'The Fairy Chimneys',
      'Pigeon Valley',
      'The Rock Church',
      'The Dance of the Fairies',
      'Uçhisar',
    ],
    whispers: [
      'Eskiler bu ülkeye Katpatuka derdi; kimi "güzel atlar ülkesi" der. Ama atlardan önce burada periler vardı.',
      'Bir zamanlar başları dağlara değen devler varmış. İnsanları ateş dalgalarıyla cezalandırırlarmış; Erciyes\'in, Hasan Dağı\'nın ağzından alevler akarmış.',
      'Peri Padişahı buna dayanamamış. Binlerce periyi toplamış; ellerinde kar ve buz, devlerin ateşli dağına yürümüşler.',
      'Ateş sönmüş, devler yeraltına sürülmüş. Küllerden bu bacalar yükselmiş. O günden beri insanlar bacaların dibinde, periler tepesinde yaşar.',
      'Güvercinlik Vadisi. Bağlar güvercinlerin bıraktığıyla yeşerir; bu yüzden onlara kayalara ev oyulmuştur. Ürkütürsen bütün vadi duyar.',
      'Anadolu\'da derler ki her insanla birlikte bir peri eşi doğar: hemzat. Sevdiğini sever, nefret ettiğinden nefret eder. Sâye, senin hemzatın kim?',
      'Bu kilise kayanın içine oyulmuş. Duvardaki tasvirlerin gözleri kazınmış: kimi bakışlarından korkulmuş der, kimi kazınan boyayı şifa diye içmişler der.',
      'Ay doğunca tepelerde ışıklar dolaşır. Çobanlar onlara peri halkası der; üstüne basan göğe çıkar, inip inmeyeceğini kimse bilmez.',
      'Uçhisar\'ın tepesinden bütün vadi görünür. Kandilciler yerin altına indi: Derinkuyu\'ya, devlerin sürüldüğü yere.',
    ],
    whispersEn: [
      'The ancients called this land Katpatuka; some say it means "the land of beautiful horses". But before the horses, there were fairies.',
      'Once there were giants whose heads touched the mountains. They punished people with waves of fire; flames poured from the mouths of Erciyes and Hasan Dağı.',
      'The Fairy King could not bear it. He gathered thousands of fairies, and with snow and ice in their hands they marched on the giants\' burning mountain.',
      'The fire died, and the giants were driven underground. From the ashes these chimneys rose. Ever since, people live at the foot of the chimneys, and fairies at the top.',
      'Pigeon Valley. The vineyards grow green from what the pigeons leave, so homes were carved for them in the rocks. Startle them, and the whole valley hears.',
      'In Anatolia they say a fairy twin is born with every person: the hemzat. It loves whom you love and hates whom you hate. Saye, who is your hemzat?',
      'This church was carved inside the rock. The eyes of the figures on the walls have been scraped away: some say people feared their gaze, others that they drank the scraped paint as a cure.',
      'When the moon rises, lights wander on the summits. Shepherds call them fairy rings; whoever steps on one rises to the sky, and no one knows if they come down again.',
      'From the summit of Uçhisar the whole valley lies open. The Lamplighters have gone down beneath the earth: to Derinkuyu, where the giants were driven.',
    ],
    memories: [
      'Hatıra · Ustam perdeye peri çizmezdi. "Periler gölge bırakmaz," derdi, "o yüzden onları perdede göremezsin."',
      'Hatıra · Bir gece en yüksek tepeye çıktık. "Buradan bakınca dünya da bir perde," dedi. "Biz arkasındayız."',
      'Hatıra · Kandilini yakarken hep bir dua mırıldanırdı. Bir gün sordum, güldü: "Işığa teşekkür ediyorum."',
      'Hatıra · "Bir gün gideceğim," demişti. "O gün ağlama. Gölge ışığa kavuşunca ağlanmaz."',
    ],
    memoriesEn: [
      'Memory · My master never drew fairies on the screen. "Fairies leave no shadow," he said, "so you can never see them on a screen."',
      'Memory · One night we climbed the highest peak. "From up here the world is a screen too," he said. "And we are behind it."',
      'Memory · Whenever he lit his lamp he murmured a prayer. One day I asked; he laughed: "I am thanking the light."',
      'Memory · "One day I will go," he said. "Do not cry that day. No one weeps when a shadow reaches the light."',
    ],
    map: kMapPeri,
  ),
  LevelDef(
    title: 'XIII · DERİNKUYU',
    legends: ['derinkuyu'],
    bard: 'Ozan der ki: Yerin altı kat kattır; en dipte bir ses seni adınla çağırır.',
    bardEn: 'The bard says: the underworld lies layer upon layer; at the bottom a voice calls you by name.',
    cameos: [('erlik', 266, 43)],
    pawTrails: [(262, 318, 43)],
    gokboruHelp: true,
    subtitle: 'Yerin altında, unutulmuş bir şehir.',
    theme: LevelTheme.cave,
    wings: true,
    titleEn: 'XIII · DERİNKUYU',
    subtitleEn: 'Beneath the earth, a forgotten city.',
    place: 'Derinkuyu · Kapadokya, Aralık 1660',
    placeEn: 'Derinkuyu · Cappadocia, December 1660',
    areas: [
      'Mahzen',
      'Şapel',
      'Havalandırma Bacası',
      'Derin Kuyu',
      'Devlerin Kapısı',
      'Yukarıya',
    ],
    areasEn: [
      'The Cellar',
      'The Chapel',
      'The Air Shaft',
      'The Deep Well',
      'The Giants\' Gate',
      'Upward',
    ],
    whispers: [
      'Yerin altında bir şehir var; ne zaman kazıldığını kimse bilmez. Kimi Friglere der, kimi daha eskilere. Bugün kimse onu hatırlamıyor.',
      'Kapıları yuvarlak taşlardır; yalnızca içeriden açılıp kapanır. Dışarıdaki bekler, içerideki yaşar.',
      'Alçak geçitler bilerek alçak oyulmuş: düşman eğilmek zorunda kalsın. Kandilciler eğilmeyi sevmez.',
      'Bir yuvarlak taş yalnız bir kapıyı kapatmaz. Bazen, yükseğe çıkmak isteyene basamak olur.',
      'Bacalar şehri nefes aldırır. Aşağıdan sıcak bir rüzgâr eser; derler ki devlerin nefesidir.',
      'Kuyunun suyu en dipten gelir. Dipteki vanayı çeviren, suyu yukarı çağırır.',
      'Peri Padişahı devleri yeraltına sürmüştü. Derinkuyu\'nun en dibinde hâlâ uyurlar; uykuları ışığı yer. Ateşböceklerini sakla, onlar senin nefesin.',
      'Kuyunun en dibinde taşın arasından kökler sarkıyor. Yukarıdan reçine ve yaprak kokusu geliyor; bu kokuyu hiç bilmiyordun.',
    ],
    whispersEn: [
      'There is a city beneath the earth; no one knows when it was dug. Some say the Phrygians, some say older still. Today no one remembers it.',
      'Its doors are round stones, opened and closed only from within. Whoever is outside waits; whoever is inside lives.',
      'The low passages were made low on purpose, so that an enemy would have to bow. The Lamplighters do not like to bow.',
      'A round stone does not only close a door. Sometimes it becomes a step for whoever wants to climb.',
      'The shafts let the city breathe. A warm wind rises from below; they say it is the giants\' breath.',
      'The well\'s water comes from the very bottom. Whoever turns the valve below calls the water up.',
      'The Fairy King drove the giants underground. At the very bottom of Derinkuyu they sleep still, and their sleep devours light. Guard your fireflies; they are your breath.',
      'At the very bottom of the well, roots hang between the stones. From above comes a smell of resin and leaves, a smell you have never known.',
    ],
    memories: [
      'Hatıra · Ustam bir gece yerin altında bir şehir olduğunu anlattı. İnanmadım. "İnanmadığın her yer," dedi, "bir gün seni bekler."',
      'Hatıra · Korktuğumda kandili bana uzatırdı: "Tut. Işığı tutan korkmaz; korksa da yürür."',
      'Hatıra · "Gölge en çok karanlıkta kaybolur," derdi, "ama en çok da orada aranır."',
      'Hatıra · Ustam hiç sormadığım bir soruya cevap vermişti bir gece: "Sen benim gölgem değilsin, Sâye. Sen benim duamsın."',
    ],
    memoriesEn: [
      'Memory · One night my master told me there was a city beneath the earth. I did not believe him. "Every place you do not believe in," he said, "waits for you one day."',
      'Memory · When I was afraid he would hand me the lamp: "Hold it. Whoever holds the light is not afraid; or if afraid, still walks."',
      'Memory · "A shadow is most lost in the dark," he said, "but it is there that it is most sought."',
      'Memory · One night my master answered a question I had never asked: "You are not my shadow, Saye. You are my prayer."',
    ],
    map: kMapDerinkuyu,
    // İki Kandilcinin koridoru: gölge önden gider, onlar ona bakarken geçilir.
    shadowStones: [(206, 23)],
  ),
  LevelDef(
    title: 'XX · ŞEB-İ ARÛS',
    legends: ['sebiArus'],
    bard: 'Ozan der ki: Dönen döner, gölge düşer; kim dönerse yolunu bulur.',
    bardEn: 'The bard says: the whirling turn, the shadows fall; whoever turns finds the way.',
    gokboruGuard: true,
    subtitle: 'Bu gece ölüm bir düğündür.',
    theme: LevelTheme.konya,
    wings: true,
    titleEn: 'XX · SHEB-I ARUS',
    subtitleEn: 'Tonight, death is a wedding.',
    place: 'Konya · Şubat 1661, Şeb-i Arûs gecesi',
    placeEn: 'Konya · February 1661, the night of Sheb-i Arus',
    areas: [
      'Konya Ovası',
      'Eski Höyük',
      'İkonion Kapısı',
      'Alâeddin Tepesi',
      'Karatay Medresesi',
      'İnce Minare',
      'Şems\'in Kuyusu',
      'Dergâh Avlusu',
      'Semâhane',
      'Kubbe-i Hadrâ',
    ],
    areasEn: [
      'The Konya Plain',
      'The Old Mound',
      'The Gate of Iconium',
      'Alaeddin Hill',
      'Karatay Madrasa',
      'The Slender Minaret',
      'The Well of Shams',
      'The Dervish Courtyard',
      'The Semahane',
      'The Green Dome',
    ],
    whispers: [
      'Konya Ovası. Rivayet ederler ki Horasan\'dan iki derviş kanatlanıp batıya uçmuş. Bu ovanın üstüne gelince biri sormuş: "Konayım mı?" Öteki demiş ki: "Kon ya!" Şehrin adı o günden kalmış.',
      'Bu höyüğün altında dünyanın en eski şehirlerinden biri uyur. Evlerinin kapısı yoktu: damdan, merdivenle inilirdi. Ölülerini evlerinin tabanına gömerlerdi; ölüyle diri aynı damın altında yaşardı.',
      'Duvarda boğa boynuzları. Köşede bir ana tanrıça: iki yanında iki pars, tahtında oturur. Doğurur, besler, sonra geri alır. Bu ova dokuz bin yıldır aynı ninniyi söyler.',
      'Tufandan önce burada Nannakos adında bir kral yaşarmış. Kâhinler, o ölünce bütün insanların öleceğini söylemiş. Nannakos halkıyla öyle ağlamış ki "Nannakos gibi ağlamak" sözü dilden dile geçmiş. Üç yüz yaşında ölmüş; ardından tufan gelmiş. Ama tufandan sonra çamurdan suretler doğdu.',
      'Bir başka rivayete göre Perseus, Medusa\'nın başını kesip buraya getirmiş ve şehri o başın sureti üstüne kurmuş. Yerebatan\'daki başları hatırla: bakışı taşa çevirir. Perde der ki cilalı bir kalkanda kendi bakışıyla karşılaşırsa kendisi taşa döner.',
      'Eskiler bu şehre İkonion derdi. Frigler derdi ki tufandan sonra bu ovada tek bir can kalmamış. Prometheus ile Athena çamurdan suretler yoğurmuş, rüzgâr onlara can üflemiş. Şehrin adı o suretlerden kalmış: ikon, suret demektir. Sen de bir suretsin, Sâye.',
      'Alâeddin Tepesi. Selçuklu sultanları burada otururdu; Konya Anadolu Selçuklularının başkentiydi. Köşklerinin çinilerinde kanatlı insanlar, çift başlı kartallar, ay yüzlü saraylılar vardı. Şimdi kalıntılarında Kandilciler nöbet tutuyor.',
      'Belh\'ten bir âlim ailesini alıp yola çıkmış. Rivayete göre Nişabur\'da yaşlı bir şaire uğramışlar: Attâr\'a, kuşların Simurg\'a yolculuğunu yazan şaire. Attâr çocuğa bir kitap vermiş, babasına dönüp "Bu çocuk yakında âlemin yüreğine ateş düşürecek," demiş. Çocuk Celâleddin\'di. Konya ona Mevlânâ dedi: efendimiz.',
      'Karatay Medresesi. Kubbesinin çinileri gece göğünü taklit eder. Tepedeki açıklıktan inen ay ortadaki havuza düşermiş; talebeler gökyüzünü yerde, suyun içinde okurmuş. Ay ışığını kilide ulaştır.',
      'İnce Minare. Kandilciler şerefeye büyük fenerlerini asmış, damları tarıyorlar. Huzme kubbede, bacada, revakta kesilir. Gölgede bekle; ışık geçince koş.',
      'Bir gün Konya\'ya yırtık hırkalı bir derviş geldi: Tebrizli Şems. Mevlânâ onu görünce kitaplarını bıraktı. Şems, güneş demektir. Konyalılar onu kıskandı. Bir gece Şems kayboldu: kimi Tebriz\'e döndü der, kimi öldürülüp bu kuyuya atıldı der. Mevlânâ onu Şam\'a kadar aradı, bulamadı. Sonunda şöyle dedi: "Aradığımı kendimde buldum."',
      'Derler ki güneşini kaybeden adam bir direğin çevresinde dönmeye başladı; semâ böyle doğdu: arayanın dönüşü. Bu gece Şeb-i Arûs: Mevlânâ\'nın vefat gecesi. O, ölümüne düğün derdi. Sikke nefsin mezar taşıdır, tennure kefeni. Sağ el göğe açılır, sol el yere döner: Hak\'tan alır, halka verir. Önden geçen semâzenin eteğinde saklan.',
      'Semâhane. Neyzen ilk nefesini üflüyor. Ney kamışlıktan koparıldığından beri inler; kesildiği yeri özler, dinleyen herkes kendi ayrılığını duyar. Gölge de perdesini özler, Sâye. Avizeler dönüyor: semâzenler gibi, gezegenler gibi.',
      'Kubbe-i Hadrâ: Yeşil Kubbe, Mevlânâ\'nın türbesi. Kandilciler ustayı en tepeye çıkardı; yüzyıllardır topladıkları bütün ışık orada. Ustanın kandili sönmek üzere ve biriktirilen ışık taşıyor. Tırman, Sâye!',
    ],
    whispersEn: [
      'The Konya Plain. They say two dervishes once took wing from Khorasan and flew west. Over this plain, one asked: "Shall I land?" The other said: "Kon ya! Land!" The city has kept the name ever since.',
      'Beneath this mound sleeps one of the oldest cities in the world. Its houses had no doors: you went down through the roof, by ladder. They buried their dead under the floors of their homes; the living and the dead slept under one roof.',
      'Bull horns on the wall. In the corner, a mother goddess on her throne, a leopard at either side. She gives birth, she feeds, and then she takes back. This plain has sung the same lullaby for nine thousand years.',
      'Before the Flood a king named Nannakos lived here. The oracles said that when he died, all people would die. Nannakos wept with his people so bitterly that "to weep like Nannakos" passed from tongue to tongue. He died at three hundred; then the Flood came. But after the Flood, images of mud were born.',
      'Another tale says Perseus cut off Medusa\'s head, brought it here, and founded the city upon its image. Remember the heads in the cistern: their gaze turns all to stone. The screen says that if it meets its own gaze in a polished shield, it turns to stone itself.',
      'The ancients called this city Iconium. The Phrygians said that after the Flood not a single soul was left on this plain. Prometheus and Athena kneaded images out of mud, and the wind breathed life into them. The city is named for those images: eikon means image. You are an image too, Saye.',
      'Alaeddin Hill. The Seljuk sultans sat here; Konya was the capital of the Anatolian Seljuks. The tiles of their pavilions showed winged people, double-headed eagles, moon-faced courtiers. Now the Lamplighters keep watch among the ruins.',
      'A scholar of Balkh set out with his family. The tale goes that in Nishapur they visited an old poet: Attar, who wrote of the birds\' journey to the Simurgh. Attar gave the boy a book and told his father, "Soon this boy will set the heart of the world on fire." The boy was Jalaladdin. Konya called him Mevlana: our master.',
      'Karatay Madrasa. The tiles of its dome imitate the night sky. The moon came down through the opening at the top and fell into the pool below; the students read the heavens on the ground, inside the water. Bring the moonlight to the lock.',
      'The Slender Minaret. The Lamplighters have hung their great lamps from the balcony and sweep the rooftops. The beam breaks on domes, chimneys and porches. Wait in the shadow; run when the light has passed.',
      'One day a dervish in a torn cloak came to Konya: Shams of Tabriz. When Mevlana saw him, he left his books behind. Shams means sun. The people of Konya grew jealous. One night Shams vanished: some say he went back to Tabriz, some say he was killed and thrown into this well. Mevlana searched for him as far as Damascus and did not find him. In the end he said: "What I was seeking, I found in myself."',
      'They say the man who lost his sun began to turn around a pillar; that is how the sema was born: the turning of one who seeks. Tonight is Sheb-i Arus: the night Mevlana died. He called his death a wedding. The tall felt hat is the tombstone of the self, the white skirt its shroud. The right hand opens to the sky, the left turns to the earth: receiving from God, giving to the people. Hide in the skirt of a whirling dervish as he passes in front.',
      'The Semahane. The ney player breathes his first breath. Ever since the reed was torn from the reed bed it has lamented; it longs for the place it was cut from, and whoever listens hears their own parting. A shadow longs for its screen too, Saye. The chandeliers are turning: like the dervishes, like the planets.',
      'Kubbe-i Hadra: the Green Dome, Mevlana\'s tomb. The Lamplighters have taken your master to the very top; all the light they have hoarded for centuries is there. His lamp is about to go out, and the hoarded light is spilling over. Climb, Saye!',
    ],
    memories: [
      'Hatıra · Son gece perdeyi katlarken bana döndü: "Bir gün kandilim sönecek, Sâye. O gece korkma. Gölge, ışık sönünce kaybolmaz; ışığa karışır."',
      'Hatıra · Bir gün dükkâna Kandilciler geldi; ustamın kandilini satın almak istediler. "Bu ışık satılmaz," dedi ustam, "çünkü benim değil. Ben yalnızca önünde duruyorum."',
      'Hatıra · "Işığı saklayan, gölgesini kaybeder," derdi ustam. "Kandilciler bütün ışığı topladı; bak, hiçbirinin gölgesi yok. Benim kandilimi o yüzden istiyorlar: gölgelere can veren tek ışık o."',
      'Hatıra · Ustam bir gece perdeye bir çocuk gölgesi çizdi. "Kim bu?" dedim. "Henüz kimse," dedi. "Bir dua. Karşılığını bekliyor."',
      'Hatıra · "Güneş neden kırıldı, usta?" "Biri onu yalnız kendisi için asmak istedi, Sâye. Işık bölünmeye razı olur; sahiplenilmeye razı olmaz."',
    ],
    memoriesEn: [
      'Memory · On the last night, folding the screen, he turned to me: "One day my lamp will go out, Saye. Do not be afraid that night. A shadow does not vanish when the light dies; it joins the light."',
      'Memory · One day the Lamplighters came to the shop and wanted to buy my master\'s lamp. "This light is not for sale," he said, "because it is not mine. I only stand in front of it."',
      'Memory · "Whoever hides the light loses their shadow," my master used to say. "The Lamplighters gathered all the light; look, not one of them has a shadow. That is why they want my lamp: it is the only light that gives shadows life."',
      'Memory · One night my master drew the shadow of a child on the screen. "Who is that?" I asked. "No one yet," he said. "A prayer. Waiting for its answer."',
      'Memory · "Why did the sun break, master?" "Someone wanted to hang it up for himself alone, Saye. Light agrees to be shared; it never agrees to be owned."',
    ],
    map: kMapKonya,
    // Gölge ikinci kez: iki Kandilci ve semâzensiz bir koridor.
    shadowStones: [(129, 27)],
  ),
  LevelDef(
    title: 'XVI · ERLİK\'İN KATI',
    subtitle: 'Yerin altında ışık tehlikeli, karanlık güvenlidir.',
    titleEn: 'XVI · ERLIK\'S REALM',
    subtitleEn: 'Beneath the earth, light is danger and darkness is safety.',
    theme: LevelTheme.underworld,
    bard: 'Ozan der ki: Yerin altında ışık düşmandır; karanlık, sırtını dayayacağın duvardır.',
    bardEn: 'The bard says: beneath the earth light is the enemy; darkness is the wall you lean your back on.',
    place: 'Ötüken · Yerin altı, Erlik\'in katı',
    placeEn: 'Ötüken · Beneath the earth, Erlik\'s realm',
    gokboruHelp: true,
    cameos: [('erTostuk', 20, 27)],
    areas: [
      'Kara Kapı',
      'Mürekkep Köprüler',
      'Körmös Mağarası',
      'Kut Zindanı',
      'Çalkuyruk Kuyusu',
    ],
    areasEn: [
      'The Black Gate',
      'The Ink Bridges',
      'The Cave of the Körmös',
      'The Dungeon of Kut',
      'Çalkuyruk\'s Well',
    ],
    whispers: [
      'Derinkuyu\'nun da altı: Erlik\'in katı. Burada kanatlar açılmaz; yerin altında gök yok.',
      'Mürekkepten köprüler: ışığını örtersen tutar, açarsan erir.',
      'Tepede Erlik\'in feneri dolaşıyor. Işığı köprüyü de seni de bulur. Taşın oyuğunda bekle.',
      'Kimi tahta ışıkla, kimi karanlıkla durur. Kenarda dur, sonra kavanozunu aç ya da ört.',
      'Körmösler: Erlik\'in gölgeleri. Açık kavanoza gelirler; ateşböceğine de.',
      'Kafeslerde kutlar çırpınıyor: Erlik\'in çaldığı canlar. Her biri bir kapının anahtarı.',
      'Kavanozun parladıkça yolun aydınlanır; ama karanlıkta seni daha uzaktan görürler.',
      'Kuyunun dibinde bir at bekliyor: Er Töştük\'ün atı Çalkuyruk.',
      'Yukarıda bir aralık. Ötesinde ışık var, ama bu kez senin ışığın.',
    ],
    whispersEn: [
      'Below even Derinkuyu: Erlik\'s realm. Wings will not open here; beneath the earth there is no sky.',
      'Bridges of ink: they hold if you cover your light, and melt if you open it.',
      'Erlik\'s lantern drifts overhead. Its light finds the bridge and you alike. Wait in the hollow of the stone.',
      'Some planks stand in light, some in darkness. Stop at the edge, then open or cover your jar.',
      'The Körmös: Erlik\'s shades. They come to an open jar, and to a firefly.',
      'Kuts flutter in the cages: lives Erlik has stolen. Each is the key to a gate.',
      'The brighter your jar, the brighter your path; but in the dark they see you from farther away.',
      'A horse waits at the bottom of the well: Çalkuyruk, Er Töştük\'s horse.',
      'An opening above. Beyond it there is light, but this time it is your own.',
    ],
    memories: [
      'Hatıra · Bir atın gölgesini perdeye ilk kez çizdiğimde ustam güldü: "Atın gölgesi bile seni taşır, Sâye."',
      'Hatıra · Ustam bir gece kandili söndürdü. "Karanlıktan korkma," dedi, "gölge orada doğar."',
      'Hatıra · "Her canın bir ışığı var," derdi. "Kimse onu kafese koyamaz; koyarsa ışık söner, kafes kalır."',
    ],
    memoriesEn: [
      'Memory · The first time I drew a horse\'s shadow on the screen, my master laughed: "Even a horse\'s shadow will carry you, Saye."',
      'Memory · One night my master put out the lamp. "Do not fear the dark," he said, "that is where the shadow is born."',
      'Memory · "Every life has its light," he used to say. "No one can put it in a cage; if they do, the light dies and only the cage remains."',
    ],
    map: kMapErlik,
  ),
  LevelDef(
    title: 'XVII · ERGENEKON',
    subtitle: 'Dört yanı dağ; çıkış demirin içinden.',
    titleEn: 'XVII · ERGENEKON',
    subtitleEn: 'Mountains on every side; the way out runs through iron.',
    theme: LevelTheme.ergenekon,
    bard: 'Ozan der ki: Dağ demirse demir erir; sabreden boyun önü açılır.',
    bardEn: 'The bard says: if the mountain is iron, iron melts; the patient people find the way open.',
    place: 'Ötüken · Ergenekon vadisi',
    placeEn: 'Ötüken · The valley of Ergenekon',
    gokboruHelp: true,
    gokboruWatch: [(316, 5)],
    pawTrails: [(152, 213, 34)],
    mists: [(152, 26, 213, 37)],
    cameos: [('asena', 227, 34)],
    // İlk ocak ritimli (Demirci'nin çekicine uy) ve iki kömür sandığı ister;
    // ikinci ocak çentik sırasıyla.
    forges: [(true, 2), (false, 0)],
    noWings: true,
    nevruz: (316, 6),
    interiors: [(287, 0, 310, 34)],
    bellows: [
      (58, 34, 1),
      (62, 30, 1),
      (66, 34, 1),
      (50, 34, 0),
      (53, 34, 0),
      (240, 34, 1),
      (260, 26, 2),
      (276, 34, 3),
      (248, 34, 0),
      (251, 34, 0),
      (283, 34, 0),
    ],
    areas: [
      'Kıyan Boğazı',
      'Demir Dağın Dibi',
      'Akan Demir',
      'Sisli Çayır',
      'Asena\'nın Mağarası',
      'İkinci Damar',
      'Demir Dağın İçi',
    ],
    areasEn: [
      'Kıyan\'s Gorge',
      'At the Foot of the Iron Mountain',
      'Flowing Iron',
      'The Misty Meadow',
      'Asena\'s Cave',
      'The Second Vein',
      'Inside the Iron Mountain',
    ],
    whispers: [
      'Ergenekon: dört yanı aşılmaz dağ. İçeride çayır, ırmak, meyve; ama çıkış yok.',
      'Dağın dibinde körükler: deriden, sıra sıra. Ocak boş ve sönük: önce odun ve kömür yığılır, sonra yetmiş körük bir ağızdan üfler.',
      'Demir aktı. Akarken yakar; soğuyup kararınca yol olur.',
      'Sabah sisi vadiyi örttü. Yolu göremiyorsun; ama biri önünden geçmiş.',
      'Bir mağara, içinde ak boz bir kurt. Göktürkler derdi ki kurt, yok olmaktan kurtulan çocuğu böyle bir mağarada büyüttü.',
      'İkinci damar daha derin. Üç körük: biri yukarıda, biri akan demirin ötesinde.',
      'Dağ eriyor! Aşağıdan akkor demir yükseliyor: kat kat yukarı, bacaların arasından!',
      'Vadiden çıkış: ilk sabah. Bu gün kutlu sayılır; her yıl bir demir ateşte kızdırılır, örste dövülür. Bugün Nevruz\'da da anılır.',
    ],
    whispersEn: [
      'Ergenekon: impassable mountains on every side. Inside, meadows, a river, fruit; but no way out.',
      'Bellows at the foot of the mountain: made of hide, row upon row. The forge is empty and cold: first wood and charcoal are heaped, then seventy bellows blow as one.',
      'The iron flowed. While it flows it burns; when it cools and darkens it becomes a road.',
      'The morning mist has covered the valley. You cannot see the way; but someone has walked ahead of you.',
      'A cave, and in it a pale grey wolf. The Göktürks said a wolf raised the child saved from destruction in just such a cave.',
      'The second vein runs deeper. Three bellows: one above, one beyond the flowing iron.',
      'The mountain is melting! Molten iron rises from below: up, floor by floor, between the vents!',
      'Out of the valley: the first morning. This day is held sacred; every year a piece of iron is heated in the fire and struck on the anvil. Today it is remembered at Nevruz too.',
    ],
    memories: [
      'Hatıra · "Bir gün bu perdeden çıkacağız," derdi ustam. "Dört yanımız dağ olsa da."',
      'Hatıra · Ustam deriyi gerip perdeye çakarken söylerdi: "Sabırla gerilen deri yırtılmaz."',
      'Hatıra · "Ocak sönerse ne olur, usta?" "Biri yeniden yakar, Sâye. Ateş hep birinin elinden gelir."',
    ],
    memoriesEn: [
      'Memory · "One day we will step out of this screen," my master used to say. "Even if there are mountains on every side."',
      'Memory · Stretching the hide and nailing it to the screen, my master would say: "Hide stretched with patience does not tear."',
      'Memory · "What happens if the forge goes out, master?" "Someone lights it again, Saye. Fire always comes from someone\'s hand."',
    ],
    map: kMapErgenekon,
  ),
  LevelDef(
    title: 'XVIII · GÖĞÜN KATLARI',
    subtitle: 'Her kat bir öncekinden aydınlık.',
    titleEn: 'XVIII · THE LAYERS OF THE SKY',
    subtitleEn: 'Each layer brighter than the last.',
    theme: LevelTheme.heavens,
    bard: 'Ozan der ki: Gök kat kattır; davul vurdukça basamak olur, yıldız döndükçe merdiven.',
    bardEn: 'The bard says: the sky is layer upon layer; each drumbeat a step, each turning star a stair.',
    place: 'Ötüken · Göğün katları',
    placeEn: 'Ötüken · The layers of the sky',
    wings: true,
    cameos: [('kam', 12, 38), ('gokKat', 84, 30)],
    skies: [(0, 0), (121, 1), (198, 2), (290, 1)],
    starStreams: [
      [(295, 23), (300, 20), (306, 16), (312, 13), (318, 11), (323, 11)],
      [(362, 11), (367, 14), (373, 18), (379, 22), (384, 23)],
    ],
    ulker: (
      [
        (325, 10),
        (326, 9),
        (328, 9),
        (329, 10),
        (331, 9),
        (332, 10),
        (333, 11),
      ],
      (334, 355, 12),
    ),
    wheels: [
      (131, 26, 4, 3, 9, 0),
      (147, 17, 3.5, 3, 9, 0),
      (154, 12, 3.5, 3, -9, 0),
      (174, 9, 3, 2, 8, 1),
    ],
    karakci: [(174, 9, 5.2, -18)],
    yel: [(186, 2, 215, 16, 1), (221, 6, 243, 17, -1), (244, 4, 272, 22, -1)],
    areas: ['Bulut Kapısı', 'Ay Katı', 'Yıldız Katı', 'Yel Katı', 'Kuş Yolu'],
    areasEn: [
      'The Cloud Gate',
      'The Moon Layer',
      'The Star Layer',
      'The Wind Layer',
      'The Bird Road',
    ],
    whispers: [
      'Kam\'ın davulu seni göğe taşıdı. Göğün katları üst üste; her biri bir öncekinden aydınlık.',
      'Davulun her vuruşunda bir bulut belirir, öbürü söner. Vuruşu say.',
      'Ay katı: ışık soğuk ve yumuşak. Burada hem ışık hem gölge yol olur.',
      'Ay katının üstünde gece daha derin. Atalar derdi ki gök bir çadırdır, yıldızlar onun delikleri; ışık oradan sızar.',
      'Her yıldız bir kazığa bağlıdır, çevresinde döner. Döneni tutan onunla yükselir.',
      'Göğün ortasında Demir Kazık: göğün direği. Ona iki at bağlı, Ak Boz At ile Kök Boz At. Yedi Karakçı onları çalmak için döner durur; atlar çalınırsa dünyanın sonu gelir.',
      'Yel Katı. Yel Ana burada soluk alır; kamlar ondan yol ister. Soluğu arkana al.',
      'Bu bir yada taşı. Kamlar onunla yağmuru, karı, rüzgârı çağırır. Taşa dokunan, Yel Ana\'ya yön söyler.',
      'Yelin ucunda göğün rengi değişiyor: yukarıda gün katı. Işık orada yakar.',
      'Kuş Yolu. Kazaklar, Kırgızlar Samanyolu\'na böyle der: göçmen kuşlar yolunu onunla bulur. Işık nehrine gir; o seni taşır.',
      'Ülker: yedi yıldız. Yedisine de dokun; aralarındaki çizgiler köprü olur.',
    ],
    whispersEn: [
      'The shaman\'s drum carried you into the sky. The layers of the sky lie one above another, each brighter than the last.',
      'With every drumbeat one cloud appears and the other fades. Count the beat.',
      'The moon layer: the light is cold and soft. Here both light and shadow become a road.',
      'Above the moon layer the night is deeper. The forefathers said the sky is a tent and the stars are its holes; the light seeps through them.',
      'Every star is tied to a stake and turns around it. Whoever holds the turning star rises with it.',
      'At the middle of the sky stands the Iron Stake: the pillar of the sky. Two horses are tied to it, the White-Grey Horse and the Blue-Grey Horse. The Seven Thieves circle forever to steal them; if the horses are stolen, the world will end.',
      'The Wind Layer. Here the Wind Mother breathes; shamans ask her for a road. Keep her breath at your back.',
      'This is a yada stone. With it shamans call rain, snow and wind. Whoever touches it tells the Wind Mother which way to blow.',
      'At the end of the wind the colour of the sky changes: above lies the sun layer. Its light burns.',
      'The Bird Road. So the Kazakhs and Kyrgyz call the Milky Way: migrating birds find their way by it. Step into the river of light; it will carry you.',
      'Ülker: seven stars. Touch all seven; the lines between them become a bridge.',
    ],
    memories: [
      'Hatıra · Ustam geceleri bana Demir Kazık\'ı gösterirdi. "Yolunu yitirirsen ona bak," derdi, "o hiç yerinden oynamaz."',
      'Hatıra · Rüzgârlı gecelerde perdenin bezi dalgalanırdı. Ustam kızmazdı: "Yel de oynamak ister," derdi.',
      'Hatıra · Ay ışığında perde başka türlü yanar. "Soğuk ışık da ışıktır," demişti ustam.',
    ],
    memoriesEn: [
      'Memory · At night my master would show me the Iron Stake. "If you lose your way, look at it," he said. "It never moves."',
      'Memory · On windy nights the cloth of the screen would ripple. My master never minded: "The wind wants to play too," he said.',
      'Memory · In moonlight the screen glows differently. "Cold light is light as well," my master had said.',
    ],
    map: kMapGok,
  ),
  LevelDef(
    title: 'XIV · ÖTÜKEN ORMANI',
    subtitle: 'Yeşilin ilk görüldüğü yer; karanlık da ardından geldi.',
    titleEn: 'XIV · THE FOREST OF ÖTÜKEN',
    subtitleEn:
        'Where green is seen for the first time; and the dark came after.',
    theme: LevelTheme.forest,
    noWings: true,
    legends: ['otuken'],
    bard: 'Ozan der ki: Ötüken\'de ağaç ağaca kök verir; kök tutanı karanlık tutamaz.',
    bardEn: 'The bard says: in Ötüken, tree lends root to tree; whoever holds a root, the dark cannot hold.',
    place: 'Ötüken Yış · Kutlu orman',
    placeEn: 'Ötüken Yış · The sacred forest',
    cameos: [('kam', 153, 39)],
    glades: [
      (32, 26, 60, 40, 0),
      (70, 26, 100, 40, 1),
      // Sahanlıkta ışık sırayla söner; vuruş beklenen uçta ve köklerin
      // üstünde durgundur (iki zorluk üst üste binince geçilmiyordu).
      (232, 18, 241, 33, 2),
      (242, 18, 262, 33, 0),
      (343, 26, 373, 40, 0),
      (628, 18, 641, 40, 2),
    ],
    lifeTree: (642, 18, 649, 39),
    areas: [
      'Orman Eşiği',
      'Kam\'ın Korusu',
      'Ak Geyik',
      'Geyiğin Yolu',
      'Kara Bataklık',
      'Ulu Dallar',
      'Hayat Ağacı',
    ],
    areasEn: [
      'The Forest\'s Edge',
      'The Shaman\'s Grove',
      'The White Deer',
      "The Deer's Path",
      'The Black Marsh',
      'The Great Boughs',
      'The Tree of Life',
    ],
    whispers: [
      'Kökler Sâye\'yi yeryüzüne çıkardı: Ötüken, atalarının kutlu ormanı.',
      'Ama yalnız değil. Sarnıçta onu ilk gören Karabasan da çıktı; sahipsiz gölgeleri yer. Işığa giremez.',
      'Rüzgâr esince ışık kayar. Ötüken\'in yaprakları önce fısıldar, sonra kıpırdar.',
      'Korudan bir davul sesi. Bir kam Sâye\'yi Hayat Ağacı\'na çağırıyor; davulu kökleri uyandırıyor.',
      'Sarmaşıklar kayınlardan sarkar. Atalar derdi ki: orman, yolu ona tutunana açar.',
      'Kökler kam gibi sırayla konuşur: biri kalkar, öbürü iner.',
      'Davul uzaklaşıyor. Hayat Ağacı yakın; Karabasan da.',
      'Ağaçların arasında ak bir geyik: Umay\'ın habercisi. Hun avcılarını da bataklıktan o geçirmişti.',
      'Geyik aşağıdan yürür, sen yukarıdan bakarsın. Ak Geyik\'e yolu ışık gösterir.',
      'Ak Geyik karanlığa adım atmaz. Işığı sen taşı; orman sana ateşböceği verir.',
      'Kara Bataklık. Arkanda dallar kırılıyor: Karabasan geldi!',
      'Hayat Ağacı. Kökleri yerin altına, dalları göğe uzanır; Umay dallarında oturur. Işık dallara sırayla düşer.',
      'Tepede güneş yaprakları deliyor. Ustanın perdesindeki gibi: ışığı çeviren, karanlığı kovar.',
      'Işık köklere aktı; Karabasan bir çığlıkla dağıldı. Ağacın kökleri Erlik\'in katına iniyor: usta oradan geçirilmiş.',
      'Geyik ışığa karışmadan önce başıyla yarı gösterdi: yol sarmaşıklardan geçer. Ötüken\'in sarmaşıkları atalarını da taşımıştı.',
    ],
    whispersEn: [
      'The roots brought Saye up into the world: Ötüken, the sacred forest of her forefathers.',
      'But she is not alone. The Karabasan that first saw her in the cistern has come up too; it devours masterless shadows. It cannot enter the light.',
      'When the wind blows, the light shifts. The leaves of Ötüken whisper first, then stir.',
      'A drum sounds from the grove. A shaman is calling Saye to the Tree of Life; his drum wakes the roots.',
      'Vines hang from the birches. The forefathers said: the forest opens its road to whoever holds on.',
      'The roots speak in turn, like the shaman: one rises, the other sinks.',
      'The drum fades away. The Tree of Life is near; so is the Karabasan.',
      'A white deer among the trees: Umay\'s messenger. It led the Hun hunters across the marsh, too.',
      'The deer walks below, you watch from above. Light shows the White Deer its way.',
      'The White Deer will not step into darkness. You carry the light; the forest will give you fireflies.',
      'The Black Marsh. Behind you branches are snapping: the Karabasan has come!',
      'The Tree of Life. Its roots reach beneath the earth, its branches to the sky; Umay sits on its boughs. The light falls on its branches in turn.',
      'At the top the sun pierces the leaves. As on the master\'s screen: whoever turns the light drives out the dark.',
      'The light flowed down to the roots; the Karabasan scattered with a scream. The tree\'s roots descend to Erlik\'s realm: the master was taken that way.',
      'Before the deer melted into the light, it pointed its head at the ravine: the road runs along the vines. The vines of Ötüken carried your forefathers too.',
    ],
    memories: [
      'Hatıra · Ustam bir kayın dalına ak bir çaput bağlamıştı. "Ne diledin?" dedim. "Dilemedim," dedi, "teşekkür ettim."',
      'Hatıra · Bir gece perdeye bir geyik tasviri koydu. "Geyik yol bilir," dedi. "Ama önüne ışık tutmazsan yürümez."',
      'Hatıra · Ustam tasvirlerin iplerini kendisi bükerdi. "İp," derdi, "tutanın elini değil, yüreğini taşır."',
      'Hatıra · Kâbus görüp uyandığımda ustam kandili başucuma koyardı. "Karabasan ışıkta oturamaz," derdi. "Göğsün hafifler, görürsün."',
      'Hatıra · "Ağacın gölgesi ağaçtan uzun düşer, Sâye," demişti. "Kökü de öyle: görünmez, ama dalı o taşır."',
    ],
    memoriesEn: [
      'Memory · My master had tied a white strip of cloth to a birch branch. "What did you wish for?" I asked. "I did not wish," he said. "I gave thanks."',
      'Memory · One night he set a deer figure on the screen. "A deer knows the way," he said. "But unless you hold a light before it, it will not walk."',
      'Memory · My master twisted the puppets\' strings himself. "A string," he said, "does not carry the hand that holds it, but its heart."',
      'Memory · When I woke from a nightmare my master would set the lamp beside my head. "The Karabasan cannot sit in the light," he would say. "Your chest will lighten, you\'ll see."',
      'Memory · "A tree\'s shadow falls longer than the tree, Saye," he had said. "So do its roots: unseen, yet they carry the branches."',
    ],
    map: kMapOtuken,
    vistas: [(234, 32, 'valley')],
  ),
  LevelDef(
    title: 'XIX · ÜLGEN\'İN KAPISI',
    subtitle: 'Işığın kaynağına, fırtınanın içinden.',
    titleEn: 'XIX · ÜLGEN\'S GATE',
    subtitleEn: 'To the source of light, through the storm.',
    theme: LevelTheme.heavens,
    bard: 'Ozan der ki: Gün katında gölge bir sığınaktır; şimşek bir fener.',
    bardEn: 'The bard says: in the sun layer a shadow is a shelter; lightning, a lantern.',
    place: 'Ötüken · Göğün en yüksek katları',
    placeEn: 'Ötüken · The highest layers of the sky',
    wings: true,
    legends: ['sugeToyon'],
    scorch: [(10, 18, 88, 31)],
    cameos: [('ulgen', 171, 30)],
    skies: [(0, 4), (90, 5), (150, 3), (186, 5)],
    stormSteps: [
      (100, 30, 2),
      (103, 29, 2),
      (116, 29, 2),
      (119, 27, 2),
      (121, 25, 2),
      (133, 26, 2),
      (137, 28, 2),
      (140, 30, 1),
    ],
    strikes: [(95, 30, 0), (111, 30, 1.6), (127, 24, 3.0), (145, 30, 0.8)],
    areas: ['Gün Katı', 'Şimşek Katı', 'Ülgen\'in Kapısı'],
    areasEn: ['The Sun Layer', 'The Lightning Layer', 'Ülgen\'s Gate'],
    whispers: [
      'Yukarısı gün katı: ışık yakar. Biri gölgesini sana uzatacak.',
      'Hüma! Gölgesi kimin başına düşerse... Gölgesinden çıkma.',
      'Şimşek Katı. Yakutlar derdi ki gök gürültüsünün efendisi Süge Toyon kötü ruhlara yıldırım indirir. Bu gece Erlik\'in gölgeleri göğe sızmış.',
      'Yıldırım her çaktığında kara bulutlar bir an görünür. Gördüğünü unutma.',
      'Ülgen\'in kapısı. Işık burada konuşmaz; görünür.',
      'Fırtına! Erlik göğe de uzandı. Tulpar seni bekliyor.',
      'Tulpar seni bulutların arasından aşağı, karlı bir ovaya indirdi. Uzakta bir şehrin kubbeleri.',
    ],
    whispersEn: [
      'Above is the sun layer: its light burns. Someone will lend you their shadow.',
      'The Huma! Whoever its shadow falls on... Do not leave its shadow.',
      'The Lightning Layer. The Yakuts said that Süge Toyon, lord of thunder, hurls lightning at evil spirits. Tonight Erlik\'s shades have crept into the sky.',
      'Each time lightning strikes, the black clouds show for a moment. Do not forget what you saw.',
      'Ülgen\'s gate. Here light does not speak; it shows itself.',
      'A storm! Erlik has reached into the sky as well. Tulpar is waiting for you.',
      'Tulpar brought you down through the clouds to a snowy plain. In the distance, the domes of a city.',
    ],
    memories: [
      'Hatıra · "Bir gün gökte de bir perde açacağım," derdi ustam. "Bulutlar tasvir olacak."',
      'Hatıra · Yıldırım düşünce korkup ustamın arkasına saklanırdım. "Işık bazen bağırır," derdi, "ama yine de ışıktır."',
      'Hatıra · "Usta, güneşi kim kırdı?" "Ona tek başına sahip olmak isteyen, Sâye."',
    ],
    memoriesEn: [
      'Memory · "One day I will open a screen in the sky too," my master used to say. "The clouds will be the puppets."',
      'Memory · When lightning struck I used to hide behind my master. "Sometimes light shouts," he said, "but it is still light."',
      'Memory · "Master, who broke the sun?" "Someone who wanted it all to himself, Saye."',
    ],
    map: kMapGok2,
  ),
  // XX · Yeşil Kubbe: oyunun finali (docs/YESIL_KUBBE_PLANI.md).
  LevelDef(
    title: 'XXI · YEŞİL KUBBE',
    legends: ['sebiArus'],
    bard: 'Ozan der ki: Işık bölünmeye razıdır; sahiplenilmeye razı olmaz.',
    bardEn: 'The bard says: light consents to be shared; it never consents to be owned.',
    subtitle: 'Kandil sönerken gölge ışığa karışır.',
    subtitleEn: 'As the lamp goes out, the shadow joins the light.',
    theme: LevelTheme.konya,
    wings: true,
    titleEn: 'XXI · THE GREEN DOME',
    place: 'Konya · Yeşil Kubbe, Şeb-i Arûs gecesi',
    placeEn: 'Konya · The Green Dome, the night of Sheb-i Arus',
    areas: [
      'Türbe Avlusu',
      'Kandiller Koridoru',
      'Kubbenin Kaburgaları',
      'Ustanın Kandili',
    ],
    areasEn: [
      'The Tomb Courtyard',
      'The Corridor of Lamps',
      'The Ribs of the Dome',
      'The Master\'s Lamp',
    ],
    whispers: [
      'Yeşil Kubbe. Kandilciler ustayı en tepeye çıkardı; yüzyıllardır topladıkları bütün ışık orada. Bu gece düğün gecesi.',
      'Şadırvanın havuzuna ay düşer. Aynaları çevir: ay ışığı türbenin gümüş kapısını açar.',
      'Gümüş kapının üstünde Câmî\'nin beyti: "Burası âşıkların Kâbesidir; buraya eksik gelen tamamlanır."',
      'Kandiller koridoru. Kandilciler topladıkları ışıkları gümüş kafeslere asmış: her biri bir evin, bir çocuğun ışığı. Kafesi aç; ışık sahibini hatırlar.',
      'Işığı saklayan gölgesini kaybeder. Kandilciler yüzyıllardır gölgesiz dolaşıyor; o yüzden fenerleri hiç sönmez.',
      'Sandukaların başında sikkeler: dervişin keçe külahı, nefsin mezar taşı. Burada ölüm bir düğündür.',
      'Kubbenin yeşil kaburgaları. Kandilciler kasnağı dolaşıyor, fenerleri kaburgaları tarıyor. Gölgede bekle; ışık geçince tırman.',
      'Aşağıda biriken ışık taşıyor. Sel yükseliyor, Sâye: tırman!',
      'Ustanın kandili. Kandilci Başı onu bırakmıyor. Bir zamanlar o da bir hayalîydi; gölgesini kaybedeli çok oldu. Ona kendi gölgesini göster.',
    ],
    whispersEn: [
      'The Green Dome. The Lamplighters carried the master to the very top; all the light they have gathered for centuries is there. Tonight is the wedding night.',
      'The moon falls into the fountain\'s pool. Turn the mirrors: moonlight opens the tomb\'s silver door.',
      'Above the silver door, Jami\'s couplet: "This is the Kaaba of lovers; whoever comes here incomplete is made whole."',
      'The corridor of lamps. The Lamplighters hung the light they gathered in silver cages: each the light of a home, of a child. Open a cage; the light remembers its owner.',
      'Whoever hides the light loses his shadow. The Lamplighters have wandered shadowless for centuries; that is why their lanterns never go out.',
      'Felt caps on the cenotaphs: the dervish\'s sikke, the tombstone of the ego. Here, death is a wedding.',
      'The green ribs of the dome. Lamplighters circle the drum; their lanterns sweep the ribs. Wait in the shadow; climb when the light has passed.',
      'The light gathered below is overflowing. The flood is rising, Saye: climb!',
      'The master\'s lamp. The Chief Lamplighter will not let it go. He too was once a shadow master; it has been long since he lost his shadow. Show him his own shadow.',
    ],
    memories: [
      'Hatıra · Ustam her oyunun sonunda kandili üflemeden önce perdeye eğilir, gölgelere teşekkür ederdi.',
      'Hatıra · "Perde biter, Sâye," derdi. "Gölge bitmez. Bir başka kandilde yeniden doğar."',
      'Hatıra · Bir gece sordum: "Usta, gölgenin de gölgesi olur mu?" Güldü: "Dua eden gölgenin olur."',
    ],
    memoriesEn: [
      'Memory · At the end of every play, before blowing out the lamp, my master bowed to the screen and thanked the shadows.',
      'Memory · "The screen comes to an end, Saye," he said. "The shadow does not. It is born again by another lamp."',
      'Memory · One night I asked: "Master, does a shadow have a shadow too?" He laughed: "A praying shadow does."',
    ],
    shadowStones: [(101, 51), (145, 51)],
    cages: [(92, 51), (132, 51), (182, 51)],
    finale: (284, 9),
    finaleLocks: [(281, 9), (290, 7), (287, 9)],
    floodSpeed: 16,
    map: kMapYesilKubbe,
  ),
  LevelDef(
    title: 'XV · AK ANA\'NIN DENİZİ',
    subtitle: 'İlk su: ne dibi görünür ne ucu.',
    titleEn: 'XV · THE SEA OF AK ANA',
    subtitleEn: 'The first water: neither its floor nor its end can be seen.',
    theme: LevelTheme.sea,
    noWings: true,
    legends: ['akAna'],
    bard: 'Ozan der ki: Su her şeyden önce vardı; her şeyden sonra da olacak.',
    bardEn: 'The bard says: water was there before everything; it will be there after everything too.',
    place: 'İlk Su · Ak Ana\'nın denizi',
    placeEn: 'The First Water · The sea of Ak Ana',
    areas: [
      'Köklerin Ucu',
      'Yosun Ormanı',
      'Denizanası Mağaraları',
      'Akıntı Koridorları',
      'Kişi\'nin Taşı',
      'Karanlık Dip',
    ],
    areasEn: [
      "The Roots' End",
      'The Kelp Forest',
      'The Jellyfish Caves',
      'The Current Corridors',
      "Kişi's Stone",
      'The Dark Deep',
    ],
    whispers: [
      'İlk su. Ne dibi görünür ne ucu. Kökler Sâye\'yi kıyısına bırakmıştı.',
      'Ozan der ki: Kişi, Kayra Han\'dan yükseğe çıkmak istedi; kanatları tutmadı, suya düştü. Boğulurken yardım diledi.',
      'Işığa yaklaşma. Derinde ışık, yem demektir.',
      'Kayra Han sudan bir taş yükseltti; Kişi ona tutundu. O taş hâlâ ilk suyun ortasında durur derler.',
      'Kişi\'nin taşı. Su da burada nefes alır.',
      'Kişi dibe daldı, toprak getirdi; bir parçasını ağzında sakladı. Toprak ağzında şişti; "Tükür," denince tükürdü. Bataklıklar ondan kaldı.',
      'Körmösler! Işığa geliyorlar. Yosuna saklan.',
      'Su kıpırdadı. Ak Ana yükseldi; Sâye\'nin göğsüne ak bir nefes doldu.',
    ],
    whispersEn: [
      'The first water. Neither its floor nor its end can be seen. The roots had left Saye on its shore.',
      'The bard says: Kişi wanted to rise higher than Kayra Khan; his wings failed him and he fell into the water. Drowning, he begged for help.',
      'Keep away from the light. In the deep, light means bait.',
      'Kayra Khan raised a stone from the water, and Kişi held on to it. They say that stone still stands in the middle of the first water.',
      "Kişi's stone. Here, the water breathes too.",
      'Kişi dived to the bottom and brought up earth; a piece of it he hid in his mouth. The earth swelled in his mouth; told to spit, he spat. The marshes were left from that.',
      'The Körmös! They are coming to the light. Hide in the kelp.',
      'The water stirred. Ak Ana rose; a white breath filled Saye\'s chest.',
    ],
    memories: [
      'Hatıra · Ustam suya bir kandil bırakıp ardından bakardı. "Su ışığı saklamaz," derdi, "derine götürür."',
      'Hatıra · Bana yüzmeyi Haliç\'in sığında öğretti. "Nefesini say," dedi, "korkunu sayma."',
      'Hatıra · Perdede balıkları hep sürüyle oynatırdı. "Tek balık kaybolur," derdi, "sürü yolu bilir."',
      'Hatıra · "Taşa tutunan boğulmaz, Sâye," demişti. "Ama taş da bir gün bırakmanı ister."',
    ],
    memoriesEn: [
      'Memory · My master would set a lamp on the water and watch it drift away. "Water does not hide light," he said, "it carries it deep."',
      'Memory · He taught me to swim in the shallows of the Golden Horn. "Count your breaths," he said, "not your fears."',
      'Memory · On the screen he always played the fish in a shoal. "One fish gets lost," he said, "a shoal knows the way."',
      'Memory · "Whoever holds on to a stone does not drown, Saye," he had said. "But one day the stone asks you to let go."',
    ],
    map: kMapDeniz,
    seaSurface: kDenizSurface,
    airPockets: kDenizAir,
    kelpBeds: kDenizKelp,
    fishSchools: kDenizFish,
    jellies: kDenizJellies,
    anglers: kDenizAnglers,
    octopi: kDenizOctopi,
    currents: kDenizCurrents,
    bubbleVents: kDenizVents,
    turtle: kDenizTurtle,
    boats: kDenizBoats,
    akAna: kDenizAkAna,
  ),
];
