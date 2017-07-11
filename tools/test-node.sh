#!/usr/bin/env bash
# Copyright 2017, RackN Inc

. ./tools/wl-lib.sh

# root-remote-access template
# access_ssh_root_mode - defaults to without-password

# update-drp-local template
# next_boot_env - defaults to ce-local

# Kick start / Preseed templates
# operating-system-disk - defaults to /dev/sda
# provisioner-default-user - defaults to rocketskates
# provisioner-default-password-hash - defaults to encrypted RocketSkates

error=0

# IP of DRP server
DRP_IP=$1
ADMIN_IP=$1
NodeName=$2

# The name has parameters: Get them
INSTALL_BE=$(echo $NodeName | awk -F- '{ print $1 }')
COMPLETE_BE=$(echo $NodeName | awk -F- '{ print $2 }')
DEFAULT_DISK=$(echo $NodeName | awk -F- '{ print $3 }')
ROOT_SSH_PASSWORD=$(echo $NodeName | awk -F- '{ print $4 }')
CUSTOM_PASSWORD=$(echo $NodeName | awk -F- '{ print $5 }') # fred/fredfred user/pw

InstallBE=bad
if [[ $INSTALL_BE == c ]] ; then
    InstallBE=ce-centos-7.3.1611-install
fi
if [[ $INSTALL_BE == u ]] ; then
    InstallBE=ce-ubuntu-16.04-install
fi
if [[ $InstallBE == bad ]] ; then
        echo "Failed to send a valid bootenv"
        error=1
fi

CompleteBE=bad
if [[ $COMPLETE_BE == l ]] ; then
    CompleteBE=ce-local
fi
if [[ $COMPLETE_BE == s ]] ; then
    CompleteBE=ce-sledgehammer
fi
if [[ $CompleteBE == bad ]] ; then
        echo "Failed to send a valid complete bootenv"
        error=1
fi

# Start machines booting
start_machine $NodeName $DRP_IP
NodePxeId=$PXE_DEVICE_ID
NodeIP=$PXE_IP

NodeUUID=$(ssh root@$DRP_IP "drpcli machines list Address=$NodeIP" | jq -r .[].Uuid)
count=0
while [[ $NodeUUID == "" ]] ; do
        sleep 6
        NodeUUID=$(ssh root@$DRP_IP "drpcli machines list Address=$NodeIP" | jq -r .[].Uuid)
        count=$((count+1))
        if [[ $count -gt 200 ]]; then
                break
        fi
done

# Machine Up??
if [[ $NodeUUID == "" ]] ; then
        echo "Failed to discovery boot into the sledgehammer for $NodeName: $NodeIP"
        error=1
fi

# SSH tests
error=1
count=0
while [[ $error -eq 1 ]] ; do
    sleep 6

    error=0
    if ! ssh -i key1 root@$NodeIP date >/dev/null 2>/dev/null ; then
        echo "Failed to ssh into the sledgehammer for $NodeName as key1: $NodeIP"
        error=1
    fi
    if ! ssh -i key2 root@$NodeIP date >/dev/null 2>/dev/null ; then
        echo "Failed to ssh in the sledgehammer for $NodeName as key2: $NodeIP"
        error=1
    fi
    if [[ $count -gt 200 ]]; then
        break
    fi
done

if [[ $error -ne 0 ]] ; then
        echo "FAILED: TEST"
        exit 1 
fi

ssh root@$DRP_IP "drpcli machines bootenv $NodeUUID $InstallBE"
if [[ $COMPLETE_BE == s ]] ; then
    ssh root@$DRP_IP "drpcli machines addprofile $NodeUUID ce-sledgehammer-final"
fi
if [[ $DEFAULT_DISK == d ]] ; then
    ssh root@$DRP_IP "drpcli machines addprofile $NodeUUID ce-os-disk"
fi
if [[ $ROOT_SSH_PASSWORD == y ]] ; then
    ssh root@$DRP_IP "drpcli machines addprofile $NodeUUID ce-yes-password"
fi
if [[ $CUSTOM_PASSWORD == p ]] ; then
    ssh root@$DRP_IP "drpcli machines addprofile $NodeUUID ce-user-password"
fi

ssh -i key1 root@$NodeIP reboot

count=0
NodeBE=$(ssh root@$DRP_IP "drpcli machines show $NodeUUID" | jq -r .BootEnv)
while [[ $NodeBE != $CompleteBE ]] ; do
        sleep 6
        NodeBE=$(ssh root@$DRP_IP "drpcli machines show $NodeUUID" | jq -r .BootEnv)
        count=$((count+1))
        if [[ $count -gt 200 ]]; then
                break
        fi
done

error=0
# Machine Up??
if [[ $NodeBE != $CompleteBE ]] ; then
        echo "Failed to install $InstallBE into the $CompleteBE for $NodeName: $NodeIP"
        error=1
fi

# SSH tests
error=1
count=0
while [[ $error -eq 1 ]] ; do
    sleep 6

    error=0
    if ! ssh -i key1 root@$NodeIP date >/dev/null 2>/dev/null ; then
        echo "Failed to ssh into the $CompleteBE for $NodeName as key1: $NodeIP"
        error=1
    fi
    if ! ssh -i key2 root@$NodeIP date >/dev/null 2>/dev/null ; then
        echo "Failed to ssh into the $CompleteBE for $NodeName as key2: $NodeIP"
        error=1
    fi
    if [[ $count -gt 200 ]]; then
        break
    fi
done

if [[ $INSTALL_BE == c && $COMPLETE_BE == l ]] ; then
    if [[ $ROOT_SSH_PASSWORD == y ]] ; then
        # Centos Local - root password should be RocketSkates or fredfred if yes password
        if [[ $CUSTOM_PASSWORD == p ]] ; then
            if ! sshpass -pfredfred ssh root@$NodeIP date >/dev/null 2>/dev/null ; then
                    echo "Could not log in as root/fredfred on $NodeName"
                    error=1
            fi
        else
            if ! sshpass -pRocketSkates ssh root@$NodeIP date >/dev/null 2>/dev/null ; then
                    echo "Could not log in as root/RocketSkates on $NodeName"
                    error=1
            fi
        fi
    else
        # Else it should fail
        if sshpass -pRocketSkates ssh root@$NodeIP date ; then
                echo "Successfully logged into $NodeName and should not have"
                error=1
        fi
    fi
elif [[ $INSTALL_BE == u && $COMPLETE_BE == l ]] ; then
    # Ubuntu Local - should be rocketskates/RocketSkates or fred/fredfred if p password
    if [[ $CUSTOM_PASSWORD == p ]] ; then
            if ! sshpass -pfredfred ssh fred@$NodeIP date >/dev/null 2>/dev/null ; then
                    echo "Could not log in as fred/fredfred on $NodeName"
                    error=1
            fi
    else
            if ! sshpass -pRocketSkates ssh rocketskates@$NodeIP date >/dev/null 2>/dev/null ; then
                    echo "Could not log in as rocketskates/RocketSkates on $NodeName"
                    error=1
            fi
    fi

    # Non-keyed root will always fail on ubuntu
    if sshpass -pRocketSkates ssh root@$NodeIP date ; then
        echo "Successfully logged into $NodeName and should not have"
        error=1
    fi
fi

if [[ $error -ne 0 ]] ; then
    echo "FAILED: TEST"
else
    stop_machine $NodePxeId
fi


