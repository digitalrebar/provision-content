#!/usr/bin/env bash

set -e

[[ $GOPATH ]] || export GOPATH="$HOME/go"
fgrep -q "$GOPATH/bin" <<< "$PATH" || export PATH="$PATH:$GOPATH/bin"

go get -u github.com/stevenroose/remarshal

version=$(tools/version.sh)

tools/pieces.sh | while read i ; do
    echo "Publishing $i to rebar-catalog"
    remarshal -i $i.yaml -o $i.json -if yaml -of json
    mkdir -p rebar-catalog/$i
    cp $i.json rebar-catalog/$i/$version.json
done

