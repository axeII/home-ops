# Home Operations

<div align="center">

<img src="https://i.imgur.com/gdvBkNE.png" align="center" width="144px" height="144px"/>

### My HomeOps repository using kubernetes 💪 :octocat:

_... automated via [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions)_ :robot:

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/home-operations)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2FaxeII%2Fhome-ops%2Fmain%2Fkubernetes%2Fapps%2Fsystem-upgrade%2Fk3s%2Fks.yaml&query=%24.spec.postBuild.substitute.KUBE_VERSION&style=for-the-badge&logo=kubernetes&logoColor=white&label=%20)](https://k3s.io/)&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/axeII/home-ops/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/axeII/home-ops/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![Home-Internet](https://img.shields.io/endpoint?url=https%3A%2F%2Fhealthchecks.io%2Fb%2F2%2Fd7bbc17d-0348-4fbf-9db6-946c4b7d5bf0.shields&style=for-the-badge&logo=ubiquiti&logoColor=white&label=Home%20Internet)](https://github.com/axeII/home-ops/blob/main/README.md#file_cabinet-hardware)&nbsp;&nbsp;
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)&nbsp;&nbsp;
[![Alertmanager](https://img.shields.io/endpoint?url=https%3A%2F%2Fhealthchecks.io%2Fb%2F2%2Fc2d2a0dc-d550-4196-90a4-cdc4a7b9b3da.shields&style=for-the-badge&logo=prometheus&logoColor=white&label=Alertmanager)](https://github.com/axeII/home-ops/blob/main/README.md)

</div>

<div align="center">

![image](https://axell.dev/favorite/my-home-lab/featured_hu15d310b3720445b3c7baf7181f7cbd8d_475147_600x0_resize_q75_box.jpeg "My homelab")

</div>


## 📖  Overview

Here, I perform DevOps best practices but at home. Check out the hardware section where I describe what sort of hardware I am using. Thanks to Ansible, it's very easy for me to manage my home infrastructure and the cluster.  I try to adhere to Infrastructure as Code (IaC) and GitOps practices using tools like [Terraform](https://github.com/hashicorp/terraform), [Kubernetes](https://github.com/kubernetes/kubernetes), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions).

## ⛵ Kubernetes

There is a template over at [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) if you wanted to try and follow along with some of the practices I use here.

### Installation

For my cluster, I decided to use the PostgreSQL database instead of high IO load using etcd. I store critical data for my cluster in the PostgreSQL database and maintain it in High Availability mode. I use k3s deployed on ubuntu machines. For that I use ansible to prepare the machines and then install k3s and deploy my cluster configuration.


### Core Components

- [cert-manager](https://cert-manager.io/) - SSL certificates - with Cloudflare DNS challenge
- [cillium](https://github.com/cilium/cilium) - CNI for k8s
- [cloudflared](https://github.com/cloudflare/cloudflared): Enables Cloudflare secure access to my ingresses.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically syncs ingress DNS records to a DNS provider.
- [external-secrets](https://github.com/external-secrets/external-secrets): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [flux](https://toolkit.fluxcd.io/) - GitOps tool for deploying manifests from the `cluster` directory
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx): Kubernetes ingress controller using NGINX as a reverse proxy and load balancer.
- [k8s_gateway](https://github.com/ori-edge/k8s_gateway) - DNS resolver for all types of external Kubernetes resources
- [kube-vip](https://kube-vip.io) - layer 2 load balancer for the Kubernetes control plane
- [longhorn](https://longhorn.com) - storage class provider for data persistence (yeah I'm giving longhorn second chance)
- [reflector](https://github.com/emberstack/kubernetes-reflector) - mirror configmaps or secrets to other Kubernetes namespaces
- [reloader](https://github.com/stakater/Reloader) - restart pods when Kubernetes `configmap` or `secret` changes
- [sops](https://github.com/getsops/sops): Managed secrets for Kubernetes which are commited to Git.
- [spegel](https://github.com/spegel-org/spegel): Stateless cluster local OCI registry mirror.
- [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) - upgrade k3s
- [tailscale](https://github.com/tailscale/tailscale): Private WireGuard based VPN.


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
