This is the [DevTools extension](https://pub.dev/packages/devtools_extensions) for drift,
based on the [drift_db_viewer](https://pub.dev/packages/drift_db_viewer) package.

## Debugging

To run the extension in standalone mode, run

```console
flutter run -d chrome --dart-define=use_simulated_environment=true
```

You'd also need to run an app with a drift database for you to be able to see it running.
You can use our example app for that.

```console
cd ../../examples/app/
flutter run --debug
```

Once the example app launches, it will print out something like:

```console
Connecting to VM Service at ws://127.0.0.1:33333/7j9YZqoiWe8=/ws
```

or

```console
This app is linked to the debug service: ws://127.0.0.1:33333/7j9YZqoiWe8=/ws
```

or even

```console
Debug service listening on ws://127.0.0.1:33333/7j9YZqoiWe8=/ws
```

What you will need to do is to copy everything from `//127.0.0.1` to `=/` (no `ws`) and
add `http:` in front and paste this inside the `Dart VM Service Connection` that appears
on the right side of the simulated environment. Then simply click on the `Connect` button
or press Return/Enter and you'll see the database connected there.
