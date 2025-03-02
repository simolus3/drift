import '../compiler.dart';
import '../expressions/expression.dart';

abstract base class ColumnConstraint implements SqlComponent {
  const ColumnConstraint._();

  const factory ColumnConstraint.custom(CustomComponent custom) =
      _CustomColumnConstraint;
}

final class ColumnPrimaryKeyConstraint extends ColumnConstraint {
  final bool isAutoIncrementing;

  const ColumnPrimaryKeyConstraint({required this.isAutoIncrementing})
      : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnPrimaryKeyConstraint(this);
  }
}

/// A `GENERATED AS` clause in SQL.
///
/// This information filled out by the generator to support generated or virtual
/// columns.
final class ColumnGeneratedAs extends ColumnConstraint {
  /// The expression that this column evaluates to.
  final Expression generatedAs;

  /// Wehter this column is stored in the database, as opposed to being
  /// `VIRTUAL` and evaluated on each read.
  final bool stored;

  const ColumnGeneratedAs({required this.generatedAs, required this.stored})
      : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnGeneratedAs(this);
  }
}

/// A `UNIQUE` constraint on an individual column.
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

final class ColumnCheckConstraint extends ColumnConstraint {
  final Expression<bool> check;

  const ColumnCheckConstraint(this.check) : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addColumnCheckConstraint(this);
  }
}

final class _CustomColumnConstraint extends ColumnConstraint {
  final CustomComponent component;

  const _CustomColumnConstraint(this.component) : super._();

  @override
  void compileWith(StatementCompiler compiler) {
    component.compileWith(compiler);
  }
}
