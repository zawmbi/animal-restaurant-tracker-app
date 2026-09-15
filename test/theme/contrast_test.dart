// The accent colour was #9EBD7A on a #FCF3EA background — 1.91:1, where body
// text needs 4.5:1 — and it was also the checkbox fill, so a white tick on a
// checked box sat at 2.1:1. In an app for ticking things off, that is the one
// thing that has to be visible.
//
// These compute the real WCAG 2.1 ratios from the themes themselves, so a
// palette edit that undoes it fails here rather than on someone's phone.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/theme/app_theme.dart';

/// WCAG 2.1 contrast ratio. Flutter's `computeLuminance()` is already the
/// relative luminance the formula asks for.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Text below 18pt, which is all of this app's body copy.
const double aaBodyText = 4.5;

/// Icons, borders and other non-text things that carry meaning.
const double aaNonText = 3.0;

void main() {
  group('light theme', () {
    final theme = buildLightTheme();
    final scheme = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;

    test('body text is readable on the background and on a card', () {
      expect(contrast(scheme.onSurface, background),
          greaterThanOrEqualTo(aaBodyText));
      expect(contrast(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(aaBodyText));
    });

    test('the accent colour is readable as text, which is what it is used for',
        () {
      // primary and secondary are what Flutter paints text button labels, tab
      // labels, links and selected chip labels in.
      for (final accent in [scheme.primary, scheme.secondary]) {
        expect(contrast(accent, background), greaterThanOrEqualTo(aaBodyText));
        expect(
            contrast(accent, scheme.surface), greaterThanOrEqualTo(aaBodyText));
      }
    });

    test('a label on a filled button is readable', () {
      expect(contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(aaBodyText));
      expect(contrast(scheme.onSecondary, scheme.secondary),
          greaterThanOrEqualTo(aaBodyText));
    });

    test('a ticked checkbox shows its tick', () {
      final fill = theme.checkboxTheme.fillColor!
          .resolve(<WidgetState>{WidgetState.selected})!;
      final check = theme.checkboxTheme.checkColor!.resolve(<WidgetState>{})!;
      expect(contrast(check, fill), greaterThanOrEqualTo(aaBodyText));
    });

    test('an empty checkbox shows its outline against the background', () {
      // An unticked box is nothing but its outline, so the outline is the
      // whole control.
      final side = theme.checkboxTheme.side as BorderSide;
      expect(contrast(side.color, background),
          greaterThanOrEqualTo(aaNonText));
    });
  });

  group('dark theme', () {
    final theme = buildDarkTheme();
    final scheme = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;

    test('body text and the accent are readable', () {
      expect(contrast(scheme.onSurface, background),
          greaterThanOrEqualTo(aaBodyText));
      expect(contrast(scheme.primary, background),
          greaterThanOrEqualTo(aaBodyText));
      expect(
          contrast(scheme.primary, scheme.surface), greaterThanOrEqualTo(aaBodyText));
    });

    test('a ticked checkbox shows its tick', () {
      final fill = theme.checkboxTheme.fillColor!
          .resolve(<WidgetState>{WidgetState.selected})!;
      final check = theme.checkboxTheme.checkColor!.resolve(<WidgetState>{})!;
      expect(contrast(check, fill), greaterThanOrEqualTo(aaBodyText));
    });
  });
}
