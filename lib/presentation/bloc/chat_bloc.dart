import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../services/settings_service.dart';
import '../../../services/speech_service.dart';
import '../../../services/tts_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// Orchestrates the full voice loop:
/// mic -> transcript -> Gemini reply -> TTS playback.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ChatRepository chatRepository,
    required SettingsService settingsService,
    required SpeechService speechService,
    required TtsService ttsService,
  })  : _chatRepository = chatRepository,
        _settingsService = settingsService,
        _speechService = speechService,
        _ttsService = ttsService,
        super(const ChatState()) {
    on<ChatInitialized>(_onInitialized);
    on<ApiKeySaveRequested>(_onApiKeySaveRequested);
    on<MicToggled>(_onMicToggled);
    on<SpeechTranscribed>(_onSpeechTranscribed);
    on<UserMessageSubmitted>(_onUserMessageSubmitted);
    on<SaruSpeakingStarted>(_onSpeakingStarted);
    on<SaruSpeakingFinished>(_onSpeakingFinished);
    on<ErrorDismissed>(_onErrorDismissed);

    // Wire platform callbacks into bloc events (guarded against a closed
    // bloc during teardown).
    _speechService.onFinalResult =
        (String text) => add(SpeechTranscribed(text));
    _ttsService.onSpeakingStarted = () => add(const SaruSpeakingStarted());
    _ttsService.onSpeakingCompleted = () => add(const SaruSpeakingFinished());
  }

  final ChatRepository _chatRepository;
  final SettingsService _settingsService;
  final SpeechService _speechService;
  final TtsService _ttsService;

  // ---- Event handlers ------------------------------------------------------

  Future<void> _onInitialized(
    ChatInitialized event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.idle));

    // Load the persisted API key without ever blocking the UI on its absence.
    emit(state.copyWith(hasApiKey: _settingsService.hasApiKey));

    try {
      // Permission request + recognizer warm-up run behind the first frame;
      // failure only degrades the mic, never the app.
      final bool available = await _speechService.initialize();
      if (!isClosed) emit(state.copyWith(micAvailable: available));
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            micAvailable: false,
            error: 'Speech recognition is not available on this device. '
                'You can still chat by typing below.',
          ),
        );
      }
    }
  }

  Future<void> _onApiKeySaveRequested(
    ApiKeySaveRequested event,
    Emitter<ChatState> emit,
  ) async {
    await _settingsService.saveApiKey(event.apiKey);
    if (!isClosed) {
      emit(
        state.copyWith(
          hasApiKey: _settingsService.hasApiKey,
          clearError: true,
        ),
      );
    }
  }

  Future<void> _onMicToggled(
    MicToggled event,
    Emitter<ChatState> emit,
  ) async {
    // Stop an active listening session.
    if (state.isListening) {
      await _speechService.stopListening();
      if (!isClosed) emit(state.copyWith(status: ChatStatus.idle));
      return;
    }

    if (state.isBusy) return;

    if (!state.hasApiKey) {
      emit(
        state.copyWith(
          status: ChatStatus.idle,
          error: 'Please add your Gemini API key first — tap the gear icon '
              'in the top-right corner.',
        ),
      );
      return;
    }

    final bool started = await _speechService.startListening();
    if (isClosed) return;
    if (!started) {
      emit(
        state.copyWith(
          status: ChatStatus.idle,
          error: 'Microphone unavailable. Please grant the microphone '
              'permission in system settings.',
        ),
      );
      return;
    }
    emit(state.copyWith(clearError: true, status: ChatStatus.listening));
  }

  Future<void> _onSpeechTranscribed(
    SpeechTranscribed event,
    Emitter<ChatState> emit,
  ) async {
    await _speechService.stopListening();
    await _respond(event.text, emit);
  }

  Future<void> _onUserMessageSubmitted(
    UserMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    await _respond(event.text, emit);
  }

  void _onSpeakingStarted(SaruSpeakingStarted event, Emitter<ChatState> emit) {
    if (state.status == ChatStatus.processing) {
      emit(state.copyWith(status: ChatStatus.speaking));
    }
  }

  void _onSpeakingFinished(
    SaruSpeakingFinished event,
    Emitter<ChatState> emit,
  ) {
    if (state.status == ChatStatus.speaking ||
        state.status == ChatStatus.listening) {
      emit(state.copyWith(status: ChatStatus.idle));
    }
  }

  void _onErrorDismissed(ErrorDismissed event, Emitter<ChatState> emit) {
    emit(state.copyWith(clearError: true));
  }

  // ---- Core conversation flow ----------------------------------------------

  Future<void> _respond(String rawText, Emitter<ChatState> emit) async {
    final String text = rawText.trim();
    if (text.isEmpty || state.isBusy) return;

    if (!state.hasApiKey) {
      emit(
        state.copyWith(
          status: ChatStatus.idle,
          error: 'No Gemini API key configured yet. Tap the gear icon to '
              'add one — it takes just a moment.',
        ),
      );
      return;
    }

    // History snapshot BEFORE appending the new user message.
    final List<ChatMessage> history = List<ChatMessage>.of(state.messages);

    final List<ChatMessage> withUserMessage = <ChatMessage>[
      ...history,
      ChatMessage.user(text),
    ];
    emit(
      state.copyWith(
        messages: withUserMessage,
        clearError: true,
        status: ChatStatus.processing,
      ),
    );

    final String reply;
    try {
      reply = await _chatRepository.sendMessage(
        apiKey: _settingsService.getApiKey(),
        history: history,
        message: text,
      );
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            messages: withUserMessage,
            status: ChatStatus.idle,
            error: e.toString(),
          ),
        );
      }
      return;
    }

    if (isClosed) return;

    emit(
      state.copyWith(
        messages: <ChatMessage>[...withUserMessage, ChatMessage.saru(reply)],
        status: ChatStatus.speaking,
      ),
    );

    // Spoken playback; the TTS completion handler flips us back to idle.
    try {
      await _ttsService.speak(reply);
    } catch (_) {/* completion handler already covers failure */}

    // Safety net for engines whose handlers never fire (rare emulators):
    // never leave the orb stuck in the Speaking state.
    if (!isClosed && state.status == ChatStatus.speaking) {
      emit(state.copyWith(status: ChatStatus.idle));
    }
  }

  @override
  Future<void> close() async {
    await _ttsService.stop();
    _speechService.dispose();
    return super.close();
  }
}
