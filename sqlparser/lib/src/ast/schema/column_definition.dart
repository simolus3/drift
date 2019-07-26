part of '../ast.dart';

/// https://www.sqlite.org/syntax/column-def.html
class ColumnDefinition extends AstNode {
  final String columnName;
  final String typeName;
  final List<ColumnConstraint> constraints;

  ColumnDefinition(
      {@required this.columnName,
      @required this.typeName,
      this.constraints = const []});

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitColumnDefinition(this);

  @override
  Iterable<AstNode> get childNodes => constraints;

  @override
  bool contentEquals(ColumnDefinition other) {
    return other.columnName == columnName && other.typeName == typeName;
  }
}

/// https://www.sqlite.org/syntax/column-constraint.html
abstract class ColumnConstraint extends AstNode {
  // todo foreign key clause

  final String name;

  ColumnConstraint(this.name);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitColumnConstraint(this);

  T when<T>({
    T Function(NotNull n) notNull,
    T Function(PrimaryKey) primaryKey,
    T Function(Unique) unique,
    T Function(Check) check,
    T Function(Default) isDefault,
    T Function(CollateConstraint) collate,
  }) {
    if (this is NotNull) {
      return notNull?.call(this as NotNull);
    } else if (this is PrimaryKey) {
      return primaryKey?.call(this as PrimaryKey);
    } else if (this is Unique) {
      return unique?.call(this as Unique);
    } else if (this is Check) {
      return check?.call(this as Check);
    } else if (this is Default) {
      return isDefault?.call(this as Default);
    } else if (this is CollateConstraint) {
      return collate?.call(this as CollateConstraint);
    } else {
      throw Exception('Did not expect $runtimeType as a ColumnConstraint');
    }
  }

  @visibleForOverriding
  bool _equalToConstraint(covariant ColumnConstraint other);

  @override
  bool contentEquals(ColumnConstraint other) {
    return other.name == name && _equalToConstraint(other);
  }
}

enum ConflictClause { rollback, abort, fail, ignore, replace }

class NotNull extends ColumnConstraint {
  final ConflictClause onConflict;

  NotNull(String name, {this.onConflict}) : super(name);

  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  bool _equalToConstraint(NotNull other) => onConflict == other.onConflict;
}

class PrimaryKey extends ColumnConstraint {
  final bool autoIncrement;
  final ConflictClause onConflict;
  final OrderingMode mode;

  PrimaryKey(String name,
      {this.autoIncrement = false, this.mode, this.onConflict})
      : super(name);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool _equalToConstraint(PrimaryKey other) {
    return other.autoIncrement == autoIncrement &&
        other.mode == mode &&
        other.onConflict == onConflict;
  }
}

class Unique extends ColumnConstraint {
  final ConflictClause onConflict;

  Unique(String name, this.onConflict) : super(name);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool _equalToConstraint(Unique other) {
    return other.onConflict == onConflict;
  }
}

class Check extends ColumnConstraint {
  final Expression expression;

  Check(String name, this.expression) : super(name);

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool _equalToConstraint(Check other) => true;
}

class Default extends ColumnConstraint {
  final Expression expression;

  Default(String name, this.expression) : super(name);

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool _equalToConstraint(Default other) => true;
}

class CollateConstraint extends ColumnConstraint {
  final String collation;

  CollateConstraint(String name, this.collation) : super(name);

  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  bool _equalToConstraint(CollateConstraint other) => true;
}
