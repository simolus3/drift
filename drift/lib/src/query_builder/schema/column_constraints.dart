import '../compiler.dart';
import '../dialect.dart';
import '../expressions/expression.dart';
import 'package:meta/meta.dart';

@immutable
abstract base class ColumnConstraint implements SqlComponent {
  const ColumnConstraint._();

  const factory ColumnConstraint.custom(CustomComponent custom,
      {KnownSqlDialect? onlyOnDialect}) = CustomColumnConstraint;

  factory ColumnConstraint.customSql(String sql) {
    return ColumnConstraint.custom(CustomComponent(sql));
  }
}

@immutable
final class ColumnPrimaryKeyConstraint extends ColumnConstraint {
  final bool isAutoIncrementing;

  const ColumnPrimaryKeyConstraint({required this.isAutoIncrementing})
      : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnPrimaryKeyConstraint(this);
  }
}

/// A `DEFAULT` constraint in SQL.
@immutable
final class ColumnDefaultConstraint<T extends Object> extends ColumnConstraint {
  /// The default expression to use for the column when no value is given for
  /// inserts.
  final Expression<T> defaultExpression;

  /// Creates a `DEFAULT` constraint from the [defaultExpression].
  const ColumnDefaultConstraint(this.defaultExpression) : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnDefaultConstraint(this);
  }
}

/// A `GENERATED AS` clause in SQL.
///
/// This information filled out by the generator to support generated or virtual
/// columns.
@immutable
final class ColumnGeneratedAs extends ColumnConstraint {
  /// The expression that this column evaluates to.
  final Expression generatedAs;

  /// Wether this column is stored in the database, as opposed to being
  /// `VIRTUAL` and evaluated on each read.
  final bool stored;

  const ColumnGeneratedAs(this.generatedAs, {this.stored = false}) : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnGeneratedAs(this);
  }
}

/// A `UNIQUE` constraint on an individual column.
@immutable
final class ColumnUniqueConstraint extends ColumnConstraint {
  const ColumnUniqueConstraint() : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnUniqueConstraint(this);
  }
}

enum ReferenceAction {
  setNull('SET NULL'),
  setDefault('SET DEFAULT'),
  cascade('CASCADE'),
  restrict('RESTRICT'),
  noAction('NO ACTION');

  /// The default lexeme to use for this reference action in SQL.
  final String defaultLexeme;

  const ReferenceAction(this.defaultLexeme);
}

@immutable
final class ColumnForeignKeyConstraint extends ColumnConstraint {
  final String otherTableName;
  final String otherColumnName;

  final ReferenceAction? onUpdate;
  final ReferenceAction? onDelete;

  /// Whether this foreign key reference was marked as deferrable and initially
  /// deferred, meaning that it is only checked at the end of transactions.
  final bool initiallyDeferred;

  const ColumnForeignKeyConstraint({
    required this.otherTableName,
    required this.otherColumnName,
    this.onUpdate,
    this.onDelete,
    this.initiallyDeferred = false,
  }) : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnForeignKeyConstraint(this);
  }
}

@immutable
final class ColumnCheckConstraint extends ColumnConstraint {
  final Expression<bool> check;

  const ColumnCheckConstraint(this.check) : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnCheckConstraint(this);
  }
}

@immutable
final class CustomColumnConstraint extends ColumnConstraint {
  final CustomComponent component;
  final KnownSqlDialect? onlyOnDialect;

  const CustomColumnConstraint(this.component, {this.onlyOnDialect})
      : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    component.compileWith(compiler);
  }
}
