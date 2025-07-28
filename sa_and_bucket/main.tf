resource "yandex_iam_service_account" "sa" {
  name        = "diploma-sa"
  description = "Service account for Terraform"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  members   = ["serviceAccount:${yandex_iam_service_account.sa.id}"]
}

resource "yandex_resourcemanager_folder_iam_binding" "storage_admin" {
  folder_id = var.yc_folder_id
  role      = "storage.admin"
  members   = ["serviceAccount:${yandex_iam_service_account.sa.id}"]
}

resource "yandex_storage_bucket" "state_bucket" {
  bucket     = "diploma-tf-state"
  acl        = "private"
  folder_id  = var.yc_folder_id  # Явно указываем folder_id
  depends_on = [yandex_resourcemanager_folder_iam_binding.storage_admin]
}