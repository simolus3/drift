import 'dart:async';

import 'package:drift3_preview/drift.dart';
import 'package:test/test.dart';

import 'package:drift/src/drift3_preview/src/utils/synchronized.dart';

void main() {
  group('SharedOrExclusiveLock', () {
    test('can acquire multiple shared locks', () async {
      final lock = SharedOrExclusiveLock();
      await lock.shared(() async {
        await lock.shared(() async {});
      });
    });

    test('shared lock blocks exclusive lock', () async {
      final lock = SharedOrExclusiveLock();

      final hasShared = Completer<void>();
      final releaseShared = Completer<void>();
      lock.shared(() async {
        hasShared.complete();
        await releaseShared.future;
      });
      await hasShared.future;

      var hasExclusive = false;
      lock.exclusive(() async {
        hasExclusive = true;
      });
      await pumpEventQueue();
      expect(hasExclusive, isFalse);

      releaseShared.complete();
      await pumpEventQueue(times: 1);
      expect(hasExclusive, isTrue);
    });

    test('exclusive lock blocks shared lock', () async {
      final lock = SharedOrExclusiveLock();

      final hasExclusive = Completer<void>();
      final releaseExclusive = Completer<void>();
      lock.exclusive(() async {
        hasExclusive.complete();
        await releaseExclusive.future;
      });
      await hasExclusive.future;

      var hasShared = false;
      lock.shared(() async {
        hasShared = true;
      });
      await pumpEventQueue();
      expect(hasShared, isFalse);

      releaseExclusive.complete();
      await pumpEventQueue(times: 1);
      expect(hasShared, isTrue);
    });

    test('can abort waiting', () async {
      final lock = SharedOrExclusiveLock();

      await lock.exclusive(() async {
        await expectLater(
          lock.shared(() {}, AbortToken(pumpEventQueue())),
          throwsA(isA<AbortException>()),
        );
      });
    });
  });
}
