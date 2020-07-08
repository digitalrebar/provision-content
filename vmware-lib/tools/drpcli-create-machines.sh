#!/usr/bin/env bash

###
#  Simply creates machines to bind to context runners.  You must have
#  uploaded the runner docker container and installed the content bundle
#  located here.
#
#  These are used to launch workflow contexts without using a real machine.
###
MACHINES=${*:-"zz-govc-1 zz-govc-2"}

# prefix w/ 'zz' to sort last - and create 2 for now
for MACHINE in $MACHINES
do
  if drpcli machines exists Name:$MACHINE 2> /dev/null
  then
    echo "Machine '$MACHINE' exists already..."
    CTX="$(drpcli machines show Name:$MACHINE | jq -r '.Meta.BaseContext' 2> /dev/null)"

    if [[ "$CTX" != "govc" ]]
    then
      echo "... AND it does not have a 'Meta.BaseContext' of 'govc' - BAILING BAILING out"
      continue
    else
      RE="(re)"
      echo "Re-creating Machine '$MACHINE' (so base context spins up)."
      drpcli machines destroy Name:$MACHINE
    fi
  fi

  echo "${RE}CREATING machine '$MACHINE' ..."
  drpcli machines create '{"Meta": {"BaseContext": "govc"}, "Name": "'$MACHINE'" }'
  CTX=""
done
