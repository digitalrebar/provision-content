#!/usr/bin/env bash

###
#  Setup tasks for 'make' run - always run this - be sure to make your
#  setup function idempotent.
###

# make sure the TMPDIR exists if used
if [[ -n "$TMPDIR" ]]
then
  [[ ! -d "$TMPDIR" ]] && mkdir -p "$TMPDIR"
fi
