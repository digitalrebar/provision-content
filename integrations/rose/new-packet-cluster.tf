variable "machine_prefix" {
  default = "rose"
}
variable "cluster_profile" {
  default = "rose-auto"
}
variable "cluster_count" {
  default = 1
}
variable "master_count" {
  default = 1
}
variable "workflow" {
  default = "discover-rose-cluster"
}
variable "pool" {
  default = "tf-rose"
}
variable "packet_plan" {
  default = "baremetal_1"
}

resource "drp_profile" "rose-auto" {
  count = 1
  Name = "${var.cluster_profile}"
  Description = "Terraform Added"
  Params {
  	"rose/cluster-profile" = "${var.cluster_profile}"
  }
  Meta {
  	icon = "cloud"
  	color = "green"
  }
}

resource "drp_workflow" "discover-rose-cluster" {
  count = 1
  depends_on = ["drp_profile.rose-auto"]
  Name = "discover-rose-cluster"
  Description = "Terraform Added"
  Stages = [
    "discover", "packet-discover",
    "ubuntu-18.04-install", "drp-agent", "finish-install",
    "ssh-access", "packet-ssh-keys", "rose-config", "complete"
  ]
  Meta {
  	icon = "cloud"
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

resource "drp_machine" "rose-machines" {
  count = "${var.cluster_count}"
  depends_on = ["drp_workflow.discover-rose-cluster", "drp_raw_machine.packet-machines"]
  Description = "KRIB via Terraform"
  Workflow = "${var.workflow}"
  Meta {
  	icon = "map"
  	color = "yellow"
  }
  completion_stage = "complete"
  add_profiles = ["${var.cluster_profile}"]
  decommission_color = "purple"
  decommission_icon = "server"
  pool = "${var.pool}"
}