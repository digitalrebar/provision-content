#!/usr/bin/env bash

###
#  Use this script to pull down the Container images form Docker Hub, instead of
#  building them from source.
###

#CONTEXTS="govc vcsa-deploy context-runner"
CONTEXTS="govc vcsa-deploy"

for CONTEXT in $CONTEXTS
do
  T="dockerfiles/dockerfile-$CONTEXT.tar"

  echo "Getting container '$CONTEXT' from docker hub"
  docker pull digitalrebar/$CONTEXT
  echo "Saving container  '$CONTEXT' to local tar file ('$T')"
  [[ -r "$T" ]] && rm -f "$T"
  docker save digitalrebar/$CONTEXT > "$T"
done
