import 'package:analyzer/dart/element/element.dart';

class MoorError {
  final bool critical;
  final String message;
  final Element affectedElement;

  MoorError({this.critical = false, this.message, this.affectedElement});
}

class ErrorStore {
  final List<MoorError> errors = [];

  void add(MoorError error) => errors.add(error);

  bool get hasCriticalError => errors.any((e) => e.critical);
}
