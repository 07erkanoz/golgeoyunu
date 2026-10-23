// Seslendirilecek anlatım satırlarını rolleri ve kimlikleriyle yazar.
// `flutter test tools/preview/ses_satirlari_test.dart`
// → build/ses/satirlar_<dil>.json (tools/seslendir.py okur).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golge/game/hints.dart';
import 'package:golge/game/levels.dart';
import 'package:golge/game/strings.dart';
import 'package:golge/game/voice.dart';

void main() {
  test('satırlar', () {
    for (final lang in [Lang.tr, Lang.en]) {
      S.lang = lang;
      final out = <Map<String, Object>>[];
      void add(String text, VoiceRole role, String where) {
        if (text.trim().isEmpty) return;
        if (out.any((e) => e['text'] == text)) return;
        out.add({
          'id': voiceId(text),
          'text': text,
          'role': role.name,
          'where': where,
        });
      }

      for (final l in prologueText) {
        add(l, VoiceRole.perde, 'prologue');
      }
      for (var i = 0; i < levels.length; i++) {
        final d = levels[i];
        for (final l in interludeText(i)) {
          add(l, VoiceRole.perde, 'perde:$i');
        }
        if (d.bardText.isNotEmpty) add(d.bardText, VoiceRole.ozan, 'ozan:$i');
        for (final w in d.whisperTexts) {
          add(w, whisperRole(w), 'fisilti:$i');
        }
        for (final m in d.memoryTexts) {
          add(m, VoiceRole.hatira, 'hatira:$i');
        }
      }
      for (final l in epilogueText) {
        add(l, VoiceRole.perde, 'epilogue');
      }
      // Oyunun içinden gelen sözler (fısıltı olarak): ziyaretçiler, olaylar,
      // uyarılar ve düzeneklerin şiirleri. İpucu olanlar (simgede) yok.
      for (final (key, role) in _sozler) {
        add(S.of(key), role, 'soz:$key');
      }
      for (final key in ['giant', 'medusa', 'shield', 'umay']) {
        add(Hints.poem(key), VoiceRole.ozan, 'siir:$key');
      }
      Directory('build/ses').createSync(recursive: true);
      File('build/ses/satirlar_${lang.name}.json').writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert(out),
      );
    }
  });
}

/// Oyun içi sözler ve okuyacak ses: anlatıcı (rivayet) ya da karanlık
/// fısıltı (uyarı, kovalamaca).
const _sozler = [
  ('cameo_akAna', VoiceRole.rivayet),
  ('cameo_albasti', VoiceRole.fisilti),
  ('cameo_asena', VoiceRole.rivayet),
  ('cameo_ayazAta', VoiceRole.rivayet),
  ('cameo_basat', VoiceRole.ozan),
  ('cameo_demirci', VoiceRole.rivayet),
  ('cameo_erTostuk', VoiceRole.rivayet),
  ('cameo_erlik', VoiceRole.rivayet),
  ('cameo_gokKat', VoiceRole.rivayet),
  ('cameo_kam', VoiceRole.rivayet),
  ('cameo_suIyesi', VoiceRole.rivayet),
  ('cameo_tulpar', VoiceRole.rivayet),
  ('cameo_ulgen', VoiceRole.rivayet),
  ('chase', VoiceRole.fisilti),
  ('darkZone', VoiceRole.fisilti),
  ('shadowLooked', VoiceRole.fisilti),
  ('blizzard', VoiceRole.rivayet),
  ('calkuyrukMount', VoiceRole.rivayet),
  ('tulparMount', VoiceRole.rivayet),
  ('giantFell', VoiceRole.rivayet),
  ('guardStone', VoiceRole.rivayet),
  ('horoscope', VoiceRole.rivayet),
  ('medusaSealed', VoiceRole.rivayet),
  ('nevruzStruck', VoiceRole.rivayet),
  ('perdeSolved', VoiceRole.rivayet),
  ('scaleSolved', VoiceRole.rivayet),
  ('ventCrateBurn', VoiceRole.rivayet),
  ('wings', VoiceRole.rivayet),
  ('feathersAll', VoiceRole.rivayet),
  ('forgeCold', VoiceRole.rivayet),
  ('forgeFuel', VoiceRole.rivayet),
  ('forgeLit', VoiceRole.rivayet),
  ('forgeLitBeat', VoiceRole.rivayet),
];
