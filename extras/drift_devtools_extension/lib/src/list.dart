import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/transformers.dart';
import 'package:vm_service/vm_service.dart';
import 'package:path/path.dart' as p;

import 'service.dart';

class TrackedDatabase {
  final int id;
  final InstanceRef database;

  TrackedDatabase({required this.id, required this.database});

  String get typeName => database.classRef!.name!;
}

final _databaseListChanged = AutoDisposeStreamProvider<void>((ref) {
  return Stream.fromFuture(ref.watch(serviceProvider.future))
      .switchMap((serviceProvider) {
    return serviceProvider.onExtensionEvent.where((event) {
      return event.extensionKind == 'drift:database-list-changed';
    });
  });
});

final databaseList =
    AutoDisposeFutureProvider<List<TrackedDatabase>>((ref) async {
  ref
    ..watch(hotRestartEventProvider)
    ..watch(_databaseListChanged);

  final isAlive = Disposable();
  ref.onDispose(isAlive.dispose);

  final eval = await ref.watch(driftEvalProvider.future);
  final resultsRefList =
      await eval.evalInstance('TrackedDatabase.all', isAlive: isAlive);

  return await Future.wait(
      resultsRefList.elements!.cast<InstanceRef>().map((trackedRef) async {
    final trackedDatabase = await eval.safeGetInstance(trackedRef, isAlive);

    final idField = trackedDatabase.fields!.firstWhere((f) => f.name == 'id');
    final databaseField =
        trackedDatabase.fields!.firstWhere((f) => f.name == 'database');

    final (id, database) = await (
      eval.safeGetInstance(idField.value, isAlive),
      eval.safeGetInstance(databaseField.value, isAlive)
    ).wait;

    return TrackedDatabase(
      id: int.parse(id.valueAsString!),
      database: database,
    );
  }));
});

final selectedDatabase = AutoDisposeStateNotifierProvider<
    StateController<TrackedDatabase?>, TrackedDatabase?>((ref) {
  final controller = StateController<TrackedDatabase?>(null);

  ref.listen(
    databaseList,
    (previous, next) {
      final databases = next.asData?.value ?? const [];

      if (databases.isEmpty) {
        controller.state = null;
      } else if (controller.state == null &&
          databases.every((e) => e.id != controller.state?.id)) {
        controller.state = databases.first;
      }
    },
    fireImmediately: true,
  );
  return controller;
});

class DatabaseList extends ConsumerStatefulWidget {
  const DatabaseList({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _DatabaseListState();
  }
}

class _DatabaseListState extends ConsumerState<DatabaseList> {
  static const _tilePadding = EdgeInsets.only(
    left: defaultSpacing,
    right: densePadding,
    top: densePadding,
    bottom: densePadding,
  );

  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final databases = ref.watch(databaseList);

    return databases.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Padding(
        padding: _tilePadding,
        child: Text('Could not load databases: $err\n$stack'),
      ),
      data: (databases) {
        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: ListView(
            primary: false,
            controller: scrollController,
            children: [
              for (final db in databases) _DatabaseEntry(database: db),
            ],
          ),
        );
      },
    );
  }
}

class _DatabaseEntry extends ConsumerWidget {
  final TrackedDatabase database;

  const _DatabaseEntry({super.key, required this.database});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(selectedDatabase)?.id == database.id;
    final colorScheme = Theme.of(context).colorScheme;

    String? fileName;
    int? lineNumber;

    if (database.database.classRef?.location case SourceLocation sl) {
      final uri = sl.script?.uri;
      if (uri != null) {
        fileName = p.url.basename(uri);
      }
      lineNumber = sl.line;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(selectedDatabase.notifier).state = database;
      },
      child: Container(
        color: isSelected ? colorScheme.selectedRowBackgroundColor : null,
        padding: _DatabaseListState._tilePadding,
        child: ListTile(
          title: Text(database.typeName),
          subtitle: fileName != null && lineNumber != null
              ? Text('$fileName:$lineNumber')
              : null,
        ),
      ),
    );
  }
}
