// Bölüm haritaları ve hikâye metinleri.
//
// Harita gösterimi: lib/game/level.dart başındaki açıklamaya bakın.

import 'maps.dart';
import 'strings.dart';

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
  konya;

  /// Kapalı mekân: tavanın üstü kaya, uzaktan zincir sesleri.
  bool get indoor => this == cistern || this == cave || this == ark;

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
    this.magnet = const [],
    this.titleEn = '',
    this.subtitleEn = '',
    this.whispersEn = const [],
    this.memoriesEn = const [],
    this.place = '',
    this.placeEn = '',
    this.areas = const [],
    this.areasEn = const [],
  });

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

  /// Ara ara deprem olur: yer sarsılır, gevşek kayalar düşer.
  final bool quakes;

  /// Aynı temanın farklı görünümü (ör. kar: 0 Ağrı, 1 Palandöken, 2 çığ;
  /// Nemrut: 0 taş tanrılar, 1 gün doğumu).
  final int variant;

  final String title;
  final String subtitle;
  final LevelTheme theme;
  final List<String> map;

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
  'GÖLGE OYUNU',
];

const prologueEn = [
  'Istanbul, July 1660. The city had been burning for two days.',
  'The Lamplighters\' Guild walked among the ashes, gathering every lamp, every candle, every light in every eye.',
  'Last, they came to Master Hayali\'s screen. They snuffed his lamp and took him away.',
  'The screen went dark. But one shadow fell from it before the light died.',
  'SHADOW PLAY',
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
  'His master was there, grown old and small. The Lamplighters stood in a ring around him, holding their lanterns toward the lamp.',
  '"You came," said the master. "I knew it. No prayer goes unanswered."',
  'The Lamplighters had gathered all the light, and so they had lost their shadows. The master\'s lamp was the only light that gave shadows life. When they had tried to hang the sun for themselves alone, the sun had broken; now they meant to kindle it again with this lamp.',
  '"They brought me here so my lamp would not go out," said the master. "To Mevlana\'s wedding night. They believe light cannot die tonight."',
  '"They are right, Saye. Tonight light does not die. It only reunites."',
  'From the semahane rose the sound of the ney. The master placed the lamp in Saye\'s hands.',
  '"You were never my shadow. You were my prayer. My companion, my road, my hemzat. Now it is your turn to hold the light."',
  'The lamp went out.',
  'The screen went dark. For a moment nothing remained: neither master nor shadow.',
  'Then a light was born from within Saye. The shadow had not vanished; it had joined the light.',
  'All the light the Lamplighters had hoarded for centuries turned toward that light and rose into the sky. The Lamplighters looked at the shadows falling on the snow, and wept.',
  'The Hoopoe landed on Saye\'s shoulder: "Only one piece of the broken sun was here. The others are scattered to the four corners of the world."',
  'Saye looked beyond the screen. As if the snow had only just fallen, a road stretched out before him.',
  'In the wind, his master\'s voice: "Walk on, Saye. The road does not end; the one who walks it changes."',
  'SAYE\'S JOURNEY WILL CONTINUE',
];

List<String> get epilogueText => S.en ? epilogueEn : epilogue;

/// Bölüm aralarında perdede oynanan gölge oyunu sahneleri: her bölümden
/// önce (indeks = bölüm). Satırlar sırayla, perdedeki tasvirlerle birlikte.
const interludes = <List<String>>[
  [],
  [
    'Sarnıçtan çıktığında şehir hâlâ yanıyordu.',
    'Galata\'nın tepesinde bir zamanlar bir adam kanat takmış, göğe atlamıştı.',
    'Onu alkışladılar. Sonra korktular. Sonra sürdüler.',
    'Uçanlar sürgün edilir, Sâye. Yine de uç.',
  ],
  [
    'Bulutların ardında, Kaf Dağı\'na giden bir yol vardır.',
    'Hüdhüd kuşları oraya, Simurg\'a götürdü. Çoğu yolda vazgeçti.',
    'Kandilciler topladıkları ışığı göğe astı; güneşi onlar kırdı.',
    'Ustanın kandili orada, Sâye. Ve sen her adımda ona biraz daha benziyorsun.',
  ],
  [],
  [
    'Kaf\'ın tepesinde bir ayna vardı. Kuşlar Simurg\'u aradı; aynada kendilerini gördüler.',
    'Sâye de baktı. Aynada bir çocuk yoktu. Bir gölge vardı.',
    'Sâye. Eski dilde gölge demektir.',
    'Ustanın kandili Kaf\'ta değildi. Kandilciler onu doğuya, tufandan beri sönmeyen ışığın yattığı dağa götürmüştü.',
    'İKİNCİ PERDE · DAĞ',
  ],
  [
    'Ağrı\'nın buzullarının altında, taşa dönmüş kocaman bir gövde yatıyordu.',
    'Tufan kırk gün kırk gece yağmış. Sular çekilince gemi bu dağın omzuna oturmuş.',
    'Nuh önce bir kuzgun salmış; kuzgun dönmemiş. Sonra bir güvercin salmış; güvercin gagasında bir zeytin dalıyla dönmüş.',
    'Gemide tufandan beri hiç sönmeyen bir ışık varmış. Kandilciler onu almak için gövdeye girdi. Peşlerinden git, Sâye.',
  ],
  [
    'Gemideki ışık çoktan götürülmüştü. Sâye güneye, Fırat\'ın ötesine uçtu: karlı bir zirveye.',
    'Orada taş tanrılar oturuyordu; aralarında bir de kral. Kommagene Kralı Antiochos tanrılarla yan yana oturmak istemişti.',
    'Ama tanrılar kibri sevmez. Bir gün dağ sarsıldı; başlar gövdelerden koptu, kara düştü.',
    'Kandilciler gemiden aldıkları ışığı tanrıların arasından doğu terasına taşıyordu. Güneş doğunca yakacaklardı.',
  ],
  [
    'Nemrut\'ta güneş iki kez doğar, derler: bir kez gökte, bir kez de taş tanrıların yüzünde.',
    'Ama gökte kırık bir güneş vardı. Kandilciler bu sabahın ışığını da kendilerine ayırmıştı.',
    'Doğu terasında bir dev uyanıyordu: Nemrud. Bir zamanlar göğe ok atan, bir sivrisinekle yenilen kral.',
    'Şafaktan önce doğu terasına yetiş, Sâye.',
  ],
  [
    'Sâye ışığa dokunduğunda bir an ustasını gördü.',
    'Bir kervanın ortasında, zincirli, karın içinde yürüyordu. Kandili göğsündeydi; alevi bir mum kadar kalmıştı.',
    'Kandilciler kırık güneşin ışıklarını topladıkça ustanın kandilinden çekiyorlardı. Kervan kuzeye, Erzurum\'a gidiyordu.',
    'Önde dik yokuşlu bir dağ vardı. Kervancılar ona Palandöken der.',
    'ÜÇÜNCÜ PERDE · KAR',
  ],
  [
    'Kar Yolu bitti. Önde iki beyaz doruk yükseliyordu: Büyük Ejder ve Küçük Ejder.',
    'Bu dağın yokuşlarında palanlar hayvanların sırtından kayar, yükler uçuruma dökülürmüş. Dağ, taşınan yükü sevmez.',
    'Sâye\'nin taşıyacak yükü yoktu: bir kavanoz ışık, bir de bir isim.',
    'Kandilcilerin kervanı karşı yamaçtan iniyordu. Ancak kayarak yetişebilirdi.',
  ],
  [
    'Kandilciler fenerlerini Küçük Ejder\'in burnuna tuttu. Dağ derin bir nefes aldı.',
    'Erzurum\'un yaşlıları der ki Ejder uyurken dağ susar; uyandığında kar akar.',
    'Ve kar aktı.',
  ],
  [
    'Çığ dindiğinde kervan batıya dönmüştü. Sâye karların ardından Kapadokya\'ya indi.',
    'Burada kayalar insan elinden önce rüzgârla ve külle oyulmuştu. Bacalar ay ışığında başlıklı devler gibi duruyordu.',
    'Muşkara köyünün çobanları geceleri tepelerde ışıklar görürdü. Periler, derlerdi; periler ve onların devlerle savaşı.',
    'Peri halkı gölge bırakmaz, Sâye. Ama gölgeyi tanır.',
    'DÖRDÜNCÜ PERDE · PERİLER',
  ],
  [
    'Uçhisar\'dan bakınca Sâye ovanın ortasında bir kuyu ağzı gördü. Kandilcilerin fenerleri birer birer içine iniyordu.',
    'Peri Padişahı ateşli devleri yerin altına sürmüştü. Derinkuyu\'yu kazanlar, devlerin uykusunun üstüne bir şehir kurmuştu.',
    'Yuvarlak taş kapılar yalnızca içeriden açılır. İçeride olan yaşar.',
    'Aşağı in, Sâye. Ama uyuyanı uyandırma.',
  ],
  [
    'Derinkuyu\'nun dibinden çıktığında gökte ay vardı; önünde uçsuz bucaksız, karlı bir ova.',
    'Batıda bir şehrin kubbeleri parlıyordu. Kandilciler ustayı oraya götürmüştü: Konya\'ya.',
    'O gece on yedi Aralık\'tı. Konya\'da bu geceye Şeb-i Arûs derler: düğün gecesi.',
    'Neredeyse dört yüz yıl önce bu gece Mevlânâ ölmüştü. "Ağlamayın," demişti, "bu benim düğünümdür."',
    'Kandilciler sanıyordu ki düğün gecesinde ışık ölmez. Ustanın kandilini sonsuza dek yakmak için bu geceyi bekliyorlardı.',
    'SON PERDE · DÜĞÜN',
  ],
];

const interludesEn = <List<String>>[
  [],
  [
    'When he left the cistern, the city was still burning.',
    'Once, atop Galata, a man strapped on wings and leapt into the sky.',
    'They cheered him. Then they feared him. Then they sent him away.',
    'Those who fly are exiled, Saye. Fly anyway.',
  ],
  [
    'Beyond the clouds there is a road to Mount Qaf.',
    'The Hoopoe led the birds there, to the Simurgh. Most gave up on the way.',
    'The Lamplighters hung their stolen light in the sky; it was they who broke the sun.',
    'Your master\'s lamp is there, Saye. And with every step, you look more like it.',
  ],
  [],
  [
    'At the summit of Qaf there was a mirror. The birds sought the Simurgh; in the mirror they saw themselves.',
    'Saye looked too. There was no child in the mirror. There was a shadow.',
    'Saye. In the old tongue, it means shadow.',
    'The master\'s lamp was not on Qaf. The Lamplighters had carried it east, to the mountain where a light has slept since the Flood.',
    'THE SECOND VEIL · THE MOUNTAIN',
  ],
  [
    'Beneath the glaciers of Ararat lay a vast hull turned to stone.',
    'The Flood rained for forty days and forty nights. When the waters fell, the ship came to rest on the shoulder of this mountain.',
    'Noah first sent out a raven; the raven did not return. Then he sent a dove; the dove came back with an olive branch in its beak.',
    'Aboard was a light that had never gone out since the Flood. The Lamplighters went into the hull to take it. Follow them, Saye.',
  ],
  [
    'The light from the ship had long since been taken. Saye flew south, beyond the Euphrates, to a snowy summit.',
    'There sat gods of stone, and among them a king. Antiochos, King of Commagene, had wanted to sit side by side with the gods.',
    'But the gods do not love pride. One day the mountain shook; the heads broke from the bodies and fell into the snow.',
    'The Lamplighters were carrying the light from the ship through the gods to the eastern terrace. They would kindle it at sunrise.',
  ],
  [
    'On Nemrut, they say, the sun rises twice: once in the sky, and once on the faces of the stone gods.',
    'But the sun in the sky was broken. The Lamplighters had claimed this morning\'s light for themselves as well.',
    'On the eastern terrace a giant was waking: Nimrod. The king who once shot arrows at heaven and was defeated by a gnat.',
    'Reach the eastern terrace before dawn, Saye.',
  ],
  [
    'When Saye touched the light, for a moment he saw his master.',
    'He was walking in chains in the middle of a caravan, through the snow. His lamp was at his chest; its flame had shrunk to a candle\'s.',
    'With every light of the broken sun they gathered, the Lamplighters drew on the master\'s lamp. The caravan was heading north, to Erzurum.',
    'Ahead rose a mountain of steep slopes. The caravan drivers call it Palandoken.',
    'THE THIRD VEIL · SNOW',
  ],
  [
    'The Snow Road ended. Ahead rose two white peaks: Great Dragon and Little Dragon.',
    'On these slopes, pack saddles slid from the animals\' backs and loads spilled into the abyss. The mountain does not love a burden.',
    'Saye had no burden to carry: a jar of light, and a name.',
    'The Lamplighters\' caravan was coming down the far slope. Only by skiing could he catch it.',
  ],
  [
    'The Lamplighters held their lanterns to Little Dragon\'s nose. The mountain drew a deep breath.',
    'The elders of Erzurum say that while the Dragon sleeps, the mountain is silent; when it wakes, the snow flows.',
    'And the snow flowed.',
  ],
  [
    'When the avalanche stilled, the caravan had turned west. Saye followed the snows down into Cappadocia.',
    'Here the rocks had been carved by wind and ash before any human hand. In the moonlight the chimneys stood like hooded giants.',
    'The shepherds of Muskara saw lights on the hilltops at night. Fairies, they said; fairies, and their war with the giants.',
    'The fairy folk leave no shadow, Saye. But they know a shadow when they see one.',
    'THE FOURTH VEIL · THE FAIRIES',
  ],
  [
    'From Uchisar, Saye saw the mouth of a well in the middle of the plain. One by one, the Lamplighters\' lanterns were going down into it.',
    'The Fairy King had driven the fiery giants underground. Those who dug Derinkuyu built a city on top of the giants\' sleep.',
    'The round stone doors open only from within. Whoever is inside lives.',
    'Go down, Saye. But do not wake the sleeper.',
  ],
  [
    'When he climbed out of the depths of Derinkuyu, the moon was in the sky, and before him lay an endless snowy plain.',
    'In the west the domes of a city were shining. The Lamplighters had taken the master there: to Konya.',
    'That night was the seventeenth of December. In Konya they call this night Sheb-i Arus: the wedding night.',
    'Almost four hundred years before, on this night, Mevlana had died. "Do not weep," he had said, "this is my wedding."',
    'The Lamplighters believed that on the wedding night, light cannot die. They had waited for this night to make the master\'s lamp burn forever.',
    'THE LAST VEIL · THE WEDDING',
  ],
];

List<String> interludeText(int level) {
  final all = S.en ? interludesEn : interludes;
  return level < all.length ? all[level] : const [];
}

const levels = <LevelDef>[
  LevelDef(
    title: 'I · YEREBATAN',
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
      'Medusa\'nın başlarını ters koymuşlar, kimse taşa dönmesin diye. Bu ikisini ters koymayı unutmuşlar.',
      'Perseus ona hiç doğrudan bakmadı. Cilalı kalkanında gördü ve yürüdü.',
      'Bu sular bin yıl şehre su taşıdı. Şimdi bir gölge taşıyor.',
    ],
    whispersEn: [
      'Saye… Is that the master\'s voice, or the water\'s?',
      'Whatever the lantern touches, it takes. Keep to the dark.',
      'They turned her head so no one would become stone. Learn to see without looking.',
      'Doors open to patience, not to force.',
      'Do not wake those who sleep above. Every sound is a confession.',
      'One must sink so the other may rise. So the scales of the world were set.',
      'Some paths show themselves only to the light. Some, only to the dark.',
      'Rotten wood will bear you. It will not bear one heavier.',
      'Water too is a door: first it empties, then it lifts.',
      'They laid Medusa\'s heads upside down so no one would turn to stone. These two, they forgot.',
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
  ),
  LevelDef(
    title: 'II · KULE',
    subtitle: 'Yükseldikçe ışık soğur.',
    theme: LevelTheme.cliffs,
    titleEn: 'II · THE TOWER',
    subtitleEn: 'The higher you climb, the colder the light.',
    whispers: [
      'Haliç\'in suları her şeyi hatırlar; düşenleri de.',
      'Basınca kopan taşlar var. Hiçbir yer seni uzun süre taşımaz.',
      'Damlarda bir Kandilci dolaşıyor. Kargalar onun gözleridir.',
      'Kanatlar burada bekliyordu. Rüzgâra teslim ol.',
      'Hezarfen\'in merceği ışığı toplar. Bir aynayla onu dilediğin göze çevir.',
      'Galata\'nın altında mahzenler yanıyor. Alevin de bir nefesi var; dinle.',
      'Bir sandık bir alevi susturur. Hangisini susturacağını iyi seç.',
      'Kulenin çanını rüzgâr çalar. Bir kez de sen çal; Kandilciler sese gelir.',
    ],
    whispersEn: [
      'The waters of the Horn remember everything, even those who fall.',
      'Some stones break beneath you. Nothing holds you for long.',
      'A Lamplighter walks the rooftops. The crows are his eyes.',
      'The wings were waiting here. Surrender to the wind.',
      'Hezarfen\'s lens gathers the light. With a mirror, turn it on any eye you choose.',
      'Beneath Galata the cellars are burning. Fire breathes too; listen.',
      'One crate can silence one flame. Choose well which.',
      'The wind rings the tower bell. Ring it once yourself; the Lamplighters come to its voice.',
    ],
    memories: [
      'Hatıra · "Haliç bir aynadır," derdi ustam. "Şehir kendine orada bakar."',
      'Hatıra · Kulenin tepesini gösterip "Bir gün oradan bütün perdeyi göreceksin," demişti.',
      'Hatıra · Gözcülerin ışığı soğuktur; çünkü onlar ışığı sevmez, sayar.',
      'Hatıra · Ustam Hezarfen\'i görmüş. "Kanatları vardı," derdi, "ama asıl cesareti vardı."',
      'Hatıra · Kuleden şehre bakarken sorardı: "Bunca ışığın gölgesi nereye düşer?"',
    ],
    memoriesEn: [
      'Memory · "The Horn is a mirror," he said. "The city looks at itself there."',
      'Memory · He pointed at the top of the tower: "One day you will see the whole screen from there."',
      'Memory · The Watchers\' light is cold, for they do not love the light; they count it.',
      'Memory · My master once saw Hezarfen. "He had wings," he said, "but what he really had was courage."',
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
  ),
  LevelDef(
    title: 'III · GÖKYOLU',
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
      'Şimşek çakınca her şey görünür; sen de.',
      'Kırık güneşin kapısı. Kandilciler onu kimseye açmaz.',
    ],
    whispersEn: [
      'A shard of the broken sun… Its warmth is familiar.',
      'Lamplighters here too. Even the sky is theirs.',
      'The sky is not as empty as you thought.',
      'The wind will carry you, so long as you do not let go.',
      'The Lamplighters hung their lanterns from balloons. They have eyes in the sky as well.',
      'A bridge made of shadow: touch it with light and it scatters. Guard its darkness.',
      'When the lightning strikes, everything is seen; you too.',
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
  ),
  LevelDef(
    title: 'IV · KAF',
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
      'Simurg\'un Tüyleri',
      'Simurg\'un Ayna Salonu',
    ],
    areasEn: [
      'The Emerald Bridge',
      'The Lamplighters\' Sky Post',
      'The Shadow Bridge',
      'The Back of the Wind',
      'The Feathers of the Simurgh',
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
  ),
  LevelDef(
    title: 'V · AĞRI',
    subtitle: 'Tufandan beri karla örtülü bir sır.',
    theme: LevelTheme.snow,
    wings: true,
    headwind: 140,
    storm: true,
    titleEn: 'V · ARARAT',
    subtitleEn: 'A secret wrapped in snow since the Flood.',
    place: 'Ağrı Dağı · Doğubayazıt, Ekim 1660',
    placeEn: 'Mount Ararat · Doğubayazıt, October 1660',
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
      'Aziz Hakob\'un manastırı. Çanı rüzgârda kendi kendine çalar; Kandilciler sese gelir, sarkıtlar da düşer.',
    ],
    whispersEn: [
      'A monk once set out for the summit. Every morning he woke again at the mountain\'s foot.',
      'The wind pushes your wings back. Here a rope is more faithful than wings.',
      'The shepherds left their flocks behind. When the Lamplighters come, even the lambs fall silent.',
      'One night an angel came to the monk and put a plank of the Ark in his hand: "Climb no higher," it said.',
      'Up above, inside the ice, a body made of wood is sleeping.',
      'In Akori they say Noah, stepping from the Ark, planted the first vine here. The vines are frozen; their roots are still warm.',
      'The monastery of Saint Hakob. Its bell rings by itself in the wind; the Lamplighters come to its voice, and the icicles fall.',
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
      'Ambar Kuyusu',
      'Güverte',
    ],
    areasEn: [
      'The Lions\' Hold',
      'Those Who Wait for Their Mates',
      'The Hold of Lamps',
      'The Hold Shaft',
      'The Deck',
    ],
    whispers: [
      'Bu gemi kırk gün kırk gece karanlıkta yüzdü. İçinde hiç sönmeyen bir ışık vardı.',
      'Her canlı eşiyle bindi. Eşini yitirenin gölgesi hâlâ onu bekliyor.',
      'Önce yolu aç, sonra yürüt. Sırayı şaşıran geri dönemez.',
      'Kandiller burada asılıydı. Kandilciler onları da toplamış.',
      'Su hatırlar. Bir kere yükseldi; bir daha yükselir.',
      'Güvercin buradan uçtu, ağzında bir zeytin dalıyla döndü. Hüdhüd onu tanıdı.',
      'Işık burada değil. Kandilciler onu güneşin doğduğu dağa, Nemrut\'a taşımış.',
    ],
    whispersEn: [
      'This ship sailed forty days and nights in darkness. Inside it was a light that never went out.',
      'Every creature boarded with its mate. The shadow of one who lost its mate is still waiting.',
      'First open the way, then lead them on. Whoever confuses the order cannot turn back.',
      'The lamps hung here. The Lamplighters gathered them too.',
      'Water remembers. It rose once; it will rise again.',
      'The dove flew from here and came back with an olive branch in its beak. The Hoopoe knew it.',
      'The light is not here. The Lamplighters have carried it to the mountain where the sun rises: Nemrut.',
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
  ),
  LevelDef(
    title: 'VII · NEMRUT',
    subtitle: 'Tanrılarla yan yana oturmak isteyen bir kralın dağı.',
    theme: LevelTheme.nemrut,
    wings: true,
    headwind: 80,
    storm: true,
    quakes: true,
    titleEn: 'VII · NEMRUT',
    subtitleEn: 'The mountain of a king who wished to sit beside the gods.',
    place: 'Nemrut Dağı · Kommagene, Kasım 1660',
    placeEn: 'Mount Nemrut · Commagene, November 1660',
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
  ),
  LevelDef(
    title: 'VIII · GÜN DOĞUMU',
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
      'Güneşin Doğduğu Yer',
    ],
    areasEn: [
      'The Processional Way',
      'The Terrace Gate',
      'The East Terrace',
      'Where the Sun Rises',
    ],
    whispers: [
      'Doğu terası. Kral burada tanrılarla el sıkışırken kazıttı kendini.',
      'Kandilcilerin fenerleri şafakta soluklaşır. Güneşten korkarlar.',
      'Tanrının omzundaki kolu çek. Kapı taşın sözünü dinler.',
      'Kandilciler taşa can vermiş: Nemrud gibi göğe başkaldıran bir dev.',
      'Nemrud\'u bir sivrisinek yendi. Senin de küçük bir ışığın var. Yoluna bırak, kulağı ona değsin.',
      'Işık orada, güneşin doğduğu yerde. Sâye, ona dokun.',
    ],
    whispersEn: [
      'The eastern terrace. Here the king had himself carved shaking hands with the gods.',
      'At dawn the Lamplighters\' lanterns grow pale. They fear the sun.',
      'Pull the lever on the god\'s shoulder. The gate listens to the stone.',
      'The Lamplighters have breathed life into stone: a giant who rebels against the sky, like Nemrud.',
      'Nemrud was beaten by a gnat. You too have a small light. Leave it in his path; let his ear touch it.',
      'The light is there, where the sun rises. Saye, touch it.',
    ],
    memories: [
      'Hatıra · Ustam el sıkışan iki tasviri hep yan yana koyardı. "Gölgeler de barışır," derdi.',
      'Hatıra · Güneş doğarken perdeyi indirirdik. "Artık gölge oyunu yok," derdi. "Şimdi asıl oyun başlıyor."',
    ],
    memoriesEn: [
      'Memory · My master always set two figures shaking hands side by side. "Shadows make peace too," he said.',
      'Memory · At sunrise we took down the screen. "No more shadow play," he said. "Now the real play begins."',
    ],
    map: kMapGunDogumu,
  ),
  LevelDef(
    title: 'IX · KAR YOLU',
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
      'Evliya Çelebi yazmış: Erzurum\'da kış öyle sert gelir ki damdan dama atlayan kedi havada donar.',
      'Kurtlar seni gözle değil, kokuyla bulur. Saklanmak yetmez; yüksel ya da ışığını göster.',
      'Ağaçlar kurtların ulaşamadığı yerdir. Daldan dala, kardan uzak.',
      'Göl ince buzla örtülü. Hafif olan geçer, ağır olan düşer.',
      'Kervanlar burada geceyi geçirirdi. Şimdi hanın ocağı Kandilcilerin fenerleriyle yanıyor.',
      'Yukarıda iki tepe var: Büyük Ejder ve Küçük Ejder. Derler ki kışın zirvelerde ejderler uyur.',
      'Dağdan inmenin tek yolu kaymak. Rüzgâra değil, kara güven.',
    ],
    whispersEn: [
      'They call this mountain Palandöken: its slopes are so steep that the caravans\' pack saddles slipped off and fell.',
      'Evliya Çelebi wrote that winter in Erzurum is so harsh a cat leaping from roof to roof freezes in mid-air.',
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
    subtitle: 'Ejderlerin uyuduğu dağdan aşağı.',
    theme: LevelTheme.snow,
    variant: 1,
    skiSurface: kSkiPalandoken,
    magnet: [(203, 226)],
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
      'İki zirvenin adı Büyük Ejder ile Küçük Ejder. Eski inanışta dağların doruğu kutsaldır; orada koruyucu ruhlar, dev ejderler yaşar. Fırtına onların nefesi, sis onların uykusudur.',
      'Kandilciler fenerlerini balonlara asmış, yamacı tarıyor. Işıklarında oyalanma; hız, gölgenin kalkanıdır.',
      'Burada kar yokuş yukarı akar. Çobanlar bunun bir göz aldanması mı, yoksa dağın seni geri çağırması mı olduğunu hiç bilememiş.',
      'Dağ çağırırsa direnme. Seni sırtına kadar taşır; oradan uçarsın.',
      'Ejder\'in Sıçrayışı. Buradan atlayan rüzgârın kanadına biner. Korkan düşer, inanan uçar.',
      'Aşağıda Erzurum\'un kandilleri titriyor. Dağın sırtında bir gürültü uyanıyor.',
    ],
    whispersEn: [
      'They call this mountain Palandöken. Its slopes were so steep that the pack saddles slid off the caravans\' backs and fell, and so it got its name.',
      'The snow wants to carry you. Lift off its ridges, land turning; let your feet come down to the ground.',
      'The two summits are the Great Dragon and the Little Dragon. In the old belief mountaintops are sacred; guardian spirits and giant dragons dwell there. The storm is their breath, the fog their sleep.',
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
    subtitle: 'Ejder uyandı. Beyaz bir nefes peşinde.',
    theme: LevelTheme.snow,
    variant: 2,
    skiSurface: kSkiCig,
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
      'Erzurum\'un yaşlıları anlatır: bir kervan bir gece çığa yakalanmış. Baharda karlar eriyince develeri ayakta, donmuş bulmuşlar; boyunlarındaki çanlar rüzgârda hâlâ çalıyormuş.',
      'Kırık sırt. Kayalar çığdan önce düşer; gözünü yoldan ayırma.',
      'Son atlayış. Ejderin nefesi sırtında: ya uçarsın, ya kar olursun.',
      'Çığ dağın dibinde durdu, Ejder yeniden uykuya daldı. Batıda, peri bacalarının ülkesinde bir kandil yanıp sönüyor.',
    ],
    whispersEn: [
      'They say when the Little Dragon sleeps, the mountain is silent; when it wakes, the snow flows. Tonight the Lamplighters\' lanterns woke it.',
      'There is no fleeing an avalanche, only racing it. Whoever slows becomes snow.',
      'The elders of Erzurum tell of a caravan caught by an avalanche one night. When the snow melted in spring, they found the camels standing, frozen; the bells on their necks still rang in the wind.',
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
      'Eskiler bu ülkeye Katpatuka derdi: güzel atlar ülkesi. Ama atlardan önce burada periler vardı.',
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
      'The ancients called this land Katpatuka: the land of beautiful horses. But before the horses, there were fairies.',
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
      'Alçak geçitler bilerek alçak oyulmuş: düşman eğilmek zorunda kalsın. Kandilciler eğilemez; fenerleri tavana takılır.',
      'Bir yuvarlak taş yalnız bir kapıyı kapatmaz. Bazen, yükseğe çıkmak isteyene basamak olur.',
      'Bacalar şehri nefes aldırır. Aşağıdan sıcak bir rüzgâr eser; derler ki devlerin nefesidir.',
      'Kuyunun suyu en dipten gelir. Kovayı indiren, suyu da çağırır.',
      'Peri Padişahı devleri yeraltına sürmüştü. Derinkuyu\'nun en dibinde hâlâ uyurlar; uykuları ışığı yer. Ateşböceklerini sakla, onlar senin nefesin.',
      'Yukarıda ay doğmuş. Batıda Konya\'nın kubbeleri karla örtülü. Kandilciler bir düğün gecesine yetişmeye çalışıyor.',
    ],
    whispersEn: [
      'There is a city beneath the earth; no one knows when it was dug. Some say the Phrygians, some say older still. Today no one remembers it.',
      'Its doors are round stones, opened and closed only from within. Whoever is outside waits; whoever is inside lives.',
      'The low passages were made low on purpose, so that an enemy would have to bow. The Lamplighters cannot bow; their lanterns catch on the ceiling.',
      'A round stone does not only close a door. Sometimes it becomes a step for whoever wants to climb.',
      'The shafts let the city breathe. A warm wind rises from below; they say it is the giants\' breath.',
      'The well\'s water comes from the very bottom. Whoever lowers the bucket calls the water too.',
      'The Fairy King drove the giants underground. At the very bottom of Derinkuyu they sleep still, and their sleep devours light. Guard your fireflies; they are your breath.',
      'Above, the moon has risen. In the west, Konya\'s domes lie under snow. The Lamplighters are racing to reach a wedding night.',
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
  ),
  LevelDef(
    title: 'XIV · ŞEB-İ ARÛS',
    subtitle: 'Bu gece ölüm bir düğündür.',
    theme: LevelTheme.konya,
    wings: true,
    titleEn: 'XIV · SHEB-I ARUS',
    subtitleEn: 'Tonight, death is a wedding.',
    place: 'Konya · 17 Aralık 1660, Şeb-i Arûs gecesi',
    placeEn: 'Konya · 17 December 1660, the night of Sheb-i Arus',
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
      'Eskiler bu şehre İkonion derdi. Tufandan sonra yeryüzünde tek bir can kalmamış. Prometheus ile Athena çamurdan suretler yoğurmuş, rüzgâr onlara can üflemiş. Şehrin adı o suretlerden kalmış: ikon, suret demektir. Sen de bir suretsin, Sâye.',
      'Bir başka rivayete göre Perseus, Medusa\'nın başını kesip buraya getirmiş ve şehri o başın sureti üstüne kurmuş. Yerebatan\'daki başları hatırla: bakışı taşa çevirir. Ama cilalı bir kalkanda kendi yüzünü görürse kendisi taşa döner.',
      'Tufandan önce burada Nannakos adında bir kral yaşarmış. Kâhinler, o ölünce bütün insanların öleceğini söylemiş. Nannakos halkıyla öyle ağlamış ki "Nannakos gibi ağlamak" sözü dilden dile geçmiş. Üç yüz yaşında öldü; ardından tufan geldi. Ama tufandan sonra çamurdan suretler doğdu.',
      'Alâeddin Tepesi. Selçuklu sultanları burada otururdu; Konya bütün Anadolu\'nun başkentiydi. Köşklerinin çinilerinde kanatlı insanlar, çift başlı kartallar, ay yüzlü saraylılar vardı. Şimdi kalıntılarında Kandilciler nöbet tutuyor.',
      'Belh\'ten bir âlim, ailesini alıp Moğollardan kaçmış. Nişabur\'da yaşlı bir şaire uğramışlar: Attâr\'a, kuşların Simurg\'a yolculuğunu yazan şaire. Attâr çocuğa bir kitap vermiş, babasına dönüp "Bu çocuk yakında âlemin yüreğine ateş düşürecek," demiş. Çocuk Celâleddin\'di. Konya ona Mevlânâ dedi: efendimiz.',
      'Karatay Medresesi. Kubbesinin çinileri gece göğünü taklit eder. Tepedeki açıklıktan inen ay ortadaki havuza düşermiş; talebeler gökyüzünü yerde, suyun içinde okurmuş. Ay ışığını kilide ulaştır.',
      'İnce Minare. Kandilciler şerefeye büyük fenerlerini asmış, damları tarıyorlar. Huzme kubbede, bacada, revakta kesilir. Gölgede bekle; ışık geçince koş.',
      'Bir gün Konya\'ya yırtık hırkalı bir derviş geldi: Tebrizli Şems. Mevlânâ onu görünce kitaplarını bıraktı. Şems, güneş demektir. Konyalılar onu kıskandı. Bir gece Şems kayboldu: kimi Tebriz\'e döndü der, kimi öldürülüp bu kuyuya atıldı der. Mevlânâ onu Şam\'a kadar aradı, bulamadı. Sonunda şöyle dedi: "Aradığımı kendimde buldum."',
      'Güneşini kaybeden adam bir direğin çevresinde dönmeye başladı. Semâ böyle doğdu: arayanın dönüşü. Bu gece on yedi Aralık, Şeb-i Arûs: Mevlânâ\'nın vefat gecesi. O, ölümüne düğün derdi. Sikke nefsin mezar taşıdır, tennure kefeni. Sağ el göğe açılır, sol el yere döner: Hak\'tan alır, halka verir. Önden geçen semâzenin eteğinde saklan.',
      'Semâhane. Neyzen ilk nefesini üflüyor. Ney kamışlıktan koparıldığından beri inler; kesildiği yeri özler, dinleyen herkes kendi ayrılığını duyar. Gölge de perdesini özler, Sâye. Avizeler dönüyor: semâzenler gibi, gezegenler gibi.',
      'Kubbe-i Hadrâ: Yeşil Kubbe, Mevlânâ\'nın türbesi. Kandilciler ustayı en tepeye çıkardı; yüzyıllardır topladıkları bütün ışık orada. Ustanın kandili sönmek üzere ve biriktirilen ışık taşıyor. Tırman, Sâye!',
    ],
    whispersEn: [
      'The Konya Plain. They say two dervishes once took wing from Khorasan and flew west. Over this plain, one asked: "Shall I land?" The other said: "Kon ya! Land!" The city has kept the name ever since.',
      'Beneath this mound sleeps one of the oldest cities in the world. Its houses had no doors: you went down through the roof, by ladder. They buried their dead under the floors of their homes; the living and the dead slept under one roof.',
      'Bull horns on the wall. In the corner, a mother goddess on her throne, a leopard at either side. She gives birth, she feeds, and then she takes back. This plain has sung the same lullaby for nine thousand years.',
      'The ancients called this city Iconium. After the Flood not a single soul was left on earth. Prometheus and Athena kneaded images out of mud, and the wind breathed life into them. The city is named for those images: eikon means image. You are an image too, Saye.',
      'Another tale says Perseus cut off Medusa\'s head, brought it here, and founded the city upon its image. Remember the heads in the cistern: their gaze turns all to stone. But if one sees its own face in a polished shield, it turns to stone itself.',
      'Before the Flood a king named Nannakos lived here. The oracles said that when he died, all people would die. Nannakos wept with his people so bitterly that "to weep like Nannakos" passed from tongue to tongue. He died at three hundred; then the Flood came. But after the Flood, images of mud were born.',
      'Alaeddin Hill. The Seljuk sultans sat here; Konya was the capital of all Anatolia. The tiles of their pavilions showed winged people, double-headed eagles, moon-faced courtiers. Now the Lamplighters keep watch among the ruins.',
      'A scholar of Balkh took his family and fled the Mongols. In Nishapur they visited an old poet: Attar, who wrote of the birds\' journey to the Simurgh. Attar gave the boy a book and told his father, "Soon this boy will set the heart of the world on fire." The boy was Jalaladdin. Konya called him Mevlana: our master.',
      'Karatay Madrasa. The tiles of its dome imitate the night sky. The moon came down through the opening at the top and fell into the pool below; the students read the heavens on the ground, inside the water. Bring the moonlight to the lock.',
      'The Slender Minaret. The Lamplighters have hung their great lamps from the balcony and sweep the rooftops. The beam breaks on domes, chimneys and porches. Wait in the shadow; run when the light has passed.',
      'One day a dervish in a torn cloak came to Konya: Shams of Tabriz. When Mevlana saw him, he left his books behind. Shams means sun. The people of Konya grew jealous. One night Shams vanished: some say he went back to Tabriz, some say he was killed and thrown into this well. Mevlana searched for him as far as Damascus and did not find him. In the end he said: "What I was seeking, I found in myself."',
      'The man who lost his sun began to turn around a pillar. That is how the sema was born: the turning of one who seeks. Tonight is the seventeenth of December, Sheb-i Arus: the night Mevlana died. He called his death a wedding. The tall felt hat is the tombstone of the self, the white skirt its shroud. The right hand opens to the sky, the left turns to the earth: receiving from God, giving to the people. Hide in the skirt of a whirling dervish as he passes in front.',
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
  ),
];
