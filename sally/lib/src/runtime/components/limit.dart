import 'package:sally/src/runtime/components/component.dart';

class Limit extends Component {
  final int amount;
  final int offset;

  Limit(this.amount, this.offset);

  @override
  void writeInto(GenerationContext context) {
    if (offset != null)
      context.buffer.write('LIMIT $amount, $offset');
    else
      context.buffer.write('LIMIT $amount');
  }
}
