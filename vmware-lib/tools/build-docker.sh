#!/usr/bin/env bash
# build docker container TGZ from the dockerfiles/* files

CONTAINERS=${*:-"$(ls -1 dockerfiles/dockerfile-*)"}

set -e

for C in $CONTAINERS
do
  N=$(echo $C | sed 's/^dockerfile-//')
  I="digitalrebar/$N"
  T="${C}.tar"

  [[ -r "$T" ]] && rm -f $T

  echo ">>> BUILDING $I"
  docker build . --file=$C --tag=$I
  docker save $I > $T

  [[ -s "$T" ]] && echo ">>> SAVED as $T" || echo "!!!!!!!!!! zero length: $T"

  echo ""
done


