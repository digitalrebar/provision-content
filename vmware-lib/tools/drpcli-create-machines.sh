#!/usr/bin/env bash

###
#  Simply creates machines to bind to context runners.  You must have
#  uploaded the runner docker container and installed the content bundle
#  located here.
#
#  These are used to launch workflow contexts without using a real machine.
###

drpcli machines create  '{"Name": "zz-runner-1", "Meta": {"BaseContext": "runner-1"}}'
drpcli machines create  '{"Name": "zz-runner-2", "Meta": {"BaseContext": "runner-2"}}'
