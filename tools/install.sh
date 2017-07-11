#!/usr/bin/env bash

set -e

DEFAULT_DRP_VERSION="tip"

usage() {
        echo
	echo "Usage: $0 [--drp-version=<Version to install>]"
        echo
        echo "Options:"
        echo "  --debug=[true|false] # Enables debug output"
        echo "  --drp-version=<string>  # Version identifier if downloading.  stable, tip, or specific version label."
        echo "                          # Defaults to $DEFAULT_DRP_VERSION"
        echo
	echo "Defaults are: "
	echo "  version = $DEFAULT_DRP_VERSION (instead of v2.9.1003)"
        echo "  debug = false"
        echo
	exit 1
}

DRP_VERSION=$DEFAULT_DRP_VERSION
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

if ! which drpcli 2>/dev/null >/dev/null ; then
    echo "drpcli needs to be in the path."
    exit 1
fi

# Figure out what Linux distro we are running on.
export OS_TYPE= OS_VER= OS_NAME=

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_TYPE=${ID,,}
    OS_VER=${VERSION_ID,,}
elif [[ -f /etc/lsb-release ]]; then
    . /etc/lsb-release
    OS_VER=${DISTRIB_RELEASE,,}
    OS_TYPE=${DISTRIB_ID,,}
elif [[ -f /etc/centos-release || -f /etc/fedora-release || -f /etc/redhat-release ]]; then
    for rel in centos-release fedora-release redhat-release; do
        [[ -f /etc/$rel ]] || continue
        OS_TYPE=${rel%%-*}
        OS_VER="$(egrep -o '[0-9.]+' "/etc/$rel")"
        break
    done

    if [[ ! $OS_TYPE ]]; then
        echo "Cannot determine Linux version we are running on!"
        exit 1
    fi
elif [[ -f /etc/debian_version ]]; then
    OS_TYPE=debian
    OS_VER=$(cat /etc/debian_version)
elif [[ $(uname -s) == Darwin ]] ; then
    OS_TYPE=darwin
    OS_VER=$(sw_vers | grep ProductVersion | awk '{ print $2 }')
fi
OS_NAME="$OS_TYPE-$OS_VER"

case $OS_TYPE in
    centos|redhat|fedora) OS_FAMILY="rhel";;
    debian|ubuntu) OS_FAMILY="debian";;
    *) OS_FAMILY=$OS_TYPE;;
esac

ensure_packages() {
    echo "Ensuring required tools are installed"
    if [[ $OS_FAMILY == darwin ]] ; then
        VER=$(tar -h | grep "bsdtar " | awk '{ print $2 }' | awk -F. '{ print $1 }')
        if [[ $VER != 3 ]] ; then
            echo "Please update tar to greater than 3.0.0"
            echo
            echo "E.g: "
            echo "  brew install libarchive --force"
            echo "  brew link libarchive --force"
            echo
            echo "Close current terminal and open a new terminal"
            echo
            exit 1
        fi
        if ! which 7z &>/dev/null; then
            echo "Must have 7z"
            echo "E.g: brew install p7zip"
            exit 1
        fi
    else
        if ! which bsdtar &>/dev/null; then
            echo "Installing bsdtar"
            if [[ $OS_FAMILY == rhel ]] ; then
                sudo yum install -y bsdtar
            elif [[ $OS_FAMILY == debian ]] ; then
                sudo apt-get install -y bsdtar
            fi
        fi
        if ! which 7z &>/dev/null; then
            echo "Installing 7z"
            if [[ $OS_FAMILY == rhel ]] ; then
                sudo yum install -y epel-release
                sudo yum install -y p7zip
            elif [[ $OS_FAMILY == debian ]] ; then
                sudo apt-get install -y p7zip-full
            fi
        fi
    fi
}

family=386
if [[ $(uname -m) == x86_64 ]] ; then
        family=amd64
fi

case $(uname -s) in
    Darwin)
        tar="command bsdtar"
        shasum="command shasum -a 256";;
    Linux)
        tar="command bsdtar"
        shasum="command sha256sum";;
    *)
        # Someday, support installing on Windows.  Service creation could be tricky.
        echo "No idea how to check sha256sums"
        exit 1;;
esac

ensure_packages

# We aren't a build tree, but are we extracted install yet?
# If not, get the requested version.
if [[ ! -e drp-community-content.sha256 || $force ]] ; then
    echo "Installing Version $DRP_VERSION of Digital Rebar Provision Content"
    curl -sfL -o drp-community-content.zip https://github.com/digitalrebar/provision-content/releases/download/$DRP_VERSION/drp-community-content.zip
    curl -sfL -o drp-community-content.sha256 https://github.com/digitalrebar/provision-content/releases/download/$DRP_VERSION/drp-community-content.sha256

    $shasum -c drp-community-content.sha256
    $tar -xf drp-community-content.zip
fi
$shasum -c sha256sums || exit 1

export RS_KEY=${RS_KEY:-rocketskates:r0cketsk8ts}

for i in ce-local ce-discovery ce-sledgehammer ;
do
    if ! drpcli bootenvs exists $i ; then
        echo "Installing bootenv: $i"
        drpcli bootenvs install bootenvs/$i.yml
    fi
done

echo "Setting default preferences for ce-discovery"
drpcli prefs set unknownBootEnv ce-discovery defaultBootEnv ce-sledgehammer

echo
echo "You may want to also run:"
echo
echo "  export RS_KEY=${RS_KEY:-rocketskates:r0cketsk8ts}"
echo "  drpcli bootenvs install bootenvs/ce-ubuntu-16.04.yml"
echo "  drpcli bootenvs install bootenvs/ce-centos-7.3.1611.yml"
echo

