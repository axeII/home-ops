import subprocess

result = subprocess.run("kubectl get ingress -A | awk '{print $4}' | awk -F ',' '{print $1}' | grep -v flux-rec | awk -F '.' '{print $1}' | grep -v HOSTS", stdout=subprocess.PIPE, shell=True, stderr=subprocess.STDOUT)

template = """resource "pihole_dns_record" "{}_moe" {{
  domain = "{}.${{data.sops_file.pihole_secrets.data["domain"]}}"
  ip     = "192.168.69.105"
}}
"""

for line in filter(None, result.stdout.decode().split('\n')):
  print(template.format(line, line))
