import 'package:json_annotation/json_annotation.dart';

import 'element.dart';

part '../../generated/analysis/results/dart.g.dart';

class AnnotatedDartCode {
  final List<dynamic /* String|DartTopLevelSymbol */ > elements;

  AnnotatedDartCode(this.elements);

  factory AnnotatedDartCode.fromJson(Map json) {
    final serializedElements = json['elements'] as List;

    return AnnotatedDartCode([
      for (final part in serializedElements)
        if (part is Map) DartTopLevelSymbol.fromJson(json) else part as String
    ]);
  }

  Map<String, Object?> toJson() {
    return {
      'elements': [
        for (final element in elements)
          if (element is DartTopLevelSymbol) element.toJson() else element
      ],
    };
  }
}

@JsonSerializable()
class DartTopLevelSymbol {
  final String lexeme;
  final DriftElementId elementId;

  DartTopLevelSymbol(this.lexeme, this.elementId);

  factory DartTopLevelSymbol.fromJson(Map json) =>
      _$DartTopLevelSymbolFromJson(json);

  Map<String, Object?> toJson() => _$DartTopLevelSymbolToJson(this);
}
