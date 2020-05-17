import 'package:moor_generator/src/analyzer/runner/file_graph.dart';
import 'package:moor_generator/src/backends/common/file_tracker.dart';
import 'package:test/test.dart';

void main() {
  FileTracker tracker;

  final fa = FoundFile(Uri.parse('file://a'), FileType.dartLibrary);
  final fb = FoundFile(Uri.parse('file://b'), FileType.dartLibrary);
  final fc = FoundFile(Uri.parse('file://c'), FileType.dartLibrary);
  final fd = FoundFile(Uri.parse('file://d'), FileType.dartLibrary);

  setUp(() {
    tracker = FileTracker();
  });

  void notifyChanged(
      {bool a = false, bool b = false, bool c = false, bool d = false}) {
    tracker.notifyFilesChanged([
      if (a) fa,
      if (b) fb,
      if (c) fc,
      if (d) fd,
    ]);
  }

  tearDown(() {
    tracker.dispose();
  });

  test("doesn't report outstanding work in initial state", () {
    expect(tracker.hasWork, isFalse);
    expect(tracker.fileWithHighestPriority, isNull);
  });

  test('reports works after files were added', () {
    notifyChanged(a: true, c: true);
    expect(tracker.hasWork, isTrue);
    expect(tracker.fileWithHighestPriority, isNotNull);
  });

  test('priority-files are reported first', () {
    notifyChanged(a: true, b: true);
    tracker.setPriorityFiles([fa]);
    tracker.setPriorityFiles([fb]);

    expect(tracker.fileWithHighestPriority.file, fb);
  });

  test('can remove pending files', () {
    notifyChanged(a: true);
    expect(tracker.hasWork, isTrue);

    tracker.removePending(tracker.fileWithHighestPriority);
    expect(tracker.hasWork, isFalse);
  });
}
