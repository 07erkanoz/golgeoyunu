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
    'starWheel': 'Yıldız kazığının çevresinde döner · üstüne zıpla, seni taşır · istediğin yerde {jump} ile atla',
    'karakci':
        'Yedi Karakçı · kara yıldızlara değme · dönüşlerini izle, aradan geç',
    'yel': 'Yel Ana üfleyecek · çizgiler sıklaşınca {down} çömel · arkadan eserken süzül: {glide}',
    'yada': '{up} Yada taşına dokun · Yel Ana\'nın soluğu yön değiştirir',
    'lightning':
        'Yer kızarırsa çekil · yıldırımın ışığında bulut basamaklarını ezberle',
    'glade': 'Işık lekelerinde yürü · gölgede Karabasan bekler · ışık yoksa {firefly} ateşböceği sal',
    'rootDrum': 'Kam\'ın davulu · her vuruşta bir sıra kök kalkar, öbürü suya iner · ayağının altındaki titreyince atla',
    'deer': 'Ak Geyik ışığa gelir · {firefly} ateşböceğini önüne sal, peşinden yürür · karanlığa girmez',
    'deerPlate': 'Geyik kökü · Ak Geyik basınca uyanır, kapı açılır · senin ağırlığın yetmez',
    'karabasan': 'Karabasan arkanda · durma, koş · {firefly} ateşböceği onu bir an geri iter',
    'fireflyPickup': 'Ateşböceklerine dokun · kavanoza girerler',
    'hide': '{down} Çömel ya da gölgede dur · saklanırsın',
    'guard': '{firefly} Ateşböceği sal · Kandilci ışığa gider',
    'climb': '{up} Tırman · bırakmak için yön + {jump}',
    'lightPlank': 'Işık tahtası · kavanozun açıkken var olur',
    'shadePlank': '{down} Çömel · gölge tahtası ışıkta erir',
    'crate': 'Sandığı it · üstüne çıkıp yüksel',
    'lever': '{up} Kolu çek',
    'umay': 'Umay ağacı · dokun: düştüğünde buradan yeniden başlarsın',
    'treeTale':
        'Umay ağacının yanında dur: ağaç sana bu yerin rivayetini anlatır',
    'drum': 'Kam\'ın davulu · her vuruşta bir bulut takımı belirir, öbürü söner · vuruşu bekle, sonra atla',
    'scorch':
        'Gün katının ışığı yakar · Hüma\'nın gölgesinde, onunla birlikte yürü',
    'tulpar': 'Tulpar · sırtına bin · havada zıplayınca kanat çırpar: {jump}',
    'forge': 'Ocak sönmüş · yanına ateşböceği sal, yeniden yansın: {firefly}',
    'bellows': '{up} Oklu körüğe bas · çentik sayısı sırası · yanlış körük ateşi söndürür',
    'bellowsBeat': '{up} Oklu körüğe, çekiç örse inince bas · altı vuruş · sonra öbür körük yanar',
    'fuel': 'Ocak boş · kömür sandıklarını ocağın önündeki çukura it · birini basamak için sakla',
    'goalFuel':
        'Kömür sandıklarını ocağın önündeki ışıklı çukura it ({n}/{need})',
    'goalLight': 'Ocağın ağzına bir ateşböceği at: {firefly}',
    'goalBeat': 'Oklu körüğe, halkası kapanınca bas: {up} · vuruş {n}/{need}',
    'goalOrder': 'Oklu körüğe bas: {up} · sıradaki {next}',
    'goalForge': 'Ocak',
    'nevruz': '{up} Demire üç kez vur',
    'molten': 'Akan demir yakar · soğuyup kararınca üstünden geç',
    'kormos': 'Körmösler ışığa gelir · {down} kavanozunu ört · ya da ateşböceği sal: {firefly}',
    'kut': '{up} Kafesi aç · kut kavanoza girer, kapı açılır · kavanoz parladıkça Körmösler uzaktan görür',
    'lightCage': '{up} Kafesi aç · ışık kavanozuna girer, bir kapı açılır',
    'dawn': 'Güneşte dur · Kandilciler gölgeden çıkmaz, güneşte seni görmez · güneş yükseldikçe gölge kısalır',
    'mirrorLake': 'Yol havada görünmez · suya bak: basamaklar yansımada · rüzgâr esince bekle',
    'leak': 'Fışkıran su geri savurur · sandığın ardına sığın, deliğin üstüne it: {right}',
    'barrel': 'Gemi yalpalıyor, fıçılar yuvarlanır · yığının üstünde bekle, geçince koş ya da üstünden atla',
    'birdBridge': 'Kuşların sırtına bas · Gözcü\'nün feneri değen kuş ürker · ateşböceğiyle feneri oyala: {firefly}',
    'finale': '{up} Aynaları çevir · ay ışığı Kandilci Başı\'na düşsün · fenerin geçerken sütunun gölgesinde bekle',
    'horse': 'Çalkuyruk · yanına git, sırtına bin · atla çok yükseğe sıçrarsın',
    'gokboruTrail':
        '{down} Kavanozunu ört · Gökbörü\'nün izleri karanlıkta parlar',
    'valve': '{up} Vanayı çevir',
    'scale': 'Terazi · eşleri iki kefeye koy · ağırlıklar denk gelmeli · {up} kol teraziyi boşaltır',
    'cord': '{up} İpi çek · kandil perdenin ardında kayar',
    'golgehane': '{up} Tasvire dokun · perdede canlanır · kandili iterek gölgeni büyüt, küçült',
    'shadowStone': '{up} Gölgeni önden gönder · Kandilciler ona bakarken geç',
    'coldBridge': '{firefly} Kandilci yolu yalnız onların feneriyle belirir · ateşböceği at, Kandilci ona dalınca ışığında geç',
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
    'animal': 'Heykeli perdedeki eşinin gölgesine it',
    'bouncer': 'Zıpzıp · üstüne zıpla: seni yükseğe atar, ışıkları topla',
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
    'starWheel': 'The star turns around its stake · jump on, it carries you · leap off when you like: {jump}',
    'karakci': 'The Seven Thieves · do not touch the black stars · watch them turn and slip between',
    'yel': 'The Wind Mother will blow · when the lines thicken, crouch: {down} · with the wind at your back, glide: {glide}',
    'yada':
        'Touch the yada stone: {up} · the Wind Mother\'s breath turns around',
    'lightning': 'If the ground glows red, step away · in the lightning\'s flash, memorise the cloud steps',
    'glade': 'Walk in the patches of light · the Karabasan waits in the shadow · no light? Release a firefly: {firefly}',
    'rootDrum': 'The shaman\'s drum · each beat raises one row of roots and sinks the other · jump when the one beneath you trembles',
    'deer': 'The White Deer comes to the light · release a firefly ahead of it: {firefly} · it will not enter darkness',
    'deerPlate': 'A deer root · it wakes under the White Deer\'s hoof and the gate opens · your weight is not enough',
    'karabasan': 'The Karabasan is behind you · don\'t stop, run · a firefly pushes it back for a moment: {firefly}',
    'fireflyPickup': 'Touch the fireflies · they fly into your jar',
    'hide': '{down} Crouch or stand in shadow · you are hidden',
    'guard': '{firefly} Release a firefly · the Lamplighter follows it',
    'climb': '{up} Climb · to let go, direction + {jump}',
    'lightPlank': 'Plank of light · exists while your jar is open',
    'shadePlank': '{down} Crouch · the shadow plank melts in light',
    'crate': 'Push the crate · climb it to reach higher',
    'lever': '{up} Pull the lever',
    'umay': 'Umay tree · touch it: if you fall, you rise here again',
    'treeTale':
        'Stand by the Umay tree: it will tell you the legend of this place',
    'drum': 'Kam\'s drum · on each beat one set of clouds appears and the other fades · wait for the beat, then jump',
    'scorch': 'The light of the sun layer burns · walk in the Huma\'s shadow, along with it',
    'tulpar': 'Tulpar · climb on his back · jump in the air to beat his wings: {jump}',
    'forge': 'The forge is cold · release a firefly beside it to light it again: {firefly}',
    'bellows': '{up} Pump the bellows with the arrow · in notch order · the wrong one puts the fire out',
    'bellowsBeat': '{up} Pump the bellows with the arrow as the hammer strikes · six beats · then another lights up',
    'fuel': 'The forge is empty · push the charcoal crates into the pit before it · keep one as a step',
    'goalFuel': 'Push the charcoal crates into the glowing pit before the forge ({n}/{need})',
    'goalLight': 'Throw a firefly into the forge mouth: {firefly}',
    'goalBeat': 'Pump the bellows with the arrow when its ring closes: {up} · beat {n}/{need}',
    'goalOrder': 'Pump the bellows with the arrow: {up} · next {next}',
    'goalForge': 'Forge',
    'nevruz': '{up} Strike the iron three times',
    'molten': 'Flowing iron burns · cross only when it cools and darkens',
    'kormos': 'Körmös drift toward light · {down} cover your jar · or release a firefly: {firefly}',
    'kut': '{up} Open the cage · the kut enters your jar and a gate opens · the brighter the jar, the farther the Körmös see',
    'lightCage': '{up} Open the cage · the light enters your jar and a gate opens',
    'dawn': 'Stay in the sun · Lamplighters never leave the shadow and cannot see you in sunlight · the shadows shorten as the sun climbs',
    'mirrorLake': 'The road cannot be seen in the air · look at the water: the steps are in the reflection · wait when the wind blows',
    'leak': 'The spraying water throws you back · hide behind a crate and push it over the hole: {right}',
    'barrel': 'The ark is rolling; barrels roll loose · wait on top of a stack and run when one has passed, or jump over it',
    'birdBridge': 'Step on the birds\' backs · a bird touched by the Watcher\'s lantern takes fright · distract the lantern with a firefly: {firefly}',
    'finale': '{up} Turn the mirrors · let the moonlight fall on the Chief Lamplighter · wait in a pillar\'s shadow as his lantern passes',
    'horse':
        'Çalkuyruk · go to him and climb on · on horseback you leap far higher',
    'gokboruTrail':
        '{down} Cover your jar · Gökbörü\'s tracks glow in the dark',
    'valve': '{up} Turn the valve',
    'scale':
        'The scales · put the pair on the two pans · the weights must match',
    'cord': '{up} Pull the cord · the lamp slides behind the screen',
    'golgehane': '{up} Touch a figure · it comes alive on the screen · push the lamp to grow or shrink your shadow',
    'shadowStone': '{up} Send your shadow ahead · slip past while the Lamplighters watch it',
    'coldBridge': '{firefly} The Lamplighters\' path shows only in their lanterns · throw a firefly, cross in the light while one stares at it',
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
    'animal': 'Push the statue to its mate\'s shadow on the screen',
    'bouncer': 'Bouncer · jump on it: it throws you high, gather the lights',
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
    'starWheel': 'Yıldız çark gibi döner: altta alçalır, tepede yükselir; en yüksek yerde bırakan en yükseğe varır.',
    'karakci': 'Yedi Karakçı yavaş ama durmadan döner; geçtiği yer bir süre boş kalır.',
    'yel': 'Yel Ana önce çizgiyle uyarır, sonra eser; çömelen yerinden kımıldamaz, süzülen en çok sürüklenir.',
    'lightning': 'Yıldırım hep aynı yerlere düşer; her düşüşte göğü aydınlatıp gizli basamakları gösterir.',
    'glade': 'Karabasan ışığa giremez; huzme kayınca ya da sönünce gölge de yer değiştirir.',
    'rootDrum': 'Kökler davulun vuruşuna bağlı: biri kalkarken komşusu iner; inmeden önce titrer.',
    'deer': 'Ak Geyik en yakın ateşböceğine yürür ama karanlığa adım atmaz.',
    'karabasan':
        'Karabasan hızlanır ama ateşböceğinin ışığında bir an geri çekilir.',
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
    'bellowsBeat': 'Körük ancak çekiç örse indiği anda ocağı ısıtır; altı denk vuruşta demir erir.',
  };

  static const _relationEn = {
    'starWheel': 'The star turns like a wheel: low at the bottom, high at the top; leap off at the top to reach the highest ledge.',
    'karakci': 'The Seven Thieves turn slowly but never stop; where they have passed stays empty for a while.',
    'yel': 'The Wind Mother warns with lines, then blows; whoever crouches stays put, whoever glides is carried furthest.',
    'lightning': 'Lightning always strikes the same places; each strike lights the sky and shows the hidden steps.',
    'glade': 'The Karabasan cannot enter the light; when a beam shifts or fades, the shadow moves with it.',
    'rootDrum': 'The roots follow the drum: as one rises its neighbour sinks; it trembles before it sinks.',
    'deer': 'The White Deer walks to the nearest firefly, but it will not step into darkness.',
    'karabasan': 'The Karabasan gathers speed, but a firefly\'s light drives it back for a moment.',
    'guard': 'A Lamplighter turns first toward sound and light; that is when the way behind him opens.',
    'watcher': 'The Watcher\'s light sweeps back and forth; it cannot see near and far at once.',
    'bell': 'The bell draws nearby Lamplighters; they look where the sound came from.',
    'medusa': 'Medusa\'s gaze turns to stone only what moves.',
    'giant': 'Lifting a stone, the giant covers its ear; after the throw it recovers for a moment.',
    'kormos': 'A Körmös sees only open light; when it loses the light it drifts to where it last saw it.',
    'wolf': 'A wolf crouches before it lunges; once it lunges, it cannot turn.',
    'lamp': 'The great lamp\'s beam sweeps the roofs in turn; whatever lies in shadow is safe.',
    'bellowsBeat': 'A bellows heats the forge only when pumped as the hammer strikes; six true beats melt the iron.',
  };

  static const _solutionTr = {
    'starWheel': 'Yıldız sana en yakın geçtiğinde üstüne zıpla. Tepeye çıkınca hedefe doğru bak ve atla; gerekirse süzül.',
    'karakci': 'Kara yıldızlar uzaklaşıp kepçe dönünce atlara geç; atın üstünde kazığın öbür yanına dön, Karakçılar yine uzaktayken atla.',
    'yel': 'Önden eserken çizgiler sıklaşır sıklaşmaz çömel, soluk dinince koş. Geniş boşlukta soluk arkadan eserken atla ve süzül.',
    'lightning': 'Kızaran yerden çekil, yıldırımı bekle. Çaktığı an basamakları gör, ışık sönmeden ilk iki basamağa geç; sonrakini bir sonraki yıldırımla gör.',
    'glade': 'Bir huzmenin içinde dur ve izle. Rüzgârlı yerde yapraklar hışırdayınca huzme kayar: onunla birlikte yürü. Sönen huzmeler sırayla söner; titreyeni bırak, yanan komşusuna geç. Gölgede kalırsan ateşböceği sal: ışığı seni korur.',
    'rootDrum': 'Davulu dinle. Ayağının altındaki kök titreyince bir sonrakine atla; kalkacak kökün uçlarını suyun yüzünde önceden görürsün.',
    'deer': 'Geyiği yukarıdan yönetiyorsan ateşböceğini kökün hizasına sal. Karanlık yolda ateşböceklerini sırayla sal: biri sönmeden öbürünü ileri at; geyik ışıktan ışığa yürür.',
    'karabasan': 'Duraksama. Kökün kalkmasını beklerken ateşböceği sal; Karabasan geri çekilir. İplerde en uçta bırak, ileri fırla.',
    'guard': 'Ateşböceğini Kandilci\'nin ardına sal ya da yakındaki çanı çal. Başını çevirince sütunun ardından geç. Görüldüysen aynı sütunda bekleme; bir sonrakine geç.',
    'watcher': 'Işığın uçtan uca gidişini bir kez izle. Işık senden uzağa döndüğü anda koş, sıradaki siperde dur. Ateşböceği salarsan Gözcü ışığını ona çevirir.',
    'bell': 'Çana ateşböceği sal ya da altından koşarak geç. Kandilci sese yürürken sütunun ardında çömel; o geçince öbür yana ilerle.',
    'medusa': 'Gözleri kapanınca bir sonraki sütuna yürü; aralanınca dur, kıpırdama. Kalkan varsa önüne it, ardında yürü.',
    'giant': 'Dev yürürken kulağını korur. İşaret belirince yerinden çekil; taş düşer düşmez, dev toparlanırken ya da yolun sonunda soluklanırken kulağı parlar: o an rafa çık, ateşböceği sal. Üç kez. Ateşböceğin bitince devden uzaklaş: yenileri başka yerde çıkar.',
    'kormos': 'Kavanozunu ört ve hemen yer değiştir: Körmös eski yerinde ararken karanlıktan geç. Ateşböceği salarsan onu uzağa çeker.',
    'wolf': 'Kurt çömelince yana ya da yukarı çekil. İnce buzun kenarında beklersen atılışı onu buza düşürür. Ateşböceği kurdu bir süre korkutur.',
    'lamp': 'Revakın ya da bacanın gölgesinde dur. Huzme üstünden geçip uzaklaşınca bir sonraki gölgeye koş; huzmede bir an bile kalma.',
    'bellowsBeat': 'Örsü dinle: üstünde ok olan körüğün halkası daralır, çekiç inince kapanıp parlar; o anda bas. Her denk vuruştan sonra ok öbür körüğe geçer; oraya koş, sıradaki vuruşu bekle. Altı vuruş yeter.',
  };

  static const _solutionEn = {
    'starWheel': 'Jump on when the star passes closest to you. At the top, face your goal and leap; glide if you must.',
    'karakci': 'When the black stars are far and the dipper has turned away, step onto a horse; ride to the far side of the stake and leap while the Thieves are still away.',
    'yel': 'Against the wind, crouch as soon as the lines thicken and run when the breath dies. Over a wide gap, jump and glide while it blows at your back.',
    'lightning': 'Step off the glowing spot and wait for the bolt. The moment it strikes, see the steps and cross the first two before the light fades; see the next with the next bolt.',
    'glade': 'Stand inside a beam and watch. Where the wind blows, the leaves rustle before the beam shifts: walk along with it. Fading beams go out in turn; leave the trembling one for its lit neighbour. Caught in shadow? Release a firefly: its light protects you.',
    'rootDrum': 'Listen to the drum. When the root beneath you trembles, jump to the next; you can see the tips of the rising roots on the water beforehand.',
    'deer': 'Guiding the deer from above? Release the firefly right over the root. On the dark path release fireflies one after another: throw the next before the last fades, and the deer walks from light to light.',
    'karabasan': 'Do not hesitate. While waiting for a root to rise, release a firefly; the Karabasan draws back. On the vines let go at the far end and fly forward.',
    'guard': 'Release a firefly behind the Lamplighter or ring a nearby bell. When he turns his head, slip past behind the column. If you were seen, do not wait at the same column; move to the next.',
    'watcher': 'Watch the light sweep end to end once. Run the moment it turns away from you and stop at the next cover. A firefly makes the Watcher turn its light to it.',
    'bell': 'Release a firefly at the bell or run beneath it. While the Lamplighter walks to the sound, crouch behind a column; once he has passed, go the other way.',
    'medusa': 'Walk to the next column when her eyes close; stop and stay still as they open. If there is a shield, push it ahead and walk behind it.',
    'giant': 'Walking, the giant guards its ear. Step away when the mark appears; as the stone lands, while it recovers or rests at the end of its path, its ear glows: climb to the shelf and release a firefly. Three times. Out of fireflies? Get away from the giant: new ones appear elsewhere.',
    'kormos': 'Cover your jar and move at once: while the Körmös searches the old spot, pass through the dark. A firefly draws it away.',
    'wolf': 'When the wolf crouches, step aside or climb. Wait at the edge of thin ice and its lunge will drop it in. A firefly scares the wolf for a while.',
    'lamp': 'Stand in the shadow of a porch or chimney. When the beam has passed over and away, run to the next shadow; never stay in the beam even for a moment.',
    'bellowsBeat': 'Listen to the anvil: the ring over the bellows with the arrow narrows and flashes as the hammer falls; pump then. After each true beat the arrow moves to another bellows; run there and wait for the next strike. Six beats are enough.',
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
