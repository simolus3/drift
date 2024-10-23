import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'details.dart';

class ClearDatabaseButton extends ConsumerStatefulWidget {
  const ClearDatabaseButton({super.key});

  @override
  ConsumerState<ClearDatabaseButton> createState() =>
      _ClearDatabaseButtonState();
}

class _ClearDatabaseButtonState extends ConsumerState<ClearDatabaseButton> {
  Future<void>? _pendingClear;

  @override
  Widget build(BuildContext context) {
    return DevToolsButton(
      onPressed: () {
        showDevToolsDialog(
          context: context,
          title: 'Confirm deletion',
          content: const Text(
            'This will delete contents of the database and then re-create it. '
            'All current database data will be lost. Continue?',
          ),
          actions: [
            DevToolsButton(
              onPressed: _pendingClear != null
                  ? null
                  : () {
                      setState(() {
                        _pendingClear = Future(() async {
                          final database = ref.read(loadedDatabase);
                          await database.value!.clear();
                        })
                            .whenComplete(
                                () => setState(() => _pendingClear = null))
                            .then((_) {
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.pop(context);
                          }
                        });
                      });
                    },
              label: 'Confirm deletion',
              color: Colors.redAccent,
            ),
          ],
        );
      },
      label: 'Clear database',
      color: Colors.redAccent,
      icon: Icons.delete,
    );
  }
}
