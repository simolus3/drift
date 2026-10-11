// dart format width=80
// ignore_for_file: type=lint
import 'package:drift3_preview/drift.dart' as i0;
import 'package:shared/src/posts.drift.dart' as i1;

final class SharedDrift extends i0.DatabaseAccessor {
  SharedDrift(i0.GeneratedDatabase db) : super(db);
  i1.PostsDrift get postsDrift => i1.PostsDrift(this.db);
}
