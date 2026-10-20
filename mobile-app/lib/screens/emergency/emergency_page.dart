import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class _EmergencyLocalization {
  static const Map<String, Map<String, String>> strings = {
    'en': {
      'title': 'Emergency & Health',
      'subtitle': 'Immediate help and vital precautions',
      'urgent_prompt': 'Feeling severe pain or unusual signs?',
      'emergency_call': 'Emergency Call',
      'gps_share': 'Share Location',
      'contacts_title': 'My Emergency Contacts',
      'no_contacts': 'No emergency contacts yet. Tap + to add one.',
      'add_contact_title': 'Add Emergency Contact',
      'contact_name_label': 'Contact name',
      'phone_label': 'Phone',
      'relationship_label': 'Relationship (optional)',
      'cancel': 'Cancel',
      'add': 'Add',
      'name_phone_required': 'Name and phone are required',
      'contact_added': 'Emergency contact added',
      'call_failed': 'Could not start the phone call.',
      'location_disabled': 'Location services are turned off. Please enable them.',
      'location_denied': 'Location permission was denied.',
      'location_shared': 'Location shared with your emergency contacts.',
      'location_shared_count': 'Location shared with %d emergency contact(s) and your doctor.',
      'location_failed': 'Could not share your location. Please try again.',
      'network_error': 'Network error. Please try again.',
      'retry': 'Retry',
      'warning_title': 'Warning Signs (Seek Medical Help)',
      'vital_tips_title': 'Vital Health Tips',
      'important_note': 'Important Precaution',
    },
    'am': {
      'title': 'ድንገተኛ እና ጤና',
      'subtitle': 'አፋጣኝ እርዳታ እና አስፈላጊ የጤና ጥንቃቄዎች',
      'urgent_prompt': 'ከፍተኛ ህመም ወይም ያልተለመዱ ምልክቶች ይሰማዎታል?',
      'emergency_call': 'የአደጋ ጊዜ ጥሪ',
      'gps_share': 'አካባቢን ያጋሩ',
      'contacts_title': 'የድንገተኛ አደጋ እውቂያዎቼ',
      'no_contacts': 'ምንም እውቂያዎች የሉም። አዲስ ለመጨመር + ይንኩ።',
      'add_contact_title': 'የድንገተኛ አደጋ እውቂያ ያክሉ',
      'contact_name_label': 'የእውቂያ ስም',
      'phone_label': 'ስልክ ቁጥር',
      'relationship_label': 'ዝምድና (አማራጭ)',
      'cancel': 'ይቅር',
      'add': 'አክል',
      'name_phone_required': 'ስም እና ስልክ ቁጥር ማስገባት ግዴታ ነው',
      'contact_added': 'የአደጋ ጊዜ እውቂያ በተሳካ ሁኔታ ታክሏል',
      'call_failed': 'ጥሪውን መጀመር አልተቻለም።',
      'location_disabled': 'የአካባቢ መገኛ አገልግሎት ጠፍቷል። እባክዎ ያብሩት።',
      'location_denied': 'የአካባቢ መገኛ ፈቃድ አልተሰጠም።',
      'location_shared': 'የእርስዎ መገኛ ለአደጋ ጊዜ እውቂያዎችዎ ተልኳል።',
      'location_shared_count': 'የእርስዎ መገኛ ለ %d የአደጋ ጊዜ እውቂያዎች እና ለሐኪምዎ ተልኳል።',
      'location_failed': 'አካባቢዎን ማጋራት አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
      'network_error': 'የኔትወርክ ስህተት። እባክዎ እንደገና ይሞክሩ።',
      'retry': 'እንደገና ሞክር',
      'warning_title': 'የማስጠንቀቂያ ምልክቶች (የህክምና እርዳታ ይፈልጉ)',
      'vital_tips_title': 'ጠቃሚ የጤና ምክሮች',
      'important_note': 'አስፈላጊ ጥንቃቄ',
    },
    'om': {
      'title': 'Hospitaala & Fayyaa',
      'subtitle': 'Gargaarsa hatattamaa fi of-eeggannoo barbaachisoo',
      'urgent_prompt': 'Dhukkubbiin hamaa ykn mallattoon hin baramne sitti dhagahamaa?',
      'emergency_call': 'Waamicha Hatattamaa',
      'gps_share': 'Bakka Jirtan Eeraa',
      'contacts_title': 'Lakkoofsota Yeroo Balaa Koo',
      'no_contacts': 'Lakkoofsi yeroo balaa hin jiru. Dabaluuf + tuqi.',
      'add_contact_title': 'Lakkoofsa Yeroo Balaa Dabalaa',
      'contact_name_label': 'Maqaa Namichaa',
      'phone_label': 'Bilbila',
      'relationship_label': 'Firummaa (filannoo)',
      'cancel': 'Dhiisi',
      'add': 'Dabali',
      'name_phone_required': 'Maqaa fi bilbilli barbaachisaadha',
      'contact_added': 'Lakkoofsi yeroo balaa milkaa’inaan dabalameera',
      'call_failed': 'Bilbila eegaluun hin danda’amne.',
      'location_disabled': 'Tajaajilli bakka jirtanii cufameera. Mee banaa.',
      'location_denied': 'Hayyamni bakka jirtanii dhowwameera.',
      'location_shared': 'Bakkai jirtan nama yeroo balaaf qophaa’etti ergameera.',
      'location_shared_count': 'Bakki jirtan nama %d fi ogeessa yaalaaf ergameera.',
      'location_failed': 'Bakka jirtan erguun hin danda’amne. Ammas yaalaa.',
      'network_error': 'Dogoggora neetwoorkii. Mee irra deebi’aa yaalaa.',
      'retry': 'Irra deebi’i',
      'warning_title': 'Mallattoolee Akeekkachiisaa (Gargaarsa yaalaa barbaadaa)',
      'vital_tips_title': 'Gorsa Fayyaa Murteessoo',
      'important_note': 'Of-eeggannoo Murteessaa',
    },
    'so': {
      'title': 'Xaaladaha Degdegga ah & Caafimaadka',
      'subtitle': 'Caawimaad degdeg ah iyo taxaddarro muhiim ah',
      'urgent_prompt': 'Ma dareemaysaa xanuun daran ama calaamado aan caadi ahayn?',
      'emergency_call': 'Wicitaan Degdeg ah',
      'gps_share': 'Wadaag Goobtaada',
      'contacts_title': 'Xiriirada Degdegga ah Ee Aniga',
      'no_contacts': 'Ma jiraan xiriiryo degdeg ah. Riix + si aad ugu darto.',
      'add_contact_title': 'Kudar Xiriir Degdeg ah',
      'contact_name_label': 'Magaca Xiriirka',
      'phone_label': 'Taleefanka',
      'relationship_label': 'Qaraabada (ikhtiyaari)',
      'cancel': 'Kansal garee',
      'add': 'Kudar',
      'name_phone_required': 'Magaca iyo taleefanka waa lagama maarmaan',
      'contact_added': 'Xiriirka degdegga ah si guul leh ayaa loogu daray',
      'call_failed': 'Lama bilaabi karin wicitaanka taleefanka.',
      'location_disabled': 'Adeegga goobta waa dansan yahay. Fadlan shid.',
      'location_denied': 'Oggolaanshaha goobta waa la diiday.',
      'location_shared': 'Goobtaada waxaa lala wadaagay xiriiradaada degdegga ah.',
      'location_shared_count': 'Goobtaada waxaa lala wadaagay %d xiriirka degdegga ah iyo dhakhtarkaaga.',
      'location_failed': 'Lama wadaagi karin goobtaada. Fadlan isku day mar kale.',
      'network_error': 'Khalad shabakadeed. Fadlan isku day mar kale.',
      'retry': 'Isku day mar kale',
      'warning_title': 'Calaamadaha Digniinta (Raadso Caawimaad Caafimaad)',
      'vital_tips_title': 'Talooyinka Caafimaadka Ee Muhiimka ah',
      'important_note': 'Taxadar Muhiim ah',
    },
  };

  static String t(String lang, String key) {
    return strings[lang]?[key] ?? strings['en']?[key] ?? key;
  }
}

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  String _currentLang(BuildContext context) {
    try {
      final code = Provider.of<LocaleProvider>(context, listen: false).locale?.languageCode ??
          Localizations.localeOf(context).languageCode;
      if (['en', 'am', 'om', 'so'].contains(code)) return code;
    } catch (_) {}
    return 'en';
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final contacts = await MotherService.getEmergencyContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts.map((c) => c as Map<String, dynamic>).toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      final lang = _currentLang(context);
      setState(() => _error = _EmergencyLocalization.t(lang, 'network_error'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    final lang = _currentLang(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _EmergencyLocalization.t(lang, 'add_contact_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: _EmergencyLocalization.t(lang, 'contact_name_label'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _EmergencyLocalization.t(lang, 'phone_label'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationshipController,
                decoration: InputDecoration(
                  labelText: _EmergencyLocalization.t(lang, 'relationship_label'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_EmergencyLocalization.t(lang, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_EmergencyLocalization.t(lang, 'add')),
          ),
        ],
      ),
    );

    if (result != true) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_EmergencyLocalization.t(lang, 'name_phone_required'))),
      );
      return;
    }

    try {
      await MotherService.createEmergencyContact(
        contactName: name,
        phone: phone,
        relationship: relationshipController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_EmergencyLocalization.t(lang, 'contact_added'))),
      );
      await _loadContacts();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_EmergencyLocalization.t(lang, 'network_error'))),
      );
    }
  }

  Future<void> _emergencyCall() async {
    final lang = _currentLang(context);
    try {
      await launchUrl(Uri.parse('tel:911'), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_EmergencyLocalization.t(lang, 'call_failed'))),
      );
    }
  }

  Future<Position?> _ensureGpsPosition(String lang) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_EmergencyLocalization.t(lang, 'location_disabled'))),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_EmergencyLocalization.t(lang, 'location_denied'))),
      );
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _shareLocationToContact({
    required String name,
    required String phone,
  }) async {
    final lang = _currentLang(context);
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Acquiring real-time GPS coordinates...'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final position = await _ensureGpsPosition(lang);
      if (position == null) return;

      final mapsUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      final emergencyMsg = '🚨 EMERGENCY ALERT: I need immediate assistance! Here is my current GPS location:\n$mapsUrl';

      // Open SMS directly addressed to this specific contact
      final smsUri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(emergencyMsg)}');
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);

      // Also register alert with server
      try {
        await MotherService.sendEmergencyAlert(position.latitude, position.longitude);
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
          content: Text('Sharing GPS location with $name ($phone).'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_EmergencyLocalization.t(lang, 'location_failed'))),
      );
    }
  }

  Future<void> _shareLocation() async {
    // If mother has contacts, present a quick picker to share to a specific person or all
    if (_contacts.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Share GPS Location',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a contact to send your live location SMS immediately:',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _contacts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final c = _contacts[idx];
                        final cName = c['contact_name'] as String? ?? 'Contact';
                        final cPhone = c['phone'] as String? ?? '';
                        final cRel = c['relationship'] as String?;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            child: const Icon(Icons.person_rounded, color: Colors.red),
                          ),
                          title: Text(cName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            cRel != null && cRel.isNotEmpty ? '$cPhone ($cRel)' : cPhone,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Send SMS', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _shareLocationToContact(name: cName, phone: cPhone);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.emergency_share_rounded),
                    label: const Text('Broadcast Alert to All Contacts & Doctor'),
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      _broadcastEmergencyAlert();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    // Fallback if no contacts added yet
    _broadcastEmergencyAlert();
  }

  Future<void> _broadcastEmergencyAlert() async {
    final lang = _currentLang(context);
    try {
      final position = await _ensureGpsPosition(lang);
      if (position == null) return;

      final result = await MotherService.sendEmergencyAlert(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      final notified = result['contactsNotified'];
      final msg = notified == null
          ? _EmergencyLocalization.t(lang, 'location_shared')
          : _EmergencyLocalization.t(lang, 'location_shared_count')
              .replaceAll('%d', notified.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFF0D9488)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_EmergencyLocalization.t(lang, 'location_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consumer will trigger dynamic rebuild whenever LocaleProvider changes
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final code = localeProvider.locale?.languageCode ??
            Localizations.localeOf(context).languageCode;
        final lang = ['en', 'am', 'om', 'so'].contains(code) ? code : 'en';

        final warningSigns = _getWarningSigns(lang);
        final vitalTips = _getVitalHealthTips(lang);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _EmergencyLocalization.t(lang, 'title'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _EmergencyLocalization.t(lang, 'subtitle'),
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // ── Urgent Action Banner ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.red[100]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _EmergencyLocalization.t(lang, 'urgent_prompt'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _emergencyCall,
                        icon: const Icon(Icons.phone_rounded),
                        label: Text(
                          _EmergencyLocalization.t(lang, 'emergency_call'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _shareLocation,
                        icon: const Icon(Icons.location_on_rounded),
                        label: Text(
                          _EmergencyLocalization.t(lang, 'gps_share'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ── My Emergency Contacts ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _EmergencyLocalization.t(lang, 'contacts_title'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _addContact,
                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
                      tooltip: _EmergencyLocalization.t(lang, 'add_contact_title'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                else if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _loadContacts,
                          child: Text(_EmergencyLocalization.t(lang, 'retry')),
                        ),
                      ],
                    ),
                  )
                else if (_contacts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _EmergencyLocalization.t(lang, 'no_contacts'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Column(
                    children: _contacts
                        .map((c) => _buildContactCard(
                              name: c['contact_name'] as String? ?? 'Unknown',
                              phone: c['phone'] as String? ?? '',
                              relationship: c['relationship'] as String?,
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 30),

                // ── Warning Signs ─────────────────────────────────────────
                Text(
                  _EmergencyLocalization.t(lang, 'warning_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                ...warningSigns.map((w) => _buildWarningItem(w)),

                const SizedBox(height: 30),

                // ── Vital Health Tips (Interactive Dropdowns) ────────────
                Text(
                  _EmergencyLocalization.t(lang, 'vital_tips_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                ...vitalTips.map((tip) => _VitalTipDropdownCard(
                      icon: tip.icon,
                      title: tip.title,
                      subtitle: tip.subtitle,
                      actionSteps: tip.actionSteps,
                      note: tip.note,
                      noteHeader: _EmergencyLocalization.t(lang, 'important_note'),
                      bgColor: tip.bgColor,
                      iconColor: tip.iconColor,
                      initiallyExpanded: tip.initiallyExpanded,
                    )),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactCard({
    required String name,
    required String phone,
    String? relationship,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(phone, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                if (relationship != null && relationship.isNotEmpty)
                  Text(relationship, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Share GPS location with $name',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_location_rounded, color: Colors.red, size: 20),
                ),
                onPressed: () {
                  if (phone.isNotEmpty) {
                    _shareLocationToContact(name: name, phone: phone);
                  }
                },
              ),
              IconButton(
                tooltip: 'Call $name',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 20),
                ),
                onPressed: () {
                  if (phone.isNotEmpty) {
                    launchUrl(Uri.parse('tel:$phone'), mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.report_problem_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[900], height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ── Warning Signs Localized List ──────────────────────────────────────────
  List<String> _getWarningSigns(String lang) {
    switch (lang) {
      case 'am':
        return [
          "የማይለቅ ከባድ ራስ ምታት",
          "የእይታ መደብዘዝ ወይም ብልጭታ ማየት",
          "የፊት፣ የእጅ ወይም የእግር ድንገተኛ ማበጥ",
          "የደም መፍሰስ ወይም ፈሳሽ መፍሰስ",
          "ቀጣይነት ያለው ከባድ የሆድ ህመም",
          "የፅንሱ እንቅስቃሴ በከፍተኛ ሁኔታ መቀነስ ወይም መቆም",
        ];
      case 'om':
        return [
          "Mata-dhukkubbiin cimaa dhiisuu dide",
          "Iji dhabamuu ykn ifti calaqqisuu",
          "Fuulli, harki ykn miilli tasa dhiita'uu",
          "Dhiigni ykn dhangala'aan qaama saalaatiin dhangala'uu",
          "Dhukkubbii garaa cimaa walirraa hin cinne",
          "Sochiin daa'imaa garmalee xiqqaachuu ykn dhaabbachuu",
        ];
      case 'so':
        return [
          "Madax-xanuun daran oo aan joogsanayn",
          "Aragga oo caadaqaata ama dhalaal",
          "Barar degdeg ah ee wejiga, gacmaha ama cagaha",
          "Dhiig bax ama biyo bixid",
          "Xanuun daran oo joogto ah ee caloosha",
          "Dhaqdhaqaaqa ilmaha oo yaraada ama joogsada",
        ];
      case 'en':
      default:
        return [
          "Severe headache that won't go away",
          "Changes in your vision (blurring, flashes)",
          "Sudden swelling of face, hands or feet",
          "Vaginal bleeding or leaking fluid",
          "Persistent severe abdominal pain",
          "Baby moving less than usual or not moving",
        ];
    }
  }

  // ── Vital Health Tips Localized Data ──────────────────────────────────────
  List<_VitalTipData> _getVitalHealthTips(String lang) {
    switch (lang) {
      case 'am':
        return [
          _VitalTipData(
            icon: Icons.healing_rounded,
            title: "የመሳት እና የማዞር የመጀመሪያ እርዳታ",
            subtitle: "ማዞር ወይም የድካም ስሜት ሲሰማ የሚደረጉ እርምጃዎች",
            actionSteps: [
              "ለፅንሱና ለአእምሮ የደም ዝውውር እንዲጨምር ወዲያውኑ በግራ ጎንዎ ጋደም ይበሉ።",
              "የጠበቀ ልብስ ካለ ያላሉ ወይም ያውልቁ።",
              "ቀዝቃዛ ንጹህ ውሃ ወይም የተፈጥሮ ፍራፍሬ ጭማቂ ይጠጡ።",
              "ቀስ ብለው ይተንፍሱ እና በድንገት ከመቀመጫዎ በፍጥነት አይነሱ።",
            ],
            note: "የማዞር ስሜቱ ከቀጠለ ወይም የማስታወክ ስሜት ካለ በአቅራቢያዎ ወደሚገኝ ጤና ጣቢያ ይሂዱ።",
            bgColor: Colors.blue[50]!,
            iconColor: Colors.blue[700]!,
            initiallyExpanded: true,
          ),
          _VitalTipData(
            icon: Icons.warning_amber_rounded,
            title: "የመውደቅ ወይም የሆድ አደጋ እርዳታ",
            subtitle: "ድንገት ሲወድቁ ወይም ሆድዎ ሲገጭ የሚደረግ ጥንቃቄ",
            actionSteps: [
              "እንቅስቃሴዎን ወዲያውኑ አቁመው እረፍት ይውሰዱ።",
              "ምንም ህመም ባይሰማዎትም እንኳን የፅንሱን የልብ ምት ለማረጋገጥ ወዲያውኑ ሐኪምዎን ያማክሩ።",
              "ማህፀን አካባቢ ህመም፣ የሆድ ቁርጠት ወይም ፈሳሽ ካለ ወዲያውኑ ወደ ድንገተኛ ክፍል ይሂዱ።",
            ],
            note: "አደጋው ቀላል ቢመስልም የእንግዴ ልጅ መፈናቀል እንዳይከሰት የባለሙያ ምርመራ ወሳኝ ነው።",
            bgColor: Colors.amber[50]!,
            iconColor: Colors.amber[800]!,
          ),
          _VitalTipData(
            icon: Icons.water_drop_rounded,
            title: "የደም እና የፈሳሽ መፍሰስ ጥንቃቄ",
            subtitle: "ደም ወይም የውሃ መፍሰስ ሲያጋጥም የሚወሰዱ አፋጣኝ እርምጃዎች",
            actionSteps: [
              "ወዲያውኑ አልጋ ላይ ተኝተው እረፍት ያድርጉ፤ ታምፖን በፍጹም አይጠቀሙ።",
              "የፈሳሹን መጠን እና ቀለም ለመከታተል ንጹህ ፓድ ይጠቀሙ።",
              "ወዲያውኑ ወደ ህክምና ተቋም ይሂዱ፤ የውሃ መፍሰስ አስቸኳይ ክትትል ይፈልጋል።",
            ],
            note: "የእንግዴ ልጅ ፈሳሽ መፍሰስ ለኢንፌክሽን ተጋላጭ ስለሚያደርግ ጊዜ ሳይወስዱ ሆስፒታል ይድረሱ።",
            bgColor: Colors.red[50]!,
            iconColor: Colors.red[700]!,
          ),
          _VitalTipData(
            icon: Icons.speed_rounded,
            title: "ከፍተኛ የደም ግፊት (ፕሪኤክላምፕሲያ) ምልክቶች",
            subtitle: "ከፍተኛ የደም ግፊት አደገኛ ምልክቶች እና ጥንቃቄዎች",
            actionSteps: [
              "የፊት እና የእጆች ድንገተኛ ማበጥን በየቀኑ ይከታተሉ።",
              "የማይለቅ ከባድ ራስ ምታት እና የእይታ መደብዘዝ ሲያጋጥም ወዲያውኑ ይመርመሩ።",
              "ከቀኝ የጎድን አጥንት በታች የሚሰማ ህመም የአደጋ ምልክት ነው።",
            ],
            note: "እነዚህ ምልክቶች ሲከሰቱ መደበኛ ቀጠሮ ሳይጠብቁ ወዲያውኑ የድንገተኛ ህክምና ያግኙ።",
            bgColor: Colors.purple[50]!,
            iconColor: Colors.purple[700]!,
          ),
          _VitalTipData(
            icon: Icons.medical_services_rounded,
            title: "የቅድመ ወሊድ ክትትል እና ድንገተኛ ቦርሳ",
            subtitle: "ከወሊድ በፊት አስቀድመው መዘጋጀት ያለባቸው ወሳኝ ነገሮች",
            actionSteps: [
              "መደበኛ የቅድመ ወሊድ ምርመራዎችን በፍጹም አያቋርጡ፤ የደም ግፊት ምርመራ ህይወት ያድናል።",
              "የክሊኒክ ካርድ፣ መታወቂያ፣ የህፃን ልብሶች እና የትራንስፖርት ገንዘብ ሁልጊዜ ዝግጁ ያድርጉ።",
              "የአደጋ ጊዜ እውቂያ ስልኮችን በስልክዎ በቀላሉ በሚገኝ ቦታ ያስቀምጡ።",
            ],
            note: "ወደ መውለጃው ሆስፒታል የሚወስደውን ፈጣን መንገድ አስቀድመው ያቅዱ።",
            bgColor: Colors.teal[50]!,
            iconColor: Colors.teal[700]!,
          ),
        ];

      case 'om':
        return [
          _VitalTipData(
            icon: Icons.healing_rounded,
            title: "Gargaarsa Jalqabaa Gagaabuu fi Dhimmisaa",
            subtitle: "Yeroo dhiphinni fi laafinni sitti dhagahamu tarkaanfii fudhatamu",
            actionSteps: [
              "Dhiigni gara sammuu fi daa'imaatti akka yaa'uuf battalumatti cinaacha bitaatiin ciisaa.",
              "Uffata dhiphaa ta'e hiikaa ykn bal'isaa.",
              "Bishaan qabbanaawaa ykn cuunfaa fuduraa dhugaa.",
              "Suuta qilleensa baafadhaa, tasa ol hin ka'inaa.",
            ],
            note: "Dhimmisni yoo itti fufe battalumatti gara buufata fayyaa deemaa.",
            bgColor: Colors.blue[50]!,
            iconColor: Colors.blue[700]!,
            initiallyExpanded: true,
          ),
          _VitalTipData(
            icon: Icons.warning_amber_rounded,
            title: "Kufuu fi Balaa Garaa",
            subtitle: "Balaa kufuu ykn garaatti rukutamuun booda tarkaanfii barbaachisu",
            actionSteps: [
              "Hojii kamuu battalatti dhaabaatii boqodhaa.",
              "Fayyaa taatus rukuttaa onnee daa'imaa mirkaneeffachuuf doktoora keessan qunnamaa.",
              "Dhukkubbii garaa ykn dhangala'aan yoo jiraate battalatti gara mana yaalaa deemaa.",
            ],
            note: "Miidhaan xiqqaatus qorannoon ogeessaa baay'ee murteessaadha.",
            bgColor: Colors.amber[50]!,
            iconColor: Colors.amber[800]!,
          ),
          _VitalTipData(
            icon: Icons.water_drop_rounded,
            title: "Dhiiga fi Dhangala'aa Dhangala'u",
            subtitle: "Of-eeggannoo dhangala'aa fi dhiigaa yeroo ulfaa",
            actionSteps: [
              "Battalatti ciisaa boqodhaa, wanta tokkoyyuu qaama saalaa keessa hin galchinaa.",
              "Halluu fi hamma dhangala'aa hordofuuf uffata qulqulluu fayyadamaa.",
              "Battalatti gargaarsa hatattamaa barbaadaa.",
            ],
            note: "Dhangala'aan yoo dhangala'e battalatti mana yaalaa gahaa.",
            bgColor: Colors.red[50]!,
            iconColor: Colors.red[700]!,
          ),
          _VitalTipData(
            icon: Icons.speed_rounded,
            title: "Mallattoolee Dhiibbaa Dhiigaa Cimaa",
            subtitle: "Mallattoolee dhiibbaa dhiigaa ulfaa (Preeclampsia)",
            actionSteps: [
              "Fuulli fi harki dhiita'uu guyyaa guyyaan hordofaa.",
              "Mata-dhukkubbii cimaa fi iji dhabamuu yoo jiraate battalatti qoradhaa.",
              "Cinaacha mirgaa jala dhukkubuun mallattoo balaati.",
            ],
            note: "Beellama osoo hin eegin battalatti gara mana yaalaa deemaa.",
            bgColor: Colors.purple[50]!,
            iconColor: Colors.purple[700]!,
          ),
          _VitalTipData(
            icon: Icons.medical_services_rounded,
            title: "Hordoffii Ulfaa fi Qophii Balaa",
            subtitle: "Qophiiwwan da'umsaa dura barbaachisan",
            actionSteps: [
              "Qorannoo da'umsaa duraa hin hambisinaa; dhiibbaa dhiigaa to'achuun lubbuu baraara.",
              "Waraqaa yaalaa, eenyummeessaa fi maallaqa geejjibaa qopheessaa.",
              "Lakkoofsa yeroo balaa bilbila keessan irratti qophii godhaa.",
            ],
            note: "Karaa gara mana yaalaa geessu dursitanii karoorfadhaa.",
            bgColor: Colors.teal[50]!,
            iconColor: Colors.teal[700]!,
          ),
        ];

      case 'so':
        return [
          _VitalTipData(
            icon: Icons.healing_rounded,
            title: "Gargaarka Degdegga ah Ee Suuxdinta & Wareerka",
            subtitle: "Tallaabooyinka degdegga ah markaad daciifto ama wareerto",
            actionSteps: [
              "U seexo dhinaca bidix isla markiiba si dhiiggu u gaaro maskaxda iyo ilmaha.",
              "Furi ama debci dharka adag.",
              "Cab biyo qabow ama cabitaan dabiici ah oo cusub.",
              "Si tartiib ah u neefso, hana istaagin si degdeg ah.",
            ],
            note: "Haddii wareerku sii socdo tag xarunta caafimaadka ee kuugu dhow.",
            bgColor: Colors.blue[50]!,
            iconColor: Colors.blue[700]!,
            initiallyExpanded: true,
          ),
          _VitalTipData(
            icon: Icons.warning_amber_rounded,
            title: "Dhicidda & Dhaawaca Caloosha",
            subtitle: "Waxa la sameeyo ka dib dhicidda ama jugta caloosha",
            actionSteps: [
              "Jooji dhammaan waxqabadka oo naso isla markiiba.",
              "Xitaa haddii aad caadi dareento, la xiriir dhakhtarkaaga si loo eego ilmaha.",
              "Tag qolka degdegga ah haddii aad dareento xanuun ama dhiig bax.",
            ],
            note: "Baaritaanka dhakhtarku waa muhiim si loo hubiyo badqabka mandheerta.",
            bgColor: Colors.amber[50]!,
            iconColor: Colors.amber[800]!,
          ),
          _VitalTipData(
            icon: Icons.water_drop_rounded,
            title: "Dhiigbaxa & Biyo Bixidda",
            subtitle: "Daryeelka muhiimka ah ee dhiigbaxa ama biyaha dillaaca",
            actionSteps: [
              "Ku naso sariirta isla markiiba; ha isticmaalin wax gudaha la geliyo.",
              "Isticmaal suuf nadiif ah si aad u eegto midabka iyo xaddiga.",
              "Raadso daryeel caafimaad oo degdeg ah isla markiiba.",
            ],
            note: "Biyaha dillaaca waxay keeni karaan caabuq, markaa degdeg isbitaalka tag.",
            bgColor: Colors.red[50]!,
            iconColor: Colors.red[700]!,
          ),
          _VitalTipData(
            icon: Icons.speed_rounded,
            title: "Calaamadaha Khatarta Ee Dhiig-karka",
            subtitle: "Calaamadaha khatarta ah ee preeclampsia",
            actionSteps: [
              "Ogow bararka degdegga ah ee wejiga iyo gacmaha.",
              "Madax-xanuun daran iyo aragga oo xumaada baaritaan degdeg ah u baahan.",
              "Xanuun ka hooseeya feeraha midig waa calaamad digniin ah.",
            ],
            note: "Tag isbitaalka adoon sugin ballantaada xigta.",
            bgColor: Colors.purple[50]!,
            iconColor: Colors.purple[700]!,
          ),
          _VitalTipData(
            icon: Icons.medical_services_rounded,
            title: "Baaritaanka Uurka & Boorsada Degdegga ah",
            subtitle: "Diyaargarowga muhiimka ah ka hor dhalmada",
            actionSteps: [
              "Ha seegin ballamaha baarista uurka ee joogtada ah.",
              "Diyaarso kaarka caafimaadka, aqoonsiga iyo lacagta gaadiidka.",
              "Keydi lambarada xaaladaha degdegga ah meel sahlan.",
            ],
            note: "Qorsheyso waddada ugu dhakhsaha badan ee lagu tagi karo isbitaalka.",
            bgColor: Colors.teal[50]!,
            iconColor: Colors.teal[700]!,
          ),
        ];

      case 'en':
      default:
        return [
          _VitalTipData(
            icon: Icons.healing_rounded,
            title: "Fainting & Dizziness First Aid",
            subtitle: "Immediate steps when feeling lightheaded or weak",
            actionSteps: [
              "Lie down on your left side immediately to maximize blood and oxygen flow to baby.",
              "Loosen tight clothing around your neck, chest and waist.",
              "Drink a full glass of cool water or natural fruit juice.",
              "Breathe slowly and deeply; never stand up suddenly from sitting or lying down.",
            ],
            note: "If fainting recurs or is accompanied by blurred vision, seek urgent evaluation.",
            bgColor: Colors.blue[50]!,
            iconColor: Colors.blue[700]!,
            initiallyExpanded: true,
          ),
          _VitalTipData(
            icon: Icons.warning_amber_rounded,
            title: "Falls & Abdominal Trauma",
            subtitle: "What to do after a fall, bump, or vehicle jolt",
            actionSteps: [
              "Stop all activities and lie down to rest immediately.",
              "Even if you feel completely fine, contact your doctor right away to check fetal heart tones.",
              "Go to the emergency room immediately if you feel contractions, uterine tenderness, or spotting.",
            ],
            note: "A doctor check is critical to rule out concealed placental abruption even in minor falls.",
            bgColor: Colors.amber[50]!,
            iconColor: Colors.amber[800]!,
          ),
          _VitalTipData(
            icon: Icons.water_drop_rounded,
            title: "Bleeding & Leaking Fluid",
            subtitle: "Critical actions for amniotic leak and spotting",
            actionSteps: [
              "Rest immediately in bed and do NOT use tampons or insert anything into the vagina.",
              "Wear a clean sanitary pad to observe fluid color, odor, and bleeding amount.",
              "Seek urgent emergency medical evaluation immediately; leaking amniotic fluid requires prompt hospital admission.",
            ],
            note: "Ruptured membranes expose baby to infection risks. Do not wait until labor starts.",
            bgColor: Colors.red[50]!,
            iconColor: Colors.red[700]!,
          ),
          _VitalTipData(
            icon: Icons.speed_rounded,
            title: "Preeclampsia Emergency Signs",
            subtitle: "Dangerous high blood pressure warning signals",
            actionSteps: [
              "Check for sudden facial puffiness or swelling in your hands and feet.",
              "Severe pounding headaches unresponsive to rest require immediate attention.",
              "Pain just below the right rib cage or visual spots/flashes are urgent red flags.",
            ],
            note: "Do not wait for your scheduled clinic day if you experience any of these symptoms.",
            bgColor: Colors.purple[50]!,
            iconColor: Colors.purple[700]!,
          ),
          _VitalTipData(
            icon: Icons.medical_services_rounded,
            title: "Prenatal Check-ups & Emergency Kit",
            subtitle: "Essential preparations before delivery day",
            actionSteps: [
              "Never miss scheduled antenatal appointments; blood pressure checks save lives.",
              "Keep your antenatal card, ID, baby clothes, and transport emergency funds ready in a bag.",
              "Save your doctor and ambulance emergency contact numbers on speed dial.",
            ],
            note: "Know the quickest route to your assigned hospital and alternative transport options.",
            bgColor: Colors.teal[50]!,
            iconColor: Colors.teal[700]!,
          ),
        ];
    }
  }
}

class _VitalTipData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> actionSteps;
  final String note;
  final Color bgColor;
  final Color iconColor;
  final bool initiallyExpanded;

  const _VitalTipData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionSteps,
    required this.note,
    required this.bgColor,
    required this.iconColor,
    this.initiallyExpanded = false,
  });
}

// ── Dropdown / Expandable Vital Tip Tile ────────────────────────────────────
class _VitalTipDropdownCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> actionSteps;
  final String note;
  final String noteHeader;
  final Color bgColor;
  final Color iconColor;
  final bool initiallyExpanded;

  const _VitalTipDropdownCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionSteps,
    required this.note,
    required this.noteHeader,
    required this.bgColor,
    required this.iconColor,
    this.initiallyExpanded = false,
  });

  @override
  State<_VitalTipDropdownCard> createState() => _VitalTipDropdownCardState();
}

class _VitalTipDropdownCardState extends State<_VitalTipDropdownCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isExpanded ? widget.iconColor.withOpacity(0.4) : widget.iconColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.iconColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.iconColor.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, color: widget.iconColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            style: TextStyle(fontSize: 12.5, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: widget.iconColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                // Expanded Dropdown Content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: widget.iconColor.withOpacity(0.2), height: 1),
                        const SizedBox(height: 14),

                        // Action steps with badges
                        ...widget.actionSteps.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final step = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: widget.iconColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$idx',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.grey[850],
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Note Box
                        if (widget.note.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: widget.iconColor.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded, color: widget.iconColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.noteHeader,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: widget.iconColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.note,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}