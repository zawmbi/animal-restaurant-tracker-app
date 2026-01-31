// ignore_for_file: deprecated_member_use, duplicate_ignore
import 'package:flutter/material.dart';

// ===== Global Colors (Light) =====
const kCreamLight = Color(0xFFFCF3EA);
const kCreamDark  = Color(0xFFE8D4B3);
const kGreen      = Color(0xFF9EBD7A);
const kBrownDark  = Color(0xFF624F43);

// ===== Global Colors (Dark) =====
const kBgDark      = Color(0xFF15120F);
const kSurfaceDark = Color(0xFF221C17);
const kTextDark    = Color(0xFFE8D4B3);

ThemeData buildLightTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    scaffoldBackgroundColor: kCreamLight,
    dividerColor: Colors.transparent,
    iconTheme: const IconThemeData(color: kBrownDark),
    primaryIconTheme: const IconThemeData(color: kBrownDark),
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.light,
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
        fontFamily: 'Quano',
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
        if (states.contains(WidgetState.disabled)) {
          return !states.contains(WidgetState.selected)
              ? Colors.white.withOpacity(0.5)
              : kGreen.withOpacity(0.5);
        }
        return states.contains(MaterialState.selected) ? kGreen : Colors.white;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      side: const BorderSide(color: kGreen, width: 3),
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

ThemeData buildDarkTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    scaffoldBackgroundColor: kBgDark,
    dividerColor: Colors.transparent,
    iconTheme: const IconThemeData(color: kTextDark),
    primaryIconTheme: const IconThemeData(color: kTextDark),
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: kGreen,
      secondary: kGreen,
      surface: kSurfaceDark,
      onSurface: kTextDark,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgDark,
      foregroundColor: kTextDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Quano',
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: kTextDark,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: kTextDark,
      displayColor: kTextDark,
      fontFamily: 'Quano',
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return states.contains(WidgetState.selected)
              ? kGreen.withOpacity(0.5)
              : kTextDark.withOpacity(0.2);
        }
        return states.contains(MaterialState.selected)
            ? kGreen
            : kSurfaceDark;
      }),
      checkColor: MaterialStateProperty.all(Colors.black),
      side: const BorderSide(color: kGreen, width: 3),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    ),
    cardTheme: CardThemeData(
      color: kSurfaceDark,
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
      textColor: kTextDark,
      collapsedTextColor: kTextDark,
      iconColor: kTextDark,
      collapsedIconColor: kTextDark,
    ),
  );
}
