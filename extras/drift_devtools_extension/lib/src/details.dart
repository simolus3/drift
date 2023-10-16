import 'package:devtools_app_shared/service.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vm_service/vm_service.dart';

import 'list.dart';
import 'remote_database.dart';
import 'service.dart';

final loadedDatabase = AutoDisposeFutureProvider((ref) async {
  final selected = ref.watch(selectedDatabase);
  final eval = await ref.watch(driftEvalProvider.future);

  final isAlive = Disposable();
  ref.onDispose(isAlive.dispose);

  if (selected?.database case InstanceRef dbRef) {
    final db = await eval.safeGetInstance(dbRef, isAlive);

    return await RemoteDatabase.resolve(db, eval, isAlive);
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
          return Scrollbar(
            controller: controller,
            child: ListView(
              controller: controller,
              children: [
                for (final entity in database.description.entities)
                  Text('${entity.name}: ${entity.type}'),
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
