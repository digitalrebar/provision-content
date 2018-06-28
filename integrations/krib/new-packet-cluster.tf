variable "api_url" { 
  default = "https://127.0.0.1:8092"
}
variable "api_user" { 
  default = "rocketskates"
}
variable "api_password" { 
  default = "r0cketsk8ts"
}

provider "drp" {
  api_user     = "${var.api_user}"
  api_password = "${var.api_password}"
  api_url      = "${var.api_url}"
}

resource "drp_profile" "krib-auto" {
  count = 1	
  Name = "krib-auto"
  Description = "Terraform Added"
  Params {
  	"etcd/cluster-profile" = "krib-auto"
  	"krib/cluster-profile" = "krib-auto"
  }
  Meta {
  	icon = "ship"
  	color = "blue"
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
  count = 3
  Description = "Terraform Added RAW"
  Workflow = "discover"
  Name = "tfkrib${count.index}"
  Params {
  	"machine-plugin" = "packet-ipmi"
  	"packet/plan" ="baremetal_0"
  	"terraform/managed" = "true"
  	"terraform/allocated" = "false"
  }
  Meta {
  	icon = "rocket"
  	color = "yellow"
  }
}

resource "drp_machine" "krib-machines" {
  count = 3
  depends_on = ["drp_workflow.discover-krib-live-cluster", "drp_raw_machine.packet-machines"]
  Description = "KRIB via TF"
  Workflow = "discover-krib-live-cluster"
  add_profiles = ["krib-auto"]
  Meta {
  	icon = "rocket"
  	color = "green"
  }
}