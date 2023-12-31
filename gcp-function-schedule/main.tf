terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
data "archive_file" "source" {
  output_path = "${path.module}/${var.function_name}.zip"
  type        = "zip"
  source_dir = var.function_path
}

resource "google_storage_bucket" "function_bucket" {
 location = var.region
  name = "${var.project_id}-${var.function_name}"
}

resource "google_storage_bucket_object" "zip" {
  name = "${data.archive_file.source.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.source.output_path
}

resource "google_service_account" "sa" {
  account_id = "${var.function_name}-sa"
}

resource "google_project_iam_member" "sa-roles" {
  project = var.project_id
  for_each = toset(var.roles)
  role = each.key
  member = "serviceAccount:${google_service_account.sa.email}"
}

module "incoming_messages_topic" {
  count = var.new_pubsub_topic != null ? 1 : 0
  source  = "terraform-google-modules/pubsub/google"
  topic      = var.new_pubsub_topic
  project_id = var.project_id
}

resource "google_cloudfunctions2_function" "function" {
  name = var.function_name
  location = var.region

  build_config {
    runtime = var.runtime
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.zip.name
      }
    }
  }

  service_config {
    min_instance_count = var.min_instance_count
    max_instance_count = var.max_instance_count
    timeout_seconds = var.timeout_seconds
    available_memory = var.available_memory
    all_traffic_on_latest_revision = var.all_traffic_on_latest_revision
    environment_variables = var.environment_variables
    ingress_settings = var.ingress_settings
    vpc_connector = var.vpc_connector
    vpc_connector_egress_settings = var.vpc_connector_egress_settings
    service_account_email = google_service_account.sa.email
  }
}

data "google_iam_policy" "invoker" {
  binding {
    role = "roles/run.invoker"
    members = concat(
      var.invokers, (
        var.schedule == null ? [] : [
          "serviceAccount:${google_service_account.scheduler-sa[0].email}"
        ]
      )
    )
  }
}

resource "google_cloud_run_service_iam_policy" "policy" {
  project = google_cloudfunctions2_function.function.project
  location = google_cloudfunctions2_function.function.location
  service = google_cloudfunctions2_function.function.name
  policy_data = data.google_iam_policy.invoker.policy_data
}

resource "google_service_account" "scheduler-sa" {
  count = var.schedule == null ? 0 : 1
  account_id = "${var.function_name}-scheduler-sa"
}

resource "google_cloud_scheduler_job" "default" {
  count = var.schedule == null ? 0 : 1
  name             = "${var.function_name}-schedule"
  description      = var.schedule_description
  schedule         = var.schedule
  time_zone        = var.schedule_timezone
  attempt_deadline = var.schedule_attempt_deadline
  region = var.region

  retry_config {
    retry_count = var.schedule_retry_count
  }

  http_target {
    http_method = "GET"
    uri         =  google_cloudfunctions2_function.function.service_config[0].uri

    oidc_token {
      service_account_email = google_service_account.scheduler-sa[0].email
    }
  }
}