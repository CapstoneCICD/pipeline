// Configure the Google Cloud provider
provider "google" {
 credentials = file("capstone-a180a1e8a848.json")
 project     = "capstone-280400"
 region  = "us-central1"
 zone      = "us-central1-a"
}

// A variable for extracting the external ip of the instance
output "ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}
output "hostname" {
  value = google_compute_instance.vm_instance.hostname
}

variable gce_ssh_user0 { default = "Ash" }
variable gce_ssh_pub_key_file0 { default = "id_rsa.pub" }

resource "google_compute_instance" "vm_instance" {
  name         = "capstonevm"
  machine_type = "n1-standard-8"
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ubuntu-1804-bionic-v20200317"
     size = 50GB
    }
  }
  network_interface {
    network       = google_compute_network.vpc_network.self_link
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }
  hostname = "kubernet.capstone.com"
  metadata = {
    ssh-keys = "${var.gce_ssh_user0}:${file(var.gce_ssh_pub_key_file0)}"
    startup-script = "sudo apt-get update -y; sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y; curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -; sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"; sudo apt-get update -y; sudo apt-get install docker-ce docker-ce-cli containerd.io -y; curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x ./minikube && sudo mkdir -p /usr/local/bin/ && sudo mv ./minikube /usr/local/bin/minikube; curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl; sudo apt-get install conntrack; curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | sudo bash"
  }
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
}

resource "google_compute_firewall" "terraformfw" {
  name    = "terraform-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "0-65535"]
  }
}
resource "google_dns_managed_zone" "capstone" {
  name     = "capstone-zone"
  dns_name = "capstone.com."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc_network.self_link
    }
  }
}

resource "google_dns_record_set" "capstonevm" {
  name = "capstonevm.${google_dns_managed_zone.capstone.dns_name}"
  type = "A"
  ttl  = 300
  managed_zone = google_dns_managed_zone.capstone.name
  rrdatas = [google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip]
}

resource "google_dns_record_set" "jenkins" {
  name = "jenkins.${google_dns_managed_zone.capstone.dns_name}"
  type = "A"
  ttl  = 300
  managed_zone = google_dns_managed_zone.capstone.name
  rrdatas = [google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip]
}

resource "google_dns_record_set" "gitlab" {
  name = "gitlab.${google_dns_managed_zone.capstone.dns_name}"
  type = "A"
  ttl  = 300
  managed_zone = google_dns_managed_zone.capstone.name
  rrdatas = [google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip]
}

resource "google_dns_record_set" "dashboard" {
  name = "dashboard.${google_dns_managed_zone.capstone.dns_name}"
  type = "A"
  ttl  = 300
  managed_zone = google_dns_managed_zone.capstone.name
  rrdatas = [google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip]
}
