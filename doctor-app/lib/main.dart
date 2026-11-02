import 'package:flutter/material.dart';
import 'package:doctor_app/splash/splash_screen.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DoctorApp());
}

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleNotifier.shared,
      builder: (context, _) {
        return MaterialApp(
          title: LocaleNotifier.shared.t('app_title'),
          debugShowCheckedModeBanner: false,
          locale: LocaleNotifier.shared.currentLocale,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.secondary,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.secondary,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.textPrimary),
              titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
