import '../entities/chat_message.dart';

/// Contract for talking to Saru Bot's AI brain.
abstract class ChatRepository {
  /// Sends [message] (plus [history] for multi-turn context) to Gemini and
  /// returns Saru Bot's textual reply. Throws [ChatRepositoryException] on
  /// any failure with a human-friendly message ready for display/TTS.
  Future<String> sendMessage({
    required String apiKey,
    required List<ChatMessage> history,
    required String message,
  });
}

/// Failure type carrying a display-ready explanation.
class ChatRepositoryException implements Exception {
  const ChatRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
