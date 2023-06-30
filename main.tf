/*
 Terraform module to create a GCP storage bucket.
 This module will create a GCP storage bucket and return the bucket name and region.
 It also proxies credentials for the workload to access the created bucket.
 
 Required variables:
 - gcp_credentials_b64: base64 encoded GCP credentials
 - gcp_project: GCP project name
 - bucket_location: GCP bucket location
 - app_name: Application name
 - env_name: Environment name
 - resource_name: Resource name
 - workload_access_credentials_b64: base64 encoded credentials for the workload to access created buckets

 Why workload_access_credentials_b64?
  The workload needs to access the created bucket. Ideally we would create a service account for the workload and grant it access to the bucket.
  However for this simple implementation we will just proxy the workload credentials to the bucket.
  The credentials used will be created externally and scoped to only read/write buckets in this gcp project.

 Setup Resource Definition:

 Resource Type: S3
 Driver: Terraform
 URL: https://github.com/humanitec-poc-org-8367/gcp-bucket-tf.git
 Revision: refs/heads/main

 Inputs (Change GCP_PROJECT_ID to your GCP project ID):
  {
    "app_name": "${context.app.id}",
    "bucket_location": "US",
    "env_name": "${context.env.id}",
    "gcp_project": "GCP_PROJECT_ID",
    "resource_name": "${context.res.id}"
  }

  Secrets:
  {
    "gcp_credentials_b64": "BASE64_ENCODED_GCP_CREDENTIALS",
    "workload_access_credentials_b64": "BASE64_ENCODED_WORKLOAD_CREDENTIALS"
  }
*/

variable gcp_credentials_b64 {
  type = string
  sensitive = true
}

variable gcp_project {
  type = string
}

variable bucket_location {
  type = string
  default = "US"
}

variable app_name {
  type = string
}

variable env_name {
  type = string
}

variable resource_name {
  type = string
}

variable workload_access_credentials_b64 {
  type = string
  sensitive = true
  description = "Credentials for the workload to access created buckets"
}

locals {
  resource_id = split(".", var.resource_name)[3]
}

provider "google" {
  credentials = base64decode(var.gcp_credentials_b64)
  project     = var.gcp_project
}

resource "google_storage_bucket" "bucket" {
  name          = replace(replace(lower("${var.app_name}-${var.env_name}-${local.resource_id}"), " ", "_"), ".", "_")
  location      = var.bucket_location
  force_destroy = true // Allow terraform to destroy the bucket.

  public_access_prevention = "enforced" // Never allow public access to this bucket
}

output "bucket" {
  value = google_storage_bucket.bucket.name
}

output "region" {
  value = google_storage_bucket.bucket.location
}

output "credentials" {
  value = base64decode(var.workload_access_credentials_b64)
  description = "Credentials for the workload to access created buckets"
  sensitive = true
}
