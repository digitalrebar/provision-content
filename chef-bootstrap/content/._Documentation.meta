# chef-bootstrap

## Quickstart

Clone the `chef-bootstrap-example` profile, edit the profile parameters to your case, and add the cloned profile to the 
machine you want to bootstrap.

Add the `chef-bootstrap` workflow to bootstrap your machine to your chef server and organization.

The node name defaults to the machine's fqdn (`hostname -f` result)

## Workflows

### chef-bootstrap

Simple showcase for bootstraping a node into a Chef server's organization

## Stages
### chef-bootstrap

  The actual bootstrap stage

### chef-bootstrap-complete

  Decorator stage to show workflow completion

### chef-bootstrap-start

  Decorator stage to show workflow start

## Tasks
### chef-bootstrap-configure

  This task takes care of configuring client.rb file, setting up temporary validation/admin credentials and other 
  optional settings, like encrypted data bag secret, or first run user-defined json.

### chef-bootstrap-install

  This task takes care of installing the chef-client software.

### chef-bootstrap-join

  This task takes care of creating a client in the Chef server, and executing a chef-client run, which will register a
  new node.

## Templates
### chef-bootstrap-configure.sh
### chef-bootstrap-install.sh
### chef-bootstrap-join.sh

## Parameters

<!-- below should be a description, but I don't like to mix html with markdown, yes ironic -->

#### chef-bootstrap/chef_server
 - The address or hostname corresponding to the Chef Server

#### chef-bootstrap/encrypted_data_bag_secret
 - The Chef encrypted data bag secret

#### chef-bootstrap/environment
 - The Environment to add the node to, incompatible with PolicyFiles

#### chef-bootstrap/first_boot
 - A JSON formated string that defines the first chef run of a machine

#### chef-bootstrap/named_runlist
 - A named run_list defined in a policy this node will belong to

#### chef-bootstrap/node_name
 - The Chef identifier for the registering node/client

#### chef-bootstrap/organization
 - The Chef organization this node belongs to

#### chef-bootstrap/policy_group
 - The Policy Group this node belongs to

#### chef-bootstrap/policy_name
 - The Policy Name to be applied to the node

#### chef-bootstrap.recreate_client
 - If True we delete client and node if they already exist on the Chef Server

#### chef-bootstrap/user
 - The user to authenticate as when bootstrapping the Chef node

#### chef-bootstrap/user_key
 - The Chef user private key

## Inject into DRP endpoint

First create the bundle:

```shell script
chef-bootstrap$ cd content
chef-bootstrap/content$ drpcli contents bundle ../chef-bootstrap.yaml
```

then upload the bundle 

```shell script
chef-bootstrap/content$ cd ..
chef-bootstrap$ drpcli -E https://<DRP ENPOINT URL>:8092 -U <ADMIN USER> -P <ADMIN PASSWORD> contents create chef-bootstrap.yaml 
```

or update if it already exists

```shell script
chef-bootstrap$ drpcli -E https://<DRP ENPOINT URL>:8092 -U <ADMIN USER> -P <ADMIN PASSWORD> contents update chef-bootstrap chef-bootstrap.yaml 
```