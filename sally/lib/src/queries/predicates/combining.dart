import 'package:sally/src/queries/generation_context.dart';
import 'package:sally/src/queries/predicates/predicate.dart';

class NotPredicate extends Predicate {
  final Predicate inner;

  NotPredicate(this.inner);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write("NOT ");
    inner.writeInto(context);
  }
}

class OrPredicate extends Predicate {
  final Predicate a, b;

  OrPredicate(this.a, this.b);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('(');
    a.writeInto(context);
    context.buffer.write(') OR ( ');
    b.writeInto(context);
    context.buffer.write(') ');
  }
}

class AndPredicate extends Predicate {
  final Predicate a, b;

  AndPredicate(this.a, this.b);

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('(');
    a.writeInto(context);
    context.buffer.write(') AND (');
    b.writeInto(context);
    context.buffer.write(') ');
  }
}
