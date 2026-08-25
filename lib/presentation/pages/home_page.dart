import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/message_bubble.dart';
import '../widgets/settings_dialog.dart';

/// Main screen: live chat stream + central glowing audio orb.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            const Text('SARU BOT'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => showSettingsDialog(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (ChatState prev, ChatState next) =>
                    prev.messages != next.messages ||
                    prev.error != next.error ||
                    prev.hasApiKey != next.hasApiKey,
                builder: (BuildContext context, ChatState state) {
                  return _MessageList(state: state);
                },
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (BuildContext context, ChatState state) {
                return Column(
                  children: <Widget>[
                    GlowingOrb(
                      status: state.status,
                      onTap: () =>
                          context.read<ChatBloc>().add(const MicToggled()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusHint(state.status),
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.4,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            const _Composer(),
          ],
        ),
      ),
    );
  }

  static String _statusHint(ChatStatus status) {
    switch (status) {
      case ChatStatus.listening:
        return 'Listening… tap to stop';
      case ChatStatus.processing:
        return 'Thinking…';
      case ChatStatus.speaking:
        return 'Speaking…';
      case ChatStatus.idle:
      case ChatStatus.loading:
        return 'Tap the orb and just speak';
    }
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) => ListView(
        reverse: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _buildChildren(context).reversed.toList(),
      );

  List<Widget> _buildChildren(BuildContext context) {
    final List<Widget> children = <Widget>[];

    // Graceful, non-blocking API key onboarding banner.
    if (!state.hasApiKey) {
      children.add(_ApiKeyBanner(onTap: () => showSettingsDialog(context)));
    }

    if (state.error != null) {
      children.add(_ErrorBanner(message: state.error!));
    }

    for (final ChatMessage message in state.messages) {
      children.add(MessageBubble(message: message));
    }

    if (state.messages.isEmpty && state.hasApiKey && state.error == null) {
      children.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: <Widget>[
                Icon(Icons.waving_hand_rounded, size: 40, color: Colors.grey.shade600),
                const SizedBox(height: 12),
                Text(
                  'Say hello to Saru Bot!\nTap the orb below to start talking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return children;
  }
}

class _ApiKeyBanner extends StatelessWidget {
  const _ApiKeyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Icon(Icons.key_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap here to add your Gemini API key and bring '
                    'Saru Bot to life.',
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.red.shade700.withValues(alpha: 0.5)),
        ),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent),
          title: Text(message, style: const TextStyle(fontSize: 13)),
          trailing: IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () =>
                context.read<ChatBloc>().add(const ErrorDismissed()),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(UserMessageSubmitted(text));
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (ChatState prev, ChatState next) => prev.isBusy != next.isBusy,
      builder: (BuildContext context, ChatState state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  enabled: !state.isBusy,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '…or type a message',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(26),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black87,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 20),
                  onPressed: state.isBusy ? null : _submit,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

