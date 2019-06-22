# sqlparser

An sql parser and static analyzer, written in pure Dart. Currently in development and
not really suitable for any use.

## Using this library

```dart
import 'package:sqlparser/sqlparser.dart';

final engine = SqlEngine();
final stmt = engine.parse('''
SELECT f.* FROM frameworks f
  INNER JOIN uses_language ul ON ul.framework = f.id
  INNER JOIN languages l ON l.id = ul.language
WHERE l.name = 'Dart'
ORDER BY f.name ASC, f.popularity DESC
LIMIT 5 OFFSET 5 * 3
  ''');
// ???
profit();
```