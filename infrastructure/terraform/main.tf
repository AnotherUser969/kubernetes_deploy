terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  zone                     = "ru-central1-b"
  service_account_key_file = "/home/user/key.json"
  folder_id                = "b1g3a65ovr0uv7n30pq7"
}

resource "yandex_compute_instance_group" "master" {
  name                = "test-ig-master"
  folder_id           = "b1g3a65ovr0uv7n30pq7"
  service_account_id  = "aje2qo68d01hqiolpukk"
  deletion_protection = false
  instance_template {
    name = "master-{instance.index}"
	hostname = "master-{instance.index}"
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
	  network_id = "enp31dqjpjv7hn17a8f2"
      subnet_ids = ["${yandex_vpc_subnet.subnet.id}"]
	  dns_record {
	     fqdn = "test-ig."
	  }
    }
    //labels = {
    //  label1 = "label1-value"
    //  label2 = "label2-value"
    //}
    metadata = {
      foo      = "bar"
      //ssh-keys = "${file("~/.ssh/id_rsa.pub")}"
	  user-data = "${file("~/metadata")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  //variables = {
  //  test_key1 = "test_value1"
  //  test_key2 = "test_value2"
  //}

  scale_policy {
    fixed_scale {
      size = 3
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
	  network_id = "enp31dqjpjv7hn17a8f2"
      subnet_ids = ["${yandex_vpc_subnet.subnet.id}"]
	  dns_record {
	     fqdn = "test-ig."
	  }
    }
    //labels = {
    //  label1 = "label1-value"
    //  label2 = "label2-value"
    //}
    metadata = {
      foo      = "bar"
      //ssh-keys = "${file("~/.ssh/id_rsa.pub")}"
	  user-data = "${file("~/metadata")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  //variables = {
  //  test_key1 = "test_value1"
  //  test_key2 = "test_value2"
  //}

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

//resource "yandex_vpc_network" "network" {
//  name = "yc-auto-network"
//}

resource "yandex_vpc_subnet" "subnet" {
  //count          = "${var.cluster_size > length(var.zones) ? length(var.zones) : var.cluster_size}"
  name           = "yc-auto-subnet"
  zone           = "ru-central1-b"
  //network_id     = "${yandex_vpc_network.network.id}"
  network_id = "enp31dqjpjv7hn17a8f2"
  v4_cidr_blocks = ["192.168.10.0/24"]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "rt" {
  name       = "route-table"
  //network_id = "${var.network_id}"
  network_id = "enp31dqjpjv7hn17a8f2"

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

locals {
   masters_ips = {
	 internal = ["${yandex_compute_instance_group.master.instance_template.*.network_interface.0.ip_address}"]
	 external = ["${yandex_compute_instance_group.master.instance_template.*.network_interface.0.nat_ip_address}"]
   }
   workers_ips = {
	 internal = ["${yandex_compute_instance_group.worker.instance_template.*.network_interface.0.ip_address}"]
	 external = ["${yandex_compute_instance_group.worker.instance_template.*.network_interface.0.nat_ip_address}"]
   }
   prod_subnet_ids = yandex_vpc_subnet.subnet.*.id
}

output "masters_ips" {
  value = "${local.masters_ips}"
}
output "workers_ips" {
  value = "${local.masters_ips}"
}
output "prod_subnet_ids" {
  value = "${local.prod_subnet_ids}"
}
