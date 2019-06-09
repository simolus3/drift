import 'package:moor/src/runtime/components/component.dart';

/// A limit clause inside a select, update or delete statement.
class Limit extends Component {
  /// The maximum amount of rows that should be returned by the query.
  final int amount;

  /// When the offset is non null, the first offset rows will be skipped an not
  /// included in the result.
  final int offset;

  Limit(this.amount, this.offset);

  @override
  void writeInto(GenerationContext context) {
    if (offset != null) {
      context.buffer.write('LIMIT $amount, $offset');
    } else {
      context.buffer.write('LIMIT $amount');
    }
  }
}
