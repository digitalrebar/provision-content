#!/usr/bin/env bash
# RackN Copyright 2019
# Build Manager Demo

set -e

echo "Testing Container Build Process"

files="$(ls *-dockerfile)"

for f in $files; do
	echo "Removing $f from docker images"
	docker rmi digitalrebar-$f || true
	echo "Building $f"
	docker build -f $f -t digitalrebar-$f .
done

echo "Checking Docker Images"
docker images digitalrebar-*

echo "done"