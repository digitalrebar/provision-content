Packer Builder Content
----------------------

The content in this directory provides a Digital Rebar content pack to
setup for, and perform Packer image builds.  These builds are uploaded to
the DRP Endpoint, and ready to be used in the RackN ``image-deploy``
plugin.

This content will provide complete setup of KVM / QEMU and all requirements
on top of Ubunty 18.04 or CentOS 7.  We **STRONGLY** suggest you only attempt
to use Ubuntu 18.04 for now as a base OS for your "gold master" build
platform.  AFter that, you can build images as described below.  A single
workflow exists to setup KVM/QEMU, and build in one step.

This directory contains two primary pieces:

  * ``content`` - the content pack that creates the workflows, params, tasks (etc.) to drive the Packer build automation
  * ``packer`` - Packer JSON definitions for supported Operating Systems, and scripts for customization of the OS images

If this content pack (``packer-builder``) is not yet available in the *Catalog* you
will need to ``git checkout ...`` the source, and bundle/uplooad it to your DRP
Endpoint.  See the directions below.

Currently the Packer pieces are not templatized nor very flexible.  The primary
problem is that Packer itself uses golang templating to custimze it's JSON
descriptor files.  Digital Rebar also uses golang templating for it's templates.
This creates incredibly hard challenges to creating flexible DRP content.

To customize image builds today; you will need to ``git clone`` the ``packer``
directory, customize the JSON and scripts, then use the Params to customize the
Git repo (and potentially) Branch to checkout to build your gold master images
against.

RackN is working on a solution to break apart the Packer JSON structure in to a
much more flexible and customizable solution, but it will take some time to get
things there.


Digital Rebar Content Pack
==========================

The ``content`` directory is a Digital Rebar content pack.  If you do not
have the content (``packer-builder``) available in your catalog, you can bundle
 and install this with the following steps:

  ::

    mkdir -p digitalrebar && cd digitalrebar
    git init
    git remote add origin https://github.com/digitalrebar/provision-content.git
    git fetch origin
    git checkout origin/v4 -- packer-builder
    cd provision-content/packer-builder/content
    ### the dir 'provision-content/packer-builder/packer' contains the Packer build definition info
    drpcli contents bundle ../packer-builder.yaml Version="v20200628-000000"
    drpcli contents upload ../packer-builder.yaml

.. note:: The ``packer`` directory can be used on it's own to build with Packer, but you
          will be left with the task of setting up the build environment and QEMu versions
          that match the Packer requirements.


Using this Content Pack
=======================

Once you have the content pack bundled and uploaded, and if appropriate, the JSON
structures customized and available for checkout by the Workflow, perform the
following to use the content.

.. warning:: It is HIGHLY recommended you do NOT modify the JSON structure for the
             builds your first time through.  Packer JSON and QEMU build arguments
             are EXTREMELY FRAGILE.  Until you have a tested image build, we do not
             recommend customizing things.

  1. Check out the github repo, bundle and upload the content pack in the ``content`` directory
  2. Have a single Bare Metal machine available and dedicated to your gold master builds (this DOES NOT work in virtual machines)
  3. Discover and perform a fresh Ubuntu 18.04 install - KVM / QEMU arguments are very fragile - this has only been tested in that environment
  4. Ensure you have the DRP Agent in place in the installed Ubuntu build machine
  5. Set the Params appropriately to customize (at minimum) the Image to be built (see below)
  6. Run the ``packer-setup-and-build`` workflow

Wait several hours.  Many hours.  Keep waiting.  Then wait some more.  This is Windows.
It reboots a LOT.  It's really really slow.  Plus there are post-processing cleanup (ala
*sysprep* like activities that take a LONG time).  Plus there is image conversion and
compression processes that take a LONG time.

Expect between 3 to 6 hours at a minimum.  Seriously.

At the end of the process, the Build artifacts should be built and uploaded to your DRP
Endpoint in the Files space under ``/files/images/builder/``.


Defining What OS to Build
=========================

See the content Params for more documentation.  At a minimum, you'll need:

  * ``packer-builder/build-image`` - defines what supported Operating System to build

See the Param for the list of supported OSes that have been tested and validated.

Additionally, possibly:

  * ``packer-builder/var-file`` - a small amount of customization can be performed on the Packer JSON by setting this to a JSON structure of variables.json like data - see param for documentation
  * ``packer-builder/git-branch`` - define the Git branch that contains the Packer JSON customizations

Read the Params documentation ... all of them.


Deploying Your Builds
=====================

Like any standard RackN / Digital Rebar image-deploy image, simply specify the Params
that describe your deployable image.  For example:

  * ``image-deploy/image-file: files/images/builder/windows-2016-amd64-libvirt.img.xz``
  * ``image-deploy/image-os: windows``
  * ``image-deploy/image-type: dd-xz``

Your Windows builds should be deployable to Virtual Machines and Physical bare metal systems
both.


Logging In To Your Deployed Images
==================================

For now ... use the following.  This really needs fixed up.  You can change this with use of
the ``packer-builder/var-file`` customization.

  * user:  *vagrant*
  * pass:  *vagrant*

Additionally, the Windows images has OpenSSH server service installed.  NOTE that the OpenSSH
service on Windows is extremely fragile.  It'll freeze up on you regularly.  You have been
warned.


A Note about Hardware Drivers
=============================

Your target hardware or systems for deploying your image to, must be supported by the drivers
in the image.  If the stock Operationg System installation does not support your hardware,
you will need to modify the Packer JSON ``provisioners`` stanzas to inject apprpriate drives.
The installations will be performed at the command line, in the running image as it is built.
See some of the existing PowerShell scripts in use to make image customizations as inspiration.


A Note about Disk Space
=======================

Your build target platform will need gobs of it.  At a minimum, 100 GB of free space for a
Windows image build.  There are multiple copies of the build artifacts that are created and
used through the process, do not rely on just the "disk size" specified in the Packer JSON.

Typically the disk space will be consumed in the root file system of the build system.  If you
need to relocate the build artifacts and working space to a different directory or file system,
see the ``packer-builder/var-file`` for customization of the ``output`` and ``complete``
directories.

