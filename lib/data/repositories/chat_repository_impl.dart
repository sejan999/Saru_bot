import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/gemini_remote_data_source.dart';

/// Production [ChatRepository] backed by the Gemini remote datasource.
class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._remoteDataSource);

  final GeminiRemoteDataSource _remoteDataSource;

  @override
  Future<String> sendMessage({
    required String apiKey,
    required List<ChatMessage> history,
    required String message,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const ChatRepositoryException(
        'No Gemini API key configured. Tap the gear icon to add one.',
      );
    }

    final List<GeminiTurn> turns = <GeminiTurn>[
      for (final ChatMessage msg in history)
        GeminiTurn(isUser: msg.isUser, text: msg.text),
    ];

    try {
      return await _remoteDataSource.generateResponse(
        apiKey: apiKey.trim(),
        history: turns,
        prompt: message,
      );
    } on ChatDataSourceException catch (e) {
      throw ChatRepositoryException(e.message);
    }
  }
}
