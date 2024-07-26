### This function delares macros which can be used in the documentation files.
import json
from pathlib import Path
import random
import string

current_dir = Path(__file__).parent


def define_env(env):
    # Read the versions.json file in `/lib`
    # This allows `{{ versions.drift }}` in the markdown files
    version_file = Path(__file__).parent.parent / "lib" / "versions.json"
    versions: dict[str, str] = json.loads(version_file.read_text())
    env.variables["versions"] = versions

    @env.macro
    def load_snippet(snippet_name: str, *args: list[str], indent: int = 0):
        """
        This macro allows to load a snippets from source files and display them in the documentation.

        The snippet_name referes to whatever the snippet is named in the source file (e.g. `setup` from  `// #docregion setup``)

        The args are a list of files to load the snippet from. (e.g 'lib/snippets/setup/database.dart.excerpt.json')

        The indent is the number of spaces to indent the snippet by. (default is 0)
        This is used when placing a snippet inside tabs.
        See the `docs` for examples where indentation is used.
        """
        files = [current_dir.parent / i for i in args]
        data = {}
        for file in files:
            data.update(json.loads(file.read_text()))
        return code_template(data[snippet_name], indent)


def code_template(content: str, indent: int = 0):
    """
    Create the html for this code block.
    """
    random_id = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
    # Split the content by new line
    content = content.splitlines()

    # Add indent to each line, besides the first line
    lines = content[1:]
    content = [content[0]] + [f"{' '*indent}{line}" for line in lines]

    # Replace blank lines with <br> tag
    content = [
        line if len(line.strip()) > 0 else f"{' '*indent}<br>" for line in content
    ]

    content = "\n".join(content)

    result = f"""<pre id="{random_id}"><code>{content}</code></pre>"""
    return result
