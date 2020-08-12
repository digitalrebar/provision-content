#!/usr/bin/env bash
# 

# input arguments:
# 1 - {{user `complete_directory`}} (eg '/scratch/completed')
# 2 - {{.BuildName}} (packer-windows-2019-amd64-libvirt)

CMP=$1
BLD=$2
#complete windows-2019-amd64-libvirt # windows-2019-amd64-libvirt.box
STAMP=$(date +%y%m%d-%H%M%S)

FLOG=findlog-$BLD-$STAMP.log
> $FLOG

flog() {
  printf ">>> %s\n" "$*" | tee -a $FLOG
}

echo "Find log - logging to '$FLOG'"

flog "STAMP - find log starts"
[[ -n "$BLD" ]] && flog "    Build Name: $BLD"
                   flog "          Path: $CMP/$BLD/$BLD.box"
[[ -n "$CMP" ]] && flog " Completed dir: $CMP"
find $CMP/$BLD -exec ls -lh {} \; >> $FLOG

echo "Find log - COMPLETE"
