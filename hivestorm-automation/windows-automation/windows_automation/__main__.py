import argparse
import os
import sys
import ctypes
import json
import subprocess


script_dir = os.path.dirname(os.path.abspath(__file__))
config_template_path = os.path.join(script_dir, "config_template.json")
location_path = os.path.join(script_dir, "location.json") # stores location of the user defined config file

with open(config_template_path, 'r') as f:
    CONFIG_TEMPLATE = json.load(f)


def is_admin():
    try:
        return os.getuid() == 0
    except AttributeError:
        pass
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() == 1
    except AttributeError:
        raise Exception("[-] OS Not recognized")
    

class Command:
    def __init__(self, script_name=None, config_fields=None, policy=None):
        self.policy = policy
        if not policy:
            return None
        cwd = os.path.dirname(os.path.abspath(__file__))
        self.script = os.path.join(cwd, f"{cwd}/{script_name}.ps1")

        if config_fields and policy:
            self.args = {field:policy[field] for field in config_fields}

    def __call__(self, *args):
        if not self.policy:
            return "[-] Policy not found, cancelling"
        process = subprocess.Popen(["powershell",self.script, self.args], stdout=subprocess.PIPE) # this will not work. Must parse these args to work with the powershell scripts
        p_out, p_err = process.communicate()
        return p_out, p_err


class Executor:
    def __init__(self):
        self.parser = argparse.ArgumentParser("Windows Policy Configurer ", 
                                        description="Automated script system to complete tasks for hivestorm",
                                        )

        self.parser.add_argument("-gC", "--generateConfig", help="generate a config file at designated path", metavar="CONFIG_PATH")
        self.parser.add_argument("-sC", "--setConfig", help="set the active config file to the path", metavar="CONFIG_PATH")
        self.parser.add_argument("-cU", "--configureUsers", help="run user checks", action="store_true")
        self.parser.add_argument("-cS", "--configureSecurity", help="configure security settings on the machine", action="store_true")
        self.parser.add_argument("-U", "--update", help="run system and program updates", action="store_true")
        self.parser.add_argument("-cF", "--configureFiles", help="search file system for unauthorized files and programs", action="store_true")
        self.parser.add_argument("-eXC", "--exeCheck", help="Check all the EXE files on the system for suspicious behavior", action="store_true")

        self.config = self.load_config()
        if not self.config:
            print(f"[!] No config file is currently loaded. Use -sC to specify policy config file!")

        self.commands = {
            "generateConfig":self.generate_config,
            "setConfig":self.set_config_location,
            "configureUsers":Command(script_name="users.ps1", config_fields=['authorized_users'], policy=self.config),
            "configureFiles":Command(script_name="files.ps1", config_fields=['unauthorized_programs', 'unauthorized_extensions'], policy=self.config),
            "configureSecurity":Command(script_name="security.ps1", policy=self.config),
            "update":Command(script_name="updates.ps1", config_fields=['need_update'], policy=self.config),
            "exeCheck":Command(script_name="exeCheck.ps1", policy=self.config)
        }
        
    def set_config_location(self, config_location, *args):
        print(f"[+] Setting policy config location to {config_location}")
        is_path = os.path.isfile(config_location)
        if not is_path: return "[-] The entered file does not exist"

        with open(location_path, 'w') as f:
            json.dump({"location":os.path.abspath(config_location)}, f)

        return f"[+] Successfully set policy config location to {config_location}"
        
    def load_config(self) -> dict:
        with open(location_path, 'r') as f:
            config_location = json.load(f)['location']

        if not config_location:
            return None
        is_path = os.path.isfile(config_location)
        if not is_path:
            with open(location_path, 'w') as f:
                json.dump({"location":None}, f)
            return "[-] The config file was moved or no longer exists. Please set a new config file location"
        
        with open(config_location, 'r') as f:
            return json.load(f)

    def generate_config(self, user_config_location: str, *args) -> str:
        with open(f"{user_config_location}.json", 'w') as f:
            f.write(json.dumps(CONFIG_TEMPLATE))
        return f"[+] Config generated at {user_config_location}.json"
    
    def run(self):
        args = vars(self.parser.parse_args())
        for command, argument in args.items():
            if argument:
                print(self.commands[command](argument))


if __name__ == "__main__":
    print("[!] PLEASE ENSURE THAT YOU HAVE COMPLETED ALL OF THE FORENSICS QUESTIONS BEFORE RUNNING THIS!")
    if not is_admin():
        print("[-] Program must be run as admin to function properly")
        sys.exit()
    executor = Executor()
    executor.run()