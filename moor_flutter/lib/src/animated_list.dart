import 'dart:async';

import 'package:flutter/widgets.dart';

// ignore: deprecated_member_use
import 'package:moor/diff_util.dart';

typedef Widget ItemBuilder<T>(
    BuildContext context, T item, Animation<double> anim);
typedef Widget RemovedItemBuilder<T>(
    BuildContext context, T item, Animation<double> anim);

/// An [AnimatedList] that shows the result of a moor query stream.
@Deprecated('Will be removed in moor 2.0. You could use the '
    'animated_stream_list package as an alternative')
class MoorAnimatedList<T> extends StatefulWidget {
  final Stream<List<T>> stream;
  final ItemBuilder<T> itemBuilder;
  final RemovedItemBuilder<T> removedItemBuilder;

  /// A function that decides whether two items are considered equal. By
  /// default, `a == b` will be used. A customization is useful if the content
  /// of items can change (e.g. when a title changes, you'd only want to change
  /// one text and not let the item disappear to show up again).
  final bool Function(T a, T b) equals;

  MoorAnimatedList(
      {@required this.stream,
      @required this.itemBuilder,
      @required this.removedItemBuilder,
      this.equals});

  @override
  _MoorAnimatedListState<T> createState() {
    return _MoorAnimatedListState<T>();
  }
}

class _MoorAnimatedListState<T> extends State<MoorAnimatedList<T>> {
  List<T> _lastSnapshot;
  int _initialItemCount;

  StreamSubscription _subscription;

  final GlobalKey<AnimatedListState> _key = GlobalKey();
  AnimatedListState get listState => _key.currentState;

  @override
  void initState() {
    _setupSubscription();
    super.initState();
  }

  void _receiveData(List<T> data) {
    if (listState == null) {
      setState(() {
        _lastSnapshot = data;
        _initialItemCount = data.length;
      });
      return;
    }

    if (_lastSnapshot == null) {
      // no diff possible. Initialize lists instead of diffing
      _lastSnapshot = data;
      for (var i = 0; i < data.length; i++) {
        listState.insertItem(i);
      }
    } else {
      final editScript = diff(_lastSnapshot, data, equals: widget.equals);

      for (var action in editScript) {
        if (action.isDelete) {
          // we need to delete action.amount items at index action.index
          for (var i = 0; i < action.amount; i++) {
            // i items have already been deleted, so + 1 for the index. Notice
            // that we don't have to do this when calling removeItem on the
            // animated list state, as it will reflect the operation immediately.
            final itemHere = _lastSnapshot[action.index + i];
            listState.removeItem(action.index, (ctx, anim) {
              return widget.removedItemBuilder(ctx, itemHere, anim);
            });
          }
        } else {
          for (var i = 0; i < action.amount; i++) {
            listState.insertItem(action.index + i);
          }
        }
      }

      setState(() {
        _lastSnapshot = data;
      });
    }
  }

  void _setupSubscription() {
    _subscription = widget.stream.listen(_receiveData);
  }

  @override
  void didUpdateWidget(MoorAnimatedList<T> oldWidget) {
    _subscription?.cancel();
    _lastSnapshot = null;
    _setupSubscription();

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastSnapshot == null) return const SizedBox();

    return AnimatedList(
      key: _key,
      initialItemCount: _initialItemCount ?? 0,
      itemBuilder: (ctx, index, anim) {
        final item = _lastSnapshot[index];
        final child = widget.itemBuilder(ctx, item, anim);

        return child;
      },
    );
  }
}
