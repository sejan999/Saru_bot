import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/app_constants.dart';

/// Callback fired by platform TTS lifecycle handlers.
typedef TtsStateCallback = void Function();

/// Wraps `flutter_tts` with Saru Bot's voice configuration.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  /// Fired when the engine starts speaking.
  TtsStateCallback? onSpeakingStarted;

  /// Fired when speech completes, is cancelled or errors out.
  TtsStateCallback? onSpeakingCompleted;

  /// Initialises the underlying TTS engine.
  ///
  /// IMPORTANT: `setStartHandler`, `setCompletionHandler`, `setCancelHandler`
  /// and `setErrorHandler` are registered SYNCHRONOUSLY (never `await`ed),
  /// exactly as required by the plugin contract.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // ---- Synchronous handler registration (deliberately NOT awaited) ------
    _tts.setStartHandler(() {
      onSpeakingStarted?.call();
    });
    _tts.setCompletionHandler(() {
      onSpeakingCompleted?.call();
    });
    _tts.setCancelHandler(() {
      onSpeakingCompleted?.call();
    });
    _tts.setErrorHandler((dynamic message) {
      debugPrint('[SaruBot] TTS error: $message');
      onSpeakingCompleted?.call();
    });
    // -----------------------------------------------------------------------

    try {
      await _tts.setLanguage(AppConstants.ttsLanguage);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      // State transitions are driven by the completion handler above, so we
      // do not block speak() until the utterance finishes.
      await _tts.awaitSpeakCompletion(false);
    } catch (e) {
      debugPrint('[SaruBot] TTS configuration warning: $e');
    }
  }

  /// Speaks [text] aloud. Strips markdown artifacts that sound wrong when
  /// spoken. Returns as soon as the utterance is queued.
  Future<void> speak(String text) async {
    final String clean = text
        .replaceAll(RegExp(r'[*_#`>]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return;

    await init();
    try {
      final dynamic result = await _tts.speak(clean);
      if (result != 1) {
        debugPrint('[SaruBot] TTS failed to queue utterance: $result');
        onSpeakingCompleted?.call();
      }
    } catch (e) {
      debugPrint('[SaruBot] TTS speak failure: $e');
      onSpeakingCompleted?.call();
    }
  }

  /// Stops any ongoing speech.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {/* nothing playing */}
  }
}
