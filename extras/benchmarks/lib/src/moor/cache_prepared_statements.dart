import 'package:benchmarks/benchmarks.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: invalid_use_of_protected_member

const int _numQueries = 100000;

const Uuid uuid = Uuid();

Future<void> _runQueries(Database _db) async {
  // a query with a subquery so that the query planner takes some time
  const queryToBench = '''
SELECT * FROM key_values WHERE value IN (SELECT value FROM key_values WHERE value = ?);
''';

  final fs = <Future>[];
  
  for (var i = 0; i < _numQueries; i++) {
    fs.add(
      _db.customSelect(queryToBench, variables: [Variable(uuid.v4())]).get(),
    );
  }

  await Future.wait(fs);
}

class CachedPreparedStatements extends AsyncBenchmarkBase {
  final _db = Database(cachePreparedStatements: true);

  CachedPreparedStatements(ScoreEmitter emitter)
      : super('Running $_numQueries queries (cached prepared statements)',
            emitter);

  @override
  Future<void> setup() async {
    // Empty db so that we mostly bench the prepared statement time
  }

  @override
  Future<void> run() async {
    await _runQueries(_db);
  }
}

class NonCachedPreparedStatements extends AsyncBenchmarkBase {
  final _db = Database(cachePreparedStatements: false);

  NonCachedPreparedStatements(ScoreEmitter emitter)
      : super('Running $_numQueries queries (non-cached prepared statements)',
            emitter);

  @override
  Future<void> setup() async {
    // Empty db so that we mostly bench the prepared statement time
  }

  @override
  Future<void> run() async {
    await _runQueries(_db);
  }
}
