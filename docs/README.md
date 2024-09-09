### Documentation for the Drift package

Folder Structure:

- `builders` Contains the builders for the snippets and dart projects versions (`versions.json` and `*.excerpt.json` in `lib`).
- `docs` Contains the markdown files for the documentation.
- `deploy` The output of the documentation build.
- `lib` Contains the code snippets for the documentation.
- `test` Contains the tests for the documentation.
- `web` Contains some dart which code which is compiled to JavaScript and served with the documentation.
- `stubs` Contains dummy projects for the snippets to reference.
- `mkdocs` Contains the MkDocs configuration.

### Building the Documentation
You will need to make the `docs.sh` script executable before you can run it. You can do this by running the following command:

```bash
chmod +x docs.sh
```

Run the following command to build the documentation:

```bash
docs.sh build
```

### 
Run the following command to build the documentation:

```bash
docs.sh serve
```

If you would like changes to snippets to be available in real-time, you can run the following command:

```bash
docs.sh serve --with-build-runner
```

### Syntax Highlighting
The CSS for the syntax highlighting rarely changes. It can be found in the `docs/docs/css` folder. If you need to update it, run the `docs/builders/src/css_classes.dart` file which outputs the contents of the CSS file.


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

