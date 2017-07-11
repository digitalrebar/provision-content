
#
# tools/wl-lib.sh - Provides a library of functions for all workloads
#

# Initialize if it hasn't already
. tools/wl-init.sh

# Prevent recursion
if [[ $WL_LIB_LOADED == true ]] ; then
    return
fi
export WL_LIB_LOADED=true

validate_provider() {
    error=0
    prov=$1

    if [ "$prov" == "" ] ; then
        return 0
    fi

    case $prov in
    packet)
        if [ "$PROVIDER_PACKET_KEY" == "" ] ; then
            echo "You must define PROVIDER_PACKET_KEY (can be added to ~/.dr_info)"
            error=1
        fi
        if [ "$PROVIDER_PACKET_PROJECT_ID" == "" ] ; then
            PROVIDER_PACKET_PROJECT_ID=`curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects | jq -r ".projects[].id"`
            if [ "$PROVIDER_PACKET_PROJECT_ID" == "" ] ; then
                echo "You must define PROVIDER_PACKET_PROJECT_ID (can be added to ~/.dr_info as PROVIDER_PACKET_PROJECT_ID)"
                error=1
            fi
        fi
        ;;
    aws)
        if [ "$PROVIDER_AWS_ACCESS_KEY_ID" == "" ] ; then
            echo "You must define PROVIDER_AWS_ACCESS_KEY_ID (can be added to ~/.dr_info)"
            error=1
        fi
        if [ "$PROVIDER_AWS_SECRET_ACCESS_KEY" == "" ] ; then
            echo "You must define PROVIDER_AWS_SECRET_ACCESS_KEY (can be added to ~/.dr_info)"
            error=1
        fi
        if [ "$PROVIDER_AWS_REGION" == "" ] ; then
            echo "You must define PROVIDER_AWS_REGION (can be added to ~/.dr_info)"
            error=1
        fi

        if [[ $error = 0 ]] ; then
            aws configure set aws_access_key_id $PROVIDER_AWS_ACCESS_KEY_ID
            aws configure set aws_secret_access_key $PROVIDER_AWS_SECRET_ACCESS_KEY
            aws configure set default.region $PROVIDER_AWS_REGION
        fi

        ;;
    debug)
        ;;
    docean)
        # ADD PROVIDER INIT HERE!
        ;;
    google)
        if [ "$PROVIDER_GOOGLE_PROJECT" == "" ] ; then
            echo "You must define PROVIDER_GOOGLE_PROJECT (can be added to ~/.dr_info)"
            error=1
        fi
        if [ "$PROVIDER_GOOGLE_JSON_KEY" == "" ] ; then
            echo "You must define PROVIDER_GOOGLE_JSON_KEY (can be added to ~/.dr_info)"
            error=1
        fi
        ;;
    openstack)
        if [ "$PROVIDER_OS_AUTH_URL" == "" ] ; then
            echo "You must define PROVIDER_OS_AUTH_URL (can be added to ~/.dr_info)"
            error=1
        fi
        ;;
    system|local)
        ;;
    *)
        echo "Unknown Provider or Unset Provider: $prov"
        error=1
        ;;
    esac

    if [[ $error == 1 ]] ; then
        exit 1
    fi
}

bring_up_admin() {

    echo "Bring up admin: provider $DEPLOY_ADMIN"

    case $DEPLOY_ADMIN in
        packet)
            if [ "$DEVICE_ID" != "" ] ; then
                # Get Public IP - HACK - should look it up
                IP=`curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices/$DEVICE_ID | jq -r .ip_addresses[0].address`
                CIDR=`curl -s -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices/$DEVICE_ID | jq -r .ip_addresses[0].cidr`
                export ADMIN_IP="$IP/$CIDR"
            fi
            ;;
        aws)
            if [ "$DEVICE_ID" != "" ] ; then
                # Get Public IP - HACK - should look it up
                IP=`aws ec2 describe-instances --instance-id $DEVICE_ID | jq -r .Reservations[0].Instances[0].PublicIpAddress`
                CIDR=32
            fi
            ;;
        google)
            if [ "$DEVICE_ID" != "" ] ; then
                # Get Public IP - HACK - should look it up
                if [[ $PROVIDER_GOOGLE_ZONE ]] ; then
                    ZONE_NAME="--zone $PROVIDER_GOOGLE_ZONE"
                fi
                if [[ $PROVIDER_GOOGLE_PROJECT ]] ; then
                    PROJECT_ID="--project $PROVIDER_GOOGLE_PROJECT"
                fi
                IP=`gcloud ${PROJECT_ID} compute instances describe $ZONE_NAME $DEVICE_ID --format=json | jq -r .networkInterfaces[0].accessConfigs[0].natIP`
                CIDR=32
            fi
            ;;
        local)
            if [[ $(uname -s) = Darwin ]] ; then
                IP=${DOCKER_HOST%:*}
                IP=${IP##*/}

                SUBNETISH=${IP%.*}
                netmask=$(ifconfig -a | grep $SUBNETISH | awk '{ print $4}')
                CIDR=??
                if [ "$netmask" == "0xffffff00" ] ; then
                  CIDR=24
                fi
                if [ "$netmask" == "0xffff0000" ] ; then
                  CIDR=16
                fi
                export ADMIN_IP="$IP/$CIDR"
            fi
            ;;
    esac

    if [[ $ADMIN_IP ]] ; then
        export RS_ENDPOINT=https://${ADMIN_IP%/*}:8092
        # GREG: Fix this.
        if rebar ping 2>/dev/null >/dev/null ; then
            echo "Admin node at $ADMIN_IP already running."
            ADMIN_ALREADY_UP=true
            return 0
        fi
    fi

    # Must set ADMIN_IP if it isn't set.
    case $DEPLOY_ADMIN in
        packet)
            # Inherits all our vars!!
            . ./tools/run-in-packet.sh "$1"
            ;;
        local|system)
            # Inherits all our vars!!
            . ./tools/run-in-system.sh
            ;;
        *)
            die "bring_up_admin not implemented: $DEPLOY_ADMIN"
            ;;
    esac

    export RS_ENDPOINT=https://${ADMIN_IP%/*}:8092
}

tear_down_admin() {
    case $DEPLOY_ADMIN in
        packet)
            curl -s -X DELETE -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices/$DEVICE_ID
            ;;

        system|local)
            # Inherits all our vars!!
            sleep 60 # Let the deletes drain.  This is lame
            . ./stop-in-system.sh
            ;;
        *)
            die "tear_down_admin not implemented: $DEPLOY_ADMIN"
            ;;
    esac
}

#
# Set up pxe booting packet machine (packet only really)
#
# Arg1 is name of node
# Arg2 is the IP to use for system provider
#
start_machine() {

    case $PROVIDER in
        packet)
            # Inherits all our vars!!
            PXE_DEVICE_ID=""
            . ./tools/pxe-in-packet.sh "$1" "$2"
            ;;
        *)
            die "start_machine not implemented: $PROVIDER"
            ;;
    esac
}

#
# Stop Machine with ID (arg1)
#
stop_machine() {
    case $PROVIDER in
        packet)
            curl -s -X DELETE -H "X-Auth-Token: $PROVIDER_PACKET_KEY" https://api.packet.net/projects/$PROVIDER_PACKET_PROJECT_ID/devices/$1
            ;;

        *)
            die "tear_down_admin not implemented: $PROVIDER"
            ;;
    esac

}

DEPLOY_ADMIN=${DEPLOY_ADMIN:-system}
branch="$(git symbolic-ref -q HEAD)"
branch="${branch##refs/heads/}"
branch="${branch:-latest}"

DR_TAG="${DR_TAG:-${branch}}"

args=()
while (( $# > 0 )); do
    arg="$1"
    arg_key="${arg%%=*}"
    arg_data="${arg#*=}"
    case $arg_key in
        --help|-h)
            usage
            exit 0
            ;;
        --*)
            arg_key="${arg_key#--}"
            arg_key="${arg_key//-/_}"
            arg_key="${arg_key^^}"
            echo "Overriding $arg_key with $arg_data"
            export $arg_key="$arg_data"
            ;;
        *)
            args+=("$arg");;
    esac
    shift
done
set -- "${args[@]}"

if [[ $DEBUG == true ]] ; then
    set -x
fi

validate_tools

# Gets overridden when bringing up the admin node
export RS_ENDPOINT=https://${ADMIN_IP%/*}:8092

validate_provider $DEPLOY_ADMIN
validate_provider $PROVIDER

