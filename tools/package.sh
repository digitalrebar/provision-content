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

P=`pwd`
PATH=$PATH:$P/bin
export GO111MODULE=on
which drpcli || (go build -o $P/bin/drpcli github.com/digitalrebar/provision/v4/cmds/drpcli)

version=$(tools/version.sh)

tools/pieces.sh | while read i ; do
    dir=$i
    if [[ $i == "drp-community-content" ]] ; then
        dir="content"
    fi
    if [[ $i == "drp-community-contrib" ]] ; then
        dir="contrib"
    fi

    ldir=$(pwd)
    if [ -d $dir/content ] ; then
        echo "$version" > $dir/content/._Version.meta
        cd $dir/content
        drpcli contents bundle $ldir/$i.yaml
        cd -
    else
        echo "$version" > $dir/._Version.meta
        cd $dir
        drpcli contents bundle $ldir/$i.yaml
        cd -
    fi

    drpcli contents document $i.yaml > $i.rst
    $shasum $i.yaml > $i.sha256
done

