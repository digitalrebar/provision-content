#!/usr/bin/env bash

# commands to run after building container tar files

contexts="vcsa-deploy-context:latest govc-context:latest"

# run as:  CONTEXT=1 ./drpcli-commands.sh
# if you want to run the context upload to DRP - if they are not already in
# another content pack
SKIP_CONTEXT=${CONTEXT:-0}

set -e

main () {
  for context in $contexts
  do
    name=$(echo $context | sed 's/-context:.*$//g' )
    # should plumb version tags in here
    image="digitalrebar-$name"

    drpcli files upload dockerfile-$name.tar as "contexts/docker-context/$image"

    (( $CONTEXT )) && contexts || echo "Skipping check/create contexts (must already be in your content packs, eh?)."

    echo "Installing Container for $context named from $image"
    drpcli plugins runaction docker-context imageUpload \
      context/image-name ${image} \
      context/image-path files/contexts/docker-context/${image}
  done
}

contexts() {
  if drpcli contexts exists $name > /dev/null 2>&1
  then
    echo "context ('$name') already exists - doing nothing"
  else

    echo ""
    echo "Assuming your RS_ENDPOINT and other env vars are set right to address your DRP Endpoint."
    echo ""

    cat <<EOF | drpcli contexts create -
---
Name: "$name"
Description: "$name context using image $image"
Engine: "docker-context"
Image: "$image"
Meta:
  icon: "cube"
  color: "blue"
  title: "RackN Content"
EOF

  fi
}

main $*
