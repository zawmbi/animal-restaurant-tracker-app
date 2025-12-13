import 'dart:convert';
import 'package:http/http.dart' as http;

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

static const String _endpoint =
  'https://backendfeedbackartracker-ld654l1wr-lindas-projects-8d7821fa.vercel.app';

  Future<void> sendFeedback({
    required String message,
    String? contact,
  }) async {
    final resp = await http.post(
      Uri.parse(_endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'contact': contact,
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to send feedback (${resp.statusCode}): ${resp.body}');
    }

  }
}
