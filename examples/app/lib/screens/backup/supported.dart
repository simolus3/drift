import 'dart:io';

import 'package:app/database/connection/native.dart';
import 'package:app/database/database.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class BackupIcon extends StatelessWidget {
  const BackupIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () =>
          showDialog(context: context, builder: (_) => const BackupDialog()),
      icon: const Icon(Icons.save),
      tooltip: 'Backup',
    );
  }
}

class BackupDialog extends ConsumerWidget {
  const BackupDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Database backup'),
      content: const Text(
        'Here, you can save the database to a file or restore a created '
        'backup.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            createDatabaseBackup(ref.read(AppDatabase.provider));
          },
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () async {
            final db = ref.read(AppDatabase.provider);
            await db.close();

            // Open the selected database file
            final backupFile = await FilePicker.pickFile();
            if (backupFile == null) return;
            final backupDb = sqlite3.open(backupFile.path!);

            // Vacuum it into a temporary location first to make sure it's working.
            final tempPath = await getTemporaryDirectory();
            final tempDb = p.join(tempPath.path, 'import.db');
            backupDb
              ..execute('VACUUM INTO ?', [tempDb])
              ..close();

            // Then replace the existing database file with it.
            final tempDbFile = File(tempDb);
            await tempDbFile.copy((await databaseFile).path);
            await tempDbFile.delete();

            // And now, re-open the database!
            ref.read(AppDatabase.provider.notifier).state = AppDatabase();
          },
          child: const Text('Restore'),
        ),
      ],
    );
  }
}

Future<void> createDatabaseBackup(DatabaseConnectionUser database) async {
  final temporary = await getTemporaryDirectory();
  if (!await temporary.exists()) {
    await temporary.create(recursive: true);
  }

  final directory = await temporary.createTemp('drift-backup');

  try {
    final file = p.join(directory.path, 'drift_example_backup.db');
    await database.customStatement('VACUUM INTO ?', [file]);

    await FilePicker.saveFile(
      fileName: 'drift_example_backup.db',
      bytes: await File(file).readAsBytes(),
    );
  } finally {
    await directory.delete(recursive: true);
  }
}
