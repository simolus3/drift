import 'package:moor_example/database/database.dart';
import 'package:moor_flutter/moor_flutter.dart';
import 'package:rxdart/rxdart.dart';

/// Class that keeps information about a category and whether it's selected at
/// the moment.
class CategoryWithActiveInfo {
  CategoryWithCount categoryWithCount;
  bool isActive;

  CategoryWithActiveInfo(this.categoryWithCount, this.isActive);
}

class TodoAppBloc {
  final Database db;

  // the category that is selected at the moment. null means that we show all
  // entries
  final BehaviorSubject<Category?> _activeCategory =
      BehaviorSubject.seeded(null);

  late final Stream<List<EntryWithCategory>> _currentEntries;

  /// A stream of entries that should be displayed on the home screen.
  Stream<List<EntryWithCategory>> get homeScreenEntries => _currentEntries;

  final BehaviorSubject<List<CategoryWithActiveInfo>> _allCategories =
      BehaviorSubject();
  Stream<List<CategoryWithActiveInfo>> get categories => _allCategories;

  TodoAppBloc() : db = Database() {
    // listen for the category to change. Then display all entries that are in
    // the current category on the home screen.
    _currentEntries = _activeCategory.switchMap(db.watchEntriesInCategory);

    // also watch all categories so that they can be displayed in the navigation
    // drawer.
    Rx.combineLatest2<List<CategoryWithCount>, Category?,
        List<CategoryWithActiveInfo>>(
      db.categoriesWithCount(),
      _activeCategory,
      (allCategories, selected) {
        return allCategories.map((category) {
          final isActive = selected?.id == category.category?.id;

          return CategoryWithActiveInfo(category, isActive);
        }).toList();
      },
    ).listen(_allCategories.add);
  }

  void showCategory(Category? category) {
    _activeCategory.add(category);
  }

  Future<void> addCategory(String description) async {
    final id = await db.createCategory(description);

    showCategory(Category(id: id, description: description));
  }

  void createEntry(String content) {
    db.createEntry(TodosCompanion(
      content: Value(content),
      category: Value(_activeCategory.value?.id),
    ));
  }

  void updateEntry(TodoEntry entry) {
    db.updateEntry(entry);
  }

  void deleteEntry(TodoEntry entry) {
    db.deleteEntry(entry);
  }

  void deleteCategory(Category category) {
    // if the category being deleted is the one selected, reset that state by
    // showing the entries who aren't in any category
    if (_activeCategory.value?.id == category.id) {
      showCategory(null);
    }

    db.deleteCategory(category);
  }

  void close() {
    db.close();
    _allCategories.close();
  }
}
