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
  service_account_id  = "aje2qo68d01hqiolpukk"
  deletion_protection = false
  instance_template {
    name = "master-{instance.index}"
	hostname = "master-{instance.index}"
    platform_id = "standard-v3"
    resources {
      memory = 2
      cores  = 4
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
	  network_id = "enp7m02qd9vbo1m3r75q"
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
  folder_id           = "b1g3a65ovr0uv7n30pq7"
  service_account_id  = "aje2qo68d01hqiolpukk"
  deletion_protection = false
  instance_template {
    name = "worker-{instance.index}"
	hostname = "worker-{instance.index}"
    platform_id = "standard-v3"
    resources {
      memory = 2
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
      network_id = "enp7m02qd9vbo1m3r75q"
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
      size = 0
    }
  }

  allocation_policy {
    zones = ["ru-central1-b"]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 1
    max_deleting    = 1
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
