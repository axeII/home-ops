import socket
import subprocess
from getpass import getpass
from pathlib import Path

use_key = True
config_path = f"{Path.home()}/.ssh/config.d/home"

user = input("User: ")
host = input("Host: ")
name = input("Name: ")
# password = getpass()

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
if sock.connect_ex((host,22)) != 0:
  print("Couldn't connect")
  quit()

subprocess.Popen(f"ssh-keygen -R {host}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).communicate()

if use_key:
  subprocess.Popen(f"ssh-copy-id -o ConnectTimeout=5 {user}@{host}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

template = f"""

#### GENERATED VIA SCRIPT #####
Host {name}
  HostName {host}
  User {user}
  Port 22
"""

Path(config_path).touch()

with open(config_path) as readfile:
  if name in readfile.read():
    quit()

with open(config_path, "a") as myfile:
  myfile.write(template)
