# Terraform: Reusable EKS Foundation (No eksctl)

## Usage
```bash
terraform init
terraform plan -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars
```

## What this creates
- VPC with public/private subnets across configurable AZs.
- EKS cluster with managed node group baseline capacity.
- IRSA enabled for workload IAM roles.
- EKS core addons with most recent stable versions.

## Reuse strategy
- Override variables per environment (`env/<env>.tfvars`).
- Keep tags and naming consistent for cost/governance.
- Add more node groups or autoscaler integrations without changing root layout.
