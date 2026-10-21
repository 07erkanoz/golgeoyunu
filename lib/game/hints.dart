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
  static String text(String key) {
    var s = (S.en ? _en : _tr)[key] ?? _tr[key] ?? key;
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
    'kormos': 'Körmösler ışığa gelir · {down} kavanozunu ört · ya da ateşböceği sal: {firefly}',
    'kut': '{up} Kafesi aç · kut kavanoza girer, kapı açılır · kavanoz parladıkça Körmösler uzaktan görür',
    'horse': 'Çalkuyruk · yanına git, sırtına bin · atla çok yükseğe sıçrarsın',
    'gokboruTrail':
        '{down} Kavanozunu ört · Gökbörü\'nün izleri karanlıkta parlar',
    'valve': '{up} Vanayı çevir',
    'scale': 'Terazi · eşleri iki kefeye koy · ağırlıklar denk gelmeli · {up} kol teraziyi boşaltır',
    'cord': '{up} İpi çek · kandil perdenin ardında kayar',
    'eyeStone': 'Dev gölgenin başı perdedeki göze · kavanozunun ışığı taştaki göze · ikisi birden',
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
    'giant': '{firefly} Devin kulağına üç kez ateşböceği sal',
    'wolf': 'Kurt kokunu alır · yükseğe çık ya da {firefly}',
    'ice': 'İnce buzda durma · çatlar',
    'ski': '{right} hızlan · {left} yavaşla · {jump} sıçra',
    'ring': 'Peri halkasına bas · göğe fırla',
    'millstone': 'Sürgü taşını it · basamak yap',
    'semazen': '{sneak} Önden geçen semâzenin eteğinde yürü',
    'chandelier': 'Mum tablasına zıpla · avize seni taşır',
    'lamp': 'Gölgede bekle · huzme geçince koş',
    'flood': 'Tırman!',
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
    'eyeStone': 'The giant shadow\'s head on the eye in the screen · your jar\'s light on the eye in the stone · both at once',
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
    'giant': '{firefly} Release a firefly at the giant\'s ear, three times',
    'wolf': 'Wolves smell you · climb high or {firefly}',
    'ice': 'Don\'t stand on thin ice · it cracks',
    'ski': '{right} speed up · {left} slow down · {jump} leap',
    'ring': 'Step on the fairy ring · fly up',
    'millstone': 'Push the rolling stone · make a step',
    'semazen': '{sneak} Walk in the skirt of the dervish passing in front',
    'chandelier': 'Jump onto a candle tray · the chandelier carries you',
    'lamp': 'Wait in shadow · run when the beam has passed',
    'flood': 'Climb!',
  };

  /// Hikâyeye karışan şiirsel bilmeceler (alttaki fısıltıyla anlatılır).
  static String poem(String key) => (S.en ? _poemEn : _poemTr)[key] ?? '';

  static const _poemTr = {
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
