part of 'engine.dart';

/// The result of suggesting auto-complete at a specific location.
class ComputedSuggestions {
  /// The offset from the source file from which the suggestion should be
  /// applied. Effectively, the range from [anchor] to `anchor + lengthBefore`
  /// will be replaced with the suggestion.
  final int anchor;

  /// The amount of chars that have already been typed and would be replaced
  /// when applying a suggestion.
  final int lengthBefore;

  /// The actual suggestions which are relevant here.
  final List<Suggestion> suggestions;

  ComputedSuggestions(this.anchor, this.lengthBefore, this.suggestions);
}

/// A single auto-complete suggestion.
class Suggestion {
  /// The code inserted.
  final String code;

  /// The relevance of this suggestion, where more relevant suggestions have a
  /// higher [relevance].
  final int relevance;

  Suggestion(this.code, this.relevance);
}
