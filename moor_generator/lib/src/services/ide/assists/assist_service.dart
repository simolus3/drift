//@dart=2.9
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:sqlparser/sqlparser.dart';

import '../utils.dart';

part 'column_nullability.dart';

class AssistContributor {
  AssistContributor();

  ColumnNullability get _nullability => const ColumnNullability();

  List<_AssistOnNodeContributor> get _nodeContributors => [_nullability];

  List<PrioritizedSourceChange> computeAssists(
      FoundFile file, int offset, int length, String path) {
    final moor = file.parsedMoorOrNull;
    final collector = _SimpleCollector();

    if (moor == null) return const [];

    final nodes = moor.parseResult.findNodesAtPosition(offset, length: length);
    final contributors = _nodeContributors;

    for (final node in nodes.expand((node) => node.selfAndParents)) {
      for (final contributor in contributors) {
        if (contributor.handles(node)) {
          contributor.contribute(collector, node, path);
        }
      }
    }

    return collector.assists;
  }
}

class _SimpleCollector implements AssistCollector {
  final List<PrioritizedSourceChange> assists = [];

  @override
  void addAssist(PrioritizedSourceChange assist) {
    assists.add(assist);
  }
}

abstract class _AssistOnNodeContributor<T extends AstNode> {
  const _AssistOnNodeContributor();

  bool handles(AstNode node) => node is T;

  void contribute(AssistCollector collector, T node, String path);

  SourceEdit replaceNode(AstNode node, String text) {
    final start = node.firstPosition;
    final length = node.lastPosition - start;
    return SourceEdit(start, length, text);
  }
}

class AssistId {
  final String id;
  final int priority;

  const AssistId._(this.id, this.priority);

  static const makeNullable = AssistId._('make_column_nullable', 100);
  static const makeNotNull = AssistId._('make_column_not_nullable', 10);
}
