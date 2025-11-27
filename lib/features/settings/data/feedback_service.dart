import 'dart:convert';
import 'package:http/http.dart' as http;

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  // TODO: replace this with your deployed backend URL
  static const String _endpoint = 'https://your-backend-domain.com/api/feedback';

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

    if (resp.statusCode != 200) {
      throw Exception('Failed to send feedback (status ${resp.statusCode})');
    }
  }
}
