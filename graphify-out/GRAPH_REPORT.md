# Graph Report - .  (2026-08-10)

## Corpus Check
- 427 files · ~59,179 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 748 nodes · 934 edges · 95 communities (53 shown, 42 thin omitted)
- Extraction: 86% EXTRACTED · 13% INFERRED · 1% AMBIGUOUS · INFERRED: 120 edges (avg confidence: 0.79)
- Token cost: 0 input · 1,528,919 output

## Community Hubs (Navigation)
- Media Automation Stack (*arr)
- GitButler CLI Workflow
- Grafana Cloud Observability
- GitOps CI/CD Automation Policy
- KEDA Autoscaling & Metrics Badges
- Karakeep Bookmark Manager
- Default Namespace App Catalog
- Reloader & Spegel Infra Add-ons
- CoreDNS & External Secrets
- Cloudflare Tunnel Ingress
- Postgres Backup & Default Apps
- Flux Operator & Konflate
- PR Labeler Path Config
- Flux Validation Python Tooling
- Bootstrap Helmfile Core Releases
- External Proxy Apps (Grafana/Proxmox)
- PR CI Workflows & Agents
- Rook-Ceph Storage Cluster
- GitHub Issue Templates & Labels
- VolSync Maintenance & Kopia
- System Upgrade (Talos/K8s via tuppr)
- Flux Meta Repos Bootstrap
- Talos Machine Patches & VolSync Docs
- Talos Control Plane Nodes
- Bootstrap Apps Script
- Observability VM Docker Compose
- Flux Instance & GitHub Webhook
- Smartctl & Unpoller Exporters
- Container Scan & Scorecard CI
- Gatus Health Checks
- Kopia & Snapshot Controller
- Common Kustomize Components & SOPS
- Renovate Helm Chart Functions Script
- Post-Process Download Script
- Blackbox Exporter Probes
- GitOps Pipeline Stages Overview
- Cilium Gateway TLS Certificates
- CSI Driver NFS Storage
- Common Shell Script Helpers
- External Grafana Reverse Proxy
- Sabnzbd Download Client
- Etcd Metrics Scrape
- VolSync App Monitoring
- Docker Volume Backup Script
- Stuck Container Cleanup Script
- Deploy Script
- Linter Configs (Markdown/YAML/Mega)
- Plex App & Alerts
- Smartctl Grafana Dashboard
- KEDA NFS Scaler Component
- Database Manager Script
- Stuck Namespace Cleanup Script
- Renovate & PR Classify Workflows
- Sandbox Agent
- Talos & tuppr Upgrade Orchestrator
- Debug Pods (busybox/dns-test)
- Healthcheck Ping Script
- Support Requests Workflow
- Flux Validate Skill
- Cloudflare WAF Rules
- Observability Stack Concept
- Opencode Agents/Skills
- Prettier Configuration
- Flate Workflow
- Lychee Link Checker
- Pluto Deprecated API Detector
- Security Namespace
- Chaski Alert Routing
- Cilium eBPF CNI
- Cloudflared Tunnel Concept
- Coroot APM
- CSI Driver NFS Media Shares
- External-DNS Sync
- External-Secrets + 1Password
- Gateway API TLS
- Gatus Health Checks Concept
- Grafana Dashboards Concept
- Intel GPU Plugin
- KEDA Autoscaling Concept
- Kopia Backup Engine Concept
- Kromgo Badges Concept
- Metrics Server
- Reloader Concept
- Rook-Ceph Storage Concept
- SOPS Encrypted Secrets
- Spegel P2P Image Mirroring
- Talos Control Plane Concept
- VictoriaLogs
- VictoriaMetrics
- VolSync PVC Backup Concept
- Observability Docker Compose Stack

## God Nodes (most connected - your core abstractions)
1. `bash` - 30 edges
2. `Grafana CR: grafana (external instance)` - 27 edges
3. `Kustomization: grafana/instance` - 27 edges
4. `README Applications Catalog` - 25 edges
5. `GrafanaDatasource: grafanacloud-prometheus` - 25 edges
6. `HelmRelease: kube-state-metrics` - 14 edges
7. `Auto-Merge Workflow` - 12 edges
8. `rel()` - 10 edges
9. `Supply chain posture (limit blast radius from compromised upstream packages)` - 10 edges
10. `main()` - 9 edges

## Surprising Connections (you probably didn't know these)
- `yamllint config (.github/yamllint.config.yaml)` --semantically_similar_to--> `pre-commit config (.pre-commit-config.yaml)`  [AMBIGUOUS] [semantically similar]
  .github/yamllint.config.yaml → .pre-commit-config.yaml
- `Secrets encrypted at rest with age/sops + external-secrets/1Password Connect` --semantically_similar_to--> `SOPS + Age secret encryption`  [INFERRED] [semantically similar]
  SECURITY.md → AGENTS.md
- `README Auto-merge Policy Table` --semantically_similar_to--> `Auto-merge policy (.github/workflows/auto-merge.yaml)`  [INFERRED] [semantically similar]
  README.md → AGENTS.md
- `Auto-merge deny list (Plex, Rook-Ceph, Cilium, Talos, Flux)` --semantically_similar_to--> `Auto-merge policy (.github/workflows/auto-merge.yaml)`  [INFERRED] [semantically similar]
  SECURITY.md → AGENTS.md
- `3-day release-age cooldown on auto-merged patches` --semantically_similar_to--> `Auto-merge policy (.github/workflows/auto-merge.yaml)`  [INFERRED] [semantically similar]
  SECURITY.md → AGENTS.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Konflate-Gated PR Merge Automation** — github_workflows_auto_merge_workflow, github_workflows_konflate_refresh_workflow, github_workflows_debug_konflate_workflow [INFERRED 0.85]
- **Repository Label Governance System** — github_labeler_config, github_labels_config, github_workflows_label_sync_workflow, github_workflows_labeler_workflow [INFERRED 0.85]
- **Kubernetes Manifest CI Validation Pipeline** — github_workflows_flate_workflow, github_workflows_pluto_workflow, github_workflows_megalinter_workflow [INFERRED 0.75]
- **Files implementing the Flux/Kustomize validation pipeline** — _opencode_skills_flux_validate_skill, _opencode_command_validate, _opencode_agent_gitops, _pre_commit_config, concept_flux_validation_pipeline [INFERRED 0.85]
- **GitButler skill and its reference documents** — _opencode_skills_gitbutler_skill, _opencode_skills_gitbutler_references_concepts, _opencode_skills_gitbutler_references_examples, _opencode_skills_gitbutler_references_reference [EXTRACTED 1.00]
- **Agents delegating VCS to gitbutler under medior/senior review model** — _opencode_agent_gitops, _opencode_agent_talos, _opencode_skills_gitbutler_skill, concept_medior_senior_workflow [EXTRACTED 1.00]
- **Cert-manager Flux Kustomization Layering** — kubernetes_apps_cert_manager_kustomization_kustomization, kubernetes_apps_cert_manager_cert_manager_ks_kustomization, kubernetes_apps_cert_manager_cert_manager_app_kustomization_kustomization [INFERRED 0.85]
- **Dragonfly Operator-then-Instance Deployment Pattern** — kubernetes_apps_database_dragonfly_app_helmrelease_helmrelease, kubernetes_apps_database_dragonfly_cluster_cluster_dragonfly, kubernetes_apps_database_dragonfly_ks_dragonfly, kubernetes_apps_database_dragonfly_ks_dragonfly_cluster [INFERRED 0.85]
- **Core Operator Bootstrap Sequence** — bootstrap_helmfile_cilium, bootstrap_helmfile_coredns, bootstrap_helmfile_spegel, bootstrap_helmfile_cert_manager, bootstrap_helmfile_flux_operator, bootstrap_helmfile_flux_instance [EXTRACTED 1.00]
- **Shared CloudNativePG postgres-init pattern across apps (db.internal, cloudnative-pg secret)** — kubernetes_apps_default_affine_app_externalsecret_affine, kubernetes_apps_default_atuin_app_externalsecret_atuin, kubernetes_apps_default_docmost_app_externalsecret_docmost [INFERRED 0.85]
- **Apps expose glance/name, glance/show route annotations consumed by the glance dashboard extension widget** — kubernetes_apps_default_glance_app_config_glance_config, kubernetes_apps_default_atuin_app_helmrelease_atuin, kubernetes_apps_default_docmost_app_helmrelease_docmost, kubernetes_apps_default_home_assistant_app_helmrelease_home_assistant [INFERRED 0.85]
- **Scheduled postgres-backup cronjob covers atuin and docmost databases among others** — kubernetes_apps_database_pgbackup_app_helmrelease_postgres_backup, kubernetes_apps_default_atuin_app_externalsecret_atuin, kubernetes_apps_default_docmost_app_externalsecret_docmost [INFERRED 0.75]
- **Karakeep Bookmark Manager Stack** — kubernetes_apps_default_karakeep_app_helmrelease_karakeep_controller, kubernetes_apps_default_karakeep_app_helmrelease_chrome_controller, kubernetes_apps_default_karakeep_app_helmrelease_meilisearch_controller [EXTRACTED 1.00]
- **Paperless Document Processing Pipeline** — kubernetes_apps_default_paperless_app_helmrelease_app_container, kubernetes_apps_default_paperless_app_helmrelease_gotenberg_container, kubernetes_apps_default_paperless_app_helmrelease_tika_container [EXTRACTED 1.00]
- **Minecraft Scale-to-Zero Serving Stack** — kubernetes_apps_default_minecraft_app_helmrelease_minecraft, kubernetes_apps_default_minecraft_app_mc_router_helmrelease_mc_router, kubernetes_apps_default_minecraft_app_scaledobject_minecraft_scheduled [INFERRED 0.85]
- **Proxmox External Exposure Pipeline (HTTPRoute -> Service -> nginx sidecar)** — kubernetes_apps_external_proxmox_app_route_proxmox, kubernetes_apps_external_proxmox_app_service_proxmox, kubernetes_apps_external_proxmox_app_nginx_proxy_proxmox_nginx [INFERRED 0.85]
- **TrueNAS External Exposure Pipeline (HTTPRoute -> Service -> nginx sidecar)** — kubernetes_apps_external_truenas_app_route_truenas, kubernetes_apps_external_truenas_app_service_truenas, kubernetes_apps_external_truenas_app_nginx_proxy_truenas_nginx [INFERRED 0.85]
- **GitHub Webhook Notification Flow (HTTPRoute -> Receiver -> ExternalSecret token)** — kubernetes_apps_flux_system_flux_instance_app_httproute_github_webhook, kubernetes_apps_flux_system_flux_instance_app_receiver_github_webhook, kubernetes_apps_flux_system_flux_instance_app_externalsecret_github_webhook_token [INFERRED 0.85]
- **Reused ConfigMap nameReference Kustomize-Config Pattern** — kubernetes_apps_flux_system_flux_operator_app_helm_kustomizeconfig_namereference, kubernetes_apps_kube_system_cilium_app_helm_kustomizeconfig_namereference, kubernetes_apps_kube_system_coredns_app_helm_kustomizeconfig_namereference [INFERRED 0.85]
- **Shared TLS Certificate Flow for juno.moe Gateways** — kubernetes_apps_kube_system_cilium_gateway_certificate_certificate_juno_moe_production, kubernetes_apps_kube_system_cilium_gateway_external_gateway_external, kubernetes_apps_kube_system_cilium_gateway_internal_gateway_internal [EXTRACTED 1.00]
- **Konflate Secret-Chart-Release Deployment Flow** — kubernetes_apps_flux_system_konflate_app_externalsecret_externalsecret_konflate, kubernetes_apps_flux_system_konflate_app_ocirepository_ocirepository_konflate, kubernetes_apps_flux_system_konflate_app_helmrelease_helmrelease_konflate [EXTRACTED 1.00]
- **SOPS-encrypted secretRef decryption pattern across Flux Kustomizations** — kubernetes_apps_kube_system_coredns_ks_kustomization, kubernetes_apps_kube_system_external_secrets_ks_kustomization, kubernetes_apps_kube_system_metrics_server_ks_kustomization [INFERRED 0.75]
- **Intel GPU device plugin operator dependency and health-check chain** — kubernetes_apps_kube_system_intel_device_plugin_operator_ks_kustomization_operator, kubernetes_apps_kube_system_intel_device_plugin_operator_ks_kustomization_gpu, kubernetes_apps_kube_system_intel_device_plugin_operator_gpu_helmrelease_helmrelease [EXTRACTED 1.00]
- **External Secrets to 1Password ClusterSecretStore integration chain** — kubernetes_apps_kube_system_external_secrets_ks_kustomization, kubernetes_apps_kube_system_external_secrets_ks_kustomization_stores, kubernetes_apps_kube_system_external_secrets_stores_onepassword_clustersecretstore_clustersecretstore [EXTRACTED 1.00]
- **Media apps sharing the bjw-s-labs app-template Helm chart** — kubernetes_apps_media_flaresolverr_app_helmrelease_helmrelease, kubernetes_apps_media_kapowarr_app_helmrelease_helmrelease, kubernetes_apps_media_komga_app_helmrelease_helmrelease, kubernetes_apps_media_plex_music_app_helmrelease_helmrelease, kubernetes_apps_media_plex_app_helmrelease_helmrelease, app_template_chart [EXTRACTED 1.00]
- **Apps mounting the shared NFS media library from nas.internal** — kubernetes_apps_media_komga_app_helmrelease_helmrelease, kubernetes_apps_media_kapowarr_app_helmrelease_helmrelease, kubernetes_apps_media_plex_app_helmrelease_helmrelease [EXTRACTED 1.00]
- **Apps exposing routes annotated for the Glance homelab dashboard** — kubernetes_apps_media_komga_app_helmrelease_helmrelease, kubernetes_apps_media_kapowarr_app_helmrelease_helmrelease, kubernetes_apps_media_plex_music_app_helmrelease_helmrelease, kubernetes_apps_media_plex_app_helmrelease_helmrelease [EXTRACTED 1.00]
- **Shared KEDA NFS-Scaler Component Usage** — kubernetes_apps_media_plex_ks_plex, kubernetes_apps_media_radarr_ks_radarr, kubernetes_apps_media_sabnzbd_ks_sabnzbd [EXTRACTED 1.00]
- **Shared CloudNativePG Init-Container Pattern (Prowlarr & Radarr)** — kubernetes_apps_media_prowlarr_app_externalsecret_prowlarr, kubernetes_apps_media_prowlarr_app_helmrelease_prowlarr, kubernetes_apps_media_radarr_app_externalsecret_radarr, kubernetes_apps_media_radarr_app_helmrelease_radarr [INFERRED 0.85]
- **Recyclarr TRaSH-Guides Sync Data Flow** — kubernetes_apps_media_recyclarr_app_config_recyclarr_config, kubernetes_apps_media_recyclarr_app_externalsecret_recyclarr, kubernetes_apps_media_recyclarr_app_helmrelease_recyclarr, kubernetes_apps_media_radarr_app_helmrelease_radarr [INFERRED 0.85]
- **cloudnative-pg 1Password item shared by seerr and sonarr** — kubernetes_apps_media_seerr_app_externalsecret_seerr, kubernetes_apps_media_sonarr_app_externalsecret_sonarr, onepassword_item_cloudnative_pg [EXTRACTED 1.00]
- **Unpackerr integrates with sonarr and radarr via shared API keys and service URLs** — kubernetes_apps_media_unpackerr_app_externalsecret_unpackerr, kubernetes_apps_media_unpackerr_app_helmrelease_unpackerr, kubernetes_apps_media_sonarr_app_helmrelease_sonarr, media_radarr_app_helmrelease_radarr [INFERRED 0.85]
- **Cloudflare tunnel runtime configuration trio: config, credentials, workload** — kubernetes_apps_network_cloudflare_tunnel_app_configs_config_cloudflared_ingress, kubernetes_apps_network_cloudflare_tunnel_app_externalsecret_cloudflared, kubernetes_apps_network_cloudflare_tunnel_app_helmrelease_cloudflare_tunnel [EXTRACTED 1.00]
- **Network Namespace App Deployment Cascade** — kubernetes_apps_network_kustomization, kubernetes_apps_network_cloudflare_tunnel_ks_kustomization, kubernetes_apps_network_echo_server_ks_kustomization, kubernetes_apps_network_external_dns_ks_kustomization_cloudflare, kubernetes_apps_network_external_dns_ks_kustomization_unifi [EXTRACTED 1.00]
- **External-DNS Cloudflare Secrets Pipeline** — kubernetes_apps_network_external_dns_cloudflare_externalsecret_external_dns_cloudflare, kubernetes_apps_network_external_dns_cloudflare_helmrelease_external_dns_cloudflare, kubernetes_apps_network_external_dns_ks_kustomization_cloudflare [INFERRED 0.85]
- **Blackbox Exporter Probe Stack** — kubernetes_apps_observability_blackbox_exporter_app_helmrelease_blackbox_exporter, kubernetes_apps_observability_blackbox_exporter_app_repository_blackbox_exporter, kubernetes_apps_observability_blackbox_exporter_app_probes_devices, kubernetes_apps_observability_blackbox_exporter_app_probes_nfs [EXTRACTED 1.00]
- **Gatus App Deployment Stack** — kubernetes_apps_observability_gatus_app_kustomization_gatus, kubernetes_apps_observability_gatus_app_helmrelease_gatus, kubernetes_apps_observability_gatus_app_externalsecret_gatus, kubernetes_apps_observability_gatus_app_resources_config_gatusconfig [INFERRED 0.85]
- **Grafana Cloud Alloy Metrics and Logs Pipeline** — kubernetes_apps_observability_grafana_cloud_app_helmrelease_grafanacloud, kubernetes_apps_observability_grafana_cloud_app_externalsecret_grafanacloud, kubernetes_apps_observability_grafana_instance_grafanadatasource_grafanacloudprometheus, kubernetes_apps_observability_grafana_instance_grafanadatasource_loki_loki [INFERRED 0.85]
- **Grafana Instance Observability Stack** — kubernetes_apps_observability_grafana_instance_grafana_grafana, kubernetes_apps_observability_grafana_instance_grafanadatasource_grafanacloudprometheus, kubernetes_apps_observability_grafana_instance_servicemonitor_grafana, kubernetes_apps_observability_grafana_instance_kustomization_instance [INFERRED 0.85]
- **Kromgo badges consume kube-state-metrics + node-exporter Prometheus metrics** — kubernetes_apps_observability_kromgo_app_resources_config_badges_config, kubernetes_apps_observability_kube_state_metrics_app_helmrelease_helmrelease_ksm, kubernetes_apps_observability_node_exporter_app_helmrelease_helmrelease_node_exporter [INFERRED 0.85]
- **Standard Flux GitOps app deployment pattern (ks -> HelmRelease -> OCIRepository)** — kubernetes_apps_observability_node_exporter_ks_kustomization_node_exporter, kubernetes_apps_observability_node_exporter_app_helmrelease_helmrelease_node_exporter, kubernetes_apps_observability_node_exporter_app_repository_ocirepository_node_exporter [INFERRED 0.75]
- **kube-state-metrics exposes Flux GitOps resource state as Prometheus metrics** — kubernetes_apps_observability_kube_state_metrics_app_helmrelease_helmrelease_ksm, kubernetes_apps_observability_kube_state_metrics_app_helmrelease_flux_kustomization_crd, kubernetes_apps_observability_kube_state_metrics_app_helmrelease_flux_helmrelease_crd [INFERRED 0.75]
- **Ceph Dashboard Proxy Request Pipeline** — kubernetes_apps_rook_ceph_rook_ceph_cluster_dashboard_proxy_httproute, kubernetes_apps_rook_ceph_rook_ceph_cluster_dashboard_proxy_service, kubernetes_apps_rook_ceph_rook_ceph_cluster_dashboard_proxy_deployment, kubernetes_apps_rook_ceph_rook_ceph_cluster_dashboard_proxy_configmap [INFERRED 0.85]
- **Rook Ceph Flux Reconciliation Chain** — kubernetes_apps_rook_ceph_rook_ceph_ks_kustomization_rook_ceph, kubernetes_apps_rook_ceph_rook_ceph_ks_kustomization_rook_ceph_cluster, kubernetes_apps_rook_ceph_rook_ceph_cluster_helmrelease_helmrelease [INFERRED 0.85]
- **OCIRepository HelmRelease Exporter Pattern** — kubernetes_apps_observability_smartctl_exporter_app_helmrelease_helmrelease, kubernetes_apps_observability_unpoller_app_helmrelease_helmrelease, kubernetes_apps_rook_ceph_rook_ceph_app_helmrelease_helmrelease [INFERRED 0.75]
- **Ceph noout toggling coordinated with Talos node upgrade** — kubernetes_apps_system_upgrade_app_talos_upgrade_cluster, kubernetes_apps_system_upgrade_app_ceph_secrets_sops_secret_rook_ceph_mon, kubernetes_apps_system_upgrade_app_ceph_secrets_sops_secret_rook_ceph_config [INFERRED 0.85]
- **Flux GitOps pipeline deploying tuppr controller** — kubernetes_apps_system_upgrade_ks_tuppr, kubernetes_apps_system_upgrade_app_kustomization_app, kubernetes_apps_system_upgrade_app_helmrelease_tuppr [INFERRED 0.75]
- **VolSync monitoring stack (dashboard + alert rules over metrics)** — kubernetes_apps_volsync_system_volsync_app_helmrelease_volsync, kubernetes_apps_volsync_system_volsync_app_dashboard_volsync, kubernetes_apps_volsync_system_volsync_app_prometheusrule_volsync [INFERRED 0.85]
- **Volsync PVC backup/restore pipeline via Kopia** — kubernetes_components_volsync_pvc_pvc, kubernetes_components_volsync_replicationdestination_replicationdestination, kubernetes_components_volsync_replicationsource_replicationsource, kubernetes_components_volsync_externalsecret_externalsecret [INFERRED 0.85]
- **Kopia repository maintenance job flow with NFS volume injection** — kubernetes_apps_volsync_system_volsync_maintenance_externalsecret_externalsecret, kubernetes_apps_volsync_system_volsync_maintenance_kopiamaintenance_kopiamaintenance, kubernetes_apps_volsync_system_volsync_maintenance_mutatingadmissionpolicy_policy [INFERRED 0.85]
- **Common Flux Kustomize component bundle (namespace, repos, sops)** — kubernetes_components_common_kustomization_component, kubernetes_components_common_repos_kustomization_kustomization, kubernetes_components_common_sops_kustomization_kustomization, kubernetes_components_common_namespace_namespace [EXTRACTED 1.00]
- **Flux Meta Bootstrap Chain** — kubernetes_flux_cluster_ks_clustermeta, kubernetes_flux_meta_kustomization_kustomization, kubernetes_flux_meta_repos_kustomization_kustomization [EXTRACTED 1.00]
- **Talos Global Machine Configuration Patches** — talos_patches_global_machine_features_patch, talos_patches_global_machine_files_patch, talos_patches_global_machine_kubelet_patch, talos_patches_global_machine_network_patch [INFERRED 0.85]
- **Manual Kubernetes Debug and Recovery Toolkit** — scripts_busybox_busyboxdebug, scripts_dns_test_dnstestpod, scripts_volsync_restore_guide [INFERRED 0.75]
- **Self-hosted Observability Stack (Prometheus + Loki + Grafana + Caddy)** — vm_observability_docker_compose_prometheus, vm_observability_docker_compose_loki, vm_observability_docker_compose_grafana, vm_observability_docker_compose_caddy [EXTRACTED 1.00]
- **Talos 3-Node Control Plane with Shared VIP** — talos_talconfig_k8s_0, talos_talconfig_k8s_1, talos_talconfig_k8s_2 [EXTRACTED 1.00]
- **Grafana Datasource Wiring to Prometheus and Loki** — vm_observability_grafana_provisioning_datasources_datasources, vm_observability_docker_compose_prometheus, vm_observability_docker_compose_loki [EXTRACTED 1.00]

## Communities (95 total, 42 thin omitted)

### Community 0 - "Media Automation Stack (*arr)"
Cohesion: 0.08
Nodes (43): Flux Kustomization: external-secrets-stores (dependency), Kustomize component: keda/nfs-scaler, Prowlarr ExternalSecret, Prowlarr HelmRelease, Prowlarr App Kustomization, Prowlarr Flux Kustomization, Radarr ExternalSecret, Radarr HelmRelease (+35 more)

### Community 1 - "GitButler CLI Workflow"
Cohesion: 0.05
Nodes (41): but amend*, but branch*, but commit*, but diff*, but move*, but pull*, but push*, but show* (+33 more)

### Community 2 - "Grafana Cloud Observability"
Cohesion: 0.13
Nodes (38): ServiceMonitor: etcd, ExternalSecret: grafana-admin-password, HelmRelease: grafana-operator, Kustomization: grafana/app, OCIRepository: grafana-operator, ExternalSecret: grafana-cloud, HelmRelease: grafana-cloud (Grafana Alloy), Kustomization: grafana-cloud/app (+30 more)

### Community 3 - "GitOps CI/CD Automation Policy"
Cohesion: 0.06
Nodes (37): Auto-merge policy (.github/workflows/auto-merge.yaml), GitButler CLI (`but`), flate offline Flux renderer, Flux CD GitOps operator, konflate PR review service, AI as Medior Developer / Human as Senior Reviewer Model, PR Creation Workflow, pre-commit hook checks (+29 more)

### Community 4 - "KEDA Autoscaling & Metrics Badges"
Cohesion: 0.07
Nodes (36): HelmRelease: keda, Kustomization: keda app resources, OCIRepository: keda chart, Flux Kustomization: keda, Gateway: external (kube-system), HelmRelease: kromgo, OCIRepository: app-template (flux-system, shared chart), Secret: grafana-cloud-credentials (+28 more)

### Community 5 - "Karakeep Bookmark Manager"
Cohesion: 0.11
Nodes (26): PersistentVolumeClaim home-assistant-cache, Flux Kustomization home-assistant, ExternalSecret karakeep, Chrome Headless Browser Controller, HelmRelease karakeep, Karakeep App Controller, Meilisearch Controller, Kustomization karakeep/app (+18 more)

### Community 6 - "Default Namespace App Catalog"
Cohesion: 0.08
Nodes (26): AFFiNE knowledge base, README Applications Catalog, Atuin shell history sync, Cloudflare Tunnel ingress, Docmost wiki, Echo Server (connectivity testing), FlareSolverr, Glance dashboard (+18 more)

### Community 7 - "Reloader & Spegel Infra Add-ons"
Cohesion: 0.11
Nodes (25): bjw-s-labs app-template Helm chart (shared OCIRepository), HelmRelease: reloader, OCIRepository: reloader, Kustomization (reloader app resources), Flux Kustomization: reloader, Kustomize NameReference config (spegel), Helm values: spegel, HelmRelease: spegel (+17 more)

### Community 8 - "CoreDNS & External Secrets"
Cohesion: 0.09
Nodes (25): CoreDNS Helm Values (kube-dns config), HelmRelease coredns, OCIRepository coredns, Kustomization (coredns app), Flux Kustomization coredns, HelmRelease external-secrets, Kustomization (external-secrets app), Flux Kustomization external-secrets (+17 more)

### Community 9 - "Cloudflare Tunnel Ingress"
Cohesion: 0.10
Nodes (22): Service: cilium-gateway-external (kube-system), cloudflared config.yaml: ingress rules, DNSEndpoint: cloudflared, ExternalSecret: cloudflared, HelmRelease: cloudflare-tunnel, Rationale: tolerant liveness probe instead of shell retry wrapper (distroless image), Cloudflare Tunnel App Kustomization, cloudflare-tunnel-configmap ConfigMapGenerator (+14 more)

### Community 10 - "Postgres Backup & Default Apps"
Cohesion: 0.13
Nodes (22): HelmRelease: postgres-backup (pgbackup cronjob), Kustomization resources: pgbackup app, Flux Kustomization: pgbackup, ExternalSecret: affine, HelmRelease: affine, Kustomization resources: affine app, Flux Kustomization: affine, ExternalSecret: atuin (+14 more)

### Community 11 - "Flux Operator & Konflate"
Cohesion: 0.14
Nodes (21): flux-operator kustomizeconfig nameReference, flux-operator Helm values (serviceMonitor), HelmRelease flux-operator, OCIRepository flux-operator, flux-operator app Kustomization, Flux Kustomization flux-operator, ExternalSecret konflate, HelmRelease konflate (+13 more)

### Community 12 - "PR Labeler Path Config"
Cohesion: 0.13
Nodes (20): PR Path-Based Auto-Labeler Config, Label: area/bootstrap, Label: area/github, Label: area/kubernetes, Label: area/minecraft, Label: area/talos, Label: area/taskfile (used by labeler, undefined in labels.yaml), Label: do not merge (+12 more)

### Community 13 - "Flux Validation Python Tooling"
Cohesion: 0.24
Nodes (18): Path, check_common_component(), check_depends_on(), check_duplicate_resources(), check_helm_repo_refs(), check_ks_components(), check_ks_paths(), check_kustomization_refs() (+10 more)

### Community 14 - "Bootstrap Helmfile Core Releases"
Cohesion: 0.12
Nodes (19): Helmfile release: cert-manager, Helmfile release: cilium, Helmfile release: coredns, Helmfile release: flux-instance, Helmfile release: flux-operator, Helmfile release: spegel, ClusterIssuer letsencrypt-production, cert-manager kustomizeconfig nameReference (HelmRelease valuesFrom) (+11 more)

### Community 15 - "External Proxy Apps (Grafana/Proxmox)"
Cohesion: 0.21
Nodes (17): Service grafana (external), Flux Kustomization external-grafana, Kustomization: external namespace aggregator, ConfigMap proxmox-ca, BackendTLSPolicy proxmox-tls, Kustomization: proxmox app aggregator, Deployment proxmox-nginx, ConfigMap proxmox-nginx-config (+9 more)

### Community 16 - "PR CI Workflows & Agents"
Cohesion: 0.17
Nodes (16): PR Check Workflow, Yayamlls Workflow, yamllint config (.github/yamllint.config.yaml), Cloudflare Agent (juno.moe zone ops), GitOps Agent, Talos Agent, /validate command, GitButler CLI Key Concepts reference (+8 more)

### Community 17 - "Rook-Ceph Storage Cluster"
Cohesion: 0.19
Nodes (16): Kustomization: rook-ceph namespace root, Namespace rook-ceph (privileged PSA), HelmRelease rook-ceph-operator, Kustomization: rook-ceph operator app resources, OCIRepository rook-ceph chart, ConfigMap rook-ceph-dashboard-proxy-config (nginx conf), Deployment rook-ceph-dashboard-proxy (nginx), HTTPRoute rook-ceph-dashboard (rook.juno.moe) (+8 more)

### Community 18 - "GitHub Issue Templates & Labels"
Cohesion: 0.15
Nodes (15): Bug Report Issue Template, Deploy New App Issue Template, Improvement Issue Template, Question / Help Issue Template, Maintenance Issue Template, Repository Label Definitions, Label: bug, Label: deploy (+7 more)

### Community 19 - "VolSync Maintenance & Kopia"
Cohesion: 0.28
Nodes (13): OCIRepository: volsync (perfectra1n chart), Flux Kustomization: volsync-maintenance, Flux Kustomization: volsync (app), ExternalSecret: volsync-maintenance, KopiaMaintenance: daily, Kustomize aggregator: volsync maintenance, MutatingAdmissionPolicyBinding: kopia-maintenance-nfs, MutatingAdmissionPolicy: kopia-maintenance-nfs (injects NFS repository volume) (+5 more)

### Community 20 - "System Upgrade (Talos/K8s via tuppr)"
Cohesion: 0.24
Nodes (12): Secret: rook-ceph-config (SOPS-encrypted), Secret: rook-ceph-mon (SOPS-encrypted), ExternalSecret: tuppr, HelmRelease: tuppr, KubernetesUpgrade: kubernetes, Kustomization: system-upgrade app resources, OCIRepository: tuppr, TalosUpgrade: cluster (+4 more)

### Community 21 - "Flux Meta Repos Bootstrap"
Cohesion: 0.17
Nodes (12): Kustomization: cluster-apps, Kustomization: cluster-meta, Kustomization aggregator (flux/meta), Namespace: observability, HelmRepository: backube, HelmRepository: coroot, HelmRepository: external-dns, HelmRepository: grafana (+4 more)

### Community 22 - "Talos Machine Patches & VolSync Docs"
Cohesion: 0.20
Nodes (11): Kopia (backup repository/snapshot tool), VolSync (Kubernetes PVC backup/restore operator), Manual VolSync Snapshot Restore Guide, EthernetConfig: eno1 (disable TSO/GSO/GRO offloads), Controller Patch: apiServer resource limits, Controller Patch: cluster (apiServer/controllerManager/etcd/scheduler/coreDNS/proxy), Global Patch: machine.features (Talos API access), Global Patch: machine.files (Spegel containerd config, NFS mount options) (+3 more)

### Community 23 - "Talos Control Plane Nodes"
Cohesion: 0.27
Nodes (10): Cloudflared QUIC Tunnel, Watchdog (inotify tuning), Talos Machine Sysctls Patch, Talos Machine Time Patch, Talos Cluster Configuration (talhelper), k8s-0 Control Plane Node, k8s-1 Control Plane Node, k8s-2 Control Plane Node (+2 more)

### Community 24 - "Bootstrap Apps Script"
Cohesion: 0.33
Nodes (9): apply_crds(), apply_namespaces(), apply_sops_secrets(), LOG_LEVEL, main(), ROOT_DIR, bootstrap-apps.sh script, sync_helm_releases() (+1 more)

### Community 25 - "Observability VM Docker Compose"
Cohesion: 0.28
Nodes (9): Grafana Alloy Agent (in-cluster metrics shipper), Caddy Reverse Proxy Service, Grafana Service, Loki Service, Prometheus Service, Grafana Dashboards Provisioning Config, Grafana Datasources Provisioning Config, Loki Configuration (+1 more)

### Community 26 - "Flux Instance & GitHub Webhook"
Cohesion: 0.36
Nodes (9): ExternalSecret github-webhook-token, Kustomize Configurations nameReference (ConfigMap -> HelmRelease valuesFrom), FluxInstance values.yaml (distribution 2.9.3, controller patches), HelmRelease flux-instance, OCIRepository flux-instance, HTTPRoute github-webhook, Kustomization: flux-instance app aggregator, Receiver github-webhook (+1 more)

### Community 27 - "Smartctl & Unpoller Exporters"
Cohesion: 0.33
Nodes (9): HelmRelease smartctl-exporter, Kustomization: smartctl-exporter app resources, OCIRepository smartctl-exporter chart, Flux Kustomization smartctl-exporter, ExternalSecret unpoller, HelmRelease unpoller, Kustomization: unpoller app resources, OCIRepository app-template chart (unpoller) (+1 more)

### Community 28 - "Container Scan & Scorecard CI"
Cohesion: 0.39
Nodes (7): Scan Containers Workflow, OpenSSF Scorecard Workflow, entry(), main(), parse_command_line(), container-parser.sh script, show_help()

### Community 29 - "Gatus Health Checks"
Cohesion: 0.46
Nodes (8): ExternalSecret: gatus, HelmRelease: gatus, Kustomization: gatus/app, ClusterRole: gatus, ClusterRoleBinding: gatus, ServiceAccount: gatus, Gatus application config.yaml, Flux Kustomization: gatus

### Community 30 - "Kopia & Snapshot Controller"
Cohesion: 0.29
Nodes (8): ExternalSecret: kopia, HelmRelease: kopia, Kustomization: kopia app resources, Flux Kustomization: kopia, Kustomization: volsync-system root, HelmRelease: snapshot-controller, Kustomization: snapshot-controller app resources, Flux Kustomization: snapshot-controller

### Community 31 - "Common Kustomize Components & SOPS"
Cohesion: 0.29
Nodes (8): Kustomize Component: common, Namespace: not-used (prune-disabled placeholder), Kustomize aggregator: app-template repo, OCIRepository: app-template (bjw-s-labs), Kustomize aggregator: common repos, SOPS Secret: cluster-secrets, Kustomize aggregator: common sops, SOPS Secret: sops-age (decryption key)

### Community 33 - "Post-Process Download Script"
Cohesion: 0.52
Nodes (6): main(), search_cross_seed(), send_pushover_notification(), set_qb_vars(), set_sab_vars(), post-process.sh script

### Community 34 - "Blackbox Exporter Probes"
Cohesion: 0.53
Nodes (6): HelmRelease: blackbox-exporter, Blackbox Exporter App Kustomization, VMProbe: devices (icmp), VMProbe: nfs (tcp_connect), OCIRepository: blackbox-exporter chart, Flux Kustomization: blackbox-exporter

### Community 35 - "GitOps Pipeline Stages Overview"
Cohesion: 0.33
Nodes (6): Auto-Merge (evaluates policy daily at 02:00 UTC), CI gates (flate + yayamlls), Flux (applies to cluster), Konflate (renders cluster diff, flags cautions), Labeler (classifies PR by labels/path), Renovate (opens PRs hourly)

### Community 36 - "Cilium Gateway TLS Certificates"
Cohesion: 0.60
Nodes (5): Certificate juno-moe-production, Gateway external, Gateway internal, cilium gateway Kustomization, Flux Kustomization cilium-gateway

### Community 37 - "CSI Driver NFS Storage"
Cohesion: 0.40
Nodes (5): HelmRelease csi-driver-nfs, OCIRepository csi-driver-nfs, StorageClass nfs-slow (NFS on nas.internal), Kustomization (csi-driver-nfs app), Flux Kustomization csi-driver-nfs

### Community 38 - "Common Shell Script Helpers"
Cohesion: 0.60
Nodes (4): check_cli(), check_env(), log(), common.sh script

### Community 39 - "External Grafana Reverse Proxy"
Cohesion: 0.67
Nodes (4): Kustomization grafana/app (external), Deployment grafana-nginx reverse proxy, ConfigMap grafana-nginx-config, HTTPRoute grafana

### Community 40 - "Sabnzbd Download Client"
Cohesion: 0.67
Nodes (4): Sabnzbd ExternalSecret, Sabnzbd HelmRelease, Sabnzbd App Kustomization, Sabnzbd Flux Kustomization

### Community 41 - "Etcd Metrics Scrape"
Cohesion: 0.67
Nodes (4): Endpoints: etcd-metrics, Flux Kustomization: etcd-scrape, Etcd Scrape Kustomization, Service: etcd-metrics (headless)

### Community 42 - "VolSync App Monitoring"
Cohesion: 0.83
Nodes (4): GrafanaDashboard: volsync, HelmRelease: volsync, Kustomization: volsync app resources, VMRule: volsync

### Community 43 - "Docker Volume Backup Script"
Cohesion: 0.83
Nodes (3): backup-volume(), main(), backup-docker-volume.sh script

### Community 44 - "Stuck Container Cleanup Script"
Cohesion: 0.83
Nodes (3): delete_from_source(), delete_pod(), delete-stuck.containers.sh script

### Community 45 - "Deploy Script"
Cohesion: 0.83
Nodes (3): err(), log(), deploy.sh script

### Community 46 - "Linter Configs (Markdown/YAML/Mega)"
Cohesion: 0.67
Nodes (3): Markdownlint Configuration, Yamllint Configuration, MegaLinter Workflow

### Community 47 - "Plex App & Alerts"
Cohesion: 1.00
Nodes (3): Plex App Kustomization, PlexDatabaseIsBusy Loki Alert Rule, Plex Flux Kustomization

### Community 48 - "Smartctl Grafana Dashboard"
Cohesion: 0.67
Nodes (3): Grafana.com Dashboard 22604 (smartctl-exporter), Datasource: Prometheus (Grafana), GrafanaDashboard: smartctl-exporter

### Community 49 - "KEDA NFS Scaler Component"
Cohesion: 0.67
Nodes (3): Kustomize Component: keda nfs-scaler, ScaledObject: ${APP} (NFS-probe scale-to-zero), ClusterTriggerAuthentication: keda-prometheus-credentials

## Ambiguous Edges - Review These
- `PR Check Workflow` → `yamllint config (.github/yamllint.config.yaml)`  [AMBIGUOUS]
  .github/workflows/pr-check.yml · relation: semantically_similar_to
- `yamllint config (.github/yamllint.config.yaml)` → `pre-commit config (.pre-commit-config.yaml)`  [AMBIGUOUS]
  .github/yamllint.config.yaml · relation: semantically_similar_to
- `Kustomization: database namespace root` → `ExternalSecret pgbackup`  [AMBIGUOUS]
  kubernetes/apps/database/kustomization.yaml · relation: references
- `Deployment grafana-nginx reverse proxy` → `HTTPRoute grafana`  [AMBIGUOUS]
  kubernetes/apps/external/grafana/app/route.yaml · relation: references
- `Flux Kustomization csi-driver-nfs` → `Kustomization kube-system (namespace aggregator)`  [AMBIGUOUS]
  kubernetes/apps/kube-system/kustomization.yaml · relation: references
- `HelmRelease: seerr` → `HelmRelease: sonarr`  [AMBIGUOUS]
  kubernetes/apps/media/sonarr/app/helmrelease.yaml · relation: semantically_similar_to
- `ExternalSecret: grafana-admin-password` → `Kustomization: grafana/app`  [AMBIGUOUS]
  kubernetes/apps/observability/grafana/app/kustomization.yaml · relation: references
- `GrafanaDatasource: loki` → `Kustomization: grafana/instance`  [AMBIGUOUS]
  kubernetes/apps/observability/grafana/instance/kustomization.yaml · relation: references
- `ScaledObject: ${APP} (NFS-probe scale-to-zero)` → `ClusterTriggerAuthentication: keda-prometheus-credentials`  [AMBIGUOUS]
  kubernetes/components/keda/nfs-scaler/scaledobject.yaml · relation: conceptually_related_to
- `EthernetConfig: eno1 (disable TSO/GSO/GRO offloads)` → `Global Patch: machine.network (nameservers, disableSearchDomain)`  [AMBIGUOUS]
  talos/manifests/e1000e.yaml · relation: conceptually_related_to

## Knowledge Gaps
- **242 isolated node(s):** `functions.sh script`, `$schema`, `small_model`, `type`, `url` (+237 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **42 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `PR Check Workflow` and `yamllint config (.github/yamllint.config.yaml)`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **What is the exact relationship between `yamllint config (.github/yamllint.config.yaml)` and `pre-commit config (.pre-commit-config.yaml)`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **What is the exact relationship between `Kustomization: database namespace root` and `ExternalSecret pgbackup`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `Deployment grafana-nginx reverse proxy` and `HTTPRoute grafana`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `Flux Kustomization csi-driver-nfs` and `Kustomization kube-system (namespace aggregator)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `HelmRelease: seerr` and `HelmRelease: sonarr`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **What is the exact relationship between `ExternalSecret: grafana-admin-password` and `Kustomization: grafana/app`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._