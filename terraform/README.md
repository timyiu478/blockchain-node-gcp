# Terraform Setup for deploying an Ethereum node on Google Cloud Platform (GCP)

This document provides a step-by-step guide to set up terraform for deploying an ethereum node that connect with "hoodi" testnet on GCP VM for learning purposes.

## 1. Create a Service Account for Terraform

```bash
gcloud iam service-accounts create terraform-sa --display-name "Terraform Service Account"
```

## 2. Add IAM Roles to the Service Account

In this DEMO, we will assign the `Editor` role to the service account. You can adjust the roles based on your requirements.

```bash
gcloud projects add-iam-policy-binding <gcp_project_id> \
  --member="serviceAccount:terraform-sa@<gcp_project_id>.iam.gserviceaccount.com" \
  --role="roles/editor"
```

## 3. Create and Download the Service Account Key

```bash
gcloud iam service-accounts keys create credentials.json \
  --iam-account=terraform-sa@<gcp_project_id>.iam.gserviceaccount.com
```

## 4. Init terraform

```bash
terraform init
```

## 5. Specify the terraform variables in `terraform.tfvars` file

Example of the `terraform.tfvars` file:

```
gcp_project = "your gcp project id"
gcp_region = "asia-east1"
gcp_region_zone = "asia-east1-b"
gcp_credential_file = "credentials.json"
eth_node_vm_machine_type = "n2-standard-4" # Optional, default is "n2-standard-4"
```

## 6. Apply the Terraform Configuration

```bash
terraform apply
```

## 7. Destroy the Terraform Resources

When you no longer need the resources, you can destroy them using:

```bash
terraform destroy
```



## References

1. https://docs.nethermind.io/monitoring/metrics/grafana-and-prometheus/
2. https://lighthouse-book.sigmaprime.io/
