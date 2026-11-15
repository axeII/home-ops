# The NIC is matched by MAC and given a stable alias, so the address, route and
# VIP do not depend on kernel interface naming.
apiVersion: v1alpha1
kind: LinkAliasConfig
name: ethSel0
selector:
  match: glob("{{ .Node.Data.macAddr }}", mac(link.hardware_addr))
---
apiVersion: v1alpha1
kind: LinkConfig
name: ethSel0
mtu: 1500
addresses:
  - address: "{{ .Node.IP }}/24"
routes:
  - gateway: 192.168.69.1
{{- if eq .Node.Role "control-plane" }}
---
apiVersion: v1alpha1
kind: Layer2VIPConfig
name: 192.168.69.254
link: ethSel0
{{- end }}
