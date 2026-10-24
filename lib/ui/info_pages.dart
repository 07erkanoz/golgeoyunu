import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../game/anlatim_plani.dart';
import '../game/levels.dart';
import '../game/myth_cards.dart';
import '../game/strings.dart';
import '../settings.dart';

const _text = Color(0xFFEBDDCB);
const _accent = Color(0xFFE0A15F);
const _ink = Color(0xFF1A0B05);

/// Başlık ve altında ince bir süs çizgisi.
class _Heading extends StatelessWidget {
  const _Heading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _text,
            fontSize: 20,
            letterSpacing: 6,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 48, height: 1, color: _accent.withAlpha(90)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.local_fire_department,
                size: 12,
                color: _accent,
              ),
            ),
            Container(width: 48, height: 1, color: _accent.withAlpha(90)),
          ],
        ),
      ],
    );
  }
}

TextStyle get _body =>
    TextStyle(color: _text.withValues(alpha: 0.82), fontSize: 13, height: 1.55);

// ========================================================== Hatıra defteri

/// Bölümün rivayetleri: Umay ağacında anlatılan ve Defter'e kalan sözler.
List<String> _tales(int level) {
  final texts = levels[level].whisperTexts;
  return [
    for (var i = 0; i < texts.length; i++)
      if (whisperPlace(level, i).$1 == WhisperPlace.agac ||
          whisperPlace(level, i).$1 == WhisperPlace.defter)
        texts[i],
  ];
}

/// Bulunan hatıraların defteri: açılmış her bölümün hatıraları sırayla;
/// bulunmayanların yerinde boş bir satır.
class MemoryBookPage extends StatelessWidget {
  const MemoryBookPage({
    super.key,
    required this.memories,
    this.myths = const {},
    this.showMemories = true,
    this.showLegends = true,
    this.heading = true,
  });

  /// Defter sekmeli açılınca yalnız bir bölümü gösterir; başlık çerçevede.
  final bool showMemories;
  final bool showLegends;
  final bool heading;

  /// "bölüm:sıra" anahtarları.
  final Set<String> memories;

  /// Karşılaşılan mitolojik varlıklar (Efsaneler).
  final Set<String> myths;

  @override
  Widget build(BuildContext context) {
    final open = levelOrder.take(Settings.unlocked + 1);
    // Gizli dokunuşla her şey açıldıysa bütün hatıralar ve efsaneler.
    final memories = Settings.allOpen
        ? {
            for (var l = 0; l < levels.length; l++)
              for (var i = 0; i < levels[l].memoryTexts.length; i++) '$l:$i',
          }
        : this.memories;
    // Efsaneler hep açık: oyuncu kahramanları ve varlıkları istediği an
    // okur. Hatıralar bulundukça açılır (her şey açıksa hepsi).
    final myths = {for (final c in MythCard.all) c.id};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMemories) ...[
          if (heading) ...[
            _Heading(S.of('bookTitle')),
            const SizedBox(height: 14),
          ],
          Text(S.of('bookIntro'), style: _body),
          const SizedBox(height: 10),
          // Özet: bütün yolda bulunanlar.
          Text(
            S
                .of('bookTally')
                .replaceAll(
                  '{m}',
                  '${[for (var l = 0; l < levels.length; l++)
                    for (var i = 0; i < levels[l].memoryTexts.length; i++)
                      if (memories.contains('$l:$i')) 1].length}',
                )
                .replaceAll(
                  '{mt}',
                  '${levels.fold(0, (n, l) => n + l.memoryTexts.length)}',
                )
                .replaceAll(
                  '{e}',
                  '${MythCard.all.where((c) => myths.contains(c.id)).length}',
                )
                .replaceAll('{et}', '${MythCard.all.length}'),
            style: const TextStyle(
              color: _accent,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          // Bulunan sırlar: yalnız sayı (yerleri ve toplamı söylenmez);
          // ilk sır bulununca görünür.
          if (Settings.secrets.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              S
                  .of('secretsTally')
                  .replaceAll('{n}', '${Settings.secrets.length}'),
              style: const TextStyle(
                color: _accent,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
          for (final l in open)
            if (levels[l].memoryTexts.isNotEmpty || _tales(l).isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      S.upper(levels[l].titleText),
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Text(
                    '${[for (var i = 0; i < levels[l].memoryTexts.length; i++)
                      if (memories.contains('$l:$i')) i].length}'
                    ' / ${levels[l].memoryTexts.length}',
                    style: TextStyle(
                      color: _text.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              for (var i = 0; i < levels[l].memoryTexts.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: memories.contains('$l:$i')
                      ? Text(
                          // "Hatıra ·" öneki defterde gereksiz.
                          levels[l].memoryTexts[i].replaceFirst(
                            RegExp(r'^\S+ · '),
                            '',
                          ),
                          style: _body.copyWith(fontStyle: FontStyle.italic),
                        )
                      : Text(
                          '· · ·',
                          style: TextStyle(
                            color: _text.withValues(alpha: 0.25),
                            letterSpacing: 4,
                          ),
                        ),
                ),
              // Rivayetler: Umay ağaçlarında anlatılan ve Defter'e kalan
              // sözler (açılmış bölümde hep okunur).
              if (_tales(l).isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  S.upper(S.of('talesTitle')),
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.75),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                for (final t in _tales(l))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(t, style: _body),
                  ),
              ],
            ],
        ],
        if (showLegends) ...[
          if (showMemories) const SizedBox(height: 30),
          if (heading) ...[
            _Heading(S.of('legendsTitle')),
            const SizedBox(height: 14),
          ],
          Text(S.of('legendsIntro'), style: _body),
          for (final card in MythCard.all)
            if (myths.contains(card.id)) ...[
              const SizedBox(height: 16),
              Text(
                S.upper(card.name),
                style: const TextStyle(
                  color: _accent,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                card.who,
                style: _body.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 6),
              Text(card.story, style: _body),
              const SizedBox(height: 4),
              Text(
                card.source,
                style: TextStyle(
                  color: _text.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
            ],
          if (MythCard.all.any((c) => !myths.contains(c.id))) ...[
            const SizedBox(height: 18),
            Text(
              S
                  .of('legendsWaiting')
                  .replaceAll(
                    '{n}',
                    '${MythCard.all.where((c) => !myths.contains(c.id)).length}',
                  ),
              style: TextStyle(
                color: _text.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ================================================================= Hikâye

/// Oyunun hikâyesi: oyuncunun ulaştığı perdeye kadar açılır, sonu söylemez.
class StoryPage extends StatelessWidget {
  const StoryPage({super.key, this.heading = true});

  /// Başlık çerçevedeyse sayfada yinelenmez.
  final bool heading;

  /// Perdeler oynanış sırasıyla: (metin numarası, perdenin ilk bölümünün
  /// kimliği). Yer, `levelOrder`'daki sıradan bulunur (bölüm kimliği değil).
  static const _acts = [(0, 0), (1, 4), (2, 8), (3, 11), (5, 17), (4, 13)];

  @override
  Widget build(BuildContext context) {
    // Oynanan en ileri yer: kayıttaki bölümün sırası ya da açılan en ileri.
    final reached = math.max(
      orderOf(SaveGame.current?.level ?? 0),
      Settings.unlocked,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading) ...[
          _Heading(S.of('storyTitle')),
          const SizedBox(height: 18),
        ],
        Text(S.of('storyIntro'), style: _body),
        for (final (i, start) in _acts) ...[
          const SizedBox(height: 18),
          Text(
            S.upper(S.of('storyAct$i')),
            style: TextStyle(
              color: reached >= orderOf(start)
                  ? _accent
                  : _accent.withValues(alpha: 0.35),
              fontSize: 11,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reached >= orderOf(start)
                ? S.of('storyAct${i}Text')
                : S.of('storyLocked'),
            style: reached >= orderOf(start)
                ? _body
                : _body.copyWith(
                    color: _text.withValues(alpha: 0.35),
                    fontStyle: FontStyle.italic,
                  ),
          ),
        ],
      ],
    );
  }
}

// =============================================================== Hakkında

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _open(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Tarayıcı açılamazsa sessizce geçilir.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(S.of('aboutTitle')),
        const SizedBox(height: 18),
        Text(
          S.of('aboutGame'),
          textAlign: TextAlign.center,
          style: _body.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 20),
        // Geliştirici kartı: arkadan kandille aydınlanan küçük bir perde.
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x55E0A15F)),
            gradient: const RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [Color(0xFF4A2512), Color(0xFF24120A), Color(0xFF140C09)],
              stops: [0, 0.55, 1],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ink,
                  border: Border.all(color: _accent, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66E0A15F), blurRadius: 18),
                  ],
                ),
                child: const Text(
                  'EÖ',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 22,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Erkan Öz',
                style: TextStyle(color: _text, fontSize: 17, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                S.of('aboutRole'),
                style: TextStyle(
                  color: _accent.withValues(alpha: 0.85),
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                S.of('aboutDev'),
                textAlign: TextAlign.center,
                style: _body.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _LinkTile(
          icon: Icons.person_outline,
          title: 'erkanoz.com',
          subtitle: S.of('aboutSite'),
          onTap: () => _open(Uri.https('erkanoz.com', '/')),
        ),
        _LinkTile(
          icon: Icons.nightlight_outlined,
          title: 'lifeos.com.tr/gölgeler',
          subtitle: S.of('aboutGamePage'),
          onTap: () => _open(Uri.https('lifeos.com.tr', '/gölgeler/')),
        ),
        const SizedBox(height: 18),
        Text(
          S.upper(S.of('aboutMusic')),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _accent.withValues(alpha: 0.7),
            fontSize: 10,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          S.of('musicLicense'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _text.withValues(alpha: 0.45),
            fontSize: 10.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          S.upper(S.of('aboutArt')),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _accent.withValues(alpha: 0.7),
            fontSize: 10,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          S.of('artLicense'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _text.withValues(alpha: 0.45),
            fontSize: 10.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: _accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: _text, fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _text.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: _text.withValues(alpha: 0.35),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
