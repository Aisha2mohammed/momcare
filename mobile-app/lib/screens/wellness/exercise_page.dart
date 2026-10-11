import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:pregnancy_appp/widget/week_selector.dart';
import 'package:pregnancy_appp/widget/wellness_info_card.dart';
import 'package:pregnancy_appp/widget/wellness_type_filter_row.dart';
import 'exercise_detail_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// URL resolver
// ─────────────────────────────────────────────────────────────────────────────

String _safeExtractMedia(dynamic source) {
  if (source == null) return '';
  if (source is String) return source.trim();
  if (source is Map) {
    if (source['url'] != null) return _safeExtractMedia(source['url']);
    if (source['uri'] != null) return _safeExtractMedia(source['uri']);
    if (source['path'] != null) return _safeExtractMedia(source['path']);
    if (source['en'] != null) return _safeExtractMedia(source['en']);
  }
  return source.toString();
}

String _safeStr(dynamic val, [String fallback = '']) {
  if (val == null) return fallback;
  if (val is String) {
    final trimmed = val.trim();
    return trimmed.isNotEmpty ? trimmed : fallback;
  }
  if (val is Map) {
    for (final key in ['label', 'value', 'text', 'title', 'name', 'tip', 'desc', 'description', 'en', 'am', 'om', 'or', 'so']) {
      final v = val[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Map) {
        final inner = _safeStr(v);
        if (inner.isNotEmpty) return inner;
      }
    }
  }
  return val.toString();
}

String _resolveUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();
  String resolved = trimmed;
  if (resolved.contains('localhost')) {
    resolved = resolved.replaceAll('localhost', '192.168.1.4');
  }
  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return resolved;
  }
  const host = 'http://192.168.1.4:5000';
  return resolved.startsWith('/') ? '$host$resolved' : '$host/$resolved';
}

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 0 = not loaded yet → no week filter is applied.
  int _currentWeek = 0;
  int _selectedWeek = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectCurrentTrimester();
    _loadWeek();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeek() async {
    try {
      final data = await MotherService.getGestationalWeek();
      final week = (data['currentWeek'] as int?) ?? 0;
      if (!mounted || week <= 0) return;
      setState(() {
        _currentWeek = week;
        _selectedWeek = week;
      });
    } catch (_) {
      // Keep 0 → the week selector still renders, the current-week chip is
      // simply not highlighted and no week filter is applied.
    }
  }

  Future<void> _selectCurrentTrimester() async {
    final trimester = await ContentService.currentTrimester();
    if (!mounted || _tabController.index == trimester - 1) return;
    setState(() => _tabController.index = trimester - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(AppStrings.of(context, 'exercise')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: AppStrings.of(context, 'trimester_1')),
            Tab(text: AppStrings.of(context, 'trimester_2')),
            Tab(text: AppStrings.of(context, 'trimester_3')),
          ],
        ),
      ),
      body: Column(
        children: [
          WeekSelector(
            mode: 'week',
            selected: _selectedWeek,
            currentWeek: _currentWeek,
            onSelected: (v) => setState(() => _selectedWeek = v),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ExerciseList(trimester: 1, selectedWeek: _selectedWeek),
                _ExerciseList(trimester: 2, selectedWeek: _selectedWeek),
                _ExerciseList(trimester: 3, selectedWeek: _selectedWeek),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseList extends StatefulWidget {
  final int trimester;
  final int selectedWeek;

  const _ExerciseList({required this.trimester, required this.selectedWeek});

  @override
  State<_ExerciseList> createState() => _ExerciseListState();
}

class _ExerciseListState extends State<_ExerciseList> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String? _lastLang;
  String _currentType = 'do';

  Map<String, dynamic>? _weekInfo;

  static String _defaultExerciseWhy(String lang) {
    if (lang == 'am') return 'መደበኛ ቀላል እንቅስቃሴ የደም ዝውውርን ያሻሽላል፣ የወገብ ህመምን ያቃልላል።';
    if (lang == 'om' || lang == 'or') return 'Sochii salphaa yeroo yerootiin hojjechuun dhiiga sochoodhaa, cinaacha dugdaa hir’isa.';
    if (lang == 'so') return 'Dhaqdhaqaaq fudud oo joogto ah waxa uu horumariyaa wareega dhiigga.';
    return 'Regular gentle movement improves circulation, eases back pain and helps you sleep better.';
  }

  static String _defaultExerciseTips(String lang) {
    if (lang == 'am') return 'በቂ ውሃ ይጠጡ፣ የሰውነትዎን ስሜት ያዳምጡ፣ እና ከፍተኛ ጫና ያላቸውን እንቅስቃሴዎች ያስወግዱ።';
    if (lang == 'om' || lang == 'or') return 'Bishaan gahaa dhugaa, qaama kee dhagaggeeffadhu, sochii humna ol ta\'e irraa fagaadhu.';
    if (lang == 'so') return 'Cab biyo kugu filan, dhegeyso jirkaaga, kana fogow dhaqdhaqaaqyada culculus.';
    return 'Stay hydrated, listen to your body, and avoid high-impact activities or lying flat on your back.';
  }

  static List<Map<String, dynamic>> _getCuratedExerciseAvoidances(int trimester, String lang) {
    return [
      {
        'id': 'ex-avoid-1',
        'type': 'avoid',
        'category': 'High Impact',
        'isAvoid': true,
        'title_en': 'High-Impact Jumping & Intense Burpees',
        'title_am': 'ከፍተኛ ጫና ያላቸው ዝላይዎች እና ከባድ ቡርፒስ',
        'title_om': 'Utaalcha Humna Ol Ta\'e fi Burpees Cimaa',
        'title_so': 'Boodboodka Culus iyo Dhaqdhaqaaqa Xooggan',
        'why_important_en': 'Jumping exerts excessive downward pressure on your pelvic floor and loose joints, increasing risk of ligament injury and preterm contractions.',
        'why_important_am': 'ከፍተኛ ዝላይ በማህፀን ወለል እና በመገጣጠሚያዎች ላይ ከፍተኛ ጫና ስለሚፈጥር የመገጣጠሚያ መላላትና ድንገተኛ ምጥ ሊያስከትል ይችላል።',
        'why_important_om': 'Utaalchi humnaa naannoo mudhii fi buusaa irratti dhiibbaa guddaa uumuun balaa dhaloota yeroodhaa duraa fiduu danda\'a.',
        'why_important_so': 'Boodboodku waxa uu culeys badan saaraa minka iyo kala-goysyada, taasoo kordhisa halista dhaawaca iyo foosha degdegga ah.',
        'health_tips': 'Replace high-impact aerobics with low-impact walking, swimming, or prenatal stationary cycling.',
        'benefit_label': 'Risk Level',
        'benefit_value': 'High Risk of Pelvic Strain',
        'image_url': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
        'video_url': 'https://www.youtube.com/watch?v=2O7BqU2-z98',
        'movements': [
          {
            'name_en': 'Burpees & Box Jumps',
            'name_am': 'ከባድ ቡርፒስ እና ቦክስ ጃምፕስ',
            'name_om': 'Burpees fi Box Jumps',
            'name_so': 'Burpees iyo Boodboodka Sanduuqa',
            'label': 'Impact: Severe',
            'description_en': 'Rapid changes in elevation and hard landings risk abdominal jarring and balance loss.',
            'description_am': 'ፈጣን የከፍታ ለውጥ እና ጠንካራ ማረፍ ሚዛንን በማሳት እና ሆድ ላይ ጫና በማሳረፍ አደገኛ ነው።',
            'description_om': 'Saffisaan ol ka\'uun dhiibbaa garaa irratti fida.',
            'description_so': 'Degdeg u boodidu waxay dhibtaa dheelitirka iyo caloosha.',
            'image_url': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=400',
          },
          {
            'name_en': 'Heavy Weighted Squat Jumps',
            'name_am': 'ክብደት ያዘ ዝላይ ስኳት',
            'name_om': 'Ispoortii Ulfaataa Utaaluun',
            'name_so': 'Isku-dayga Culayska ee Boodboodka leh',
            'label': 'Strain: Pelvic Floor',
            'description_en': 'Excessive downward shock weakens pelvic ligaments already softened by pregnancy relaxin hormones.',
            'description_am': 'የሆርሞን ለውጥ ምክንያት የላሉ ጅማቶችን በእጅጉ በማዳከም የማህፀን መውረድ ሊያመጣ ይችላል።',
            'description_om': 'Misiirri dhiigaa fi ribuu miidhuu danda\'a.',
            'description_so': 'Waxay daciifisaa seedaha minka ee horey u jilcay.',
            'image_url': 'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=400',
          },
        ],
      },
      {
        'id': 'ex-avoid-2',
        'type': 'avoid',
        'category': 'Supine Posture',
        'isAvoid': true,
        'title_en': 'Exercises Lying Flat on Your Back (Supine)',
        'title_am': 'በጀርባ ተኝቶ የሚሰሩ እንቅስቃሴዎች',
        'title_om': 'Dugdaan Ciisanii Sochii Gochuu',
        'title_so': 'Jimicsiga Dhabarka Loogu Jiifo',
        'why_important_en': 'Lying flat on your back compresses the inferior vena cava, severely restricting blood and oxygen flow to your placenta and baby.',
        'why_important_am': 'በጀርባ መተኛት ትልቁን የደም ስር በመጫን ወደ ልጅዎ እና የእንግዴ ልጅ የሚሄደውን የደም እና የኦክስጅን መጠን ይቀንሳል።',
        'why_important_om': 'Dugdaan ciisuun ujummoo dhiigaa cuqunca\'ee oksijiinii gara daa\'imaatti deemu hir\'isa.',
        'why_important_so': 'Dhabarka oo loo jiifsadaa waxay cadaadinaysaa xididdada dhiigga, taasoo yareysa ogsijiinta u socota ilmaha.',
        'health_tips': 'Elevate your upper body with a wedge pillow or tilt 30 degrees to the left side while doing core exercises.',
        'benefit_label': 'Restriction',
        'benefit_value': 'Avoid After 16th Week',
        'image_url': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'video_url': 'https://www.youtube.com/watch?v=2O7BqU2-z98',
        'movements': [
          {
            'name_en': 'Standard Flat Bench Sit-ups',
            'name_am': 'ጠፍጣፋ መሬት ላይ የሚሰራ ቁጭ ብሎ መነሳት',
            'name_om': 'Ol Ka\'iinsa Dugdaan Ciisanii',
            'name_so': 'Jimicsiga Caloosha ee Tooska ah',
            'label': 'Risk: Diastasis Recti',
            'description_en': 'Causes abdominal muscle separation (diastasis recti) and dizziness from low blood pressure.',
            'description_am': 'የሆድ ጡንቻዎችን መለያየት እና የደም ግፊት በመቀነስ ማዞር ሊያስከትል ይችላል።',
            'description_om': 'Maashaa garaa addaan fageessuu danda\'a.',
            'description_so': 'Waxay keentaa kala go\'a murqaha caloosha iyo dawakhaad.',
            'image_url': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
          },
          {
            'name_en': 'Supine Leg Raises & Bicycles',
            'name_am': 'በጀርባ ተኝቶ እግርን ማንሳት እና ማሽከርከር',
            'name_om': 'Miila Ol Kaasuun Dugdaan',
            'name_so': 'Lugaha oo Kor Loo Qaado Dhabarka',
            'label': 'Risk: Vena Cava Compression',
            'description_en': 'Heavy pressure on maternal blood vessels leads to sudden nausea and shortness of breath.',
            'description_am': 'በትልልቅ የደም ስሮች ላይ ጫና በማሳደር ድንገተኛ የማቅለሽለሽ እና የአየር ማጠር ስሜት ያመጣል።',
            'description_om': 'Hafuura kuta fi haqqisaa fiduu danda\'a.',
            'description_so': 'Waxay keenaysaa lalabbo iyo neef-qabasho degdeg ah.',
            'image_url': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400',
          },
        ],
      },
      {
        'id': 'ex-avoid-3',
        'type': 'avoid',
        'category': 'Thermal Hazard',
        'isAvoid': true,
        'title_en': 'Hot Yoga & Extreme Overheating',
        'title_am': 'ሆት ዮጋ እና ከመጠን ያለፈ የሙቀት መጠን',
        'title_om': 'Hot Yoga fi Hoo\'a Humna Ol Ta\'e',
        'title_so': 'Hot Yoga iyo Kulaylka Badan',
        'why_important_en': 'Elevating core body temperature above 39°C (102°F) increases risks of neural tube defects and dehydration.',
        'why_important_am': 'የሰውነት ሙቀት ከ 39°C በላይ መጨመር የፅንስ ነርቭ እድገት እክል እና ከፍተኛ የሰውነት ፈሳሽ ማነስ ያስከትላል።',
        'why_important_om': 'Hoo\'i qaamaa dabaluun qaama daa\'imaa fi sammuu irratti rakkoo uuma.',
        'why_important_so': 'Heerkulka jirka oo kaca wuxuu keenaa cilladaha koritaanka neerfaha ee ilmaha.',
        'health_tips': 'Exercise in well-ventilated, air-conditioned rooms and drink water every 10–15 minutes.',
        'benefit_label': 'Safe Core Temp',
        'benefit_value': 'Keep Below 38.3°C',
        'image_url': 'https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=800',
        'video_url': 'https://www.youtube.com/watch?v=2O7BqU2-z98',
        'movements': [
          {
            'name_en': 'Bikram Heated Yoga Rooms',
            'name_am': 'በከፍተኛ ሙቀት ውስጥ የሚደረግ ዮጋ',
            'name_om': 'Bikram Yoga Hoo\'a Qabu',
            'name_so': 'Qolalka Kulul ee Bikram Yoga',
            'label': 'Room Temp: >40°C Danger',
            'description_en': 'Dangerous hyperthermia develops rapidly because pregnancy impairs maternal heat dissipation.',
            'description_am': 'በእርግዝና ወቅት ሰውነት ሙቀትን በቀላሉ ማስወገድ ስለማይችል ከፍተኛ የሙቀት ድካም ያመጣል።',
            'description_om': 'Hoo\'a qaamaa to\'achuun rakkisaa waan ta\'eef sodaachisaa dha.',
            'description_so': 'Jirku si dabiici ah kulaylka iskaga saari karin xilliga uurka.',
            'image_url': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400',
          },
        ],
      },
      {
        'id': 'ex-avoid-4',
        'type': 'avoid',
        'category': 'Contact Sports',
        'isAvoid': true,
        'title_en': 'Contact Sports & Heavy Weightlifting',
        'title_am': 'ግጭት ያለባቸው ስፖርቶች እና ከባድ ክብደት ማንሳት',
        'title_om': 'Ispoortii Walitti Bu\'iinsaa fi Ulfaatina Cimaa',
        'title_so': 'Ciyaaraha Iska-hor-imaadka iyo Culayska Weyn',
        'why_important_en': 'Risk of blunt abdominal trauma, placental abruption, and excessive intra-abdominal pressure from breath-holding.',
        'why_important_am': 'ሆድ ላይ ቀጥተኛ ጉዳት፣ የእንግዴ ልጅ መላቀቅ እና ትንፋሽ ይዞ በማንሳት የሚመጣ ከፍተኛ ጫና ሊያስከትል ይችላል።',
        'why_important_om': 'Balaa garaa irratti dhufullee fi dhiibbaa guddaan daa\'ima miidhuu danda\'a.',
        'why_important_so': 'Khatarta dhaawaca caloosha, go\'idda mandheerta iyo cadaadiska sare ee neefta la xajisto.',
        'health_tips': 'Never hold your breath (Valsalva maneuver); exhale on effort and use light hand weights under 3 kg.',
        'benefit_label': 'Precaution',
        'benefit_value': 'Zero Abdominal Impact',
        'image_url': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'video_url': 'https://www.youtube.com/watch?v=2O7BqU2-z98',
        'movements': [
          {
            'name_en': 'Maximal Barbell Deadlifts & Cleans',
            'name_am': 'ከባድ ባርቤል ዴድሊፍት',
            'name_om': 'Ulfaatina Garmalee Guddaa Kaasu',
            'name_so': 'Qaadista Birta Culus ee Xad-dhaafka ah',
            'label': 'Warning: Placental Strain',
            'description_en': 'Spikes blood pressure dangerously and puts acute strain on weakened uterine ligaments.',
            'description_am': 'የደም ግፊትን በከፍተኛ ሁኔታ ስለሚጨምር በማህፀን ጅማቶች ላይ አደገኛ ጫና ያሳድራል።',
            'description_om': 'Dhiibbaa dhiigaa ol kaasuun miidhaa fida.',
            'description_so': 'Waxay si degdeg ah kor ugu qaaddaa dhiigkarka.',
            'image_url': 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=400',
          },
        ],
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLang = Localizations.localeOf(context).languageCode;
    if (_lastLang != null && _lastLang != newLang) {
      _load();
    }
    _lastLang = newLang;
  }

  @override
  void didUpdateWidget(covariant _ExerciseList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWeek != widget.selectedWeek) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final week = widget.selectedWeek > 0 ? widget.selectedWeek : null;
      final currentLang = Localizations.localeOf(context).languageCode;
      final exFuture = ContentService.getExercises(
        widget.trimester,
        week: week,
        type: _currentType,
        lang: currentLang,
      );
      final weekFuture = ContentService.getExerciseWeek(widget.trimester, week: week, lang: currentLang);

      final results = await Future.wait([exFuture, weekFuture]);
      if (!mounted) return;

      final fetched = results[0] as List<dynamic>;
      final weekData = results[1] as Map<String, dynamic>?;

      // Client-side week filter.
      List<dynamic> items = fetched;
      if (week != null) {
        final matches = fetched.where((it) {
          final w = it['week'];
          return w != null &&
              (w == week || w.toString() == week.toString());
        }).toList();
        if (matches.isNotEmpty) items = matches;
      }

      // Filter by type (do vs avoid)
      final typeMatches = items.where((it) {
        if (it is! Map) return _currentType == 'do';
        final t = (it['type'] ?? it['category_type'] ?? it['category'] ?? '').toString().toLowerCase();
        final isAvoid = t == 'avoid' || it['isAvoid'] == true || it['is_avoid'] == true;
        return _currentType == 'avoid' ? isAvoid : !isAvoid;
      }).toList();

      if (_currentType == 'avoid') {
        items = typeMatches.isNotEmpty
            ? typeMatches
            : _getCuratedExerciseAvoidances(widget.trimester, currentLang);
      } else {
        items = typeMatches;
      }

      setState(() {
        _items = items;
        _weekInfo = weekData;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text(AppStrings.of(context, 'retry'))),
          ],
        ),
      );
    }

    final currentLang = Localizations.localeOf(context).languageCode;
    final lKey = currentLang == 'or' ? 'om' : currentLang;

    String resolveStr(Map? map, List<String> keys) {
      if (map == null) return '';
      for (final k in keys) {
        final v = map[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    String whyImportant = resolveStr(_weekInfo, [
      'why_important_$lKey', 'why_important_$currentLang',
      'whyImportant$lKey', 'whyImportant$currentLang',
      'why_important', 'whyImportant',
    ]);
    if (whyImportant.isEmpty) {
      for (final it in _items) {
        if (it is Map) {
          final candidate = resolveStr(it, [
            'why_important_$lKey', 'why_important_$currentLang',
            'why_important', 'whyImportant',
          ]);
          if (candidate.isNotEmpty) {
            whyImportant = candidate;
            break;
          }
        }
      }
    }
    if (whyImportant.isEmpty) {
      whyImportant = _defaultExerciseWhy(currentLang);
    }

    String exerciseTips = resolveStr(_weekInfo, [
      'exercise_tips_$lKey', 'exercise_tips_$currentLang',
      'exerciseTips$lKey', 'exerciseTips$currentLang',
      'exercise_tips', 'exerciseTips',
      'tips_$lKey', 'tips_$currentLang',
      'tips',
    ]);
    if (exerciseTips.isEmpty) {
      for (final it in _items) {
        if (it is Map) {
          final candidate = resolveStr(it, [
            'exercise_tips_$lKey', 'exercise_tips_$currentLang',
            'exercise_tips', 'exerciseTips',
            'tips_$lKey', 'tips_$currentLang',
            'tips',
          ]);
          if (candidate.isNotEmpty) {
            exerciseTips = candidate;
            break;
          }
        }
      }
    }
    if (exerciseTips.isEmpty) {
      exerciseTips = _defaultExerciseTips(currentLang);
    }

    final listView = _items.isEmpty
        ? ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.of(context, 'no_data'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              WellnessInfoCard.whyImportant(context: context, content: whyImportant),
              WellnessInfoCard.exerciseTips(context: context, content: exerciseTips),
            ],
          )
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _items.length + 1,
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    WellnessInfoCard.whyImportant(context: context, content: whyImportant),
                    WellnessInfoCard.exerciseTips(context: context, content: exerciseTips),
                  ],
                );
              }
              return _buildExerciseItem(context, _items[index]);
            },
          );

    return Column(
      children: [
        WellnessTypeFilterRow(
          currentType: _currentType,
          firstKey: 'do',
          firstLabel: AppStrings.of(context, 'what_to_do'),
          firstIcon: '💪',
          secondKey: 'avoid',
          secondLabel: AppStrings.of(context, 'what_not_to_do'),
          secondIcon: '🚫',
          onChanged: (newType) {
            setState(() {
              _currentType = newType;
            });
            _load();
          },
        ),
        Expanded(child: listView),
      ],
    );
  }

  Widget _buildExerciseItem(BuildContext context, dynamic item) {
    final lang = Localizations.localeOf(context).languageCode;
    final lKey = lang == 'or' ? 'om' : lang;

    String resolve(List<String> keys) {
      if (item is! Map) return '';
      for (final k in keys) {
        final v = item[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
        if (v is Map) {
          final s = _safeStr(v);
          if (s.isNotEmpty) return s;
        }
      }
      return '';
    }

    final name = resolve([
      'title_$lKey', 'title_$lang', 'name_$lKey', 'name_$lang',
      'title', 'name', 'title_en', 'title_am',
    ]);
    final safetyNotes = resolve([
      'why_important_$lKey', 'why_important_$lang', 'safety_notes_$lKey', 'safety_notes_$lang',
      'why_important', 'safetyNotes', 'safety_notes', 'description_$lKey', 'description',
    ]);
    final durationMin = (item['duration_minutes'] as num?)?.toInt() ??
        (item['duration_min'] as num?)?.toInt() ??
        0;
    final imageUrl =
        _resolveUrl(_safeExtractMedia(item['image_url'] ?? item['imageUrl'] ?? item['image']));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseDetailPage(
              exercise: Map<String, dynamic>.from(item as Map),
              isAvoid: _currentType == 'avoid',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image / hero ───────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ExercisePlaceholder(),
                    )
                  : _ExercisePlaceholder(),
            ),

            // ── Text content ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (name.isNotEmpty)
                              Text(
                                name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                            if (durationMin > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer_rounded,
                                      size: 13, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.of(context, 'about_min').replaceAll('%d', '$durationMin'),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.chevron_right_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                  if (safetyNotes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      safetyNotes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey[600], height: 1.4, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 56,
        ),
      ),
    );
  }
}
