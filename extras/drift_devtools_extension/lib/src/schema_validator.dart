import 'package:devtools_app_shared/ui.dart';
// ignore: implementation_imports
import 'package:drift_dev/src/services/schema/find_differences.dart';
// ignore: implementation_imports
import 'package:drift_dev/src/services/schema/verifier_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/wasm.dart' hide Row;
import 'package:url_launcher/url_launcher.dart';

import 'details.dart';
import 'remote_database.dart';
import 'service.dart';

sealed class SchemaStatus {}

final class DidNotValidateYet implements SchemaStatus {
  const DidNotValidateYet();
}

final class SchemaComparisonResult implements SchemaStatus {
  final bool schemaValid;
  final String message;

  SchemaComparisonResult({required this.schemaValid, required this.message});
}

final schemaStateProvider =
    AsyncNotifierProvider.autoDispose<SchemaVerifier, SchemaStatus>(
        SchemaVerifier._);

class SchemaVerifier extends AutoDisposeAsyncNotifier<SchemaStatus> {
  RemoteDatabase? _database;
  CommonSqlite3? _sqlite3;

  SchemaVerifier._();

  @override
  Future<SchemaStatus> build() async {
    _database = await ref.read(loadedDatabase.future);
    _sqlite3 = await ref.read(sqliteProvider.future);

    return const DidNotValidateYet();
  }

  Future<void> validate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<SchemaStatus>(() async {
      final database = _database!;

      final virtualTables = database.description.entities
          .where((e) => e.type == 'virtual_table')
          .map((e) => e.name)
          .toList();

      final expected = await _inputFromNewDatabase(virtualTables);
      final actual = <Input>[];

      for (final row in await database
          .select('SELECT name, sql FROM sqlite_schema;', [])) {
        final name = row['name'] as String;
        final sql = row['sql'] as String;

        if (!isInternalElement(name, virtualTables)) {
          actual.add(Input(name, sql));
        }
      }

      try {
        verify(expected, actual, true);
        return SchemaComparisonResult(
          schemaValid: true,
          message: 'The schema of the database matches its Dart and .drift '
              'definitions, meaning that migrations are likely correct.',
        );
      } on SchemaMismatch catch (e) {
        return SchemaComparisonResult(
          schemaValid: false,
          message: e.toString(),
        );
      }
    });
  }

  Future<List<Input>> _inputFromNewDatabase(List<String> virtuals) async {
    final expectedStatements = await _database!.createStatements;
    final newDatabase = _sqlite3!.openInMemory();
    final inputs = <Input>[];

    for (var statement in expectedStatements) {
      newDatabase.execute(statement);
    }

    for (final row
        in newDatabase.select('SELECT name, sql FROM sqlite_schema;', [])) {
      final name = row['name'] as String;
      final sql = row['sql'] as String;

      if (!isInternalElement(name, virtuals)) {
        inputs.add(Input(name, sql));
      }
    }

    newDatabase.dispose();
    return inputs;
  }
}

class DatabaseSchemaCheck extends ConsumerWidget {
  const DatabaseSchemaCheck({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schemaStateProvider);

    final description = switch (state) {
      AsyncData(
        value: SchemaComparisonResult(schemaValid: true, :var message)
      ) =>
        Text.rich(TextSpan(
          children: [
            const TextSpan(
                text: 'Success! ', style: TextStyle(color: Colors.green)),
            TextSpan(text: message),
          ],
        )),
      AsyncData(
        value: SchemaComparisonResult(schemaValid: false, :var message)
      ) =>
        Text.rich(TextSpan(
          children: [
            const TextSpan(
                text: 'Mismatch detected! ',
                style: TextStyle(color: Colors.red)),
            TextSpan(text: message),
          ],
        )),
      AsyncError(:var error) =>
        Text('The schema could not be validated due to an error: $error'),
      _ => Text.rich(TextSpan(
          text: 'By validating your schema, you can ensure that the current  '
              'state of the database in your app (after migrations ran) '
              'matches the expected state of tables as defined in your sources. ',
          children: [
            TextSpan(
              text: 'Learn more',
              style: const TextStyle(
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  await launchUrl(Uri.parse(
                      'https://drift.simonbinder.eu/docs/migrations/#verifying-a-database-schema-at-runtime'));
                },
            ),
          ],
        )),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: description,
        ),
        DevToolsButton(
          label: switch (state) {
            AsyncError() ||
            AsyncData(value: SchemaComparisonResult()) =>
              'Validate again',
            _ => 'Validate schema',
          },
          onPressed: () {
            if (state is! AsyncLoading) {
              ref.read(schemaStateProvider.notifier).validate();
            }
          },
        )
      ],
    );
  }
}
