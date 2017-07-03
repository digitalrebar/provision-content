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


tmpdir="$(mktemp -d /tmp/rs-bundle-XXXXXXXX)"
cp -a bootenvs "$tmpdir"
cp -a profiles "$tmpdir"
cp -a templates "$tmpdir"
(
    cd "$tmpdir"
    $shasum $(find . -type f) >sha256sums
    zip -p -r drp-community-content.zip *
)

cp "$tmpdir/drp-community-content.zip" .
$shasum drp-community-content.zip > drp-community-content.sha256
rm -rf "$tmpdir"
