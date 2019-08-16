# Integration tests

These directories contain integration tests for the various moor backends by running the same 
set of actions on multiple databases.

## Tests
All test cases live in `tests/lib`. We have a `runAllTests` method that basically takes a
`QueryExecutor` (the database backend in moor) and then runs all tests on that executor.
Everything the other packages are doing is calling the `runAllTests` method with the
database they're supposed to test.

------

Flutter is a bit annoying here because AFAIK there is no easy way to run tests that run on
a real device? With `flutter drive`, the tests are still run on a local machine which
communicates with an app to verify behavior of widgets. As we want to run the whole test bundle 
on a device, we instead put the test files into `flutter_db/lib` and run them with
`flutter run`. That works, but we don't get an output format that is machine readable.
Please create an issue if you know a better way, thanks!
TODO: https://github.com/tomaszpolanski/flutter-presentations/blob/master/lib/test_driver/test_runner.dart
looks promising

That is also why these tests are not running automatically.