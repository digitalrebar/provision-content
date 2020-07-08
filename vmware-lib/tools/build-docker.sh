#!/usr/bin/env bash
# build docker container TGZ from the dockerfiles/* files

CONTAINERS=${*:-"$(ls -1 dockerfiles/dockerfile-* | grep -v "\.tar$")"}

set -e

for C in $CONTAINERS
do
  D=$(dirname $C)
  N=$(echo $C | sed "s|^$D/dockerfile-||")
  I="digitalrebar-$N"
  T="${C}.tar"

  [[ -r "$D/$T" ]] && rm -f $D/$T

  echo ">>> BUILDING $I"
  docker build . --file=$D/$C --tag=$I
  docker save $I > $D/$T

  [[ -s "$D/$T" ]] && echo ">>> SAVED as $T" || echo "!!!!!!!!!! zero length: $D/$T"

  echo ""
done


