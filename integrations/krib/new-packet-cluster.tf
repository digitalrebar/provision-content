variable "api_url" { 
  default = "https://127.0.0.1:8092"
}
variable "api_user" { 
  default = "rocketskates"
}
variable "api_password" { 
  default = "r0cketsk8ts"
}
variable "cluster_profile" { 
  default = "krib-auto"
}
variable "cluster_count" { 
  default = 4
}
variable "workflow" { 
  default = "discover-krib-live-cluster"
}

provider "drp" {
  api_user     = "${var.api_user}"
  api_password = "${var.api_password}"
  api_url      = "${var.api_url}"
}

resource "drp_profile" "krib-auto" {
  count = 1
  Name = "${var.cluster_profile}"
  Description = "Terraform Added"
  Params {
  	"etcd/cluster-profile" = "${var.cluster_profile}"
  	"krib/cluster-profile" = "${var.cluster_profile}"
  }
  Meta {
  	icon = "ship"
  	color = "green"
  	render = "kubernetes"
  }
}

resource "drp_workflow" "discover-krib-live-cluster" {
  count = 1
  depends_on = ["drp_profile.krib-auto"]
  Name = "discover-krib-live-cluster"
  Description = "Terraform Added"
  Stages = [
  	"discover", "packet-discover", "ssh-access", "mount-local-disks", "docker-install", 
  	"kubernetes-install", "krib-config", "krib-live-wait"
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
  Name = "krib-${count.index}.terraform.local"
  Params {
  	"machine-plugin" = "packet-ipmi"
  	"packet/plan" ="baremetal_0"
  	"terraform/managed" = "true"
  	"terraform/allocated" = "false"
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
  add_profiles = ["${var.cluster_profile}"]
  decommission_color = "purple"
  decommission_icon = "server"
}

output "admin.conf" {
  value = "drpcli -E ${var.api_url} profiles params ${var.cluster_profile} krib/cluster-admin-conf > admin.conf"
}