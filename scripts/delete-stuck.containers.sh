#!/usr/bin/env bash

function delete_pod () {
    echo "Deleting pod $1"
    kubectl delete pod $1
}


function delete_from_source () {
    for pod in $1
    do
        delete_pod $pod
    done
}

UNKNOWN_PODS=$(kubectl get pods | awk '$3=="ContainerStatusUnknown" {print $1}')
EVICTED_PODS=$(kubectl get pods | awk '$3=="Evicted" {print $1}')

delete_from_source $UNKNOWN_PODS
delete_from_source $EVICTED_PODS
