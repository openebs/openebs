
provider "google" {
  credentials = "${file("${var.credentials}")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

resource "google_container_cluster" "primary" {
  name = "${var.clustername}"
  zone = "${var.region}"
  initial_node_count = "${var.nodecount}"

  master_auth {
    username = "admin"
    password = "oebsstaging@1234"
  }

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

