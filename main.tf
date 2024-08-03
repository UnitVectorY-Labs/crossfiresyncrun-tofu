# Enable Cloud Run API
resource "google_project_service" "run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Enable Eventarc API
resource "google_project_service" "eventarc" {
  project            = var.project_id
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

# Enable Pub/Sub API
resource "google_project_service" "pubsub" {
  project            = var.project_id
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

# Enable Firestore API
resource "google_project_service" "firestore" {
  project            = var.project_id
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

# The Pub/Sub topic that will be used to transport messages between the regions
resource "google_pubsub_topic" "crossfiresyncrun_pubsub_topic" {
  project                    = var.project_id
  name                       = "${var.name}-crossfiresyncrun"
  message_retention_duration = "86600s"
}

# The Pub/Sub Service Account that Cloud Run runs with
resource "google_service_account" "crossfiresyncrun_cloud_run_sa" {
  project      = var.project_id
  account_id   = "crossfiresyncrun-cr-${var.name}"
  display_name = "crossfiresyncrun Cloud Run (${var.name}) service account"
}

# Grant the Cloud Run service account the ability to write to Firestore
resource "google_project_iam_member" "crossfiresyncrun_firestore_writer" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.crossfiresyncrun_cloud_run_sa.email}"
}

# Grant publish permission to the Cloud Run service account for the specific Pub/Sub topic
resource "google_pubsub_topic_iam_member" "crossfiresyncrun_pubsub_topic_publish" {
  project = var.project_id
  topic   = google_pubsub_topic.crossfiresyncrun_pubsub_topic.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.crossfiresyncrun_cloud_run_sa.email}"
}

# The Cloud Run service in each of the regions
resource "google_cloud_run_v2_service" "crossfiresyncrun" {
  for_each = toset(var.regions)
  project  = var.project_id
  location = each.value
  name     = "${var.name}-${each.value}"
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.crossfiresyncrun_cloud_run_sa.email
    
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
        value = google_pubsub_topic.crossfiresyncrun_pubsub_topic.name
      }
    }
  }
}

# Firestore databases in each of the regions
resource "google_firestore_database" "databases" {
  for_each        = toset(var.regions)
  project         = var.project_id
  location_id     = each.value
  name            = "${var.name}-${each.value}"
  type            = "FIRESTORE_NATIVE"
  deletion_policy = var.deletion_policy
}

resource "google_service_account" "crossfiresyncrun_eventarc_sa" {
  project      = var.project_id
  account_id   = "crossfiresyncrun-ea-${var.name}"
  display_name = "crossfiresyncrun Eventarc (${var.name}) service account"
}

resource "google_project_iam_member" "crossfiresyncrun_eventarc_sa_eventarc_event_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.crossfiresyncrun_eventarc_sa.email}"
}

# Grant invoke permission to the Eventarc service account for the Cloud Run service
resource "google_cloud_run_service_iam_member" "crossfiresyncrun_invoke_permission" {
  for_each = toset(var.regions)
  project  = var.project_id
  location = each.value
  service  = google_cloud_run_v2_service.crossfiresyncrun[each.value].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.crossfiresyncrun_eventarc_sa.email}"
}

# Eventarc trigger that will be used to trigger the Cloud Run service
resource "google_eventarc_trigger" "crossfiresyncrur_eventarc_firebase_trigger" {
  for_each                = toset(var.regions)
  project                 = var.project_id
  name                    = "crossfiresyncrun-${var.name}-${each.value}"
  location                = each.value
  service_account         = google_service_account.crossfiresyncrun_eventarc_sa.email
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

  depends_on = [google_project_iam_member.crossfiresyncrun_eventarc_sa_eventarc_event_receiver]
}

resource "google_pubsub_subscription" "crossfiresyncrun_pubsub_subscription" {
  for_each                = toset(var.regions)
  project                 = var.project_id
  name  = "crossfiresyncrun-${var.name}-${each.value}"
  topic = google_pubsub_topic.crossfiresyncrun_pubsub_topic.name

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.crossfiresyncrun[each.value].uri}/pubsub"

    oidc_token {
      service_account_email = google_service_account.crossfiresyncrun_eventarc_sa.email
    }

    attributes = {
      x-goog-version = "v1"
    }
  }
}