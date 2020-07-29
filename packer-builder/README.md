Packer Builder Content
~~~~~~~~~~~~~~~~~~~~~~

The content in this directory provides a Digital Rebar content pack to
setup for, and perform Packer image builds.


Digital Rebar Content Pack
--------------------------

The ``content`` directory is a Digital Rebar content pack.  If you do not
have the content available in your catalog, you can bundle and install this
with the following steps:

  ::

    git clone https://github.com/digitalrebar/provision-content.git
    cd provision-content/packer-builder/content
    drpcli contents bundle ../packer-builder.yaml Version="v20200628-000000"
    drpcli contents upload ../packer-builder.yaml


Get Only the Packer Build Pieces
--------------------------------

If you do not want to execute the image builds with the use of the Digital Rebar
automation workflow, you can check out just the Packer build pieces independently.

To do so, perform the following *git* commands:

  ::

    git init
    git remote add origin https://github.com/digitalrebar/provision-content.git
    git fetch origin
    git checkout origin/v4 -- packer-builder/packer

This will check out the Packer build artifacts in to ``packer-builder/packer/``
in your current working directory.


For More Documentation
----------------------

More complete documentation for the Digital Rebar content pack and automation can
be found in the usual documentation location - which is:

  * https://provision.readthedocs.io/
