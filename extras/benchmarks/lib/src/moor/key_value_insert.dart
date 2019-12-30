import 'package:benchmarks/benchmarks.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: invalid_use_of_protected_member

const int _size = 1000;

class KeyValueInsertBatch extends AsyncBenchmarkBase {
  final _db = Database();
  final Uuid uuid = Uuid();

  KeyValueInsertBatch(ScoreEmitter emitter)
      : super('Inserting $_size entries (batch)', emitter);

  @override
  Future<void> run() async {
    await _db.delete(_db.keyValues).go();

    await _db.batch((batch) {
      for (var i = 0; i < _size; i++) {
        final key = uuid.v4();
        final value = uuid.v4();

        batch.insert(
            _db.keyValues, KeyValuesCompanion.insert(key: key, value: value));
      }
    });
  }
}

class KeyValueInsertSerial extends AsyncBenchmarkBase {
  final _db = Database();
  final Uuid uuid = Uuid();

  KeyValueInsertSerial(ScoreEmitter emitter)
      : super('Inserting $_size entries (serial)', emitter);

  @override
  Future<void> run() async {
    await _db.delete(_db.keyValues).go();

    for (var i = 0; i < _size; i++) {
      final key = uuid.v4();
      final value = uuid.v4();

      await _db
          .into(_db.keyValues)
          .insert(KeyValuesCompanion.insert(key: key, value: value));
    }
  }
}
