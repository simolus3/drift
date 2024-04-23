import 'package:sqlparser/src/analysis/analysis.dart';
import 'package:sqlparser/src/ast/ast.dart';
import 'package:sqlparser/src/engine/module/module.dart';
import 'package:sqlparser/src/engine/sql_engine.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

final class GeopolyExtension implements Extension {
  const GeopolyExtension();

  @override
  void register(SqlEngine engine) {
    engine
      ..registerModule(_GeopolyModule(engine))
      ..registerFunctionHandler(_GeopolyFunctionHandler());
  }
}

const String _shapeKeyword = '_shape';
const ResolvedType _typePolygon = ResolvedType(
  type: BasicType.blob,
  nullable: true,
  hints: [
    IsGeopolyPolygon(),
  ],
);

final class _GeopolyModule extends Module {
  _GeopolyModule(this.engine) : super('geopoly');

  final SqlEngine engine;

  @override
  Table parseTable(CreateVirtualTableStatement stmt) {
    final resolvedColumns = <TableColumn>[
      RowId(),
      TableColumn(
        _shapeKeyword,
        _typePolygon,
      ),
    ];

    for (final column in stmt.argumentContent) {
      final tokens = engine.tokenize(column);

      final String resolvedName;
      final ResolvedType resolvedType;
      switch (tokens) {
        // geoID INTEGER not null
        case [final name, final type, final not, final $null, final eof]
            when name.type == TokenType.identifier &&
                type.type == TokenType.identifier &&
                not.type == TokenType.not &&
                $null.type == TokenType.$null &&
                eof.type == TokenType.eof:
          resolvedName = name.lexeme;
          resolvedType = engine.schemaReader
              .resolveColumnType(type.lexeme)
              .withNullable(false);
        // a INTEGER
        case [final name, final type, final eof]
            when name.type == TokenType.identifier &&
                type.type == TokenType.identifier &&
                eof.type == TokenType.eof:
          resolvedName = name.lexeme;
          resolvedType = engine.schemaReader
              .resolveColumnType(type.lexeme)
              .withNullable(true);
        // b
        case [final name, final eof]
            when name.type == TokenType.identifier && eof.type == TokenType.eof:
          resolvedName = name.lexeme;
          resolvedType = const ResolvedType(
            type: BasicType.any,
            nullable: true,
          );
        // ?
        default:
          throw ArgumentError('Can\'t be parsed', column);
      }

      resolvedColumns.add(
        TableColumn(
          resolvedName,
          resolvedType,
        ),
      );
    }

    return Table(
      name: stmt.tableName,
      resolvedColumns: resolvedColumns,
      definition: stmt,
      isVirtual: true,
    );
  }
}

final class _GeopolyFunctionHandler extends FunctionHandler {
  @override
  Set<String> get functionNames => {
        for (final value in _GeopolyFunctions.values) value.sqlName,
      };

  @override
  ResolveResult inferArgumentType(
    AnalysisContext context,
    SqlInvocation call,
    Expression argument,
  ) {
    // TODO(nikitadol): Copy from `_Fts5Functions`. Must be removed when argument index appears
    int? argumentIndex;
    if (call.parameters is ExprFunctionParameters) {
      argumentIndex = (call.parameters as ExprFunctionParameters)
          .parameters
          .indexOf(argument);
    }
    if (argumentIndex == null || argumentIndex < 0) {
      // couldn't find expression in arguments, so we don't know the type
      return const ResolveResult.unknown();
    }
    //

    final func = _GeopolyFunctions.bySqlName(call.name);

    if (argumentIndex < func.args.length) {
      return ResolveResult(func.args[argumentIndex]);
    } else if (func.otherArgs != null) {
      return ResolveResult(func.otherArgs);
    } else {
      return ResolveResult.unknown();
    }
  }

  @override
  ResolveResult inferReturnType(
    AnalysisContext context,
    SqlInvocation call,
    List<Typeable> expandedArgs,
  ) {
    final func = _GeopolyFunctions.bySqlName(call.name);

    if (expandedArgs.length == func.args.length) {
      // ok
    } else if (expandedArgs.length > func.args.length &&
        func.otherArgs != null) {
      // ok
    } else {
      final buffer = StringBuffer(
        'The function `${func.sqlName}` takes ',
      );

      buffer.write('${func.args.length} ');

      switch (func.args.length) {
        case 1:
          buffer.write('argument');
        case > 1:
          buffer.write('arguments');
      }

      if (func.otherArgs != null) {
        buffer.write(' (or more)');
      }

      buffer.write(' but ${expandedArgs.length} ');

      switch (expandedArgs.length) {
        case 1:
          buffer.write('argument is');
        case > 1:
          buffer.write('arguments are');
      }
      buffer.write('passed');

      throw ArgumentError(buffer);
    }

    return ResolveResult(
      func.returnType,
    );
  }
}

const _typeInt = ResolvedType(
  type: BasicType.int,
  nullable: true,
);

const _typeReal = ResolvedType(
  type: BasicType.real,
  nullable: true,
);

const _typeBlob = ResolvedType(
  type: BasicType.blob,
  nullable: true,
);

const _typeText = ResolvedType(
  type: BasicType.text,
  nullable: true,
);

enum _GeopolyFunctions {
  overlap(
    'geopoly_overlap',
    _typeInt,
    [_typePolygon, _typePolygon],
  ),
  within(
    'geopoly_within',
    _typeInt,
    [_typePolygon, _typePolygon],
  ),
  area(
    'geopoly_area',
    _typeReal,
    [_typePolygon],
  ),
  blob(
    'geopoly_blob',
    _typeBlob,
    [_typePolygon],
  ),
  json(
    'geopoly_json',
    _typeText,
    [_typePolygon],
  ),
  svg(
    'geopoly_svg',
    _typeText,
    [_typePolygon],
    _typeText,
  ),
  bbox(
    'geopoly_bbox',
    _typeBlob,
    [_typePolygon],
  ),
  groupBbox(
    'geopoly_group_bbox',
    _typeBlob,
    [_typePolygon],
  ),
  containsPoint(
    'geopoly_contains_point',
    _typeInt,
    [_typePolygon, _typeInt, _typeInt],
  ),
  xform(
    'geopoly_xform',
    _typeBlob,
    [
      _typePolygon,
      _typeReal,
      _typeReal,
      _typeReal,
      _typeReal,
      _typeReal,
      _typeReal
    ],
  ),
  regular(
    'geopoly_regular',
    _typeBlob,
    [_typeReal, _typeReal, _typeReal, _typeInt],
  ),
  ccw(
    'geopoly_ccw',
    _typeBlob,
    [_typePolygon],
  );

  final String sqlName;
  final ResolvedType returnType;
  final List<ResolvedType> args;
  final ResolvedType? otherArgs;

  const _GeopolyFunctions(
    this.sqlName,
    this.returnType,
    this.args, [
    this.otherArgs,
  ]);

  factory _GeopolyFunctions.bySqlName(String sqlName) {
    return _GeopolyFunctions.values.firstWhere(
        (element) => element.sqlName == sqlName,
        orElse: () => throw ArgumentError('$sqlName not exists'));
  }
}
