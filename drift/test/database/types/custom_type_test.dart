import 'package:drift/drift.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../../test_utils/test_utils.dart';

class UuidType implements CustomSqlType<UuidValue> {
  const UuidType();

  @override
  String mapToSqlLiteral(UuidValue dartValue) {
    return "'$dartValue'";
  }

  @override
  Object mapToSqlParameter(UuidValue dartValue) {
    return dartValue;
  }

  @override
  UuidValue read(Object fromSql) {
    return fromSql as UuidValue;
  }

  @override
  String sqlTypeName(GenerationContext context) => 'uuid';
}

void main() {
  final uuid = Uuid().v4obj();

  group('in expression', () {
    test('variable', () {
      final c = Variable<UuidValue>(uuid, const UuidType());

      expect(c.driftSqlType, isA<UuidType>());
      expect(c, generates('?', [uuid]));
    });

    test('constant', () {
      final c = Constant<UuidValue>(uuid, const UuidType());

      expect(c.driftSqlType, isA<UuidType>());
      expect(c, generates("'$uuid'"));
    });

    test('cast', () {
      final cast = Variable('foo').cast<UuidValue>(const UuidType());

      expect(cast.driftSqlType, isA<UuidType>());
      expect(cast, generates('CAST(? AS uuid)', ['foo']));
    });
  });
}
