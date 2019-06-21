import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/components/component.dart';
import 'package:moor/src/runtime/components/limit.dart';
import 'package:moor/src/runtime/components/order_by.dart';
import 'package:moor/src/runtime/components/where.dart';
import 'package:moor/src/runtime/expressions/custom.dart';
import 'package:moor/src/runtime/expressions/expression.dart';
import 'package:moor/src/utils/single_transformer.dart';

/// Statement that operates with data that already exists (select, delete,
/// update).
abstract class Query<T extends Table, D extends DataClass> {
  @protected
  QueryEngine database;
  TableInfo<T, D> table;

  Query(this.database, this.table);

  @protected
  Where whereExpr;
  @protected
  OrderBy orderByExpr;
  @protected
  Limit limitExpr;

  /// Subclasses must override this and write the part of the statement that
  /// comes before the where and limit expression..
  @visibleForOverriding
  void writeStartPart(GenerationContext ctx);

  /// Constructs the query that can then be sent to the database executor.
  @protected
  GenerationContext constructQuery() {
    final ctx = GenerationContext.fromDb(database);
    var needsWhitespace = false;

    writeStartPart(ctx);
    needsWhitespace = true;

    if (whereExpr != null) {
      if (needsWhitespace) ctx.writeWhitespace();

      whereExpr.writeInto(ctx);
      needsWhitespace = true;
    }

    if (orderByExpr != null) {
      if (needsWhitespace) ctx.writeWhitespace();

      orderByExpr.writeInto(ctx);
      needsWhitespace = true;
    }

    if (limitExpr != null) {
      if (needsWhitespace) ctx.writeWhitespace();

      limitExpr.writeInto(ctx);
      needsWhitespace = true;
    }

    ctx.buffer.write(';');

    return ctx;
  }
}

/// Abstract class for queries which can return one-time values or a stream
/// of values.
abstract class Selectable<T> {
  /// Executes this statement and returns the result.
  Future<List<T>> get();

  /// Creates an auto-updating stream of the result that emits new items
  /// whenever any table used in this statement changes.
  Stream<List<T>> watch();

  /// Executes this statement, like [get], but only returns one value. If the
  /// result has no or too many values, this method will throw.
  ///
  /// Be aware that this operation won't put a limit clause on this statement,
  /// if that's needed you would have to do that yourself.
  Future<T> getSingle() async {
    final list = await get();
    final iterator = list.iterator;

    if (!iterator.moveNext()) {
      throw StateError('Expected exactly one result, but actually there were '
          'none!');
    }
    final element = iterator.current;
    if (iterator.moveNext()) {
      throw StateError('Expected exactly one result, but found more than one!');
    }

    return element;
  }

  /// Creates an auto-updating stream of this statement, similar to [watch].
  /// However, it is assumed that the query will only emit one result, so
  /// instead of returning a [Stream<List<T>>], this returns a [Stream<T>]. If
  /// the query emits more than one row at some point, an error will be emitted
  /// to the stream instead.
  Stream<T> watchSingle() {
    return watch().transform(singleElements());
  }
}

mixin SingleTableQueryMixin<T extends Table, D extends DataClass>
    on Query<T, D> {
  void where(Expression<bool, BoolType> filter(T tbl)) {
    final predicate = filter(table.asDslTable);

    if (whereExpr == null) {
      whereExpr = Where(predicate);
    } else {
      whereExpr = Where(and(whereExpr.predicate, predicate));
    }
  }

  /// Applies a [where] statement so that the row with the same primary key as
  /// [d] will be matched.
  void whereSamePrimaryKey(D d) {
    assert(
        table.$primaryKey != null && table.$primaryKey.isNotEmpty,
        'When using Query.whereSamePrimaryKey, which is also called from '
        'DeleteStatement.delete and UpdateStatement.replace, the affected table'
        'must have a primary key. You can either specify a primary implicitly '
        'by making an integer() column autoIncrement(), or by explictly '
        'overriding the primaryKey getter in your table class. You\'ll also '
        'have to re-run the code generation step.\n'
        'Alternatively, if you\'re using DeleteStatement.delete or '
        'UpdateStatement.replace, consider using DeleteStatement.go or '
        'UpdateStatement.write respectively. In that case, you need to use a '
        'custom where statement.');

    final primaryKeys = table.$primaryKey.map((c) => c.$name);

    final updatedFields = table.entityToSql(d, includeNulls: true);
    // Extract values of the primary key as they are needed for the where clause
    final primaryKeyValues = Map.fromEntries(updatedFields.entries
        .where((entry) => primaryKeys.contains(entry.key)));

    Expression<bool, BoolType> predicate;
    for (var entry in primaryKeyValues.entries) {
      // custom expression that references the column
      final columnExpression = CustomExpression(entry.key);
      final comparison =
          Comparison(columnExpression, ComparisonOperator.equal, entry.value);

      if (predicate == null) {
        predicate = comparison;
      } else {
        predicate = and(predicate, comparison);
      }
    }

    whereExpr = Where(predicate);
  }
}

mixin LimitContainerMixin<T extends Table, D extends DataClass> on Query<T, D> {
  /// Limits the amount of rows returned by capping them at [limit]. If [offset]
  /// is provided as well, the first [offset] rows will be skipped and not
  /// included in the result.
  void limit(int limit, {int offset}) {
    limitExpr = Limit(limit, offset);
  }
}
