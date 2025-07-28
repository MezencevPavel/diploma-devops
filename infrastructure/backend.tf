terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket     = "diploma-tf-state"
    region     = "ru-central1"
    key        = "terraform.tfstate"
    access_key = "x"  # Новый идентификатор ключа
    secret_key = "x"  # Новый секретный ключ
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}