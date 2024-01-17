import 'package:sqlparser/sqlparser.dart';

class Json1Extension implements Extension {
  const Json1Extension();

  @override
  void register(SqlEngine engine) {
    final supportsJsonb = engine.options.version >= SqliteVersion.v3_45;

    engine
      ..registerFunctionHandler(_Json1Functions(supportsJsonb))
      ..registerTableValuedFunctionHandler(const _JsonEachFunction())
      ..registerTableValuedFunctionHandler(const _JsonTreeFunction());
  }
}

class _Json1Functions implements FunctionHandler {
  final bool _supportBinaryJson;

  const _Json1Functions(this._supportBinaryJson);

  static const Set<String> _returnStrings = {
    'json',
    'json_array',
    'json_insert',
    'json_replace',
    'json_set',
    'json_object',
    'json_patch',
    'json_remove',
    'json_quote',
    'json_group_array',
    'json_group_object',
  };

  static const Set<String> _returnBlobs = {
    'jsonb',
    'jsonb_array',
    'jsonb_insert',
    'jsonb_object',
    'jsonb_patch',
    'jsonb_remove',
    'jsonb_replace',
    'jsonb_set',
    'jsonb_group_array',
    'jsonb_group_object'
  };

  @override
  Set<String> get functionNames => {
        ..._returnStrings,
        if (_supportBinaryJson) ..._returnBlobs,
        'json_type',
        'json_valid',
        'json_extract',
        if (_supportBinaryJson) 'jsonb_extract',
        'json_array_length',
      };

  @override
  ResolveResult inferArgumentType(
      AnalysisContext context, SqlInvocation call, Expression argument) {
    return const ResolveResult.unknown();
  }

  @override
  ResolveResult inferReturnType(AnalysisContext context, SqlInvocation call,
      List<Typeable> expandedArgs) {
    final name = call.name.toLowerCase();

    if (_returnStrings.contains(name)) {
      return const ResolveResult(ResolvedType(type: BasicType.text));
    } else if (_returnBlobs.contains(name)) {
      return const ResolveResult(ResolvedType(type: BasicType.blob));
    } else {
      switch (name) {
        case 'json_type':
          return const ResolveResult(
              ResolvedType(type: BasicType.text, nullable: true));
        case 'json_valid':
          return const ResolveResult(ResolvedType.bool());
        case 'json_extract':
        case 'jsonb_extract':
          return const ResolveResult.unknown();
        case 'json_array_length':
          return const ResolveResult(ResolvedType(type: BasicType.int));
      }
    }

    throw AssertionError("Can't happen, unknown json1 function");
  }

  @override
  void reportErrors(SqlInvocation call, AnalysisContext context) {}
}

final _jsonFunctionResultSet = CustomResultSet([
  // https://www.sqlite.org/json1.html#the_json_each_and_json_tree_table_valued_functions
  // we use string for any
  TableColumn('key', const ResolvedType(type: BasicType.text)),
  TableColumn(
      'value', const ResolvedType(type: BasicType.text, nullable: true)),
  TableColumn('type', const ResolvedType(type: BasicType.text)),
  TableColumn('atom', const ResolvedType(type: BasicType.text)),
  TableColumn('type', const ResolvedType(type: BasicType.text)),
  TableColumn('id', const ResolvedType(type: BasicType.int)),
  TableColumn(
      'parent', const ResolvedType(type: BasicType.int, nullable: true)),
  TableColumn('fullkey', const ResolvedType(type: BasicType.text)),
]);

abstract class _JsonTableValuedFunction implements TableValuedFunctionHandler {
  const _JsonTableValuedFunction();

  @override
  ResultSet resolveTableValued(
      AnalysisContext context, TableValuedFunction call) {
    return _jsonFunctionResultSet;
  }
}

class _JsonEachFunction extends _JsonTableValuedFunction {
  const _JsonEachFunction();

  @override
  String get functionName => 'json_each';
}

class _JsonTreeFunction extends _JsonTableValuedFunction {
  const _JsonTreeFunction();

  @override
  String get functionName => 'json_tree';
}
