// ignore_for_file: deprecated_member_use, duplicate_ignore
import 'package:flutter/material.dart';

// ===== Global Colors (Light) =====
const kCreamLight = Color(0xFFFCF3EA);
const kCreamDark  = Color(0xFFE8D4B3);
const kGreen      = Color(0xFF9EBD7A);
const kBrownDark  = Color(0xFF624F43);

/// The same green as [kGreen] — hue 88, saturation 0.34 — darkened from 0.61
/// lightness to 0.28 so it can be read.
///
/// [kGreen] was `colorScheme.primary` and `secondary`, which is what Flutter
/// draws text button labels, tab labels, links, selected chips and focused
/// field labels in. On the cream background that is a contrast ratio of
/// **1.91:1**, and on a card **1.45:1**, against the 4.5:1 that body text
/// needs. It was also the checkbox fill, so a white tick on a checked box
/// came out at 2.1:1 — invisible, in an app whose entire purpose is seeing
/// what you have ticked.
///
/// This reads 6.47:1 on cream, 4.90:1 on a card, and carries a cream label at
/// 6.47:1. [kGreen] itself is kept for decoration that is not text and not
/// state — the card borders — so the app still looks like itself.
const kGreenDeep = Color(0xFF495F2F);

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
      primary: kGreenDeep,
      secondary: kGreenDeep,
      surface: kCreamDark,
      onSurface: kBrownDark,
      // Cream on the deep green reads 6.47:1. Brown on it does not.
      onPrimary: kCreamLight,
      onSecondary: kCreamLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCreamLight,
      foregroundColor: kBrownDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Quano',
        fontSize: 30,
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
              : kGreenDeep.withOpacity(0.5);
        }
        return states.contains(MaterialState.selected)
            ? kGreenDeep
            : Colors.white;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      // An empty box is shown entirely by its outline, so the outline has to
      // be visible: kGreen on cream was 1.91:1.
      side: const BorderSide(color: kGreenDeep, width: 3),
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
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Quano',
        fontSize: 30,
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
