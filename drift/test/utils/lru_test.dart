// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:drift/src/sqlite3/database.dart';
import 'package:test/test.dart';

void main() {
  test("lru/mru order and remove callback", () {
    var removedEntries = <Entry<String, String>>[];
    final map = LruMap<String, String>(
      maximumSize: 3,
      onItemRemoved: (k, v) {
        removedEntries.add(Entry(k, v));
      },
    );

    map["a"] = "Alpha";
    map["b"] = "Beta";
    map["c"] = "Charlie";

    expect(map.lruKey, "a");
    expect(map.mruKey, "c");

    map["d"] = "Delta";

    // a is removed and b is the new lru
    expect(map["a"], isNull);
    expect(map.lruKey, "b");

    // onItemRemoved gets called
    expect(removedEntries, [
      Entry("a", "Alpha"),
    ]);
    removedEntries.clear();

    // Remove c
    final c = map.remove("c");
    expect(c, "Charlie");

    // onItemRemoved gets called
    expect(removedEntries, [
      Entry("c", "Charlie"),
    ]);
    removedEntries.clear();

    // Clear all
    map.clear();

    // onItemRemoved gets called
    expect(removedEntries, [
      Entry("b", "Beta"),
      Entry("d", "Delta"),
    ]);
  });
}

class Entry<K, V> {
  final K key;
  final V value;

  Entry(this.key, this.value);

  @override
  bool operator ==(covariant Entry<K, V> other) {
    if (identical(this, other)) return true;

    return other.key == key && other.value == value;
  }

  @override
  int get hashCode => Object.hash(key, value);
}
