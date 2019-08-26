Playground to test the analyzer plugin for `.moor` files. 

## Playing around with this
At the moment, [DartCode](https://dartcode.org/) with version `v3.4.0-beta.2` is needed to run the
plugin. To set up the plugin, run the following steps

1. Change the file `moor/tools/analyzer_plugin/pubspec.yaml` so that the `dependency_overrides`
   section points to the location where you cloned this repository. This is needed because we
   can't use relative paths for dependencies in analyzer plugins yet.
2. In VS Code, change `dart.additionalAnalyzerFileExtensions` to include `moor` files:
   ```json
   {
       "dart.additionalAnalyzerFileExtensions": [
           "moor"
       ]
   }
   ```
3. If you already had the project open, close and re-open VS Code. Otherwise, simply open this
   project.
4. Type around in a `.moor` file - notice how you still don't get syntax highlighting because
   VS Code required a static grammar for files and can't use a language server for that :(

Debugging plugins is not fun. See the [docs](https://github.com/dart-lang/sdk/blob/master/pkg/analyzer_plugin/doc/tutorial/debugging.md)
on some general guidance, and good luck. Enabling the analyzer diagnostics server can help.
