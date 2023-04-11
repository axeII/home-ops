
import re
import subprocess
import pathlib

files = subprocess.run("fd kustomization.yaml", shell=True, stdout=subprocess.PIPE)

for file_ in filter(None, files.stdout.decode().split('\n')):
  abs_path = pathlib.Path(file_).absolute().parents[0]
  files = subprocess.run(f"cat {file_} | grep y.ml | grep -v '#'|grep -v http", shell=True, stdout=subprocess.PIPE).stdout.decode().split('\n')
  for checkfile in filter(None, files):
    # check if files exts
    thefile = pathlib.Path(str(abs_path)+'/'+checkfile.strip()[1:].strip().replace('./',''))
    if not thefile.exists():
      print(str(thefile))
