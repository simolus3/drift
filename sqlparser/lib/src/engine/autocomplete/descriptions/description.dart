part of '../engine.dart';

/// Attached to a hint. A [HintDescription], together with additional context,
/// can be used to compute the available autocomplete suggestions.
abstract class HintDescription {
  const HintDescription();

  const factory HintDescription.tokens(List<TokenType> types) =
      TokensDescription;

  factory HintDescription.token(TokenType type) = TokensDescription.single;

  Iterable<Suggestion> suggest(CalculationRequest request);
}
