import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/screens/wellness/music_page.dart';
import 'package:pregnancy_appp/screens/wellness/exercise_page.dart';
import 'package:pregnancy_appp/screens/wellness/sleep_tips_page.dart';
import 'package:pregnancy_appp/screens/wellness/nutrition_guide_page.dart';
import 'package:pregnancy_appp/screens/chatbot_page.dart';
import 'package:pregnancy_appp/widget/am_i_pregnant_card.dart';
import 'package:pregnancy_appp/screens/home/fetal_details_page.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';
import 'package:pregnancy_appp/services/push_service.dart';
import 'package:pregnancy_appp/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentWeek = 0;
  int _daysRemaining = 0;
  double _progress = 0.0;
  String _motherName = '';

  @override
  void initState() {
    super.initState();
    MotherService.pregnancyProgress.addListener(_onProgressChanged);
    _loadCachedData();
    _loadData();
    _setupPushNotifications();
  }

  @override
  void dispose() {
    MotherService.pregnancyProgress.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    final progress = MotherService.pregnancyProgress.value;
    if (progress != null && mounted) {
      setState(() {
        final w = (progress['currentWeek'] as int?) ?? 0;
        if (w > 0) _currentWeek = w;
        final dr = (progress['daysRemaining'] as int?) ?? 0;
        if (dr > 0) _daysRemaining = dr;
        final pct = (progress['percentageComplete'] as num?)?.toDouble() ?? 0.0;
        _progress = (pct / 100).clamp(0.0, 1.0);
      });
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final cachedProgress = await MotherService.getCachedGestationalWeek();
      final cachedProfile = await MotherService.getCachedProfile();
      if (!mounted) return;
      setState(() {
        if (cachedProgress != null && (cachedProgress['currentWeek'] as int? ?? 0) > 0) {
          _currentWeek = cachedProgress['currentWeek'] as int;
          _daysRemaining = (cachedProgress['daysRemaining'] as int?) ?? _daysRemaining;
          final pct = (cachedProgress['percentageComplete'] as num?)?.toDouble() ?? 0.0;
          _progress = (pct / 100).clamp(0.0, 1.0);
        }
        if (cachedProfile != null) {
          final user = cachedProfile['user'] as Map<String, dynamic>? ?? {};
          final name = (user['name'] as String?) ?? '';
          if (name.isNotEmpty) _motherName = name;
        }
      });
    } catch (_) {}
  }

  Future<void> _setupPushNotifications() async {
    try {
      final token = await ApiService.getToken();
      if (token != null && mounted) {
        await PushService.init(
          jwt: token,
          onTap: (data) {
            if (mounted) {
              PushService.handleNotificationTap(context, data);
            }
          },
          onInApp: (n) {
            debugPrint('[Home] In-app notification received: ${n['title']} (type: ${n['type']})');
            if (mounted && n['title'] != null) {
              final type = (n['type'] ?? '').toString().toLowerCase();
              final isAlert = type == 'alert';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: isAlert ? const Color(0xFFDC2626) : const Color(0xFF61183E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (n['body'] != null)
                        Text(
                          n['body'].toString(),
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  action: SnackBarAction(
                    label: 'View',
                    textColor: Colors.amberAccent,
                    onPressed: () {
                      final data = n['data'] is Map ? Map<String, dynamic>.from(n['data']) : n;
                      PushService.handleNotificationTap(context, data);
                    },
                  ),
                ),
              );
            }
          },
        );
        // Refresh unread count for top navbar red badge
        NotificationService.fetchUnreadCount();
      }
    } catch (e) {
      debugPrint('[Home] Push setup error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        MotherService.getGestationalWeek(),
        MotherService.getProfile(),
      ]);
      if (!mounted) return;
      final progress = results[0];
      final profile = results[1];
      final user = profile['user'] as Map<String, dynamic>? ?? {};

      setState(() {
        final w = (progress['currentWeek'] as int?) ?? 0;
        if (w > 0) _currentWeek = w;
        final dr = (progress['daysRemaining'] as int?) ?? 0;
        if (dr > 0) _daysRemaining = dr;
        final pct = (progress['percentageComplete'] as num?)?.toDouble() ?? 0.0;
        _progress = (pct / 100).clamp(0.0, 1.0);
        final name = (user['name'] as String?) ?? '';
        if (name.isNotEmpty) _motherName = name;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      // Silently keep cached data on network failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final greetingName = _motherName.isEmpty ? 'there' : _motherName;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- GREETING SECTION ---
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.of(context, 'welcome'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.of(context, 'baby_growing', [greetingName]),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // --- UNIFIED DAY + PROGRESS CONTAINER ---
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FetalDetailsPage()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day scrollable row
                      SizedBox(
                        height: 75,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            final now = DateTime.now();
                            final monday = now.subtract(Duration(days: now.weekday - 1));
                            final thisDay = monday.add(Duration(days: index));
                            final daysMap = {
                              'am': ["ሰኞ", "ማክሰ", "ረቡዕ", "ሐሙስ", "አርብ", "ቅዳሜ", "እሁድ"],
                              'om': ["Wix", "Kib", "Rob", "Kam", "Jim", "San", "Dil"],
                              'so': ["Isni", "Tala", "Arba", "Kham", "Jum", "Saba", "Axad"],
                              'en': ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                            };
                            final currentLocale = Localizations.localeOf(context).languageCode;
                            final days = daysMap[currentLocale] ?? daysMap['en']!;
                            final bool isToday = thisDay.year == now.year &&
                                                 thisDay.month == now.month &&
                                                 thisDay.day == now.day;
                            return Container(
                              width: 55,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: isToday ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: isToday ? [
                                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                                ] : [
                                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    days[index],
                                    style: TextStyle(
                                      color: isToday ? Colors.white70 : Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${thisDay.day}",
                                    style: TextStyle(
                                      color: isToday ? Colors.white : Colors.black87,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentWeek > 0
                                ? "${AppStrings.of(context, 'week')} $_currentWeek"
                                : AppStrings.of(context, 'pregnancy'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (_daysRemaining > 0)
                            Text(
                              "$_daysRemaining ${AppStrings.of(context, 'days_left')}",
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // --- YOUR PREGNANCY THIS WEEK CARD ---
              AmIPregnantCard(week: _currentWeek, daysRemaining: _daysRemaining),

              const SizedBox(height: 25),

              // --- CHATBOT CONTAINER UI ---
              _buildChatbotContainer(context),

              const SizedBox(height: 30),

              // --- WELLNESS QUICK ACCESS (OVERHAULED TO ROWS) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.of(context, 'wellness_guides'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _buildWellnessRow(
                context,
                AppStrings.of(context, 'music'),
                AppStrings.of(context, 'relaxation_music'),
                Icons.audiotrack_rounded,
                Colors.purple[50]!,
                const MusicPage()
              ),
              _buildWellnessRow(
                context,
                AppStrings.of(context, 'exercise'),
                AppStrings.of(context, 'stay_active'),
                Icons.fitness_center_rounded,
                Colors.orange[50]!,
                const ExercisePage()
              ),
              _buildWellnessRow(
                context,
                AppStrings.of(context, 'sleeping'),
                AppStrings.of(context, 'better_sleep'),
                Icons.bedtime_rounded,
                Colors.indigo[50]!,
                const SleepTipsPage()
              ),
              _buildWellnessRow(
                context,
                AppStrings.of(context, 'nutrition'),
                AppStrings.of(context, 'nutrition'),
                Icons.restaurant_rounded,
                Colors.green[50]!,
                const NutritionGuidePage()
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatbotContainer(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatBotPage())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.of(context, 'ask_assistant'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.of(context, 'ask_assistant_subtitle'),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessRow(BuildContext context, String title, String subtitle, IconData icon, Color bgColor, Widget targetPage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage)),
            child: Text(
              AppStrings.of(context, 'see_all'),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}