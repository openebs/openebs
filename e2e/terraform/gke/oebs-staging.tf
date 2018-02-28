/* THIS IS THE TERRAFORM HCL FILE USED TO CREATE THE CLUSTER 
   RESOURCES */

#-------PROVIDER DEF-------#

# The Google Cloud provider is used to interact with Google Cloud services
# It needs to be configured with the proper credentials before it can be used

provider "google" {
  credentials = "${file("${var.credentials}")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

#-------RESOURCE DEF-------#

resource "google_container_cluster" "primary" {
  name = "${var.clustername}"
  zone = "${var.region}"
  initial_node_count = "${var.nodecount}"

  #-------K8s MASTER AUTH DEF-------#
  
  master_auth {
    username = "${var.username}"
    password = "${var.password}"
  }

  #-------COMPUTE NODE DEF-------#
  
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
    machine_type = "${var.machinetype}"
    image_type = "${var.imagetype}"
  }
}

