#!/usr/bin/env bash
# build docker container TGZ from the dockerfiles/* files

CONTAINERS=${*:-"$(ls -1 dockerfiles/dockerfile-* | grep -v "\.tar$")"}

set -e

for C in $CONTAINERS
do
  D=$(dirname $C)
  N=$(echo $C | sed "s|^$D/dockerfile-||")
  I="$N"
  T="${C}.tar"

  [[ -r "$T" ]] && rm -f $T

  echo ">>> BUILDING $I"
  docker build . --file=$C --tag=$I
  docker save $I > $T

  [[ -s "$T" ]] && echo ">>> SAVED as $T" || echo "!!!!!!!!!! zero length: $T"

  echo ""
done


