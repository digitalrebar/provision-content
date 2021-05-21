#!/usr/bin/env bash
# RackN Copyright 2021
# Upload Local Cloud Credentials

export PATH=$PATH:$PWD

echo "RackN Digital Rebar Cloud Credentials Uploader (v1.1 May 2021)"
echo "=============================================================="
echo "0/3 Checking Cloudwapper Prereqs"

if ! which drpcli > /dev/null ; then
  echo "MISSING: drpcli required!"
  exit 1
else
  echo "  verified drpcli is installed"
fi

if ! which jq > /dev/null ; then
  echo "  adding jq via drpcli as soft link in current directory"
  ln -s $(which drpcli) jq >/dev/null
else
  echo "  verified jq is installed"
fi

if ! drpcli info get > /dev/null ; then
  echo "MISSING: set RS_ENDPOINT and RS_KEY!"
  exit 1
else
  drpid=$(drpcli info get | jq -r .id | sed 's/:/-/g')
  echo "  verified drp $drpid access and credentials"
fi

ENDPOINTS="$drpid $(drpcli endpoints list | jq -r .[].Id)"
echo
echo "FOUND ENDPOINTS: $ENDPOINTS"
echo

for s in $ENDPOINTS; do

  echo "1/3 Setting up Endpoints: $s"
  ep="-u $s"
  if [[ "$s" == "$drpid" ]]; then
    ep=""
  fi

  if ! drpcli $ep contents exists rackn-license > /dev/null 2>/dev/null ; then
    if [[ -f rackn-license.json ]] ; then
      echo "  found local copy of rackn-license, uploading"
      drpcli $ep contents upload rackn-license.json > /dev/null 2>/dev/null
    else
      echo "MISSING: rackn-license.  Install using UX"
      exit 1
    fi
  else
    echo "  verified rackn-license is available"
  fi

  if ! drpcli $ep contents exists cloud-wrappers > /dev/null 2>/dev/null ; then
    echo "  INSTALLING: missing cloud-wrappers content pack"
    drpcli $ep catalog item install cloud-wrappers --version=tip >/dev/null
  else
    echo "  verified cloud-wrappers is available"
  fi

  if drpcli $ep machines exists Name:$s > /dev/null 2>/dev/null ; then
    echo "  Self-Runner Detected - using bootstrap-advanced to install docker-context"
    drpcli $ep machines update Name:$s '{"Locked":false}' > /dev/null
    drpcli $ep machines workflow Name:$s "" > /dev/null
    drpcli $ep machines workflow Name:$s bootstrap-advanced > /dev/null
    drpcli $ep machines run Name:$s > /dev/null
    echo "    you can monitor progress via the UX"
    echo "    waiting up to 120 seconds for workflow to complete..."
    drpcli $ep machines wait Name:$s WorkflowComplete true 120
  else
    if ! drpcli $ep plugins exists docker-context > /dev/null 2>/dev/null ; then
      echo "  INSTALLING: missing docker-context plugin, installing"
      drpcli $ep catalog item install docker-context --version=tip >/dev/null
    else
      echo "  verified docker-context is available.  Restarting"
      drpcli $ep plugins runaction docker-context restartProvider >/dev/null
    fi
    echo "  Checking for Context Images"
    contexts=$(drpcli $ep contexts list | jq -r .[].Name)
    for c in $contexts; do
      o=$(drpcli $ep contexts show $c)
      image=$(jq -r .Image <<< "$o")
      source=$(jq -r .Meta.Imagepull <<< "$o")
      if [[ $source ]] ; then
        if drpcli $ep plugins runaction docker-context imageExists context/image-name ${image} >/dev/null 2>/dev/null ; then
          echo "    image file for $c exists, no action"
        else
          echo "    INSTALLING: Image file for $c missing (may be slow....)"
          drpcli $ep files upload "$source" as "contexts/docker-context/$image" >/dev/null
          drpcli $ep plugins runaction docker-context imageUpload \
            context/image-name ${c} \
            context/image-path files/contexts/docker-context/${image}
        fi
      else
        echo "  WARNING: no Imagepull defined for $c"
      fi
    done
  fi

  echo "2/3 Building Cloudwapper Profiles for $s"

  if [[ -f ~/.aws/credentials ]]; then
    if drpcli $ep profiles exists aws > /dev/null 2>/dev/null ; then
      echo "  Skipping AWS, already exists"
    else
      echo "  Adding AWS profile for cloud-wrap"
      drpcli $ep profiles create - >/dev/null << EOF
---
Name: "aws"
Description: "AWS Credentials"
Params:
  "cloud/provider": "aws"
  "rsa/key-user": "ec2-user"
Meta:
  color: "blue"
  icon: "amazon"
  title: "generated"
EOF
      drpcli $ep profiles add aws param "aws/secret-key" to "$(awk '/aws_secret_access_key/{ print $3}' ~/.aws/credentials)" > /dev/null
      drpcli $ep profiles add aws param "aws/access-key-id" to "$(awk '/aws_access_key_id/{ print $3}' ~/.aws/credentials)" > /dev/null
    fi
  else
    echo "  no AWS credentials, skipping"
  fi

  # upload aws & google credentials
  google=$(ls ~/.gconf/desktop/*.json || echo "none")
  if [[ -f $google ]]; then
    if drpcli $ep profiles exists google > /dev/null 2>/dev/null ; then
      echo "  Skipping Google, already exists"
    else
        echo "  Adding Google profile for cloud-wrap"
        gconf=$(cat $google) > /dev/null
        drpcli $ep profiles create - >/dev/null << EOF
{
  "Name": "google",
  "Description": "GCE Credentials",
  "Params": {
    "cloud/provider": "google",
    "google/project-id": "$(jq -r .project_id <<< "$gconf")",
    "rsa/key-user": "rob",
  },
  "Meta": {
    "color": "blue",
    "icon": "google",
    "title": "generated"
  }
}
EOF
      drpcli $ep profiles add google param "google/credential" to - >/dev/null <<< $(cat $google)
    fi
  else
    echo "  no Google credentials, skipping"
  fi

  if [[ $DO_TOKEN ]]; then
    if drpcli $ep profiles exists digitalocean > /dev/null 2>/dev/null ; then
      echo "  Skipping Digital Ocean, already exists"
    else
      echo "  upload digital ocean credentials"
        drpcli $ep profiles create - >/dev/null << EOF
---
Name: "digitalocean"
Description: "Digital Ocean Credentials"
Params:
  "cloud/provider": "digitalocean"
Meta:
  color: "green"
  icon: "digital ocean"
  title: "generated"
EOF
      drpcli $ep profiles add digitalocean param "digitalocean/token" to "$DO_TOKEN" > /dev/null
    fi
  else
    echo "  Skipping Digital Ocean, no token DO_TOKEN"
  fi

  if [[ $LINODE_TOKEN ]]; then
    if drpcli $ep profiles exists linode > /dev/null 2>/dev/null ; then
      echo "  Skipping Linode, already exists"
    else
      echo "  upload linode credentials"
      drpcli $ep profiles create - >/dev/null << EOF
---
Name: "linode"
Description: "Linode Credentials"
Params:
  "cloud/provider": "linode"
  "linode/instance-image": "linode/centos8"
  "linode/instance-type": "g6-standard-2"
Meta:
  color: "blue"
  icon: "linode"
  title: "generated"
EOF
      drpcli $ep profiles add linode param "linode/root-password" to "r0cketsk8ts" > /dev/null
      drpcli $ep profiles add linode param "linode/token" to "$LINODE_TOKEN" > /dev/null
    fi
  else
    echo "  Skipping Linode, no token LINODE_TOKEN"
  fi

  if [[ -f ~/.pnap/config.yaml ]]; then
    if drpcli $ep profiles exists pnap > /dev/null 2>/dev/null ; then
      echo "  Skipping Phoenix NAP, already exists"
    else
      echo "  upload Phoenix NAP (pnap) credentials"
      drpcli $ep profiles create - >/dev/null << EOF
---
Name: "pnap"
Description: "Phoenix NAP Credentials"
Params:
  "cloud/provider": "pnap"
  "rsa/key-user": "ubuntu"
  "pnap/client-id": "$(cat ~/.pnap/config.yaml | grep "clientId:" | awk '{split($0,a,": "); print a[2]}')"
Meta:
  color: "blue"
  icon: "cloud"
  title: "generated"
EOF
      drpcli $ep profiles add pnap param "pnap/client-secret" to "$(cat ~/.pnap/config.yaml | grep "clientSecret:" | awk '{split($0,a,": "); print a[2]}')" > /dev/null
    fi
  else
    echo "  Skipping Phoenix NAP, no ~/.pnap/config.yaml"
  fi


  if which az > /dev/null ; then
    if drpcli $ep profiles exists azure > /dev/null 2>/dev/null ; then
      echo "  Skipping Azure, already exists"
    else
      if az vm list > /dev/null ; then
        echo "  Azure login verified"
      else
        if ! az login > /dev/null ; then
          echo "  WARNING: no azure credentials!"
        fi
      fi
      if az account list > /dev/null ; then
        # see https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html
        azure_subscription_id=$(az account list | jq -r '.[0].id')
        azure_resource=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$azure_subscription_id")
        drpcli $ep profiles create - >/dev/null << EOF
{
  "Name": "azure",
  "Description": "Azure Credentials",
  "Params": {
    "cloud/provider": "azure",
    "azure/subscription_id": "$azure_subscription_id",
    "azure/appId": "$(jq -r .appId <<< "$azure_resource")",
    "azure/tenant": "$(jq -r .tenant <<< "$azure_resource")",
    "rsa/key-user": "rob"
  },
  "Meta": {
    "color": "blue",
    "icon": "microsoft",
    "title": "generated"
  }
}
EOF
        drpcli $ep profiles add azure param "azure/password" to "$(jq -r .password <<< "$azure_resource")" > /dev/null
      else
        echo "  WARNING: az account list failed"
      fi
    fi
  else
    echo "  Skipping Azure, no az cli installed"
  fi

  echo "3/3 Touch cloud-wrappers to ensure reload for $s"
  cw=$(drpcli $ep contents show cloud-wrappers)
  drpcli $ep contents update cloud-wrappers - <<< "$cw" > /dev/null

  echo "Done with $s"
  echo

done

echo "=============================================================="
echo "All Done!"