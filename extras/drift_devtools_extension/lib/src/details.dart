import 'package:devtools_app_shared/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db_viewer/viewer.dart';
import 'list.dart';
import 'remote_database.dart';
import 'service.dart';

final loadedDatabase = AutoDisposeFutureProvider((ref) async {
  final selected = ref.watch(selectedDatabase);
  final eval = await ref.watch(driftEvalProvider.future);

  final isAlive = Disposable();
  ref.onDispose(isAlive.dispose);

  if (selected != null) {
    return await RemoteDatabase.resolve(selected, eval, isAlive);
  }

  return null;
});

class DatabaseDetails extends ConsumerStatefulWidget {
  const DatabaseDetails({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _DatabaseDetailsState();
  }
}

class _DatabaseDetailsState extends ConsumerState<DatabaseDetails> {
  final ScrollController controller = ScrollController();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(loadedDatabase);

    return database.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('unknown error: $err\n$stack'),
      data: (database) {
        if (database != null) {
          final textTheme = Theme.of(context).textTheme;

          return Scrollbar(
            controller: controller,
            child: ListView(
              controller: controller,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text('Database viewer', style: textTheme.headlineMedium),
                    ],
                  ),
                ),
                DatabaseViewer(database: database),
              ],
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
