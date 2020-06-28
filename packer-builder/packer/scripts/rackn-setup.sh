#!/usr/bin/env bash

LOGDIR="/curtin/packer-logs"
LOGFILE="$LOGDIR/$(basename $0).log"
mkdir -p $LOGDIR
exec > >(tee ${LOGFILE}) 2>&1

echo "Starting image cleanup tasks ... "

echo "Saving '$0' to '$LOGDIR' ... "
cp $0 $LOGDIR/

echo "Starting setup pieces... "
echo ""

echo "Making curtin directory ... "
mkdir /curtin

#apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install cloud-init linux-generic linux-headers-generic

# required because 'grub-pc' does not honor DPKG options,
# it uses UCF system for managing config file
unset UCF_FORCE_CONFFOLD
export UCF_FORCE_CONFFNEW=YES
ucf --purge /boot/grub/menu.lst


PKGS="libdbus-glib linux-headers linux-headers-generic linux-image-generic linux-modules-generic linux-modules-extra-generic thermald cloud-init jq"
export DEBIAN_FRONTEND=noninteractive
apt update
apt -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install $PKGS
apt -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade

OS_TYPE="ubuntu"
DSTAMP=`date +%Y%m%d-%H%M%S`
RS_IMAGE_IDENT=`uuidgen | md5sum | awk ' { print $1 } ' | cut -c 1-10`
RS_BUILDER_DATE="`date`"

echo $(date) > /root/rackn-branding-stamp-$DSTAMP

# branding
for F in issue issue.net
do
    # first pass, backup the issue files, if we re-run this prevents
    # duplicate Rebar messages in the issue files
    BKUP=/etc/$F.rebar.backup
    [[ -r "$BKUP" ]] && cp $BKUP /etc/$F || cp /etc/$F $BKUP

    cat << ISSUE >> /etc/$F

          ######  ###  #####  ### #######   #    #
          #     #  #  #        #     #    #   #  #
          #     #  #  #  ####  #     #   #     # #
          #     #  #  #     #  #     #   # ### # #
          ######  ###  #####  ###    #   #     # #######

             ######  ####### ######     #    ######
             #     # #       #     #  #   #  #     #
             ######  #####   ######  #     # ######
             #   #   #       #     # # ### # #   #
             #    #  ####### ######  #     # #    #

          This image built with Digital Rebar Provision.
                       (c) RackN, Inc.

                IMAGE IDENTITY: ${RS_IMAGE_IDENT}
                    BUILD DATE: ${RS_BUILDER_DATE}
                    BUILD TOOL: packer

ISSUE
done

echo "Setting SSH Banner to use /etc/issue.net"
sed -i.bak "s|#Banner.*$|Banner /etc/issue.net|g" /etc/ssh/sshd_config

exit 0
