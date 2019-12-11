part of '../analysis.dart';

/// Sets the [AstNode.parent] property for each node in a tree.
class SetParentVisitor {
  const SetParentVisitor();

  void startAtRoot(AstNode root) {
    _applyFor(root, null);
  }

  void _applyFor(AstNode node, AstNode parent) {
    node.parent = parent;

    for (final child in node.childNodes) {
      assert(child != null, '$node had a null-child');
      _applyFor(child, node);
    }
  }
}
