#!/usr/bin/env bash

# quick and dirty setup of Packer on a system

set -e

############ WARNING
############ WARNING - packer 1.6.0 seems to have changed JSON format - verify
############ WARNING - JSON files by running 1.6.0 version  'packer fix <FILE>.json'
############ WARNING
PKR_VER="1.5.6"
PPW_VER="v0.9.0"
VGT_VER="2.2.9"

osfamily=$(grep "^ID=" /etc/os-release | tr -d '"' | cut -d '=' -f 2)

xiterr() { [[ $1 =~ ^[0-9]+$ ]] && { XIT=$1; shift; } || XIT=1; printf "FATAL: $*\n"; exit $XIT; }

echo "# install bsdtar"

if ! which bsdtar > /dev/null 2>&1
then
  case $osfamily in
    centos|redhat|fedora|oel)
      inst=$(which yum 2> /dev/null)
      [[ -z "$inst" ]] && inst=$(which dnf 2> /dev/null)
      [[ -z "$inst" ]] && xiterr 1 "oops, how to install on '$osfamily'? (it ain't 'yum' or 'dnf')."
      $inst -y makecache
      PKGS="xz"
    ;;
    debian|ubuntu)
      inst=apt
      apt -y update
      PKGS="xz-utils"
    ;;
    *) echo "Ask my masters for help, I don't know what to do for '$osfamily'."; exit 1;;
  esac

  $inst -y install bsdtar git wget curl $PKGS
else
  echo "'bsdtar' found in PATH, continuing"
fi

echo ""
echo "Setup vagrant/packer/packer-provisioner-windows-update-linux:"
echo ""
cd /usr/local/bin/
curl -s https://releases.hashicorp.com/packer/${PKR_VER}/packer_${PKR_VER}_linux_amd64.zip | zcat > packer && chmod 755 packer
curl -fsSL https://github.com/rgl/packer-provisioner-windows-update/releases/download/${PPW_VER}/packer-provisioner-windows-update-linux.tgz | tar -xzvf - && chmod 755  packer-provisioner-windows-update
curl -fsSL https://releases.hashicorp.com/vagrant/${VGT_VER}/vagrant_${VGT_VER}_linux_amd64.zip | zcat > vagrant && chmod 755 vagrant

echo "Sanity check the binaries"
./packer --version
file ./packer-provisioner-windows-update
./vagrant --version

exit 0
