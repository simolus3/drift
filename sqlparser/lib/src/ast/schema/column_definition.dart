part of '../ast.dart';

/// https://www.sqlite.org/syntax/column-def.html
class ColumnDefinition extends AstNode {
  final String columnName;
  final String typeName;
  final List<ColumnConstraint> constraints;

  /// The tokens there were involved in defining the type of this column.
  List<Token> typeNames;
  Token nameToken;

  ColumnDefinition(
      {@required this.columnName,
      @required this.typeName,
      this.constraints = const []});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitColumnDefinition(this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => constraints;

  @override
  bool contentEquals(ColumnDefinition other) {
    return other.columnName == columnName && other.typeName == typeName;
  }

  /// Finds a constraint of type [T], or null, if none is set.
  T findConstraint<T extends ColumnConstraint>() {
    final typedConstraints = constraints.whereType<T>().iterator;
    if (typedConstraints.moveNext()) {
      return typedConstraints.current;
    }
    return null;
  }
}

/// https://www.sqlite.org/syntax/column-constraint.html
abstract class ColumnConstraint extends AstNode {
  final String name;

  ColumnConstraint(this.name);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitColumnConstraint(this, arg);
  }

  T when<T>({
    T Function(NotNull) notNull,
    T Function(PrimaryKeyColumn) primaryKey,
    T Function(UniqueColumn) unique,
    T Function(CheckColumn) check,
    T Function(Default) isDefault,
    T Function(CollateConstraint) collate,
    T Function(ForeignKeyColumnConstraint) foreignKey,
    T Function(MappedBy) mappedBy,
  }) {
    if (this is NotNull) {
      return notNull?.call(this as NotNull);
    } else if (this is PrimaryKeyColumn) {
      return primaryKey?.call(this as PrimaryKeyColumn);
    } else if (this is UniqueColumn) {
      return unique?.call(this as UniqueColumn);
    } else if (this is CheckColumn) {
      return check?.call(this as CheckColumn);
    } else if (this is Default) {
      return isDefault?.call(this as Default);
    } else if (this is CollateConstraint) {
      return collate?.call(this as CollateConstraint);
    } else if (this is ForeignKeyColumnConstraint) {
      return foreignKey?.call(this as ForeignKeyColumnConstraint);
    } else if (this is MappedBy) {
      return mappedBy?.call(this as MappedBy);
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

  Token not;
  Token $null;

  NotNull(String name, {this.onConflict}) : super(name);

  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  bool _equalToConstraint(NotNull other) => onConflict == other.onConflict;
}

class PrimaryKeyColumn extends ColumnConstraint {
  final bool autoIncrement;
  final ConflictClause onConflict;
  final OrderingMode mode;

  PrimaryKeyColumn(String name,
      {this.autoIncrement = false, this.mode, this.onConflict})
      : super(name);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool _equalToConstraint(PrimaryKeyColumn other) {
    return other.autoIncrement == autoIncrement &&
        other.mode == mode &&
        other.onConflict == onConflict;
  }
}

class UniqueColumn extends ColumnConstraint {
  final ConflictClause onConflict;

  UniqueColumn(String name, this.onConflict) : super(name);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  bool _equalToConstraint(UniqueColumn other) {
    return other.onConflict == onConflict;
  }
}

class CheckColumn extends ColumnConstraint {
  final Expression expression;

  CheckColumn(String name, this.expression) : super(name);

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  bool _equalToConstraint(CheckColumn other) => true;
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

class ForeignKeyColumnConstraint extends ColumnConstraint {
  final ForeignKeyClause clause;

  ForeignKeyColumnConstraint(String name, this.clause) : super(name);

  @override
  bool _equalToConstraint(ForeignKeyColumnConstraint other) => true;

  @override
  Iterable<AstNode> get childNodes => [clause];
}

/// A `MAPPED BY` constraint, which is only parsed for moor files. It can be
/// used to declare a type converter for this column.
class MappedBy extends ColumnConstraint {
  /// The Dart expression creating the type converter we use to map this token.
  final InlineDartToken mapper;

  MappedBy(String name, this.mapper) : super(name);

  @override
  bool _equalToConstraint(MappedBy other) {
    return other.mapper.dartCode == mapper.dartCode;
  }

  @override
  final Iterable<AstNode> childNodes = const [];
}

/// A `JSON KEY xyz` constraint which, which is only parsed for moor files.
class JsonKey extends ColumnConstraint {
  Token json;
  Token key;
  IdentifierToken jsonNameToken;

  @override
  final Iterable<AstNode> childNodes = const [];

  String get jsonKey => jsonNameToken.identifier;

  JsonKey(String name, this.jsonNameToken) : super(name);

  @override
  bool _equalToConstraint(JsonKey other) {
    return other.jsonKey == jsonKey;
  }
}
