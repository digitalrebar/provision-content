#!/usr/bin/env bash
# Copyright 2015, RackN Inc

# Still helper commands for finding values.
#curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/plans
#curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/operating-systems

#
# We are deploying in packet add this packet instance as a provider
# and force the admin deploy to packet
#
FORCE_PROVIDER=${PROVIDER:-packet}
FORCE_DEPLOY_ADMIN=${DEPLOY_ADMIN:-packet}

# Processes args, inits provider, and validates provider
. tools/wl-lib.sh

# Check to see if device id exists.
if [ "$PXE_DEVICE_ID" != "" ] ; then
    STATE=`curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices/$PXE_DEVICE_ID | jq -r .state`

    if [[ $STATE == null ]] ; then
        echo "Device ID doesn't exist in packet: $PXE_DEVICE_ID"
        exit 1
    fi
    echo "My projects: ${PROVIDER_PACKET_PROJECT_ID} will reuse ${PXE_DEVICE_ID}"
else
    echo "My projects: ${PROVIDER_PACKET_PROJECT_ID} will create ${NODENAME}"

    # Make name for unamed items
    NODENAME=$1
    if [ "$NODENAME" == "" ] ; then
        TSTAMP=`date +%H%M`
        NODENAME="${USER}1-${TSTAMP}"
    else
        shift
    fi

    node="{
  \"facility\": \"ewr1\",
  \"plan\": \"baremetal_0\",
  \"operating_system\": \"custom_ipxe\",
  \"always_pxe\": true,
  \"ipxe_script_url\": \"http://$1:8091/default.ipxe\",
  \"hostname\": \"${NODENAME}\"
}"

    PXE_DEVICE_ID=`curl -H "Content-Type: application/json" -X POST --data "$node" -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices | jq -r .id`
fi

# Wait for device to be up
STATE=`curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices/$PXE_DEVICE_ID | jq -r .state`
while [ "$STATE" != "active" ] ; do
  echo "STATE = $STATE"
  sleep 5
  STATE=`curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices/$PXE_DEVICE_ID | jq -r .state`
done

# We sleep here because while the API says up, not all services have started.
sleep 30

# Get Public IP - HACK - should look it up
PXE_IP=`curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices/$PXE_DEVICE_ID | jq -r .ip_addresses[0].address`
PXE_CIDR=`curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices/$PXE_DEVICE_ID | jq -r .ip_addresses[0].cidr`

