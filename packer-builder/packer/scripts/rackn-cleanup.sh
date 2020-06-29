#!/usr/bin/env bash
# RackN Linux Image clean tasks

LOGDIR="/curtin/packer-logs"
LOGFILE="$LOGDIR/$(basename $0).log"
mkdir -p $LOGDIR
exec > >(tee ${LOGFILE}) 2>&1

echo "Starting image cleanup tasks ... "

echo "Saving '$0' to '$LOGDIR' ... "
cp $0 $LOGDIR/

# cleanup
# remove our policy file we created to stop stupid ubuntu packaging from firing up services
rm -f /usr/sbin/policy-rc.d
[[ -r /etc/resolv.conf ]] && > /etc/resolv.conf || true
cd /var/log
find . -type f -name "*log" -exec truncate --size 0  '{}' \;
cd -

apt -y --purge autoremove
apt autoclean
apt clean

history -c

# excise the temporary swapfile
swapoff -v /swapfile || true
rm -f /swapfile
sed -i'' '/^\/swapfile/d' /etc/fstab || true

[[ -d "/root" ]] && > /root/.bash_history || true

exit 0
