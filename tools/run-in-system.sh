#!/usr/bin/env bash
# Copyright 2015, RackN Inc

ACCOUNT=${ACCOUNT:-"--user root"}
LOGIN_USER=${LOGIN_USER:-root}
DEPLOY_ADMIN=${DEPLOY_ADMIN:-system}

# Load it up
. tools/wl-lib.sh

if [[ ! $ADMIN_IP ]] ; then
    echo "Please specify an ADMIN IP"
    exit 1
fi

CIDRIP=$ADMIN_IP
IP=${CIDRIP%/*}
CIDR=${CIDRIP##*/}
if [ "$CIDRIP" == "" ] ; then
    echo "Please provide a CIDR IP"
    exit 1
fi

echo "Device IP = $IP/$CIDR"

ssh -i cicd root@$IP apt-get update
ssh -i cicd root@$IP mkdir -p provision
ssh -i cicd root@$IP "cd provision ; curl -fsSL https://raw.githubusercontent.com/digitalrebar/provision/master/tools/install.sh | bash -s -- --nocontent --drp-version=tip install"
ssh -i cicd root@$IP "systemctl daemon-reload && systemctl enable dr-provision"
ssh -i cicd root@$IP "systemctl daemon-reload && systemctl start dr-provision"

