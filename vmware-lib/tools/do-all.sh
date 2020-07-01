#!/usr/bin/env bash
# runs all scripts in an opinionated way to get govc context working

function xiterr() { [[ $1 =~ ^[0-9]+$ ]] && { XIT=$1; shift; } || XIT=1; printf "FATAL: $*\n"; exit $XIT; }

drpcli info check > /dev/null || xiterr 1 "'drpcli info check' failed - can't run API commands to DRP endpoint (set RS_ENDPOINT, RS_KEY, etc?)"

git init
git remote add origin https://github.com/digitalrebar/provision-content.git
git fetch origin
git checkout origin/v4 -- vmware-lib

cd vmware-lib
drpcli catalog item install docker-context
drpcli catalog item install vmware
drpcli catalog item install vmware-lib

tools/dockerhub-containers.sh
tools/drpcli-commands.sh
tools/drpcli-create-machines.sh


