part of '../analysis.dart';

class SetParentVisitor {
  const SetParentVisitor();

  void startAtRoot(AstNode root) {
    _applyFor(root, null);
  }

  void _applyFor(AstNode node, AstNode parent) {
    node.parent = parent;

    for (var child in node.childNodes) {
      _applyFor(child, node);
    }
  }
}
