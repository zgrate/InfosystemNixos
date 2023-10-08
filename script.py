import os

import requests
import threading
from subprocess import Popen
from time import sleep

mapping_commands = {
    #   'mpv': './mpv_exe/mpv.exe'
}

IP_ADDRESS = os.environ["SCREEN_IP"]
PASSPHRASE = os.environ["SCREEN_PASSPHRASE"]

SCREEN_DETAILS = 'screen/'

interrupt = True

last_response = None

current_running_process = None


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
            if not self.process:
                self.process = Popen(self.exec_args)

            error_code = (self.process.poll())
            if error_code is not None:
                if not self.terminated and self.repeat_if_dead:
                    print("starting again")
                    self.process = None

            sleep(1)

    def spawn_process_keep_alive(self):
        thread = threading.Thread(target=self._task_process, daemon=True)
        thread.start()


def request_status():
    try:
        res = requests.get(build_address("screen"), timeout=5)
        return res
    except:
        print("EX")
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


while interrupt:
    try:
        res = request_status()
        if res:
            res_json = res.json()
            if last_response != res_json:
                print("new command")
                last_response = res_json
                execute_command()

        sleep(5)
    except KeyError:
        interrupt = False

# MPV_EXE = './mpv_exe/mpv.exe'
#
# ARGS = '--profile=low-latency -fs --stream-lavf-o=rw_timeout=3000000 --no-terminal --no-input-cursor -osc=no --network-timeout=2 rtmp://stream.vrcdn.live/live/furxmas'
#
#
# process = RunningProcess(MPV_EXE, ARGS)
# process.spawn_process_keep_alive()
#
#
#
# sleep(100)
# process.terminate()
# sleep(10)
