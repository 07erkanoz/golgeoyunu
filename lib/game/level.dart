import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flame/components.dart';

import 'levels.dart';

const double kTile = 32;

/// Bir bölüm haritasının çözümlenmiş hâli: hücre sorguları ve özel noktalar.
///
/// Harita gösterimi (haritalar tools/generate_maps.py ile üretilir):
/// - Zemin: `#` kaya, `=` tahta, `|` tırmanılan zincir/sarmaşık, `^` diken,
///   `w` su, `~` ve `I` saklanılan gölge, `r` rüzgâr akımı, `D` damla.
/// - Oyuncu ve yol: `P` başlangıç, `E` çıkış, `K` kontrol noktası, `B` Hüdhüd
///   konakları, `1`-`9` fısıltılar, `M` hatıralar.
/// - Canlılar: `G` Kandilci, `g` Gözcü, `b` yarasalar, `k` karga, `z`/`Z`
///   Karabasan kovalamacasının başı/sonu, `e` karanlıkta beliren gözler.
/// - Düzenekler: `C` sandık, `L` kol, `H` kapı, `A`/`Y` terazi kefeleri,
///   `R`/`V` yatay/dikey kayan kaya, `O` çöken kaya, `F` ateşböcekleri,
///   `W` Hezarfen'in kanatları.
/// - Bölgeler: `x` sol üst ve `X` sağ alt köşeleriyle karanlık bölge (ışığı
///   yer, ateşböcekleri birer birer söner).
/// - Bulmacalar: `l` ışık tahtası, `n` gölge tahtası, `u` çürük tahta,
///   `q`/`Q` su haznesinin köşeleri, `f` yüzen tahta (başlangıç su seviyesi),
///   `v` boşaltan ve `y` dolduran vana, `j` güneş huzmesi (aşağı iner),
///   `m` ayna `/`, `h` ayna `\`, `t` ışık kilidi, `J` dev perde (sol alt).
class Level {
  Level(this.def) {
    _parse();
  }

  final LevelDef def;
  late final int width;
  late final int height;
  late final List<List<String>> _cells;

  Vector2 playerStart = Vector2.zero();
  Vector2 exitCell = Vector2.zero();
  final guardCells = <Vector2>[];
  final birdCells = <Vector2>[];
  final memoryCells = <Vector2>[];
  final checkpointCells = <Vector2>[];
  final crateCells = <Vector2>[];
  final fireflyCells = <Vector2>[];
  final movingCells = <(Vector2, bool)>[];
  final crumbleCells = <Vector2>[];
  final liftA = <Vector2>[];
  final liftB = <Vector2>[];
  final batCells = <Vector2>[];
  final crowCells = <Vector2>[];
  final watcherCells = <Vector2>[];
  final wingsCells = <Vector2>[];
  double? chaseStart;
  double? chaseEnd;
  final leverCells = <Vector2>[];
  final glimpseCells = <Vector2>[];

  /// Yatay tahta dizileri: (sütun, satır, uzunluk).
  final glowRuns = <(int, int, int)>[];
  final shadeRuns = <(int, int, int)>[];
  final rottenRuns = <(int, int, int)>[];
  final basins = <Rect>[];
  final _basinStarts = <Vector2>[];
  final floatCells = <Vector2>[];
  final drainValves = <Vector2>[];
  final fillValves = <Vector2>[];
  final beamCells = <Vector2>[];
  final mirrorCells = <(Vector2, bool)>[];
  final lockCells = <Vector2>[];
  final perdeCells = <Vector2>[];

  /// Karanlık bölgeler (dünya koordinatında dikdörtgenler).
  final darkZones = <Rect>[];
  final _darkStarts = <Vector2>[];

  /// Dikey `H` dizileri: her biri bir kapı (sütun, üst satır, alt satır).
  final gates = <(int, int, int)>[];
  final triggers = <(int, Vector2)>[];

  double get pixelWidth => width * kTile;
  double get pixelHeight => height * kTile;

  void _parse() {
    height = def.map.length;
    width = def.map.map((r) => r.length).reduce(math.max);
    _cells = [];
    for (var r = 0; r < height; r++) {
      final row = def.map[r].padRight(width, '.').split('');
      for (var c = 0; c < width; c++) {
        final ch = row[c];
        final cell = Vector2(c * kTile, r * kTile);
        switch (ch) {
          case 'P':
            playerStart = cell;
          case 'E':
            exitCell = cell;
          case 'G':
            guardCells.add(cell);
          case 'B':
            birdCells.add(cell);
          case 'M':
            memoryCells.add(cell);
          case 'K':
            checkpointCells.add(cell);
          case 'C':
            crateCells.add(cell);
          case 'F':
            fireflyCells.add(cell);
          case 'R':
            movingCells.add((cell, false));
          case 'V':
            movingCells.add((cell, true));
          case 'O':
            crumbleCells.add(cell);
          case 'A':
            liftA.add(cell);
          case 'Y':
            liftB.add(cell);
          case 'b':
            batCells.add(cell);
          case 'k':
            crowCells.add(cell);
          case 'g':
            watcherCells.add(cell);
          case 'W':
            wingsCells.add(cell);
          case 'z':
            chaseStart = cell.x;
          case 'Z':
            chaseEnd = cell.x;
          case 'L':
            leverCells.add(cell);
          case 'e':
            glimpseCells.add(cell);
          case 'l' || 'n' || 'u':
            // Bir dizinin ilk hücresinde tüm diziyi kaydet.
            final line = def.map[r].padRight(width, '.');
            if (c > 0 && line[c - 1] == ch) {
              if (ch == 'u') continue;
            } else {
              var len = 1;
              while (c + len < width && line[c + len] == ch) {
                len++;
              }
              (ch == 'l'
                      ? glowRuns
                      : ch == 'n'
                      ? shadeRuns
                      : rottenRuns)
                  .add((c, r, len));
              // Çürük tahta Kandilci'nin yürüyebileceği hücredir: kalır.
              if (ch == 'u') continue;
            }
          case 'q':
            _basinStarts.add(cell);
          case 'Q':
            if (_basinStarts.isNotEmpty) {
              final a = _basinStarts.removeAt(0);
              basins.add(
                Rect.fromLTRB(a.x, a.y, cell.x + kTile, cell.y + kTile),
              );
            }
          case 'f':
            floatCells.add(cell);
          case 'v':
            drainValves.add(cell);
          case 'y':
            fillValves.add(cell);
          case 'j':
            beamCells.add(cell);
          case 'm':
            mirrorCells.add((cell, true));
          case 'h':
            mirrorCells.add((cell, false));
          case 't':
            lockCells.add(cell);
          case 'J':
            perdeCells.add(cell);
          case 'x':
            _darkStarts.add(cell);
          case 'X':
            if (_darkStarts.isNotEmpty) {
              final a = _darkStarts.removeAt(0);
              darkZones.add(
                Rect.fromLTRB(a.x, a.y, cell.x + kTile, cell.y + kTile),
              );
            }
          case 'H':
            if (r == 0 || def.map[r - 1].padRight(width, '.')[c] != 'H') {
              var end = r;
              while (end + 1 < height &&
                  def.map[end + 1].padRight(width, '.')[c] == 'H') {
                end++;
              }
              gates.add((c, r, end));
            }
          default:
            final n = int.tryParse(ch);
            if (n == null) continue;
            triggers.add((n - 1, cell));
        }
        row[c] = '.';
      }
      _cells.add(row);
    }
  }

  /// Harita dışı: yanlar katı duvar, üst ve alt boşluk.
  String cell(int c, int r) {
    if (c < 0 || c >= width) return '#';
    if (r < 0 || r >= height) return '.';
    return _cells[r][c];
  }

  bool solid(int c, int r) => cell(c, r) == '#';

  /// Bir hücreyi boşaltır (çöken tahta).
  void clearCell(int c, int r) {
    if (c < 0 || c >= width || r < 0 || r >= height) return;
    _cells[r][c] = '.';
  }

  /// Nokta bir karanlık bölgenin içinde mi?
  bool inDarkZone(Vector2 p) =>
      darkZones.any((z) => z.contains(Offset(p.x, p.y)));

  /// Bölümde ne kadar ilerlendiği: yatay bölümlerde x, dikey (tırmanma)
  /// bölümlerinde yükseklik.
  bool get vertical => height > width;
  double progressOf(Vector2 p) => vertical ? pixelHeight - p.y : p.x;

  String cellAt(double x, double y) =>
      cell((x / kTile).floor(), (y / kTile).floor());

  bool rectHits(
    double left,
    double top,
    double right,
    double bottom,
    bool Function(String) test,
  ) {
    final c0 = (left / kTile).floor();
    final c1 = ((right - 0.01) / kTile).floor();
    final r0 = (top / kTile).floor();
    final r1 = ((bottom - 0.01) / kTile).floor();
    for (var r = r0; r <= r1; r++) {
      for (var c = c0; c <= c1; c++) {
        if (test(cell(c, r))) return true;
      }
    }
    return false;
  }

  bool rectSolid(double left, double top, double right, double bottom) =>
      rectHits(left, top, right, bottom, (ch) => ch == '#');

  bool lineOfSight(Vector2 a, Vector2 b) {
    final d = b - a;
    final steps = math.max(1, (d.length / 8).ceil());
    for (var i = 1; i < steps; i++) {
      final p = a + d * (i / steps);
      if (cellAt(p.x, p.y) == '#') return false;
    }
    return true;
  }

  /// Hücreye yerleşen bir karakterin sol-üst konumu (ayakları zeminde).
  static Vector2 standOn(Vector2 cell, double w, double h) =>
      Vector2(cell.x + (kTile - w) / 2, cell.y + kTile - h);
}
