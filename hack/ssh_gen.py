import os
import socket
import subprocess
from getpass import getpass
from pathlib import Path

template = """

#### GENERATED VIA SCRIPT #####
Host {}
  HostName {}
  User {}
  Port 22
"""


def ask_for_input():
    user = input("User: ")
    host = input("Host: ")
    name = input("Name: ")
    # password = getpass()
    return user, host, name


def check_if_port_open(host):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    if sock.connect_ex((host, 22)) != 0:
        print("Couldn't connect")
        quit()


def upload_pub_key(user, host):
    key = os.environ.get("SSH_PUB_KEY_PATH", "")
    if key:
        command = f"ssh-copy-id -f -i {key} -o ConnectTimeout=5 {user}@{host}"
    else:
        command = f"ssh-copy-id -o ConnectTimeout=5 {user}@{host}"

    subprocess.Popen(
        f"ssh-keygen -R {host}",
        shell=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ).communicate()
    subprocess.Popen(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ).communicate()


def apply_changes_to_config(config_path, user, host, name):
    Path(config_path).touch()

    with open(config_path) as readfile:
        if name in readfile.read():
            quit()

    with open(config_path, "a") as myfile:
        myfile.write(template.format(name, host, user))


def main():
    the_path = f"{Path.home()}/.ssh/config.d/home"
    u, h, n = ask_for_input()
    check_if_port_open(h)

    if import_key := input(" Yo you want to import key?[Y/n]: ").lower() == 'y':
      upload_pub_key(u, h)
    apply_changes_to_config(the_path, u, h, n)


if __name__ == "__main__":
    main()
