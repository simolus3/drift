import 'package:collection/collection.dart';

import '../common/escape.dart';
import '../dialect.dart';
import '../expressions/variable.dart';

/// A component is anything that can appear in a sql query.
abstract class SqlComponent {
  /// Default, constant constructor.
  const SqlComponent();

  /// Writes this component into the [context] by writing to its
  /// [GenerationContext.buffer] or by introducing bound variables. When writing
  /// into the buffer, no whitespace around the this component should be
  /// introduced. When a component consists of multiple composed component, it's
  /// responsible for introducing whitespace between its child components.
  void writeInto(GenerationContext context);
}

/// Contains information about a query while it's being constructed.
class GenerationContext {
  final List<ContextScope> _scopeStack = [];

  /// When set to a non-null value, [Variable]s in this context will generate
  /// explicit indices starting at [explicitVariableIndex].
  int? explicitVariableIndex;

  /// The [SqlDialect] that should be respected when generating the query.
  final SqlDialect dialect;

  /// Whether variables are supported and can be written as `?` to be bound
  /// later.
  ///
  /// This is almost always the case, but not in a `CREATE VIEW` statement.
  final bool supportsVariables;

  final List<BoundVariable> _boundVariables = [];

  /// The values of [introducedVariables] that will be sent to the underlying
  /// engine.
  List<BoundVariable> get boundVariables => _boundVariables;

  /// All variables ("?" in sql) that were added to this context.
  final List<Variable> introducedVariables = [];

  /// Returns the amount of variables that have been introduced when writing
  /// this query.
  int get amountOfVariables => boundVariables.length;

  /// The string buffer contains the sql query as it's being constructed.
  final StringBuffer buffer = StringBuffer();

  /// Gets the generated sql statement
  String get sql => buffer.toString();

  bool get shouldUseIndexedVariables {
    assert(supportsVariables);

    return explicitVariableIndex != null ||
        !dialect.capabilites.supportsAnonymousVariables;
  }

  int get nextVariableIndex {
    final explicit = explicitVariableIndex;

    if (explicit != null) {
      return explicit + amountOfVariables;
    } else {
      return amountOfVariables;
    }
  }

  /// Constructs a custom [GenerationContext] by setting the fields manually.
  /// See [GenerationContext.fromDb] for a more convenient factory.
  GenerationContext(this.dialect, {this.supportsVariables = true});

  /// Introduces a variable that will be sent to the database engine. Whenever
  /// this method is called, a question mark should be added to the [buffer] so
  /// that the prepared statement can be executed with the variable. The value
  /// must be a type that is supported by the sqflite library. A list of
  /// supported types can be found [here](https://github.com/tekartik/sqflite#supported-sqlite-types).
  void introduceVariable(Variable v, String name, dynamic value) {
    introducedVariables.add(v);
    _boundVariables.add(BoundVariable(value, name));
  }

  /// Shortcut to add a single space to the buffer because it's used very often.
  void writeWhitespace() => buffer.write(' ');

  void pushScope(ContextScope scope) => _scopeStack.add(scope);
  void popScope() => _scopeStack.removeLast();
  Scope? scope<Scope extends ContextScope>() {
    return _scopeStack.whereType<Scope>().lastOrNull;
  }

  Scope requireScope<Scope extends ContextScope>() {
    return scope()!;
  }

  String identifier(String identifier) {
    return escapeIfNeeded(dialect.keywords, identifier);
  }
}

class BoundVariable {
  final Object? value;
  final String sqlName;

  BoundVariable(this.value, this.sqlName);

  @override
  String toString() {
    return '$sqlName: $value';
  }
}

abstract class ContextScope {}
