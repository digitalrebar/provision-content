#!/bin/bash

set -e

case $(uname -s) in
    Darwin)
        shasum="command shasum -a 256";;
    Linux)
        shasum="command sha256sum";;
    *)
        # Someday, support installing on Windows.  Service creation could be tricky.
        echo "No idea how to check sha256sums"
        exit 1;;
esac

if [ ! -e drp ] ; then
  mkdir -p drp
  cd drp
  curl -fsSL https://raw.githubusercontent.com/digitalrebar/provision/master/tools/install.sh | bash -s -- --isolated --drp-version=tip install
  cd ..
fi

drp/drpcli contents bundle drp-community-content.yaml --format=yaml
$shasum drp-community-content.yaml > drp-community-content.sha256
