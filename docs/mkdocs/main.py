### This function delares macros which can be used in the documentation files.
import json
from pathlib import Path
import random
import string
current_dir = Path(__file__).parent

version_file = Path(__file__).parent.parent / "lib" / "versions.json"
def define_env(env):
    # Read the versions.json file
    versions:dict[str,str] = json.loads(version_file.read_text())
    env.variables['versions'] = versions


    @env.macro
    def load_snippet(snippet_name:str, *args:list[str], indent:int=0):
        files = [current_dir.parent / i for i in args]
        data = {}
        for file in files:
            data.update(json.loads(file.read_text()))
        return code_template(data[snippet_name], indent)
            


def code_template(content:str,indent:int=0):
    random_id = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    # Split the content by new line
    content = content.splitlines()
    # Add indent to each line, besides the first line
    lines = content[1:]
    content = [content[0]] + [f"{' '*indent}{line}" for line in lines]
    # Join the content
    content = "\n".join(content)

    result =  f"""<pre id="{random_id}"><code>{content}</code></pre>"""

    return result