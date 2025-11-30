import 'package:sqlparser/src/analysis/types/types.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/engine/sql_engine.dart';

import '../../analysis/analysis.dart';
import 'module.dart';

/// Provides static analysis support for the [PowerSync SQLite core extension].
///
/// This provides the `powersync_crud` eponymous virtual table to store local
/// mutation as well as some JSON / UUID helper functions.
///
/// [PowerSync SQLite core extension]: https://github.com/powersync-ja/powersync-sqlite-core/
final class PowerSyncSqliteExtension implements Extension {
  const PowerSyncSqliteExtension();

  @override
  void register(SqlEngine engine) {
    engine
      ..registerTable(_powersyncCrudLegacy)
      ..registerTable(_powersyncCrud)
      ..registerFunctionHandler(const _PowerSyncFunctionHandler());
  }
}

final class _PowerSyncFunctionHandler implements FunctionHandler {
  const _PowerSyncFunctionHandler();

  @override
  Set<String> get functionNames => {
        'powersync_diff', // (TEXT, TEXT) -> TEXT
        'powersync_client_id', // () -> TEXT
        'powersync_in_sync_operation', // () -> BOOLEAN
        'gen_random_uuid', // () -> TEXT
        'uuid', // () -> TEXT
      };

  @override
  ResolveResult inferArgumentType(
      TypeInferenceSession session, SqlInvocation call, Expression argument) {
    switch (call.name.toLowerCase()) {
      case 'powersync_diff':
        return ResolveResult(_text);
      default:
        return ResolveResult.unknown();
    }
  }

  @override
  ResolveResult inferReturnType(TypeInferenceSession session,
      SqlInvocation call, List<Typeable> expandedArgs) {
    switch (call.name.toLowerCase()) {
      case 'powersync_diff':
      case 'powersync_client_id':
      case 'gen_random_uuid':
      case 'uuid':
        return const ResolveResult(_text);
      case 'powersync_in_sync_operation':
        return const ResolveResult(ResolvedType.bool());
      default:
        return ResolveResult.unknown();
    }
  }

  @override
  void reportErrors(SqlInvocation call, AnalysisContext context) {}
}

/// `CREATE TABLE powersync_crud_(data TEXT, options INT HIDDEN);`
///
/// Source: https://github.com/powersync-ja/powersync-sqlite-core/blob/637fda0f1d84c46964736a4f8c59fab5ae27e304/crates/core/src/crud_vtab.rs#L26
Table get _powersyncCrudLegacy {
  return Table(name: 'powersync_crud', isVirtual: true, resolvedColumns: [
    TableColumn('data', _text),
    TableColumn('options', _int, isHidden: true),
  ]);
}

/// `CREATE TABLE powersync_crud(op TEXT, id TEXT, type TEXT, data TEXT, old_values TEXT, metadata TEXT, options INT HIDDEN);`
///
/// Source: https://github.com/powersync-ja/powersync-sqlite-core/blob/637fda0f1d84c46964736a4f8c59fab5ae27e304/crates/core/src/crud_vtab.rs#L27C6-L27C126
Table get _powersyncCrud {
  return Table(name: 'powersync_crud', isVirtual: true, resolvedColumns: [
    TableColumn('op', _text),
    TableColumn('id', _text),
    TableColumn('type', _text),
    TableColumn('data', _text),
    TableColumn('old_values', _text),
    TableColumn('metadata', _text),
    TableColumn('options', _int, isHidden: true),
  ]);
}

const _text = ResolvedType(type: BasicType.text);
const _int = ResolvedType(type: BasicType.int);
