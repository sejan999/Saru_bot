import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/app_constants.dart';

/// Lightweight immutable turn used to replay conversation history into
/// Gemini as request contents.
@immutable
class GeminiTurn {
  const GeminiTurn({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// Remote datasource wrapping the `google_generative_ai` SDK.
///
/// Stateless by design: a fresh [GenerativeModel] is built per request so a
/// hot-swapped API key (saved from the Settings dialog) takes effect
/// immediately without an app restart.
class GeminiRemoteDataSource {
  const GeminiRemoteDataSource();

  /// Strictly pinned model — do not change.
  static const String _modelName = AppConstants.geminiModelName;

  Future<String> generateResponse({
    required String apiKey,
    required List<GeminiTurn> history,
    required String prompt,
  }) async {
    final GenerativeModel model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(AppConstants.systemInstruction),
      // NOTE: GenerationConfig is intentionally NOT const — its constructor
      // is non-const in google_generative_ai ^0.4.6.
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 1024,
      ),
    );

    final List<Content> contents = <Content>[
      for (final GeminiTurn turn in history)
        turn.isUser
            ? Content.text(turn.text)
            : Content.model(<Part>[TextPart(turn.text)]),
      Content.text(prompt),
    ];

    try {
      final GenerateContentResponse response = await model
          .generateContent(contents)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Gemini did not respond within 15 seconds.',
            ),
          );
      final String? reply = response.text;
      if (reply == null || reply.trim().isEmpty) {
        throw const ChatDataSourceException(
          'Saru Bot received an empty response. Please try again.',
        );
      }
      return reply.trim();
    } on TimeoutException {
      throw const ChatDataSourceException(
        'Saru Bot took too long to respond (15s timeout). Please check '
        'your internet connection and try again.',
      );
    } on GenerativeAIException catch (e) {
      throw ChatDataSourceException(_explain(e));
    } catch (e) {
      throw ChatDataSourceException(_explainGeneric(e));
    }
  }

  static String _explain(GenerativeAIException e) {
    debugPrint('[SaruBot] Gemini API error: ${e.message}');
    final String m = e.message.toLowerCase();
    if (m.contains('api key') ||
        m.contains('api_key') ||
        m.contains('permission denied') ||
        m.contains('unauthenticated') ||
        m.contains('401') ||
        m.contains('403')) {
      return 'Your Gemini API key looks invalid or unauthorized. '
          'Tap the gear icon to update it.';
    }
    if (m.contains('quota') || m.contains('resource_exhausted') || m.contains('429')) {
      return 'Gemini quota exceeded. Please try again in a little while.';
    }
    if (m.contains('404') || m.contains('not found')) {
      return 'The Gemini model "$_modelName" is not available for your key. '
          '${e.message}';
    }
    if (m.contains('500') || m.contains('503') || m.contains('unavailable')) {
      return 'Gemini is temporarily unavailable. Please try again shortly.';
    }
    return 'Gemini error: ${e.message}';
  }

  static String _explainGeneric(Object e) {
    debugPrint('[SaruBot] Gemini transport error: $e');
    final String s = e.toString().toLowerCase();
    if (s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('connection')) {
      return 'Network problem reaching Gemini — please check your internet '
          'connection and try again.';
    }
    return 'Saru Bot could not complete the request: $e';
  }
}

/// Failure carrying a display-ready message up to the presentation layer.
class ChatDataSourceException implements Exception {
  const ChatDataSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}
