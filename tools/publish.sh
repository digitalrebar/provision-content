#!/usr/bin/env bash

set -e

. tools/version.sh
version="$Prepart$MajorV.$MinorV.$PatchV$Extra-$GITHASH"

DOIT=0
if [[ $version =~ ^v || $version =~ ^tip ]] ; then
    DOIT=1
fi
if [[ $DOIT == 0 ]] ;then
    echo "Not a publishing branch."
    exit 0
fi

[[ $GOPATH ]] || export GOPATH="$HOME/go"
fgrep -q "$GOPATH/bin" <<< "$PATH" || export PATH="$PATH:$GOPATH/bin"

go get -u github.com/stevenroose/remarshal

. tools/version.sh
version="$Prepart$MajorV.$MinorV.$PatchV$Extra-$GITHASH"

TOKEN=R0cketSk8ts
for i in drp-community-content drp-community-contrib krib ; do
    echo "Publishing $i to cloud"
    CONTENT=$i
    remarshal -i $CONTENT.yaml -o $CONTENT.json -if yaml -of json
    curl -f -X PUT -T $CONTENT.json https://qww9e4paf1.execute-api.us-west-2.amazonaws.com/main/support/content/$CONTENT?token=$TOKEN
    echo
done

