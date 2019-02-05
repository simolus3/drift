import 'package:analyzer/dart/element/element.dart';

class SallyError {
  final bool critical;
  final String message;
  final Element affectedElement;

  SallyError({this.critical = false, this.message, this.affectedElement});
}

class ErrorStore {
  final List<SallyError> errors = [];

  void add(SallyError error) => errors.add(error);

  bool get hasCriticalError => errors.any((e) => e.critical);
}
