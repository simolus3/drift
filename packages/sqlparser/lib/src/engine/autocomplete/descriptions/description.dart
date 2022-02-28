part of '../engine.dart';

/// Attached to a hint. A [HintDescription], together with additional context,
/// can be used to compute the available autocomplete suggestions.
abstract class HintDescription {
  const HintDescription();

  const factory HintDescription.tokens(List<TokenType> types) =
      TokensDescription;

  factory HintDescription.token(TokenType type) = TokensDescription.single;

  Iterable<Suggestion> suggest(CalculationRequest request);

  HintDescription mergeWith(HintDescription other) {
    return CombinedDescription()
      ..descriptions.add(this)
      ..descriptions.add(other);
  }
}

/// A [HintDescription] that bundles multiple independent [HintDescription]s.
class CombinedDescription extends HintDescription {
  /// The descriptions to consult when using [suggest]. This list may be
  /// modified at runtime.
  final List<HintDescription> descriptions = [];

  @override
  Iterable<Suggestion> suggest(CalculationRequest request) {
    return descriptions.expand((s) => s.suggest(request));
  }

  @override
  HintDescription mergeWith(HintDescription other) {
    if (other is CombinedDescription) {
      // optimization: flatten into single list
      descriptions.addAll(other.descriptions);
    } else {
      descriptions.add(other);
    }

    return this;
  }
}
