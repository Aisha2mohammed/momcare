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
      // Navigation
      'nav_home': 'Home',
      'nav_community': 'Community',
      'nav_wellness': 'Wellness',
      'nav_profile': 'Profile',
      // Home & Greeting
      'baby_growing': '%s, your baby is growing beautifully!',
      'ask_assistant': 'Ask our Assistant',
      'ask_assistant_subtitle': 'Get instant and safe answers',
      'wellness_guides': 'Wellness Guides',
      'relaxation_music': 'Relaxation Music',
      'stay_active': 'Stay Active',
      'better_sleep': 'Better Sleep',
      'see_all': 'See All',
      // Am I Pregnant Card
      'your_pregnancy_this_week': 'Your Pregnancy\nThis Week',
      'size_comparison_text': 'Size of a %s',
      'heart_rate_text': 'Heart rate: %d bpm',
      'days_remaining_text': '%d days remaining',
      'view_details': 'View Details',
      // Profile Page
      'account_settings': 'Account Settings',
      'personal_info': 'Personal Information',
      'pregnancy_details': 'Pregnancy Details (LMP)',
      'app_settings': 'App Settings',
      'notifications': 'Notifications',
      'privacy_security': 'Privacy & Security',
      'change_photo': 'Change Profile Photo',
      'choose_photo_source': 'Choose where to select your profile picture from:',
      'take_photo': 'Take Photo',
      'capture_camera': 'Capture using device camera',
      'choose_gallery': 'Choose from Gallery',
      'select_gallery': 'Select an existing photo from gallery',
      'remove_photo': 'Remove Photo',
      'remove_photo_confirm': 'Are you sure you want to remove your profile photo?',
      'remove_photo_success': 'Your profile photo has been removed successfully.',
      'photo_uploaded': 'Photo Uploaded!',
      'photo_uploaded_msg': 'Your profile picture has been updated successfully.',
      'upload_failed': 'Upload Failed',
      'edit_name': 'Edit Name',
      'full_name': 'Full Name',
      'save': 'Save',
      'cancel': 'Cancel',
      'log_out': 'Log out',
      'change_password': 'Change password',
      'privacy_policy': 'Privacy policy',
      'weeks_pregnant': '%d Weeks Pregnant',
      'pregnancy_details_not_set': 'Not set (tap to set LMP date)',
      'pregnancy_details_updated': 'Pregnancy details updated successfully.',
      'stat_phone': 'Phone',
      'stat_due_date': 'Due Date',
      'assigned_hospital': 'Assigned hospital: %s',
      'push_notifications': 'Push notifications',
      'managed_by_phone': 'Managed by your phone settings',
      'open_system_settings': 'Open system settings',
      'reset_link_sent': 'Password reset link will be sent to your email',
      'policy_coming_soon': 'Privacy policy screen coming soon',
      'loading': 'Loading...',
      // Birth Plan
      'birth_material_list': 'Birth Material List',
      'hospital_bag_checklist': 'Hospital Bag Checklist',
      'hospital_bag_desc': 'Pack your hospital bag a few weeks before your due date.',
      'item_mother_id': "Mother's ID and Medical Records",
      'item_printed_plan': 'Birth Plan printed copies',
      'item_comfortable_clothing': 'Comfortable clothing / Robe',
      'item_slippers_socks': 'Slippers and socks',
      'item_maternity_pads': 'Maternity pads & Underwear',
      'item_toiletries': 'Toiletries (Toothbrush, Deodorant)',
      'item_baby_clothes': 'Baby Clothes (Newborn size)',
      'item_diapers_wipes': 'Baby Diapers & Wipes',
      'item_baby_blanket': 'Baby blanket',
      'item_car_seat': 'Car seat installed',
      // Quick Actions & Chatbot
      'quick_actions': 'Quick Actions',
      'connect_doctor': 'Connect Doctor',
      'connect_doctor_desc': 'Book appointments & find doctors',
      'ai_assistant': 'AI Assistant',
      'ai_assistant_desc': 'Chat with Enat AI Bot',
      'type_message': 'Type a message...',
      'thinking': 'Thinking...',
      'always_active': 'Always active',
      'currently_offline': 'Currently offline',
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
      // Navigation
      'nav_home': 'መነሻ',
      'nav_community': 'ማህበረሰብ',
      'nav_wellness': 'ጤና',
      'nav_profile': 'መገለጫ',
      // Home & Greeting
      'baby_growing': '%s፣ ልጅዎ በሚያምር ሁኔታ እያደገ ነው!',
      'ask_assistant': 'ረዳታችንን ይጠይቁ',
      'ask_assistant_subtitle': 'ፈጣን እና ደህንነቱ የተጠበቀ መልስ ያግኙ',
      'wellness_guides': 'የጤና መመሪያዎች',
      'relaxation_music': 'የእረፍት ሙዚቃ',
      'stay_active': 'ንቁ ይሁኑ',
      'better_sleep': 'ጥሩ እንቅልፍ',
      'see_all': 'ሁሉንም እይ',
      // Am I Pregnant Card
      'your_pregnancy_this_week': 'የእርስዎ እርግዝና\nበዚህ ሳምንት',
      'size_comparison_text': 'የ%s ያህል መጠን',
      'heart_rate_text': 'የልብ ምት፡ %d bpm',
      'days_remaining_text': '%d ቀናት ቀርተዋል',
      'view_details': 'ዝርዝሮችን ይመልከቱ',
      // Profile Page
      'account_settings': 'የመለያ ቅንብሮች',
      'personal_info': 'የግል መረጃ',
      'pregnancy_details': 'የእርግዝና ዝርዝሮች (LMP)',
      'app_settings': 'የመተግበሪያ ቅንብሮች',
      'notifications': 'ማሳወቂያዎች',
      'privacy_security': 'ግላዊነት እና ደህንነት',
      'change_photo': 'የመገለጫ ፎቶ ይቀይሩ',
      'choose_photo_source': 'የመገለጫ ፎቶ ከየት እንደሚመርጡ ይምረጡ፡',
      'take_photo': 'ፎቶ አንሳ',
      'capture_camera': 'በስልክ ካሜራ ያንሱ',
      'choose_gallery': 'ከጋለሪ ይምረጡ',
      'select_gallery': 'ከጋለሪ ውስጥ ፎቶ ይምረጡ',
      'remove_photo': 'ፎቶውን ሰርዝ',
      'remove_photo_confirm': 'እርግጠኛ ነዎት የመገለጫ ፎቶዎን መሰረዝ ይፈልጋሉ?',
      'remove_photo_success': 'የመገለጫ ፎቶው በተሳካ ሁኔታ ተሰርዟል።',
      'photo_uploaded': 'ፎቶው ተጭኗል!',
      'photo_uploaded_msg': 'የመገለጫ ፎቶዎ በተሳካ ሁኔታ ተዘምኗል።',
      'upload_failed': 'ፎቶውን መጫን አልተሳካም',
      'edit_name': 'ስም ቀይር',
      'full_name': 'ሙሉ ስም',
      'save': 'አስቀምጥ',
      'cancel': 'ይቅር',
      'log_out': 'ውጣ',
      'change_password': 'የይለፍ ቃል ቀይር',
      'privacy_policy': 'የግላዊነት ፖሊሲ',
      'weeks_pregnant': '%d ሳምንታት እርጉዝ',
      'pregnancy_details_not_set': 'አልተመረጠም (LMP ለመምረጥ ይንኩ)',
      'pregnancy_details_updated': 'የእርግዝና መረጃ በተሳካ ሁኔታ ተዘምኗል።',
      'stat_phone': 'ስልክ',
      'stat_due_date': 'የሚወልዱበት ቀን',
      'assigned_hospital': 'የተመደበው ሆስፒታል፡ %s',
      'push_notifications': 'የስልክ ማሳወቂያዎች',
      'managed_by_phone': 'በስልክዎ ቅንብሮች የሚተዳደር',
      'open_system_settings': 'የስርዓት ቅንብሮችን ክፈት',
      'reset_link_sent': 'የይለፍ ቃል ዳግም ማስጀመሪያ ሊንክ ወደ ኢሜልዎ ይላካል',
      'policy_coming_soon': 'የግላዊነት ፖሊሲ ገጽ በቅርቡ ይቀርባል',
      'loading': 'በመጫን ላይ...',
      // Birth Plan
      'birth_material_list': 'የወሊድ ዕቃዎች ዝርዝር',
      'hospital_bag_checklist': 'የሆስፒታል ቦርሳ ዝርዝር',
      'hospital_bag_desc': 'የሆስፒታል ቦርሳዎን ከመውለጃዎ ቀን ጥቂት ሳምንታት በፊት ያዘጋጁ።',
      'item_mother_id': 'የእናት መታወቂያ እና የህክምና ካርድ',
      'item_printed_plan': 'የወሊድ እቅድ የታተመ ቅጂ',
      'item_comfortable_clothing': 'ምቹ ልብሶች / ጋዋን',
      'item_slippers_socks': 'የቤት ጫማ እና ካልሲዎች',
      'item_maternity_pads': 'የወሊድ ፓድ እና የውስጥ ሱሪዎች',
      'item_toiletries': 'የግል ንፅህና መጠበቂያዎች (የጥርስ ብሩሽ፣ ዲዮድራንት)',
      'item_baby_clothes': 'የጨቅላ ህፃን ልብሶች',
      'item_diapers_wipes': 'የህፃናት ዳይፐር እና እርጥብ ሶፍት',
      'item_baby_blanket': 'የህፃን ብርድ ልብስ',
      'item_car_seat': 'የመኪና ህፃናት መቀመጫ ተዘጋጅቷል',
      // Quick Actions & Chatbot
      'quick_actions': 'ፈጣን እርምጃዎች',
      'connect_doctor': 'ከሐኪም ጋር ይገናኙ',
      'connect_doctor_desc': 'ቀጠሮ ይያዙ እና ሐኪሞችን ያግኙ',
      'ai_assistant': 'የ AI ረዳት',
      'ai_assistant_desc': 'ከእናት AI ቦት ጋር ይወያዩ',
      'type_message': 'መልዕክት ይፃፉ...',
      'thinking': 'በማሰብ ላይ...',
      'always_active': 'ሁልጊዜ ንቁ',
      'currently_offline': 'በአሁኑ ጊዜ ከመስመር ውጭ ነው',
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
      // Navigation
      'nav_home': 'Mana',
      'nav_community': 'Hawaasa',
      'nav_wellness': 'Fayyaa',
      'nav_profile': 'Piroofaayilii',
      // Home & Greeting
      'baby_growing': '%s, daa\'imni keessan bifa bareedaan guddachaa jira!',
      'ask_assistant': 'Gargaaraa Keenya Gaafadhaa',
      'ask_assistant_subtitle': 'Deebii saffisaa fi nageenya qabu argadhaa',
      'wellness_guides': 'Qajeelfama Fayyaa',
      'relaxation_music': 'Muuziqaa Boqonnaa',
      'stay_active': 'Sochii Qabaadhaa',
      'better_sleep': 'Hirriba Gaarii',
      'see_all': 'Hunda Ilaali',
      // Am I Pregnant Card
      'your_pregnancy_this_week': 'Ulfa Keessan\nTorban Kana',
      'size_comparison_text': 'Guddina %s',
      'heart_rate_text': 'Rukuttaa Onnee: %d bpm',
      'days_remaining_text': 'Guyyoota %d hafan',
      'view_details': 'Bal\'ina Ilaali',
      // Profile Page
      'account_settings': 'Qindaa\'ina Eenyummaa',
      'personal_info': 'Odeeffannoo Dhuunfaa',
      'pregnancy_details': 'Bal\'ina Ulfaa (LMP)',
      'app_settings': 'Qindaa\'ina Applikeeshinii',
      'notifications': 'Beeksisa',
      'privacy_security': 'Iccitii fi Nageenya',
      'change_photo': 'Suuraa Piroofaayilii Jijjiiri',
      'choose_photo_source': 'Bakka suuraa itti filattan filadhaa:',
      'take_photo': 'Suuraa Kaasi',
      'capture_camera': 'Kaameeraadhaan kaasaa',
      'choose_gallery': 'Gaalerii Keessaa Filadhu',
      'select_gallery': 'Suuraa gaalerii keessaa filadhaa',
      'remove_photo': 'Suuraa Haqi',
      'remove_photo_confirm': 'Dhuguma suuraa piroofaayilii keessanii haquu barbaadduu?',
      'remove_photo_success': 'Suuraan piroofaayilii milkaa\'inaan haqameera.',
      'photo_uploaded': 'Suuraan Olkaa\'ameera!',
      'photo_uploaded_msg': 'Suuraan piroofaayilii keessan milkaa\'inaan haaromfameera.',
      'upload_failed': 'Suuraa olkaa\'uun hin danda\'amne',
      'edit_name': 'Maqaa Jijjiiri',
      'full_name': 'Maqaa Guutuu',
      'save': 'Olkaayi',
      'cancel': 'Dhiisi',
      'log_out': 'Bahi',
      'change_password': 'Jechama Darbiinsa Jijjiiri',
      'privacy_policy': 'Imaammata Iccitii',
      'weeks_pregnant': 'Torban %d Ulfa',
      'pregnancy_details_not_set': 'Hin murtoofne (LMP filachuuf tuqi)',
      'pregnancy_details_updated': 'Odeeffannoon ulfaa milkaa\'inaan haaromfameera.',
      'stat_phone': 'Bilbila',
      'stat_due_date': 'Guyyaa Dhaluuf Karoorfame',
      'assigned_hospital': 'Hospitaala Ramadame: %s',
      'push_notifications': 'Beeksisa Bilbilaa',
      'managed_by_phone': 'Qindaa\'ina bilbilaan to\'atama',
      'open_system_settings': 'Qindaa\'ina bilbilaa bani',
      'reset_link_sent': 'Geessituun jechama darbiinsa gara imeelii keessaniitti ni ergama',
      'policy_coming_soon': 'Fuulli imaammata iccitii dhiyeenyatti ni dhufa',
      'loading': 'Fe\'aa jira...',
      // Birth Plan
      'birth_material_list': 'Tarree Meeshaalee Dhaluuf',
      'hospital_bag_checklist': 'Tarree Qodaa Hospitaalaa',
      'hospital_bag_desc': 'Boorsaa hospitaalaa guyyaa dhalootaa torban muraasa dura qopheessaa.',
      'item_mother_id': 'Waraqaa Eenyummaa fi Galmee Yaalaa Haadhaa',
      'item_printed_plan': 'Koppii Karoora Dhaluu Maxxanfame',
      'item_comfortable_clothing': 'Uffata Mijataa / Gaawunii',
      'item_slippers_socks': 'Kophee Manaa fi Kaalsii',
      'item_maternity_pads': 'Paadii Dhalmaa fi Uffata Keessaa',
      'item_toiletries': 'Meeshaalee Qulqullinaa (Rigata Ilkaanii, Shittoo)',
      'item_baby_clothes': 'Uffata Daa\'ima Haaraa Dhalate',
      'item_diapers_wipes': 'Daayipparii fi Wipes Daa\'imaa',
      'item_baby_blanket': 'Uffata Qorraa Daa\'imaa',
      'item_car_seat': 'Koomfii Konkolaataa Daa\'imaaf Dhaabame',
      // Quick Actions & Chatbot
      'quick_actions': 'Tarkaanfiiwwan Saffisaa',
      'connect_doctor': 'Ogeessa Yaalaa Qunnamaa',
      'connect_doctor_desc': 'Beellama qabadhaa & doktoorota barbaadaa',
      'ai_assistant': 'Gargaaraa AI',
      'ai_assistant_desc': 'Enat AI waliin haasa\'aa',
      'type_message': 'Ergaa barreessi...',
      'thinking': 'Yaadaa jira...',
      'always_active': 'Yeroo hunda banaa',
      'currently_offline': 'Amma toora irra hin jiru',
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
      // Navigation
      'nav_home': 'Hoyga',
      'nav_community': 'Bulshada',
      'nav_wellness': 'Caafimaadka',
      'nav_profile': 'Muuqaalka',
      // Home & Greeting
      'baby_growing': '%s, ilmahaagu si qurux badan buu u korayaa!',
      'ask_assistant': 'Weydii Kaaliyahaaga',
      'ask_assistant_subtitle': 'Hel jawaabo degdeg ah oo aamin ah',
      'wellness_guides': 'Hagaha Caafimaadka',
      'relaxation_music': 'Muusiga Nasashada',
      'stay_active': 'Firfircoonaaw',
      'better_sleep': 'Hurdo Wanaagsan',
      'see_all': 'Arag Dhammaan',
      // Am I Pregnant Card
      'your_pregnancy_this_week': 'Uurkaaga\nToddobaadkan',
      'size_comparison_text': 'Cabbirka %s',
      'heart_rate_text': 'Garaaca Wadnaha: %d bpm',
      'days_remaining_text': '%d maalmood baa hadhay',
      'view_details': 'Faahfaahinta Eeg',
      // Profile Page
      'account_settings': 'Dejinta Koontada',
      'personal_info': 'Macluumaadka Shaqsiyeed',
      'pregnancy_details': 'Faahfaahinta Uurka (LMP)',
      'app_settings': 'Dejinta Abka',
      'notifications': 'Ogeysiisyada',
      'privacy_security': 'Asturnaanta & Amniga',
      'change_photo': 'Beddel Sawirka Muuqaalka',
      'choose_photo_source': 'Ka dooro halka aad ka keenayso sawirkaaga:',
      'take_photo': 'Sawir Qaad',
      'capture_camera': 'Ku sawir kaameerada aaladda',
      'choose_gallery': 'Ka Dooro Sawirrada (Gallery)',
      'select_gallery': 'Ka dooro sawir jira taleefankaaga',
      'remove_photo': 'Tirtir Sawirka',
      'remove_photo_confirm': 'Ma hubtaa inaad rabto inaad tirtirto sawirkaaga muuqaalka?',
      'remove_photo_success': 'Sawirka muuqaalka si guul leh ayaa loo tirtiray.',
      'photo_uploaded': 'Sawirka Waa La Galiyay!',
      'photo_uploaded_msg': 'Sawirkaaga muuqaalka si guul leh ayaa loo cusbooneysiiyay.',
      'upload_failed': 'Ku-shubiddu way fashilantay',
      'edit_name': 'Wax ka beddel Magaca',
      'full_name': 'Magaca oo Buuxa',
      'save': 'Kaydi',
      'cancel': 'Ka noqo',
      'log_out': 'Ka bax',
      'change_password': 'Beddel Furaha Sirta',
      'privacy_policy': 'Xeerka Asturnaanta',
      'weeks_pregnant': '%d Toddobaad Uur leh',
      'pregnancy_details_not_set': 'Lama dejin (Taabo si aad u doorato LMP)',
      'pregnancy_details_updated': 'Faahfaahinta uurka si guul leh ayaa loo cusboonaysiiyay.',
      'stat_phone': 'Taleefan',
      'stat_due_date': 'Taariikhda Dhalmada',
      'assigned_hospital': 'Isbitaalka laguu qoondeeyay: %s',
      'push_notifications': 'Ogeysiisyada Taleefanka',
      'managed_by_phone': 'Waxaa maamula dejinta taleefankaaga',
      'open_system_settings': 'Fur dejinta taleefanka',
      'reset_link_sent': 'Xiriirka dib-u-dejinta furaha sirta waxaa loo diri doonaa iimaylkaaga',
      'policy_coming_soon': 'Bogga xeerka asturnaanta dhawaan baa la soo kordhin doonaa',
      'loading': 'Waa la soo gelinayaa...',
      // Birth Plan
      'birth_material_list': 'Liiska Qalabka Dhalmada',
      'hospital_bag_checklist': 'Liiska Shandadaha Isbitaalka',
      'hospital_bag_desc': 'Diyaari boorsadaada isbitaalka dhowr toddobaad ka hor taariikhda dhalmada.',
      'item_mother_id': 'Aqoonsiga Hooyada iyo Diiwaanka Caafimaadka',
      'item_printed_plan': 'Nuqullada daabacan ee Qorshaha Dhalmada',
      'item_comfortable_clothing': 'Dhar Raaxo leh / Go\'aanka jiifka',
      'item_slippers_socks': 'Dacas iyo sharabaadyo',
      'item_maternity_pads': 'Kootooyinka dhalmada & Dharka hoose',
      'item_toiletries': 'Qalabka nadaafadda (Burush caday, Udgoon)',
      'item_baby_clothes': 'Dharka Ilmaha (Cabbirka dhashay)',
      'item_diapers_wipes': 'Xafaayadaha Ilmaha & Masaxyada',
      'item_baby_blanket': 'Buste yar oo ilmaha ah',
      'item_car_seat': 'Kursiga baabuurka ee ilmaha oo la rakibay',
      // Quick Actions & Chatbot
      'quick_actions': 'Hawlo Degdeg ah',
      'connect_doctor': 'La xiriir Dhakhtar',
      'connect_doctor_desc': 'Ballamo qabso oo raadso dhakhaatiir',
      'ai_assistant': 'Kaaliyaha AI',
      'ai_assistant_desc': 'La sheekeyso Bot-ka Enat AI',
      'type_message': 'Qor farriin...',
      'thinking': 'Wuu fikirayaa...',
      'always_active': 'Had iyo jeer furan',
      'currently_offline': 'Hadda khadka kama baxsana',
    },
  };

  static String of(BuildContext context, String key, [List<dynamic>? args]) {
    final locale = Localizations.localeOf(context).languageCode;
    String text = localizedValues[locale]?[key] ?? localizedValues['en']?[key] ?? key;
    if (args != null && args.isNotEmpty) {
      for (final arg in args) {
        if (text.contains('%s')) {
          text = text.replaceFirst('%s', arg.toString());
        } else if (text.contains('%d')) {
          text = text.replaceFirst('%d', arg.toString());
        }
      }
    }
    return text;
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
