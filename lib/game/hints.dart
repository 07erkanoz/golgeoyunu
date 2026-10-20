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
              'firefly': 'tap with two fingers',
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
              'firefly': 'iki parmakla dokun',
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
    return s;
  }

  static bool has(String key) => _tr.containsKey(key);

  static const _tr = {
    'fireflyPickup': 'Ateşböceklerine dokun, kavanoza girerler. Hem ışığın hem Kandilcileri kandıran yemin onlardır.',
    'hide': 'Sütunun ardında ya da otların içinde dur, ya da çömel ({down}): saklanırsın, Kandilci seni göremez.',
    'guard': 'Kandilci\'nin fenerine yakalanma. Bir ateşböceği sal ({firefly}): Kandilci ışığın peşine düşer, sen geçersin. Ateşböceklerin sınırlı.',
    'climb': 'Sarmaşıkta, zincirde ve merdivende tırman ({up}). Bırakmak için bir yöne basıp zıpla ({jump}).',
    'lightPlank': 'Noktalı iz bir ışık tahtası: yalnızca ışıkta var olur. Kavanozun açıkken üstünden yürü; çömelirsen kaybolur.',
    'shadePlank': 'Koyu tahta yalnızca karanlıkta durur, kavanozunun ışığında erir. Çömel ({down}): kavanozun örtülür, tahta kalır. Çömelerek geç.',
    'crate': 'Sandığı yürüyerek it. Üstüne çıkıp yükseğe ulaşabilirsin.',
    'lever': 'Kolun yanında yukarı bas ({up}): bir kapı açılır.',
    'valve': 'Vananın yanında yukarı bas ({up}): su boşalır ya da dolar.',
    'lift': 'Terazi asansörü: ağır kefe iner, öteki çıkar. Bir kefeye sandık koy, ötekine sen bin.',
    'rotten': 'Çürük tahta seni taşır, Kandilci\'yi taşımaz. Onu bir ateşböceğiyle tahtaya çekebilirsin.',
    'bats': 'Tavanda yarasalar uyuyor. Koşma; parmak ucunda geç ({sneak}). Ürkerlerse Kandilciler sese gelir.',
    'crow': 'Karga koşanı görüp bağırır, Kandilcileri uyarır. Parmak ucunda geç ({sneak}).',
    'watcher': 'Gözcü\'nün ışığında uzun kalma. Bir ateşböceği salarsan ({firefly}) ışığını ona kilitler; bir aynayla huzmeyi gözüne çevirirsen kamaşır.',
    'mirror': 'Aynanın yanında yukarı bas ({up}): döner, ışığı başka yöne kırar. Işığı kilide ulaştır.',
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
    'raft':
        'Sala bin; üstündeyken yön tuşları salı sırıkla iter ({move}). Karşı kıyıya varınca zıplayarak in ({jump}).',
    'vent': 'Baca aralıklarla alev püskürtür. Alev sönünce geç ya da üstüne bir sandık itip tıka.',
    'balloon': 'Fener balonunun ışığına girme; görülürsen yakalanırsın. Işığı uzaklaşınca ilerle.',
    'wings': 'Hezarfen\'in kanatları. Havada süzülmek için zıplamayı basılı tut ({glide}).',
    'glide': 'Kanatların var: havada zıplamayı basılı tut ({glide}), süzül.',
    'wind': 'Rüzgâr akımı yukarı iter; kanat açıkken ({glide}) çok daha yükseğe çıkarır.',
    'feather':
        'Simurg\'un tüylerini topla. Hepsi toplanınca tüy sunağı yolu açar.',
    'crumble': 'Çatlak kaya basınca kopar. Üstünde durma, hemen atla.',
    'rope': 'İpe zıplayarak tutun, sallan ({move}), zıplayıp bırak ({jump}): savrulursun.',
    'bell': 'Çanın yanından koşarak geçme; çalarsa Kandilciler sese gelir. Parmak ucunda geç ({sneak}).',
    'icicle': 'Sarkıtlar altından geçince düşer. Hızlı geç, altında durma.',
    'animal': 'Oyma hayvanı eşinin gölgesinin önüne it: kavuşunca yol açılır. Sıra önemli.',
    'star': 'Yıldız taşının yanında yukarı bas ({up}): işaret değişir. Aslan Horoskobu\'ndaki sırayı kur.',
    'boulder': 'Gevşek kayalar depremde ya da altından geçince düşer.',
    'giant': 'Taş dev kuvvetle yenilmez. Kulağına bir ateşböceği sal ({firefly}); ayaklarının dibinde kalma.',
    'wolf': 'Kurtlar seni kokundan bulur, saklanmak yetmez. Yükseğe çık (kurt tırmanamaz) ya da ateşböceği sal ({firefly}): ışıktan korkarlar.',
    'ice': 'İnce buzda durma, çatlar. Kurtlar ağırdır; buz onları hemen kırar.',
    'ski': 'Kay: hızlan ({right}), yavaşla ({left}), sıçra ({jump}). Havada zıplamayı basılı tutarsan takla atarsın. Yere tahtaların düz gelsin.',
    'ring': 'Peri halkasına bas: seni göğe fırlatır.',
    'millstone': 'Sürgü taşını it; Kandilciler onu oynatamaz. Üstüne çıkıp basamak yapabilirsin.',
    'semazen': 'Önden geçen semâzenin eteğinde saklanırsın. Onunla birlikte parmak ucunda yürü ({sneak}); arkaya dönünce saklamaz.',
    'chandelier': 'Avizenin mum tablalarına zıpla; avize döner, seni taşır. Yükselince sıradakine atla.',
    'lamp': 'Büyük fenerin huzmesi damları tarar. Kubbenin, bacanın, revakın gölgesinde bekle; huzme geçince koş.',
    'flood': 'Işık seli yükseliyor. Durma, tırman!',
  };

  static const _en = {
    'fireflyPickup': 'Touch the fireflies and they fly into your jar. They are both your light and the bait that fools the Lamplighters.',
    'hide': 'Stand behind a pillar or in the grass, or crouch ({down}): you are hidden and the Lamplighter cannot see you.',
    'guard': 'Don\'t get caught in a Lamplighter\'s lantern. Release a firefly ({firefly}): the Lamplighter follows the light and you slip past. Your fireflies are limited.',
    'climb': 'Climb vines, chains and ladders ({up}). To let go, press a direction and jump ({jump}).',
    'lightPlank': 'The dotted trail is a plank of light: it exists only in light. Walk over it with your jar uncovered; if you crouch, it vanishes.',
    'shadePlank': 'The dark plank exists only in darkness and melts in your jar\'s light. Crouch ({down}) to cover the jar and the plank stays. Cross it crouching.',
    'crate': 'Push the crate by walking into it. Climb on it to reach higher.',
    'lever': 'Press up beside the lever ({up}): a gate opens.',
    'valve': 'Press up beside the valve ({up}): the water drains or fills.',
    'lift': 'A balance lift: the heavier pan goes down, the other rises. Put a crate on one pan and ride the other.',
    'rotten': 'The rotten plank holds you, but not a Lamplighter. Lure one onto it with a firefly.',
    'bats': 'Bats sleep on the ceiling. Don\'t run; tiptoe past ({sneak}). If they scatter, the Lamplighters come to the noise.',
    'crow': 'A crow sees anyone running and cries out to the Lamplighters. Tiptoe past ({sneak}).',
    'watcher': 'Don\'t linger in the Watcher\'s light. Release a firefly ({firefly}) and it locks its beam on it; turn a beam into its eye with a mirror and it is dazzled.',
    'mirror': 'Press up beside a mirror ({up}): it turns and bends the light. Lead the light to the lock.',
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
    'raft':
        'Step onto the raft; while on it, the direction keys pole it along ({move}). At the far bank, jump off ({jump}).',
    'vent': 'The chimney spits flame now and then. Pass when it dies down, or push a crate on top to plug it.',
    'balloon': 'Stay out of the lantern balloon\'s light; if you are seen, you are caught. Move on when the light drifts away.',
    'wings': 'Hezarfen\'s wings. To glide in the air, hold jump ({glide}).',
    'glide': 'You have wings: hold jump in the air ({glide}) to glide.',
    'wind': 'The wind current pushes you up; with your wings open ({glide}) it lifts you much higher.',
    'feather': 'Gather the Simurgh\'s feathers. When all are found, the feather altar opens the way.',
    'crumble':
        'Cracked rock breaks when you step on it. Don\'t stand still; jump on.',
    'rope': 'Jump to grab the rope, swing ({move}), then jump to let go ({jump}) and fly.',
    'bell': 'Don\'t run past the bell; if it rings, the Lamplighters come. Tiptoe past ({sneak}).',
    'icicle': 'Icicles fall when you pass beneath. Move fast; don\'t stop under them.',
    'animal': 'Push the carved animal before its mate\'s shadow: when they are reunited, the way opens. Order matters.',
    'star': 'Press up beside a star stone ({up}): its sign changes. Match the order on the Lion Horoscope.',
    'boulder': 'Loose boulders fall in a quake, or when you pass beneath.',
    'giant': 'The stone giant cannot be beaten by strength. Release a firefly into its ear ({firefly}); stay away from its feet.',
    'wolf': 'Wolves find you by your scent; hiding is not enough. Climb high (wolves cannot climb) or release a firefly ({firefly}): they fear the light.',
    'ice': 'Don\'t stand on thin ice; it cracks. Wolves are heavy, and the ice breaks under them at once.',
    'ski': 'Ski: speed up ({right}), slow down ({left}), leap ({jump}). Hold jump in the air to flip. Land with your skis flat.',
    'ring': 'Step on the fairy ring: it launches you into the sky.',
    'millstone': 'Push the rolling stone door; the Lamplighters cannot move it. Climb on it to make a step.',
    'semazen': 'You are hidden in the skirt of a whirling dervish as he passes in front. Tiptoe along with him ({sneak}); when he turns away, he no longer hides you.',
    'chandelier': 'Jump onto the chandelier\'s candle trays; it turns and carries you. When you are high, leap to the next.',
    'lamp': 'The great lantern\'s beam sweeps the rooftops. Wait in the shadow of a dome, chimney or porch; run when the beam has passed.',
    'flood': 'The flood of light is rising. Don\'t stop. Climb!',
  };
}
