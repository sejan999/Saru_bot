import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/app_theme.dart';
import 'data/datasources/gemini_remote_data_source.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories/chat_repository.dart';
import 'presentation/bloc/chat_bloc.dart';
import 'presentation/bloc/chat_event.dart';
import 'presentation/pages/home_page.dart';
import 'services/settings_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage is initialised eagerly so the API key is available before the
  // first frame. A missing key NEVER blocks startup — the UI offers the
  // Settings dialog gracefully instead.
  final SettingsService settingsService = SettingsService();
  await settingsService.init();

  runApp(SaruBotApp(settingsService: settingsService));
}

class SaruBotApp extends StatelessWidget {
  const SaruBotApp({super.key, required this.settingsService});

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ChatRepository>(
      create: (_) => ChatRepositoryImpl(const GeminiRemoteDataSource()),
      child: BlocProvider<ChatBloc>(
        create: (BuildContext context) => ChatBloc(
          chatRepository: context.read<ChatRepository>(),
          settingsService: settingsService,
          speechService: SpeechService(),
          ttsService: TtsService(),
        )..add(ChatInitialized()),
        child: MaterialApp(
          title: 'Saru Bot',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const HomePage(),
        ),
      ),
    );
  }
}
