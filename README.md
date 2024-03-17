# Home Operations

<div align="center">

<img src="https://i.imgur.com/gdvBkNE.png" align="center" width="144px" height="144px"/>

### My HomeOps repository using kubernetes 💪 :octocat:

_... managed with Flux, Renovate_ and GitHub Actions :robot:

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/home-operations)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FaxeII%2Fhome-ops%2Fmain%2Fkubernetes%2Fapps%2Fsystem-upgrade%2Fk3s%2Fks.yaml&query=%24.spec.postBuild.substitute.KUBE_VERSION&style=for-the-badge&logo=kubernetes&logoColor=white&label=%20)](https://k3s.io/)&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/axeII/home-ops/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/axeII/home-ops/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![pre-commit](https://img.shields.io/badge/cluster--status-down-red?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)

![image](https://axell.dev/favorite/my-home-lab/featured.jpg "My homelab")

</div>


## 📖  Overview

Here, I perform DevOps best practices but at home. Check out the hardware section where I describe what sort of hardware I am using. Thanks to Ansible, it's very easy for me to manage my home infrastructure and the cluster.  I try to adhere to Infrastructure as Code (IaC) and GitOps practices using tools like [Terraform](https://github.com/hashicorp/terraform), [Kubernetes](https://github.com/kubernetes/kubernetes), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions).

## ⛵ Kubernetes

There is a template over at [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) if you wanted to try and follow along with some of the practices I use here.

### Installation

For my cluster, I decided to use the PostgreSQL database instead of high IO load using etcd. I store critical data for my cluster in the PostgreSQL database and maintain it in High Availability mode. I use k3s deployed on ubuntu machines. For that I use ansible to prepare the machines and then install k3s and deploy my cluster configuration.


### Core Components

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


### ☸ GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [kubernetes](./kubernetes) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

The way Flux works for me here is it will recursively search the [kubernetes/apps](./kubernetes/apps) folder until it finds the most top level `kustomization.yaml` per directory and then apply all the resources listed in it. That aforementioned `kustomization.yaml` will generally only have a namespace resource and one or many Flux kustomizations. Those Flux kustomizations will generally have a `HelmRelease` or other resources related to the application underneath it which will be applied.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

### Directories

This Git repository contains the following directories under [kubernetes](./kubernetes).

```sh
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 bootstrap     # Flux installation
├─📁 flux          # Main Flux configuration of repository
└─📁 apps          # Apps deployed into my cluster grouped by namespace (see below)
```


### :file_cabinet: Hardware

My homelab runs on the following hardware (all k8s nodes are running on ubuntu 20.04):

<!-- textlint-disable -->
| Device                 | OS Disk Size     | Data Disk Size | Ram  | Purpose                         |
|------------------------|------------------|----------------|------|---------------------------------|
| Udoo Bolt V8 AMD Ryzen | 250GB NVMe       | N/A            | 32GB | k3s node                        |
| Intel NUC              | 250GB NVMe       | 1TB HDD        | 32GB | k3s node                        |
| AMD GPU Server         | 250GB NVMe       | 1TB SSD        | 32GB | k3s node with Nvidia GPU        |
| TRUENAS                | ZFS raidz 1 40TB | 4x10TB HDD     | 32GB | Storage                         |
| Unifi UDM Pro          | SSD 14GB         | HDD 1TB        | 4GB  | Router and security Gateway     |
| Unifi Switch 16 PoE    | N/A              | N/A            | N/A  | Switch with 802.3at PoE+ ports  |
| Offsite Machine        | 60 GB            | 8TB            | 8GB  | for backups and offsite storage |
<!-- textlint-enable -->

### 📰 Blog post

Feel free to checkout my blog [axell.dev](https://axell.dev) which is also [open source](https://github.com/axeII/my-blog)!
I also have made a blog post about HW, what were my choices... which ones were good and which ones were bad. [Click here](https://axell.dev/favorite/my-home-lab/).


## 🤝 Gratitude and Thanks

I am proud to be a member of the home operations (previously k8s-at-home) community! I received a lot of help and inspiration for my Kubernetes cluster from this community which helped a lot. Thanks! :heart:


If you are interested in running your own k8s cluster at home, I highly recommend you to check out the [k8s-at-home](https://k8s-at-home.com) website.

Be sure to check out [kubesearch.dev](https://kubesearch.dev) for ideas on how to deploy applications or get ideas on what you may deploy.

## 🔏 License

See [LICENSE](./LICENSE).
