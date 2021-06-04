#!/usr/bin/env bash

subs=(edge-lab
      validation
      burnin
      classify-tests
      classify
      coreos
      dell-support
      dev-library
      drp-prom-mon
      flash
      hardware-tooling
      hpe-support
      image-builder
      kube-lib
      kubespray
      lenovo-support
      supermicro-support
      opsramp
      os-other
      rancheros
      task-library
      terraform
      drp-community-content
      drp-community-contrib
      krib
      sledgehammer-builder
      sledgehammer-builder-centos-7
      flexiflow
      vmware-lib
      chef-bootstrap
      cloud-wrappers
      kvm-simple
      packer-builder
      proxmox)
printf '%s\n' "${subs[@]}"

