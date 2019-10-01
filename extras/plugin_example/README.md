Playground to test the analyzer plugin for `.moor` files. 

Currently, we support

- showing errors in moor files
- outline
- folding
- (very, very limited) autocomplete
-  some quickfixes to make columns nullable or non-null
- navigation for references in sql queries

## Setup
To debug this plugin, you'll need to perform these steps once. It is assumed that you
have already cloned the `moor` repository.

1. Make sure you run version `3.5.0` or later of the Dart extension in VS Code.
2. In the editor settings, change `dart.additionalAnalyzerFileExtensions`
   to include `moor` files:
   ```json
   {
       "dart.additionalAnalyzerFileExtensions": ["moor"]
   }
   ```
3. Uncomment the plugin lines in `analysis_options.yaml`
  
## Running
After you completed the setup, these steps will open an editor instance that runs the plugin.
1. chdir into `moor_generator` and run `lib/plugin.dart`. You can run that file from an IDE if
   you need debugging capabilities, but starting it from the command line is fine. Keep that
   script running.
2. Open this folder in the code instance
3. Wait ~15s, you should start to see some log entries in the output of step 1. 
   As soon as they appear, the plugin is ready to go.
   
_Note_: `lib/plugin.dart` doesn't support multiple clients. Whenever you close or reload the
editor, that script needs to be restarted as well. That script should also be running before 
starting the analysis server.

## Troubleshooting

If the plugin doesn't start properly, you can

1. make sure it was picked up by the analysis server: You set the `dart.analyzerDiagnosticsPort`
   to any port and see some basic information under the "plugins" tab of the website started.
2. When setting `dart.analyzerInstrumentationLogFile`, the analysis server will write the
   exception that caused the plugin to stop