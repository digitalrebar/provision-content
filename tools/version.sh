#!/bin/bash

tag_re='([^-]+)-([^-]+)-g([^ ]+)'
semver_re='v([0-9]+).([0-9]+).([0-9]+)'
tip_re='^tip-'


TAG=$(git describe --tags --abbrev=1000)
if [[ $TAG =~ $tag_re ]]; then
    BASE="${BASH_REMATCH[1]}"
    AHEAD="${BASH_REMATCH[2]}"
    GITHASH="${BASH_REMATCH[3]}"
fi

if [[ $BASE == tip || $TAG == tip ]] ; then
    Extra="-tip"
    TAG=$(git describe --tags --abbrev=1000 tip^2 --always)
    if [[ $TAG =~ $tag_re ]]; then
        BASE="${BASH_REMATCH[1]}"
        if [[ $AHEAD ]] ; then
            AHEAD=$(($AHEAD + ${BASH_REMATCH[2]}))
            Extra="$Extra-$(whoami)-dev"
        else
            AHEAD="${BASH_REMATCH[2]}"
        fi
        GITHASH="${GITHASH:-${BASH_REMATCH[3]}}"
    fi
    commit=$(git show $BASE | head -1 | awk '{ print $2 }')
    REAL_VER=$(git tag --points-at $commit | grep -v stable)
    TAG="${REAL_VER}-${AHEAD}-g${GITHASH}"
fi

if [[ $GITHASH == "" ]] ; then
    # Find ref tag
    commit=$(git show $TAG | head -1 | awk '{ print $2 }')
    REAL_VER=$(git tag --points-at $commit | grep -v stable)
    TAG="${TAG//stable/$REAL_VER}-0-g${commit}"
fi

if [[ $TAG =~ $tag_re ]]; then
    BASE="${BASH_REMATCH[1]}"
    AHEAD="${BASH_REMATCH[2]}"
    GITHASH="${BASH_REMATCH[3]}"
fi

if [[ $BASE =~ $semver_re ]] ; then
    MajorV=${BASH_REMATCH[1]}
    MinorV=${BASH_REMATCH[2]}
    PatchV=${BASH_REMATCH[3]}
    Extra="$Extra-$AHEAD"
    Prepart="v"
else
    MajorV="$BASE"
    MinorV=$(whoami)
    PatchV=$AHEAD
    Extra="$Extra-strange"
    Prepart=""
fi

echo "Version = $Prepart$MajorV.$MinorV.$PatchV$Extra-$GITHASH"
