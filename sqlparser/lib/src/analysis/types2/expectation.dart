part of 'types.dart';

/// Contains expectations on the type that a [Typeable] might have.
///
/// Different instances of this class are passed along when descending into the
/// AST during type analysis. For instance, logical binary expressions might
/// expect that their operands are logical expressions as well. This model
/// also allows us to construct more complicated relationships. For instance,
/// we can express the expected column types for a `INSERT INTO SELECT`
/// statement.
abstract class TypeExpectation {
  const TypeExpectation();
}

/// Passed along when an ast node makes no assumption on the type of its
/// child nodes.
class NoTypeExpectation extends TypeExpectation {
  const NoTypeExpectation();
}

/// Passed down when a node must have a known type.
class ExactTypeExpectation extends TypeExpectation {
  /// The type we expect the child nodes to have.
  final ResolvedType type;

  /// Whether the child node max have another type than [type].
  ///
  /// When false, we can report a compile-time error for a type mismatch.
  final bool lax;

  const ExactTypeExpectation(this.type) : lax = false;

  const ExactTypeExpectation.laxly(this.type) : lax = true;
}

/// Passed down when the general type must match (e.g. "numeric), but the
/// exact type is unknown.
///
/// This makes no expectation on nullability.
class RoughTypeExpectation extends TypeExpectation {
  final _RoughType _type;

  const RoughTypeExpectation._(this._type);

  const RoughTypeExpectation.numeric() : this._(_RoughType.numeric);

  bool accepts(ResolvedType type) {
    final baseType = type.type;
    switch (_type) {
      case _RoughType.numeric:
        return baseType == BasicType.int || baseType == BasicType.real;
    }
    return false;
  }
}

enum _RoughType {
  numeric,
}

/// Type expectation for result columns in a select statement.
///
/// This can be used to set expectations in an `INSERT INTO SELECT` statement,
/// where the column types are constrained by what's expected in the insert
/// statement.
class SelectTypeExpectation extends TypeExpectation {
  final List<TypeExpectation> columnExpectations;

  SelectTypeExpectation(this.columnExpectations);
}
