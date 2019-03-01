import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sally/diff_util.dart';

typedef Widget ItemBuilder<T>(
    BuildContext context, T item, Animation<double> anim);
typedef Widget RemovedItemBuilder<T>(
    BuildContext context, T item, Animation<double> anim);

/// An [AnimatedList] that shows the result of a sally query stream.
class SallyAnimatedList<T> extends StatefulWidget {
  final Stream<List<T>> stream;
  final ItemBuilder<T> itemBuilder;
  final RemovedItemBuilder<T> removedItemBuilder;

  SallyAnimatedList(
      {@required this.stream,
      @required this.itemBuilder,
      @required this.removedItemBuilder});

  @override
  _SallyAnimatedListState<T> createState() {
    return _SallyAnimatedListState<T>();
  }
}

class _SallyAnimatedListState<T> extends State<SallyAnimatedList<T>> {
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
      final editScript = diff(_lastSnapshot, data);

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
  void didUpdateWidget(SallyAnimatedList<T> oldWidget) {
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
