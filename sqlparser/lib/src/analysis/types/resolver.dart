part of '../analysis.dart';

/// Attempts to resolve types of expressions, result columns and variables.
/// As sqlite is pretty lenient at typing and pretty much accepts every value
/// everywhere, this
class TypeResolver {
  final Map<Typeable, _ResolvingState> _matchedStates = {};

  _ResolvingState _stateFor(Typeable typeable) {
    return _matchedStates.putIfAbsent(
        typeable, () => _ResolvingState(typeable, this));
  }

  void finish() {}

  /// Suggest that [t] should have the type [type].
  void suggestType(Typeable t, SqlType type) {
    _stateFor(t).suggested.add(type);
  }

  void suggestSame(Typeable a, Typeable b) {}

  void suggestBool(Typeable t) {
    final state = _stateFor(t);
    state.suggested.add(const SqlType.int());
    state.hints.add(const IsBoolean());
  }

  /// Marks that [t] will definitely have the type [type].
  void forceType(Typeable t, SqlType type) {
    _stateFor(t).forced = type;
  }

  /// Add an additional hint
  void addTypeHint(Typeable t, TypeHint hint) {
    _stateFor(t).hints.add(hint);
  }
}

class _ResolvingState {
  final Typeable typeable;
  final TypeResolver resolver;

  final List<TypeHint> hints = [];
  final List<SqlType> suggested = [];
  SqlType forced;

  _ResolvingState(this.typeable, this.resolver);
}
