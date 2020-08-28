#!/usr/bin/env bash
# upload the post-processor-convert artifact to DRP for image deploy

# our post-processor-convert.sh script should produce the img.xz
# artifact as {{BuildName}}.img.xz - our

function xiterr() { [[ $1 =~ ^[0-9]+$ ]] && { XIT=$1; shift; } || XIT=1; printf "FATAL: $*\n"; exit $XIT; }

CMP=${1}
BLD=${2}
IMG=$CMP/$BLD/${BLD}.img.xz

echo "++ DEBUG:"
echo "CMP set to:"
ls -l $CMP
echo "CMP/BLD set to:"
ls -l $CMP/$BLD
echo "IMG set to:"
ls -l $IMG
echo "-- DEBUG:"

if [[ ! -r "$IMG" ]]
then
  echo "FATAL: Unable to read '$IMG' image file.  Where is my image to upload?"
  echo "       NOT EXITING WITH ERROR CODE - as that will nuke Packer and all"
  echo "       build artifacts"
  exit 0
fi

echo "Starting image upload to DRP Endpoint ... "

if drpcli info check > /dev/null 2>&1
then
  echo "Successfully connected to DRP Endpoint ... "
else
  echo "FATAL: Unable to connect to DRP Entpoint.  You must specify the"
  echo "       DRP Endpoint via the RS_* shell environment variables, like:"
  echo ""
  echo "       export RS_ENDPOINT=https://10.10.10.10:8092"
  echo "       export RS_USERNAME=rocketskates"
  echo "       export RS_PASSWORD=r0cketsk8ts"
  echo ""
  echo "You may also specify them in the $HOME/.drpclirc file."
  echo ""
  echo "NOT EXITING WITH ERROR CODE - as that will nuke Packer and all"
  echo "build artifacts"
  exit 0
fi

echo ""
echo "IF this process fails, the script will still exit 0"
echo ""
echo "Beginning upload of '$IMG' to DRP Files as 'images/${BLD}.img.xz' - be patient"
drpcli files upload "$IMG" as "images/${BLD}.img.xz" || true

exit 0
