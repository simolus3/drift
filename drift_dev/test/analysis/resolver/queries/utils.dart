import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/expect.dart';

import '../../test_utils.dart';

Future<SqlQuery> analyzeSingleQueryInDriftFile(String driftFile) async {
  final file = await TestBackend.analyzeSingle(driftFile);
  return file.fileAnalysis!.resolvedQueries.values.single;
}

Future<SqlQuery> analyzeQuery(String sql) async {
  return analyzeSingleQueryInDriftFile('a: $sql');
}

TypeMatcher<ScalarResultColumn> scalarColumn(String name) =>
    isA<ScalarResultColumn>().having((e) => e.name, 'name', name);

TypeMatcher<StructuredFromNestedColumn> structedFromNested(
        TypeMatcher<QueryRowType> nestedType) =>
    isA<StructuredFromNestedColumn>()
        .having((e) => e.nestedType, 'nestedType', nestedType);

TypeMatcher<MappedNestedListQuery> nestedListQuery(
    String columnName, TypeMatcher<QueryRowType> nestedType) {
  return isA<MappedNestedListQuery>()
      .having((e) => e.column.filedName(), 'column', columnName)
      .having((e) => e.nestedType, 'nestedType', nestedType);
}

TypeMatcher<QueryRowType> isExistingRowType({
  String? type,
  String? constructorName,
  Object? singleValue,
  Object? positional,
  Object? named,
}) {
  var matcher = isA<QueryRowType>();

  if (type != null) {
    matcher = matcher.having((e) => e.rowType.toString(), 'rowType', type);
  }
  if (constructorName != null) {
    matcher = matcher.having(
        (e) => e.constructorName, 'constructorName', constructorName);
  }
  if (singleValue != null) {
    matcher = matcher.having((e) => e.singleValue, 'singleValue', singleValue);
  }
  if (positional != null) {
    matcher = matcher.having(
        (e) => e.positionalArguments, 'positionalArguments', positional);
  }
  if (named != null) {
    matcher = matcher.having((e) => e.namedArguments, 'namedArguments', named);
  }

  return matcher;
}
