# Enable required APIs for Cloud Run, Eventarc, Pub/Sub, and Firestore
resource "google_project_service" "run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "eventarc" {
  project            = var.project_id
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "pubsub" {
  project            = var.project_id
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "firestore" {
  project            = var.project_id
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

# Create Pub/Sub topic for cross-region messaging
resource "google_pubsub_topic" "crossfiresyncrun_topic" {
  project                    = var.project_id
  name                       = "${var.name}-crossfiresyncrun"
  message_retention_duration = "86600s"
}

# Service account for Cloud Run services
resource "google_service_account" "cloud_run_sa" {
  project      = var.project_id
  account_id   = "crossfiresyncrun-cr-${var.name}"
  display_name = "crossfiresyncrun Cloud Run (${var.name}) service account"
}

# IAM role to grant Firestore write permissions to Cloud Run service account
resource "google_project_iam_member" "firestore_writer_role" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# IAM role to grant Pub/Sub publish permissions to Cloud Run service account
resource "google_pubsub_topic_iam_member" "pubsub_publisher_role" {
  project = var.project_id
  topic   = google_pubsub_topic.crossfiresyncrun_topic.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Deploy Cloud Run services in specified regions
resource "google_cloud_run_v2_service" "crossfiresyncrun" {
  for_each = toset(var.regions)
  project  = var.project_id
  location = each.value
  name     = "${var.name}-${each.value}"
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.cloud_run_sa.email

    containers {
      image = "us-docker.pkg.dev/${var.project_id}/ghcr/unitvectory-labs/crossfiresyncrun:dev"

      env {
        name  = "REPLICATION_MODE"
        value = "MULTI_REGION_PRIMARY"
      }
      env {
        name  = "DATABASE"
        value = "${var.name}-${each.value}"
      }
      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }
      env {
        name  = "TOPIC"
        value = google_pubsub_topic.crossfiresyncrun_topic.name
      }
    }
  }
}

# Create Firestore databases in specified regions
resource "google_firestore_database" "databases" {
  for_each        = toset(var.regions)
  project         = var.project_id
  location_id     = each.value
  name            = "${var.name}-${each.value}"
  type            = "FIRESTORE_NATIVE"
  deletion_policy = var.deletion_policy
}

# Service account for Eventarc triggers
resource "google_service_account" "eventarc_sa" {
  project      = var.project_id
  account_id   = "crossfiresyncrun-ea-${var.name}"
  display_name = "crossfiresyncrun Eventarc (${var.name}) service account"
}

# IAM role to grant Eventarc event receiver permissions to Eventarc service account
resource "google_project_iam_member" "eventarc_event_receiver_role" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.eventarc_sa.email}"
}

# IAM role to grant invoke permissions to Eventarc service account for Cloud Run services
resource "google_cloud_run_service_iam_member" "invoke_permission" {
  for_each = toset(var.regions)
  project  = var.project_id
  location = each.value
  service  = google_cloud_run_v2_service.crossfiresyncrun[each.value].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.eventarc_sa.email}"
}

# Eventarc trigger to invoke Cloud Run services on Firestore changes
resource "google_eventarc_trigger" "firestore_trigger" {
  for_each                = toset(var.regions)
  project                 = var.project_id
  name                    = "crossfiresyncrun-${var.name}-${each.value}"
  location                = each.value
  service_account         = google_service_account.eventarc_sa.email
  event_data_content_type = "application/protobuf"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.firestore.document.v1.written"
  }

  matching_criteria {
    attribute = "database"
    value     = "${var.name}-${each.value}"
  }

  destination {
    cloud_run_service {
      region  = each.value
      service = google_cloud_run_v2_service.crossfiresyncrun[each.value].name
      path    = "/firestore"
    }
  }

  depends_on = [google_project_iam_member.eventarc_event_receiver_role]
}

# Pub/Sub subscription to forward messages to Cloud Run services
resource "google_pubsub_subscription" "pubsub_subscription" {
  for_each                = toset(var.regions)
  project                 = var.project_id
  name                    = "crossfiresyncrun-${var.name}-${each.value}"
  topic                   = google_pubsub_topic.crossfiresyncrun_topic.name

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.crossfiresyncrun[each.value].uri}/pubsub"

    oidc_token {
      service_account_email = google_service_account.eventarc_sa.email
    }

    attributes = {
      x-goog-version = "v1"
    }
  }
}