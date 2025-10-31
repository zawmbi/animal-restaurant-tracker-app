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
    colorScheme: base.colorScheme.copyWith(
      primary: kGreen,
      secondary: kGreen,
      surface: kCreamDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCreamLight,
      foregroundColor: kBrownDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: kBrownDark,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: kBrownDark,
      displayColor: kBrownDark,
      fontFamily: 'Roboto',
    ),
    checkboxTheme: CheckboxThemeData(
  fillColor: MaterialStateProperty.resolveWith((states) {
    // Disabled look (optional, but nicer)
    if (states.contains(MaterialState.disabled)) {
      return states.contains(MaterialState.selected)
          ? kGreen.withOpacity(0.5)
          : Colors.white.withOpacity(0.5);
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
        side: const BorderSide(color: kGreen, width: 3),
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
