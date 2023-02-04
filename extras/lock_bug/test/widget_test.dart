import 'package:drift/native.dart';
import 'package:drift_lock_bug/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError();
});

final myFutureProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);

  await db.customSelect("SELECT 1").get();

  return 1;
});

void main() {
  testWidgets("deadlock test", (tester) async {
    final db = Database.executor(
      NativeDatabase.memory(logStatements: true),
    );

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );

    addTearDown(() async {
      print("closing db");
      await db.close();
      print("db closed");
      container.dispose();
      print("finish teardown");
    });

    final widget = UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final dbRes = ref.watch(myFutureProvider);
          print("db result $dbRes");

          return const SizedBox();
        },
      ),
    );

    await tester.pumpWidget(widget);
  });
}
