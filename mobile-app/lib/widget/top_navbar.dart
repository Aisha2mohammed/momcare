import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/screens/notification_page.dart';
import 'package:provider/provider.dart';

class CustomTopNavbar extends StatelessWidget implements PreferredSizeWidget {
  const CustomTopNavbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
            ),
            Row(
              children: [
                // Language Translator Dropdown
                PopupMenuButton<Locale>(
                  icon: Icon(Icons.language_rounded, color: AppColors.primary, size: 28),
                  onSelected: (Locale locale) {
                    provider.setLocale(locale);
                  },
                  itemBuilder: (BuildContext context) => L10n.all.map((locale) {
                    final name = L10n.getLanguageName(locale.languageCode);
                    return PopupMenuItem<Locale>(
                      value: locale,
                      child: Text(name),
                    );
                  }).toList(),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationPage()),
                    );
                  },
                  icon: Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 28),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}