import 'dart:convert';

/// Anlatım seslerinin kimliği: satırın metninden (UTF-8, FNV-1a 32 bit)
/// türetilir; ses dosyası `assets/voice/<dil>/<kimlik>.mp3`. Metin
/// değişince kimlik de değişir: eski ses yanlış satıra çalınmaz, o satır
/// yeniden seslendirilene dek sessiz kalır.
String voiceId(String text) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode(text)) {
    h ^= b;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

/// Seslendirilen satırın rolü: kimin sesiyle, nasıl okunacağı.
enum VoiceRole {
  /// Perde: hayali (perdeyi oynatan usta), Charon.
  perde,

  /// Ozanın dizesi: aynı yaşlı ses, Charon.
  ozan,

  /// Efsane ve rivayet anlatısı (fısıltılardan): Charon.
  rivayet,

  /// Sâye'ye seslenen karanlık fısıltı: Enceladus.
  fisilti,

  /// Hatıra: Sâye anlatır (Leda), tırnak içini usta söyler (Charon).
  hatira,
}

/// Fısıltının rolü: geçmiş zaman anlatısı ("-mış, derler, rivayet") ya da
/// uzun bir efsane anlatısıysa anlatıcı; kısa, Sâye'ye seslenen ya da uyaran
/// satırlar karanlık fısıltı.
VoiceRole whisperRole(String text) {
  final t = text.toLowerCase();
  const tells = [
    'rivayet',
    'derler',
    'derlermiş',
    'anlatılır',
    'imiş',
    'mış ',
    'miş ',
    'muş ',
    'müş ',
    'mış.',
    'miş.',
    'muş.',
    'müş.',
    'mış,',
    'miş,',
    'muş,',
    'müş,',
    'legend',
    'they say',
    'it is said',
    'once ',
  ];
  if (text.length > 150 || tells.any(t.contains)) return VoiceRole.rivayet;
  return VoiceRole.fisilti;
}
