output "service_account_id" {
  value = yandex_iam_service_account.sa.id
}

output "bucket_name" {
  value = yandex_storage_bucket.state_bucket.bucket
}