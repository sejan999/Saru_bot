/// Application-wide constants for Saru Bot.
class AppConstants {
  const AppConstants._();

  /// SharedPreferences key under which the user-entered Gemini API key
  /// is persisted locally on-device.
  static const String apiKeyStorageKey = 'gemini_api_key';

  /// Gemini model used by Saru Bot.
  static const String geminiModelName = 'gemini-1.5-flash';

  /// System instruction injected into every Gemini request.
  static const String systemInstruction =
      'You are Saru Bot, a warm, witty and highly capable voice assistant. '
      'Your replies are spoken aloud through text-to-speech, so keep them '
      'conversational, friendly and concise (1-4 sentences). Never use '
      'markdown formatting, bullet points or emoji in your replies. '
      'Respond naturally in Bengali if the user speaks in Bengali.';

  /// Locale identifiers for speech recognition / synthesis.
  ///
  /// Fully localised for Bengali (Bangladesh):
  /// - STT uses the Bengali (Bangladesh) recognizer locale.
  /// - TTS uses the Bengali (Bangladesh) synthesis voice.
  static const String sttLocaleId = 'bn_BD';
  static const String ttsLanguage = 'bn-BD';
}
