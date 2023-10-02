terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  zone                     = "ru-central1-b"
  service_account_key_file = "${var.service_account_key_file}"
  folder_id                = "${var.folder_id}"
}

resource "yandex_compute_instance_group" "master" {
  name                = "test-ig-master"
  folder_id           = "${var.folder_id}"
  service_account_id  = "${var.service_account_id}"
  deletion_protection = false
  instance_template {
    name = "master-{instance.index}"
    hostname = "master-{instance.index}"
    platform_id = "standard-v3"
    resources {
      memory = 1
      cores  = 2
      core_fraction = 20
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
	type = "network-hdd"
        image_id = "fd830gae25ve4glajdsj"
        size     = 8
      }
    }
    network_interface {
      //network_id = "${yandex_vpc_network.network.id}"
      network_id = "${var.network_id}"
      subnet_ids = ["${yandex_vpc_subnet.subnet.id}"]
      dns_record {
	fqdn = "test-ig."
       }
    }
    metadata = {
      foo      = "bar"
      //ssh-keys = "${file("~/.ssh/id_rsa.pub")}"
      user-data = "${file("~/metadata")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }
  scale_policy {
    fixed_scale {
      size = 2
    }
  }
  allocation_policy {
    zones = ["ru-central1-b"]
  }
  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }
}

resource "yandex_compute_instance_group" "worker" {
  name                = "test-ig-worker"
  folder_id           = "${var.folder_id}"
  service_account_id  = "${var.service_account_id}"
  deletion_protection = false
  instance_template {
    name = "worker-{instance.index}"
    hostname = "worker-{instance.index}"
    platform_id = "standard-v3"
    resources {
      memory = 1
      cores  = 2
      core_fraction = 20
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
	type = "network-hdd"
        image_id = "fd830gae25ve4glajdsj"
        size     = 8
      }
    }
    network_interface {
      //network_id = "${yandex_vpc_network.network.id}"
      network_id = "${var.network_id}"
      subnet_ids = ["${yandex_vpc_subnet.subnet.id}"]
	  dns_record {
	     fqdn = "test-ig."
	  }
    }

    metadata = {
      foo      = "bar"
      //ssh-keys = "${file("~/.ssh/id_rsa.pub")}"
      user-data = "${file("${var.user_data_path}")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    zones = ["ru-central1-b"]
  }

  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }
}

locals {
   masters_ips = {
	 internal = ["${yandex_compute_instance_group.master.instances.*.network_interface.0.ip_address}"]
   }
   workers_ips = {
	 internal = ["${yandex_compute_instance_group.worker.instances.*.network_interface.0.ip_address}"]
   }
}
