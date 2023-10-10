import argparse
import os
import json
from command import Command


script_dir = os.path.dirname(os.path.abspath(__file__))
config_template_path = os.path.join(script_dir, "config_template.json")
location_path = os.path.join(script_dir, "location.json") # stores location of the user defined config file

with open(config_template_path, 'r') as f:
    CONFIG_TEMPLATE = json.load(f)


class Executor:
    def __init__(self):
        self.parser = argparse.ArgumentParser("Windows Policy Configurer ", 
                                        description="Automated script system to complete tasks for hivestorm",
                                        )

        self.parser.add_argument("-gC", "--generateConfig", help="generate a config file at designated path")
        self.parser.add_argument("-sC", "--setConfig", help="set the active config file to the path")
        self.parser.add_argument("-cU", "--configureUsers", help="run user checks", action="store_true")
        self.parser.add_argument("-cP", "--configurePasswords", help="run password policy configuration", action="store_true")
        self.parser.add_argument("-cS", "--configureSecurity", help="configure security settings on the machine", action="store_true")
        self.parser.add_argument("-U", "--update", help="run system and program updates", action="store_true")
        self.parser.add_argument("-cF", "--configureFiles", help="search file system for unauthorized files and programs", action="store_true")

        self.config = self.load_config()
        if not self.config:
            print(f"[!] No config file is currently loaded. Use -sC to specify policy config file!")

        self.commands = {
            "generateConfig":self.generate_config,
            "setConfig":self.set_config_location,
            "configureUsers":Command(script_name="users.ps1", config_fields=['authorized_users'], policy=self.config),
            "configureFiles":Command(script_name="files.ps1", config_fields=['authorized_users', 'unauthorized_programs', 'unauthorized_extensions'], policy=self.config),
            "configureSecurity":Command(script_name="security.ps1", config_fields=['authorized_users'], policy=self.config),
            "configurePasswords":Command(script_name="passwords.ps1", config_fields=['authorized_users'], policy=self.config),
            "update":Command(script_name="updates.ps1", config_fields=['need_update'], policy=self.config)
        }
        
    def set_config_location(self, config_location, *args):
        print(f"[+] Setting policy config location to {config_location}")
        is_path = os.path.isfile(config_location)
        if not is_path: raise FileNotFoundError("[-] The entered file does not exist")

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
    executor = Executor()
    executor.run()