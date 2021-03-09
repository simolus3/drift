//@dart=2.9
part of 'assist_service.dart';

class ColumnNullability extends _AssistOnNodeContributor<ColumnDefinition> {
  const ColumnNullability();

  @override
  void contribute(
      AssistCollector collector, ColumnDefinition node, String path) {
    final notNull = node.findConstraint<NotNull>();

    if (notNull == null) {
      // there is no not-null constraint on this column, suggest to add one
      // after the type name
      final end = node.typeNames.last.span.end.offset;
      const id = AssistId.makeNotNull;

      collector.addAssist(PrioritizedSourceChange(
        id.priority,
        SourceChange('Add a NOT NULL constraint', id: id.id, edits: [
          SourceFileEdit(
            path,
            -1,
            edits: [
              SourceEdit(end, 0, ' NOT NULL'),
            ],
          )
        ]),
      ));
    } else {
      // suggest to remove the NOT NULL constraint, e.g. to make this column
      // nullable
      const id = AssistId.makeNullable;

      collector.addAssist(PrioritizedSourceChange(
        id.priority,
        SourceChange('Make this column nullable', id: id.id, edits: [
          SourceFileEdit(path, -1, edits: [replaceNode(notNull, '')])
        ]),
      ));
    }
  }
}
