part of '../engine.dart';

/// Suggestion that just inserts a bunch of token types with whitespace in
/// between.
class TokensDescription extends HintDescription {
  final List<TokenType> types;

  const TokensDescription(this.types);
  TokensDescription.single(TokenType type) : types = [type];

  @override
  Iterable<Suggestion> suggest(CalculationRequest request) sync* {
    final code = types
        .map((type) => reverseKeywords[type])
        .where((k) => k != null)
        .join(' ');

    yield Suggestion(code, 0);
  }
}
