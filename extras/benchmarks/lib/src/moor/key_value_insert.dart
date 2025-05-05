import 'package:benchmarks/benchmarks.dart';
import 'package:benchmarks/src/moor/cache_prepared_statements.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: invalid_use_of_protected_member

class KeyValueInsertBatch extends AsyncBenchmarkBase {
  static const int _size = 1000;
  final _db = Database();
  static const Uuid uuid = Uuid();

  KeyValueInsertBatch(ScoreEmitter emitter)
      : super('Inserting $_size entries (batch)', emitter);
  final keys = [];
  final values = [];

  @override
  Future<void> run() async {
    await _db.batch((batch) {
      for (var i = 0; i < _size; i++) {
        final key = uuid.v4();
        final value = uuid.v4();

        batch.insert(
            _db.keyValues, KeyValuesCompanion.insert(key: key, value: value));
      }
    });
  }

  @override
  Future<void> teardown() async {
    await _db.wipeAll();
    await _db.close();
  }
}

class KeyValueInsertSerial extends AsyncBenchmarkBase {
  static const int _size = 1000;

  final _db = Database();
  static const Uuid uuid = Uuid();

  KeyValueInsertSerial(ScoreEmitter emitter)
      : super('Inserting $_size entries (serial)', emitter);

  final keys = [];
  final values = [];

  @override
  Future<void> run() async {
    for (var i = 0; i < _size; i++) {
      final key = uuid.v4();
      final value = uuid.v4();

      await _db
          .into(_db.keyValues)
          .insert(KeyValuesCompanion.insert(key: key, value: value));
    }
  }

  @override
  Future<void> teardown() async {
    await _db.wipeAll();
    await _db.close();
  }
}

class KeyValueReads extends AsyncBenchmarkBase {
  static const int _size = 1000;

  final _db = Database();

  KeyValueReads(ScoreEmitter emitter)
      : super('Reading $_size entries', emitter);

  @override
  Future<void> setup() async {
    await _db.batch(
      (batch) {
        for (var i = 0; i < _size; i++) {
          final key = uuid.v4();
          final value = uuid.v4();

          batch.insert(
              _db.keyValues, KeyValuesCompanion.insert(key: key, value: value));
        }
      },
    );
  }

  @override
  Future<void> run() async {
    await _db.select(_db.keyValues).get();
  }

  @override
  Future<void> teardown() async {
    await _db.wipeAll();
    await _db.close();
  }
}

class KeyValueReadsBatch extends AsyncBenchmarkBase {
  static const int _size = 1000;

  final _db = Database();

  KeyValueReadsBatch(ScoreEmitter emitter)
      : super('Reading $_size entries (batches)', emitter);
  @override
  Future<void> setup() async {
    await _db.batch(
      (batch) {
        for (var i = 0; i < _size; i++) {
          final key = uuid.v4();
          final value = uuid.v4();

          batch.insert(
              _db.keyValues, KeyValuesCompanion.insert(key: key, value: value));
        }
      },
    );
  }

  @override
  Future<void> run() async {
    int offset = 0;
    final limit = 100;
    while (true) {
      final result =
          await (_db.select(_db.keyValues)..limit(limit, offset: offset)).get();
      if (result.isEmpty) {
        break;
      }
      offset += limit;
    }
  }

  @override
  Future<void> teardown() async {
    await _db.wipeAll();
    await _db.close();
  }
}

class KeyValueUpdate extends AsyncBenchmarkBase {
  static const int _size = 100;

  final _db = Database();

  KeyValueUpdate(ScoreEmitter emitter)
      : super('Updating $_size entries', emitter);

  final keys = [];

  @override
  Future<void> setup() async {
    await _db.batch(
      (batch) {
        for (var i = 0; i < _size; i++) {
          final key = uuid.v4();
          final value = uuid.v4();

          keys.add(key);

          batch.insert(
              _db.keyValues, KeyValuesCompanion.insert(key: key, value: value));
        }
      },
    );
  }

  @override
  Future<void> run() async {
    for (final (index, key) in [...keys].indexed) {
      final newKey = uuid.v4();
      await _db.update(_db.keyValues)
        ..where((tbl) => tbl.key.equals(key))
        ..write(KeyValuesCompanion(key: Value(newKey)));
      keys[index] = newKey;
    }
  }

  @override
  Future<void> teardown() async {
    await _db.wipeAll();

    await _db.close();
  }
}

class KeyValueReadStreams extends AsyncBenchmarkBase {
  static const int _size = 1000;

  final _db = Database();

  KeyValueReadStreams(ScoreEmitter emitter)
      : super('Reading $_size entries (streams)', emitter);
  final keys = [];
  @override
  Future<void> setup() async {
    await _db.batch(
      (batch) {
        for (var i = 0; i < _size; i++) {
          final key = uuid.v4();
          final value = uuid.v4();
          keys.add(key);
          batch.insert(
              _db.keyValues, KeyValuesCompanion.insert(key: key, value: value));
        }
      },
    );
  }

  @override
  Future<void> run() async {
    final stream = _db.select(_db.keyValues).watch();
    final subscription = stream.listen(
      (event) {},
    );
    for (var i = 0; i < 50; i++) {
      await _db
          .into(_db.keyValues)
          .insert(KeyValuesCompanion.insert(key: uuid.v4(), value: uuid.v4()));
      await Future.delayed(Duration.zero);
    }
    for (var i = 0; i < 50; i++) {
      await _db.delete(_db.keyValues)
        ..where((tbl) => tbl.key.equals(keys[i]));
      await Future.delayed(Duration.zero);
    }
    await subscription.cancel();
    await Future.delayed(Duration.zero);
  }

  @override
  Future<void> teardown() async {
    await _db.wipeAll();
    await _db.close();
  }
}
