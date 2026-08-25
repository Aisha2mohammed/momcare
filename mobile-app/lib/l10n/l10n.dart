import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class L10n {
  static final all = [
    const Locale('en'), // English (fallback)
    const Locale('am'), // Amharic
    const Locale('om'), // Afan Oromo
  ];

  static String getLanguageName(String code) {
    switch (code) {
      case 'am':
        return 'አማርኛ (Amharic)';
      case 'om':
        return 'Afaan Oromoo (Oromo)';
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
    },
  };

  static String of(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    return localizedValues[locale]?[key] ?? localizedValues['en']![key]!;
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
