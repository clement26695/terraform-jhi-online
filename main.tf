// Remote state
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "JHipster"
    workspaces {
      name = "jhipster-online"
    }
  }
}

// Google provider
provider "google" {
  credentials = "${file("/Users/clementdessoude/Documents/Dev/ippon/terraform/jhipster-online-test-75a30c31d56d.json")}"
  project     = "jhipster-online-test"
  region      = "us-west1"
}

// Google Compute Engine
resource "google_compute_address" "static" {
  name = "ipv4-address"
}

module "gce-container" {
  source = "github.com/terraform-google-modules/terraform-google-container-vm"

  container = {
    image = "docker.io/cdessoude/jhipster-online:1.0.0"
    env = [
      {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "prod,swagger"
      },
      {
        name  = "SPRING_DATASOURCE_URL"
        value = "jdbc:mysql://${google_sql_database_instance.instance.ip_address.0.ip_address}:3306/jhipster-online?useUnicode=true&characterEncoding=utf8&useSSL=false&useLegacyDatetimeCode=false&serverTimezone=UTC"
      },
      {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = var.database_username
      },
      {
        name  = "SPRING_DATASOURCE_PASSWORD"
        value = var.database_password
      }
    ]
  }
}

resource "google_compute_instance" "default" {
  name         = "jhipster-online-test-vm-${random_id.db_name_suffix.hex}"
  machine_type = "f1-micro"
  zone         = "us-west1-a"

  boot_disk {
    initialize_params {
      image = module.gce-container.source_image
    }
  }

  metadata = {
    gce-container-declaration = module.gce-container.metadata_value
    ssh-keys                  = "cdessoude:${file(".ssh/id_rsa.pub")}"
  }

  network_interface {
    network = "${google_compute_network.default.name}"

    access_config {
      nat_ip = "${google_compute_address.static.address}"
    }
  }
}

// Database
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database" "database" {
  name     = "jhipster-online"
  instance = "${google_sql_database_instance.instance.name}"
}

resource "google_sql_database_instance" "instance" {
  name   = "jhipster-mysql-instance-${random_id.db_name_suffix.hex}"
  region = "us-central"
  settings {
    tier = "D0"
    ip_configuration {
      ipv4_enabled = "true"
      authorized_networks {
        value = var.dev_ip
        name  = "Dev"
      }
      authorized_networks {
        value = google_compute_address.static.address
        name  = "GCE"
      }
    }
  }
}

resource "google_sql_user" "users" {
  name     = var.database_username
  instance = "${google_sql_database_instance.instance.name}"
  password = var.database_password
}

// Firewall
resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = "${google_compute_network.default.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "443"]
  }

  # allow {
  #   protocol = "ssh"
  #   ports    = ["22"]
  # }
}

resource "google_compute_network" "default" {
  name = "test-network"
}
