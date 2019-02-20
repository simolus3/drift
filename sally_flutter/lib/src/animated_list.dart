/*
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sally_flutter/src/utils.dart';

typedef Widget AppearingAnimationBuilder<T>(
    BuildContext ctx, T item, Animation<double> animation,
    {int index});
typedef Widget OutgoingAnimationBuilder<T>(
    BuildContext ctx, T item, Animation<double> animation,
    {int index});

/// A list that animatse
class AnimatedStreamList<T> extends StatefulWidget {
  static const Widget _defaultPlaceholder = SizedBox();

  /// Builder that builds widget as they appear on the list.
  final AppearingAnimationBuilder<T> appearing;

  /// Builder that builds widgets as they leave the list.
  final OutgoingAnimationBuilder<T> leaving;

  /// Widget that will be built when the stream emits an empty list after all
  /// remaining list items have animated away.
  final WidgetBuilder empty;

  /// Widget that will be built when the stream has not yet emitted any item.
  final WidgetBuilder loading;

  AnimatedStreamList(
      {@required this.appearing,
      @required this.leaving,
      this.empty,
      this.loading});

  @override
  _AnimatedStreamListState<T> createState() => _AnimatedStreamListState<T>();
}

const Duration _kDuration = Duration(milliseconds: 300);

class _AnimatedStreamListState<T> extends State<AnimatedStreamList<T>>
    with TickerProviderStateMixin {
  StreamSubscription _subscription;

  List<T> _lastSnapshot;
  final List<_AnimatedItemState> _insertingItems = [];
  final List<_AnimatedItemState> _leavingItems = [];

  void _handleDataReceived(List<T> data) {
    if (_lastSnapshot == null) {
      for (var i = 0; i < data.length; i++) {
        _animateIncomingItem(i);
      }
    } else {

    }

    setState(() {
      _lastSnapshot = data;
    });
  }

  void _animateIncomingItem(int index) {
    final controller = AnimationController(vsync: this);
    final state = _AnimatedItemState(controller, true, index);

    insertIntoSortedList<_AnimatedItemState>(_insertingItems, state,
        compare: (a, b) => a.itemIndex.compareTo(b.itemIndex));
  }

  void _animateOutgoingItem(int index) {

  }

  @override
  void initState() {}

  @override
  void didUpdateWidget(AnimatedStreamList oldWidget) {}

  @override
  void dispose() {
    for (var item in _insertingItems) {
      item._controller.dispose();
    }
    for (var item in _leavingItems) {
      item._controller.dispose();
    }

    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastSnapshot == null) {
      // no data yet, show placeholder
      return widget.loading != null
          ? widget.loading(context)
          : AnimatedStreamList._defaultPlaceholder;
    } else if (_lastSnapshot.isEmpty && _leavingItems.isEmpty) {
      return widget.empty != null
          ? widget.empty(context)
          : AnimatedStreamList._defaultPlaceholder;
    }

    return ListView.builder(
      itemBuilder: (ctx, i) {},
      itemCount: _lastSnapshot.length + _leavingItems.length,
    );
  }
}

class _AnimatedItemState {
  final AnimationController _controller;
  final bool isInserting;
  int itemIndex;

  _AnimatedItemState(this._controller, this.isInserting, this.itemIndex);
}
*/
