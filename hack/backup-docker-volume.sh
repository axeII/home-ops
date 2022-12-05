#!/usr/bin/env bash

set -o errexit
set -o pipefail

function backup-volume(){
    local volume
    volume=$(docker volume ls | awk '$2 != "VOLUME" {print $2}' | fzf)

    docker run --rm --name backup\
    -v "$volume":/backup-volume \
    busybox \
    /bin/sh -c \
    "tar zcf - /backup-volume | cat" > $volume.tar.gz
    #"tar acf - /backup-volume | cat" > $volume.tar.zst
}


function main() {
    backup-volume
}


main
