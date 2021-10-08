import 'package:moor/moor.dart' show $mrjf, $mrjc;

int hashAll(List<dynamic> objects) {
  if (objects.length == 1) {
    return objects.single.hashCode;
  } else {
    final firstHash = objects.first.hashCode;
    // create a chain of $mrjc(first, $mrjc(second, ...)), finish it off with a
    // $mrjf in the end.
    return $mrjf(objects.skip(1).map((o) => o.hashCode).fold(firstHash, $mrjc));
  }
}
