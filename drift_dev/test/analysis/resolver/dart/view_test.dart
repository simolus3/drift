import 'package:drift/drift.dart' show DriftSqlType;
import 'package:drift_dev/src/analysis/results/results.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  test('can analyze Dart view', () async {
    final backend = TestBackend.inTest({
      'a|lib/main.dart': '''
import 'package:drift/drift.dart';

class TodoCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text().nullable()();
  IntColumn get categoryId => integer().references(TodoCategories, #id)();

  TextColumn get generatedText => text().nullable().generatedAs(
      title + const Constant(' (') + content + const Constant(')'))();
}

abstract class TodoCategoryItemCount extends View {
  TodoItems get todoItems;
  TodoCategories get todoCategories;

  Expression<int> get itemCount => todoItems.id.count();

  @override
  Query as() => select([
        todoCategories.name,
        itemCount,
      ]).from(todoCategories).join([
        innerJoin(todoItems, todoItems.categoryId.equalsExp(todoCategories.id))
      ]);
}

@DriftView(name: 'customViewName')
abstract class TodoItemWithCategoryNameView extends View {
  TodoItems get todoItems;
  TodoCategories get todoCategories;

  Expression<String> get title =>
      todoItems.title +
      const Constant('(') +
      todoCategories.name +
      const Constant(')');

  @override
  Query as() => select([todoItems.id, title]).from(todoItems).join([
        innerJoin(
            todoCategories, todoCategories.id.equalsExp(todoItems.categoryId))
      ]);
}
''',
    });

    final result =
        await backend.driver.fullyAnalyze(Uri.parse('package:a/main.dart'));
    expect(result.allErrors, isEmpty);

    final views =
        result.analysis.values.map((e) => e.result).whereType<DriftView>();
    expect(views, hasLength(2));

    final todoCategoryItemCount = views.singleWhere(
        (e) => e.definingDartClass.toString() == 'TodoCategoryItemCount');
    final todoItemWithCategoryName = views.singleWhere((e) =>
        e.definingDartClass.toString() == 'TodoItemWithCategoryNameView');

    expect(
        todoCategoryItemCount.source,
        isA<DartViewSource>().having(
            (e) => e.dartQuerySource.toString(),
            'dartQuerySource',
            '.join([ innerJoin(todoItems,todoItems.categoryId.equalsExp(todoCategories.id)) ])'));
    expect(
        todoItemWithCategoryName.source,
        isA<DartViewSource>().having(
            (e) => e.dartQuerySource.toString(),
            'dartQuerySource',
            '.join([ innerJoin(todoCategories,todoCategories.id.equalsExp(todoItems.categoryId)) ])'));
    expect(todoCategoryItemCount.columns, hasLength(2));
    expect(
        todoCategoryItemCount.columns[0],
        isA<DriftColumn>()
            .having((e) => e.nameInDart, 'nameInDart', 'name')
            .having((e) => e.nullable, 'nullable', isFalse));
    expect(
        todoCategoryItemCount.columns[1],
        isA<DriftColumn>()
            .having((e) => e.nameInDart, 'nameInDart', 'itemCount')
            .having((e) => e.sqlType.builtin, 'sqlType', DriftSqlType.int)
            .having((e) => e.nullable, 'nullable', isTrue));

    expect(todoItemWithCategoryName.columns, hasLength(2));
    expect(
        todoItemWithCategoryName.columns[0],
        isA<DriftColumn>()
            .having((e) => e.nameInDart, 'nameInDart', 'id')
            .having((e) => e.nullable, 'nullable', isFalse));
    expect(
        todoItemWithCategoryName.columns[1],
        isA<DriftColumn>()
            .having((e) => e.nameInDart, 'nameInDart', 'title')
            .having((e) => e.sqlType.builtin, 'sqlType', DriftSqlType.string)
            .having((e) => e.nullable, 'nullable', isTrue));
  });
}
