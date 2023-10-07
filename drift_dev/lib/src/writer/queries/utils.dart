import '../../analysis/results/results.dart';
import '../writer.dart';

extension FoundElementType on FoundElement {
  AnnotatedDartCode dartType(Scope scope) {
    final $this = this;
    if ($this is FoundVariable) {
      return scope.dartType($this);
    } else if ($this is FoundDartPlaceholder) {
      return AnnotatedDartCode.build((builder) {
        final kind = $this.type;

        if (kind is SimpleDartPlaceholderType) {
          switch (kind.kind) {
            case SimpleDartPlaceholderKind.limit:
              builder.addSymbol('Limit', AnnotatedDartCode.drift);
              break;
            case SimpleDartPlaceholderKind.orderByTerm:
              builder.addSymbol('OrderingTerm', AnnotatedDartCode.drift);
              break;
            case SimpleDartPlaceholderKind.orderBy:
              builder.addSymbol('OrderBy', AnnotatedDartCode.drift);
              break;
          }
        } else if (kind is ExpressionDartPlaceholderType) {
          builder
            ..addSymbol('Expression', AnnotatedDartCode.drift)
            ..addText('<')
            ..addCode(scope.innerColumnType(kind.columnType!))
            ..addText('>');
        } else if (kind is InsertableDartPlaceholderType) {
          final table = kind.table;

          builder.addSymbol('Insertable', AnnotatedDartCode.drift);
          if (table != null) {
            builder
              ..addText('<')
              ..addCode(scope.rowType(table))
              ..addText('>');
          }
        }
      });
    } else {
      throw ArgumentError.value(this, 'this', 'Unknown query element');
    }
  }
}
