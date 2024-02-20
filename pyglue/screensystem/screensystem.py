#!/usr/bin/env python3
import os

import requests
import threading
from subprocess import Popen
from time import sleep

#IP_ADDRESS = os.environ["SCREEN_IP"]
#PASSPHRASE = os.environ["SCREEN_PASSPHRASE"]

#SCREEN_DETAILS = 'screen/'

#mapping_commands = {
#}

# Global Variables
#interrupt = True
#last_response = None
#current_running_process = None

#vlc_player_process = None

#VLC_EXECUTABLE = 'cvlc'
#VLC_ARGS = '-vvv'


def build_address(command):
    if command == "screen":
        return f"{IP_ADDRESS}{SCREEN_DETAILS}{PASSPHRASE}/"
    return None


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


def request_status():
    try:
        res = requests.get(build_address("screen"), timeout=5)
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


def execute_command():
    global current_running_process
    if current_running_process:
        current_running_process.terminate()

    cmd = last_response['command']['base_command']
    if cmd in mapping_commands:
        cmd = mapping_commands[cmd]

    current_running_process = RunningProcess(cmd, last_response['command']['args'])
    current_running_process.spawn_process_keep_alive()


def play_background_music():
    global vlc_player_process

    if vlc_player_process:
        vlc_player_process.terminate()

    if last_response['background_audio_stream'] is not None:
        vlc_player_process = RunningProcess(VLC_EXECUTABLE, VLC_ARGS + " " + str(last_response['background_audio_stream']))
        vlc_player_process.spawn_process_keep_alive()

def main():
    IP_ADDRESS = os.environ["SCREEN_IP"]
    PASSPHRASE = os.environ["SCREEN_PASSPHRASE"]

    SCREEN_DETAILS = 'screen/'

    mapping_commands = {
    }

    # Global Variables
    interrupt = True
    last_response = None
    current_running_process = None

    vlc_player_process = None

    VLC_EXECUTABLE = 'cvlc'
    VLC_ARGS = '-vvv'

    while interrupt:
        try:
            res = request_status()
            if res:
                res_json = res.json()
                if last_response != res_json:
                    print("new config!")
                    old = last_response
                    last_response = res_json
                    if old is None or last_response['command'] != old['command']:
                        print("Command changed")
                        execute_command()

                    if old is None or last_response['background_audio_stream'] != old['background_audio_stream']:
                        play_background_music()

            sleep(5)
        except (KeyboardInterrupt, SystemExit) as ex:
            print("Exiting! Thanks for watching!")
            interrupt = False
