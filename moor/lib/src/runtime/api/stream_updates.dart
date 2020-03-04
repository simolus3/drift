part of 'runtime_api.dart';

/// Collects a set of [UpdateRule]s which can be used to express how a set of
/// direct updates to a table affects other updates.
///
/// This is used to implement query streams in databases that have triggers.
///
/// Note that all the members in this class are visible for generated code and
/// internal moor code. They don't adhere to Semantic Versioning and should not
/// be used manually.
class StreamQueryUpdateRules {
  /// All rules active in a database.
  final List<UpdateRule> rules;

  /// Creates a [StreamQueryUpdateRules] from the underlying [rules].
  const StreamQueryUpdateRules(this.rules);

  /// The default implementation, which doesn't have any rules.
  const StreamQueryUpdateRules.none() : this(const []);

  /// Obtain a set of all tables that might be affected by direct updates to
  /// [updatedTables].
  ///
  /// This method should be used in internal moor code only, it does not respect
  /// Semantic Versioning and might change at any time.
  Set<String> apply(Iterable<String> updatedTables) {
    // Most users don't have any update rules, and this check is much faster
    // than crawling through all updates.
    if (rules.isEmpty) return updatedTables.toSet();

    final pending = List.of(updatedTables);
    final seen = <String>{};
    while (pending.isNotEmpty) {
      final updatedTable = pending.removeLast();
      seen.add(updatedTable);

      for (final rule in rules) {
        if (rule is WritePropagation && rule.onTable == updatedTable) {
          pending.addAll(rule.updates.where((u) => !seen.contains(u)));
        }
      }
    }

    return seen;
  }
}

/// Users should not extend or implement this class.
abstract class UpdateRule {
  /// Common const constructor so that subclasses can be const.
  const UpdateRule();
}

/// An [UpdateRule] for triggers that exist in a database.
///
/// An update on [onTable] implicitly triggers updates on [updates].
///
/// This class is for use by generated or moor-internal code only. It does not
/// adhere to Semantic Versioning and should not be used manually.
class WritePropagation extends UpdateRule {
  /// The table name that the trigger is active on.
  final String onTable;

  /// All tables potentially updated by the trigger.
  final Set<String> updates;

  /// Default constructor. See [WritePropagation] for details.
  const WritePropagation(this.onTable, this.updates);
}
