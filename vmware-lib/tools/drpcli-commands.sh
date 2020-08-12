#!/usr/bin/env bash

# commands to run after building container tar files

[[ -n "$*" ]] && contexts="$*"
#contexts="vcsa-deploy-context:latest govc-context:latest context-runner-context:latest"
contexts=${contexts:-"vcsa-deploy-context:latest govc-context:latest pyvmomi-context:latest"}

# run as:  CONTEXT=0 ./drpcli-commands.sh
# if your contexts are already installed on the DRP Endpoint
SKIP_CONTEXT=${CONTEXT:-1}

set -e

main () {
  for context in $contexts
  do
    name=$(echo $context | sed 's/-context:.*$//g' )
    ver=$(echo $context | sed 's/^.*-context:\(.*\)$/\1/g' )
    # should plumb version tags in here
    image="$name:$ver"

    drpcli files upload dockerfiles/dockerfile-$name.tar as "contexts/docker-context/$image"

    context $name $image

    echo "Installing Container for $context named from $image"
    drpcli plugins runaction docker-context imageUpload         \
      context/image-name ${image}                               \
      context/image-path files/contexts/docker-context/${image}
  done
}

context() {
  local _name=$1
  local _image=$2

  echo "Checking context name '$_name' with image tag '$_image'".

  if drpcli contexts exists $_name > /dev/null 2>&1
  then
    echo "context ('$_name') already exists - doing nothing, hopefully it's right"
    echo "if 'vmware-lib' was installed already, then it was added by that"
  else
    echo "creating context '$_name' from tag '$_image' now ... "

    cat <<EOF | drpcli contexts create -
---
Name: "$_name"
Description: "$_name context using image $_image"
Engine: "docker-context"
Image: "$_image"
Meta:
  icon: "cube"
  color: "blue"
  title: "RackN Content"
EOF

  fi
}

main $*
