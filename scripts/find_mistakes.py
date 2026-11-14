
#!/usr/bin/env python3
"""Pre-flight validation for home-ops Kubernetes GitOps repository.

Catches common mistakes before Flux applies them to the cluster:
- Missing files referenced in kustomization.yaml
- App directories not registered in namespace kustomization
- ks.yaml paths pointing to nonexistent directories
- HelmRelease referencing nonexistent HelmRepository
- Component paths that don't exist
- dependsOn referencing Kustomizations that aren't defined
- Duplicate resource references in kustomizations
- talosctl/kubectl pins drifting from the cluster versions they talk to
- A Kubernetes version the pinned Talos does not support, or tuppr upgrade
  CRs disagreeing with talos/talenv.yaml
"""

import sys
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
APPS_DIR = ROOT / "kubernetes" / "apps"
FLUX_DIR = ROOT / "kubernetes" / "flux"
MISE_TOML = ROOT / "mise.toml"
TALENV = ROOT / "talos" / "talenv.yaml"
UPGRADE_DIR = APPS_DIR / "system-upgrade" / "app"

# Kubernetes minors each Talos minor supports, inclusive. Copied from
# MinimumKubernetesVersion / MaximumKubernetesVersion in Talos's
# pkg/machinery/compatibility/talos1XX/talos1XX.go, which is what Talos itself
# enforces on upgrade-k8s (the docs support matrix has lagged it before).
# A Talos minor missing here is an error, not a pass: moving to a new Talos
# minor starts with adding its row.
TALOS_KUBERNETES_SUPPORT = {
    (1, 13): ((1, 31), (1, 36)),
    (1, 14): ((1, 32), (1, 37)),
}

errors: list[str] = []
warnings: list[str] = []


def rel(path: pathlib.Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def find_kustomization_files() -> list[pathlib.Path]:
    return sorted((ROOT / "kubernetes").rglob("kustomization.yaml"))


def find_ks_files() -> list[pathlib.Path]:
    return sorted((ROOT / "kubernetes").rglob("ks.yaml"))


# ── Check 1: Missing files referenced in kustomization.yaml ──────────────

def check_kustomization_refs():
    for kfile in find_kustomization_files():
        kdir = kfile.parent
        try:
            content = kfile.read_text()
        except OSError:
            continue

        in_resources = False
        in_components = False
        in_configmap_files = False

        for line in content.splitlines():
            stripped = line.strip()

            if stripped.startswith("#") or not stripped:
                continue

            if re.match(r'^resources:\s*$', stripped):
                in_resources = True
                in_components = False
                in_configmap_files = False
                continue
            elif re.match(r'^components:\s*$', stripped):
                in_components = True
                in_resources = False
                in_configmap_files = False
                continue
            elif re.match(r'^files:\s*$', stripped):
                in_configmap_files = True
                continue
            elif re.match(r'^\w', stripped) and not stripped.startswith("-"):
                in_resources = False
                in_components = False
                in_configmap_files = False
                continue

            if in_resources and stripped.startswith("- "):
                ref = stripped[2:].strip()
                if ref.startswith("#") or ref.startswith("http"):
                    continue
                ref = ref.split(" #")[0].strip()
                target = (kdir / ref).resolve()
                if not target.exists():
                    errors.append(f"Missing resource: {rel(kfile)} -> {ref}")

            if in_components and stripped.startswith("- "):
                ref = stripped[2:].strip()
                if ref.startswith("#"):
                    continue
                target = (kdir / ref).resolve()
                if not target.exists():
                    errors.append(f"Missing component: {rel(kfile)} -> {ref}")

            if in_configmap_files and stripped.startswith("- "):
                ref = stripped[2:].strip()
                if ref.startswith("#"):
                    continue
                # name: entries start a new configMapGenerator item, not a file ref
                if re.match(r'name:\s', ref):
                    in_configmap_files = False
                    continue
                if "=" in ref:
                    ref = ref.split("=", 1)[1]
                target = (kdir / ref).resolve()
                if not target.exists():
                    errors.append(f"Missing file: {rel(kfile)} -> {ref}")


# ── Check 2: ks.yaml path references ─────────────────────────────────────

def check_ks_paths():
    for ks_file in find_ks_files():
        try:
            content = ks_file.read_text()
        except OSError:
            continue

        for match in re.finditer(r'^\s+path:\s+(\./\S+)', content, re.MULTILINE):
            path_ref = match.group(1)
            target = (ROOT / path_ref).resolve()
            if not target.exists():
                errors.append(f"ks.yaml path missing: {rel(ks_file)} -> {path_ref}")
            elif not (target / "kustomization.yaml").exists():
                # Skip root aggregation paths (Flux auto-generates kustomization)
                if any(target == (ROOT / d).resolve() for d in (
                    "kubernetes/apps", "kubernetes/flux",
                )):
                    continue
                errors.append(
                    f"ks.yaml path has no kustomization.yaml: {rel(ks_file)} -> {path_ref}"
                )


# ── Check 3: Unregistered app directories ────────────────────────────────

def check_unregistered_apps():
    if not APPS_DIR.exists():
        return

    for ns_dir in sorted(APPS_DIR.iterdir()):
        if not ns_dir.is_dir():
            continue
        ns_kustomization = ns_dir / "kustomization.yaml"
        if not ns_kustomization.exists():
            continue

        try:
            ns_content = ns_kustomization.read_text()
        except OSError:
            continue

        referenced = set()
        commented = set()
        for line in ns_content.splitlines():
            stripped = line.strip()
            m = re.match(r'^-\s+\./(\S+)/ks\.yaml', stripped)
            if m:
                referenced.add(m.group(1))
                continue
            m = re.match(r'^#\s*-\s+\./(\S+)/ks\.yaml', stripped)
            if m:
                commented.add(m.group(1))

        for app_dir in sorted(ns_dir.iterdir()):
            if not app_dir.is_dir():
                continue
            app_name = app_dir.name
            if not (app_dir / "ks.yaml").exists():
                continue
            if app_name not in referenced and app_name not in commented:
                warnings.append(
                    f"Unregistered app: {rel(app_dir)}/ks.yaml not in {rel(ns_kustomization)}"
                )


# ── Check 4: Duplicate resources in kustomization.yaml ───────────────────

def check_duplicate_resources():
    for kfile in find_kustomization_files():
        try:
            content = kfile.read_text()
        except OSError:
            continue

        in_resources = False
        refs = []
        for line in content.splitlines():
            stripped = line.strip()
            if stripped.startswith("#") or not stripped:
                continue
            if re.match(r'^resources:\s*$', stripped):
                in_resources = True
                continue
            elif re.match(r'^\w', stripped) and not stripped.startswith("-"):
                in_resources = False
                continue
            if in_resources and stripped.startswith("- "):
                refs.append(stripped[2:].strip())

        seen = set()
        for ref in refs:
            if ref in seen:
                errors.append(f"Duplicate resource: {rel(kfile)} -> {ref}")
            seen.add(ref)


# ── Check 5: ks.yaml component paths ─────────────────────────────────────

def check_ks_components():
    for ks_file in find_ks_files():
        try:
            content = ks_file.read_text()
        except OSError:
            continue

        for doc in re.split(r'^---\s*$', content, flags=re.MULTILINE):
            path_match = re.search(r'^\s+path:\s+(\./\S+)', doc, re.MULTILINE)
            if not path_match:
                continue
            base_path = ROOT / path_match.group(1)

            in_components = False
            for line in doc.splitlines():
                stripped = line.strip()
                if stripped.startswith("#"):
                    continue
                if re.match(r'components:\s*$', stripped):
                    in_components = True
                    continue
                elif re.match(r'\w', stripped) and not stripped.startswith("-"):
                    in_components = False
                    continue
                if in_components and stripped.startswith("- "):
                    ref = stripped[2:].strip()
                    if ref.startswith("#"):
                        continue
                    target = (base_path / ref).resolve()
                    if not target.exists():
                        errors.append(f"Missing component: {rel(ks_file)} -> {ref}")


# ── Check 6: HelmRelease -> HelmRepository references ────────────────────

def check_helm_repo_refs():
    known_repos: set[str] = set()

    # Scan flux/meta/repos
    repos_dir = FLUX_DIR / "meta" / "repos"
    if repos_dir.exists():
        for f in repos_dir.rglob("*.yaml"):
            if f.name == "kustomization.yaml":
                continue
            try:
                text = f.read_text()
            except OSError:
                continue
            if "kind: HelmRepository" in text:
                for m in re.finditer(r'^\s+name:\s+(\S+)', text, re.MULTILINE):
                    known_repos.add(m.group(1))

    # Scan all kubernetes/ for inline repo definitions and component repos
    for kind in ("HelmRepository", "OCIRepository"):
        for f in (ROOT / "kubernetes").rglob("*.yaml"):
            if f.name == "kustomization.yaml":
                continue
            try:
                text = f.read_text()
            except OSError:
                continue
            if f"kind: {kind}" not in text:
                continue
            # Match both metadata-wrapped and direct name patterns
            for m in re.finditer(
                rf'kind:\s+{kind}\s*\n\s*metadata:\s*\n\s+name:\s+(\S+)',
                text,
            ):
                known_repos.add(m.group(1))
            # Simpler pattern (e.g. in components)
            for m in re.finditer(
                rf'kind:\s+{kind}\s*\n(?:(?!\nkind:)[\s\S])*?^\s+name:\s+(\S+)',
                text,
                re.MULTILINE,
            ):
                known_repos.add(m.group(1))

    for f in (ROOT / "kubernetes").rglob("helmrelease.yaml"):
        try:
            text = f.read_text()
        except OSError:
            continue
        for m in re.finditer(
            r'sourceRef:\s*\n\s+kind:\s+HelmRepository\s*\n\s+name:\s+(\S+)',
            text,
        ):
            if m.group(1) not in known_repos:
                errors.append(f"HelmRepository not found: {rel(f)} -> '{m.group(1)}'")

        for m in re.finditer(
            r'chartRef:\s*\n\s+kind:\s+OCIRepository\s*\n\s+name:\s+(\S+)',
            text,
        ):
            if m.group(1) not in known_repos:
                errors.append(f"OCIRepository not found: {rel(f)} -> '{m.group(1)}'")


# ── Check 7: dependsOn references ────────────────────────────────────────

def check_depends_on():
    defined_ks: set[str] = set()

    for ks_file in find_ks_files():
        try:
            content = ks_file.read_text()
        except OSError:
            continue
        for m in re.finditer(r'^\s+name:\s+(?:&\w+\s+)?(\S+)', content, re.MULTILINE):
            defined_ks.add(m.group(1))

    cluster_dir = FLUX_DIR / "cluster"
    if cluster_dir.exists():
        for f in cluster_dir.rglob("*.yaml"):
            try:
                content = f.read_text()
            except OSError:
                continue
            if "kind: Kustomization" in content:
                for m in re.finditer(r'^\s+name:\s+(?:&\w+\s+)?(\S+)', content, re.MULTILINE):
                    defined_ks.add(m.group(1))

    for ks_file in find_ks_files():
        try:
            content = ks_file.read_text()
        except OSError:
            continue

        in_depends = False
        for line in content.splitlines():
            stripped = line.strip()
            if stripped == "---":
                in_depends = False
                continue
            if stripped.startswith("#"):
                continue
            if re.match(r'dependsOn:\s*$', stripped):
                in_depends = True
                continue
            if in_depends and not stripped.startswith("-"):
                in_depends = False
                continue
            if in_depends:
                m = re.match(r'-\s+name:\s+(\S+)', stripped)
                if m and m.group(1) not in defined_ks:
                    warnings.append(
                        f"dependsOn target not found: {rel(ks_file)} -> '{m.group(1)}'"
                    )


# ── Check 8: Namespace kustomization.yaml has common component ───────────

def check_common_component():
    if not APPS_DIR.exists():
        return

    for ns_dir in sorted(APPS_DIR.iterdir()):
        if not ns_dir.is_dir():
            continue
        ns_kustomization = ns_dir / "kustomization.yaml"
        if not ns_kustomization.exists():
            continue
        try:
            content = ns_kustomization.read_text()
        except OSError:
            continue
        if "components/common" not in content:
            warnings.append(f"Missing common component: {rel(ns_kustomization)}")


def check_client_tool_versions():
    """Client tools in mise.toml must match the cluster in talos/talenv.yaml.

    talosctl and kubectl are pinned in mise.toml; the cluster they talk to is
    pinned in talos/talenv.yaml. Renovate groups each tool with its cluster
    version so they move together; this catches one side bumped without the
    other.
    """
    if not MISE_TOML.exists() or not TALENV.exists():
        return
    try:
        mise = MISE_TOML.read_text()
        talenv = TALENV.read_text()
    except OSError:
        return

    pairs = [
        ("talosctl", r'^talosctl\s*=\s*"([^"]+)"', r"^talosVersion:\s*v?(\S+)"),
        ("kubectl", r'^kubectl\s*=\s*"([^"]+)"', r"^kubernetesVersion:\s*v?(\S+)"),
    ]
    for tool, tool_re, cluster_re in pairs:
        pinned = re.search(tool_re, mise, re.MULTILINE)
        cluster = re.search(cluster_re, talenv, re.MULTILINE)
        if not pinned or not cluster:
            continue
        if pinned.group(1) != cluster.group(1):
            errors.append(
                f"{tool} is {pinned.group(1)} in mise.toml but the cluster is "
                f"{cluster.group(1)} in talos/talenv.yaml - bump both together"
            )


def minor(version: str):
    m = re.match(r"v?(\d+)\.(\d+)", version)
    return (int(m.group(1)), int(m.group(2))) if m else None


def fmt(m) -> str:
    return f"{m[0]}.{m[1]}"


def check_cluster_versions():
    """Kubernetes must be a version the pinned Talos supports.

    Talos and Kubernetes arrive as separate Renovate PRs, so nothing in review
    shows the pair side by side. This fails a PR that would leave
    kubernetesVersion outside the range talosVersion supports - in either
    direction, so a Talos bump that drops the running Kubernetes minor fails too.

    tuppr applies the versions in its TalosUpgrade / KubernetesUpgrade CRs, not
    talenv.yaml, so those must match talenv.yaml for the check to mean anything.
    """
    if not TALENV.exists():
        return
    try:
        talenv = TALENV.read_text()
    except OSError:
        return

    talos = re.search(r"^talosVersion:\s*(\S+)", talenv, re.MULTILINE)
    k8s = re.search(r"^kubernetesVersion:\s*(\S+)", talenv, re.MULTILINE)
    if not talos or not k8s:
        errors.append("talos/talenv.yaml: talosVersion or kubernetesVersion not found")
        return
    talos, k8s = talos.group(1), k8s.group(1)

    for cr, pinned in (("talos-upgrade.yaml", talos), ("kubernetes-upgrade.yaml", k8s)):
        path = UPGRADE_DIR / cr
        try:
            found = re.search(r"^\s+version:\s*(\S+)", path.read_text(), re.MULTILINE)
        except OSError:
            errors.append(f"{rel(path)}: not found")
            continue
        if not found:
            errors.append(f"{rel(path)}: spec version not found")
        elif found.group(1).lstrip("v") != pinned.lstrip("v"):
            errors.append(
                f"{rel(path)} upgrades to {found.group(1)} but talos/talenv.yaml "
                f"pins {pinned} - bump both together"
            )

    talos_minor, k8s_minor = minor(talos), minor(k8s)
    if not talos_minor or not k8s_minor:
        errors.append(f"talos/talenv.yaml: cannot parse {talos} / {k8s}")
        return
    supported = TALOS_KUBERNETES_SUPPORT.get(talos_minor)
    if not supported:
        errors.append(
            f"Talos {fmt(talos_minor)} has no row in TALOS_KUBERNETES_SUPPORT "
            "(scripts/find_mistakes.py) - add its Kubernetes range from the "
            "Talos support matrix"
        )
        return
    lo, hi = supported
    if not lo <= k8s_minor <= hi:
        first = "Talos" if k8s_minor > hi else "Kubernetes"
        errors.append(
            f"Kubernetes {k8s} is not supported by Talos {talos} "
            f"(supports {fmt(lo)}-{fmt(hi)}) - upgrade {first} first"
        )


# ── Main ──────────────────────────────────────────────────────────────────

def main():
    checks = [
        ("Kustomization file references", check_kustomization_refs),
        ("Flux Kustomization paths", check_ks_paths),
        ("Unregistered apps", check_unregistered_apps),
        ("Duplicate resources", check_duplicate_resources),
        ("Flux Kustomization components", check_ks_components),
        ("HelmRepository references", check_helm_repo_refs),
        ("dependsOn references", check_depends_on),
        ("Common component usage", check_common_component),
        ("Client tool versions", check_client_tool_versions),
        ("Talos/Kubernetes compatibility", check_cluster_versions),
    ]

    for name, check_fn in checks:
        check_fn()

    if errors:
        print(f"\n\033[31m✗ {len(errors)} error(s)\033[0m")
        for e in errors:
            print(f"  \033[31m✗\033[0m {e}")

    if warnings:
        print(f"\n\033[33m⚠ {len(warnings)} warning(s)\033[0m")
        for w in warnings:
            print(f"  \033[33m⚠\033[0m {w}")

    if not errors and not warnings:
        print("\033[32m✓ All checks passed\033[0m")

    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
