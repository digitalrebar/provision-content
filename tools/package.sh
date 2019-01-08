#!/bin/bash

set -e

family=386
if [[ $(uname -m) == x86_64 ]] ; then
    family=amd64
fi
case $(uname -s) in
    Darwin)
        shasum="command shasum -a 256"
        ;;
    Linux)
        shasum="command sha256sum"
        ;;
    *)
        # Someday, support installing on Windows.  Service creation could be tricky.
        echo "No idea how to check sha256sums"
        exit 1;;
esac

PATH=$PATH:$GOPATH/bin
which drbundler || go get -u github.com/digitalrebar/provision/cmds/drbundler
which drpcli || go get -u github.com/digitalrebar/provision/cmds/drpcli

. tools/version.sh

for dir in content contrib ; do
    echo -n "$Prepart$MajorV.$MinorV.$PatchV$Extra-$GITHASH" > $dir/._Version.meta
    drbundler $dir drp-community-$dir.yaml
    drpcli contents document drp-community-$dir.yaml > drp-community-$dir.rst
    $shasum drp-community-$dir.yaml > drp-community-$dir.sha256
done

for dir in krib sledgehammer-builder ; do
    echo -n "$Prepart$MajorV.$MinorV.$PatchV$Extra-$GITHASH" > $dir/._Version.meta
    drbundler $dir $dir.yaml
    drpcli contents document $dir.yaml > $dir.rst
    $shasum $dir.yaml > $dir.sha256
done

