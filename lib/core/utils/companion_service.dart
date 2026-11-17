/// Talks to the Calm Attack companion server.
///
/// The server holds the OpenAI API key and the companion's instructions;
/// the app only sends the chat so far and gets the next reply back.
/// Set the server address when building the app:
///
///   flutter run --dart-define=COMPANION_URL=https://your-server.example
///
/// Optionally add --dart-define=COMPANION_TOKEN=... if the server has
/// APP_TOKEN set.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

/// One message in the chat.
class ChatMessage {
  /// Either 'user' or 'assistant'.
  final String role;
  final String text;

  const ChatMessage({required this.role, required this.text});

  bool get fromUser => role == 'user';

  Map<String, String> toJson() => {'role': role, 'content': text};
}

class CompanionService {
  static const _url = String.fromEnvironment('COMPANION_URL');
  static const _token = String.fromEnvironment('COMPANION_TOKEN');

  /// Used when the server can't be reached and doesn't send its own.
  static const offlineReply =
      "I can't connect right now, but you can still do this. "
      'Breathe in for 3, hold for 3, out for 3. '
      'If you feel unsafe, please call your local emergency number.';

  /// True when the app was built with a companion server address.
  static bool get isConfigured => _url.isNotEmpty;

  /// Sends the conversation and returns the companion's next reply.
  /// [checkInSummary] is the user's check-in log, sent only when they chose
  /// to talk it through with Bloom.
  /// Never throws: on any failure it returns a calm fallback message.
  static Future<String> reply(
    List<ChatMessage> conversation, {
    String? checkInSummary,
  }) async {
    if (!isConfigured) return offlineReply;
    try {
      final response = await http
          .post(
            Uri.parse('$_url/chat'),
            headers: {
              'content-type': 'application/json',
              if (_token.isNotEmpty) 'x-app-token': _token,
            },
            body: jsonEncode({
              'messages': [for (final m in conversation) m.toJson()],
              if (checkInSummary != null) 'checkIns': checkInSummary,
            }),
          )
          .timeout(const Duration(seconds: 60));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map && data['reply'] is String) {
        return data['reply'] as String;
      }
      return offlineReply;
    } catch (_) {
      return offlineReply;
    }
  }
}
