#!/usr/bin/env bash
# Copyright 2017, RackN Inc

set -x

export TRAVIS_JOB_NUMBER=${TRAVIS_JOB_NUMBER:-localtest}

# Still helper commands for finding values.
#curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/plans
#curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/operating-systems

. tools/wl-lib.sh

if [ ! -e drp-community-content.yaml ] ; then
    echo "Missing yaml file to test.  Run tools/package.sh"
    exit 1
fi

bring_up_admin "drp-${TRAVIS_JOB_NUMBER//./-}"

# Install content - we are testing
ssh -i cicd root@$IP service dr-provision stop
ssh -i cicd root@$IP mkdir -p /usr/share/dr-provision
scp -i cicd -r drp-community-content.yaml root@$IP:/usr/share/dr-provision/default.yaml
ssh -i cicd root@$IP service dr-provision start

# Wait for DRP to start.
sleep 10

# Pull ISO
ssh -i cicd root@$IP "drpcli bootenvs uploadiso ce-ubuntu-16.04-install"
ssh -i cicd root@$IP "drpcli bootenvs uploadiso ce-centos-7.3.1611-install"
ssh -i cicd root@$IP "drpcli bootenvs uploadiso ce-sledgehammer"
ssh -i cicd root@$IP "drpcli prefs set defaultBootEnv ce-sledgehammer"
ssh -i cicd root@$IP "drpcli prefs set unknownBootEnv ce-discovery"

# Packet console parameter
ssh -i cicd root@$IP "drpcli profiles set global param kernel-console to 'console=ttyS1,115200'"

# access_keys - default to nothing
rm -rf key1* key2*
ssh-keygen -t rsa -f key1 -N ""
ssh-keygen -t rsa -f key2 -N ""
ssh -i cicd root@$IP "drpcli profiles set global param access-keys to '{ \"key1\": \"$(cat key1.pub)\", \"key2\": \"$(cat key2.pub)\" }'"


# Testing profiles
ssh -i cicd root@$IP "drpcli profiles create '{ \"Name\": \"ce-sledgehammer-final\", \"Params\": { \"next-boot-env\": \"ce-sledgehammer\" } }'"
ssh -i cicd root@$IP "drpcli profiles create '{ \"Name\": \"ce-user-password\", \"Params\": { \"provisioner-default-user\": \"fred\", \"provisioner-default-password-hash\": \"\$6\$drprocksdrprocks\$KLQOIAGEXNmHvtCRFIhlWR3gW1LfHtAW6ngPNW0v6q/wBKJmbYQLDWF26nL3bDbYkdyL0jgSl/T0e/yGEpDmn/\", \"access-ssh-root-mode\": \"yes\" } }'"
ssh -i cicd root@$IP "drpcli profiles create '{ \"Name\": \"ce-yes-password\", \"Params\": { \"access-ssh-root-mode\": \"yes\" } }'"
ssh -i cicd root@$IP "drpcli profiles create '{ \"Name\": \"ce-os-disk\", \"Params\": { \"operating-system-disk\": \"sda\" } }'"

mkdir -p logs
rm -rf logs/*

# Hostnames are: [uc][ls][nd][wy][qp]
# Valid combos and double up testing:
#  u = ubuntu
#  c = centos
#  l = local end
#  s = sledge hammer end
#  n = default disk
#  d = os disk
#  w = without-password
#  y = yes password
#  p = default password
#  q = Custom password user.
#
export WL_INIT_LOADED=false
export WL_LIB_LOADED=false
for i in u-s-d-w-p u-s-d-y-p u-l-n-w-p u-l-n-y-q u-l-d-y-p c-s-d-w-p c-s-d-y-p c-l-n-w-p c-l-n-y-q c-l-d-y-p ; do
    tools/test-node.sh $IP $i 2> logs/$i.se.log > logs/$i.so.log &
done

COUNT=6
while [[ $COUNT -ne 0 ]]
do
    # Export logs to the admin node for now.
    scp -i cicd -r logs root@$IP:

    sleep 10
    COUNT=`ps auxwww | grep test-node.sh | grep -v grep | wc -l`
    echo "Remaining: $COUNT"
done

# Check logs for FAIL
error=0
if grep -q "FAILED: TEST" logs/* ; then
    error=1
else
    tear_down_admin 
fi

exit $error
