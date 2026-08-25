import 'package:equatable/equatable.dart';

/// Who produced a chat message.
enum ChatAuthor { user, saru }

/// A single immutable chat message shown in the conversation stream.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.timestamp,
  });

  factory ChatMessage.user(String text) => ChatMessage(
        id: 'u_${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        author: ChatAuthor.user,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.saru(String text) => ChatMessage(
        id: 's_${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        author: ChatAuthor.saru,
        timestamp: DateTime.now(),
      );

  final String id;
  final String text;
  final ChatAuthor author;
  final DateTime timestamp;

  bool get isUser => author == ChatAuthor.user;

  @override
  List<Object?> get props => <Object?>[id, text, author, timestamp];
}
