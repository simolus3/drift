import 'package:sally/src/runtime/executor/executor.dart';

/// Anything that can appear in a sql query.
abstract class Component {
  /// Writes this component into the [context] by writing to its
  /// [GenerationContext.buffer] or by introducing bound variables.
  void writeInto(GenerationContext context);
}

/// Contains information about a query while it's being constructed.
class GenerationContext {
  final GeneratedDatabase database;

  final List<dynamic> _boundVariables = [];
  List<dynamic> get boundVariables => _boundVariables;

  final StringBuffer buffer = StringBuffer();

  String get sql => buffer.toString();

  GenerationContext(this.database);

  void introduceVariable(dynamic value) {
    _boundVariables.add(value);
  }

  void writeWhitespace() => buffer.write(' ');
}
