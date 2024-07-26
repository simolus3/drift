### Documentation for the Drift package

Folder Structure:

- `bin` Contains the CLI for building and serving the documentation.
- `builders` Contains the builders for the documentation. (Version Extraction and Code Snippets Generation)
- `docs` Contains the markdown files for the documentation.
- `deploy` The output of the documentation build.
- `lib` Contains the snippets for the documentation.
- `test` Contains the tests for the documentation.
- `web` Contains some dart which code which is compiled to javascript and served with the documentation.
- `stubs` Contains dummy projects for the snippets to reference.
- `mkdocs` Contains the Dockerfile and Macros for the documentation.

### Building the Documentation
Run the following command to build the documentation:

```bash
docs.sh build
```

### 
Run the following command to build the documentation:

```bash
docs.sh serve
```

There are multiple steps to building the documentation:
1. Running `webdev`:
    - Creates `versions.json`  which will inject the latest version into MkDocs. e.g. `^{{ versions.drift }}`
    - Creates `.excerpt.json` snippet files in `lib` which MkDocs will use to inject syntax highlighted code into the documentation. e.g. `{{ load_snippet('flutter','lib/snippets/setup/database.dart.excerpt.json') }}`
    - Run the `drift_dev` builder to generate the code for the snippets.
    - Compile the dart code in `web` to javascript.
2. Running `mkdocs`:
    - Compile the markdown files in `docs` to html.
3. Combine the output of the two steps into the `deploy` folder.

