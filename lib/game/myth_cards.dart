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
      id: 'hayal',
      nameTr: 'Hayal perdesi (Karagöz)',
      nameEn: 'The shadow screen (Karagöz)',
      whoTr:
          'Arkadan kandille aydınlatılan beyaz perdede oynatılan gölge oyunu.',
      whoEn: 'The shadow play performed on a white screen lit from behind by a lamp.',
      storyTr: 'Osmanlı\'da hayal perdesi ya da hayal-i zıl denen bu oyunda, deve ya da manda derisinden oyulup boyanan tasvirler, arkadan kandille aydınlatılan perdeye (aynaya) yaslanarak oynatılır. Oynatan ustaya hayalî denir. Karagöz geleneği 2009\'da UNESCO Somut Olmayan Kültürel Miras listesine alındı.',
      storyEn: 'In this play, called the hayal screen or hayal-i zıl in Ottoman times, figures cut from camel or buffalo hide and painted are pressed against a white screen (the "mirror") lit from behind by a lamp. The master who performs is called the hayalî. The Karagöz tradition was inscribed on UNESCO\'s Intangible Cultural Heritage list in 2009.',
      sourceTr: 'Karagöz geleneği; UNESCO (2009)',
      sourceEn: 'The Karagöz tradition; UNESCO (2009)',
    ),
    MythCard(
      id: 'hudhud',
      nameTr: 'Hüdhüd',
      nameEn: 'The Hoopoe (Hüdhüd)',
      whoTr: 'Süleyman\'ın habercisi; kuşlara yol gösteren bilge kuş.',
      whoEn: 'Solomon\'s messenger; the wise bird who shows the birds the way.',
      storyTr: 'Kur\'an\'ın Neml suresinde Hüdhüd, Süleyman\'a Saba ülkesinin haberini getirir. Feridüddin Attar\'ın Mantıku\'t-Tayr\'ında ise bütün kuşları toplar ve onlara yol göstererek Kaf Dağı\'ndaki Simurg\'u aramaya götürür.',
      storyEn: 'In the Quran\'s sura of the Ant, the hoopoe brings Solomon news of the land of Sheba. In Farid ud-Din Attar\'s The Conference of the Birds, it gathers all the birds and leads them in search of the Simurgh on Mount Qaf.',
      sourceTr: 'Kur\'an (Neml suresi); Attar, Mantıku\'t-Tayr',
      sourceEn: 'The Quran (sura an-Naml); Attar, The Conference of the Birds',
    ),
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
      whoTr:
          'Suların koruyucu ruhu; Hakas, Altay ve Tatar anlatılarında ak '
          'giysili, ışık saçan bir kadın.',
      whoEn:
          'The guardian spirit of the waters; in Khakas, Altai and Tatar '
          'tales a woman in white who sheds light.',
      storyTr:
          'Eski Türk inancında dağın, ormanın, ocağın ve suyun iyesi vardır. '
          'Hakas inancına göre Su İyesi dişidir: su bereketin kaynağıdır, '
          'ama taşkının ve yıkımın da. Ak giysiler içinde, bulunduğu yere '
          'ışık saçarak görünür; maviye çalan rengi ve çevresinde yüzen '
          'ışıltılı mavi balıklarıyla anlatılır. Kimi anlatıda balık '
          'kuyrukludur, kimi zaman boynuzlu betimlenir; kuş ya da yılan '
          'kılığına da girebilir. Suyun derinliğinde, büyük bir kayanın '
          'altındaki geçitten girilen sarayında yaşar. Ona saygı gösterilir: '
          'suya kirli şey atılmaz, sudan geçerken izin istenir; görene uğur '
          'getirdiği söylenir. Kazan Tatarlarında Su Anası, kıyıda altın '
          'tarağıyla saçlarını tarayan bir kadındır (Tukay\'ın "Su Anası" '
          'şiiri).',
      storyEn:
          'In old Turkic belief mountains, forests, hearths and waters each '
          'have their iye. In Khakas belief the Water Spirit is female: water '
          'is the source of plenty, but also of flood and ruin. She appears '
          'in white garments, shedding light wherever she is; she is told of '
          'with a bluish hue and glowing blue fish swimming around her. In '
          'some tales she has a fish\'s tail, at times she is shown horned, '
          'and she can take the shape of a bird or a snake. She lives deep in '
          'the water, in a palace entered through a passage beneath a great '
          'rock. She is shown respect: nothing foul is thrown into water, and '
          'one asks leave before crossing it; to see her is said to bring '
          'luck. Among the Kazan Tatars, Su Anası (Water Mother) is a woman '
          'who combs her hair with a golden comb by the shore (Tukay\'s poem '
          '"Su Anası").',
      sourceTr: 'Türk halk inançları (iye inancı); Hakas ve Altay anlatıları; Tukay, Su Anası',
      sourceEn: 'Turkic folk belief (the iye spirits); Khakas and Altai tales; Tukay, Su Anası',
    ),
    MythCard(
      id: 'medusa',
      nameTr: 'Medusa',
      nameEn: 'Medusa',
      whoTr: 'Yunan mitinin bakışı taşa çeviren Gorgon\'u; Yerebatan\'da iki sütunun kaidesi.',
      whoEn: 'The Gorgon of Greek myth whose gaze turns to stone; the base of two columns in the Basilica Cistern.',
      storyTr: 'Mite göre Medusa\'nın yüzüne bakan taşa döner; Perseus ona cilalı kalkanındaki yansımadan bakarak yaklaşır. Yerebatan Sarnıcı\'nın bir köşesinde iki sütun Roma dönemine ait Medusa başlarının üstüne oturtulmuştur: biri ters, biri yan; nereden getirildikleri bilinmez.',
      storyEn: 'In the myth, whoever looks upon Medusa\'s face turns to stone; Perseus approaches her by watching her reflection in his polished shield. In one corner of the Basilica Cistern two columns rest on Roman-era heads of Medusa, one upside down and one on its side; no one knows where they were brought from.',
      sourceTr: 'Yunan mitolojisi; Yerebatan Sarnıcı',
      sourceEn: 'Greek mythology; the Basilica Cistern',
    ),
    MythCard(
      id: 'hezarfen',
      nameTr: 'Hezarfen Ahmed Çelebi',
      nameEn: 'Hezarfen Ahmed Çelebi',
      whoTr: 'Galata Kulesi\'nden kanatlarla uçtuğu anlatılan "bin fen bilen" bilgin.',
      whoEn: 'The scholar "of a thousand sciences" said to have flown with wings from the Galata Tower.',
      storyTr: 'Evliya Çelebi\'nin Seyahatname\'sine göre IV. Murad döneminde Hezarfen, kartal kanadına benzeyen kanatlarla Galata Kulesi\'nden atlayıp Boğaz\'ın üstünden süzülerek Üsküdar\'da Doğancılar\'a indi. Padişah ona bir kese altın verdi, sonra "korkulacak adam" diyerek Cezayir\'e sürdü. Anlatının tek kaynağı Evliya Çelebi\'dir.',
      storyEn: 'According to Evliya Çelebi\'s Book of Travels, in the reign of Murad IV Hezarfen leapt from the Galata Tower with wings like an eagle\'s and glided over the Bosphorus to land at Doğancılar in Üsküdar. The sultan gave him a purse of gold, then, calling him "a man to be feared", exiled him to Algiers. Evliya Çelebi is the only source for the story.',
      sourceTr: 'Evliya Çelebi, Seyahatname',
      sourceEn: 'Evliya Çelebi, Book of Travels',
    ),
    MythCard(
      id: 'karabasan',
      nameTr: 'Karabasan',
      nameEn: 'Karabasan',
      whoTr: 'Uyuyanın göğsüne çöküp nefesini daraltan karanlık varlık.',
      whoEn: 'The dark being that sits on a sleeper\'s chest and steals their breath.',
      storyTr: 'Türk halk inancında karabasan, gece uyuyan kişinin üstüne çöker; kişi uyanık olduğu hâlde kıpırdayamaz, bağıramaz. Ondan korunmak için yastık altına demir ya da Kur\'an konurdu. Bugün uyku felcinin halk arasındaki adıdır.',
      storyEn: 'In Turkish folk belief the karabasan settles on a person sleeping at night; though awake, they cannot move or cry out. People put iron or a Quran under the pillow to keep it away. Today it is the folk name for sleep paralysis.',
      sourceTr: 'Türk halk inançları',
      sourceEn: 'Turkish folk belief',
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
      id: 'kaf',
      nameTr: 'Kaf Dağı',
      nameEn: 'Mount Qaf',
      whoTr: 'Dünyanın kıyısını çeviren, ulaşılmaz zümrüt dağ.',
      whoEn:
          'The unreachable emerald mountain that rings the edge of the world.',
      storyTr: 'İslam kozmolojisinde ve halk anlatılarında Kaf Dağı dünyayı çepeçevre kuşatır; zümrüttendir, göğün rengi ondan yansır. Simurg\'un (Anka\'nın) yuvası oradadır. "Kaf Dağı\'nın ardı" deyimi ulaşılmaz uzaklık demektir.',
      storyEn: 'In Islamic cosmology and folk tales Mount Qaf encircles the whole world; it is made of emerald, and the colour of the sky is its reflection. The Simurgh (Anqa) nests there. "Beyond Mount Qaf" means an unreachable distance.',
      sourceTr: 'İslam kozmolojisi; Attar, Mantıku\'t-Tayr',
      sourceEn: 'Islamic cosmology; Attar, The Conference of the Birds',
    ),
    MythCard(
      id: 'simurg',
      nameTr: 'Simurg',
      nameEn: 'The Simurgh',
      whoTr: 'Kaf Dağı\'nda yaşayan bilge kuş; aranan ve bulunan.',
      whoEn: 'The wise bird of Mount Qaf; the one sought and found.',
      storyTr: 'Firdevsî\'nin Şehname\'sinde Simurg, terk edilen Zal\'i büyüten bilge kuştur. Attar\'ın Mantıku\'t-Tayr\'ında Hüdhüd\'ün ardından yola çıkan binlerce kuştan yalnızca otuzu Kaf\'a varır; "sî murg" (otuz kuş) olarak Simurg\'un kendileri olduğunu görürler.',
      storyEn: 'In Ferdowsi\'s Shahnameh the Simurgh is the wise bird who raises the abandoned Zal. In Attar\'s Conference of the Birds, of the thousands of birds who set out behind the hoopoe only thirty reach Qaf; as "si murgh" (thirty birds) they see that the Simurgh is themselves.',
      sourceTr: 'Firdevsî, Şehname; Attar, Mantıku\'t-Tayr',
      sourceEn: 'Ferdowsi, Shahnameh; Attar, The Conference of the Birds',
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
      id: 'nuh',
      nameTr: 'Nuh\'un Gemisi',
      nameEn: 'Noah\'s Ark',
      whoTr: 'Tufandan kurtulanları taşıyan, dağa oturan gemi.',
      whoEn: 'The ship that carried the survivors of the Flood and came to rest on a mountain.',
      storyTr: 'Tufan anlatısında Nuh, her canlıdan bir çifti gemiye alır; sular çekilince gemi bir dağa oturur. Tevrat\'ta "Ararat dağları", Kur\'an\'da Cudi Dağı anılır. Batı geleneği Ararat\'ı Ağrı Dağı ile özdeşleştirir; Ağrı\'nın eteklerinde gemiyle ilgili anlatılar bugün de yaşar.',
      storyEn: 'In the Flood story Noah takes a pair of every creature aboard; when the waters recede the ship comes to rest on a mountain. The Torah names "the mountains of Ararat", the Quran Mount Judi. Western tradition identifies Ararat with Mount Ağrı, and stories of the ark still live at its foot.',
      sourceTr: 'Tevrat (Yaratılış); Kur\'an (Hud suresi)',
      sourceEn: 'The Torah (Genesis); the Quran (sura Hud)',
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
      id: 'nemrut',
      nameTr: 'Nemrut Dağı',
      nameEn: 'Mount Nemrut',
      whoTr: 'Kendini tanrılarla yan yana oturttuğu dev heykellerle anan bir kralın tepesi.',
      whoEn: 'The summit of a king who had himself carved as a giant seated beside the gods.',
      storyTr: 'Kommagene Kralı I. Antiokhos MÖ 1. yüzyılda Nemrut Dağı\'nın zirvesine bir tümülüs yaptırdı; doğu ve batı teraslarına kendisini Zeus, Apollon, Herakles ve Kommagene\'nin tanrıçasıyla yan yana oturan dev heykeller olarak diktirdi. Depremlerle heykellerin başları düştü. 1987\'de UNESCO Dünya Mirası oldu.',
      storyEn: 'In the 1st century BC King Antiochus I of Commagene had a tumulus raised on the summit of Mount Nemrut, and on its east and west terraces giant statues of himself seated beside Zeus, Apollo, Heracles and the goddess of Commagene. Earthquakes toppled the statues\' heads. It became a UNESCO World Heritage Site in 1987.',
      sourceTr: 'Arkeoloji; UNESCO (1987)',
      sourceEn: 'Archaeology; UNESCO (1987)',
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
      id: 'ejder',
      nameTr: 'Palandöken\'in Ejderleri',
      nameEn: 'The Dragons of Palandöken',
      whoTr: 'Erzurum\'un Palandöken dağlarının iki doruğu: Büyük Ejder ve Küçük Ejder.',
      whoEn: 'Two summits of Erzurum\'s Palandöken mountains: the Great Dragon and the Little Dragon.',
      storyTr: 'Palandöken dağlarının en yüksek doruğuna Büyük Ejder Tepesi, yanındakine Küçük Ejder denir. Dağın adının, ağır kışta kervanların palanlarını (semerlerini) dökerek geçtiği yoldan geldiği anlatılır.',
      storyEn: 'The highest summit of the Palandöken mountains is called the Great Dragon, and the one beside it the Little Dragon. The mountain\'s name is said to come from the road where, in hard winters, caravans shed their saddles (palan) to get through.',
      sourceTr: 'Erzurum halk anlatıları',
      sourceEn: 'Erzurum folk tales',
    ),
    MythCard(
      id: 'peri',
      nameTr: 'Peri bacaları',
      nameEn: 'The fairy chimneys',
      whoTr: 'Kapadokya\'nın şapkalı kayaları; halkın perilerin evi saydığı bacalar.',
      whoEn: 'Cappadocia\'s capped rock spires; the chimneys people believed were the homes of fairies.',
      storyTr: 'Peri bacaları, volkanik tüfün rüzgâr ve yağmurla aşınmasından oluşur; üstlerindeki sert kaya şapka gibi altını korur. Halk, böyle tuhaf biçimleri ancak perilerin yapabileceğine inanmış ve onlara perilerin bacası demiştir.',
      storyEn: 'The fairy chimneys were formed as wind and rain wore down volcanic tuff, the harder rock on top shielding the softer stone below like a cap. People believed only fairies could have made such strange shapes, and called them the fairies\' chimneys.',
      sourceTr: 'Kapadokya halk anlatıları',
      sourceEn: 'Cappadocian folk tales',
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
      id: 'derinkuyu',
      nameTr: 'Derinkuyu',
      nameEn: 'Derinkuyu',
      whoTr: 'Kapadokya\'da yerin sekiz kat altına inen saklı şehir.',
      whoEn: 'The hidden city that reaches eight floors beneath the earth in Cappadocia.',
      storyTr: 'Derinkuyu\'da yumuşak tüfe oyulmuş katlar ahırlar, şaraphaneler, mutfaklar, bir şapel ve derin havalandırma bacalarıyla iner; geçitler yalnızca içeriden yuvarlanan taş kapılarla kapanır. Ne zaman kazılmaya başlandığı bilinmez; Bizans döneminde genişletildiği düşünülür. 1963\'te bir evin onarımı sırasında yeniden bulundu.',
      storyEn: 'At Derinkuyu, floors carved into soft tuff descend with stables, wine cellars, kitchens, a chapel and deep ventilation shafts; passages close only with round stone doors rolled from within. No one knows when the digging began; it is thought to have been enlarged in Byzantine times. It was rediscovered in 1963 during the repair of a house.',
      sourceTr: 'Arkeoloji',
      sourceEn: 'Archaeology',
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
    MythCard(
      id: 'kam',
      nameTr: 'Kam',
      nameEn: 'Kam (Shaman)',
      whoTr: 'Göğün ve yerin katları arasında yolculuk eden şaman; davulu yol açar.',
      whoEn: 'The shaman who journeys between the layers of sky and earth; his drum opens the way.',
      storyTr:
          'Altay ve Sibirya Türklerinde kam, ayin sırasında ruhunu göğün '
          'katlarına ya da yerin altına gönderir. Davulu onun bineği '
          'sayılır; davulun derisine göğün, yerin ve hayat ağacının '
          'resimleri çizilir.',
      storyEn:
          'Among the Altai and Siberian Turks, the kam sends his soul to the '
          'layers of the sky or beneath the earth during the rite. His drum '
          'is said to be his mount; pictures of the sky, the earth and the '
          'tree of life are painted on its hide.',
      sourceTr: 'Altay şamanlığı (Radloff, Anohin derlemeleri)',
      sourceEn: 'Altai shamanism (collected by Radloff, Anokhin)',
    ),
    MythCard(
      id: 'ayAtaGunAna',
      nameTr: 'Ay Ata ve Gün Ana',
      nameEn: 'Ay Ata and Gün Ana',
      whoTr:
          'Kimi Türk anlatılarında Ay erkek ata, Güneş dişi ana olarak anılır.',
      whoEn:
          'In some Turkic tellings the Moon is a father and the Sun a mother.',
      storyTr:
          'Eski Türk inancında gök cisimleri kutsal sayılır. Kimi '
          'anlatılarda Ay, Ay Ata; Güneş, Gün Ana diye anılır. Oğuz Kağan '
          'Destanı\'nda Oğuz\'un oğullarından ikisinin adı Gün ve Ay\'dır.',
      storyEn:
          'In old Turkic belief the heavenly bodies were held sacred. In some '
          'tellings the Moon is called Ay Ata and the Sun Gün Ana. In the '
          'Oghuz Khagan epic two of Oghuz\'s sons are named Gün (Sun) and Ay '
          '(Moon).',
      sourceTr: 'Türk halk inançları; Oğuz Kağan Destanı',
      sourceEn: 'Turkic folk belief; Oghuz Khagan epic',
    ),
    MythCard(
      id: 'umayKusu',
      nameTr: 'Umay kuşu (Hüma)',
      nameEn: 'The Umay bird (Huma)',
      whoTr: 'Gölgesi kime düşerse ona talih ve kut getirdiğine inanılan kuş.',
      whoEn: 'The bird whose shadow is believed to bring fortune and kut to whomever it falls on.',
      storyTr:
          'Türk ve İran anlatılarında Hüma, hiç konmadan uçan efsanevi bir '
          'kuştur; gölgesinin düştüğü kişinin hükümdar olacağına inanılır. '
          'Anadolu\'da "devlet kuşu" da denir; Umay\'la birlikte anılır.',
      storyEn:
          'In Turkic and Persian tales the Huma is a legendary bird that flies '
          'without ever landing; whoever its shadow falls on is said to '
          'become a ruler. In Anatolia it is also called the "bird of '
          'fortune", and it is spoken of together with Umay.',
      sourceTr: 'Türk ve İran halk anlatıları',
      sourceEn: 'Turkic and Persian folk tales',
    ),
    MythCard(
      id: 'ulgen',
      nameTr: 'Ülgen',
      nameEn: 'Ülgen',
      whoTr: 'Göğün katlarında oturan iyiliğin ve aydınlığın temsilcisi.',
      whoEn: 'The one who dwells in the layers of the sky; the source of goodness and light.',
      storyTr:
          'Altay inancında Ülgen, göğün yüksek katlarında oturan, iyiliğin '
          've aydınlığın kaynağı olan yaratıcı güçtür; Erlik onun '
          'karşıtıdır. Kamlar en yüksek katlara ancak uzun bir yolculukla '
          'ulaşır.',
      storyEn:
          'In Altai belief Ülgen is the creative power who dwells in the high '
          'layers of the sky, the source of goodness and light; Erlik is his '
          'opposite. Shamans reach the highest layers only after a long '
          'journey.',
      sourceTr: 'Altay yaratılış destanı (W. Radloff derlemesi)',
      sourceEn: 'Altai creation epic (collected by W. Radloff)',
    ),
    MythCard(
      id: 'sebiArus',
      nameTr: 'Şeb-i Arûs',
      nameEn: 'Sheb-i Arus',
      whoTr: 'Mevlânâ\'nın ölüm gecesi: sevgiliye kavuşma, "düğün gecesi".',
      whoEn: 'The night of Rumi\'s death: union with the Beloved, the "wedding night".',
      storyTr: 'Mevlânâ Celâleddin Rûmî 17 Aralık 1273\'te Konya\'da öldü. Ölümü sevgiliye, Tanrı\'ya kavuşma sayıldığı için o geceye Şeb-i Arûs, düğün gecesi denir ve her yıl semâ ile anılır. Mevlevi semâ töreni 2008\'de UNESCO listesine alındı.',
      storyEn: 'Rumi (Mevlânâ Celâleddin) died in Konya on 17 December 1273. Because his death was seen as union with the Beloved, with God, that night is called Sheb-i Arus, the wedding night, and is remembered every year with the sema. The Mevlevi sema ceremony was inscribed on the UNESCO list in 2008.',
      sourceTr: 'Mevlevi geleneği; UNESCO (2008)',
      sourceEn: 'The Mevlevi tradition; UNESCO (2008)',
    ),
    MythCard(
      id: 'otuken',
      nameTr: 'Ötüken',
      nameEn: 'Ötüken',
      whoTr: 'Göktürklerin kutlu saydığı ormanlı dağ; ilin ve kutun yurdu.',
      whoEn: 'The forested mountain held sacred by the Göktürks; homeland of the realm and its kut.',
      storyTr: 'Orhun Yazıtları\'nda Ötüken Yış, yani Ötüken ormanı, devletin kalbidir. Kül Tigin Yazıtı ili tutacak yerin Ötüken olduğunu, orada oturan Türk budununun bengü (ebedî) kalacağını söyler. Bugün Moğolistan\'daki Hangay dağlarında olduğu düşünülür. Eski Türk inancında dağın ve ormanın iyesi vardır; Ötüken\'in kutlu yeri ve suyu (ıduk yer-sub) halkı korur.',
      storyEn: 'In the Orkhon inscriptions Ötüken Yış, the forest of Ötüken, is the heart of the realm. The Kül Tigin inscription says the place to hold the realm is Ötüken, and that the Turkic people dwelling there will endure forever. Today it is thought to lie in the Khangai mountains of Mongolia. In old Turkic belief mountains and forests have their spirits; the sacred land and water of Ötüken (ıduk yer-sub) protect the people.',
      sourceTr: 'Orhun Yazıtları (Kül Tigin, Bilge Kağan)',
      sourceEn: 'Orkhon Inscriptions (Kül Tigin, Bilge Kagan)',
    ),
    MythCard(
      id: 'akGeyik',
      nameTr: 'Ak Geyik',
      nameEn: 'The White Deer',
      whoTr: 'Kahramanlara bilmedikleri yolu gösteren kutlu geyik.',
      whoEn: 'The sacred deer that shows heroes a road they do not know.',
      storyTr: 'Jordanes\'in Priskos\'a dayanarak aktardığı Hun anlatısında avcılar bir geyiği kovalarken onun Meotis (Azak) bataklığını geçtiğini gördü; bataklığın geçilebildiğini böyle öğrendiler, geyik de karşı kıyıda kayboldu. Kırgızların Bugu boyu soyunu Boynuzlu Geyik Ana\'ya bağlar. Türk anlatılarında ak geyik çoğu zaman bir ananın ya da bir ruhun kılığıdır ve kahramanı yeni bir yurda götürür.',
      storyEn: 'In the Hun tale told by Jordanes after Priscus, hunters chasing a deer saw it cross the Maeotian (Azov) marsh; that is how they learned the marsh could be crossed, and the deer vanished on the far shore. The Bugu tribe of the Kyrgyz trace their line to the Horned Mother Deer. In Turkic tales the white deer is often the guise of a mother or a spirit, leading the hero to a new homeland.',
      sourceTr:
          'Jordanes, Getica (Priskos\'tan); Kırgız Boynuzlu Geyik Ana anlatısı',
      sourceEn: 'Jordanes, Getica (after Priscus); the Kyrgyz tale of the Horned Mother Deer',
    ),
    MythCard(
      id: 'hayatAgaci',
      nameTr: 'Hayat Ağacı',
      nameEn: 'The Tree of Life',
      whoTr: 'Yeri ve göğü birbirine bağlayan ulu ağaç; kökü yerin altında, dalları gökte.',
      whoEn: 'The great tree binding earth and sky; its roots below the earth, its branches in the heavens.',
      storyTr: 'Altay ve Yakut Türklerinin anlatılarında dünyanın ortasında ulu bir ağaç yükselir; Yakutlar ona Aal Luuk Mas der. Kökleri yerin altına, tepesi göğün katlarına uzanır. Doğacak çocukların canlarının kuş olup dallarına konduğu, Umay\'ın onları oradan indirdiği anlatılır. Kamın davulunun çerçevesi bu ağacın dalından yapılır; kam göğe çıkarken onun gövdesine tırmanır.',
      storyEn: 'In the tales of the Altai and Yakut Turks a great tree rises at the middle of the world; the Yakuts call it Aal Luuk Mas. Its roots reach beneath the earth, its crown into the layers of the sky. It is told that the souls of children yet to be born perch on its branches as birds, and that Umay brings them down from there. The frame of the shaman\'s drum is made from its wood; climbing to the sky, the shaman climbs its trunk.',
      sourceTr: 'Yakut ve Altay anlatıları (Radloff, Anohin derlemeleri)',
      sourceEn: 'Yakut and Altai tales (collected by Radloff, Anokhin)',
    ),
  ];
}
