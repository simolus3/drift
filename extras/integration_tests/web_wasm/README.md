Integration tests for `package:drift/native.dart`.

To test persistence, we need to instrument a browsers in a way not covered by the normal
`test` package. For instance, we need to reload pages to ensure data is still there.

## Running tests with Firefox

```
geckodriver &
dart run tool/drift_wasm_test.dart firefox http://localhost:4444
```

## Running tests with Chrome

```
chromedriver --port=4444 --url-base=wd/hub &
dart run tool/drift_wasm_test.dart chrome http://localhost:4444/wd/hub/
```
