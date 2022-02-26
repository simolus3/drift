part of '../ast.dart';

/// https://www.sqlite.org/syntax/column-def.html
class ColumnDefinition extends AstNode {
  final String columnName;
  final String? typeName;
  List<ColumnConstraint> constraints;

  /// The tokens there were involved in defining the type of this column.
  List<Token>? typeNames;
  Token? nameToken;

  ColumnDefinition(
      {required this.columnName,
      required this.typeName,
      this.constraints = const []});

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitColumnDefinition(this, arg);
  }

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    constraints = transformer.transformChildren(constraints, this, arg);
  }

  @override
  Iterable<AstNode> get childNodes => constraints;

  bool get isNonNullable => findConstraint<NotNull>() != null;

  /// Finds a constraint of type [T], or null, if none is set.
  T? findConstraint<T extends ColumnConstraint>() {
    final typedConstraints = constraints.whereType<T>().iterator;
    if (typedConstraints.moveNext()) {
      return typedConstraints.current;
    }
    return null;
  }
}

/// https://www.sqlite.org/syntax/column-constraint.html
abstract class ColumnConstraint extends AstNode {
  final String? name;

  ColumnConstraint(this.name);

  @override
  R accept<A, R>(AstVisitor<A, R> visitor, A arg) {
    return visitor.visitColumnConstraint(this, arg);
  }

  T? when<T>({
    T Function(NotNull)? notNull,
    T Function(NullColumnConstraint)? nullable,
    T Function(PrimaryKeyColumn)? primaryKey,
    T Function(UniqueColumn)? unique,
    T Function(CheckColumn)? check,
    T Function(Default)? isDefault,
    T Function(CollateConstraint)? collate,
    T Function(ForeignKeyColumnConstraint)? foreignKey,
    T Function(MappedBy)? mappedBy,
    T Function(GeneratedAs)? generatedAs,
  }) {
    if (this is NotNull) {
      return notNull?.call(this as NotNull);
    } else if (this is NullColumnConstraint) {
      return nullable?.call(this as NullColumnConstraint);
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
    } else if (this is GeneratedAs) {
      return generatedAs?.call(this as GeneratedAs);
    } else {
      throw Exception('Did not expect $runtimeType as a ColumnConstraint');
    }
  }
}

enum ConflictClause { rollback, abort, fail, ignore, replace }

class NullColumnConstraint extends ColumnConstraint {
  /// The `NULL` token forming this constraint.
  Token? $null;

  NullColumnConstraint(String? name, {this.$null}) : super(name);

  @override
  Iterable<AstNode> get childNodes => const Iterable.empty();

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

class NotNull extends ColumnConstraint {
  final ConflictClause? onConflict;

  Token? not;
  Token? $null;

  NotNull(String? name, {this.onConflict}) : super(name);

  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

class PrimaryKeyColumn extends ColumnConstraint {
  final bool autoIncrement;
  final ConflictClause? onConflict;
  final OrderingMode? mode;

  PrimaryKeyColumn(String? name,
      {this.autoIncrement = false, this.mode, this.onConflict})
      : super(name);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

class UniqueColumn extends ColumnConstraint {
  final ConflictClause? onConflict;

  UniqueColumn(String? name, this.onConflict) : super(name);

  @override
  Iterable<AstNode> get childNodes => const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

class CheckColumn extends ColumnConstraint {
  Expression expression;

  CheckColumn(String? name, this.expression) : super(name);

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    expression = transformer.transformChild(expression, this, arg);
  }
}

class Default extends ColumnConstraint {
  Expression expression;

  Default(String? name, this.expression) : super(name);

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    expression = transformer.transformChild(expression, this, arg);
  }
}

class CollateConstraint extends ColumnConstraint {
  final String collation;

  CollateConstraint(String? name, this.collation) : super(name);

  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

class ForeignKeyColumnConstraint extends ColumnConstraint {
  ForeignKeyClause clause;

  ForeignKeyColumnConstraint(String? name, this.clause) : super(name);

  @override
  Iterable<AstNode> get childNodes => [clause];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    clause = transformer.transformChild(clause, this, arg);
  }
}

class GeneratedAs extends ColumnConstraint {
  Expression expression;
  bool stored;

  GeneratedAs(this.expression, {this.stored = false, String? name})
      : super(name);

  @override
  Iterable<AstNode> get childNodes => [expression];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {
    expression = transformer.transformChild(expression, this, arg);
  }
}

/// A `MAPPED BY` constraint, which is only parsed for drift files. It can be
/// used to declare a type converter for this column.
class MappedBy extends ColumnConstraint {
  /// The Dart expression creating the type converter we use to map this token.
  final InlineDartToken mapper;

  MappedBy(String? name, this.mapper) : super(name);

  @override
  final Iterable<AstNode> childNodes = const [];

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

/// A `JSON KEY xyz` constraint, which is only parsed for drift files.
class JsonKey extends ColumnConstraint {
  Token? json;
  Token? key;
  IdentifierToken jsonNameToken;

  @override
  final Iterable<AstNode> childNodes = const [];

  String get jsonKey => jsonNameToken.identifier;

  JsonKey(String? name, this.jsonNameToken) : super(name);

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}

/// A `AS xyz` constraint, which is only parsed for drift files.
class DriftDartName extends ColumnConstraint {
  Token? as;
  IdentifierToken identifier;

  @override
  final Iterable<AstNode> childNodes = const [];

  String get dartName => identifier.identifier;

  DriftDartName(String? name, this.identifier) : super(name);

  @override
  void transformChildren<A>(Transformer<A> transformer, A arg) {}
}
