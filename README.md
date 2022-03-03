# home-ops

<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My HomeOps repository using proxmox, kubernetes and docker 💪 :octocat:

_... managed with Flux, Renovate_ and GitHub Actions :robot:

<br/>
<br/>
<br/>

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=for-the-badge)](https://discord.com/invite/S9yWcJVEMQ)
[![k3s](https://img.shields.io/badge/k3s-v1.23.3-blue?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)
[![renovate](https://img.shields.io/badge/renovate-enabled?style=for-the-badge&logo=renovatebot&logoColor=white&color=brightgreen)](https://github.com/renovatebot/renovate)

</div>

---

## :wave: Overview

Welcome to my HomeOps setup. See the hardware sectio where I describe what soft of hardware I am running locally. Unlike others I don't run pure k8s baremetal.
This is because I don't have enough hardware to run robust k8s and also I still like to run some services in docker/docker-compose and solution where k3s and docker are on the same machine resolt in some netowrk issues due iptables and nftables.

For setting cluster and my services I use terraform and ansible to make the most things as IaC (Inracsturcure as Code). I can anytime destroy my cluster build it again.
While for my virutal machies before I migrate to IaC and kubernetes I currently back up everyting on NAS using NFS including whole VMs (which saves ssd storage alot).

Finally at the moment of February 2022 I am satisfied with the home-ops infrastructure. Now I would like to move to the next phase -- add more services to my cluster.

## :art:&nbsp; Cluster components

- [calico](https://www.tigera.io/project-calico/) - CNI (container network interface)
- [longhorn](https://longhorn.com) - storage class provider for data persistence
- [flux](https://toolkit.fluxcd.io/) - GitOps tool for deploying manifests from the `cluster` directory
- [metallb](https://metallb.universe.tf/) - bare metal load balancer
- [kube-vip](https://kube-vip.chipzoller.dev/) - layer 2 load balancer for the Kubernetes control plane
- [cert-manager](https://cert-manager.io/) - SSL certificates - with Cloudflare DNS challenge
- [traefik](https://traefik.io/): Provides ingress cluster services.
- [hajimari](https://github.com/toboshii/hajimari) - start page with ingress discovery
- [reflector](https://github.com/emberstack/kubernetes-reflector) - mirror configmaps or secrets to other Kubernetes namespaces
- [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) - upgrade k3s
- [SOPS](https://toolkit.fluxcd.io/guides/mozilla-sops/): Encrypts secrets which is safe to store - even to a public repository.
<!--- [external-dns](https://github.com/kubernetes-sigs/external-dns): Creates DNS entries in a separate [coredns](https://github.com/coredns/coredns)-->

Following tools I use to setup infrastructure:

- [Ubuntu](https://ubuntu.com/download/server) - a pretty universal operating system that supports running all kinds of home related workloads in Kubernetes
- [Ansible](https://www.ansible.com) - tool I use for configuration ubuntu nodes and also to install k3s
- [Terraform](https://www.terraform.io) - in order to help with the DNS settings and setup VM where I run k3s I use terraform

## :file_cabinet: Hardware

My homelab runs on the following hardware (all nodes are running on VM Ubuntu 20.04):

| Device                                  | OS Disk Size | Data Disk Size       | Ram  | Purpose                                          |
|-----------------------------------------|--------------|----------------------|------|--------------------------------------------------|
| Udoo Bolt V8 AMD Ryzen | 250GB NVMe    | N/A                  | 32GB  | Proxmox Master                                       |
| Intel NUC8i5BEH                         | 250GB NVMe   | 1TB HDD             | 32GB | Proxmox node                                       |
| QNAP DAS (storage)                | BTRFS raid 1 16TB       | 2x3TB HDD, 2x10TB HDD | N/A  |  NFS storage |
| Unifi UDM Pro                | SSD 14GB       | HDD 1TB | 4GB  | Router and security Gateway  |
| Unifi Switch 16 PoE                | N/A       | N/A | N/A | Switch with 802.3at PoE+ ports |
| rock64                         | 16GB MMC |    N/A     | 4GB | Services backup device  (in case proxmox cluster is down )              |

---

## :handshake:&nbsp; Thanks

I am proud to be memeber k8s at home community! A lot of help and inspiration for my kubernetes cluster came from this community. Love you guys :heart: . Checkout their clusters - [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes)
