.. Copyright (c) 2020 RackN Inc.
.. Licensed under the Apache License, Version 2.0 (the "License");
.. DigitalRebar Provision documentation under Digital Rebar master license
..

Digital Rebar Provision Content
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. image:: images/drp-content.png

This repository contains the Community Content for use with Digital Rebar
Provision (DRP).  Please see http://rebar.digital for more infomation on DRP.
DRP is a project that is sponsored and maintained by RackN (https://rackn.com/).

If you are interested in learning the basics on creating, maintaining, and
using DRP content, you may want to check out the Colordemo repo, which is
available at:

* https://github.com/digitalrebar/colordemo

The colordemo repo has documentation on managing content, along with some
video demonstrations on how to use it.

This repo contains multiple "content packs", and is also an example of how
multiple content packs can be maintained in a single source code repo.  You
may choose to keep your content packs in separate repos, or not...

Examples of different content packs found here are as follows:

=====================  ============================================================
directory              used for
=====================  ============================================================
content/               main "drp-community-content" pack
task-library/          A library of tasks and helper functions
krib/                  Kubernetes Rebar Integrated Bootstrap content pack
rose/                  Rebar OpenStack Environment - single node master and cluster
sledgehammer-builder/  contains the Sledgehammer Builder content
=====================  ============================================================

The extraneous directories and files (images, tools, .gitignore, etc.) are
not part of the content packs.
