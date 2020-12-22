#!/bin/bash
# Updates all content packs pending merge

set -e

changed="$1 $(git status -s | awk 'match($0, /\sM\s([a-z,\-]+)/, arr) { print arr[1] }')"
echo "Bundle and Update to $RS_ENDPOINT ..."

for b in $changed; do
    if [[ ! -f "$b/$b.yaml" ]]; then
        cd $b
        echo "  updating $b/$b.yaml"
        drpcli contents bundle $b.yaml > /dev/null
        drpcli contents upload $b.yaml > /dev/null
        cd ..
    fi
done

for b in $changed; do
    rm -f $b/$b.yaml
done

echo "Done"