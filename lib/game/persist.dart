import 'package:flame/components.dart';

/// Kontrol noktasında saklanan, ölünce ve "Devam et"te geri kurulan bulmaca
/// parçası: çekilmiş kol, açılmış kapı, alınmış tüy, yerine konmuş sandık...
///
/// Sözleşme: dünya, oyuncunun kontrol noktasına son dokunduğu andaki gibi
/// kurulur. Tehlikeler (çürük tahta, ince buz, düşen kaya) ve kovalamacalar
/// baştan başlar; çözülmüş düzenekler çözülmüş kalır.
mixin Persistent on Component {
  /// Bölüm kurulurken verilir: tür ve o türdeki sırası ("gate#2").
  String persistId = '';

  /// Kimliğin tür kısmı (aynı türün parçaları kurulma sırasıyla sayılır).
  String get persistKind;

  /// Saklanacak durum (JSON'a çevrilebilir). null: başlangıç durumu.
  Object? captureState();

  /// Saklanan durumu uygular; dünyaya eklenecek bileşenleri döndürür
  /// (kendisi, yerine geçen ya da ek parçalar). [present] false ise parça
  /// kontrol noktasında artık yoktu (alınmış, düşmüş): varsayılan olarak
  /// eklenmez.
  Iterable<Component> restoreState(Object? state, {required bool present}) =>
      present ? [this] : const [];
}

/// Kurulacak parçalara kimlik verir ve varsa saklanan durumu uygular.
List<Component> restorePuzzle(
  List<Component> parts,
  Map<String, Object?>? snapshot,
) {
  final counts = <String, int>{};
  final out = <Component>[];
  for (final c in parts) {
    if (c is! Persistent) {
      out.add(c);
      continue;
    }
    final kind = c.persistKind;
    final n = counts[kind] ?? 0;
    counts[kind] = n + 1;
    c.persistId = '$kind#$n';
    if (snapshot == null) {
      out.add(c);
      continue;
    }
    try {
      out.addAll(
        c.restoreState(
          snapshot[c.persistId],
          present: snapshot.containsKey(c.persistId),
        ),
      );
    } catch (_) {
      // Bozuk ya da eski biçimli durum: parça başlangıç hâliyle kurulur.
      out.add(c);
    }
  }
  return out;
}

/// Dünyadaki parçaların şimdiki durumu.
Map<String, Object?> capturePuzzle(Iterable<Component> world) => {
  for (final c in world.whereType<Persistent>())
    if (c.persistId.isNotEmpty) c.persistId: c.captureState(),
};

/// JSON'dan gelen sayı listesini okur.
List<double>? numbers(Object? state, int count) {
  if (state is! List || state.length != count) return null;
  final out = <double>[];
  for (final v in state) {
    if (v is! num || !v.isFinite) return null;
    out.add(v.toDouble());
  }
  return out;
}

/// Bölüm haritasının imzası (FNV-1a): kayıttaki bulmaca durumu ancak aynı
/// haritaya uygulanır. Parçalar türünde sırayla eşlendiğinden ("crate#1"),
/// araya yeni bir sandık ya da kol girince eski durum yanlış parçaya düşer.
String layoutKey(List<String> rows) {
  var h = 0x811c9dc5;
  for (final u in rows.join('\n').codeUnits) {
    h ^= u;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}
