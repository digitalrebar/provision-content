#!/usr/bin/env bash
# post-process a packer vagrant box to raw image for Digital Rebar

###
#  Requires:  bsdtar, qemu-img, md5 | md5sum, uuidgen
###

set -e
xiterr() { [[ $1 =~ ^[0-9]+$ ]] && { XIT=$1; shift; } || XIT=1; printf "FATAL: $*\n"; exit $XIT; }

# example complete build artifact:
# complete/windows-2019-amd64-libvirt/windows-2019-amd64-libvirt.box
BASE="box.img"
CDR=${COMPLETE_DIR:-$1}
BLD=${PACKER_BUILD_NAME:-$2}
BBX="$BLD.box"
CMP="$CDR/$BLD/"
BOX=$BLD
RAW=$BOX.img
QCW="$BOX.qcow2"

[[ "$BOX" =~ .*\.box$ ]] || BOX="${BOX}.box"

which qemu-img > /dev/null 2>&1 || xiterr "no 'qemu-img' found, install and try again."
# thanks Mac OS .... yet again for sucking
which md5sum > /dev/null 2>&1 && MD5=$(which md5sum) || true
which md5 > /dev/null 2>&1 && MD5=$(which md5) || true
IDENT=$(uuidgen | $MD5 | awk ' { print $1 } ' | cut -c 1-10)
which tar > /dev/null 2>&1 && TAR=$(which tar) || true
which bsdtar > /dev/null 2>&1 && TAR=$(which bsdtar) || true
CH=$($TAR --version | awk ' { print $1 } ')
[[ "$CH" != "bsdtar" ]] && xiterr 1 "Require 'bsdtar', install it and try again."

cd $CMP
pwd
# get processors available for number of xz threads
T=$(lscpu | grep "^Core.*per socket:" | awk ' { print $NF } ')
# throttle back to 8 as max if we have a lot available
[[ $T -gt 8 ]] && T=8
# small processor count systems, throttle back to 1 Thread
[[ $T -le 2 ]] && T=1
set -x
$TAR -s "/$BASE/$QCW/" -xzvf $BBX $BASE
qemu-img convert -f qcow2 -O raw $QCW $RAW
xz -T $T -8 -z $RAW
set +x
cd -
echo "Build artifact ready:  $CMP/$BLD/$RAW.xz"
ls -lh $CMP/$RAW.xz"
