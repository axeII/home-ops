
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
"""

import sys
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
APPS_DIR = ROOT / "kubernetes" / "apps"
FLUX_DIR = ROOT / "kubernetes" / "flux"

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
