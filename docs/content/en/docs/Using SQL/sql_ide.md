---
title: "Experimental IDE"
weight: 5
description: Get real-time feedback as you type sql
---

Moor ships with an experimental analyzer plugin that provides real-time feedback on errors,
hints, folding and outline.

## Using with VS Code

Make sure that your project depends on moor 2.0 or later. Then

1. In the preferences, make sure that the `dart.analyzeAngularTemplates` option is
   set to true.
2. Tell Dart Code to analyze moor files as well. Add this to your `settings.json`:
   ```json
   "dart.additionalAnalyzerFileExtensions": [
        "moor"
    ]
    ```
3. Enable the plugin in Dart: Create a file called `analysis_options.yaml` in your project root,
   next to your pubspec. It should contain this section:
   ```yaml
   analyzer:
     plugins:
       - moor
   ```
4. Finally, close and reopen your IDE so that the analysis server is restarted. The analysis server will
   then load the moor plugin and start providing analysis results for `.moor` files. Loading the plugin
   can take some time (around a minute for the first time).

## Other IDEs

Unfortunately, we can't support IntelliJ and Android Studio yet. Please vote on
[this issue](https://youtrack.jetbrains.com/issue/WEB-41424) to help us here!

If you're looking for support for an other IDE that uses the Dart analysis server,
please create an issue. We can very probably make that happen.