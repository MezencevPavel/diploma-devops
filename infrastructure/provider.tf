terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.35"
    }
  }
}

provider "yandex" {
  token     = "x"
  cloud_id  = "x"
  folder_id = "x"
  zone      = "ru-central1-a" # Замените на нужную зону доступности
}
