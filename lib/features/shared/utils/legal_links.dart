// lib/features/shared/utils/legal_links.dart
//
// The one place the published policy URL is written down.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The published privacy policy.
///
/// App Store Connect points at this same URL under App Information ->
/// Privacy Policy URL, and guideline 5.1.1(i) expects an app that offers
/// account creation to surface the policy inside the app as well — reviewers
/// look for it on the sign-in screen.
///
/// Keep the two in sync. A live listing whose privacy link 404s is a
/// compliance problem, not just a broken link, so if this ever moves, change
/// App Store Connect in the same pass and leave a 301 behind.
final Uri privacyPolicyUrl = Uri.parse(
  'https://zawmbi.com/privacy/animal-restaurant-tracker/',
);

/// Opens the privacy policy in the system browser.
///
/// Reports failure in a snackbar rather than looking like a dead button — a
/// reviewer tapping a link that does nothing reads it as the policy being
/// missing.
Future<void> openPrivacyPolicy(BuildContext context) async {
  // Captured before the await so the messenger does not depend on the context
  // still being mounted afterwards.
  final messenger = ScaffoldMessenger.of(context);

  var ok = false;
  try {
    ok = await launchUrl(
      privacyPolicyUrl,
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    ok = false;
  }

  if (!ok) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open the privacy policy.')),
    );
  }
}
