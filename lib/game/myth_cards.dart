import 'strings.dart';

/// Defter > Efsaneler: oyunda karşılaşılan mitolojik varlıkların kısa,
/// doğru bilgi kartları (docs/MITOLOJI.md §6). Kart, varlıkla ilk
/// karşılaşmada açılır; oyunda henüz görünmeyen varlıkların kartı eklenmez.
class MythCard {
  const MythCard({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.whoTr,
    required this.whoEn,
    required this.storyTr,
    required this.storyEn,
    required this.sourceTr,
    required this.sourceEn,
  });

  final String id;
  final String nameTr;
  final String nameEn;
  final String whoTr;
  final String whoEn;
  final String storyTr;
  final String storyEn;
  final String sourceTr;
  final String sourceEn;

  String get name => S.en ? nameEn : nameTr;

  /// Kısa kimlik: tek cümle.
  String get who => S.en ? whoEn : whoTr;

  /// Efsanedeki yeri: iki üç cümle.
  String get story => S.en ? storyEn : storyTr;

  String get source => S.en ? sourceEn : sourceTr;

  static MythCard? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static const all = [
    MythCard(
      id: 'umay',
      nameTr: 'Umay',
      nameEn: 'Umay',
      whoTr: 'Çocukların, doğumun ve bereketin koruyucu ana tanrıçası.',
      whoEn: 'Mother goddess who protects children, birth and fertility.',
      storyTr:
          'Eski Türk inancında Umay, doğan her çocuğun yanında durur; anneyi '
          've bebeği korur. Orhun Yazıtları\'nda Kül Tigin\'in annesi "Umay '
          'gibi" diye anılır. Anadolu\'da bugün de süren, dilek ağacına çaput '
          'bağlama geleneği, ağaca ve koruyucu ruhlara duyulan eski saygının '
          'izidir.',
      storyEn:
          'In old Turkic belief Umay stands beside every newborn child, '
          'guarding mother and baby. In the Orkhon inscriptions, Kül Tigin\'s '
          'mother is praised as being "like Umay". The Anatolian custom of '
          'tying strips of cloth to wishing trees, still alive today, echoes '
          'that old reverence for trees and protecting spirits.',
      sourceTr: 'Orhun Yazıtları (Kül Tigin Yazıtı)',
      sourceEn: 'Orkhon Inscriptions (Kül Tigin)',
    ),
    MythCard(
      id: 'suIyesi',
      nameTr: 'Su İyesi',
      nameEn: 'Su İyesi (Water Spirit)',
      whoTr: 'Suları koruyan ruh; eski inançta doğanın her parçasının bir iyesi vardır.',
      whoEn: 'The spirit that guards the waters; in old belief every part of nature has its iye, its keeper.',
      storyTr:
          'Eski Türk inancında dağın, ormanın, ocağın ve suyun iyesi vardır. '
          'Su İyesi\'ne saygı gösterilir: suya kirli şey atılmaz, sudan '
          'geçerken izin istenir. Anlatılara göre saygısızlık edenin yolunu '
          'şaşırtır.',
      storyEn:
          'In old Turkic belief mountains, forests, hearths and waters each '
          'have their iye. The Water Spirit is shown respect: nothing foul is '
          'thrown into water, and one asks leave before crossing it. The '
          'stories say it leads the disrespectful astray.',
      sourceTr: 'Türk halk inançları (iye inancı)',
      sourceEn: 'Turkic folk belief (the iye spirits)',
    ),
    MythCard(
      id: 'tulpar',
      nameTr: 'Tulpar',
      nameEn: 'Tulpar',
      whoTr: 'Kanatlı, yiğitlik ve özgürlük simgesi at.',
      whoEn: 'The winged horse, a sign of courage and freedom.',
      storyTr:
          'Orta Asya Türk halklarının destan ve masallarında Tulpar, '
          'kahramanın kanatlı ya da rüzgâr hızındaki atıdır; dağları aşar, '
          'göğe yükselir. Kazak ve Kırgız kültüründe bugün de hızın ve '
          'özgürlüğün simgesidir.',
      storyEn:
          'In the epics and tales of the Central Asian Turkic peoples, Tulpar '
          'is the hero\'s winged or wind-swift horse that crosses mountains '
          'and rises into the sky. Among Kazakhs and Kyrgyz it is still a '
          'symbol of speed and freedom.',
      sourceTr: 'Kazak ve Kırgız destan ve masalları',
      sourceEn: 'Kazakh and Kyrgyz epics and tales',
    ),
    MythCard(
      id: 'ayazAta',
      nameTr: 'Ayaz Ata',
      nameEn: 'Ayaz Ata',
      whoTr: 'Soğuğun ve ayazın ak sakallı ihtiyarı.',
      whoEn: 'The white-bearded old man of frost and cold.',
      storyTr:
          'Türk halk anlatılarında Ayaz Ata, ayazın ve dondurucu soğuğun '
          'kişileşmiş hâlidir; kışın ağırlığı onunla gelir. Kazak Türkçesinde '
          'bugün de kış ve yeni yıl ihtiyarının adıdır.',
      storyEn:
          'In Turkic folk tales Ayaz Ata is frost and bitter cold given a '
          'face; the weight of winter comes with him. In Kazakh his name is '
          'still used for the old man of winter and the new year.',
      sourceTr: 'Türk halk anlatıları',
      sourceEn: 'Turkic folk tales',
    ),
    MythCard(
      id: 'akAna',
      nameTr: 'Ak Ana',
      nameEn: 'Ak Ana',
      whoTr: 'Başlangıçtaki sudan yükselen ve yaratıcıya "yarat" diyen ilk ana varlık.',
      whoEn: 'The first mother who rose from the primeval water and told the creator, "Create."',
      storyTr:
          'Altay yaratılış anlatısında başlangıçta uçsuz bucaksız bir sudan '
          'başka bir şey yoktur. Yaratıcı Kayra Han ne yapacağını düşünürken '
          'sudan Ak Ana yükselir, ona "Yarat!" der ve yeniden suya döner.',
      storyEn:
          'In the Altai creation story there is nothing at first but endless '
          'water. While the creator Kayra Khan wonders what to do, Ak Ana '
          'rises from the water, tells him "Create!" and returns into it.',
      sourceTr: 'Altay yaratılış destanı (W. Radloff derlemesi)',
      sourceEn: 'Altai creation epic (collected by W. Radloff)',
    ),
    MythCard(
      id: 'basat',
      nameTr: 'Basat ve Tepegöz',
      nameEn: 'Basat and Tepegöz',
      whoTr: 'Dede Korkut\'ta tek gözlü devi yenen yiğit.',
      whoEn: 'The hero of Dede Korkut who defeats the one-eyed giant.',
      storyTr:
          'Dede Korkut Kitabı\'nın Basat\'ın Tepegöz\'ü öldürdüğü boyunda, '
          'Oğuzları yıllarca haraca bağlayan tek gözlü dev Tepegöz\'ü, '
          'aslanlar arasında büyüyen yiğit Basat yener: kızgın bir şişle '
          'gözünü kör eder, sonra devin kendi kılıcıyla başını keser.',
      storyEn:
          'In the Book of Dede Korkut, in the tale of how Basat killed '
          'Tepegöz, the one-eyed giant who held the Oghuz to ransom for years '
          'is defeated by Basat, a hero raised among lions: he blinds the '
          'giant with a red-hot spit, then slays him with the giant\'s own '
          'sword.',
      sourceTr: 'Dede Korkut Kitabı',
      sourceEn: 'The Book of Dede Korkut',
    ),
    MythCard(
      id: 'gokboru',
      nameTr: 'Gökbörü',
      nameEn: 'Gökbörü',
      whoTr: 'Gök tüylü, gök yeleli kurt; yol gösteren rehber.',
      whoEn:
          'The wolf with sky-coloured fur and mane; a guide who shows the way.',
      storyTr:
          'Oğuz Kağan Destanı\'nda bir sabah Oğuz\'un çadırına gökten bir '
          'ışık düşer; ışığın içinden gök tüylü, gök yeleli bir erkek kurt '
          'çıkar ve ordunun önünde yürüyerek yol gösterir. Ergenekon '
          'anlatısında da dağlarla çevrili vadiden çıkış yolunu bir kurt '
          'gösterir.',
      storyEn:
          'In the Oghuz Khagan epic a light falls into Oghuz\'s tent one '
          'morning; out of it steps a male wolf with sky-coloured fur and '
          'mane, who walks before the army and shows it the way. In the '
          'Ergenekon legend, too, a wolf shows the people the way out of the '
          'valley walled in by mountains.',
      sourceTr: 'Oğuz Kağan Destanı; Ergenekon Destanı',
      sourceEn: 'Oghuz Khagan epic; Ergenekon legend',
    ),
    MythCard(
      id: 'albasti',
      nameTr: 'Albastı (Al Karısı)',
      nameEn: 'Albastı (Al Karısı)',
      whoTr: 'Halk inancında kızıl bir kötü ruh; demirden korktuğuna inanılır.',
      whoEn: 'A red evil spirit of folk belief, said to fear iron.',
      storyTr:
          'Anadolu\'dan Orta Asya\'ya yaygın halk inancında Albastı, kızıl '
          'saçlı, insanın gücünü ve ışığını çalan karanlık bir varlıktır. '
          'Ondan korunmak için yanında demir taşınır, kapıya nal çakılır: '
          'demirden korktuğuna inanılır.',
      storyEn:
          'In folk belief from Anatolia to Central Asia, Albastı is a '
          'red-haired dark being that steals a person\'s strength and light. '
          'People carry iron or nail a horseshoe to the door to keep her '
          'away: she is said to fear iron.',
      sourceTr: 'Türk halk inançları',
      sourceEn: 'Turkic folk belief',
    ),
    MythCard(
      id: 'erlik',
      nameTr: 'Erlik',
      nameEn: 'Erlik',
      whoTr: 'Yerin altının, ölümün ve kötülüğün efendisi.',
      whoEn: 'Lord of the underworld, of death and of evil.',
      storyTr:
          'Altay anlatılarında Erlik, yaratıcının yanında var olup ona karşı '
          'gelen ve yerin altına sürülen varlıktır. Yeraltının katlarında '
          'hüküm sürer; ölenlerin canlarını oraya çağırdığına inanılır.',
      storyEn:
          'In Altai stories Erlik was with the creator from the beginning, '
          'rose against him and was cast down beneath the earth. He rules the '
          'layers of the underworld and is believed to call the souls of the '
          'dead down to him.',
      sourceTr: 'Altay yaratılış destanı (W. Radloff derlemesi)',
      sourceEn: 'Altai creation epic (collected by W. Radloff)',
    ),
    MythCard(
      id: 'erTostuk',
      nameTr: 'Er Töştük ve Çalkuyruk',
      nameEn: 'Er Töştük and Çalkuyruk',
      whoTr: 'Yerin altına inen Kırgız destan kahramanı ve konuşan atı.',
      whoEn: 'The Kyrgyz epic hero who descends beneath the earth, and his talking horse.',
      storyTr:
          'Kırgız destanı Er Töştük\'te kahraman yerin altına düşer; '
          'yeraltının devleri ve cadılarıyla karşılaşır. Yolunu, konuşan ve '
          'olacakları sezen atı Çalkuyruk\'un öğütleriyle bulur; sonunda '
          'onunla yeryüzüne döner.',
      storyEn:
          'In the Kyrgyz epic of Er Töştük the hero falls beneath the earth '
          'and meets the giants and witches of the underworld. He finds his '
          'way by the counsel of his talking, far-seeing horse Çalkuyruk, and '
          'at last returns with him to the surface.',
      sourceTr: 'Er Töştük Destanı (Kırgız)',
      sourceEn: 'The epic of Er Töştük (Kyrgyz)',
    ),
    MythCard(
      id: 'kormos',
      nameTr: 'Körmös',
      nameEn: 'Körmös',
      whoTr: 'Altay inancında yerin altının ruhları; Erlik\'e bağlı gölgeler.',
      whoEn: 'In Altai belief, the spirits of the underworld; shades bound to Erlik.',
      storyTr:
          'Altay ve Sibirya Türklerinin inancında körmösler, yerin altında '
          'Erlik\'e bağlı yaşayan ruhlardır; ölenlerin bir kısmının da körmöse '
          'dönüştüğüne inanılır. Kamlar onlardan korunmak için dualar okur, '
          'saçılar sunardı.',
      storyEn:
          'In the belief of the Altai and Siberian Turks, the körmös are '
          'spirits living beneath the earth in Erlik\'s service; some of the '
          'dead are believed to become körmös. Shamans recited prayers and '
          'made offerings to keep them away.',
      sourceTr: 'Altay Türk inançları',
      sourceEn: 'Altai Turkic belief',
    ),
    MythCard(
      id: 'kut',
      nameTr: 'Kut',
      nameEn: 'Kut',
      whoTr: 'Gökten verilen kutsal güç ve can ışığı.',
      whoEn: 'The sacred power and light of life granted by the sky.',
      storyTr:
          'Eski Türk inancında kut, Gök Tengri\'nin bağışladığı kutsal '
          'güçtür; hükümdara yönetme hakkını, insana canlılığını verir. '
          'Kutunu yitiren güçsüz düşer. Orhun Yazıtları\'nda kağanın kutu '
          'sık sık anılır.',
      storyEn:
          'In old Turkic belief kut is the sacred power granted by Gök '
          'Tengri, the Sky; it gives a ruler the right to rule and a person '
          'their vitality. Whoever loses their kut grows weak. The Orkhon '
          'inscriptions often speak of the khagan\'s kut.',
      sourceTr: 'Orhun Yazıtları',
      sourceEn: 'Orkhon Inscriptions',
    ),
    MythCard(
      id: 'ergenekon',
      nameTr: 'Ergenekon',
      nameEn: 'Ergenekon',
      whoTr:
          'Dört yanı aşılmaz dağlarla çevrili vadiden demir dağı eritip çıkış.',
      whoEn: 'The way out of a valley walled by mountains, through a mountain of iron melted down.',
      storyTr:
          'Anlatıya göre bir yenilgiden yalnız Kıyan ile Nüküz eşleriyle '
          'kurtulur ve çayırlı, ırmaklı, meyveli bir vadiye, Ergenekon\'a '
          'sığınır. Dört yüz yılda boy çoğalır, vadi dar gelir. Bir demirci '
          'dağın demir olduğunu söyler; odun ve kömür yığılır, deriden '
          'yetmiş körük kurulur, dağ erir ve yüklü bir devenin geçeceği yol '
          'açılır. O gün kutsal sayılır: her yıl bir demir ateşte kızdırılıp '
          'dövülür.',
      storyEn:
          'As the story goes, after a defeat only Kıyan and Nüküz escape with '
          'their wives and take refuge in Ergenekon, a valley of meadows, '
          'rivers and fruit. Over four hundred years the people multiply and '
          'the valley grows too small. A smith says the mountain is iron; '
          'wood and coal are piled up, seventy bellows of hide are set, the '
          'mountain melts and a road opens wide enough for a laden camel. '
          'That day became sacred: every year a piece of iron was heated in '
          'the fire and struck on the anvil.',
      sourceTr: 'Reşidüddin, Câmiu\'t-Tevârîh; Ebulgazi Bahadır Han, Şecere-i Terâkime',
      sourceEn: 'Rashid al-Din, Jami al-Tawarikh; Abu al-Ghazi Bahadur, Shajara-i Tarakima',
    ),
    MythCard(
      id: 'demirci',
      nameTr: 'Demirci',
      nameEn: 'The Smith',
      whoTr: 'Ergenekon\'da demir dağı eritmeyi akıl eden usta.',
      whoEn:
          'The master who thought of melting the iron mountain in Ergenekon.',
      storyTr:
          'Ergenekon anlatısında çıkış yolunu bulan bir demircidir: dağın '
          'demir damarını gösterir, körüklerin kurulmasını önerir. Türk '
          'kültüründe demircilik kutsal bir zanaat sayılmış; demir döven usta '
          'saygı görmüştür.',
      storyEn:
          'In the Ergenekon story it is a smith who finds the way out: he '
          'shows the iron vein of the mountain and proposes setting up the '
          'bellows. In Turkic culture smithing was held to be a sacred craft, '
          'and the master who forged iron was honoured.',
      sourceTr: 'Ergenekon Destanı',
      sourceEn: 'The Ergenekon legend',
    ),
    MythCard(
      id: 'asena',
      nameTr: 'Asena',
      nameEn: 'Asena',
      whoTr: 'Göktürk türeyiş efsanesinde çocuğu kurtarıp büyüten dişi kurt.',
      whoEn: 'In the Göktürk origin legend, the she-wolf who saved and raised a child.',
      storyTr:
          'Çin kaynaklarına geçen Göktürk efsanesine göre boyu yok edilince '
          'geriye kalan tek çocuğu bir dişi kurt kurtarır ve besler. Kurt '
          'onunla dağların arasındaki bir mağaraya sığınır; mağaranın içinde '
          'çevresi dağlarla kuşatılmış bir ova vardır. Göktürk hanedanı '
          'Aşina adını bu soydan alır.',
      storyEn:
          'According to the Göktürk legend preserved in Chinese sources, when '
          'the tribe was destroyed a she-wolf saved and fed the only child '
          'left. She took refuge with him in a cave among the mountains; '
          'inside the cave lay a plain encircled by mountains. The Göktürk '
          'ruling house, Ashina, took its name from this line.',
      sourceTr: 'Göktürk türeyiş efsanesi (Çin kaynakları, Zhoushu)',
      sourceEn: 'Göktürk origin legend (Chinese sources, Zhoushu)',
    ),
  ];
}
