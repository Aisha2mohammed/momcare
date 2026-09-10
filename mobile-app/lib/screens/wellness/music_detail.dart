import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:provider/provider.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';

/// Full-detail screen for a single music track.
/// Receives the raw multi-lingual track map from the backend.
class MusicDetailPage extends StatelessWidget {
  final Map<String, dynamic> track;

  const MusicDetailPage({super.key, required this.track});

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _pick(String key) {
    final v = track[key];
    return (v is String && v.trim().isNotEmpty) ? v.trim() : '';
  }

  /// Resolve title based on current language code
  String _title(String lang) {
    if (_pick('title').isNotEmpty) return _pick('title');
    return _pick('title_$lang') != '' ? _pick('title_$lang') : (_pick('titleEn') != '' ? _pick('titleEn') : _pick('title_en'));
  }

  String _description(String lang) {
    if (_pick('description').isNotEmpty) return _pick('description');
    return _pick('description_$lang') != '' ? _pick('description_$lang') : (_pick('descriptionEn') != '' ? _pick('descriptionEn') : _pick('description_en'));
  }

  String _benefits(String lang) {
    if (_pick('benefits').isNotEmpty) return _pick('benefits');
    return _pick('benefits_$lang') != '' ? _pick('benefits_$lang') : (_pick('benefitsEn') != '' ? _pick('benefitsEn') : _pick('benefits_en'));
  }

  String _audioUrl(String lang) {
    if (_pick('audio_url').isNotEmpty) return _pick('audio_url');
    final direct = _pick('audio_${lang}_url');
    if (direct.isNotEmpty) return direct;
    final camel = _pick('audio${lang[0].toUpperCase()}${lang.substring(1)}Url');
    if (camel.isNotEmpty) return camel;
    // Fallback chain
    for (final l in ['En', 'en', 'Am', 'am', 'Om', 'om', 'So', 'so']) {
      final v = _pick('audio_${l.toLowerCase()}_url');
      if (v.isNotEmpty) return v;
      final v2 = _pick('audio${l[0].toUpperCase()}${l.substring(1).toLowerCase()}Url');
      if (v2.isNotEmpty) return v2;
    }
    return '';
  }

  String _formatDuration(dynamic d) {
    if (d == null) return '';
    final s = (d is num) ? d.toInt() : int.tryParse(d.toString()) ?? 0;
    if (s <= 0) return '';
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String _langLabel(String code) {
    switch (code) {
      case 'am': return 'አማርኛ';
      case 'om': return 'Afaan Oromo';
      case 'so': return 'Af-Soomaali';
      case 'en': default: return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final lang = ['en', 'am', 'om', 'so'].contains(localeCode) ? localeCode : 'en';

    final titleText = _title(lang);
    final descText = _description(lang);
    final benefitsText = _benefits(lang);
    final audioUrl = _audioUrl(lang);
    final imageUrl = _pick('imageUrl') != '' ? _pick('imageUrl') : _pick('image_url');
    final durationStr = _formatDuration(track['durationSeconds'] ?? track['duration_seconds']);
    final category = _pick('category');

    final langColors = {
      'en': const Color(0xFF2563EB),
      'am': const Color(0xFF7C3AED),
      'om': const Color(0xFF059669),
      'so': const Color(0xFFDB2777),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1A1030),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image or gradient
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientBg(),
                    )
                  else
                    _gradientBg(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F0A1E).withOpacity(0.85),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                  // Bottom labels
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          titleText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        if (durationStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.timer_rounded, color: Colors.white70, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                durationStr,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Play button
                  if (audioUrl.isNotEmpty) ...[
                    _PlayButton(audioUrl: audioUrl, lang: _langLabel(lang)),
                    const SizedBox(height: 28),
                  ],

                  // Language-specific audio URLs
                  _AudioLanguageSection(track: track),

                  const SizedBox(height: 24),

                  // Description
                  if (descText.isNotEmpty) ...[
                    _Section(
                      icon: Icons.info_outline_rounded,
                      color: const Color(0xFF6366F1),
                      title: 'About This Track',
                      body: descText,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Benefits
                  if (benefitsText.isNotEmpty) ...[
                    _Section(
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFFEC4899),
                      title: 'Benefits',
                      body: benefitsText,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // All language titles / descriptions
                  _MultiLangSection(track: track, langColors: langColors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF61183e), Color(0xFF2D1B69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.music_note_rounded, size: 80, color: Colors.white24),
        ),
      );
}

// ── Play Button ──────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final String audioUrl;
  final String lang;
  const _PlayButton({required this.audioUrl, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF61183e), Color(0xFF9B2C6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF61183e).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing ($lang): ${audioUrl.length > 40 ? '${audioUrl.substring(0, 40)}…' : audioUrl}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'Play Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Audio by language ────────────────────────────────────────────────────────

class _AudioLanguageSection extends StatelessWidget {
  final Map<String, dynamic> track;
  const _AudioLanguageSection({required this.track});

  String _url(String key) {
    final v = track[key];
    return (v is String && v.trim().isNotEmpty) ? v.trim() : '';
  }

  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'label': 'English', 'color': const Color(0xFF2563EB), 'keys': ['audio_en_url', 'audioEnUrl']},
      {'code': 'am', 'label': 'አማርኛ', 'color': const Color(0xFF7C3AED), 'keys': ['audio_am_url', 'audioAmUrl']},
      {'code': 'om', 'label': 'Afaan Oromo', 'color': const Color(0xFF059669), 'keys': ['audio_om_url', 'audioOmUrl']},
      {'code': 'so', 'label': 'Af-Soomaali', 'color': const Color(0xFFDB2777), 'keys': ['audio_so_url', 'audioSoUrl']},
    ];

    final available = langs.where((l) {
      final keys = l['keys'] as List<String>;
      return keys.any((k) => _url(k).isNotEmpty);
    }).toList();

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Listen in Your Language',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: available.map((l) {
            final color = l['color'] as Color;
            final keys = l['keys'] as List<String>;
            final url = keys.map((k) => _url(k)).firstWhere((v) => v.isNotEmpty, orElse: () => '');
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing ${l['label']}: ${url.length > 30 ? '${url.substring(0, 30)}…' : url}'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: color,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    border: Border.all(color: color.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.headphones_rounded, color: color, size: 22),
                      const SizedBox(height: 5),
                      Text(
                        l['label'] as String,
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Multi-language titles ────────────────────────────────────────────────────

class _MultiLangSection extends StatelessWidget {
  final Map<String, dynamic> track;
  final Map<String, Color> langColors;
  const _MultiLangSection({required this.track, required this.langColors});

  String _pick(String key) {
    final v = track[key];
    return (v is String && v.trim().isNotEmpty) ? v.trim() : '';
  }

  @override
  Widget build(BuildContext context) {
    final langs = [
      {'code': 'en', 'label': 'English', 'titleKey': 'titleEn', 'titleKey2': 'title_en'},
      {'code': 'am', 'label': 'አማርኛ (Amharic)', 'titleKey': 'titleAm', 'titleKey2': 'title_am'},
      {'code': 'om', 'label': 'Afaan Oromoo', 'titleKey': 'titleOm', 'titleKey2': 'title_om'},
      {'code': 'so', 'label': 'Af-Soomaali', 'titleKey': 'titleSo', 'titleKey2': 'title_so'},
    ];

    final items = langs.where((l) {
      final t = _pick(l['titleKey']!);
      final t2 = _pick(l['titleKey2']!);
      return t.isNotEmpty || t2.isNotEmpty;
    }).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Track Details by Language',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map((l) {
            final color = langColors[l['code']] ?? AppColors.primary;
            final title = _pick(l['titleKey']!).isNotEmpty
                ? _pick(l['titleKey']!)
                : _pick(l['titleKey2']!);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l['label']!,
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Info section card ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Section({required this.icon, required this.color, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
