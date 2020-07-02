#!/usr/bin/env bash

###
#  Simply creates machines to bind to context runners.  You must have
#  uploaded the runner docker container and installed the content bundle
#  located here.
#
#  These are used to launch workflow contexts without using a real machine.
###

# prefix w/ 'zz' to sort last - and create 2 for now
drpcli machines create '{"Meta": {"BaseContext": "govc"}, "Name": "zz-govc-1" }'
drpcli machines create '{"Meta": {"BaseContext": "govc"}, "Name": "zz-govc-2" }'
