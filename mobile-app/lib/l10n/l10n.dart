import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class L10n {
  static final all = [
    const Locale('en'), // English (fallback)
    const Locale('am'), // Amharic
    const Locale('om'), // Afaan Oromo
    const Locale('so'), // Af-Soomaali (Somali)
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'am':
        return 'አማርኛ (Amharic)';
      case 'om':
        return 'Afaan Oromoo (Oromo)';
      case 'so':
        return 'Af-Soomaali (Somali)';
      case 'en':
      default:
        return 'English';
    }
  }
}

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void setLocale(Locale locale) async {
    if (!L10n.all.contains(locale)) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code');
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }
}

class AppStrings {
  static Map<String, Map<String, String>> localizedValues = {
    'en': {
      'app_title': 'Pregnancy App',
      'nutrition': 'Nutrition Guide',
      'fetal_growth': 'Fetal Tracker',
      'exercise': 'Exercise',
      'sleeping': 'Sleeping Tips',
      'music': 'Relaxation',
      'video': 'Educational Videos',
      'tracker': 'Pregnancy Tracker',
      'emergency': 'Emergency Info',
      'language': 'Language',
      'welcome': 'Welcome back!',
      'trimester': 'Trimester',
      'week': 'Week',
      'days_left': 'days left',
      'local_food': 'Local Food Recommendations',
      'meal_plan': 'Ethiopian Meal Plans',
      'emergency_call': 'Emergency Call',
      'gps_share': 'Share Location',
      'first_aid': 'First Aid Tips',
      // Wellness hub
      'wellness_hub': 'Wellness Hub',
      'wellness_subtitle': 'Take care of yourself and your baby',
      'daily_motivation': 'Daily Motivation',
      'health_tips': 'Health Tips',
      'journal': 'Journal',
      'birth_plan': 'Birth Plan',
      // Trimester tabs
      'trimester_1': '1st Trimester',
      'trimester_2': '2nd Trimester',
      'trimester_3': '3rd Trimester',
      // Fetal page sections
      'fetal_overview': 'Overview',
      'fetal_development': 'Development',
      'fetal_mom': 'Mom',
      'fetal_checklist': 'Checklist',
      // Fetal stats
      'stat_length': 'Length',
      'stat_weight': 'Weight',
      'stat_size_of': 'Size of',
      // Fetal info cards
      'milestone_title': "This Week's Milestone",
      'health_tip_title': 'Health Tip',
      'message_for_you': 'A Message for You 💕',
      'diary_prompt_title': 'Diary Prompt',
      'bonding_activity': 'Bonding Activity',
      // Fetal development sections
      'brain_dev': 'Brain Development',
      'heart_dev': 'Heart Development',
      'organ_dev': 'Organ Development',
      'bone_muscle_dev': 'Bone & Muscle',
      'movements': 'Movements',
      'physical_dev': 'Physical Development',
      'developing_senses': 'Developing Senses',
      // Fetal mom sections
      'maternal_changes': 'Maternal Changes',
      'common_symptoms': 'Common Symptoms',
      'antenatal_care': 'Antenatal Care',
      'screening_info': 'Screening Info',
      'warning_signs': 'Warning Signs',
      'when_to_contact': 'When to Contact Provider',
      // Fetal checklist
      'your_checklist': "Your Week's Checklist",
      'no_checklist': 'No checklist available for this week yet.',
      // Exercise detail
      'about_exercise': 'About This Exercise',
      'how_to_do': 'How To Do It',
      'benefits': 'Benefits',
      'safety_notes': 'Safety Notes',
      // Sleep detail
      'about_tip': 'About This Tip',
      'tips_techniques': 'Tips & Techniques',
      // Music tabs
      'music_relaxation': 'Relaxation',
      'music_classical': 'Classical',
      'music_lullaby': 'Lullaby',
      'music_stories': 'Stories',
      // Nutrition period mode
      'period_month': 'Month',
      'period_trimester': 'Trimester',
      'period_week': 'Week',
      // Wellness bottom cards
      'why_this_is_important': 'Why This Is Important',
      'hydration': 'Hydration',
      'exercise_tips': 'Exercise Tips',
      'sleeping_tips': 'Sleeping Tips',
      // Wellness filtering tabs & details
      'what_to_eat': 'What to Eat',
      'what_not_to_eat': 'What to Avoid',
      'what_to_do': 'What to Do',
      'what_not_to_do': 'What to Avoid',
      'details_tab': 'Details',
      'video_tab': 'Video',
      'why_to_avoid': 'Why to Avoid',
      'health_tips_title': 'Health Tips',
      'helpful_tip': 'Helpful Tip',
      'view_all_items': 'View All Items',
      // Common
      'retry': 'Retry',
      'no_data': 'No data available.',
      'about_min': 'About %d min',
    },
    'am': {
      'app_title': 'የእርግዝና መተግበሪያ',
      'nutrition': 'የአመጋገብ መመሪያ',
      'fetal_growth': 'የሕፃን እድገት መከታተያ',
      'exercise': 'የእንቅስቃሴ ምክሮች',
      'sleeping': 'የእንቅልፍ ሁኔታ መመሪያ',
      'music': 'ሙዚቃ እና እረፍት',
      'video': 'ትምህርታዊ ቪዲዮዎች',
      'tracker': 'የእርግዝና ክትትል',
      'emergency': 'የአደጋ ጊዜ ጥሪ',
      'language': 'ቋንቋ',
      'welcome': 'እንኳን ደህና መጡ!',
      'trimester': 'ተከታታይ ወራት',
      'week': 'ሳምንት',
      'days_left': 'ቀናት ቀርተዋል',
      'local_food': 'የአካባቢ ምግብ ምክሮች',
      'meal_plan': 'የኢትዮጵያ የምግብ ዝርዝር',
      'emergency_call': 'የአደጋ ጊዜ ጥሪ',
      'gps_share': 'አካባቢን ያጋሩ',
      'first_aid': 'የመጀመሪያ እርዳታ ምክሮች',
      // Wellness hub
      'wellness_hub': 'የጤና ማዕከል',
      'wellness_subtitle': 'ለራስዎ እና ለልጅዎ ጤና ተጠንቀቁ',
      'daily_motivation': 'የዕለት ተዕለት ተነሳሽነት',
      'health_tips': 'የጤና ምክሮች',
      'journal': 'ማስታወሻ',
      'birth_plan': 'የወሊድ እቅድ',
      // Trimester tabs
      'trimester_1': '1ኛ ሦስት ወር',
      'trimester_2': '2ኛ ሦስት ወር',
      'trimester_3': '3ኛ ሦስት ወር',
      // Fetal page sections
      'fetal_overview': 'አጠቃላይ እይታ',
      'fetal_development': 'እድገት',
      'fetal_mom': 'እናት',
      'fetal_checklist': 'ዝርዝር',
      // Fetal stats
      'stat_length': 'ቁመት',
      'stat_weight': 'ክብደት',
      'stat_size_of': 'ያህል ትልቅ',
      // Fetal info cards
      'milestone_title': 'የዚህ ሳምንት ምዕራፍ',
      'health_tip_title': 'የጤና ምክር',
      'message_for_you': 'ለእርስዎ መልዕክት 💕',
      'diary_prompt_title': 'የማስታወሻ ጥያቄ',
      'bonding_activity': 'የትስስር እንቅስቃሴ',
      // Fetal development sections
      'brain_dev': 'የአዕምሮ እድገት',
      'heart_dev': 'የልብ እድገት',
      'organ_dev': 'የአካል ክፍሎች እድገት',
      'bone_muscle_dev': 'አጥንት እና ጡንቻ',
      'movements': 'እንቅስቃሴዎች',
      'physical_dev': 'አካላዊ እድገት',
      'developing_senses': 'የሚዳብሩ ስሜቶች',
      // Fetal mom sections
      'maternal_changes': 'የእናቶች ለውጦች',
      'common_symptoms': 'ተለምዷዊ ምልክቶች',
      'antenatal_care': 'ቅድመ ወሊድ ክብካቤ',
      'screening_info': 'የምርመራ መረጃ',
      'warning_signs': 'የማስጠንቀቂያ ምልክቶች',
      'when_to_contact': 'መቼ ሐኪምን ማነጋገር',
      // Fetal checklist
      'your_checklist': 'የዚህ ሳምንት ዝርዝር',
      'no_checklist': 'ለዚህ ሳምንት ዝርዝር እስካሁን የለም።',
      // Exercise detail
      'about_exercise': 'ስለ ይህ እንቅስቃሴ',
      'how_to_do': 'እንዴት ማድረግ',
      'benefits': 'ጥቅሞች',
      'safety_notes': 'የደህንነት ምክሮች',
      // Sleep detail
      'about_tip': 'ስለ ይህ ምክር',
      'tips_techniques': 'ምክሮች እና ዘዴዎች',
      // Music tabs
      'music_relaxation': 'ዘና ማለት',
      'music_classical': 'ክላሲካል',
      'music_lullaby': 'የሕፃናት ዜማ',
      'music_stories': 'ተረቶች',
      // Nutrition period mode
      'period_month': 'ወር',
      'period_trimester': 'ሦስት ወር',
      'period_week': 'ሳምንት',
      // Wellness bottom cards
      'why_this_is_important': 'ይህ ለምን አስፈላጊ ነው',
      'hydration': 'የሰውነት ፈሳሽ (ውሃ)',
      'exercise_tips': 'የእንቅስቃሴ ምክሮች',
      'sleeping_tips': 'የእንቅልፍ ምክሮች',
      // Wellness filtering tabs & details
      'what_to_eat': 'ምን መመገብ እንዳለብዎ',
      'what_not_to_eat': 'ምን ማስወገድ እንዳለብዎ',
      'what_to_do': 'ምን ማድረግ እንዳለብዎ',
      'what_not_to_do': 'ምን ማስወገድ እንዳለብዎ',
      'details_tab': 'ዝርዝሮች',
      'video_tab': 'ቪዲዮ',
      'why_to_avoid': 'ለምን ማስወገድ እንዳለብዎ',
      'health_tips_title': 'የጤና ምክሮች',
      'helpful_tip': 'ጠቃሚ ምክር',
      'view_all_items': 'ሁሉንም ንጥሎች ይመልከቱ',
      // Common
      'retry': 'እንደገና ሞክር',
      'no_data': 'ምንም ውሂብ የለም።',
      'about_min': 'ወደ %d ደቂቃ',
    },
    'om': {
      'app_title': 'Hordoffii Ulfaa',
      'nutrition': 'Qajeelfama Nyaataa',
      'fetal_growth': 'Uumama Ilmaatti Hordoffii',
      'exercise': 'Gorsa Sochii',
      'sleeping': 'Qajeelfama Rafuu',
      'music': 'Sirba fi Tasgabii',
      'video': 'Viidiyoo Barnootaa',
      'tracker': 'Hordoffii Ulfaa',
      'emergency': 'Bilbila Ariifachiisaa',
      'language': 'Afaan',
      'welcome': 'Baga Nagaan Dhufte!',
      'trimester': 'Trimisteerii',
      'week': 'Torban',
      'days_left': 'guyyoota hafan',
      'local_food': 'Gorsa Nyaata Naannoo',
      'meal_plan': 'Karoora Nyaata Itoophiyaa',
      'emergency_call': 'Bilbila Ariifachiisaa',
      'gps_share': 'Bakka Jirtan Ergaa',
      'first_aid': 'Gorsa Gargaarsa Jalqabaa',
      // Wellness hub
      'wellness_hub': 'Giddugala Fayyaa',
      'wellness_subtitle': 'Fayyaa keessaniif fi daa\'ima keessaniif of eegaa',
      'daily_motivation': 'Jajjabeessa Guyyaa',
      'health_tips': 'Gorsa Fayyaa',
      'journal': 'Yaadannoo',
      'birth_plan': 'Karoora Dhaluu',
      // Trimester tabs
      'trimester_1': 'Trimisteerii 1ffaa',
      'trimester_2': 'Trimisteerii 2ffaa',
      'trimester_3': 'Trimisteerii 3ffaa',
      // Fetal page sections
      'fetal_overview': 'Waliigaltee',
      'fetal_development': 'Guddinaa',
      'fetal_mom': 'Haadha',
      'fetal_checklist': 'Tarree',
      // Fetal stats
      'stat_length': 'Dheerina',
      'stat_weight': 'Ulfaatina',
      'stat_size_of': 'Guddina',
      // Fetal info cards
      'milestone_title': 'Jalqaba Torban Kanaa',
      'health_tip_title': 'Gorsa Fayyaa',
      'message_for_you': 'Ergaa Isiniif 💕',
      'diary_prompt_title': 'Gaaffii Yaadannoo',
      'bonding_activity': 'Hojii Walitti Hidhamiinsa',
      // Fetal development sections
      'brain_dev': 'Guddinaa Sammuu',
      'heart_dev': 'Guddinaa Onnee',
      'organ_dev': 'Guddinaa Qaamaa',
      'bone_muscle_dev': 'Lafee fi Dhuunfaa',
      'movements': 'Sosso\'insa',
      'physical_dev': 'Guddinaa Qaamaa',
      'developing_senses': 'Miidhagina Guddataa',
      // Fetal mom sections
      'maternal_changes': 'Jijjiirama Haadha',
      'common_symptoms': 'Mallattoolee Baay\'ee',
      'antenatal_care': 'Kunuunsa Dursaa',
      'screening_info': 'Odeeffannoo Sakatta\'iinsa',
      'warning_signs': 'Mallatoo Dhorkaataa',
      'when_to_contact': 'Yoom Ogessa Qunnamu',
      // Fetal checklist
      'your_checklist': 'Tarree Torban Kanaa',
      'no_checklist': 'Torban kana tarree hin argamne.',
      // Exercise detail
      'about_exercise': 'Waa\'ee Sochii Kanaa',
      'how_to_do': 'Akkamitti Gochuu',
      'benefits': 'Faayida',
      'safety_notes': 'Gorsa Nageenya',
      // Sleep detail
      'about_tip': 'Waa\'ee Gorsa Kanaa',
      'tips_techniques': 'Gorsa fi Tooftaa',
      // Music tabs
      'music_relaxation': 'Boqonnaa',
      'music_classical': 'Klassikaal',
      'music_lullaby': 'Sirba Daa\'imaa',
      'music_stories': 'Seenaalee',
      // Nutrition period mode
      'period_month': 'Ji\'a',
      'period_trimester': 'Trimisteerii',
      'period_week': 'Torban',
      // Wellness bottom cards
      'why_this_is_important': "Maaliif Akka Murteessaa Ta'e",
      'hydration': 'Bishaan Dhuguu',
      'exercise_tips': 'Gorsa Sochii',
      'sleeping_tips': 'Gorsa Rafuu',
      // Wellness filtering tabs & details
      'what_to_eat': 'Maal Nyaachuu Qabdu',
      'what_not_to_eat': 'Maal Irraa Fagaachuu Qabdu',
      'what_to_do': 'Maal Gochuu Qabdu',
      'what_not_to_do': 'Maal Irraa Fagaachuu Qabdu',
      'details_tab': "Bal'ina",
      'video_tab': 'Viidiyoo',
      'why_to_avoid': 'Maaliif Fagaachuu Qabdu',
      'health_tips_title': 'Gorsa Fayyaa',
      'helpful_tip': 'Gorsa Faayidaa Qabu',
      'view_all_items': 'Waan Hunda Ilaali',
      // Common
      'retry': 'Irra Deebi\'i',
      'no_data': 'Odeeffannoo hin jiru.',
      'about_min': 'Daqiiqaa %d tti dhiyaata',
    },
    'so': {
      'app_title': 'Abka Uurka',
      'nutrition': 'Hagaha Nafaqada',
      'fetal_growth': 'Raadraaca Uurjiifka',
      'exercise': 'Tababarka',
      'sleeping': 'Xeeladaha Hurdo',
      'music': 'Nasasho & Muusiko',
      'video': 'Fiidiyowyada Waxbarashada',
      'tracker': 'Raadraaca Uurka',
      'emergency': 'Xaalad Degdeg ah',
      'language': 'Luqad',
      'welcome': 'Ku soo dhowow!',
      'trimester': 'Saddexdii Bilood',
      'week': 'Toddobaad',
      'days_left': 'maalmood la',
      'local_food': 'Cuntada Maxalliga ah',
      'meal_plan': 'Qorshaha Cuntada',
      'emergency_call': 'Wicitaanka Degdegga ah',
      'gps_share': 'La Wadaag Goobta',
      'first_aid': 'Xaaladaha Koowaad',
      // Wellness hub
      'wellness_hub': 'Xarunta Caafimaadka',
      'wellness_subtitle': 'Is-xanaanee adiga iyo ilmahaaga',
      'daily_motivation': 'Dhiirigelinta Maalinlaha',
      'health_tips': 'Tilmaamaha Caafimaadka',
      'journal': 'Joornaalka',
      'birth_plan': 'Qorshaha Dhalmada',
      // Trimester tabs
      'trimester_1': 'Tobanka 1aad',
      'trimester_2': 'Tobanka 2aad',
      'trimester_3': 'Tobanka 3aad',
      // Fetal page sections
      'fetal_overview': 'Guudmar',
      'fetal_development': 'Koritaanka',
      'fetal_mom': 'Hooyo',
      'fetal_checklist': 'Liiska',
      // Fetal stats
      'stat_length': 'Dhererka',
      'stat_weight': 'Culeyska',
      'stat_size_of': 'Cabbirka',
      // Fetal info cards
      'milestone_title': 'Garaadka Usbuucan',
      'health_tip_title': 'Talada Caafimaadka',
      'message_for_you': 'Farriin Kuu Ah 💕',
      'diary_prompt_title': 'Su\'aasha Joornaalka',
      'bonding_activity': 'Xiriirka La Dhiso',
      // Fetal development sections
      'brain_dev': 'Koritaanka Maskaxda',
      'heart_dev': 'Koritaanka Wadnaha',
      'organ_dev': 'Koritaanka Xubnahe',
      'bone_muscle_dev': 'Lafaha & Muruqyada',
      'movements': 'Dhaqdhaqaaqyada',
      'physical_dev': 'Koritaanka Jirka',
      'developing_senses': 'Xuduudaha Koraya',
      // Fetal mom sections
      'maternal_changes': 'Isbeddelada Hooyada',
      'common_symptoms': 'Calaaladaha Caadiga',
      'antenatal_care': 'Daryeelka Uurka',
      'screening_info': 'Macluumaadka Baarista',
      'warning_signs': 'Calaaladaha Digniinta',
      'when_to_contact': 'Goorma La Xiriiro Dhakhtarka',
      // Fetal checklist
      'your_checklist': 'Liistada Usbuucan',
      'no_checklist': 'Liis ma jirto usbuucan.',
      // Exercise detail
      'about_exercise': 'Ku Saabsan Tababarkan',
      'how_to_do': 'Sida Loo Sameeyo',
      'benefits': 'Faa\'iidooyinka',
      'safety_notes': 'Xusuustaanka Ammaanka',
      // Sleep detail
      'about_tip': 'Ku Saabsan Taladan',
      'tips_techniques': 'Talooyin & Farsamooyin',
      // Music tabs
      'music_relaxation': 'Nasasho',
      'music_classical': 'Klassikaalka',
      'music_lullaby': 'Luullabi',
      'music_stories': 'Sheekooyin',
      // Nutrition period mode
      'period_month': 'Bil',
      'period_trimester': 'Saddex Bilood',
      'period_week': 'Toddobaad',
      // Wellness bottom cards
      'why_this_is_important': 'Maxay Tani Muhiim U Tahay',
      'hydration': 'Biyo Cabidda',
      'exercise_tips': 'Tilmaamaha Tababarka',
      'sleeping_tips': 'Xeeladaha Hurdo',
      // Wellness filtering tabs & details
      'what_to_eat': 'Waxa La Cuno',
      'what_not_to_eat': 'Waxa Laga Fogaado',
      'what_to_do': 'Waxa La Sameeyo',
      'what_not_to_do': 'Waxa Laga Fogaado',
      'details_tab': 'Faahfaahin',
      'video_tab': 'Muuqaal',
      'why_to_avoid': 'Sababta Loo Joojiyo',
      'health_tips_title': 'Tilmaamaha Caafimaadka',
      'helpful_tip': 'Talada Waxtarka Leh',
      'view_all_items': 'Eeg Dhammaan Waxyaabaha',
      // Common
      'retry': 'Isku Day',
      'no_data': 'Ma jirto macluumaad.',
      'about_min': 'Qiyaastii %d daqiiqo',
    },
  };

  static String of(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return localizedValues[locale]?[key] ?? localizedValues['en']?[key] ?? key;
  }
}

class FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => L10n.all.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const DefaultMaterialLocalizations();
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => L10n.all.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return const DefaultCupertinoLocalizations();
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
