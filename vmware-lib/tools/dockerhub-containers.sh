#!/usr/bin/env bash

###
#  Use this script to pull down the Container images form Docker Hub, instead of
#  building them from source.
###

CONTEXTS="govc vcsa-deploy context-runner"

for CONTEXT in $CONTEXTS
do
  echo "Getting container '$CONTEXT' from docker hub"
  docker pull digitalrebar/$CONTEXT
  echo "Saving container  '$CONTEXT' to local tar file"
  docker save digitalrebar/$CONTEXT > dockerfiles/dockerfile-$CONTEXT.tar
done
