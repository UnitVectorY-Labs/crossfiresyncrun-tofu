
# Firestore databases in multiple regions
resource "google_firestore_database" "databases" {
  for_each        = toset(var.regions)
  project         = var.project_id
  location_id     = each.value
  name            = "${var.name}-${each.value}"
  type            = "FIRESTORE_NATIVE"
  deletion_policy = var.deletion_policy
}
