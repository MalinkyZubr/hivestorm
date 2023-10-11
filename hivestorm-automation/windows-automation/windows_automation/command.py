import os
import subprocess


class Command:
    def __init__(self, script_name=None, config_fields=None, policy=None):
        self.policy = policy
        if not policy:
            return None
        cwd = os.path.dirname(os.path.abspath(__file__))
        self.script = os.path.join(cwd, f"{cwd}/{script_name}.ps1")

        self.args = {field:policy[field] for field in config_fields}

    def __call__(self, *args):
        if not self.policy:
            return "[-] Policy not found, cancelling"
        process = subprocess.Popen(["powershell",self.script, self.args], stdout=subprocess.PIPE) # this will not work. Must parse these args to work with the powershell scripts
        p_out, p_err = process.communicate()
        return p_out, p_err