import 'package:riverpod/riverpod.dart';

import '../../database/database.dart';

final activeCategory = StateProvider<Category?>((_) => null);

final entriesInCategory = StreamProvider((ref) {
  final database = ref.watch(AppDatabase.provider);
  final current = ref.watch(activeCategory)?.id;

  return database.entriesInCategory(current);
});
