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
}

enum ConflictClause { rollback, abort, fail, ignore, replace }

class NotNull extends ColumnConstraint {
  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  bool contentEquals(NotNull other) => true;
}

class PrimaryKey extends ColumnConstraint {
  final bool autoIncrement;
  final OrderingMode mode;

  PrimaryKey(this.autoIncrement, this.mode);

  @override
  Iterable<AstNode> get childNodes => null;

  @override
  bool contentEquals(PrimaryKey other) {
    return other.autoIncrement == autoIncrement && other.mode == mode;
  }
}

class Unique extends ColumnConstraint {
  final ConflictClause onConflict;

  Unique(this.onConflict);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool contentEquals(Unique other) {
    return other.onConflict == onConflict;
  }
}

class Check extends ColumnConstraint {
  final Expression expression;

  Check(this.expression);

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool contentEquals(Check other) => true;
}

class Default extends ColumnConstraint {
  final Expression expression;

  Default(this.expression);

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool contentEquals(Default other) => true;
}

class CollateConstraint extends ColumnConstraint {
  final String collation;

  CollateConstraint(this.collation);

  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  bool contentEquals(CollateConstraint other) => true;
}
