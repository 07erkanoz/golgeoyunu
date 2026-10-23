import 'package:flutter/foundation.dart';

import '../settings.dart';
import 'strings.dart';

/// Düzeneklerin nasıl kullanıldığını ilk karşılaşmada bir kez söyleyen
/// ipuçları. Kontroller cihaza göre yazılır: klavye, dokunmatik düğmeler ya
/// da dokunmatik hareket.
class Hints {
  Hints._();

  static bool get _touch =>
      const bool.fromEnvironment('TOUCH') ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS));

  static Map<String, String> get _controls {
    if (!_touch) {
      return S.en
          ? const {
              'down': '↓',
              'up': '↑',
              'jump': 'Space',
              'glide': 'hold Space',
              'sneak': 'Shift',
              'firefly': 'F',
              'move': '← →',
              'left': '←',
              'right': '→',
            }
          : const {
              'down': '↓',
              'up': '↑',
              'jump': 'Boşluk',
              'glide': 'Boşluğu basılı tut',
              'sneak': 'Shift',
              'firefly': 'F',
              'move': '← →',
              'left': '←',
              'right': '→',
            };
    }
    if (Settings.touchGestures) {
      return S.en
          ? const {
              'down': 'drag down',
              'up': 'drag up',
              'jump': 'tap the right side',
              'glide': 'hold the right side',
              'sneak': 'tiptoe button',
              'firefly': 'tap ✨',
              'move': 'drag left or right',
              'left': 'drag left',
              'right': 'drag right',
            }
          : const {
              'down': 'aşağı sürükle',
              'up': 'yukarı sürükle',
              'jump': 'sağ yarıya dokun',
              'glide': 'sağ yarıya basılı tut',
              'sneak': 'parmak ucu düğmesi',
              'firefly': '✨ simgesine dokun',
              'move': 'sola ya da sağa sürükle',
              'left': 'sola sürükle',
              'right': 'sağa sürükle',
            };
    }
    return S.en
        ? const {
            'down': 'crouch button',
            'up': 'climb button',
            'jump': 'jump button',
            'glide': 'hold jump',
            'sneak': 'tiptoe button',
            'firefly': 'firefly button',
            'move': '◀ ▶',
            'left': '◀',
            'right': '▶',
          }
        : const {
            'down': 'çömel düğmesi',
            'up': 'tırman düğmesi',
            'jump': 'zıpla düğmesi',
            'glide': 'zıplaya basılı tut',
            'sneak': 'parmak ucu düğmesi',
            'firefly': 'ateşböceği düğmesi',
            'move': '◀ ▶',
            'left': '◀',
            'right': '▶',
          };
  }

  /// İpucunun seçili dilde, bu cihazın kontrolleriyle yazılmış metni.
  static String text(String key) =>
      fill((S.en ? _en : _tr)[key] ?? _tr[key] ?? key);

  /// Metindeki tuş yer tutucularını bu cihazın kontrolleriyle doldurur.
  static String fill(String s) {
    for (final e in _controls.entries) {
      s = s.replaceAll('{${e.key}}', e.value);
    }
    return sides(s);
  }

  /// Sol elle oynamada dokunmatik metinlerdeki sağ ve sol yer değiştirir.
  static String sides(String s) {
    if (!Settings.leftHanded) return s;
    const pairs = [
      ('Sol yarı', 'Sağ yarı'),
      ('sol yarı', 'sağ yarı'),
      ('Left half', 'Right half'),
      ('left half', 'right half'),
      ('left side', 'right side'),
    ];
    for (final (a, b) in pairs) {
      s = s.replaceAll(a, '\u0000').replaceAll(b, a).replaceAll('\u0000', b);
    }
    return s;
  }

  static bool has(String key) => _tr.containsKey(key);

  static const _tr = {
    'fireflyPickup': 'Ateşböceklerine dokun · kavanoza girerler',
    'hide': '{down} Çömel ya da gölgede dur · saklanırsın',
    'guard': '{firefly} Ateşböceği sal · Kandilci ışığa gider',
    'climb': '{up} Tırman · bırakmak için yön + {jump}',
    'lightPlank': 'Işık tahtası · kavanozun açıkken var olur',
    'shadePlank': '{down} Çömel · gölge tahtası ışıkta erir',
    'crate': 'Sandığı it · üstüne çıkıp yüksel',
    'lever': '{up} Kolu çek',
    'umay': 'Umay ağacı · dokun: düştüğünde buradan yeniden başlarsın',
    'drum': 'Kam\'ın davulu · her vuruşta bir bulut takımı belirir, öbürü söner · vuruşu bekle, sonra atla',
    'scorch':
        'Gün katının ışığı yakar · Hüma\'nın gölgesinde, onunla birlikte yürü',
    'tulpar': 'Tulpar · sırtına bin · havada zıplayınca kanat çırpar: {jump}',
    'forge': 'Ocak sönmüş · yanına ateşböceği sal, yeniden yansın: {firefly}',
    'bellows': '{up} Körüğe bas · üstündeki çentik sayısı sırasıyla · sıra bozulur ya da geç kalırsan ateş söner',
    'bellowsBeat': '{up} Körüğü çekiç örse indiği anda bas · basılan körük dolana dek öbürüne koş',
    'fuel': 'Ocak boş · kömür sandıklarını ocağın önündeki çukura it · birini basamak için sakla',
    'goalFuel':
        'Kömür sandıklarını ocağın önündeki ışıklı çukura it ({n}/{need})',
    'goalLight': 'Ocağın ağzına bir ateşböceği at: {firefly}',
    'goalBeat':
        'Körüğün üstündeki halka kapanıp parlayınca bas: {up} · ısı %{heat}',
    'goalOrder': 'Körüklere üstlerindeki çentik sayısı sırasıyla bas: {up} · sıradaki {next}',
    'goalForge': 'Ocak',
    'nevruz': '{up} Demire üç kez vur',
    'molten': 'Akan demir yakar · soğuyup kararınca üstünden geç',
    'kormos': 'Körmösler ışığa gelir · {down} kavanozunu ört · ya da ateşböceği sal: {firefly}',
    'kut': '{up} Kafesi aç · kut kavanoza girer, kapı açılır · kavanoz parladıkça Körmösler uzaktan görür',
    'horse': 'Çalkuyruk · yanına git, sırtına bin · atla çok yükseğe sıçrarsın',
    'gokboruTrail':
        '{down} Kavanozunu ört · Gökbörü\'nün izleri karanlıkta parlar',
    'valve': '{up} Vanayı çevir',
    'scale': 'Terazi · eşleri iki kefeye koy · ağırlıklar denk gelmeli · {up} kol teraziyi boşaltır',
    'cord': '{up} İpi çek · kandil perdenin ardında kayar',
    'eyeStone': 'Dev gölgenin başı perdedeki göze · kavanozunun ışığı taştaki göze · ikisi birden: kapı açılır',
    'lift': 'Bir kefeye sandık koy · öteki yükselir',
    'rotten': 'Çürük tahta seni taşır · Kandilci\'yi taşımaz',
    'bats': '{sneak} Parmak ucunda · yarasaları uyandırma',
    'crow': '{sneak} Parmak ucunda · karga bağırmasın',
    'watcher': '{firefly} Ateşböceği sal · Gözcü ışığını ona çevirir',
    'mirror': '{up} Aynayı çevir · ışığı kilide yönelt',
    'medusa': 'Gözler açıkken kıpırdama',
    'shield': 'Kalkanı it · ardında saklan',
    'raft': '{move} Salı it · karşı kıyıda {jump} ile in',
    'vent': 'Alev sönünce geç · ya da sandıkla tıka',
    'balloon': 'Fener balonunun ışığına girme',
    'wings': '{glide} · süzül',
    'glide': '{glide} · süzül',
    'wind': 'Rüzgâr akımı · {glide}, yüksel',
    'feather': 'Simurg\'un tüylerini topla',
    'crumble': 'Çatlak kaya kopar · üstünde durma',
    'rope': 'İpe zıpla · {move} sallan · {jump} bırak',
    'bell': '{sneak} Yavaş geç · ya da {up} çal, Kandilcileri çek',
    'icicle': 'Sarkıtların altında durma',
    'animal': 'Hayvanı eşinin gölgesine it',
    'star': '{up} Yıldız taşını çevir · Aslan\'ın sırasını kur',
    'boulder': 'Gevşek kayaların altında durma',
    'giant': 'İşaretten çekil · kulağı parlayınca {firefly} ateşböceği sal: atıştan sonra ya da soluklanırken (üç kez)',
    'wolf': 'Kurt kokunu alır · yükseğe çık ya da {firefly}',
    'ice': 'İnce buzda durma · çatlar',
    'ski': '{right} hızlan · {left} yavaşla · {jump} sıçra',
    'ring': 'Peri halkasına bas · göğe fırla',
    'millstone': 'Sürgü taşını it · basamak yap',
    'semazen': '{sneak} Önden geçen semâzenin eteğinde yürü',
    'chandelier': 'Mum tablasına zıpla · avize seni taşır',
    'lamp': 'Gölgede bekle · huzme geçince koş',
    'flood': 'Tırman!',
    'storm': 'Fırtına arkandan geliyor · durma, Tulpar\'la ileri uç',
    'mist': 'Sis çukurları gizler · {down} kavanozunu ört, Gökbörü\'nün izleri yolu gösterir',
    'avalanche': 'Çığ geliyor · {right} hızlan, yavaşlama',
    'magnet': 'Manyetik Tepe · kar yokuş yukarı akar, bırak taşısın',
    'flip': 'Havadayken {jump} basılı tut · takla at, hızlan · geniş uçurumlar ancak takla hızıyla aşılır',
  };

  static const _en = {
    'fireflyPickup': 'Touch the fireflies · they fly into your jar',
    'hide': '{down} Crouch or stand in shadow · you are hidden',
    'guard': '{firefly} Release a firefly · the Lamplighter follows it',
    'climb': '{up} Climb · to let go, direction + {jump}',
    'lightPlank': 'Plank of light · exists while your jar is open',
    'shadePlank': '{down} Crouch · the shadow plank melts in light',
    'crate': 'Push the crate · climb it to reach higher',
    'lever': '{up} Pull the lever',
    'umay': 'Umay tree · touch it: if you fall, you rise here again',
    'drum': 'Kam\'s drum · on each beat one set of clouds appears and the other fades · wait for the beat, then jump',
    'scorch': 'The light of the sun layer burns · walk in the Huma\'s shadow, along with it',
    'tulpar': 'Tulpar · climb on his back · jump in the air to beat his wings: {jump}',
    'forge': 'The forge is cold · release a firefly beside it to light it again: {firefly}',
    'bellows': '{up} Pump the bellows · in the order of the notches on each · break the order or wait too long and the fire dies',
    'bellowsBeat': '{up} Pump a bellows just as the hammer hits the anvil · run to another while it refills',
    'fuel': 'The forge is empty · push the charcoal crates into the pit before it · keep one as a step',
    'goalFuel': 'Push the charcoal crates into the glowing pit before the forge ({n}/{need})',
    'goalLight': 'Throw a firefly into the forge mouth: {firefly}',
    'goalBeat': 'Pump the bellows when the ring above it closes and flashes: {up} · heat {heat}%',
    'goalOrder':
        'Pump the bellows in the order of their notches: {up} · next {next}',
    'goalForge': 'Forge',
    'nevruz': '{up} Strike the iron three times',
    'molten': 'Flowing iron burns · cross only when it cools and darkens',
    'kormos': 'Körmös drift toward light · {down} cover your jar · or release a firefly: {firefly}',
    'kut': '{up} Open the cage · the kut enters your jar and a gate opens · the brighter the jar, the farther the Körmös see',
    'horse':
        'Çalkuyruk · go to him and climb on · on horseback you leap far higher',
    'gokboruTrail':
        '{down} Cover your jar · Gökbörü\'s tracks glow in the dark',
    'valve': '{up} Turn the valve',
    'scale':
        'The scales · put the pair on the two pans · the weights must match',
    'cord': '{up} Pull the cord · the lamp slides behind the screen',
    'eyeStone': 'The giant shadow\'s head on the eye in the screen · your jar\'s light on the eye in the stone · both at once: the gate opens',
    'lift': 'Put a crate on one pan · the other rises',
    'rotten': 'Rotten planks hold you · not a Lamplighter',
    'bats': '{sneak} Tiptoe · don\'t wake the bats',
    'crow': '{sneak} Tiptoe · don\'t let the crow cry out',
    'watcher': '{firefly} Release a firefly · the Watcher turns to it',
    'mirror': '{up} Turn the mirror · lead the light to the lock',
    'medusa': 'Don\'t move while her eyes are open',
    'shield': 'Push the shield · hide behind it',
    'raft': '{move} Pole the raft · at the far bank, {jump} off',
    'vent': 'Pass when the flame dies · or plug it with a crate',
    'balloon': 'Stay out of the lantern balloon\'s light',
    'wings': '{glide} · glide',
    'glide': '{glide} · glide',
    'wind': 'Wind current · {glide}, rise',
    'feather': 'Gather the Simurgh\'s feathers',
    'crumble': 'Cracked rock breaks · don\'t stand still',
    'rope': 'Jump to the rope · {move} swing · {jump} let go',
    'bell': '{sneak} Pass slowly · or {up} ring it to draw them away',
    'icicle': 'Don\'t stop under the icicles',
    'animal': 'Push the animal to its mate\'s shadow',
    'star': '{up} Turn the star stone · match the Lion\'s order',
    'boulder': 'Don\'t stop under loose boulders',
    'giant': 'Step off the mark · when its ear glows, {firefly} release a firefly: after a throw or while it rests (three times)',
    'wolf': 'Wolves smell you · climb high or {firefly}',
    'ice': 'Don\'t stand on thin ice · it cracks',
    'ski': '{right} speed up · {left} slow down · {jump} leap',
    'ring': 'Step on the fairy ring · fly up',
    'millstone': 'Push the rolling stone · make a step',
    'semazen': '{sneak} Walk in the skirt of the dervish passing in front',
    'chandelier': 'Jump onto a candle tray · the chandelier carries you',
    'lamp': 'Wait in shadow · run when the beam has passed',
    'flood': 'Climb!',
    'storm': 'The storm is behind you · don\'t stop, fly on with Tulpar',
    'mist': 'The mist hides the pits · {down} cover your jar, Gökbörü\'s prints show the way',
    'avalanche': 'An avalanche is coming · {right} speed up, don\'t slow down',
    'magnet': 'The Magnetic Hill · the snow flows uphill, let it carry you',
    'flip': 'Hold {jump} in the air · flip to gain speed · wide chasms are crossed only at flip speed',
  };

  /// İkinci basamak: aynı düzenekte ikinci kez ölünce söylenen ilişki
  /// ("ne neye bağlı"). Üçüncü basamak: istenince açılan somut çözüm ("Az
  /// önce" panelinde katlı durur).
  static String relation(String key) =>
      (S.en ? _relationEn : _relationTr)[key] ?? '';
  static String solution(String key) =>
      (S.en ? _solutionEn : _solutionTr)[key] ?? '';

  static const _relationTr = {
    'guard':
        'Kandilci önce sese ve ışığa döner; arkasındaki boşluk o zaman açılır.',
    'watcher':
        'Gözcü\'nün ışığı gidip gelir; yakınını ve uzağını aynı anda görmez.',
    'bell': 'Çanın sesi yakındaki Kandilcileri oraya çeker; sesin geldiği yere bakarlar.',
    'medusa': 'Medusa\'nın bakışı yalnız kıpırdayanı taşa çevirir.',
    'giant':
        'Dev taşı kaldırınca kulağını örter; attıktan sonra bir an toparlanır.',
    'kormos': 'Körmös yalnız açık ışığı görür; ışığı kaybedince son gördüğü yere süzülür.',
    'wolf': 'Kurt atılmadan önce çömelip hazırlanır; atıldıktan sonra yön değiştiremez.',
    'lamp': 'Büyük fenerin huzmesi damları sırayla tarar; gölgede kalan yer güvenlidir.',
    'bellowsBeat': 'Körük ancak çekiç örse indiği anda ocağı ısıtır; erken ya da geç basmak ısıyı düşürür.',
  };

  static const _relationEn = {
    'guard': 'A Lamplighter turns first toward sound and light; that is when the way behind him opens.',
    'watcher': 'The Watcher\'s light sweeps back and forth; it cannot see near and far at once.',
    'bell': 'The bell draws nearby Lamplighters; they look where the sound came from.',
    'medusa': 'Medusa\'s gaze turns to stone only what moves.',
    'giant': 'Lifting a stone, the giant covers its ear; after the throw it recovers for a moment.',
    'kormos': 'A Körmös sees only open light; when it loses the light it drifts to where it last saw it.',
    'wolf': 'A wolf crouches before it lunges; once it lunges, it cannot turn.',
    'lamp': 'The great lamp\'s beam sweeps the roofs in turn; whatever lies in shadow is safe.',
    'bellowsBeat': 'A bellows heats the forge only when pumped as the hammer strikes; too early or too late, the heat drops.',
  };

  static const _solutionTr = {
    'guard': 'Ateşböceğini Kandilci\'nin ardına sal ya da yakındaki çanı çal. Başını çevirince sütunun ardından geç. Görüldüysen aynı sütunda bekleme; bir sonrakine geç.',
    'watcher': 'Işığın uçtan uca gidişini bir kez izle. Işık senden uzağa döndüğü anda koş, sıradaki siperde dur. Ateşböceği salarsan Gözcü ışığını ona çevirir.',
    'bell': 'Çana ateşböceği sal ya da altından koşarak geç. Kandilci sese yürürken sütunun ardında çömel; o geçince öbür yana ilerle.',
    'medusa': 'Gözleri kapanınca bir sonraki sütuna yürü; aralanınca dur, kıpırdama. Kalkan varsa önüne it, ardında yürü.',
    'giant': 'Dev yürürken kulağını korur. İşaret belirince yerinden çekil; taş düşer düşmez, dev toparlanırken ya da yolun sonunda soluklanırken kulağı parlar: o an rafa çık, ateşböceği sal. Üç kez. Ateşböceğin bitince devden uzaklaş: yenileri başka yerde çıkar.',
    'kormos': 'Kavanozunu ört ve hemen yer değiştir: Körmös eski yerinde ararken karanlıktan geç. Ateşböceği salarsan onu uzağa çeker.',
    'wolf': 'Kurt çömelince yana ya da yukarı çekil. İnce buzun kenarında beklersen atılışı onu buza düşürür. Ateşböceği kurdu bir süre korkutur.',
    'lamp': 'Revakın ya da bacanın gölgesinde dur. Huzme üstünden geçip uzaklaşınca bir sonraki gölgeye koş; huzmede bir an bile kalma.',
    'bellowsBeat': 'Örsü dinle: çekiç inerken körüğün hazır ışığı yanar, o anda bas. Körük dolarken öbürüne koş, sıradaki vuruşu bekle.',
  };

  static const _solutionEn = {
    'guard': 'Release a firefly behind the Lamplighter or ring a nearby bell. When he turns his head, slip past behind the column. If you were seen, do not wait at the same column; move to the next.',
    'watcher': 'Watch the light sweep end to end once. Run the moment it turns away from you and stop at the next cover. A firefly makes the Watcher turn its light to it.',
    'bell': 'Release a firefly at the bell or run beneath it. While the Lamplighter walks to the sound, crouch behind a column; once he has passed, go the other way.',
    'medusa': 'Walk to the next column when her eyes close; stop and stay still as they open. If there is a shield, push it ahead and walk behind it.',
    'giant': 'Walking, the giant guards its ear. Step away when the mark appears; as the stone lands, while it recovers or rests at the end of its path, its ear glows: climb to the shelf and release a firefly. Three times. Out of fireflies? Get away from the giant: new ones appear elsewhere.',
    'kormos': 'Cover your jar and move at once: while the Körmös searches the old spot, pass through the dark. A firefly draws it away.',
    'wolf': 'When the wolf crouches, step aside or climb. Wait at the edge of thin ice and its lunge will drop it in. A firefly scares the wolf for a while.',
    'lamp': 'Stand in the shadow of a porch or chimney. When the beam has passed over and away, run to the next shadow; never stay in the beam even for a moment.',
    'bellowsBeat': 'Listen to the anvil: as the hammer falls the bellows\' ready light glows; pump then. While it refills, run to the other and wait for the next strike.',
  };

  /// Hikâyeye karışan şiirsel bilmeceler (alttaki fısıltıyla anlatılır).
  static String poem(String key) => (S.en ? _poemEn : _poemTr)[key] ?? '';

  static const _poemTr = {
    'giant':
        'Taş dev taşı kaldırınca kulağını örter.\n'
        'Taşın düşeceği yer önceden bellidir: orada durma.\n'
        'Atan kol ağırdır; toparlanırken kulak açıktır.',
    'umay':
        'Taşın çatlağında bir kayın.\n'
        'Umay her çocuğun yanındadır: düşersen buradan kalkarsın.',
    'medusa':
        'Taş yüzlü kadın uyur, sonra uyanır.\n'
        'Gözü kapalıyken yürü; gözü aralanınca dur.\n'
        'Bakışında kıpırdayan taşa döner,\n'
        'kıpırdamayanı görmez bile.',
    'shield':
        'Perseus ona hiç doğrudan bakmadı.\n'
        'Cilalı kalkanın ardında yürü: önündeki göz seni görmez.\n'
        'Kalkanı yüzüne tut, kendi bakışıyla taşa dönsün.\n'
        'Ama arkandaki göz açılınca sen de taş kesil: kıpırdama.',
  };

  static const _poemEn = {
    'giant':
        'Lifting a stone, the giant covers its ear.\n'
        'Where the stone will fall is known before: do not stand there.\n'
        'The throwing arm is heavy; recovering, the ear is open.',
    'umay':
        'A birch in the crack of the stone.\n'
        'Umay stands by every child: if you fall, you rise here.',
    'medusa':
        'The stone-faced woman sleeps, then wakes.\n'
        'Walk while her eyes are shut; stop as they open.\n'
        'Whatever moves in her gaze turns to stone;\n'
        'whatever is still, she does not even see.',
    'shield':
        'Perseus never looked at her directly.\n'
        'Walk behind the polished shield: the eye before you cannot see you.\n'
        'Hold the shield to her face and let her own gaze turn her to stone.\n'
        'But when the eye behind you opens, be stone yourself: stand still.',
  };
}
