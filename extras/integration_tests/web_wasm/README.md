Integration tests for `package:drift/native.dart`.

To run the tests automatically (with us managing a browser driver), just run `dart test`.

To manually debug issues, it might make sense to trigger some functionality manually.
You can run `dart run tool/serve_manually.dart` to start a web server hosting the test
content on <http://localhost:8080>.

Make sure to install [chromedriver](https://googlechromelabs.github.io/chrome-for-testing) and [geckodriver](https://github.com/mozilla/geckodriver/releases) for the test to use.