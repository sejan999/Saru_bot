import 'package:equatable/equatable.dart';

import '../../../domain/entities/chat_message.dart';

/// High-level conversation state driving both the orb animation and the
/// chat stream.
enum ChatStatus { loading, idle, listening, processing, speaking }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.loading,
    this.messages = const <ChatMessage>[],
    this.hasApiKey = false,
    this.micAvailable = false,
    this.error,
  });

  final ChatStatus status;
  final List<ChatMessage> messages;

  /// Whether a Gemini API key is stored locally.
  final bool hasApiKey;

  /// Whether the on-device speech recognizer is usable.
  final bool micAvailable;

  /// Display-ready error message, or null.
  final String? error;

  bool get isBusy =>
      status == ChatStatus.processing || status == ChatStatus.speaking;

  bool get isListening => status == ChatStatus.listening;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    bool? hasApiKey,
    bool? micAvailable,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      micAvailable: micAvailable ?? this.micAvailable,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[status, messages, hasApiKey, micAvailable, error];
}
