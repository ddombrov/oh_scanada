import 'package:flutter/material.dart';
import '../colours/colour_system.dart';

Widget buildSection({
  required String title,
  required IconData icon,
  required Widget child,
  BuildContext? context,
}) {
  final themeProvider = ThemeProvider();
  final isDark = themeProvider.isDarkMode;
  final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
  final textColor = isDark ? Colors.white : CanadianTheme.darkGrey;
  final headerBgColor = isDark
      ? CanadianTheme.canadianRed.withOpacity(0.2)
      : CanadianTheme.canadianRed.withOpacity(0.1);
  final shadowColor =
      isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05);

  return Container(
    margin: const EdgeInsets.only(bottom: 16.0),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10.0),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: headerBgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: CanadianTheme.canadianRed, size: 18),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(12.0), child: child),
      ],
    ),
  );
}
