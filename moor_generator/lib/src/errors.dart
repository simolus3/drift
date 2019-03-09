import 'package:analyzer/dart/element/element.dart';

class moorError {
  final bool critical;
  final String message;
  final Element affectedElement;

  moorError({this.critical = false, this.message, this.affectedElement});
}

class ErrorStore {
  final List<moorError> errors = [];

  void add(moorError error) => errors.add(error);

  bool get hasCriticalError => errors.any((e) => e.critical);
}
