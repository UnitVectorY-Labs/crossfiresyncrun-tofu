[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Work In Progress](https://img.shields.io/badge/Status-Work%20In%20Progress-yellow)](https://unitvectory-labs.github.io/uvy-labs-guide/bestpractices/status/#work-in-progress)

# crossfiresyncrun-tofu

This OpenTofu module is used for deploying crossfiresyncrun to GCP.

## Usage

The basic use of this module is as follows:

```hcl
module "crossfiresyncrun" {
    source = "git::https://github.com/UnitVectorY-Labs/crossfiresyncrun-tofu.git?ref=main"
    name = "mydb"
    project_id = var.project_id
    regions = ["us-east1"]
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->