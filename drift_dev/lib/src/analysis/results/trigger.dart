import 'element.dart';
import 'query.dart';

class DriftTrigger extends DriftElement {
  @override
  final List<DriftElement> references;

  /// The `CREATE TRIGGER` statement creating this trigger.
  final String createStmt;

  /// Writes performed in the body of this trigger.
  final List<WrittenDriftTable> writes;

  DriftTrigger(
    super.id,
    super.declaration, {
    required this.references,
    required this.createStmt,
    required this.writes,
  });
}
