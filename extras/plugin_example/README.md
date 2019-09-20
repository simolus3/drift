Playground to test the analyzer plugin for `.moor` files. 

Currently, we support

- showing errors in moor files
- outline
- (kinda) folding

## Setup
To use this plugin, you'll need to perform these steps once. It is assumed that you
have already cloned the `moor` repository.

1. Clone https://github.com/simolus3/Dart-Code and checkout the
   `use-custom-file-endings` branch.
2. Run `npm install` and `npm run build` to verify that everything is working.
3. Open the forked Dart-Code repo in your regular VS Code installation.
4. Press `F5` to run the plugin in another editor instance. All subsequent 
   steps need to be completed in that editor.
5. In the settings of that editor, change `dart.additionalAnalyzerFileExtensions`
   to include `moor` files:
   ```json
   {
       "dart.additionalAnalyzerFileExtensions": ["moor"]
   }
   ```
6. Close that editor.
7. Uncomment the plugin lines in `analysis_options.yaml`
  
## Running
After you completed the setup, these steps will open an editor instance that runs the plugin.
1. chdir into `moor_generator` and run `lib/plugin.dart`. You can run that file from an IDE if
   you need debugging capabilities, but starting it from the command line is fine. Keep that
   script running.
2. Re-open the "inner" editor with the custom Dart plugin
2. Open this folder in the editor that runs the custom Dart plugin. Wait ~15s, you should start
   to see some log entries in the output of step 1. As soon as they appear, the plugin is ready
   to go.
   
_Note_: `lib/plugin.dart` doesn't support multiple clients. Whenever you close or reload the
editor, that script needs to be restarted as well. That script should also be running before 
starting the analysis server.
