#!/bin/bash

export RS_KEY=${RS_KEY:-rocketskates:r0cketsk8ts}

for i in ce-local ce-discovery ce-sledgehammer ;
do
    if ! drpcli bootenvs exists $i ; then
        echo "Installing bootenv: $i"
        drpcli bootenvs install bootenvs/$i.yml
    fi
done

echo "Setting default preferences for discovery"
drpcli prefs set unknownBootEnv ce-discovery defaultBootEnv ce-sledgehammer

echo "You may want to also run:"
echo
echo "  export RS_KEY=${RS_KEY:-rocketskates:r0cketsk8ts}"
echo "  cd comminuty-assets"
echo "  drpcli bootenvs install bootenvs/ce-ubuntu-16.04.yml"
echo "  drpcli bootenvs install bootenvs/ce-centos.7.3.1611.yml"
echo

