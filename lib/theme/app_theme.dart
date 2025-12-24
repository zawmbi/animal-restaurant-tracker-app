// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';

// ===== Global Colors =====
const kCreamLight = Color(0xFFFCF3EA);
const kCreamDark  = Color(0xFFE8D4B3);
const kGreen      = Color(0xFF9EBD7A);
const kBrownDark  = Color(0xFF624F43);

ThemeData buildAppTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    scaffoldBackgroundColor: kCreamLight,
    dividerColor: Colors.transparent,
    iconTheme: const IconThemeData(
      color: kBrownDark,
    ),
    primaryIconTheme: const IconThemeData(
      color: kBrownDark,
    ),
    colorScheme: base.colorScheme.copyWith(
      primary: kGreen,
      secondary: kGreen,
      surface: kCreamDark,
      onSurface: kBrownDark,
      onPrimary: kBrownDark,
      onSecondary: kBrownDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCreamLight,
      foregroundColor: kBrownDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: kBrownDark,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: kBrownDark,
      displayColor: kBrownDark,
      fontFamily: 'Quano',
    ),
    checkboxTheme: CheckboxThemeData(
  fillColor: WidgetStateProperty.resolveWith((states) {
    // Disabled look (optional, but nicer)
    if (states.contains(WidgetState.disabled)) {
      return !states.contains(WidgetState.selected)
          // ignore: deprecated_member_use
          ? Colors.white.withOpacity(0.5)
          : kGreen.withOpacity(0.5);
    }
    // Checked → green, Unchecked → white
    return states.contains(MaterialState.selected) ? kGreen : Colors.white;
  }),
  checkColor: MaterialStateProperty.all(Colors.white),
  side: const BorderSide(color: kGreen, width: 3), // green outline in both states
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
),

    cardTheme: CardThemeData(
      color: kCreamDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kGreen, width: 4),
      ),
      elevation: 0,
      margin: const EdgeInsets.all(2),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      textColor: kBrownDark,
      collapsedTextColor: kBrownDark,
      iconColor: kBrownDark,
      collapsedIconColor: kBrownDark,
    ),
  );
}
