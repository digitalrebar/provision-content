#!/usr/bin/env bash
# runs all scripts in an opinionated way to get govc context working

set -e

#####
##### This script assumes you have checked out the vmware-lib content
##### which contains setup scripts.  If you have NOT checked out the
##### scripts, start this script with:
#####
#####   DO_GIT=1 tools/do-all.sh
#####
##### YOU MUST run it in the directory where 'tools/' exists.
#####
##### Specify alternate Git Branch if not 'v4' as follows:
#####
#####   DO_GIT=1 BRANCH="foo-git-branch" tools/do-all.sh
#####

function xiterr() { [[ $1 =~ ^[0-9]+$ ]] && { XIT=$1; shift; } || XIT=1; printf "FATAL: $*\n"; exit $XIT; }

drpcli info check > /dev/null || xiterr 1 "'drpcli info check' failed - can't run API commands to DRP endpoint (set RS_ENDPOINT, RS_KEY, etc?)"

do_git() {
  # set appropriate branch in environment
  BRANCH=${BRANCH:-"v4"}
  which git > /dev/null || xiterr "Can't find 'git' in PATH."

  git init
  git remote add origin https://github.com/digitalrebar/provision-content.git
  git fetch origin
  git checkout origin/v4 -- vmware-lib
  cd vmware-lib
}

(( $DO_GIT )) && do_git
[[ ! -d tools ]] && xiterr 1 "Can't find 'tools/' directory.  Did you check out git pieces - see script for help"

# assumes all 'stable' versions...
drpcli catalog item install task-library
drpcli catalog item install docker-context
drpcli catalog item install vmware

if [[ -d "content/" ]]
then
  echo "NOTICE - installing 'vmware-lib' content from 'content/' directory - NOT FROM catalog"
  cd content
  drpcli contents bundle /tmp/vmware-lib.yaml Version=$(date +v%y.%m.%d-%H%M%S)
  drpcli contents upload /tmp/vmware-lib.yaml
  cd ..
else
  drpcli catalog item install vmware-lib
fi

tools/dockerhub-containers.sh
tools/drpcli-commands.sh
tools/drpcli-create-machines.sh
