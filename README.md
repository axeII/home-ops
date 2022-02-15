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

Welcome to my HomeOps setup. It's mainly Kubernetes (k3s) cluster plus some services that I run in docker compose.

## :art:&nbsp; Cluster components

- [flannel](https://github.com/flannel-io/flannel) - default CNI provided by k3s
- [longhorn](https://longhorn.com) - storage class provider for data persistence
- [flux](https://toolkit.fluxcd.io/) - GitOps tool for deploying manifests from the `cluster` directory
- [metallb](https://metallb.universe.tf/) - bare metal load balancer
- [kube-vip](https://kube-vip.chipzoller.dev/) - layer 2 load balancer for the Kubernetes control plane
- [cert-manager](https://cert-manager.io/) - SSL certificates - with Cloudflare DNS challenge
- [traefik](https://traefik.io/): Provides ingress cluster services.
- [hajimari](https://github.com/toboshii/hajimari) - start page with ingress discovery
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
| Intel NUC8i5BEH                         | 250GB NVMe   | 1TB SSD.             | 32GB | Proxmox Node                                       |
| QNAP DAS (storage)                | BTRFS raid 1 16TB       | 2x3TB HDD, 2x10TB HDD | N/A  |  NFS storage |

Using terraform I craete vitual machines for k3s on both nodes. Ansible I use to configure them.


---

## :handshake:&nbsp; Thanks

I am proud to be memeber k8s at home community! A lot of help and inspiration for my kubernetes cluster came from this community. Love you guys. Checkout their clusters - [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes)
