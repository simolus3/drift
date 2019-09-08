part of 'assist_service.dart';

class ColumnNullability extends _AssistOnNodeContributor<ColumnDefinition> {
  const ColumnNullability();

  @override
  void contribute(
      AssistCollector collector, ColumnDefinition node, String path) {
    final notNull = node.findConstraint<NotNull>();

    if (notNull == null) {
      // there is no not-null constraint on this column, suggest to add one at
      // the end of the definition
      final end = node.lastPosition;
      final id = AssistId.makeNotNull;

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
      final id = AssistId.makeNullable;

      collector.addAssist(PrioritizedSourceChange(
        id.priority,
        SourceChange('Make this column nullable', id: id.id, edits: [
          SourceFileEdit(path, -1, edits: [
            SourceEdit(notNull.firstPosition, notNull.lastPosition, '')
          ])
        ]),
      ));
    }
  }
}
