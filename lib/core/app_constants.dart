/// Application-wide constants for Saru Bot.
class AppConstants {
  const AppConstants._();

  /// SharedPreferences key under which the user-entered Gemini API key
  /// is persisted locally on-device.
  static const String apiKeyStorageKey = 'gemini_api_key';

  /// Gemini model used by Saru Bot.
  static const String geminiModelName = 'gemini-3.7-flash';

  /// System instruction injected into every Gemini request.
  static const String systemInstruction =
      'You are Saru Bot, an advanced, highly knowledgeable, and incredibly '
      'friendly AI assistant. Always respond in natural, conversational, and '
      'polite Bengali. Keep your answers clear, accurate, and easy to '
      'understand. Act like a helpful friend who knows a lot about '
      'technology, coding, and the world. Do not use robotic language; speak '
      'with warmth and empathy.';

  /// Locale identifiers for speech recognition / synthesis.
  ///
  /// Fully localised for Bengali (Bangladesh):
  /// - STT uses the Bengali (Bangladesh) recognizer locale.
  /// - TTS uses the Bengali (Bangladesh) synthesis voice.
  static const String sttLocaleId = 'bn_BD';
  static const String ttsLanguage = 'bn-BD';
}
