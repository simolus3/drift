import 'package:collection/collection.dart';
import 'package:sqlparser/src/reader/tokenizer/token.dart';

part 'descriptions/description.dart';
part 'descriptions/static.dart';

part 'suggestion.dart';

/// Helper to provide context aware auto-complete suggestions inside a sql
/// query.
///
/// While parsing a query, the parser will yield a bunch of [Hint]s that are
/// specific to a specific location. Each hint contains the current position and
/// a [HintDescription] of what can appear behind that position.
/// To obtain suggestions for a specific cursor position, we then go back from
/// that position to the last [Hint] found and populate it.
class AutoCompleteEngine {
  /// The found hints.
  UnmodifiableListView<Hint> get foundHints => _hintsView;
  // hints are always sorted by their offset
  final List<Hint> _hints = [];
  UnmodifiableListView<Hint> _hintsView;

  void addHint(Hint hint) {
    _hints.insert(_lastHintBefore(hint.offset), hint);
  }

  AutoCompleteEngine() {
    _hintsView = UnmodifiableListView(_hints);
  }

  /// Suggest completions at a specific position.
  ///
  /// This api will change in the future.
  ComputedSuggestions suggestCompletions(int offset) {
    if (_hints.isEmpty) {
      return ComputedSuggestions(-1, -1, []);
    }

    final hint = foundHints[_lastHintBefore(offset)];

    final suggestions = hint.description.suggest(CalculationRequest()).toList();
    return ComputedSuggestions(hint.offset, offset - hint.offset, suggestions);
  }

  int _lastHintBefore(int offset) {
    // find the last hint that appears before offset
    var min = 0;
    var max = foundHints.length;

    while (min < max) {
      final mid = min + ((max - min) >> 1);
      final hint = _hints[mid];

      final offsetOfMid = hint.offset;

      if (offsetOfMid == offset) {
        return mid;
      } else if (offsetOfMid < offset) {
        min = mid + 1;
      } else {
        max = mid - 1;
      }
    }

    return min;
  }
}

class Hint {
  /// The token that appears just before this hint, or `null` if the hint
  /// appears at the beginning of the file.
  final Token before;

  int get offset => before?.span?.end?.offset ?? 0;

  final HintDescription description;

  Hint(this.before, this.description);
}

class CalculationRequest {}
