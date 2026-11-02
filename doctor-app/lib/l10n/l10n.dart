import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageItem {
  final String code;
  final String name;
  final String nativeName;

  const LanguageItem({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

class LocaleNotifier extends ChangeNotifier {
  static final LocaleNotifier shared = LocaleNotifier._();

  static const String _prefKey = 'doctor_app_selected_language';

  static const List<LanguageItem> languages = [
    LanguageItem(code: 'en', name: 'English', nativeName: 'English'),
    LanguageItem(code: 'am', name: 'Amharic', nativeName: 'አማርኛ'),
    LanguageItem(code: 'or', name: 'Afan Oromo', nativeName: 'Afaan Oromoo'),
    LanguageItem(code: 'so', name: 'Somali', nativeName: 'Af-Soomaali'),
  ];

  String _currentCode = 'en';

  LocaleNotifier._() {
    _loadLanguage();
  }

  String get currentCode => _currentCode;
  Locale get currentLocale => Locale(_currentCode == 'or' ? 'om' : _currentCode);

  String get currentDisplayName {
    final item = languages.firstWhere(
      (l) => l.code == _currentCode,
      orElse: () => languages.first,
    );
    return '${item.name} (${item.nativeName})';
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && languages.any((l) => l.code == saved)) {
        _currentCode = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String code) async {
    if (!languages.any((l) => l.code == code)) return;
    if (_currentCode == code) return;
    _currentCode = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {}
  }

  /// Translation lookup helper
  String t(String key) {
    return DoctorTranslations.get(key, _currentCode);
  }
}

class DoctorTranslations {
  static String get(String key, String langCode) {
    final langMap = _values[langCode] ?? _values['en']!;
    return langMap[key] ?? _values['en']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _values = {
    // ──────────────── ENGLISH ────────────────
    'en': {
      'app_title': 'MomCare Doctor',
      'home': 'Home',
      'consultations': 'Consultations',
      'appointments': 'Appointments',
      'profile': 'Profile',
      'notifications': 'Alerts & Notifications',
      // Home Screen
      'patient_registry': 'Patient Risk Registry',
      'sorted_by_risk': 'Sorted by Risk',
      'all_patients': 'All Patients',
      'high_risk': 'High Risk',
      'moderate_risk': 'Moderate Risk',
      'stable': 'Stable',
      'today_appointments': "Today's Consultations",
      'search_patient': 'Search by patient name, phone, or symptoms...',
      'chat_now': 'Chat Now',
      'view_chart': 'View Chart',
      'risk_score': 'Risk Score',
      'no_patients': 'No Patients Found',
      'no_patients_sub': 'There are no patients matching the selected filter.',
      // Duty Status
      'duty_online': 'Online',
      'duty_away': 'Away',
      'duty_off': 'Off-Duty',
      'total_patients': 'Total Patients',
      'pending_appts': 'Pending Requests',
      'high_risk_alerts': 'High Risk Alerts',
      'verified': 'Verified',
      'under_review': 'Under Review',
      'verified_badge': 'Verified & Approved by Admin',
      'under_review_badge': 'Pending Admin Verification & Credential Review',
      // Chat Tab
      'patient_consultations': 'Patient Consultations',
      'consultations_subtitle': 'Direct messages & triage follow-ups with admitted patients',
      'all_chats': 'All Chats',
      'unread': 'Unread',
      'no_active_chats': 'No Active Chats',
      'no_unread_chats': 'All Caught Up!',
      'search_chat': 'Search patient or messages...',
      // Profile Tab
      'doctor_profile': 'Doctor Profile',
      'credentials_details': 'Credentials & Practice Details',
      'edit_details': 'Edit Details',
      'medical_license': 'Medical License',
      'expires': 'Expires',
      'national_id': 'National ID Document',
      'medical_credentials': 'Medical Credentials & Certifications',
      'practice_location': 'Primary Hospital / Practice Location',
      'experience': 'Clinical Experience',
      'spoken_languages': 'Spoken Languages',
      'clinical_bio': 'Clinical Bio & Focus Areas',
      'schedule_builder': 'Weekly Schedule Builder',
      'account_preferences': 'Account & Preferences',
      'notification_prefs': 'Notification Preferences',
      'triage_push_settings': 'Triage alerts and appointment push settings',
      'app_language': 'App Language',
      'current_language': 'Current',
      'support_help': 'Provider Support & Help Desk',
      'support_help_sub': 'Contact MomCare clinical coordinator team',
      'sign_out': 'Sign Out Provider Account',
      // Notification Preferences Modal
      'notification_title': 'Notification Preferences',
      'notification_subtitle': 'Customize your maternal health triage notifications',
      'urgent_alerts': 'Urgent Patient Risk Alerts (High BP/Glucose)',
      'urgent_alerts_sub': 'Push alerts immediately when critical vitals are logged',
      'new_appt_requests': 'New Appointment & Consultation Requests',
      'new_appt_sub': 'Notify when mother requests a booking',
      'lab_reports': 'New Lab & Ultrasound Reports Uploaded',
      'lab_reports_sub': 'Alert when diagnostics are completed',
      'emergency_sound': 'Audible Emergency Risk Alert Sound',
      'emergency_sound_sub': 'Play audible tone even in silent mode for critical maternal emergencies',
      'save_preferences': 'Save Preferences',
      'preferences_saved': 'Notification settings updated',
    },

    // ──────────────── AMHARIC (አማርኛ) ────────────────
    'am': {
      'app_title': 'የዶክተር ሞምኬር',
      'home': 'ዋና ገጽ',
      'consultations': 'ውይይቶች',
      'appointments': 'ቀጠሮዎች',
      'profile': 'መገለጫ',
      'notifications': 'ማሳወቂያዎች እና ማንቂያዎች',
      // Home Screen
      'patient_registry': 'የእናቶች ስጋት መዝገብ',
      'sorted_by_risk': 'በስጋት ደረጃ የተደረደሩ',
      'all_patients': 'ሁሉም እናቶች',
      'high_risk': 'ከፍተኛ ስጋት',
      'moderate_risk': 'መካከለኛ ስጋት',
      'stable': 'መረጋጋት ያለበት',
      'today_appointments': 'የዛሬ ምክክር ቀጠሮዎች',
      'search_patient': 'በስም፣ በስልክ ወይም በምልክት ፈልግ...',
      'chat_now': 'ውይይት ጀምር',
      'view_chart': 'ቻርት ይመልከቱ',
      'risk_score': 'የስጋት ውጤት',
      'no_patients': 'ምንም እናት አልተገኘም',
      'no_patients_sub': 'የተመረጠውን ማጣሪያ የሚያሟላ እናት አልተገኘም።',
      // Duty Status
      'duty_online': 'በስራ ላይ',
      'duty_away': 'ለጊዜው የለም',
      'duty_off': 'ከስራ ውጪ',
      'total_patients': 'ጠቅላላ እናቶች',
      'pending_appts': 'በመጠባበቅ ላይ ያሉ ቀጠሮዎች',
      'high_risk_alerts': 'ከፍተኛ ስጋት ማንቂያዎች',
      'verified': 'የተረጋገጠ',
      'under_review': 'በግምገማ ላይ',
      'verified_badge': 'በአስተዳዳሪው የተረጋገጠ እና የጸደቀ',
      'under_review_badge': 'የሰነዶች ማረጋገጫ በመጠባበቅ ላይ',
      // Chat Tab
      'patient_consultations': 'የእናቶች ምክክሮች',
      'consultations_subtitle': 'ከተመዘገቡ እናቶች ጋር የቀጥታ መልዕክቶች እና ክትትሎች',
      'all_chats': 'ሁሉም ውይይቶች',
      'unread': 'ያልተነበቡ',
      'no_active_chats': 'ምንም ንቁ ውይይት የለም',
      'no_unread_chats': 'ሁሉም መልዕክቶች ተነበዋል!',
      'search_chat': 'እናትን ወይም መልዕክትን ፈልግ...',
      // Profile Tab
      'doctor_profile': 'የሀኪሙ መገለጫ',
      'credentials_details': 'የህክምና ፍቃድ እና ሙያዊ ዝርዝሮች',
      'edit_details': 'ዝርዝር አርትዕ',
      'medical_license': 'የህክምና ፈቃድ',
      'expires': 'የሚያበቃበት',
      'national_id': 'ብሔራዊ መታወቂያ ሰነድ',
      'medical_credentials': 'የሙያ ማስረጃዎች እና ሰርተፊኬቶች',
      'practice_location': 'ዋና ሆስፒታል / ክሊኒክ አድራሻ',
      'experience': 'የህክምና ልምድ',
      'spoken_languages': 'የሚናገሯቸው ቋንቋዎች',
      'clinical_bio': 'ስለ ሀኪሙ እና የሙያ ትኩረት',
      'schedule_builder': 'የሳምንታዊ የስራ መርሐግብር',
      'account_preferences': 'መለያ እና ምርጫዎች',
      'notification_prefs': 'የማሳወቂያ ምርጫዎች',
      'triage_push_settings': 'የስጋት ማንቂያ እና የቀጠሮ ማሳወቂያዎች',
      'app_language': 'የመተግበሪያ ቋንቋ',
      'current_language': 'የአሁኑ',
      'support_help': 'የአገልግሎት ድጋፍ እና እገዛ',
      'support_help_sub': 'ከሞምኬር ክሊኒካዊ አስተባባሪ ቡድን ጋር ይገናኙ',
      'sign_out': 'ከመለያ ውጣ',
      // Notification Preferences Modal
      'notification_title': 'የማሳወቂያ ምርጫዎች',
      'notification_subtitle': 'የእርግዝና ስጋት ማንቂያዎችን እንደፍላጎትዎ ያስተካክሉ',
      'urgent_alerts': 'አስቸኳይ የእናት ስጋት ማንቂያ (ከፍተኛ ደም ግፊት/ስኳር)',
      'urgent_alerts_sub': 'አስጊ የጤና መረጃዎች ሲመዘገቡ ወዲያውኑ ማሳወቂያ ይላካል',
      'new_appt_requests': 'አዳዲስ የቀጠሮ እና የምክክር ጥያቄዎች',
      'new_appt_sub': 'እናት ቀጠሮ ስትጠይቅ ማሳወቂያ ይላካል',
      'lab_reports': 'አዳዲስ የላብራቶሪ እና አልትራሳውንድ ውጤቶች',
      'lab_reports_sub': 'የምርመራ ውጤቶች ሲጠናቀቁ ማሳወቂያ ይሰጣል',
      'emergency_sound': 'የአስቸኳይ ጊዜ የስልክ ድምፅ ማንቂያ',
      'emergency_sound_sub': 'ስልኩ በዝምታ (silent) ሁነታ ቢሆንም የድምፅ ማንቂያ ያሰማል',
      'save_preferences': 'ምርጫዎችን አስቀምጥ',
      'preferences_saved': 'የማሳወቂያ ቅንብሮች በተሳካ ሁኔታ ተዘምነዋል',
    },

    // ──────────────── AFAN OROMO (Oromoo) ────────────────
    'or': {
      'app_title': 'MomCare Doktoora',
      'home': 'Fuula Duraa',
      'consultations': 'Mariiwwan',
      'appointments': 'Beellamoota',
      'profile': 'Piroofayilii',
      'notifications': 'Beeksisa & Dhaamsa',
      // Home Screen
      'patient_registry': 'Galmee Sodaa Haadholii',
      'sorted_by_risk': 'Sadarkaa Soodaan Kan Qindaa’e',
      'all_patients': 'Haadholii Hundumaa',
      'high_risk': 'Sodaa Ol’aanaa',
      'moderate_risk': 'Sodaa Giddu-galeessaa',
      'stable': 'Tasgabbaa’aa',
      'today_appointments': 'Beellamoota Har’aa',
      'search_patient': 'Maqaa, bilbila ykn mallattoon barbaadi...',
      'chat_now': 'Marii Jalqabi',
      'view_chart': 'Chaartii Ilaali',
      'risk_score': 'Qabxii Sodaa',
      'no_patients': 'Haati Tokkollee Hin Argamne',
      'no_patients_sub': 'Haati filannoo kanaan walsimu hin jiru.',
      // Duty Status
      'duty_online': 'Hojirra Jira',
      'duty_away': 'Yeroof Hin Jiru',
      'duty_off': 'Hojiin Ala',
      'total_patients': 'Ida’ama Haadholii',
      'pending_appts': 'Beellamoota Eegaman',
      'high_risk_alerts': 'Akeekkachiisa Sodaa Ol’aanaa',
      'verified': 'Mirkanaa’eera',
      'under_review': 'Qorannoo Irra Jira',
      'verified_badge': 'Bulchiinsaan Kan Mirkanaa’e',
      'under_review_badge': 'Mirkaneessi Sanadaa Eegamaa Jira',
      // Chat Tab
      'patient_consultations': 'Mariiwwan Haadholii',
      'consultations_subtitle': 'Dhaamsa kallattii haadholii galmaa’an waliin',
      'all_chats': 'Mariiwwan Hundumaa',
      'unread': 'Kan Hin Dubbifamne',
      'no_active_chats': 'Mariin Hojirra Jiru Hin Jiru',
      'no_unread_chats': 'Dhaamsi hundi dubbifameera!',
      'search_chat': 'Haadha ykn dhaamsa barbaadi...',
      // Profile Tab
      'doctor_profile': 'Piroofayilii Doktooraa',
      'credentials_details': 'Heyyama Yaalaa & Bal’ina Hojii',
      'edit_details': 'Gulaali',
      'medical_license': 'Heyyama Hojii Yaalaa',
      'expires': 'Kan Dhumu',
      'national_id': 'Sanada Waraqaa Eenyummaa',
      'medical_credentials': 'Ragaalee Ogummaa & Sertafikeetota',
      'practice_location': 'Hospitaala / Bakka Hojii',
      'experience': 'Muuxannoo Yaalaa',
      'spoken_languages': 'Afaanota Dubbataman',
      'clinical_bio': 'Waa’ee Doktooraa & Xiyyeeffannoo',
      'schedule_builder': 'Sagantaa Hojii Torbanii',
      'account_preferences': 'Herrega & Filannoowwan',
      'notification_prefs': 'Filannoowwan Beeksisaa',
      'triage_push_settings': 'Beeksisa sodaa fi beellamaa',
      'app_language': 'Afaan Appilikeeshinii',
      'current_language': 'Ammaa',
      'support_help': 'Gargaarsa & Deeggarsa',
      'support_help_sub': 'Garee qindeessituu MomCare qunnamaa',
      'sign_out': 'Herrega Keessaa Ba’i',
      // Notification Preferences Modal
      'notification_title': 'Filannoowwan Beeksisaa',
      'notification_subtitle': 'Akeekkachiisa sodaa ulfaa akka fedha keetti qindeeffadhu',
      'urgent_alerts': 'Akeekkachiisa Hatattamaa (Dhiibbaa Dhiigaa/Sukkaara Ol’aanaa)',
      'urgent_alerts_sub': 'Mallattoon yeroo galmaa’u hatattamaan beeksisa',
      'new_appt_requests': 'Gaaffii Beellamaa & Marii Haaraa',
      'new_appt_sub': 'Yeroo haati beellama gaafattu beeksisa',
      'lab_reports': 'Bu’aa Laabooratorii & Ultrasawundii Haaraa',
      'lab_reports_sub': 'Yeroo qorannoon xumuramu beeksisa',
      'emergency_sound': 'Sagalee Akeekkachiisa Yeroo Hatattamaa',
      'emergency_sound_sub': 'Bilbilli callisa (silent) irra yoo jiraatellee sagalee dhageessisa',
      'save_preferences': 'Qindaa’ina Olkaawi',
      'preferences_saved': 'Qindaa’inni beeksisaa milkaa’inaan haaromeera',
    },

    // ──────────────── SOMALI (Soomaali) ────────────────
    'so': {
      'app_title': 'MomCare Dhaqtar',
      'home': 'Hoyga',
      'consultations': 'Wadahadallada',
      'appointments': 'Ballamaha',
      'profile': 'Bogga Shakhsiga',
      'notifications': 'Ogeysiisyada & Digniinaha',
      // Home Screen
      'patient_registry': 'Diiwaanka Halista Hooyooyinka',
      'sorted_by_risk': 'Loo kala saaray sida ay u kala halis badan yihiin',
      'all_patients': 'Dhammaan Hooyooyinka',
      'high_risk': 'Halis Sare',
      'moderate_risk': 'Halis Dhexdhexaad ah',
      'stable': 'Deggan',
      'today_appointments': 'Ballamaha Maanta',
      'search_patient': 'Ku raadi magac, taleefan ama astaamo...',
      'chat_now': 'Wadahadal Hadda',
      'view_chart': 'Eeg Shaxda',
      'risk_score': 'Dhibcaha Halista',
      'no_patients': 'Lama Helin Hooyooyin',
      'no_patients_sub': 'Ma jiraan bukaan ku habboon shaandhada la doortay.',
      // Duty Status
      'duty_online': 'Shaqada Ku Jira',
      'duty_away': 'Waqti Kooban Ma Joogo',
      'duty_off': 'Shaqada Ka Maqan',
      'total_patients': 'Wadarta Hooyooyinka',
      'pending_appts': 'Ballamaha Sugaya',
      'high_risk_alerts': 'Digniinaha Halista Sare',
      'verified': 'La Hubiyay',
      'under_review': 'Dib u Eegis Ku Jirta',
      'verified_badge': 'Maamulku Wuu Xaqiijiyay Oo Ansixiyay',
      'under_review_badge': 'Xaqiijinta Dukumeentiga Ayaa La Sugayaa',
      // Chat Tab
      'patient_consultations': 'La-tashiyada Hooyooyinka',
      'consultations_subtitle': 'Farriimaha tooska ah iyo dabagalka hooyooyinka diiwaangashan',
      'all_chats': 'Dhammaan Wadahadallada',
      'unread': 'Aan La Akhrin',
      'no_active_chats': 'Ma Jiraan Wadahadallo Firfircoon',
      'no_unread_chats': 'Dhammaan farriimaha waa la akhriyay!',
      'search_chat': 'Raadi bukaan ama farriin...',
      // Profile Tab
      'doctor_profile': 'Bogga Dhaqtarka',
      'credentials_details': 'Shatiga Caafimaadka & Faahfaahinta Shaqada',
      'edit_details': 'Wax Ka Beddel',
      'medical_license': 'Shatiga Caafimaadka',
      'expires': 'Wuxuu Dhacayaa',
      'national_id': 'Dukumeentiga Aqoonsiga Qaranka',
      'medical_credentials': 'Shahaadooyinka & Khibradda Caafimaad',
      'practice_location': 'Isbitaalka / Goobta Shaqada',
      'experience': 'Khibradda Caafimaad',
      'spoken_languages': 'Luqadaha La Ku Hadlo',
      'clinical_bio': 'Faahfaahinta Dhaqtarka & Khabiirnimada',
      'schedule_builder': 'Jadwalka Shaqada Todobaadlaha ah',
      'account_preferences': 'Koontada & Dookhyada',
      'notification_prefs': 'Dookhyada Ogeysiiska',
      'triage_push_settings': 'Digniinaha halista iyo ogeysiisyada ballanta',
      'app_language': 'Luuqadda App-ka',
      'current_language': 'Hadda',
      'support_help': 'Caawinta & Taageerada Dhaqtarka',
      'support_help_sub': 'La xiriir kooxda iskuduwaha caafimaadka ee MomCare',
      'sign_out': 'Ka Bax Koontada',
      // Notification Preferences Modal
      'notification_title': 'Dookhyada Ogeysiiska',
      'notification_subtitle': 'Habee ogeysiisyada halista caafimaadka hooyada',
      'urgent_alerts': 'Digniin Degdeg ah (Dhiig-karka/Sonkorta Sare)',
      'urgent_alerts_sub': 'Ogeysiis degdeg ah marka calaamado halis ah la diiwaangeliyo',
      'new_appt_requests': 'Codsiyada Ballanta & La-tashiga Cusub',
      'new_appt_sub': 'Ogeysii marka hooyadu codsato ballan',
      'lab_reports': 'Natiijooyinka Baaritaanka & Ultrasound-ka Cusub',
      'lab_reports_sub': 'Digniin marka baaritaannada la dhammeeyo',
      'emergency_sound': 'Codka Digniinta Xaaladaha Degdegga ah',
      'emergency_sound_sub': 'Samee dhawaaq xitaa marka taleefanku aamusnaan ku jiro',
      'save_preferences': 'Keydi Dookhyada',
      'preferences_saved': 'Dejinta ogeysiiska si guul leh ayaa loo cusboonaysiiyay',
    },
  };
}
