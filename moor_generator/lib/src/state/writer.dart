import 'package:meta/meta.dart';

/// Manages a tree structure which we use to generate code.
///
/// Each leaf in the tree is a [StringBuffer] that contains some code. A
/// [Scope] is a non-leaf node in the tree. Why are we doing this? Sometimes,
/// we're in the middle of generating the implementation of a method and we
/// realize we need to introduce another top-level class! When passing a single
/// [StringBuffer] to the generators that will get ugly to manage, but when
/// passing a [Scope] we will always be able to write code in a parent scope.
class Writer {
  final Scope _root = Scope(parent: null);

  String writeGenerated() => _leafNodes(_root).join();

  Iterable<StringBuffer> _leafNodes(Scope scope) sync* {
    for (var child in scope._children) {
      if (child is _LeafNode) {
        yield child.buffer;
      } else if (child is Scope) {
        yield* _leafNodes(child);
      }
    }
  }

  Scope child() => _root.child();
  StringBuffer leaf() => _root.leaf();
}

abstract class _Node {
  final Scope parent;

  _Node(this.parent);
}

/// A single lexical scope that is a part of a [Writer].
///
/// The reason we use scopes to write generated code is that some implementation
/// methods might need to introduce additional classes when written. When we can
/// create a new text leaf of the root node, this can be done very easily. When
/// we just pass a single [StringBuffer] around, this is annoying to manage.
class Scope extends _Node {
  final List<_Node> _children = [];

  Scope({@required Scope parent}) : super(parent);

  Scope get root {
    var found = this;
    while (found.parent != null) {
      found = found.parent;
    }
    return found;
  }

  Scope child() {
    final child = Scope(parent: this);
    _children.add(child);
    return child;
  }

  StringBuffer leaf() {
    final child = _LeafNode(this);
    _children.add(child);
    return child.buffer;
  }
}

class _LeafNode extends _Node {
  final StringBuffer buffer = StringBuffer();

  _LeafNode(Scope parent) : super(parent);
}
