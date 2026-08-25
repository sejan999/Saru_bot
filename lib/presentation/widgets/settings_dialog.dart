import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';

/// Shows a non-blocking dialog where the user pastes their Gemini API key.
/// Saving dispatches [ApiKeySaveRequested]; the key persists locally via
/// SharedPreferences.
Future<void> showSettingsDialog(BuildContext context) async {
  final ChatBloc bloc = context.read<ChatBloc>();
  final TextEditingController controller = TextEditingController();

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(Icons.vpn_key_rounded, color: Theme.of(dialogContext).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('Gemini API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Paste your Google Gemini API key below. It is stored only on '
              'this device.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'AIza...',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: controller.clear,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get a free key at aistudio.google.com/apikey',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              bloc.add(ApiKeySaveRequested(controller.text.trim()));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    controller.text.trim().isEmpty
                        ? 'API key cleared.'
                        : 'API key saved — Saru Bot is ready!',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
        ],
      );
    },
  );

  controller.dispose();
}
