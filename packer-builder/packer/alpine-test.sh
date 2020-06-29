#!/usr/bin/env bash
# fast and dirt virt-install test with Alpine LiveCD

# Usage:
#
#  $0 [ pxe | live ] [ <BRIDGE> ] [ <VNC_CONSOLE> ]
#
#  "live" is default mode - live boot ISO image
#  "pxe" attempts to PXE boot on network - make sure Bridge is right
#  <BRIDGE> defaults to "virbr0" specify alternate
#  <VNC_CONSOLE> defaults to 127.0.0.1:9999 - specify alternate
#
#  BRIDGE is requires if VNC_CONSOLE is specified
#  ordering of options must be as listed in above
#

MODE=${1:-"live"}
NAME="alpine-live-test"
DESC="Alpine Live Test Virtual Machine"
BR=${2:-"virbr0"}
CONS=${3:-"127.0.0.1:9999"}

case $MODE in
  pxe) echo ">>> Setting PXE boot mode for VM."
       OPTS="--pxe --disk /var/lib/libvirt/images/${NAME}.qcow2,size=10 --boot network,cdrom,hd,menu=on"
  ;;
  live|iso) 
       echo ">>> Setting Live (ISO) boot mode for VM."
       OPTS="--livecd --boot cdrom,network,hd,menu=on"
  ;;
  *)    echo "Unknown option '$1' - try 'pxe' or 'live'"
        exit 1
  ;;
esac

echo ">>> Staging Alpine Live ISO if not already available..."
ISO="http://dl-cdn.alpinelinux.org/alpine/v3.12/releases/x86_64/alpine-virt-3.12.0-x86_64.iso"
[[ ! -r /tmp/alpine.iso ]] && wget "$ISO" -O /tmp/alpine.iso

virsh desc ${NAME} > /dev/null 2>&1 && { virsh destroy ${NAME}; virsh undefine ${NAME}; }

echo ">>> Creating '${NAME}' virtual machine"
echo ">>> VNC console listening on $CONS"

set -x
virt-install \
--name=${NAME} \
--metadata name=${NAME},title="${DESC}",description="${DESC}" \
--virt-type kvm \
--noautoconsole \
--ram=2048 --cpu host --hvm --vcpus=2 \
--os-type=linux --os-variant=alpinelinux3.8 \
$OPTS \
--disk /tmp/alpine.iso,device=cdrom,bus=ide \
--network bridge=virbr0,model=e1000 \
--graphics vnc,listen=${CONS},password=foobar --check all=off
set +x

echo ""
echo ">>>"
echo ">>> Firing up 'virsh console' to test it"
echo ">>> user:  root   pass: <none>"
echo ">>>"
echo ""

[[ "$MODE" == "pxe" ]] && { printf ">>> WARNING: is the bridge ('$BR') connected to something useful? \n\n"; sleep 3; }

sleep 3

virsh console ${NAME}

