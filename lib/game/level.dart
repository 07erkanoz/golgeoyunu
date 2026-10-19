import 'dart:math' as math;

import 'package:flame/components.dart';

import 'levels.dart';

const double kTile = 32;

/// Bir bölüm haritasının çözümlenmiş hâli: hücre sorguları ve özel noktalar.
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
