import 'package:drift_dev/src/writer/writer.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

import '../analysis/driver/driver.dart';
import '../analysis/options.dart';
import '../analysis/results/dart.dart';
import '../analysis/results/types.dart';
import '../utils/string_escaper.dart';

/// If the given [options] define custom SQL functions (via
/// [SqliteAnalysisOptions.knownFunctions]), this writer generates a typed API
/// to register these functions on a sqlite3 database provided by the `sqlite3`
/// package.
class FunctionStubsWriter {
  final DriftAnalysisDriver _driver;
  final TextEmitter _emitter;

  FunctionStubsWriter(this._driver, this._emitter);

  void write() {
    final functions = _driver.options.sqliteOptions?.knownFunctions ?? const {};
    if (functions.isEmpty) return;

    _emitter
      ..write('extension DefineFunctions on ')
      ..writeDart(_commonDatabase)
      ..writeln('{')
      ..write('void defineFunctions({');

    // Function parameters
    functions.forEach((key, value) {
      _emitter.write('required ');
      _writeFunctionTypeFor(value);
      _emitter
        ..write(_nameFor(key))
        ..write(', ');
    });
    _emitter.write('}) {');

    // Body of function: Call createFunction for each known function
    functions.forEach((key, value) {
      _emitter
        ..write('createFunction(')
        ..write('functionName: ${asDartLiteral(key)},')
        ..write('argumentCount: const ')
        ..writeDart(_allowedArgumentCount)
        ..write('(${value.argumentTypes.length}),')
        ..write('function: (args) {');
      _writeFunctionStub(key, value);
      _emitter
        ..write('},')
        ..write(');');
    });

    _emitter.writeln('}}');
  }

  String _nameFor(String sqlName) => ReCase(sqlName).camelCase;

  void _writeTypeFor(ResolvedType type) {
    final driftType = _driver.typeMapping.sqlTypeToDrift(type).builtin;

    _emitter.writeDart(AnnotatedDartCode([dartTypeNames[driftType]!]));
    if (type.nullable == true) {
      _emitter.write('?');
    }
  }

  void _writeFunctionTypeFor(KnownSqliteFunction function) {
    _writeTypeFor(function.returnType);
    _emitter.write(' Function(');

    var first = true;
    for (final type in function.argumentTypes) {
      if (!first) _emitter.write(', ');

      _writeTypeFor(type);
      first = false;
    }

    _emitter.write(')');
  }

  void _writeFunctionStub(String name, KnownSqliteFunction function) {
    for (var i = 0; i < function.argumentTypes.length; i++) {
      _emitter.write('final arg$i = args[$i] as ');
      _writeTypeFor(function.argumentTypes[i]);
      _emitter.write(';');
    }

    final allArgs =
        Iterable.generate(function.argumentTypes.length, (i) => 'arg$i')
            .join(', ');
    _emitter.write('return ${_nameFor(name)}($allArgs);');
  }

  static final _commonImport = Uri.parse('package:sqlite3/common.dart');
  static final _commonDatabase =
      AnnotatedDartCode.importedSymbol(_commonImport, 'CommonDatabase');
  static final _allowedArgumentCount =
      AnnotatedDartCode.importedSymbol(_commonImport, 'AllowedArgumentCount');
}
