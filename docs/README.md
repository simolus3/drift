### Documentation for the Drift package

Folder Structure:

- `bin` Contains the CLI for building and serving the documentation.
- `builders` Contains the builders for the documentation. (Version Extraction and Code Snippets Generation)
- `docs` Contains the markdown files for the documentation.
- `lib` Contains the snippets for the documentation.
- `test` Contains the tests for the documentation.
- `web` Contains some dart which code which is compiled to javascript and served with the documentation.
- `stubs` Contains dummy projects for the snippets to reference.
- `mkdocs` Contains the Dockerfile and Macros for the documentation.

### Building the Documentation
Run the following command to build the documentation:

```bash
dart run drift_docs build
```

There are multiple steps to building the documentation:
1. Build a dartdoc site and place it in the `build` folder.
2. Build the code snippet files and place them next to the original files.
3. Build a version.json file which contains the versions of the packages used in the documentation.
4. Build the documentation using MkDocs.

