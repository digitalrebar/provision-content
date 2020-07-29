#!/usr/bin/env bash

###
#  Simply creates machines to bind to context runners.  You must have
#  uploaded the runner docker container and installed the content bundle
#  located here.
#
#  These are used to launch workflow contexts without using a real machine.
###
MACHINES=${*:-"zz-govc-1:govc zz-govc-2:govc zz-pyvmomi-1:pyvmomi zz-pyvmomi-2:pyvmomi"}

# prefix w/ 'zz' to sort last - and create 2 for now
for MACH in $MACHINES
do
  MACHINE=$(echo $MACH | cut -d ":" -f1)
  CONTEXT=$(echo $MACH | cut -d ":" -f2)
  if drpcli machines exists Name:$MACHINE 2> /dev/null
  then
    echo "Machine '$MACHINE' exists already..."
    CTX="$(drpcli machines show Name:$MACHINE | jq -r '.Meta.BaseContext' 2> /dev/null)"

    if [[ "$CTX" != "$CONTEXT" ]]
    then
      echo "... AND it does not have a 'Meta.BaseContext' of '$CONTEXT' - BAILING BAILING out"
      continue
    else
      RE="(re)"
      echo "Re-creating Machine '$MACHINE' (so base context spins up)."
      drpcli machines destroy Name:$MACHINE
    fi
  fi

  echo "${RE}CREATING machine '$MACHINE' ..."
  drpcli machines create '{"Meta": {"BaseContext": "'$CONTEXT'"}, "Name": "'$MACHINE'" }'
  CTX=""
done
