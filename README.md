# home-ops

<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My HomeOps repository using proxmox, kubernetes and docker 💪 :octocat:

_... managed with Flux, Renovate_ and GitHub Actions :robot:

<br/>
<br/>
<br/>

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=for-the-badge)](https://discord.com/invite/S9yWcJVEMQ)
[![k3s](https://img.shields.io/badge/k3s-v1.23.5-blue?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)
[![renovate](https://img.shields.io/badge/renovate-enabled?style=for-the-badge&logo=renovatebot&logoColor=white&color=brightgreen)](https://github.com/renovatebot/renovate)

</div>

---

## :wave: Overview

Welcome to my HomeOps setup. Here I perform DevOps best practicies but at home. Checkout the hardware section where I describe what sort of hardware I am using. Thanks to terraform and ansible it's very easy for me to manage my home infrastructure and the cluster. under folder `provision` I store all my ansible and terraform scripts to manage promox virtual machines. Some of them are used for k3s cluster some only for docker instances.


### Timeline:
- [January 2022] Rebuild of infrastructure.
- [February 2022] Finally at the moment of  I am satisfied with the home-ops infrastructure.
- [April 2022] Cluster is working again yayy.
- [May 2022] Migrating to robust storage for cluster a monitoring.
- [Today] Now I would like to move to the next phase -- add more services to my cluster.

## :art:&nbsp; Cluster components

- [calico](https://www.tigera.io/project-calico/) - CNI (container network interface)
- [echo-server](https://github.com/Ealenn/Echo-Server) - REST Server Tests (Echo-Server) API (useful for debugging HTTP issues)
- [longhorn](https://longhorn.com) - storage class provider for data persistence (yeah giving longhorn second chance)
- [k8s_gateway](https://github.com/ori-edge/k8s_gateway) - DNS resolver for all types of external Kubernetes resources
- [flux](https://toolkit.fluxcd.io/) - GitOps tool for deploying manifests from the `cluster` directory
- [metallb](https://metallb.universe.tf/) - bare metal load balancer
- [kube-vip](https://kube-vip.chipzoller.dev/) - layer 2 load balancer for the Kubernetes control plane
- [cert-manager](https://cert-manager.io/) - SSL certificates - with Cloudflare DNS challenge
- [traefik](https://traefik.io/): Provides ingress cluster services.
- [botkube](https://github.com/infracloudio/botkube) Bot that helps me to monitor the cluster with notifications.
- [hajimari](https://github.com/toboshii/hajimari) - start page with ingress discovery
- [reflector](https://github.com/emberstack/kubernetes-reflector) - mirror configmaps or secrets to other Kubernetes namespaces
- [reloader](https://github.com/stakater/Reloader) - restart pods when Kubernetes `configmap` or `secret` changes
- [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) - upgrade k3s
- [SOPS](https://toolkit.fluxcd.io/guides/mozilla-sops/): Encrypts secrets which is safe to store - even to a public repository.
<!--- [external-dns](https://github.com/kubernetes-sigs/external-dns): Creates DNS entries in a separate [coredns](https://github.com/coredns/coredns)-->

Following tools I use to setup infrastructure:

- [Ubuntu](https://ubuntu.com/download/server) - a pretty universal operating system that supports running all kinds of home related workloads in Kubernetes
- [Ansible](https://www.ansible.com) - tool I use for configuration ubuntu nodes and also to install k3s
- [Terraform](https://www.terraform.io) - in order to help with the DNS settings and setup VM where I run k3s I use terraform

## :file_cabinet: Hardware

My homelab runs on the following hardware (all nodes are running on VM Ubuntu 20.04):

<!-- textlint-disable -->
| Device                                  | OS Disk Size | Data Disk Size       | Ram  | Purpose                                          |
|-----------------------------------------|--------------|----------------------|------|--------------------------------------------------|
| Udoo Bolt V8 AMD Ryzen | 250GB NVMe    | N/A                  | 32GB  | Proxmox Master                                       |
| Intel NUC8i5BEH                         | 250GB NVMe   | 1TB HDD             | 32GB | Proxmox Node                                       |
| QNAP DAS (storage)                | BTRFS raid 1 16TB       | 2x3TB HDD, 2x10TB HDD | N/A  |  NFS Storage |
| Unifi UDM Pro                | SSD 14GB       | HDD 1TB | 4GB  | Router and security Gateway  |
| Unifi Switch 16 PoE                | N/A       | N/A | N/A | Switch with 802.3at PoE+ ports |
| rock64                         | 16GB MMC |    N/A     | 4GB | Services backup device  (in case proxmox cluster is down )              |
<!-- textlint-enable -->

### Tips
Check for uniq mac addresses:
```
ansible all -i home-ops/provision/ansible/kubernetes/inventory/hosts.yml --one-line -m shell -a 'ip link show | grep link' | awk '{print $13}' | sort | uniq | wc -l
```

---

## :handshake:&nbsp; Thanks

I am proud to be memeber k8s-at-home community! A lot of help and inspiration for my k8s cluster came from this community. Without their help and inspiration I would not be where I am now. Thank you guys :heart:. Definately checkout their clusters - [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes) and join the [community](https://k8s-at-home.com).
