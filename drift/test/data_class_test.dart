import 'package:drift/drift.dart';
import 'package:test/test.dart';

class _MyInsertable extends Insertable<void> {
  const _MyInsertable();

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => const {};
}

void main() {
  test(
    'Insertable should have a const constructor so a subclass can be a const',
    () {
      const myInsertable = const _MyInsertable();
    },
  );
}
