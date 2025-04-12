import '../compiler.dart';

/// A limit clause inside a select, update or delete statement.
final class Limit implements SqlComponent {
  /// The maximum amount of rows that should be returned by the query.
  final int amount;

  /// When the offset is non null, the first offset rows will be skipped an not
  /// included in the result.
  final int? offset;

  /// Construct a limit clause from the [amount] of rows to include an a
  /// nullable [offset].
  Limit(this.amount, this.offset);

  @override
  void compileWith(StatementCompiler compiler) {
    compiler.addLimit(this);
  }
}
