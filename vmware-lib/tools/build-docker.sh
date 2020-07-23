#!/usr/bin/env bash
# build docker container TGZ from the dockerfiles/* files

if [[ -n "$*" ]]
then
  CNTS="$*"
else
  FOUND=$(ls -1 dockerfiles/dockerfile-* | grep -v "\.tar$")
  CNTS=${CONTAINERS:-$FOUND}
fi

for CNT in $CNTS
do
  if [[ -r "$CNT" ]]
  then
    CONTAINERS="$CONTAINERS $CNT"
    continue
  else
    [[ -r "dockerfiles/dockerfile-$CNT" ]] && { CONTAINERS="$CONTAINERS dockerfiles/dockerfile-$CNT"; continue; }
    [[ -r "dockerfiles/$CNT" ]] && { CONTAINERS="$CONTAINERS dockerfiles/$CNT"; continue; }
    echo "FAIL:  Unable to find $CNT, dockerfiles/dockerfile-$CNT, or dockfiles/$CNT to operate on"
    exit 1
  fi
done


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


