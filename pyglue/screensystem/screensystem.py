import json
import os
import random
import string

import requests
import threading
from subprocess import Popen
from time import sleep


class RunningProcess:
    def __init__(self, executable: str, args: str, repeat_if_dead=True):
        self.exec_args = [executable] + args.split(" ")
        self.repeat_if_dead = repeat_if_dead
        self.terminated = False
        self.process = None

    def terminate(self):
        if self.process:
            self.process.terminate()
        self.terminated = True

    def _task_process(self):
        print("starting", self.exec_args)
        while not self.terminated:
            try:
                if not self.process:
                    self.process = Popen(self.exec_args)

                error_code = (self.process.poll())
                if error_code is not None:
                    if not self.terminated and self.repeat_if_dead:
                        print("starting again")
                        self.process = None
            except Exception as ex:
                print("We have an error", ex)
                pass
            sleep(1)

    def spawn_process_keep_alive(self):
        thread = threading.Thread(target=self._task_process, daemon=True)
        thread.start()


class ScreenScript:
    SCREEN_DETAILS = 'screen/'

    mapping_commands = {
    }

    settings = None
    # Global Variables
    interrupt = True
    last_response = None
    current_running_process = None

    vlc_player_process = None

    VLC_EXECUTABLE = 'cvlc'
    VLC_ARGS = '-vvv'

    def __init__(self, ip_add, settings_path):
        self.IP_ADDRESS = ip_add
        self.settings_file = settings_path
        self.settings = self.read_from_file()

    def build_address(self, command):
        if command == "screen":
            return f"{self.IP_ADDRESS}{self.SCREEN_DETAILS}{self.settings['passphrase']}/"
        elif command == "generate":
            return f"{self.IP_ADDRESS}generate/{''.join(random.sample(string.ascii_letters, 5))}/"

        return None

    def request_status(self):
        try:
            res = requests.get(self.build_address("screen"), timeout=5)
            if res.status_code == 200:
                return res
            else:
                print(res.content)
                return None
        except (KeyboardInterrupt, SystemExit) as ex:
            raise ex
        except Exception as ex:
            print("Exception", ex)
            return None

    def request_generate(self):
        try:
            res = requests.post(self.build_address("generate"), timeout=5)
            if res.status_code == 200:
                return res
            else:
                print(res.content)
                return None
        except (KeyboardInterrupt, SystemExit) as ex:
            raise ex
        except Exception as ex:
            print("Exception", ex)
            return None

    def execute_command(self):
        if self.current_running_process:
            self.current_running_process.terminate()

        cmd = self.last_response['command']['base_command']
        if cmd in self.mapping_commands:
            cmd = self.mapping_commands[cmd]

        self.current_running_process = RunningProcess(cmd, self.last_response['command']['args'])
        self.current_running_process.spawn_process_keep_alive()

    def play_background_music(self):

        if self.vlc_player_process:
            self.vlc_player_process.terminate()

        if self.last_response['background_audio_stream'] is not None:
            self.vlc_player_process = RunningProcess(self.VLC_EXECUTABLE,
                                                     self.VLC_ARGS + " " + str(
                                                         self.last_response['background_audio_stream']))
            self.vlc_player_process.spawn_process_keep_alive()

    def run(self):
        while self.interrupt:
            try:
                res = self.request_status()
                if res:
                    res_json = res.json()
                    if self.last_response != res_json:
                        print("new config!")
                        old = self.last_response
                        self.last_response = res_json
                        if self.settings['name'] != self.last_response['name']:
                            self.settings['name'] = self.last_response['name']
                            self.save_settings(self.settings)

                        if old is None or self.last_response['command'] != old['command']:
                            print("Command changed")
                            self.execute_command()

                        if old is None or self.last_response['background_audio_stream'] != old[
                            'background_audio_stream']:
                            self.play_background_music()

                sleep(5)
            except (KeyboardInterrupt, SystemExit) as ex:
                print("Exiting! Thanks for watching!")
                self.interrupt = False

    def save_settings(self, settings):
        with open(self.settings_file, "w", encoding="utf-8") as settings_file_stream:
            json.dump(settings, settings_file_stream)

    def read_from_file(self):
        if os.path.exists(self.settings_file):
            with open(self.settings_file, "r", encoding="utf-8") as settings_file_stream:
                return json.load(settings_file_stream)
        else:
            settings = self.request_generate().json()
            print(settings)
            if settings is None:
                exit(0)

            self.save_settings(settings)
            return settings

def main():
    ip_add = os.environ['SCREEN_IP'] if "SCREEN_IP" in os.environ else "https://info.zgrate.ovh/"
    settings_path = os.environ['SETTINGS_DIR'] if "SETTINGS_DIR" in os.environ else "/home/kiosk/screen_settings.json"
    ScreenScript(ip_add, settings_path).run()
