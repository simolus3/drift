import 'element.dart';

class AnnotatedDartCode {
  final List<dynamic> elements;

  AnnotatedDartCode(this.elements);
}

class DartTopLevelSymbol {
  final String lexeme;
  final DriftElementId elementId;

  DartTopLevelSymbol(this.lexeme, this.elementId);
}
