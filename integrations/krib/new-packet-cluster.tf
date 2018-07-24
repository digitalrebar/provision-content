variable "machine_prefix" {
  default = "krib"
}
variable "cluster_profile" {
  default = "krib-auto"
}
variable "cluster_count" {
  default = 4
}
variable "master_count" {
  default = 1
}
variable "workflow" {
  default = "discover-krib-live-cluster"
}
variable "pool" {
  default = "tf-krib"
}
variable "packet_plan" {
  default = "baremetal_0"
}

resource "drp_profile" "krib-auto" {
  count = 1
  Name = "${var.cluster_profile}"
  Description = "Terraform Added"
  Params {
  	"etcd/cluster-profile" = "${var.cluster_profile}"
  	"krib/cluster-profile" = "${var.cluster_profile}"
    "krib/cluster-master-count" = "${var.master_count}"
  }
  Meta {
  	icon = "ship"
  	color = "green"
  	render = "krib"
  }
}

resource "drp_workflow" "discover-krib-live-cluster" {
  count = 1
  depends_on = ["drp_profile.krib-auto"]
  Name = "discover-krib-live-cluster"
  Description = "Terraform Added"
  Stages = [
  	"discover", "packet-discover", "ssh-access", "mount-local-disks",
    "docker-install", "kubernetes-install", "etcd-config", "krib-config", "krib-live-wait"
  ]
  Meta {
  	icon = "ship"
  	color = "green"
  }
}

resource "drp_raw_machine" "packet-machines" {
  count = "${var.cluster_count}"
  Description = "Terraform Added RAW"
  Workflow = "discover"
  Name = "${var.machine_prefix}-${count.index}.terraform.local"
  Params {
  	"machine-plugin" = "packet-ipmi"
  	"packet/plan" ="${var.packet_plan}"
  	"terraform/managed" = "true"
  	"terraform/allocated" = "false"
    "terraform/pool" = "${var.pool}"
  }
  Meta {
  	icon = "map"
  	color = "purple"
  }
}

resource "drp_machine" "krib-machines" {
  count = "${var.cluster_count}"
  depends_on = ["drp_workflow.discover-krib-live-cluster", "drp_raw_machine.packet-machines"]
  Description = "KRIB via Terraform"
  Workflow = "${var.workflow}"
  Meta {
  	icon = "map"
  	color = "yellow"
  }
  completion_stage = "krib-live-wait"
  add_profiles = ["${var.cluster_profile}"]
  decommission_color = "purple"
  decommission_icon = "server"
  pool = "${var.pool}"
}

output "admin.conf" {
  value = "export KUBECONFIG=admin.conf && drpcli profiles get ${var.cluster_profile} params krib/cluster-admin-conf > admin.conf"
}