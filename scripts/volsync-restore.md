# Manual VolSync Snapshot Restore Guide

<!-- **Path:** `kubernetes/components/volsync/MANUAL_RESTORE.md` -->

Use this procedure to restore a **specific** snapshot ID (found via Kopia UI) when the standard VolSync `ReplicationDestination` cannot be used (e.g., needed specific point-in-time recovery).

## 1. Set Variables

Define the target application and environment details.

```bash
# === CONFIGURATION ===
export APP=plex                        # Deployment / PVC name
export NS=media                        # Namespace
export NFS_SERVER=10.10.x.x            # TrueNAS IP address
export NFS_PATH=/mnt/storage0/backups  # VolSync/Kopia repo parent folder
export UID=1000                        # File ownership UID (1000 for most apps, 999 for Postgres)
```

## 2. Stop the World
```bash
flux suspend kustomization $APP -n $NS
flux suspend helmrelease $APP -n $NS
kubectl scale deployment $APP -n $NS --replicas=0
```

## 3. Deploy Restore Shell

```bash
cat <<EOF > restore-shell.yaml
apiVersion: v1
kind: Pod
metadata:
  name: ${APP}-restore-shell
  namespace: ${NS}
spec:
  restartPolicy: Never
  containers:
    - name: shell
      image: kopia/kopia:latest
      # Sleep forever so we can log in
      command: ["/bin/bash", "-c", "sleep infinity"]
      env:
        - name: KOPIA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ${APP}-volsync-secret
              key: KOPIA_PASSWORD
      volumeMounts:
        - name: data
          mountPath: /data
        - name: repository
          mountPath: /repository
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: ${APP}
    - name: repository
      nfs:
        server: ${NFS_SERVER}
        path: ${NFS_PATH}
EOF

kubectl apply -f restore-shell.yaml
kubectl wait --for=condition=ready pod/${APP}-restore-shell -n $NS --timeout=60s
```

---
## 4. Execute Restore

```bash
kubectl exec -it ${APP}-restore-shell -n $NS -- bash
```

### Inside the Pod (Run these commands):

```bash
# 1. Connect to the Repo
# Note: Hostname/Username usually match the App name in VolSync setup
kopia repository connect filesystem --path=/repository --override-hostname=${APP} --override-username=${APP}

# 2. (Optional) Verify Snapshots
kopia snapshot list

# 3. Wipe Bad Data (Recommended for clean restore)
# ⚠️ WARNING: This deletes current PVC data
rm -rf /data/*

# 4. Restore Specific Snapshot
# Go to your Kopia UI (e.g. kopia.dcunha.io) to find the Snapshot ID (e.g. k3eda...)
kopia snapshot restore <SNAPSHOT_ID> /data

# 5. Fix Permissions
# Restore often leaves files as root. Reset to the app's user ID.
chown -R ${UID}:${UID} /data

exit
```

## 5. Cleanup & Resume

```bash
# Delete Shell
kubectl delete -f restore-shell.yaml

# Restore Traffic
kubectl scale deployment $APP -n $NS --replicas=1
flux resume kustomization $APP -n $NS
flux resume helmrelease $APP -n $NS

# Remove local temp file
rm restore-shell.yaml
```
