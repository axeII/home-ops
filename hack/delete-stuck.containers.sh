#!/usr/bin/env bash

function delete_pod () {
    echo "Deleting pod $1"
    kubectl delete pod $1
}

TERMINATING_POD=$(kubectl get pods | awk '$3=="ContainerStatusUnknown" {print $1}')

for pod in $TERMINATING_POD
do
    delete_pod $pod
done
