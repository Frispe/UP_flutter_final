import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/server_state.dart';

class ServerBanner extends StatelessWidget {
  const ServerBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final server = context.watch<ServerState>();
    return Column(
      children: [
        if (!server.online)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    if (server.checking)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.cloud_off_outlined),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Сервер недоступен. Приложение восстановит данные после подключения.',
                      ),
                    ),
                    TextButton(
                      onPressed: server.checking ? null : server.checkNow,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
