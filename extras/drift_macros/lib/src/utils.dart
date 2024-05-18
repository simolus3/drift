import 'package:drift/src/macro_helper.dart';
import 'package:macros/macros.dart';

import 'model/column.dart';

final class DriftImports {
  static final _drift = Uri.parse('package:drift/src/macro_helper.dart');
  static final _core = Uri.parse('dart:core');
  static final _async = Uri.parse('dart:async');
  static final _typedData = Uri.parse('dart:typed_data');

  final TypePhaseIntrospector _introspector;
  final Map<String, Identifier> _resolvedDrift = {};
  final Map<String, Identifier> _resolvedDartCore = {};
  final Map<String, Identifier> _resolvedDartAsync = {};

  DriftImports(this._introspector);

  Future<Identifier> fromDartCore(String name) async {
    return _resolvedDartCore[name] ??=
        // ignore: deprecated_member_use
        await _introspector.resolveIdentifier(_core, name);
  }

  Future<Identifier> fromDartAsync(String name) async {
    return _resolvedDartAsync[name] ??=
        // ignore: deprecated_member_use
        await _introspector.resolveIdentifier(_async, name);
  }

  Future<Identifier> fromDrift(String name) async {
    return _resolvedDrift[name] ??=
        // ignore: deprecated_member_use
        await _introspector.resolveIdentifier(_drift, name);
  }

  Future<T> buildCode<T extends Code>(
    T Function(List<Object>) fromParts,
    Future<void> Function(CodeBuilder builder) build,
  ) async {
    final builder = CodeBuilder(this);
    await build(builder);
    return fromParts(builder._parts);
  }
}

final class CodeBuilder {
  final List<Object> _parts = [];
  final DriftImports _drift;

  CodeBuilder(this._drift);

  void part(Object part) {
    _parts.add(part);
  }

  void line(String part) {
    _parts.add('$part\n');
  }

  Future<void> dartCoreImport(String name) async {
    _parts.add(await _drift.fromDartCore(name));
  }

  Future<void> dartAsyncImport(String name) async {
    _parts.add(await _drift.fromDartAsync(name));
  }

  Future<void> driftImport(String name) async {
    _parts.add(await _drift.fromDrift(name));
  }

  Future<void> dartSqlType(ColumnType type) async {
    switch (type) {
      case ColumnDriftType(builtin: DriftSqlType.int):
        await dartCoreImport('int');
      case ColumnDriftType(builtin: DriftSqlType.bigInt):
        await dartCoreImport('BigInt');
      case ColumnDriftType(builtin: DriftSqlType.bool):
        await dartCoreImport('bool');
      case ColumnDriftType(builtin: DriftSqlType.string):
        await dartCoreImport('String');
      case ColumnDriftType(builtin: DriftSqlType.double):
        await dartCoreImport('double');
      case ColumnDriftType(builtin: DriftSqlType.blob):
        final identifier = await _drift._introspector
            // ignore: deprecated_member_use
            .resolveIdentifier(DriftImports._typedData, 'Uint8List');
        _parts.add(identifier);
      case ColumnDriftType(builtin: DriftSqlType.dateTime):
        await dartCoreImport('DateTime');
      case ColumnDriftType(builtin: DriftSqlType.any):
        await driftImport('DriftAny');
      case ColumnCustomType(:final dartType):
        _parts.add(dartType.code);
    }
  }

  Future<void> sqlTypeExpression(ColumnType type) async {
    switch (type) {
      case ColumnDriftType(:final builtin):
        await driftImport('DriftSqlType');
        part('.${builtin.name}');
      case ColumnCustomType(:final expression):
        part(expression);
    }
  }
}
