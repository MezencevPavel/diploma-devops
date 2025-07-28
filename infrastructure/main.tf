# Определение сети
resource "yandex_vpc_network" "diploma_vpc" {
  name = "diploma-vpc"
}

# Определение подсетей
resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diploma_vpc.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "yandex_vpc_subnet" "subnet_b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diploma_vpc.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

resource "yandex_vpc_subnet" "subnet_d" {
  name           = "subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.diploma_vpc.id
  v4_cidr_blocks = ["10.0.3.0/24"]
}

# Мастер-нода Kubernetes
resource "yandex_compute_instance" "k8s_master" {
  name        = "k8s-master"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8u8ttgp0t4d19ov0k5"  # Убедись, что это правильный образ Ubuntu
      size     = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_a.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:ssh-rsa x
}

# Воркер-ноды Kubernetes
resource "yandex_compute_instance" "k8s_worker" {
  count       = 2
  name        = "k8s-worker-${count.index + 1}"
  platform_id = "standard-v3"
  zone        = element(["ru-central1-b", "ru-central1-d"], count.index)

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd8u8ttgp0t4d19ov0k5"
      size     = 20
    }
  }

  network_interface {
    subnet_id = element([yandex_vpc_subnet.subnet_b.id, yandex_vpc_subnet.subnet_d.id], count.index)
    nat       = true
  }

  scheduling_policy {
    preemptible = false  # Отключаем прерываемость для стабильности
  }

  metadata = {
    ssh-keys = "ubuntu:ssh-rsa x
}