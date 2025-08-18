### Documentation for the Drift package

Folder Structure:

- `builders` Contains the builders for the snippets and dart projects versions (`versions.json` and `*.excerpt.json` in `lib`).
- `docs` Contains the markdown files for the documentation.
- `deploy` The output of the documentation build.
- `lib` Contains the code snippets for the documentation.
- `test` Contains the tests for the documentation.
- `web` Contains some dart which code which is compiled to JavaScript and served with the documentation.
- `mkdocs` Contains the MkDocs configuration.

### Building the Documentation

You will need to make the `docs.sh` script executable before you can run it. You can do this by running the following command:

```bash
chmod +x docs.sh

# Also, make sure webdev is installed:
dart pub global activate webdev
```

Run the following command to build the documentation:

```bash
docs.sh build
```

### Serving the Documentation

You can also serve the documentation locally and view it in your browser.
Changes to the documentation will be reflected in real-time.

Run the following command to serve the documentation:

```bash
docs.sh serve
```
If you would like changes to snippets to be available in real-time, you can run the following command:

```bash
docs.sh serve --with-build-runner
```

##### Limitations of Serving the Documentation

- The flutter example project will not be built when serving. If you would like the flutter example to be available while serving the docs, you will need to run the `docs.sh build` 1st.
  ```bash
  docs.sh build
  docs.sh serve
  ```
- The `web` folder will not be watch for changes. If you change code in the `web` folder, you will have to kill the server and restart it.

### Understanding the Build Process

Behind the scenes, the `docs.sh` script does the following:
1. Running `webdev`:
    - Creates `versions.json` which will inject the latest version into MkDocs. e.g. `^{{ versions.drift }}`
    - Creates `.excerpt.json` snippet files in `lib` which MkDocs will use to inject syntax highlighted code into the documentation. e.g. `{{ load_snippet('flutter','lib/snippets/setup/database.dart.excerpt.json') }}`
    - Run the `drift_dev` builder to generate the code for the snippets.
    - Compile the dart code in `web` to JavaScript.
2. Running `mkdocs`:
    - Compile the markdown files in `docs` to HTML.
3. Combine the output of the two steps into the `deploy` folder.

### Syntax Highlighting

Code which is included in markdown using \`\`\` \`\`\` snippets is highlighted by mkdocs automatically. These colors can be modified by following the instructions in the [MkDocs documentation](https://squidfunk.github.io/mkdocs-material/reference/code-blocks/#custom-syntax-theme).

Code snippets which are included in the documentation using the `{{ load_snippet() }}` macro are highlighted too. If they are from a `.dart` file we use a custom syntax highlighter, otherwise we use the default MkDocs syntax highlighter.

When `build_runner` runs, it will create a `*.excerpt.json` next to each snippet file which contains each snippet in styled HTML (`dart`) or in raw text (all other languages). The `{{ load_snippet() }}` macro injects the snippets from these `*.excerpt.json` files. The code for this macro can be found in `/docs/mkdocs/main.py`.
