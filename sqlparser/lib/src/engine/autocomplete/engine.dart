import 'package:sqlparser/src/reader/tokenizer/token.dart';

part 'descriptions/description.dart';

/// Helper to provide context aware auto-complete suggestions inside a sql
/// query.
///
/// While parsing a query, the parser will yield a bunch of [Hint]s that are
/// specific to a specific location. Each hint contains the current position and
/// a [HintDescription] of what can appear behind that position.
/// To obtain suggestions for a specific cursor position, we then go back from
/// that position to the last [Hint] found and populate it.
class AutoCompleteEngine {
  final List<Hint> foundHints = [];
}

class Hint {
  /// The token that appears just before this hint, or `null` if the hint
  /// appears at the beginning of the file.
  final Token before;
  final HintDescription description;

  Hint(this.before, this.description);
}
