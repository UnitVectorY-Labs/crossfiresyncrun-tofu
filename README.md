[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Work In Progress](https://img.shields.io/badge/Status-Work%20In%20Progress-yellow)](https://guide.unitvectorylabs.com/bestpractices/status/#work-in-progress)

# crossfiresyncrun-tofu

A module for OpenTofu that deploys crossfiresyncrun to GCP Cloud Run, along with configuring essential services including Firestore and Pub/Sub.

## References

- [crossfiresync](https://github.com/UnitVectorY-Labs/crossfiresync) - A Java library enabling real-time synchronization between GCP Firestore instances across regions using Pub/Sub.
- [crossfiresyncrun](https://github.com/UnitVectorY-Labs/crossfiresyncrun) - Provides real-time synchronization between GCP Firestore instances across regions using Pub/Sub, packaged as a Docker image for deployment on Cloud Run.
- [crossfiresyncrun-tofu](https://github.com/UnitVectorY-Labs/crossfiresyncrun-tofu) - A module for OpenTofu that deploys crossfiresyncrun to GCP Cloud Run, along with configuring essential services including Firestore and Pub/Sub.
- [crossfiresync-firestore](https://github.com/UnitVectorY-Labs/crossfiresync-firestore) - Reference implementation of a crossfiresync Firestore publisher, featuring Java code and deployment scripts for Cloud Functions.
- [crossfiresync-pubsub](https://github.com/UnitVectorY-Labs/crossfiresync-pubsub) - Reference implementation of a crossfiresync Pub/Sub consumer, featuring Java code and deployment scripts for Cloud Functions.

## Usage

The basic use of this module is as follows:

```hcl
module "crossfiresyncrun" {
    source = "git::https://github.com/UnitVectorY-Labs/crossfiresyncrun-tofu.git?ref=main"
    name = "mydb"
    project_id = var.project_id
    artifact_registry_name = "ghcr"
    regions = ["us-east1"]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_service_iam_member.invoke_permission](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service_iam_member) | resource |
| [google_cloud_run_v2_service.crossfiresyncrun](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_eventarc_trigger.firestore_trigger](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/eventarc_trigger) | resource |
| [google_firestore_database.databases](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_database) | resource |
| [google_project_iam_member.eventarc_event_receiver_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.firestore_writer_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.eventarc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.firestore](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.pubsub](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.run](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_pubsub_subscription.pubsub_subscription](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_topic.crossfiresyncrun_topic](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.pubsub_publisher_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_service_account.cloud_run_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.eventarc_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifact_registry_host"></a> [artifact\_registry\_host](#input\_artifact\_registry\_host) | The name of the Artifact Registry repository | `string` | `"us-docker.pkg.dev"` | no |
| <a name="input_artifact_registry_name"></a> [artifact\_registry\_name](#input\_artifact\_registry\_name) | The name of the Artifact Registry repository | `string` | n/a | yes |
| <a name="input_artifact_registry_project_id"></a> [artifact\_registry\_project\_id](#input\_artifact\_registry\_project\_id) | The project to use for Artifact Registry. Will default to the project\_id if not set. | `string` | `null` | no |
| <a name="input_crossfiresyncrun_tag"></a> [crossfiresyncrun\_tag](#input\_crossfiresyncrun\_tag) | The tag for the crossfiresyncrun image to deploy | `string` | `"dev"` | no |
| <a name="input_firestore_deletion_policy"></a> [firestore\_deletion\_policy](#input\_firestore\_deletion\_policy) | The deletion policy for Firestore databases | `string` | `"ABANDON"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the database (limited to 10 characters right now, boo) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project id | `string` | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | List of regions where resources will be created | `list(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
