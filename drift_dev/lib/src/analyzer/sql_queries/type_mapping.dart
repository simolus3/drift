import 'package:drift/drift.dart' as m;
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/utils/type_converter_hint.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/find_referenced_tables.dart' as s;

import '../options.dart';
import 'required_variables.dart';

/// Converts tables and types between the moor_generator and the sqlparser
/// library.
class TypeMapper {
  final Map<Table, DriftTable> _engineTablesToSpecified = {};
  final Map<View, MoorView> _engineViewsToSpecified = {};

  final DriftOptions options;

  TypeMapper({required this.options});

  /// Convert a [DriftTable] from this package into something that can be
  /// understood by the sqlparser library.
  Table extractStructure(DriftTable table) {
    if (table.parserTable != null) {
      final parserTbl = table.parserTable!;
      _engineTablesToSpecified[parserTbl] = table;
      return parserTbl;
    }

    final columns = <TableColumn>[];
    for (final specified in table.columns) {
      final hint = specified.typeConverter != null
          ? TypeConverterHint(specified.typeConverter!)
          : null;
      final type = resolveForColumnType(specified.type, overrideHint: hint)
          .withNullable(specified.nullable);

      final column = TableColumn(specified.name.name, type,
          isGenerated: specified.isGenerated);
      column.setMeta<DriftColumn>(specified);

      columns.add(column);
    }

    final engineTable = Table(
      name: table.sqlName,
      resolvedColumns: columns,
      isVirtual: table.isVirtualTable,
    );
    engineTable.setMeta<DriftTable>(table);
    _engineTablesToSpecified[engineTable] = table;
    return engineTable;
  }

  ResolvedType resolveForColumnType(DriftSqlType type,
      {TypeHint? overrideHint}) {
    switch (type) {
      case DriftSqlType.int:
        return ResolvedType(type: BasicType.int, hint: overrideHint);
      case DriftSqlType.bigInt:
        return ResolvedType(
            type: BasicType.int, hint: overrideHint ?? const IsBigInt());
      case DriftSqlType.string:
        return ResolvedType(type: BasicType.text, hint: overrideHint);
      case DriftSqlType.bool:
        return ResolvedType(
            type: BasicType.int, hint: overrideHint ?? const IsBoolean());
      case DriftSqlType.dateTime:
        return ResolvedType(
          type: options.storeDateTimeValuesAsText
              ? BasicType.text
              : BasicType.int,
          hint: overrideHint ?? const IsDateTime(),
        );
      case DriftSqlType.blob:
        return ResolvedType(type: BasicType.blob, hint: overrideHint);
      case DriftSqlType.double:
        return ResolvedType(type: BasicType.real, hint: overrideHint);
    }
  }

  DriftSqlType resolvedToMoor(ResolvedType? type) {
    if (type == null) {
      return DriftSqlType.string;
    }

    switch (type.type) {
      case null:
      case BasicType.nullType:
        return DriftSqlType.string;
      case BasicType.int:
        if (type.hint is IsBoolean) {
          return DriftSqlType.bool;
        } else if (!options.storeDateTimeValuesAsText &&
            type.hint is IsDateTime) {
          return DriftSqlType.dateTime;
        } else if (type.hint is IsBigInt) {
          return DriftSqlType.bigInt;
        }
        return DriftSqlType.int;
      case BasicType.real:
        return DriftSqlType.double;
      case BasicType.text:
        if (options.storeDateTimeValuesAsText && type.hint is IsDateTime) {
          return DriftSqlType.dateTime;
        }

        return DriftSqlType.string;
      case BasicType.blob:
        return DriftSqlType.blob;
    }
  }

  /// Converts a [MoorView] into something that can be understood
  /// by the sqlparser library.
  View extractView(MoorView view) {
    if (view.parserView != null) {
      final parserView = view.parserView!;
      _engineViewsToSpecified[parserView] = view;
      return parserView;
    }
    final engineView = View(name: view.name, resolvedColumns: []);
    engineView.setMeta<MoorView>(view);
    _engineViewsToSpecified[engineView] = view;
    return engineView;
  }

  /// Extracts variables and Dart templates from the AST tree starting at
  /// [root], but nested queries are excluded. Variables are sorted by their
  /// ascending index. Placeholders are sorted by the position they have in the
  /// query. When comparing variables and placeholders, the variable comes first
  /// if the first variable with the same index appears before the placeholder.
  ///
  /// Additionally, the following assumptions can be made if this method returns
  /// without throwing:
  ///  - array variables don't have an explicit index
  ///  - if an explicitly indexed variable appears AFTER an array variable or
  ///    a Dart placeholder, its indexed is LOWER than that element. This means
  ///    that elements can be expanded into multiple variables without breaking
  ///    variables that appear after them.
  List<FoundElement> extractElements({
    required AnalysisContext ctx,
    required AstNode root,
    NestedQueriesContainer? nestedScope,
    RequiredVariables required = RequiredVariables.empty,
  }) {
    final collector = _FindElements()..visit(root, nestedScope);

    // this contains variable references. For instance, SELECT :a = :a would
    // contain two entries, both referring to the same variable. To do that,
    // we use the fact that each variable has a unique index.
    final variables = collector.variables;
    final placeholders = collector.dartPlaceholders;

    final merged = _mergeVarsAndPlaceholders(variables, placeholders);

    final foundElements = <FoundElement>[];
    // we don't allow variables with an explicit index after an array. For
    // instance: SELECT * FROM t WHERE id IN ? OR id = ?2. The reason this is
    // not allowed is that we expand the first arg into multiple vars at runtime
    // which would break the index. The initial high values can be arbitrary.
    // We've chosen 999 because most sqlite binaries don't allow more variables.
    var maxIndex = 999;
    var currentIndex = 0;

    for (final used in merged) {
      if (used is Variable) {
        if (used.resolvedIndex == currentIndex) {
          continue; // already handled, we only report a single variable / index
        }

        currentIndex = used.resolvedIndex!;
        final name = (used is ColonNamedVariable) ? used.name : null;
        final explicitIndex =
            (used is NumberedVariable) ? used.explicitIndex : null;
        final forCapture = used.meta<CapturedVariable>();

        final internalType =
            // If this variable was introduced to replace a reference from a
            // `LIST` query to an outer query, use the type of the reference
            // instead of the synthetic variable that we're replacing it with.
            ctx.typeOf(forCapture != null ? forCapture.reference : used);
        final type = resolvedToMoor(internalType.type);

        if (forCapture != null) {
          foundElements.add(FoundVariable.nestedQuery(
            index: currentIndex,
            name: name,
            type: type,
            variable: used,
            forCaptured: forCapture,
          ));

          continue;
        }

        final isArray = internalType.type?.isArray ?? false;
        final isRequired = required.requiredNamedVariables.contains(name) ||
            required.requiredNumberedVariables.contains(used.resolvedIndex);

        if (explicitIndex != null && currentIndex >= maxIndex) {
          throw ArgumentError(
              'Cannot have a variable with an index lower than that of an '
              'array appearing after an array!');
        }

        UsedTypeConverter? converter;

        // Recognizing type converters on variables is opt-in since it would
        // break existing code.
        if (options.applyConvertersOnVariables &&
            internalType.type?.hint is TypeConverterHint) {
          converter = (internalType.type!.hint as TypeConverterHint).converter;
        }

        foundElements.add(FoundVariable(
          index: currentIndex,
          name: name,
          type: type,
          nullable: internalType.type?.nullable ?? false,
          variable: used,
          isArray: isArray,
          typeConverter: converter,
          isRequired: isRequired,
        ));

        // arrays cannot be indexed explicitly because they're expanded into
        // multiple variables when executed
        if (isArray && explicitIndex != null) {
          throw ArgumentError(
              'Cannot use an array variable with an explicit index');
        }
        if (isArray) {
          maxIndex = used.resolvedIndex!;
        }
      } else if (used is DartPlaceholder) {
        // we don't what index this placeholder has, so we can't allow _any_
        // explicitly indexed variables coming after this
        maxIndex = 0;
        foundElements.add(_extractPlaceholder(ctx, used));
      }
    }
    return foundElements;
  }

  /// Merges [vars] and [placeholders] into a list that satisfies the order
  /// described in [extractElements].
  List<dynamic /* Variable|DartPlaceholder */ > _mergeVarsAndPlaceholders(
      List<Variable> vars, List<DartPlaceholder> placeholders) {
    final groupVarsByIndex = <int, List<Variable>>{};
    for (final variable in vars) {
      groupVarsByIndex
          .putIfAbsent(variable.resolvedIndex!, () => [])
          .add(variable);
    }
    // sort each group by index
    for (final group in groupVarsByIndex.values) {
      group.sort((a, b) => a.resolvedIndex!.compareTo(b.resolvedIndex!));
    }

    late int Function(dynamic, dynamic) comparer;
    comparer = (dynamic a, dynamic b) {
      if (a is Variable && b is Variable) {
        // variables are sorted by their index
        return a.resolvedIndex!.compareTo(b.resolvedIndex!);
      } else if (a is DartPlaceholder && b is DartPlaceholder) {
        // placeholders by their position
        return AnalysisContext.compareNodesByOrder(a, b);
      } else {
        // ok, one of them is a variable, the other one is a placeholder. Let's
        // assume a is the variable. If not, we just switch results.
        if (a is Variable) {
          final placeholderB = b as DartPlaceholder;
          final firstWithSameIndex = groupVarsByIndex[a.resolvedIndex]!.first;

          return firstWithSameIndex.firstPosition
              .compareTo(placeholderB.firstPosition);
        } else {
          return -comparer(b, a);
        }
      }
    };

    final list = vars.cast<dynamic>().followedBy(placeholders).toList();
    return list..sort(comparer);
  }

  FoundDartPlaceholder _extractPlaceholder(
      AnalysisContext context, DartPlaceholder placeholder) {
    final name = placeholder.name;

    final type = placeholder.when(
      isExpression: (e) {
        final foundType = context.typeOf(e);
        DriftSqlType? columnType;
        if (foundType.type != null) {
          columnType = resolvedToMoor(foundType.type);
        }

        final defaultValue =
            context.stmtOptions.defaultValuesForPlaceholder[name];

        return ExpressionDartPlaceholderType(columnType, defaultValue);
      },
      isLimit: (_) =>
          SimpleDartPlaceholderType(SimpleDartPlaceholderKind.limit),
      isOrderBy: (_) =>
          SimpleDartPlaceholderType(SimpleDartPlaceholderKind.orderBy),
      isOrderingTerm: (_) =>
          SimpleDartPlaceholderType(SimpleDartPlaceholderKind.orderByTerm),
      isInsertable: (_) {
        final insert = placeholder.parents.whereType<InsertStatement>().first;
        final table = insert.table.resultSet;

        return InsertableDartPlaceholderType(
            table is Table ? tableToMoor(table) : null);
      },
    );

    final availableResults = placeholder.statementScope.allAvailableResultSets;
    final availableMoorResults = <AvailableMoorResultSet>[];
    for (final available in availableResults) {
      final aliasedResultSet = available.resultSet.resultSet;
      final resultSet = aliasedResultSet?.unalias();
      String name;
      if (aliasedResultSet is NamedResultSet) {
        name = aliasedResultSet.name;
      } else {
        // If we don't have a name we can't include this result set.
        continue;
      }

      DriftEntityWithResultSet moorEntity;

      if (resultSet is Table) {
        moorEntity = tableToMoor(resultSet)!;
      } else if (resultSet is View) {
        moorEntity = viewToMoor(resultSet)!;
      } else {
        // If this result set is an inner select statement or anything else we
        // can't represent it in Dart.
        continue;
      }

      availableMoorResults
          .add(AvailableMoorResultSet(name, moorEntity, available));
    }

    return FoundDartPlaceholder(type!, name, availableMoorResults)
      ..astNode = placeholder;
  }

  DriftTable? tableToMoor(Table table) {
    return _engineTablesToSpecified[table];
  }

  MoorView? viewToMoor(View view) {
    return _engineViewsToSpecified[view];
  }

  DriftEntityWithResultSet? viewOrTableToMoor(dynamic entity) {
    if (entity is Table) {
      return tableToMoor(entity);
    } else if (entity is View) {
      return viewToMoor(entity);
    } else {
      throw ArgumentError.value(entity, 'entity', 'Must be a view or a table!');
    }
  }

  WrittenMoorTable? writtenToMoor(s.TableWrite table) {
    final moorKind = const {
      s.UpdateKind.insert: m.UpdateKind.insert,
      s.UpdateKind.update: m.UpdateKind.update,
      s.UpdateKind.delete: m.UpdateKind.delete,
    }[table.kind]!;

    final moorTable = tableToMoor(table.table);
    if (moorTable != null) {
      return WrittenMoorTable(moorTable, moorKind);
    } else {
      return null;
    }
  }
}

/// Finds variables, Dart placeholders and outgoing references from nested
/// queries (which are eventually turned into variables) inside a query.
///
/// Nested children of this query are ignored, see `nested_queries.dart` for
/// details on nested queries and how they're implemented.
class _FindElements extends RecursiveVisitor<NestedQueriesContainer?, void> {
  final List<Variable> variables = [];
  final List<DartPlaceholder> dartPlaceholders = [];

  @override
  void visitVariable(Variable e, NestedQueriesContainer? arg) {
    variables.add(e);
    super.visitVariable(e, arg);
  }

  @override
  void visitDriftSpecificNode(
      DriftSpecificNode e, NestedQueriesContainer? arg) {
    if (e is NestedQueryColumn) {
      // If the node ist a nested query, return to avoid collecting elements
      // inside of it
      return;
    }

    if (e is DartPlaceholder) {
      dartPlaceholders.add(e);
    }

    super.visitDriftSpecificNode(e, arg);
  }

  @override
  void visitReference(Reference e, NestedQueriesContainer? arg) {
    if (arg is NestedQuery) {
      final captured = arg.capturedVariables[e];
      if (captured != null) {
        variables.add(captured.introducedVariable);
      }
    }

    super.visitReference(e, arg);
  }
}
