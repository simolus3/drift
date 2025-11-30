// ignore_for_file: avoid_single_cascade_in_expression_statements, unused_local_variable

import 'package:drift/drift.dart';

import '../_shared/todo_tables.dart';
import '../_shared/todo_tables.drift.dart';

abstract class Animals extends Table {
  IntColumn get amountOfLegs;
  IntColumn get averageLivespan;

  BoolColumn get isMammal;
}

class Animal {}

abstract class Products extends Table {
  IntColumn get price;
}

class Product {}

extension Snippets on CanUseCommonTables {
  TableInfo<Animals, Animal> get animals => throw 'stub';
  TableInfo<Products, Product> get products => throw 'stub';

  void compare() {
    // #docregion comparison
    // find all animals with less than 5 legs:
    (select(animals)..where((a) => a.amountOfLegs.isSmallerThanValue(5))).get();

    // find all animals who's average livespan is shorter than their amount of legs (poor flies)
    (select(animals)
      ..where((a) => a.averageLivespan.isSmallerThan(a.amountOfLegs)));

    Future<List<Animal>> findAnimalsByLegs(int legCount) {
      return (select(
        animals,
      )..where((a) => a.amountOfLegs.equals(legCount))).get();
    }
    // #enddocregion comparison

    findAnimalsByLegs(3);
  }

  void booleanAlgebra() {
    // #docregion boolean
    // find all animals that aren't mammals and have 4 legs
    select(animals)..where((a) => a.isMammal.not() & a.amountOfLegs.equals(4));

    // find all animals that are mammals or have 2 legs
    select(animals)..where((a) => a.isMammal | a.amountOfLegs.equals(2));
    // #enddocregion boolean

    Animals a = animals.asDslTable;

    // #docregion listand
    Expression.and([a.isMammal, a.amountOfLegs.equals(4)]);
    // #enddocregion listand
  }

  // #docregion arithmetic
  Future<List<Product>> canBeBought(int amount, int budget) {
    return (select(products)..where((p) {
          final totalPrice = p.price * Variable(amount);
          return totalPrice.isSmallerOrEqualValue(budget);
        }))
        .get();
  }
  // #enddocregion arithmetic

  // #docregion emptyCategories
  Future<List<Category>> emptyCategories() {
    final hasNoTodo = notExistsQuery(
      select(todoItems)..where((row) => row.category.equalsExp(categories.id)),
    );
    return (select(categories)..where((row) => hasNoTodo)).get();
  }
  // #enddocregion emptyCategories

  void queries() {
    // #docregion date1
    select(users).where((u) => u.birthDate.year.isSmallerThanValue(1950));
    // #enddocregion date1

    // #docregion nullCheck
    final withoutCategories = select(todoItems)
      ..where((row) => row.category.isNull());
    // #enddocregion nullCheck

    // #docregion coalesce
    final category = coalesce([todoItems.category, const Constant(1)]);
    // #enddocregion coalesce

    // #docregion isIn
    select(animals)..where((a) => a.amountOfLegs.isIn([3, 7, 4, 2]));
    // #enddocregion isIn
  }

  // #docregion averageItemLength
  Stream<double> averageItemLength() {
    final avgLength = todoItems.content.length.avg();

    final query = selectOnly(todoItems)..addColumns([avgLength]);

    return query.map((row) => row.read(avgLength)!).watchSingle();
  }
  // #enddocregion averageItemLength

  void counting() {
    // #docregion counting
    final amountOfTodos = todoItems.id.count();

    final query = db.select(categories).join([
      innerJoin(
        todoItems,
        todoItems.category.equalsExp(categories.id),
        useColumns: false,
      ),
    ]);
    query
      ..addColumns([amountOfTodos])
      ..groupBy([categories.id]);
    // #enddocregion counting
  }

  // #docregion allTodoContent
  Stream<String> allTodoContent() {
    final allContent = todoItems.content.groupConcat();
    final query = selectOnly(todoItems)..addColumns([allContent]);

    return query.map((row) => row.read(allContent)!).watchSingle();
  }
  // #enddocregion allTodoContent

  // #docregion findTodosInCategory
  Future<List<TodoItem>> findTodosInCategory(String category) async {
    final groupId = selectOnly(categories)
      ..addColumns([categories.id])
      ..where(categories.name.equals(category));

    final query = select(todoItems)
      ..where((row) => row.category.equalsExp(subqueryExpression(groupId)));
    return await query.get();
  }
  // #enddocregion findTodosInCategory

  void customExpressions() {
    // #docregion custom
    const inactive = CustomExpression<bool>(
      "julianday('now') - julianday(last_login) > 60",
    );
    select(users)..where((u) => inactive);
    // #enddocregion custom
  }

  // #docregion date2
  Future<void> increaseDueDates() async {
    final change = TodoItemsCompanion.custom(
      dueDate: todoItems.dueDate + Duration(days: 1),
    );
    await update(todoItems).write(change);
  }
  // #enddocregion date2

  // #docregion date3
  Future<void> moveDueDateToNextMonday() async {
    final change = TodoItemsCompanion.custom(
      dueDate: todoItems.dueDate.modify(
        DateTimeModifier.weekday(DateTime.monday),
      ),
    );
    await update(todoItems).write(change);
  }
  // #enddocregion date3

  // #docregion window
  /// Returns all todo items, associating each item with the total length of all
  /// titles up until (and including) each todo item.
  Selectable<(TodoItem, int)> todosWithRunningLength() {
    final runningTitleLength = WindowFunctionExpression(
      todoItems.title.length.sum(),
      orderBy: [OrderingTerm.asc(todoItems.id)],
    );
    final query = select(todoItems).addColumns([runningTitleLength]);
    query.orderBy([OrderingTerm.asc(todoItems.id)]);

    return query.map((row) {
      return (row.readTable(todoItems)!, row.read(runningTitleLength)!);
    });
  }
  // #enddocregion window

  // #docregion window2
  /// Returns all todo items, also reporting the index (counting from 1) each
  /// todo item would have if all items were sorted by descending content
  /// length.
  Selectable<(TodoItem, int)> todosWithLengthRanking() {
    final lengthRanking = WindowFunctionExpression(
      todoItems.id.count(),
      orderBy: [OrderingTerm.desc(todoItems.content.length)],
    );
    final query = select(todoItems).addColumns([lengthRanking]);

    return query.map((row) {
      return (row.readTable(todoItems)!, row.read(lengthRanking)!);
    });
  }
  // #enddocregion window2

  // #docregion rowvalue-use
  void rowValuesUsage() {
    select(animals).where((row) {
      // Generates (amount_of_legs, average_livespan) < (?, ?)
      return RowValues([
        row.amountOfLegs,
        row.averageLivespan,
      ]).isSmallerThan(RowValues([Variable(2), Variable(10)]));
    });
  }

  // #enddocregion rowvalue-use
}

// #docregion bitwise
Expression<int> bitwiseMagic(Expression<int> a, Expression<int> b) {
  // Generates `~(a & b)` in SQL.
  return ~(a.bitwiseAnd(b));
}
// #enddocregion bitwise

// #docregion row-values
/// Writes row values (`(1, 2, 3)`) into SQL. We use [Never] as a bound because
/// this expression cannot be evaluated, it's only useful as a subexpression.
final class RowValues extends Expression<Never> {
  final List<Expression> expressions;

  RowValues(this.expressions);

  @override
  Precedence get precedence => Precedence.primary;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write('(');

    for (final (i, expr) in expressions.indexed) {
      if (i != 0) context.buffer.write(', ');

      expr.writeInto(context);
    }

    context.buffer.write(')');
  }
}

// #enddocregion row-values
