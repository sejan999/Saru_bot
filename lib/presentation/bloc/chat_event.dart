import 'package:equatable/equatable.dart';

/// Base class for all Saru Bot chat events.
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Fired once at app startup to wire services and load the stored API key.
class ChatInitialized extends ChatEvent {
  const ChatInitialized();
}

/// User saved (or cleared) the Gemini API key from the Settings dialog.
class ApiKeySaveRequested extends ChatEvent {
  const ApiKeySaveRequested(this.apiKey);

  final String apiKey;

  @override
  List<Object?> get props => <Object?>[apiKey];
}

/// User tapped the orb to start/stop listening.
class MicToggled extends ChatEvent {
  const MicToggled();
}

/// A final speech transcript arrived from the recognizer.
class SpeechTranscribed extends ChatEvent {
  const SpeechTranscribed(this.text);

  final String text;

  @override
  List<Object?> get props => <Object?>[text];
}

/// A typed message was submitted from the text field.
class UserMessageSubmitted extends ChatEvent {
  const UserMessageSubmitted(this.text);

  final String text;

  @override
  List<Object?> get props => <Object?>[text];
}

/// The TTS engine started speaking Saru Bot's reply.
class SaruSpeakingStarted extends ChatEvent {
  const SaruSpeakingStarted();
}

/// The TTS engine finished (or cancelled / failed) speaking.
class SaruSpeakingFinished extends ChatEvent {
  const SaruSpeakingFinished();
}

/// User dismissed the error banner.
class ErrorDismissed extends ChatEvent {
  const ErrorDismissed();
}
