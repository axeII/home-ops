# Home Operations

<div align="center">

<img src="https://i.imgur.com/gdvBkNE.png" align="center" width="144px" height="144px"/>

### My HomeOps repository using kubernetes 💪 :octocat:

_... managed with Flux, Renovate_ and GitHub Actions :robot:

<br/>
<br/>
<br/>

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=for-the-badge)](https://discord.com/invite/S9yWcJVEMQ)
[![k3s](https://img.shields.io/badge/k3s-v1.25.7-blue?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)
[![renovate](https://img.shields.io/badge/renovate-enabled?style=for-the-badge&logo=renovatebot&logoColor=white&color=brightgreen)](https://github.com/renovatebot/renovate)

</div>

---

![image](https://axell.dev/favorite/my-home-lab/featured.jpg "My homelab")

## :wave: Overview

Welcome to my HomeOps setup. Here, I perform DevOps best practices but at home. Check out the hardware section where I describe what sort of hardware I am using. Thanks to Terraform and Ansible, it's very easy for me to manage my home infrastructure and the cluster. Under the folder `provision`, I store all my Ansible and Terraform scripts for my infrastructure. Some of them are used for the k3s cluster, while some are only for Docker instances.

For my cluster, I decided to use the PostgreSQL database instead of high IO load using etcd. I store critical data for my cluster in the PostgreSQL database and maintain it in High Availability mode. That's just in case you would like to copy my cluster configuration, then keep this note in mind. Here is a great guide from Devin's [template](https://github.com/onedr0p/flux-cluster-template) which can help you spin up your own cluster at home 💪.

## :art:&nbsp; Cluster components

- [calico](https://www.tigera.io/project-calico/) - CNI (container network interface)
- [echo-server](https://github.com/Ealenn/Echo-Server) - REST Server Tests (Echo-Server) API (useful for debugging HTTP issues)
- [longhorn](https://longhorn.com) - storage class provider for data persistence (yeah I'm giving longhorn second chance)
- [k8s_gateway](https://github.com/ori-edge/k8s_gateway) - DNS resolver for all types of external Kubernetes resources
- [flux](https://toolkit.fluxcd.io/) - GitOps tool for deploying manifests from the `cluster` directory
- [metallb](https://metallb.universe.tf/) - bare metal load balancer
- [kube-vip](https://kube-vip.io) - layer 2 load balancer for the Kubernetes control plane
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

My homelab runs on the following hardware (all k8s nodes are running on ubuntu 20.04):

<!-- textlint-disable -->
| Device                 | OS Disk Size     | Data Disk Size | Ram  | Purpose                                      |
|------------------------|------------------|----------------|------|----------------------------------------------|
| Udoo Bolt V8 AMD Ryzen | 250GB NVMe       | N/A            | 32GB | k3s node                                     |
| Intel NUC              | 250GB NVMe       | 1TB HDD        | 32GB | k3s node                                     |
| AMD GPU Server         | 250GB NVMe       | 1TB SSD        | 32GB | k3s node with Nvidia GPU                     |
| TRUENAS                | ZFS raidz 1 40TB | 4x10TB HDD     | 32GB | Storage                                      |
| Unifi UDM Pro          | SSD 14GB         | HDD 1TB        | 4GB  | Router and security Gateway                  |
| Unifi Switch 16 PoE    | N/A              | N/A            | N/A  | Switch with 802.3at PoE+ ports               |
| Offsite Machine        | 60 GB            | 8TB            | 8GB  | for backups and offsite storage              |
<!-- textlint-enable -->

I've made a blog post about HW, what were my choices... which ones were good and which ones were bad. [Click here](https://axell.dev/favorite/my-home-lab/).
Feel free to checkout my blog [axell.dev](https://axell.dev) which is also [open source](https://github.com/axeII/my-blog)! 

---

## :handshake:&nbsp; Thanks

I am proud to be a member of the k8s-at-home community! I received a lot of help and inspiration for my Kubernetes cluster from this community which helped a lot. Thanks! :heart:
If you are interested in running your own k8s cluster at home, I highly recommend you to check out the [k8s-at-home](https://k8s-at-home.com) website.
