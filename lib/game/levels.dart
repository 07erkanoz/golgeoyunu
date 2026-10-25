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
  forest;

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
  });

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
  'İstanbul, Temmuz 1660. Şehir iki gündür yanıyordu.',
  'Kandilciler Loncası küllerin arasında dolaştı; her kandili, her mumu, her gözdeki ışığı topladı.',
  'Son olarak Hayali Usta\'nın perdesine geldiler. Kandili söndürdüler, ustayı götürdüler.',
  'Perde karardı. Ama bir gölge, ışık sönmeden önce perdeden düştü.',
  'Düştüğü yerde, külün içinden bir kayın fidanı yükselmişti; dalında tek bir ak çaput. Umay, düşen her çocuğun yanındadır.',
  'GÖLGE OYUNU',
  'Sâye gözlerini suyun altındaki bir şehirde açtı: Yerebatan Sarnıcı.',
  'Bin yılı aşkın zaman önce Bizans imparatoru Justinianus, şehir susuz kalmasın diye yerin altına bir saray kazdırmıştı. Üç yüz otuz altı sütun karanlığa bir orman gibi dikildi.',
  'Sütunlardan birinin gövdesi hep ıslaktır. Derler ki sarnıcı kazarken ölen yüzlerce kölenin gözyaşıdır; halk ona Ağlayan Sütun der.',
  'Zamanla İstanbullular sarnıcı unuttu. Evlerinin tabanından kova sarkıtıp su çektiler, balık tuttular; altlarında bir şehir uyuduğunu bilmeden.',
  'Şimdi o sularda bir gölge yürüyor.',
];

const prologueEn = [
  'Istanbul, July 1660. The city had been burning for two days.',
  'The Lamplighters\' Guild walked among the ashes, gathering every lamp, every candle, every light in every eye.',
  'Last, they came to Master Hayali\'s screen. They snuffed his lamp and took him away.',
  'The screen went dark. But one shadow fell from it before the light died.',
  'Where it fell, a birch sapling had risen from the ashes, a single white strip of cloth tied to its branch. Umay stands beside every child who falls.',
  'SHADOW PLAY',
  'Saye opened her eyes in a city beneath the water: the Basilica Cistern.',
  'More than a thousand years ago the Byzantine emperor Justinian had a palace dug beneath the earth so the city would never go thirsty. Three hundred and thirty-six columns rose into the dark like a forest.',
  'The trunk of one column is always wet. They say it is the tears of the hundreds of slaves who died digging the cistern; the people call it the Weeping Column.',
  'In time the people of Istanbul forgot the cistern. They lowered buckets through the floors of their houses, drew water, caught fish; never knowing a city slept beneath them.',
  'Now a shadow walks on those waters.',
];

List<String> get prologueText => S.en ? prologueEn : prologue;

const epilogue = [
  'Yeşil Kubbe\'nin tepesinde, karın altında, bir kandil titriyordu.',
  'Ustası oradaydı; yaşlanmış, küçülmüştü. Kandilciler çevresine halka olmuş, fenerlerini kandile doğru tutuyorlardı.',
  '"Geldin," dedi usta. "Biliyordum. Dua karşılıksız kalmaz."',
  'Kandilciler bütün ışığı toplamış, bu yüzden gölgelerini kaybetmişlerdi. Ustanın kandili gölgelere can veren tek ışıktı. Güneşi kendileri için asmak istediklerinde güneş kırılmıştı; şimdi bu kandille onu yeniden yakacaklardı.',
  '"Kandilim sönmesin diye beni buraya getirdiler," dedi usta. "Mevlânâ\'nın düğün gecesine. Sanıyorlar ki bu gece ışık ölmez."',
  '"Haklılar, Sâye. Bu gece ışık ölmez. Yalnızca kavuşur."',
  'Semâhaneden ney sesi yükseldi. Usta kandili Sâye\'nin avuçlarına bıraktı.',
  '"Sen benim gölgem değildin. Duamdın. Hem eşim, hem yolum, hem hemzatım. Şimdi ışığı tutma sırası sende."',
  'Kandil söndü.',
  'Perde karardı. Bir an hiçbir şey kalmadı: ne usta, ne gölge.',
  'Sonra Sâye\'nin içinden bir ışık doğdu. Gölge kaybolmamıştı; ışığa karışmıştı.',
  'Kandilcilerin yüzyıllardır biriktirdiği bütün ışık o ışığa döndü ve göğe yükseldi. Kandilciler karın üstüne düşen gölgelerine baktı ve ağladı.',
  'Hüdhüd Sâye\'nin omzuna kondu: "Kırık güneşin yalnızca bir parçası buradaydı. Ötekiler dünyanın dört bir yanına dağıldı."',
  'Sâye perdenin ardına baktı. Kar yeni yağmış gibi, önünde bir yol uzanıyordu.',
  'Rüzgârda ustasının sesi: "Yürü, Sâye. Yol bitmez; yürüyen değişir."',
  'SÂYE\'NİN YOLCULUĞU SÜRECEK',
];

const epilogueEn = [
  'At the top of the Green Dome, under the snow, a lamp was trembling.',
  'Her master was there, grown old and small. The Lamplighters stood in a ring around him, holding their lanterns toward the lamp.',
  '"You came," said the master. "I knew it. No prayer goes unanswered."',
  'The Lamplighters had gathered all the light, and so they had lost their shadows. The master\'s lamp was the only light that gave shadows life. When they had tried to hang the sun for themselves alone, the sun had broken; now they meant to kindle it again with this lamp.',
  '"They brought me here so my lamp would not go out," said the master. "To Mevlana\'s wedding night. They believe light cannot die tonight."',
  '"They are right, Saye. Tonight light does not die. It only reunites."',
  'From the semahane rose the sound of the ney. The master placed the lamp in Saye\'s hands.',
  '"You were never my shadow. You were my prayer. My companion, my road, my hemzat. Now it is your turn to hold the light."',
  'The lamp went out.',
  'The screen went dark. For a moment nothing remained: neither master nor shadow.',
  'Then a light was born from within Saye. The shadow had not vanished; it had joined the light.',
  'All the light the Lamplighters had hoarded for centuries turned toward that light and rose into the sky. The Lamplighters looked at their own shadows falling on the snow, and wept.',
  'The Hoopoe landed on Saye\'s shoulder: "Only one piece of the broken sun was here. The others are scattered to the four corners of the world."',
  'Saye looked beyond the screen. As if the snow had only just fallen, a road stretched out before her.',
  'In the wind, her master\'s voice: "Walk on, Saye. The road does not end; the one who walks it changes."',
  'SAYE\'S JOURNEY WILL CONTINUE',
];

List<String> get epilogueText => S.en ? epilogueEn : epilogue;

/// Bölüm aralarında perdede oynanan gölge oyunu sahneleri: her bölümden
/// önce (indeks = bölüm). Satırlar sırayla, perdedeki tasvirlerle birlikte.
const interludes = <List<String>>[
  [],
  [
    'Sarnıçtan çıktığında şehir hâlâ yanıyordu. Dumanın içinden Galata Kulesi yükseliyordu: Cenevizlilerin İsa Kulesi, İstanbul\'un en yüksek gözü.',
    'Otuz yıl önce, Sultan Murad\'ın zamanında, bu kulede bir adam göğe bakmıştı. Adı Hezarfen Ahmed Çelebi\'ydi: bin fen bilen.',
    'Önce Okmeydanı\'nda, kartal kanadına benzeyen kanatlarla rüzgâra karşı sekiz dokuz kez havalandı.',
    'Sonra bir lodos sabahı kulenin tepesinden kendini boşluğa bıraktı. Evliya Çelebi anlatır: Boğaz\'ın üstünden süzüldü, Üsküdar\'da Doğancılar Meydanı\'na indi. O gün bütün şehir bir insanın kuş olduğunu gördü.',
    'Sultan ona bir kese altın verdi, sonra şöyle dedi: "Bu adam korkulacak adamdır; ne dilerse elinden gelir." Hezarfen\'i Cezayir\'e sürdüler. Göğü bir kez gördü; gurbette öldü.',
    'Derler ki kanatlarını kulenin en üst katına saklamıştı, düşmekten korkmayan birine. Uçanlar sürgün edilir, Sâye. Yine de uç.',
  ],
  [
    'Kanatlar onu kulenin tepesinden bulutların arasına taşıdı: Gökyolu, İstanbul\'un üstünde.',
    'Evliya Çelebi\'nin dostu Lagari Hasan Çelebi de bir zamanlar göğe çıkmıştı: Sarayburnu\'nda yedi kollu bir fişeğe bindi, barutun ateşi onu bulutlara fırlattı.',
    'Ateş bitince denize düştü, yüzerek padişahın önüne çıktı ve güldü: "İsa Peygamber sana selam söyledi."',
    'Eskiler bu yolun yalnızca kuşlara ve ölülere görünen bir köprü olduğunu söyler. Ucunda dünyanın kıyısı vardır: Kaf Dağı.',
    'Hüdhüd fısıldadı: "Kandilciler topladıkları ışığı göğe astı; güneşi onlar kırdı. Ustanın kandilini de bu yoldan götürdüler."',
    'Bulutların ardında kanatlı bir at dörtnala geçti: Tulpar, yiğidin yoldaşı. Gökyolu onun da yoludur.',
  ],
  [
    'Bulutların bittiği yerde dünyanın kıyısı göründü: zümrüt kayalardan bir dağ, Kaf.',
    'Eskiler derdi ki Kaf dünyayı bir yüzük gibi sarar; ardında ne gece vardır ne gündüz. Tepesinde kuşların padişahı Simurg yaşar.',
    'Bir zaman kuşlar padişahlarını aramaya çıktı. Onlara Hüdhüd yol gösterdi: Süleyman Peygamber\'in habercisi, yolu bilen tek kuş. Şimdi senin rehberin.',
    'Yedi vadiden geçtiler: talep, aşk, marifet, istiğna, tevhid, hayret ve yokluk. Kimi korktu, kimi yoruldu, kimi yolda bir dala kondu ve kaldı. Kaf\'a yalnızca otuz kuş vardı.',
    'Simurg üç tüyünü bu dağa bırakmış. Üçünü bulmayan, zirvedeki aynayı göremez.',
  ],
  [
    'Kaf\'ın tepesinde bir ayna vardı. Otuz kuş Simurg\'u aradı; aynada kendilerini gördüler. Simurg, eski dilde "otuz kuş" demektir.',
    'Sâye de baktı. Aynada bir çocuk yoktu. Bir gölge vardı. Sâye: eski dilde gölge.',
    'Ustanın kandili Kaf\'ta değildi. Kandilciler onu doğuya, tufandan beri sönmeyen ışığın yattığı dağa götürmüştü: Ağrı\'ya.',
    'Ermeniler bu dağa Masis der; Kürt çobanlar Çiyayê Agirî, ateşli dağ derler. Tufandan sonra gemi onun omzuna oturmuş, insanlık orada yeniden doğmuş.',
    'Zirvesine çıkılmaz. Bir keşiş, Aziz Hakob, gemiyi görmek için yıllarca tırmandı; her gece uyuyunca dağın eteğinde uyandı. Sonunda bir melek ona gemiden bir tahta parçası getirdi: "Zirve sana yasak, ama arayışın karşılıksız kalmayacak."',
    'Tipinin içinde ak sakallı bir ihtiyar yürüyordu: Ayaz Ata. Kışın ağırlığı onunla gelir.',
    'İKİNCİ PERDE · DAĞ',
  ],
  [
    'Ağrı\'nın buzullarının altında taşa dönmüş kocaman bir gövde yatıyordu: Nuh\'un Gemisi.',
    'Yağmur kırk gün kırk gece yağmış; gemi aylarca karanlık sularda sürüklenmiş. Sular çekilince bu dağın omzuna oturmuş.',
    'Nuh önce bir kuzgun salmış; kuzgun dönmemiş. Sonra bir güvercin salmış; güvercin gagasında bir zeytin dalıyla dönmüş: dünya yeniden yeşeriyordu.',
    'Gemide her canlıdan bir çift varmış, bir de hiç sönmeyen bir ışık. Kandilciler o ışığı almak için gövdeye girdi; hayvanların gölgelerini eşlerinden ayırıp ambarlara kilitlediler.',
    'Gölgeler birbirini arıyor, Sâye. Onları kavuştur.',
    'Tufan suyunun içinden ak bir ışık yükseldi: Ak Ana. İlk su da böyle kıpırdamıştı.',
  ],
  [
    'Gemideki ışık çoktan götürülmüştü. Sâye güneye, Fırat\'ın ötesine uçtu: Nemrut Dağı, eski Kommagene krallığının zirvesi.',
    'Kral Antiochos\'un babası Persli, annesi Yunanlıydı. İki dünyanın tanrılarını tek bir dağda buluşturdu: Zeus\'u Oromasdes\'le, Apollon\'u Mithras\'la, Herakles\'i Artagnes\'le birleştirdi ve onların arasına kendi tahtını koydu.',
    'Dağın tepesine taştan bir tepe yığdırdı, altına kendini gömdürdü. Tahtların ardına yazdırdı: "Ruhum tanrıların katına çıkınca, bedenim burada sonsuza dek uyusun."',
    'Ama dağ kibri sevmez. Depremler başları gövdelerden ayırdı; başlar hâlâ karda, güneşin doğduğu yere bakar.',
    'Kandilciler gemideki ışığı tanrıların arasından doğu terasına taşıyordu. Güneş doğunca yakacaklardı.',
  ],
  [
    'Nemrut\'ta güneş iki kez doğar, derler: bir kez gökte, bir kez taş tanrıların yüzünde. Halk bu dağa Nemrud\'un adını vermiştir.',
    'Nemrud göğe hükmetmek istedi. Dört kartalı bir sandığa bağladı, önlerine et astı; kartallar etin peşinde uçtukça sandık göğe yükseldi.',
    'Göğe bir ok attı; ok kanlı döndü. "Tanrı\'yı vurdum," dedi. İbrahim\'i ateşe attırdı; ateş bir gül bahçesine döndü.',
    'Sonunda ona bir sivrisinek gönderildi. Burnundan girdi, beynine ulaştı. Göğe meydan okuyan kral, yıllarca başına tokmak vurdurarak öldü.',
    'Doğu terasında taştan bir dev uyanıyor. Şafaktan önce yetiş, Sâye: küçük bir ışık, büyük bir kibri yıkabilir.',
    'Ozan der ki: Tek gözlü dev Tepegöz de taştan bir dev kadar korkunçtu; onu aslanlar arasında büyüyen Basat yendi.',
  ],
  [
    'Sâye ışığa dokunduğunda bir an ustasını gördü.',
    'Bir kervanın ortasında, zincirli, karın içinde yürüyordu. Kandili göğsündeydi; alevi bir mum kadar kalmıştı.',
    'Kandilciler kırık güneşin ışıklarını topladıkça ustanın kandilinden çekiyorlardı. Kervan kuzeye, Erzurum\'a gidiyordu.',
    'Erzurum: Romalıların Theodosiopolis\'i, Selçukluların Erzen-i Rum\'u, doğunun kalesi. Kışı öyle sert gelir ki yolcular ona "kışın kapısı" der.',
    'Şehrin güneyinde dik yokuşlu bir dağ yükselir. Kervancılar ona Palandöken der: yokuşlarında hayvanların sırtındaki palanlar kayar, yükler uçuruma dökülürmüş.',
    'Kervanın önünde, karda gök yeleli bir kurt yürüyordu: Gökbörü. Oğuz\'un ordusuna da böyle yol göstermişti.',
    'ÜÇÜNCÜ PERDE · KAR',
  ],
  [
    'Kar Yolu bitti. Önde iki beyaz doruk yükseliyordu: Büyük Ejder ve Küçük Ejder.',
    'Ozan der ki: dünya yeniyken bu doruklarda iki ejder kardeş yaşarmış. Kışın ovaya inip sürüleri, kervanları yutarlarmış.',
    'Bir gece bir derviş zirveye çıkıp dua etmiş. Kar yedi gün yedi gece yağmış; ejderler karın altında uykuya dalmış, doruklara dönüşmüşler.',
    'O günden beri fırtına onların nefesi, sis onların uykusudur. Uyandıranı kar yutar.',
    'Kandilcilerin kervanı karşı yamaçtan iniyordu. Sâye\'nin taşıyacak yükü yoktu: bir kavanoz ışık, bir de bir isim. Ancak kayarak yetişebilirdi.',
  ],
  [
    'Küçük Ejder\'in yamacında Kandilciler fenerlerini dağın burnuna tuttu.',
    'Uyuyan ejder ışığı sevmez. Ozan der ki ejder uyurken dağ susar; uyandığında kar akar.',
    'Dağ derin bir nefes aldı.',
    'Ve kar aktı.',
    'Çığın önünde gök yeleli kurt koşuyordu; güvenli yolu o biliyordu.',
  ],
  [
    'Çığ dindiğinde kervan batıya dönmüştü. Sâye karların ardından Kapadokya\'ya indi; Muşkara köyünün üstünde ay doğuyordu.',
    'Eskiler bu ülkeye Katpatuka derdi; kimi "güzel atlar ülkesi" diye çevirir. Erciyes\'in ve Hasan Dağı\'nın küllerini yağmur ve rüzgâr çağlar boyu oydu; kayalar başlıklı devler gibi göğe yükseldi.',
    'Muşkara\'nın çobanları geceleri tepelerde ışıklar görürdü. Periler, derlerdi: bacaların tepesinde yaşayan, devlerle savaşmış periler.',
    'Peri halkı gölge bırakmaz, Sâye. Ama gölgeyi tanır.',
    'Ama bacaların gölgesinde kızıl bir gölge de dolaşır: Albastı. Işığı çalar; demirden korkar.',
    'DÖRDÜNCÜ PERDE · PERİLER',
  ],
  [
    'Uçhisar\'dan bakınca Sâye ovanın ortasında bir kuyu ağzı gördü. Kandilcilerin fenerleri birer birer içine iniyordu: Derinkuyu.',
    'Yerin altında sekiz kat inen bir şehir: ahırları, şaraphaneleri, şapelleri, kuyuları, nefes alan bacalarıyla. Derler ki yirmi bin can, düşman geçene dek orada saklanırmış.',
    'Peri Padişahı ateşli devleri yerin altına sürmüştü. Derinkuyu\'yu kazanlar, devlerin uykusunun üstüne bir şehir kurmuş.',
    'Yuvarlak taş kapılar yalnızca içeriden açılır. İçeride olan yaşar. Aşağı in, Sâye; ama uyuyanı uyandırma.',
    'Yerin en dibinden boğuk bir ses gelir. Derler ki Erlik\'in katı oradan da aşağıdadır.',
  ],
  [
    'Tulpar onu bulutların arasından indirdiğinde gökte ay vardı; önünde uçsuz bucaksız, karlı bir ova.',
    'Batıda bir şehrin kubbeleri parlıyordu. Kandilciler ustayı oraya götürmüştü: Konya\'ya, Selçukluların başkentine, Mevlânâ\'nın şehrine.',
    'O gece Şeb-i Arûs\'tu: Mevlânâ\'nın vefat gecesi, düğün gecesi.',
    'Neredeyse dört yüz yıl önce bu gece Mevlânâ ölmüştü. "Ağlamayın," demişti, "bu benim düğünümdür."',
    'Kandilciler sanıyordu ki düğün gecesinde ışık ölmez. Ustanın kandilini sonsuza dek yakmak için bu geceyi bekliyorlardı.',
    'Ovada, bir tepenin üstünde gök yeleli bir kurt şehre bakıyordu.',
    'SON PERDE · DÜĞÜN',
  ],
  [
    'Hayat Ağacı\'nın kökleri yerin en dibine iner. Sâye köklerin arasından aşağı süzüldü; en dipte bir ses vardı: su sesi.',
    'Ozan der ki: Başlangıçta yalnız su vardı. Kayra Han suyun üstünde yalnızdı; ne yaratacağını bilmiyordu.',
    'Sudan ak bir ana yükseldi: Ak Ana. "Yarat," dedi, ve yeniden suya döndü.',
    'Kayra Han yarattı. Ama yarattıklarından biri, Erlik, kendini ondan büyük sandı; yerin altına sürüldü.',
    'Kandilcilerin çaldığı ışıklar yerin altına, Erlik\'in katına akıyordu. Usta da o yoldan geçirilmişti.',
    'Ozan der ki: Bir zaman Er Töştük adında bir yiğit de yerin altına düşmüştü. Konuşan atı Çalkuyruk ona yol gösterdi.',
    'Yerin altında Erlik\'in gölgeleri dolaşır: Körmösler. Işığa gelirler; çalınan canları, kutları kafeslerde tutarlar.',
  ],
  [
    'Ozan der ki: Bir zaman bir boyun ataları büyük bir savaşta yenildi; yalnız iki yiğit, Kıyan ile Nüküz, eşleriyle kurtuldu.',
    'Dağların arasında, yolu bir keçi yolundan dar bir vadiye sığındılar: Ergenekon. İçi çayır, ırmak, meyve ağacı ve av doluydu.',
    'Dört yüz yıl geçti; boy çoğaldı, vadi dar geldi. Ama dışarı çıkacak yol yoktu: dört yanı aşılmaz dağ.',
    'Bir demirci dedi ki: "Şu dağ demirdir. Odun, kömür yığalım; körük kuralım, eritelim." Deriden yetmiş körük kurdular.',
    'Dağ eridi; yüklü bir devenin geçeceği kadar yol açıldı. Kimi anlatılar, yolu bir boz kurdun gösterdiğini söyler.',
    'O gün kutsal sayıldı: her yıl o gün bir parça demir ateşte kızdırılır, örsün üstünde dövülürdü.',
    'Kandilciler vadinin ocağındaki ateşi de toplamıştı. Ocak sönük, Sâye; körükler bekliyor.',
  ],
  [
    'Ozan der ki: Altay\'da kamlar davullarını çalınca canları göğe yükselirmiş. Göğün kat kat olduğunu onlar anlatır.',
    'Göğün on altıncı katında Ülgen oturur: iyiliğin ve aydınlığın kaynağı. Erlik onun karşıtıdır.',
    'Bir katında ay soğuk ve yumuşak yanar; bir katında yıldızlar Demir Kazık\'ın çevresinde döner.',
    'Kazığa iki at bağlıdır; Yedi Karakçı onları çalmak ister. Katların arasında Yel Ana eser.',
    'Kandilciler kırık güneşin bir parçasını göğün en yüksek katına götürmüştü. Bir kam davulunu çaldı; Sâye bulutların üstüne yükseldi.',
  ],
  [
    'Derinkuyu\'nun en dibinde taşın arasından kökler sarkıyordu. Sâye bir köke tutundu; kök onu yukarı, ışığa doğru çekti.',
    'Toprağın üstüne çıktığında gün ağarıyordu. Önünde uçsuz bucaksız bir orman: kayınlar, çamlar, yosun, kuş sesi.',
    'Kül Tigin Yazıtı der ki: İli tutacak yer Ötüken ormanıdır; ondan iyisi yoktur.',
    'Ormanın ortasında bir ağaç göğe dek yükselir: Hayat Ağacı. Umay dallarında oturur; doğacak çocukların canları kuş olup konar.',
    'Ama Sâye yalnız değildi. Sarnıcın karanlığında onu ilk gören, Derinkuyu\'da ardından sürünen şey de yukarı çıkmıştı: Karabasan.',
    'Karabasan sahipsiz gölgeleri sezer. Uyuyanın göğsüne çöker gibi onlara çöker, onları yer. Ustası olmayan bir gölge, onun için en tatlı lokmadır.',
    'Ama ışığa giremez. Ötüken\'in yaprakları arasından süzülen her huzme, Sâye için bir sığınaktır.',
    'BEŞİNCİ PERDE · ÖTÜKEN',
  ],
  [
    'Yel Ana Sâye\'yi gün katının eşiğine bıraktı. Kam\'ın davulu artık duyulmuyordu.',
    'Gün katının ötesinde Ülgen\'in kapısı vardı; kırık güneşin parçası orada bekliyordu.',
    'Gün katında güneş yakar. Ama göğün bu yüksekliğinde bile Erlik\'in fırtınası kaynıyordu.',
    'Derler ki Hüma\'nın gölgesi kimin başına düşerse ona kut getirir. Tulpar ise yiğidi göğün katları arasında taşır.',
    'Yakutlar gök gürültüsünü Süge Toyon\'un sesi bilir; yıldırımı kötü ruhlara indirir. O gece gök gürlüyordu.',
  ],
  [
    'Sâye semâhanenin damından Yeşil Kubbe\'ye baktı. Kubbenin içinden yüzyılların ışığı taşıyordu.',
    'Kandilciler ustayı kubbenin tepesine, alemin dibine çıkarmıştı. Başlarında en yaşlıları vardı: Kandilci Başı.',
    'Derler ki Kandilci Başı bir zamanlar bir hayalîydi. Işığı kimseyle bölüşmemek için kandilini kapadı; o gün gölgesini kaybetti.',
    'Ustanın kandili titriyordu. Gece yarısına az kalmıştı.',
  ],
];

const interludesEn = <List<String>>[
  [],
  [
    'When she left the cistern, the city was still burning. Out of the smoke rose the Galata Tower: the Genoese Tower of Christ, the highest eye of Istanbul.',
    'Thirty years ago, in the days of Sultan Murad, a man looked at the sky from this tower. His name was Hezarfen Ahmed Celebi: the one of a thousand sciences.',
    'First, at Okmeydani, with wings like an eagle\'s, he rose against the wind eight or nine times.',
    'Then one morning, when the south wind blew, he let himself go from the top of the tower. Evliya Celebi tells it: he glided over the Bosphorus and came down in Uskudar, on the Square of the Falconers. That day the whole city saw a man become a bird.',
    'The sultan gave him a purse of gold, then said: "This man is to be feared; he can do whatever he wishes." They exiled Hezarfen to Algiers. He saw the sky once, and died far from home.',
    'They say he hid his wings on the top floor of the tower, for someone who is not afraid to fall. Those who fly are exiled, Saye. Fly anyway.',
  ],
  [
    'The wings carried her from the top of the tower into the clouds: the Sky Road, above Istanbul.',
    'Evliya Celebi\'s friend Lagari Hasan Celebi once rose into the sky as well: at Sarayburnu he mounted a seven-branched rocket, and the fire of the powder hurled him into the clouds.',
    'When the fire ran out he fell into the sea, swam to the sultan, and laughed: "The Prophet Jesus sends you his greetings."',
    'The ancients say this road is a bridge seen only by birds and by the dead. At its end lies the edge of the world: Mount Qaf.',
    'The Hoopoe whispered: "The Lamplighters hung their stolen light in the sky; it was they who broke the sun. They carried your master\'s lamp along this road too."',
    'Beyond the clouds a winged horse galloped past: Tulpar, the hero\'s companion. The Sky Road is his road too.',
  ],
  [
    'Where the clouds ended, the edge of the world appeared: a mountain of emerald rock, Qaf.',
    'The ancients said Qaf circles the world like a ring; beyond it there is neither night nor day. On its summit lives the king of the birds, the Simurgh.',
    'Once the birds set out to find their king. The Hoopoe led them: messenger of the Prophet Solomon, the only bird who knew the way. Now it is your guide.',
    'They crossed seven valleys: quest, love, knowledge, detachment, unity, bewilderment and nothingness. Some grew afraid, some grew tired, some settled on a branch along the way and stayed. Only thirty birds reached Qaf.',
    'The Simurgh left three of its feathers on this mountain. Whoever does not find all three cannot see the mirror at the summit.',
  ],
  [
    'At the summit of Qaf there was a mirror. The thirty birds sought the Simurgh; in the mirror they saw themselves. Simurgh, in the old tongue, means "thirty birds".',
    'Saye looked too. There was no child in the mirror. There was a shadow. Saye: in the old tongue, shadow.',
    'The master\'s lamp was not on Qaf. The Lamplighters had carried it east, to the mountain where a light has slept since the Flood: Ararat.',
    'The Armenians call this mountain Masis; the Kurdish shepherds call it Ciyaye Agiri, the fiery mountain, they say. After the Flood the ark came to rest on its shoulder, and humankind was born again there.',
    'No one climbs to its summit. A monk, Saint Hakob, climbed for years to see the ark; every night he fell asleep and woke at the foot of the mountain. At last an angel brought him a plank from the ark: "The summit is forbidden to you, but your seeking will not go unanswered."',
    'An old man with a white beard walked through the blizzard: Ayaz Ata. The weight of winter comes with him.',
    'THE SECOND VEIL · THE MOUNTAIN',
  ],
  [
    'Beneath the glaciers of Ararat lay a vast hull turned to stone: Noah\'s Ark.',
    'The rain fell for forty days and forty nights; for months the ark drifted on dark waters. When the waters fell, it came to rest on the shoulder of this mountain.',
    'Noah first sent out a raven; the raven did not return. Then he sent a dove; the dove came back with an olive branch in its beak: the world was turning green again.',
    'Aboard were two of every creature, and a light that never went out. The Lamplighters went into the hull to take that light; they tore the animals\' shadows from their mates and locked them in the holds.',
    'The shadows are searching for each other, Saye. Bring them together.',
    'A white light rose from the flood water: Ak Ana. The first water had stirred just like this.',
  ],
  [
    'The light from the ark had long since been taken. Saye flew south, beyond the Euphrates: Mount Nemrut, the summit of the old kingdom of Commagene.',
    'King Antiochos had a Persian father and a Greek mother. He brought the gods of two worlds together on one mountain: Zeus with Oromasdes, Apollo with Mithras, Herakles with Artagnes, and set his own throne among them.',
    'He had a hill of stones heaped on the summit and was buried beneath it. Behind the thrones he had it carved: "When my soul rises to the gods, let my body sleep here forever."',
    'But the mountain does not love pride. Earthquakes struck the heads from the bodies; the heads still lie in the snow, facing where the sun rises.',
    'The Lamplighters were carrying the light from the ark through the gods to the eastern terrace. They would kindle it at sunrise.',
  ],
  [
    'On Nemrut, they say, the sun rises twice: once in the sky, and once on the faces of the stone gods. The people named this mountain after Nimrod.',
    'Nimrod wanted to rule the sky. He tied four eagles to a chest and hung meat before them; as the eagles flew after the meat, the chest rose into the heavens.',
    'He shot an arrow at the sky; it came back bloody. "I have struck God," he said. He had Abraham thrown into the fire; the fire turned into a rose garden.',
    'At last a gnat was sent to him. It entered his nose and reached his brain. The king who challenged heaven died after years of having his head struck with a mallet.',
    'On the eastern terrace a giant of stone is waking. Reach it before dawn, Saye: a small light can bring down a great pride.',
    'The bard says: the one-eyed giant Tepegöz was as fearsome as a giant of stone; Basat, who grew up among lions, defeated him.',
  ],
  [
    'When Saye touched the light, for a moment she saw her master.',
    'He was walking in chains in the middle of a caravan, through the snow. His lamp was at his chest; its flame had shrunk to a candle\'s.',
    'With every light of the broken sun they gathered, the Lamplighters drew on the master\'s lamp. The caravan was heading north, to Erzurum.',
    'Erzurum: the Theodosiopolis of the Romans, the Erzen-i Rum of the Seljuks, the fortress of the east. Its winters are so harsh that travelers call it "the gate of winter".',
    'South of the city rises a mountain of steep slopes. Caravan drivers call it Palandoken: on its slopes, they say, pack saddles slid from the animals\' backs and loads spilled into the abyss.',
    'Ahead of the caravan a sky-maned wolf walked through the snow: Gökbörü. So had he led the army of Oghuz.',
    'THE THIRD VEIL · SNOW',
  ],
  [
    'The Snow Road ended. Ahead rose two white peaks: Great Dragon and Little Dragon.',
    'The bard says: when the world was young, two dragon brothers lived on these peaks. In winter they came down to the plain and swallowed flocks and caravans.',
    'One night a dervish climbed to the summit and prayed. Snow fell for seven days and seven nights; the dragons fell asleep beneath it and became the peaks.',
    'Since then the storm is their breath, the fog their sleep. Whoever wakes them, the snow swallows.',
    'The Lamplighters\' caravan was coming down the far slope. Saye had no burden to carry: a jar of light, and a name. Only by skiing could she catch it.',
  ],
  [
    'On the slope of Little Dragon, the Lamplighters held their lanterns to the mountain\'s nose.',
    'A sleeping dragon does not love light. The bard says that while the dragon sleeps, the mountain is silent; when it wakes, the snow flows.',
    'The mountain drew a deep breath.',
    'And the snow flowed.',
    'Before the avalanche ran the sky-maned wolf; he knew the safe way.',
  ],
  [
    'When the avalanche stilled, the caravan had turned west. Saye followed the snows down into Cappadocia; above the village of Muskara the moon was rising.',
    'The ancients called this land Katpatuka; some translate it "the land of beautiful horses". Over ages, rain and wind carved the ashes of Erciyes and Hasan Dagi; the rocks rose to the sky like hooded giants.',
    'The shepherds of Muskara saw lights on the hilltops at night. Fairies, they said: fairies who live atop the chimneys, who once made war on the giants.',
    'The fairy folk leave no shadow, Saye. But they know a shadow when they see one.',
    'But in the shadow of the chimneys a red shade roams as well: Albastı. She steals light, and fears iron.',
    'THE FOURTH VEIL · THE FAIRIES',
  ],
  [
    'From Uchisar, Saye saw the mouth of a well in the middle of the plain. One by one, the Lamplighters\' lanterns were going down into it: Derinkuyu.',
    'A city going eight floors down beneath the earth, with its stables, wine cellars, chapels, wells and breathing shafts. They say twenty thousand souls once hid there until the enemy passed.',
    'The Fairy King had driven the fiery giants underground. Those who dug Derinkuyu built a city on top of the giants\' sleep.',
    'The round stone doors open only from within. Whoever is inside lives. Go down, Saye; but do not wake the sleeper.',
    'A muffled voice comes from the very bottom of the earth. They say Erlik\'s realm lies deeper still.',
  ],
  [
    'When Tulpar brought her down through the clouds, the moon was in the sky, and before her lay an endless snowy plain.',
    'In the west the domes of a city were shining. The Lamplighters had taken the master there: to Konya, capital of the Seljuks, city of Mevlana.',
    'That night was Sheb-i Arus: the night Mevlana died, the wedding night.',
    'Almost four hundred years before, on this night, Mevlana had died. "Do not weep," he had said, "this is my wedding."',
    'The Lamplighters believed that on the wedding night, light cannot die. They had waited for this night to make the master\'s lamp burn forever.',
    'On the plain, upon a hill, a sky-maned wolf was looking at the city.',
    'THE LAST VEIL · THE WEDDING',
  ],
  [
    'The roots of the Tree of Life reach to the very bottom of the earth. Saye slipped down between them; at the very bottom there was a sound: running water.',
    'The bard says: in the beginning there was only water. Kayra Khan was alone above it; he did not know what to create.',
    'A white mother rose from the water: Ak Ana. "Create," she said, and went back into the water.',
    'Kayra Khan created. But one of his creatures, Erlik, thought himself greater; he was cast beneath the earth.',
    'The light the Lamplighters stole was flowing beneath the earth, to Erlik\'s realm. The master had been taken that way too.',
    'The bard says: once a hero named Er Töştük had fallen beneath the earth too. His talking horse Çalkuyruk showed him the way.',
    'Erlik\'s shades roam beneath the earth: the Körmös. They come to the light, and keep stolen lives, the kuts, in cages.',
  ],
  [
    'The bard says: once the forefathers of a people were defeated in a great war; only two heroes, Kıyan and Nüküz, escaped with their wives.',
    'Among the mountains, by a path narrower than a goat track, they took refuge in a valley: Ergenekon. It was full of meadows, rivers, fruit trees and game.',
    'Four hundred years passed; the people multiplied and the valley grew too small. But there was no way out: impassable mountains on every side.',
    'A smith said: "That mountain is iron. Let us pile up wood and coal, set up bellows and melt it." They set up seventy bellows of hide.',
    'The mountain melted, and a road opened wide enough for a laden camel. Some tellings say a grey wolf showed the way.',
    'That day was held sacred: every year on that day a piece of iron was heated in the fire and struck upon the anvil.',
    'The Lamplighters had taken the fire from the valley\'s forge as well. The forge is cold, Saye; the bellows are waiting.',
  ],
  [
    'The bard says: in the Altai, when shamans beat their drums their souls rose into the sky. It is they who tell that the sky has many layers.',
    'On the sixteenth layer of the sky dwells Ülgen: the source of goodness and light. Erlik is his opposite.',
    'In one layer the moon burns cold and soft; in another the stars turn around the Iron Stake.',
    'Two horses are tied to the stake; the Seven Thieves want to steal them. Between the layers blows the Wind Mother.',
    'The Lamplighters had carried a piece of the broken sun to the highest layer of the sky. A shaman beat his drum, and Saye rose above the clouds.',
  ],
  [
    'At the very bottom of Derinkuyu, roots hung between the stones. Saye grasped one; the root drew her upward, toward the light.',
    'When she came out above the earth, day was breaking. Before her lay an endless forest: birches, pines, moss, birdsong.',
    'The Kül Tigin inscription says: the place to hold the realm is the forest of Ötüken; there is no better place.',
    'In the middle of the forest a tree rises to the sky: the Tree of Life. Umay sits on its branches; the souls of children yet to be born perch there as birds.',
    'But Saye was not alone. The thing that first saw her in the dark of the cistern, that crept after her in Derinkuyu, had come up too: the Karabasan.',
    'The Karabasan senses masterless shadows. It settles on them as it settles on a sleeper\'s chest, and devours them. A shadow without its master is the sweetest morsel of all.',
    'But it cannot enter the light. Every beam that slips between the leaves of Ötüken is a refuge for Saye.',
    'THE FIFTH VEIL · ÖTÜKEN',
  ],
  [
    'The Wind Mother set Saye down at the threshold of the sun layer. The shaman\'s drum could no longer be heard.',
    'Beyond the sun layer stood Ülgen\'s gate; the piece of the broken sun was waiting there.',
    'In the sun layer the sun burns. Yet even this high in the sky, Erlik\'s storm was boiling.',
    'They say the shadow of the Huma brings kut to whomever it falls on. And Tulpar carries the hero between the layers of the sky.',
    'The Yakuts know thunder as the voice of Süge Toyon, who hurls lightning at evil spirits. That night the sky was thundering.',
  ],
  [
    'From the roof of the semahane Saye looked at the Green Dome. The light of centuries was overflowing from within.',
    'The Lamplighters had carried the master to the top of the dome, to the foot of the finial. At their head was the eldest of them: the Chief Lamplighter.',
    'They say the Chief Lamplighter was once a shadow master himself. To share the light with no one, he closed his lamp; that day he lost his shadow.',
    'The master\'s lamp was flickering. It was nearly midnight.',
  ],
];

/// Oynanış sırası. Bölümün kimliği `levels` listesindeki yeridir ve hiç
/// değişmez (kayıt, hatıralar, görülen olaylar bu kimlikle tutulur); yeni
/// bölümler listenin sonuna eklenir, oynanıştaki yerlerine bu sırada girer.
const levelOrder = <int>[
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 14, 15, 16, 18, 13, 19, //
];

/// Sıra değişince artar: kayıttaki "açılan en ileri bölüm" (sıradaki yer)
/// eski sıradan yenisine çevrilir.
const levelOrderVersion = 7;

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
    'Sâye sütunların ormanında yürüdü. Karanlık suyun içinden bir su iyesi belirdi; ince eliyle paslı bir vanayı gösterdi.',
    'Sütunların dibinde Medusa\'nın taş başları yatıyordu: biri baş aşağı, biri yan. Bakışlarına gölgesini değdirmeden geçti.',
    'Bir salın üstünde karanlık kanallardan süzüldü. Suyun bittiği yerde yukarıya, yanan şehre açılan bir merdiven vardı.',
  ],
  [
    'Kulenin mahzeninden kat kat yukarı tırmandı. Kandilcilerin gözcüleri soğuk fenerleriyle her katı tarıyordu; Sâye gölgeden gölgeye geçti.',
    'Hezarfen\'in atölyesinde tozlu bir sandık buldu. İçinde kartal tüyünden iki kanat duruyordu.',
    'Çan katını geçti, külahın tepesine çıktı. Aşağıda Haliç bir ayna gibi parlıyordu. Korkmadan kendini boşluğa bıraktı.',
  ],
  [
    'Rüzgâr yolunda kanatlarını açtı; kargaların adalarını, Kandilcilerin bulut kampını geride bıraktı.',
    'Fırtına adalarında şimşek perdeyi yaktı. Sâye gölgeden örülmüş bir köprünün üstünden uçtu.',
    'Bulutların ardında Tulpar\'ın yelesi bir an parladı. Önde güneşin kapısı açılıyordu.',
  ],
  [
    'Zümrüt köprüden geçti. Kandilcilerin gök karakolunun önünden gölgesini rüzgâra verip süzüldü.',
    'Simurg\'un üç tüyünü birer birer buldu; her tüye dokunduğunda dağın bir yerinde bir kuş öttü.',
    'Üçüncü tüyle ayna salonunun kapısı açıldı.',
  ],
  [
    'Dağın eteğinden iplere tutunarak tırmandı; tipi yüzüne vuruyordu. Terk edilmiş bir ağılda soluklandı.',
    'Akori\'de, Nuh\'un diktiği söylenen bağın yanından geçti. Aziz Hakob\'un manastırında Ayaz Ata\'nın ak gölgesi önünden yürüdü.',
    'Buz mağarasının dibinde tufanın eşiği açıldı.',
  ],
  [
    'Ambarlarda aslanların, atların, kuşların gölgeleri eşlerini arıyordu. Sâye kilitleri açtı; eşler birbirine kavuştu.',
    'Ambar kuyusunun dibinde Ak Ana sudan ona baktı. Su yükseldi, Sâye\'yi güverteye taşıdı.',
    'Güvertede ışığın yeri boştu; Kandilciler onu çoktan götürmüştü.',
  ],
  [
    'Batı terasında başsız tanrıların arasından geçti. Deprem yarıkları ayağının altında açılıp kapandı.',
    'Kartalın gözünden, tümülüsün taşlarından doğuya bir geçit buldu.',
  ],
  [
    'Doğu terasında taştan dev uyandı; her adımında dağ sarsıldı. Sâye onun gölgesinden gölgesine kaçtı.',
    'Güneş taş yüzlere vurduğu an Kandilcilerin yakmak üzere olduğu ışığa uzandı.',
  ],
  [
    'Kervan yolunda Gökbörü önden yürüdü. Sâye onun izlerine basarak kurtların ormanını geçti.',
    'Donmuş gölün üstünden, ocağı sönmüş bir hanın önünden geçti; ejderin eteğine vardı.',
  ],
  [
    'Çoban kulübesinde tahtadan bir kızak buldu ve kendini ejderin sırtından aşağı bıraktı.',
    'Kandil balonlarının altından, manyetik tepenin üstünden kaydı; ejderin sıçrayışından uçup Erzurum\'a doğru indi.',
  ],
  [
    'Ejder uyandı; beyaz nefesi Sâye\'nin ardından aktı.',
    'Gökbörü önde koştu. Sâye kırık sırttan son kez atladı, bir sığınağa girdi; çığ başının üstünden geçip gitti.',
  ],
  [
    'Muşkara\'dan peri bacalarına tırmandı. Güvercinliklerin, kaya kiliselerinin arasında perilerin dansını gördü.',
    'Albastı kızıl gölgesiyle ışığını çalmaya geldi. Sâye demirin ardına sığındı; Albastı demirden korkar.',
    'Ay doğarken Uçhisar\'ın tepesine vardı.',
  ],
  [
    'Mahzenden şapele, havalandırma bacalarından derin kuyuya indi. Yuvarlak taş kapılar onu içeriden kabul etti.',
    'Devlerin kapısında uyuyan dev uyandı ve peşine düştü; karanlıkta Gökbörü\'nün gözleri ona yolu gösterdi.',
    'En dipte taşın arasından kökler sarkıyordu; yukarıdan yaprak kokusu geliyordu.',
  ],
  [
    'Konya ovasından eski höyüğe, İkonion kapısından Alâeddin Tepesi\'ne yürüdü.',
    'Karatay\'ın yıldızlı kubbesinin altından, İnce Minare\'nin yanından, Şems\'in kuyusundan geçti. Semâhanede semâzenler dönüyordu.',
    'Kar yağıyordu. Sâye Yeşil Kubbe\'ye tırmandı.',
  ],
  [
    'Kara kapıdan geçti. Mürekkep köprülerde Körmösler ışığını kokladı; Sâye karanlığa saklandı.',
    'Kut zindanında kafesleri açtı; çalınan canlar kuş olup yukarı uçtu.',
    'Çalkuyruk kuyusunun dibinde Er Töştük\'ün atı başını kaldırdı ve ona yukarı giden yolu gösterdi.',
  ],
  [
    'Kıyan Boğazı\'ndan demir dağın dibine indi. Kömür sandıklarını ocağa itti, körükleri ritimle bastı; ocak yeniden yandı.',
    'Akan demir dalga dalga geldi. Sisli çayırın adacıklarından geçti; Asena\'nın mağarasında boz kurdun gözleri parladı.',
    'Demir dağın içinden yol açtı. Nevruz örsüne üç kez vurdu; kapı açıldı.',
  ],
  [
    'Kamın davulu çaldıkça bulut kapısından ay katına, ay katından yıldız katına yükseldi.',
    'Demir Kazık\'ın atlarına tutunup Yedi Karakçı\'nın arasından geçti; yada taşıyla Yel Ana\'ya yön verdi.',
  ],
  [
    'Kökler onu yerin altından Ötüken\'in yeşiline çıkardı. Yaprakların arasından düşen ışıkta yürüdü; gölgede Karabasan\'ın gözleri açılıp kapandı.',
    'Kam\'ın davulu vurdukça kökler kalktı; sarmaşıklara tutunup dikenli yarları aştı. Ak bir geyik ateşböceklerinin ışığını izleyip kök kapılarını açtı.',
    'Kara Bataklık\'ta Karabasan bütün gücüyle saldırdı. Sâye Hayat Ağacı\'na tırmandı, güneşi aynalarla aşağı indirdi; ışık köklere aktı, Karabasan dağıldı.',
  ],
  [
    'Hüma\'nın gölgesi başına düştü. Süge Toyon\'un yıldırımlarının ışığında kara bulutlara bastı.',
    'Ülgen\'in kapısında Tulpar onu bekliyordu.',
  ],
  [
    'Şadırvanın havuzuna düşen ayı aynalarla türbenin gümüş kapısına taşıdı.',
    'Kandiller koridorunda kafesleri açtı; çalınan ışıklar sahiplerini hatırlayıp kavanozuna girdi.',
    'Kubbenin yeşil kaburgalarına tırmandı; aşağıda biriken ışık taşıyordu.',
    'Tepede üç aynayı çevirdi. Kandilci Başı yüzyıllar sonra ilk kez kendi gölgesini gördü.',
  ],
];

const bridgesEn = <List<String>>[
  [
    'Saye walked through the forest of columns. A water spirit rose from the dark water and pointed her slender hand at a rusted valve.',
    'At the foot of the columns lay Medusa\'s stone heads: one upside down, one on its side. She passed without letting her shadow touch their gaze.',
    'On a raft she drifted through the dark channels. Where the water ended, a stair rose toward the burning city.',
  ],
  [
    'From the tower\'s cellar she climbed floor by floor. The Lamplighters\' watchmen swept every floor with cold lanterns; Saye slipped from shadow to shadow.',
    'In Hezarfen\'s workshop she found a dusty chest. Inside lay two wings of eagle feathers.',
    'She passed the bell floor and climbed to the top of the cone. Below, the Golden Horn shone like a mirror. Without fear, she let herself fall.',
  ],
  [
    'On the wind road she spread her wings and left behind the islands of crows and the Lamplighters\' cloud camp.',
    'Over the storm islands lightning lit the screen. Saye flew across a bridge woven of shadow.',
    'Beyond the clouds Tulpar\'s mane flashed for a moment. Ahead, the gate of the sun was opening.',
  ],
  [
    'She crossed the emerald bridge and glided past the Lamplighters\' sky outpost, giving her shadow to the wind.',
    'One by one she found the Simurgh\'s three feathers; each time she touched one, a bird sang somewhere on the mountain.',
    'With the third feather, the door of the mirror hall opened.',
  ],
  [
    'From the foot of the mountain she climbed along the ropes, the blizzard in her face. She rested in an abandoned sheepfold.',
    'At Akori she passed the vineyard Noah is said to have planted. At Saint Hakob\'s monastery she walked past the white shadow of Ayaz Ata.',
    'At the bottom of the ice cave, the threshold of the Flood opened.',
  ],
  [
    'In the holds the shadows of lions, horses and birds were searching for their mates. Saye opened the locks; the pairs found each other.',
    'At the bottom of the hold well, Ak Ana looked up at her from the water. The water rose and carried Saye to the deck.',
    'On the deck the place of the light was empty; the Lamplighters had long since taken it.',
  ],
  [
    'On the western terrace she passed among the headless gods. Earthquake rifts opened and closed beneath her feet.',
    'Through the eagle\'s eye and the stones of the tumulus she found a passage east.',
  ],
  [
    'On the eastern terrace the stone giant woke; the mountain shook with every step. Saye fled from one of its shadows to the next.',
    'The moment the sun struck the stone faces, she reached for the light the Lamplighters were about to kindle.',
  ],
  [
    'On the caravan road Gokboru walked ahead. Saye stepped in its tracks through the forest of wolves.',
    'She crossed the frozen lake, passed an inn whose hearth had gone cold, and reached the foot of the dragon.',
  ],
  [
    'In the shepherd\'s hut she found a wooden sled and let herself go down the dragon\'s back.',
    'She slid beneath the lantern balloons and over the magnetic hill, flew from the dragon\'s leap and came down toward Erzurum.',
  ],
  [
    'The dragon woke; its white breath poured after Saye.',
    'Gokboru ran ahead. Saye leapt from the broken ridge one last time and slipped into a shelter; the avalanche passed over her head.',
  ],
  [
    'From Mushkara she climbed the fairy chimneys. Among the dovecotes and rock churches she saw the fairies dance.',
    'Albasti came with her red shadow to steal her light. Saye took refuge behind iron; Albasti fears iron.',
    'As the moon rose she reached the top of Uchisar.',
  ],
  [
    'From the cellar to the chapel, through the air shafts, she went down into the deep well. The round stone doors let her in from the inside.',
    'At the giants\' gate the sleeping giant woke and gave chase; in the dark, Gokboru\'s eyes showed her the way.',
    'At the very bottom, roots hung between the stones; a smell of leaves came from above.',
  ],
  [
    'She walked from the plain of Konya to the old mound, through the gate of Iconium to the Hill of Alaeddin.',
    'She passed beneath the starry dome of the Karatay, beside the Slender Minaret, past the well of Shams. In the semahane the semazens were turning.',
    'Snow was falling. Saye climbed the Green Dome.',
  ],
  [
    'She passed the black gate. On the ink bridges the Kormos sniffed at her light; Saye hid in the dark.',
    'In the dungeon of kut she opened the cages; the stolen souls became birds and flew upward.',
    'At the bottom of Chalkuyruk\'s well, Er Toshtuk\'s horse raised its head and showed her the way up.',
  ],
  [
    'Through Kiyan Gorge she went down to the foot of the iron mountain. She pushed the coal crates into the forge and pressed the bellows in rhythm; the forge burned again.',
    'Molten iron came in waves. She crossed the islets of the misty meadow; in Asena\'s cave the eyes of the grey wolf shone.',
    'She opened a way through the iron mountain. She struck the Nevruz anvil three times; the gate opened.',
  ],
  [
    'With every beat of the shaman\'s drum she rose from the cloud gate to the moon layer, and from the moon layer to the star layer.',
    'Holding on to the horses of the Iron Stake she slipped between the Seven Thieves; with a yada stone she told the Wind Mother which way to blow.',
  ],
  [
    'The roots brought her up from beneath the earth into the green of Ötüken. She walked in the light falling between the leaves; in the shadow the Karabasan\'s eyes opened and closed.',
    'With every beat of the shaman\'s drum the roots rose; she swung on the vines across thorny ravines. A white deer followed the light of her fireflies and opened the root gates.',
    'In the Black Marsh the Karabasan attacked with all its strength. Saye climbed the Tree of Life and brought the sun down with mirrors; the light flowed to the roots, and the Karabasan scattered.',
  ],
  [
    'The Huma\'s shadow fell upon her. By the light of Süge Toyon\'s lightning she stepped on the black clouds.',
    'At Ülgen\'s gate, Tulpar was waiting for her.',
  ],
  [
    'With mirrors she carried the moon fallen into the fountain\'s pool to the tomb\'s silver door.',
    'In the corridor of lamps she opened the cages; the stolen lights remembered their owners and entered her jar.',
    'She climbed the green ribs of the dome; the light gathered below was overflowing.',
    'At the top she turned three mirrors. For the first time in centuries, the Chief Lamplighter saw his own shadow.',
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
    ],
    memories: [
      'Hatıra · "Haliç bir aynadır," derdi ustam. "Şehir kendine orada bakar."',
      'Hatıra · Kulenin tepesini gösterip "Bir gün oradan bütün perdeyi göreceksin," demişti.',
      'Hatıra · Gözcülerin ışığı soğuktur; çünkü onlar ışığı sevmez, sayar.',
      'Hatıra · Ustam o gün Doğancılar\'daki kalabalığın içinde bir çocukmuş. "Herkes kanatlara baktı," derdi, "ben onun yüzüne baktım. Korkmuyordu. Gölgesi denizin üstünde bir kuş gibi kayıp gidiyordu."',
      'Hatıra · Kuleden şehre bakarken sorardı: "Bunca ışığın gölgesi nereye düşer?"',
    ],
    memoriesEn: [
      'Memory · "The Horn is a mirror," he said. "The city looks at itself there."',
      'Memory · He pointed at the top of the tower: "One day you will see the whole screen from there."',
      'Memory · The Watchers\' light is cold, for they do not love the light; they count it.',
      'Memory · That day my master was a child in the crowd at the Square of the Falconers. "Everyone looked at the wings," he said, "I looked at his face. He was not afraid. His shadow slid over the sea like a bird."',
      'Memory · Looking down at the city from the tower he would ask: "Where do the shadows of all these lights fall?"',
    ],
    place: 'Galata Kulesi · İstanbul, Temmuz 1660',
    placeEn: 'Galata Tower · Istanbul, July 1660',
    areas: [
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
      'The Gate of the Sun',
    ],
    map: kMapGokyolu,
    // Kandilcilerin gök kampında boşluk: yol fenerle belirir.
    coldRuns: [(312, 8, 8)],
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
    title: 'XIX · ŞEB-İ ARÛS',
    legends: ['sebiArus'],
    bard: 'Ozan der ki: Dönen döner, gölge düşer; kim dönerse yolunu bulur.',
    bardEn: 'The bard says: the whirling turn, the shadows fall; whoever turns finds the way.',
    gokboruGuard: true,
    subtitle: 'Bu gece ölüm bir düğündür.',
    theme: LevelTheme.konya,
    wings: true,
    titleEn: 'XIX · SHEB-I ARUS',
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
    title: 'XV · ERLİK\'İN KATI',
    subtitle: 'Yerin altında ışık tehlikeli, karanlık güvenlidir.',
    titleEn: 'XV · ERLIK\'S REALM',
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
    title: 'XVI · ERGENEKON',
    subtitle: 'Dört yanı dağ; çıkış demirin içinden.',
    titleEn: 'XVI · ERGENEKON',
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
    title: 'XVII · GÖĞÜN KATLARI',
    subtitle: 'Her kat bir öncekinden aydınlık.',
    titleEn: 'XVII · THE LAYERS OF THE SKY',
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
    title: 'XVIII · ÜLGEN\'İN KAPISI',
    subtitle: 'Işığın kaynağına, fırtınanın içinden.',
    titleEn: 'XVIII · ÜLGEN\'S GATE',
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
    title: 'XX · YEŞİL KUBBE',
    legends: ['sebiArus'],
    bard: 'Ozan der ki: Işık bölünmeye razıdır; sahiplenilmeye razı olmaz.',
    bardEn: 'The bard says: light consents to be shared; it never consents to be owned.',
    subtitle: 'Kandil sönerken gölge ışığa karışır.',
    subtitleEn: 'As the lamp goes out, the shadow joins the light.',
    theme: LevelTheme.konya,
    wings: true,
    titleEn: 'XX · THE GREEN DOME',
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
];
