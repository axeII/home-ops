# Talos patches

Machine configs are assembled by [topf](https://postfinance.github.io/topf/) from `../topf.yaml`,
the secrets bundle in `../secrets.sops.yaml`, and the strategic merge patches in this directory.

Patches merge in this order, alphabetically inside each directory. Later patches win:

- `all/`: every node
- `control-plane/`: control-plane nodes
- `node/<host>/`: one node

Files ending in `.yaml.tpl` are Go templates rendered per node. `.Node.Host`, `.Node.IP` and
`.Node.Data.<key>` come from the node's entry in `topf.yaml`.

Talos 1.14 configures most things through typed documents (`KubeAPIServerConfig`, `ResolverConfig`,
`TimeSyncConfig`, ...) and rejects the same setting under the old `machine.*` / `cluster.*` keys.
New patches should use the document form. To remove a document Talos generates by default, name it
and add `$patch: delete`.

## Working with it

| Command | What it does |
| --- | --- |
| `just talos-diff` | Shows what would change on each node. Applies nothing. |
| `just talos-apply k8s-1` | Shows the diff for one node, asks, then applies. |
| `just talos-render` | Writes full machine configs to `talos/output/`. They contain secrets. |

Always read `just talos-diff` before applying, and apply one node at a time.

Two settings exist to keep the config equal to what the nodes ran before the move to typed
documents. Do not remove them without reading the comments in the files:

- `all/70-security.yaml`: `workloadIsolation: false`
- `all/71-filesystem.yaml`: no `nosuid,nodev` on `/var`, no weekly fstrim
