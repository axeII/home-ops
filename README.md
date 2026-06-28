# Home Operations

<div align="center">

<img src="https://i.imgur.com/gdvBkNE.png" align="center" width="144px" height="144px"/>

### HomeOps repo managed by k8s :wheel_of_dharma:

_... automated via [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions)_ :robot:

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/home-operations)&nbsp;&nbsp;
[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=white&color=blue&label=%20)](https://talos.dev)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=blue&label=%20)](https://kubernetes.io)&nbsp;&nbsp;
[![Flux](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Fflux_version&style=for-the-badge&logo=flux&logoColor=white&color=blue&label=%20)](https://fluxcd.io)&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/axeII/home-ops/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/axeII/home-ops/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![Home-Internet](https://img.shields.io/endpoint?url=https%3A%2F%2Fhealthchecks.io%2Fb%2F2%2Fd7bbc17d-0348-4fbf-9db6-946c4b7d5bf0.shields&style=for-the-badge&logo=ubiquiti&logoColor=white&label=Home%20Internet)](https://github.com/axeII/home-ops/blob/main/README.md#file_cabinet-hardware)&nbsp;&nbsp;
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)&nbsp;&nbsp;
[![Alertmanager](https://img.shields.io/badge/Alertmanager-on-brightgreen?style=for-the-badge&logo=prometheus&logoColor=white)](https://grafana.com/cloud)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Fcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Fcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Fcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Fcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Fcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Fcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo)&nbsp;&nbsp;
<!--[![Power-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.juno.moe%2Fcluster_power_usage&style=flat-square&label=Power)](https://github.com/kashalls/kromgo)-->

</div>

---

## 📖 Overview

Here, I perform DevOps best practices at home. I adhere to Infrastructure as Code (IaC) and GitOps practices using tools like [Kubernetes](https://github.com/kubernetes/kubernetes), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions). My cluster runs on three control-plane Talos nodes virtualized on Proxmox with Rook-Ceph for distributed storage.

![Alt](https://repobeats.axiom.co/api/embed/ac9d545da659ac0aa72d1a74c05aa89fed08418b.svg "Repobeats analytics image")

## ⛵ Kubernetes

My Kubernetes cluster runs [Talos Linux](https://www.talos.dev) on three control-plane nodes. Two are deployed bare metal and one is deployed as Proxmox VM. Talos is a fantastic lightweight Kubernetes distribution that provides a minimal, hardened, and API-driven OS — I highly recommend it to anyone seeking a secure and reproducible Kubernetes setup.

There is a template over at [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) if you wanted to try and follow along with some of the practices I use here.

### Core Components

**Networking:**
- [cilium](https://github.com/cilium/cilium) — eBPF-based CNI providing networking, observability, and security (kube-proxy replacement)
- [cloudflared](https://github.com/cloudflare/cloudflared) — Cloudflare Tunnel for secure external ingress
- [external-dns](https://github.com/kubernetes-sigs/external-dns) — automatic DNS record synchronization to Cloudflare (public) and UniFi (private)
- [Gateway API](https://gateway-api.sigs.k8s.io/) — dual external/internal gateways with cert-manager TLS via Cilium

**Storage:**
- [rook-ceph](https://rook.io) — distributed block storage for persistent volumes
- [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs) — NFS volume provisioning for media shares
- [volsync](https://github.com/backube/volsync) — PVC backup and replication
- [kopia](https://kopia.io) — snapshot-based backup client

**Secrets & Security:**
- [external-secrets](https://github.com/external-secrets/external-secrets) — syncs secrets from 1Password Connect into Kubernetes
- [cert-manager](https://cert-manager.io/) — automated TLS certificate management with Let's Encrypt
- [sops](https://github.com/getsops/sops) — encrypted secrets committed to Git with Age

**GitOps & Automation:**
- [flux](https://toolkit.fluxcd.io/) — GitOps operator watching my `kubernetes/` directory
- [renovate](https://github.com/renovatebot/renovate) — automated dependency updates via PRs
- [reloader](https://github.com/stakater/Reloader) — restarts pods when ConfigMaps or Secrets change
- [keda](https://keda.sh/) — event-driven autoscaling

**Observability:**
- [victoria-metrics](https://victoriametrics.com/) — Prometheus-compatible metrics storage and querying
- [victoria-logs](https://victoriametrics.com/victorialogs/) — log storage and querying
- [grafana](https://grafana.com/) — dashboards and visualizations
- [gatus](https://gatus.io/) — service health monitoring and status page
- [kromgo](https://github.com/kashalls/kromgo) — custom badges for README
- [coroot](https://coroot.com/) — APM and root-cause analysis
- [chaski](https://github.com/axeII/chaski) — custom alert routing and webhook receiver

**Cluster Utilities:**
- [spegel](https://github.com/spegel-org/spegel) — peer-to-peer OCI image mirroring between nodes
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server) — resource metrics for HPA and `kubectl top`
- [intel-device-plugin-operator](https://github.com/intel/intel-device-plugins-for-kubernetes) — Intel GPU device plugin for hardware transcoding
- [dragonfly](https://www.dragonflydb.io/) — Redis-compatible in-memory datastore

### ☸ GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [kubernetes](./kubernetes) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

The way Flux works for me here is it will recursively search the [kubernetes/apps](./kubernetes/apps) folder until it finds the most top level `kustomization.yaml` per directory and then apply all the resources listed in it. That aforementioned `kustomization.yaml` will generally only have a namespace resource and one or many Flux kustomizations. Those Flux kustomizations will generally have a `HelmRelease` or other resources related to the application underneath it which will be applied.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

### Directories

This Git repository contains the following directories under [kubernetes](./kubernetes).

```sh
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 flux          # Main Flux configuration of repository
├─📁 apps          # Apps deployed into my cluster grouped by namespace
└─📁 components    # Reusable Kustomize components

📁 talos           # Talos Linux node configuration and patches
```

### :file_cabinet: Hardware

My homelab runs on the following hardware. All Kubernetes nodes are Talos Linux VMs running on Proxmox.

| Device                         | OS Disk   | Data Disk | RAM  | Details                                   |
| ------------------------------ | --------- | --------- | ---- | ----------------------------------------- |
| **Proxmox VE**                 | NVMe      | NVMe      | 64GB | Main hypervisor                           |
| k8s-0 (VM)                     | 250GB     | 250GB     | 32GB | Talos control-plane, Intel ARC GPU        |
| k8s-1 (VM)                     | eMMC 30GB | 250GB     | 32GB | Talos control-plane                       |
| k8s-2 (VM)                     | 1TB SSD   | 250GB     | 32GB | Talos control-plane, e1000e driver        |
| TrueNAS SCALE (VM)             | SSD 20GB  | 40TB ZFS  | 64GB | NFS/SMB storage — 4x10TB HDD RAIDZ2       |
| Unifi UDM Pro                  | SSD 14GB  | HDD 1TB   | 4GB  | Router and security gateway               |
| Unifi Switch 16 PoE            | N/A       | N/A       | N/A  | PoE+ switch                               |
| Offsite VM                     | 60GB      | 8TB       | 8GB  | Offsite backup target                     |

### 🏠 Applications

**Media:**
| App | Description |
| --- | ----------- |
| [Plex](https://plex.tv) | Media server and streaming |
| [Plex-Music](https://github.com/axeII/chromatix) | Music streaming via Plexamp |
| [Sonarr](https://sonarr.tv) | TV show collection manager |
| [Radarr](https://radarr.video) | Movie collection manager |
| [Prowlarr](https://prowlarr.com) | Torrent/usenet indexer manager |
| [Sabnzbd](https://sabnzbd.org) | Usenet downloader |
| [Unpackerr](https://unpackerr.zip) | Auto-extracts downloaded archives |
| [Recyclarr](https://recyclarr.dev) | Syncs TRaSH Guides profiles |
| [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) | Cloudflare anti-bot bypass |
| [Seerr](https://github.com/seerr-team/seerr) | Media request management |
| [Tautulli](https://tautulli.com) | Plex statistics and monitoring |
| [Komga](https://komga.org) | Comic/manga/ebook library |
| [Kapowarr](https://github.com/Casvt/Kapowarr) | Comic book collection manager |

**Home & Productivity:**
| App | Description |
| --- | ----------- |
| [Home Assistant](https://www.home-assistant.io) | Home automation platform |
| [Glance](https://github.com/glanceapp/glance) | Personal dashboard |
| [Karakeep](https://github.com/karakeep-app/karakeep) | Bookmark manager |
| [Paperless-ngx](https://docs.paperless-ngx.com) | Document management with OCR |
| [Docmost](https://docmost.com) | Collaborative wiki and notes |
| [AFFiNE](https://affine.pro) | Knowledge base workspace |
| [Atuin](https://atuin.sh) | Shell history sync server |

**Infrastructure & Networking:**
| App | Description |
| --- | ----------- |
| [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks) | Secure external ingress |
| [Echo Server](https://github.com/mendhak/http-https-echo) | Ingress/connectivity testing |
| [Proxmox](https://www.proxmox.com) | Reverse proxy to hypervisor |
| [TrueNAS](https://www.truenas.com) | Reverse proxy to storage |
| [Minecraft](https://minecraft.net) | Game server |

### 📰 Blog post

Feel free to checkout my blog [axell.dev](https://axell.dev) which is also [open source](https://github.com/axeII/my-blog)!
I also have made a blog post about HW, what were my choices... which ones were good and which ones were bad. [Click here](https://axell.dev/favorite/my-home-lab/).

## 🤝 Gratitude and Thanks

I am proud to be a member of the home operations (previously k8s-at-home) community! I received a lot of help and inspiration for my Kubernetes cluster from this community which helped a lot. Thanks! :heart:

If you are interested in running your own k8s cluster at home, I highly recommend you to check out the [k8s-at-home](https://k8s-at-home.com) website.

Be sure to check out [kubesearch.dev](https://kubesearch.dev) for ideas on how to deploy applications or get ideas on what you may deploy.

## 🔏 License

See [LICENCE](./LICENCE).
