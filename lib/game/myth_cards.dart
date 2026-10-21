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
  ];
}
