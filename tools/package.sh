#!/bin/bash

set -e

family=386
if [[ $(uname -m) == x86_64 ]] ; then
    family=amd64
fi
case $(uname -s) in
    Darwin)
        binpath="bin/darwin/$family"
        shasum="command shasum -a 256"
        tar="command bsdtar"
        ;;
    Linux)
        binpath="bin/linux/$family"
        shasum="command sha256sum"
        tar="command bsdtar"
        ;;
    *)
        # Someday, support installing on Windows.  Service creation could be tricky.
        echo "No idea how to check sha256sums"
        exit 1;;
esac

if [ ! -e drp ] ; then
  mkdir -p drp
  cd drp

  DRP_VERSION=tip
  echo "Installing Version $DRP_VERSION of Digital Rebar Provision"
  curl -sfL -o dr-provision.zip https://github.com/digitalrebar/provision/releases/download/$DRP_VERSION/dr-provision.zip
  curl -sfL -o dr-provision.sha256 https://github.com/digitalrebar/provision/releases/download/$DRP_VERSION/dr-provision.sha256
  $shasum -c dr-provision.sha256
  $tar -xf dr-provision.zip

  rm -f drpcli
  ln -s $binpath/drpcli drpcli

  cd ..
fi

. tools/version.sh

drp/drpcli contents bundle drp-community-content.yaml Description="Digital Rebar Provision Community Content" Version="$Prepart$MajorV.$MinorV.$PatchV$Extra-$GITHASH" Source="https://github.com/digitalrebar/provision-content" Name="drp-community-content" --format=yaml
$shasum drp-community-content.yaml > drp-community-content.sha256
