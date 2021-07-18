




sync:
	flux --kubeconfig=./kubeconfig reconcile source git flux-system

kustom-health:
	kubectl --kubeconfig=./kubeconfig get kustomization -A

helm-health:
	flux --kubeconfig=./kubeconfig get helmrelease -A
