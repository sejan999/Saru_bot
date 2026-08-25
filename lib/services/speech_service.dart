import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/app_constants.dart';

/// Callbacks emitted by [SpeechService].
typedef SpeechResultCallback = void Function(String text);
typedef SpeechStatusCallback = void Function(bool listening);

/// Wraps `speech_to_text`, handling the RECORD_AUDIO runtime permission.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  SpeechResultCallback? onFinalResult;
  SpeechStatusCallback? onListeningChanged;

  /// Whether the device speech recognizer is available.
  bool get isAvailable => _initialized && _speech.isAvailable;

  /// Requests the microphone permission (if needed), then initialises the
  /// recognizer. Returns true when listening can start.
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;

    PermissionStatus status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }

    try {
      _initialized = await _speech.initialize(
        onError: (stt.SpeechRecognitionError error) =>
            onListeningChanged?.call(false),
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  /// Starts a listening session. Final transcripts arrive through
  /// [onFinalResult]; session state through [onListeningChanged].
  Future<bool> startListening() async {
    final bool ok = await initialize();
    if (!ok) return false;

    await _speech.listen(
      onResult: (stt.SpeechRecognitionResult result) {
        final String text = result.recognizedWords.trim();
        if (result.finalResult && text.isNotEmpty) {
          onFinalResult?.call(text);
        }
      },
      localeId: AppConstants.sttLocaleId,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
    onListeningChanged?.call(true);
    return true;
  }

  /// Stops the active listening session.
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {/* already stopped */}
    onListeningChanged?.call(false);
  }

  void dispose() {
    try {
      _speech.cancel();
    } catch (_) {}
  }
}
