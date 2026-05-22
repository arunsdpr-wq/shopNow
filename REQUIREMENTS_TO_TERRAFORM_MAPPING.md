# Infrastructure Requirements to Terraform Implementation Mapping

## 📋 Overview

This document maps the detailed infrastructure requirements from the **INFRASTRUCTURE_COMPOSITION.md** to the actual Terraform configuration files that implement them.

---

## 🗺️ Requirements-to-Terraform Mapping

### 1️⃣ Network Architecture

**Requirements (from Part 2.2):**
- VPC: 10.0.0.0/16
- Public subnets: 2 AZs (10.0.101.0/24, 10.0.102.0/24)
- Private subnets: 2 AZs (10.0.1.0/24, 10.0.2.0/24)
- Internet Gateway
- NAT Gateways (HA)
- Security groups (3 types)
- Network policies

**Terraform Implementation:**

| Resource | File | Lines | Details |
|----------|------|-------|---------|
| VPC | `vpc.tf` | 20-25 | `aws_vpc.main` with CIDR 10.0.0.0/16 |
| Public Subnets | `vpc.tf` | 40-50 | 2 × `aws_subnet.public` with map_public_ip |
| Private Subnets | `vpc.tf` | 56-65 | 2 × `aws_subnet.private` |
| Internet Gateway | `vpc.tf` | 28-35 | `aws_internet_gateway.main` |
| NAT Gateways | `vpc.tf` | 37-50 | 2 × `aws_nat_gateway.main` with EIP |
| Public Route Table | `vpc.tf` | 68-80 | Routes to IGW |
| Private Route Tables | `vpc.tf` | 91-105 | Each routes to its AZ's NAT |
| EKS Cluster SG | `vpc.tf` | 120-145 | Ports 80, 443, 6443 |
| Node SG | `vpc.tf` | 148-170 | Internal VPC ports |
| Database SG | `vpc.tf` | 173-190 | MongoDB port 27017 |

**Terraform Variables:**
```hcl
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]
```

---

### 2️⃣ Compute Resources (EKS Cluster)

**Requirements (from Part 2.3):**
- EKS Kubernetes cluster (v1.28)
- Managed node groups
- Auto-scaling (1-4 nodes for dev)
- Instance type: t3.medium
- 50GB root disk
- Cluster autoscaler enabled
- Pod resource limits configured

**Terraform Implementation:**

| Component | File | Resource | Details |
|-----------|------|----------|---------|
| EKS Cluster | `eks.tf` | `module.eks` | Terraform AWS module v19.0 |
| Cluster Config | `eks.tf` | `cluster_name` | shopnow-dev-cluster |
| K8s Version | `variables.tf` | `cluster_version` | Default: 1.28 |
| Logging | `eks.tf` | `cluster_enabled_log_types` | API, audit, auth, control, scheduler |
| Node Group | `eks.tf` | `eks_managed_node_groups` | General purpose group |
| Scaling Config | `eks.tf` | `desired_size: 2` | Min 1, Max 4 |
| Instance Type | `variables.tf` | `node_instance_types` | t3.medium |
| Disk Size | `variables.tf` | `node_disk_size` | 50GB |
| KMS Encryption | `eks.tf` | `cluster_encryption_config` | EKS secrets encryption |
| Storage Classes | `eks.tf` | `kubernetes_storage_class` | gp3-ssd (default) |

**Terraform Variables:**
```hcl
cluster_version              = "1.28"
node_group_desired_size      = 2
node_group_min_size          = 1
node_group_max_size          = 4
node_instance_types          = ["t3.medium"]
node_disk_size               = 50
enable_cluster_autoscaler    = true
```

**Add-ons Configuration:**
- VPC CNI: `aws_eks_addon.vpc_cni`
- CoreDNS: `aws_eks_addon.coredns`
- kube-proxy: `aws_eks_addon.kube_proxy`
- EBS CSI Driver: `aws_eks_addon.ebs_csi_driver`

---

### 3️⃣ Identity & Access Management (IAM)

**Requirements (from Part 5.1 & 5.2):**
- EKS cluster IAM role
- Node group IAM role
- Service account IRSA (IAM Roles for Service Accounts)
- OIDC provider
- Cluster Autoscaler IAM
- EBS CSI Driver IAM

**Terraform Implementation:**

| Component | File | Resource | Purpose |
|-----------|------|----------|---------|
| Cluster Role | `iam.tf` | `aws_iam_role.cluster` | EKS cluster execution |
| Cluster Policies | `iam.tf` | `aws_iam_role_policy_attachment` | AmazonEKSClusterPolicy, VPCResourceController |
| Node Role | `iam.tf` | `aws_iam_role.node` | EC2 node execution |
| Node Policies | `iam.tf` | 5 × `aws_iam_role_policy_attachment` | Worker, CNI, ECR, SSM, CloudWatch |
| OIDC Provider | `iam.tf` | `aws_iam_openid_connect_provider` | Service account integration |
| OIDC Role | `iam.tf` | `aws_iam_role.oidc_provider_role` | General IRSA role |
| Cluster Autoscaler | `iam.tf` | `aws_iam_role.cluster_autoscaler` | Auto-scaling permissions |
| Autoscaler Policy | `iam.tf` | `aws_iam_role_policy.cluster_autoscaler` | ASG actions |
| EBS CSI Driver | `iam.tf` | `aws_iam_role.ebs_csi_driver` | Volume management |
| EBS Policy | `iam.tf` | `aws_iam_role_policy_attachment` | EBS CSI driver policy |

**Service Account IRSA Configuration:**
```hcl
# In kubernetes.tf
metadata {
  annotations = {
    "eks.amazonaws.com/role-arn" = aws_iam_role.oidc_provider_role.arn
  }
}
```

---

### 4️⃣ Container Registry (ECR)

**Requirements (from Part 1.3):**
- 3 ECR repositories (frontend, backend, admin)
- Image scanning on push
- Lifecycle policies (30-day retention)
- KMS encryption
- Repository access control

**Terraform Implementation:**

| Component | File | Resource | Details |
|-----------|------|----------|---------|
| Repositories | `ecr.tf` | `for_each` loop creates 3 repos | shopnow/frontend, backend, admin |
| Image Scanning | `ecr.tf` | `image_scanning_configuration` | scan_on_push = true |
| KMS Encryption | `ecr.tf` | `encryption_configuration` | Uses KMS key |
| Lifecycle Policy | `ecr.tf` | `aws_ecr_lifecycle_policy` | Keep 10 tagged, remove untagged after 30 days |
| Repository Policy | `ecr.tf` | `aws_ecr_repository_policy` | Allow EKS nodes to pull |
| KMS Key | `ecr.tf` | `aws_kms_key.ecr` | Encryption key for ECR |
| KMS Alias | `ecr.tf` | `aws_kms_alias.ecr` | Friendly key name |

**Terraform Variables:**
```hcl
ecr_repositories         = ["frontend", "backend", "admin"]
ecr_image_scan_on_push   = true
ecr_image_retention_days = 30
```

**Outputs:**
```hcl
# ECR URLs
"${account_id}.dkr.ecr.us-east-1.amazonaws.com/shopnow/frontend"
"${account_id}.dkr.ecr.us-east-1.amazonaws.com/shopnow/backend"
"${account_id}.dkr.ecr.us-east-1.amazonaws.com/shopnow/admin"
```

---

### 5️⃣ Kubernetes Configuration

**Requirements (from Part 2.3 & Part 5):**
- Namespaces (shopnow, monitoring, cert-manager)
- Service accounts with IRSA
- ConfigMaps for configuration
- Secrets for credentials
- Network policies (default deny)
- Resource quotas
- Pod disruption budgets
- RBAC roles

**Terraform Implementation:**

| Component | File | Resource | Details |
|-----------|------|----------|---------|
| Namespaces | `kubernetes.tf` | `kubernetes_namespace` | 3 namespaces created |
| Service Account | `kubernetes.tf` | `kubernetes_service_account.shopnow_backend` | With IRSA annotation |
| ConfigMap | `kubernetes.tf` | `kubernetes_config_map.shopnow_config` | App configuration |
| ECR Secret | `kubernetes.tf` | `kubernetes_secret.ecr_credentials` | DockerCfg format |
| Network Policies | `kubernetes.tf` | 3 × `kubernetes_network_policy` | Deny-by-default, allow-ingress, inter-pod |
| Resource Quota | `kubernetes.tf` | `kubernetes_resource_quota.shopnow` | CPU, memory, storage limits |
| Pod Disruption Budgets | `kubernetes.tf` | 2 × `kubernetes_pod_disruption_budget_v1` | Backend, frontend |

**Network Policy Configuration:**
```hcl
# Deny all ingress by default
kubernetes_network_policy.default_deny

# Allow from ingress controller
kubernetes_network_policy.allow_ingress

# Allow inter-pod communication
kubernetes_network_policy.allow_inter_pod
```

**Resource Quota:**
```
Requests:
  - CPU: 10 (total across namespace)
  - Memory: 20Gi
Limits:
  - CPU: 20
  - Memory: 40Gi
  - PVCs: 10
  - Pods: 100
  - Services: 10
```

---

### 6️⃣ Storage Configuration

**Requirements (from Part 2.4):**
- EBS storage class (GP3)
- StatefulSet for MongoDB
- Persistent volumes
- ConfigMaps & Secrets

**Terraform Implementation:**

| Component | File | Resource | Details |
|-----------|------|----------|---------|
| Storage Class 1 | `eks.tf` | `kubernetes_storage_class.ebs_gp3` | gp3-ssd (not default) |
| Storage Class 2 | `eks.tf` | `kubernetes_storage_class.ebs_gp3_default` | gp3-ssd-default (default) |
| Parameters | `eks.tf` | storage_class specs | IOPS: 3000, Throughput: 125 |
| Volume Binding | `eks.tf` | `volume_binding_mode` | WaitForFirstConsumer |
| Expansion | `eks.tf` | `allow_volume_expansion` | true |

**MongoDB Storage (in Kubernetes manifests):**
- volumeClaimTemplates in StatefulSet
- 50GB per MongoDB pod
- Storage class: gp3-ssd
- Access mode: ReadWriteOnce

---

### 7️⃣ Monitoring & Observability

**Requirements (from Part 1.6):**
- Prometheus for metrics
- Grafana for visualization
- CloudWatch logging
- Metrics server for HPA
- Cluster autoscaler

**Terraform Implementation:**

| Component | File | Resource | Details |
|-----------|------|----------|---------|
| Namespace | `kubernetes.tf` | `kubernetes_namespace.monitoring` | monitoring namespace |
| Prometheus | `helm.tf` | `helm_release.prometheus` | Version 25.3.1 |
| Grafana | `helm.tf` | `helm_release.grafana` | Version 7.0.8 |
| Metrics Server | `helm.tf` | `helm_release.metrics_server` | Version 3.11.0 |
| Cluster Autoscaler | `helm.tf` | `helm_release.cluster_autoscaler` | Version 9.34.1 |
| NGINX Ingress | `helm.tf` | `helm_release.nginx_ingress` | Version 4.8.3 |
| CloudWatch Logs | `eks.tf` | `cloudwatch_log_group` | /aws/eks/{cluster_name} |
| Log Retention | `variables.tf` | `log_retention_days` | Default: 7 days |

**Prometheus Configuration:**
```hcl
retention = "7d"
resources = {
  cpu: 100m, memory: 256Mi
}
```

**Grafana Configuration:**
```hcl
persistence.enabled    = true
persistence.size       = "5Gi"
persistence.storageClass = "gp3-ssd"
```

**Cluster Autoscaler Configuration:**
```hcl
autoDiscovery.clusterName = module.eks.cluster_name
autoDiscovery.enabled     = true
awsRegion                 = var.aws_region
```

---

### 8️⃣ Disaster Recovery & Backup

**Requirements (from Part 2.5):**
- Automated daily backups
- S3 storage for backups
- Terraform state backup
- Database snapshot strategy

**Terraform Implementation:**

| Component | File | Resource | Notes |
|-----------|------|----------|-------|
| S3 Backend | `versions.tf` | Backend config (commented) | Optional remote state |
| KMS Keys | `eks.tf`, `ecr.tf` | `aws_kms_key` | Encryption for data at rest |
| DynamoDB Lock | `versions.tf` | Backend lock table | For state file locking |
| CloudWatch Logs | `eks.tf` | Log group with KMS | Encrypted, 7-day retention |
| DocumentDB Backup | `database.tf` | `backup_retention_period` | 7 days (if enabled) |
| Database Secrets | `database.tf` | `aws_secretsmanager_secret` | Credentials storage |

**Manual Implementation Notes:**
- AWS Backup for database snapshots
- S3 versioning for Terraform state
- Git history for infrastructure code
- Helm release history for rollback

---

### 9️⃣ Security Implementation

**Requirements (from Part 5):**
- KMS encryption (at rest)
- TLS 1.3 (in transit)
- Network policies (pod firewall)
- RBAC (role-based access)
- Audit logging

**Terraform Implementation:**

| Layer | File | Resource | Details |
|-------|------|----------|---------|
| Network | `vpc.tf` | Security Groups | 3 SGs with least-privilege rules |
| Network | `kubernetes.tf` | Network Policies | Default deny + selective allow |
| Identity | `iam.tf` | RBAC + IAM | Roles and policies |
| Encryption | `eks.tf`, `ecr.tf` | KMS Keys | For secrets, ECR |
| Encryption | `vpc.tf` | EBS Encryption | Default in storage classes |
| Secrets | `kubernetes.tf` | K8s Secrets | Encrypted with KMS |
| Audit | `eks.tf` | CloudWatch Logs | Cluster API audit logs |
| Audit | `iam.tf` | Service Accounts | IRSA for pod identity |

---

## 🔄 Environment-Specific Mappings

### Development Environment

**terraform.tfvars:**
```hcl
aws_region                  = "us-east-1"
environment                 = "dev"
node_group_desired_size     = 2
node_instance_types         = ["t3.medium"]
enable_monitoring           = true
enable_cluster_autoscaler   = true
log_retention_days          = 7
ecr_image_retention_days    = 30
```

**Results:**
- 1 VPC with 2 public & 2 private subnets
- 1 EKS cluster with 2 t3.medium nodes (1-4 auto-scaling)
- 3 ECR repositories with lifecycle policies
- Prometheus + Grafana for monitoring
- Cluster autoscaler enabled
- 7-day CloudWatch log retention

**Estimated Cost:** ~$189/month

### Staging Environment

```hcl
environment              = "staging"
node_group_desired_size  = 3
node_instance_types      = ["t3.large"]
log_retention_days       = 14
enable_monitoring        = true
```

**Results:**
- Same VPC structure
- 1 EKS cluster with 3 t3.large nodes (2-6 auto-scaling)
- Higher monitoring granularity
- 14-day log retention
- All security features enabled

**Estimated Cost:** ~$326/month

### Production Environment

```hcl
environment                      = "prod"
node_group_desired_size          = 4
node_group_max_size              = 10
node_instance_types              = ["t3.xlarge"]
cluster_endpoint_private_access  = true
cluster_endpoint_public_access   = false
enable_rds_mongodb               = true
log_retention_days               = 90
```

**Results:**
- Private-only cluster endpoint
- 1 EKS cluster with 4 t3.xlarge nodes (3-10+ auto-scaling)
- Optional DocumentDB (managed MongoDB)
- 90-day log retention
- Enhanced monitoring & security

**Estimated Cost:** ~$811+/month (without RDS)

---

## 📊 Implementation Checklist

### Phase 1: Network (vpc.tf)
- [x] VPC creation
- [x] Subnets (public & private)
- [x] Internet Gateway
- [x] NAT Gateways
- [x] Route tables
- [x] Security groups

### Phase 2: IAM (iam.tf)
- [x] EKS cluster role
- [x] Node role
- [x] OIDC provider
- [x] Service account roles
- [x] Cluster autoscaler role
- [x] EBS CSI driver role

### Phase 3: EKS Cluster (eks.tf)
- [x] EKS cluster creation
- [x] Managed node groups
- [x] Add-ons installation
- [x] Storage classes
- [x] CloudWatch logging
- [x] KMS encryption

### Phase 4: Container Registry (ecr.tf)
- [x] ECR repositories
- [x] Lifecycle policies
- [x] Repository policies
- [x] Image scanning
- [x] KMS encryption

### Phase 5: Kubernetes (kubernetes.tf)
- [x] Namespaces
- [x] Service accounts (IRSA)
- [x] ConfigMaps
- [x] Secrets
- [x] Network policies
- [x] Resource quotas
- [x] Pod disruption budgets

### Phase 6: Monitoring (helm.tf)
- [x] NGINX Ingress Controller
- [x] Prometheus
- [x] Grafana
- [x] Metrics Server
- [x] Cluster Autoscaler

### Phase 7: Outputs (outputs.tf)
- [x] Cluster information
- [x] ECR repository URLs
- [x] Security group IDs
- [x] IAM role ARNs
- [x] kubectl configuration command

---

## 🚀 Deployment Workflow

```
Requirements Analysis
    ↓
Infrastructure Design (INFRASTRUCTURE_COMPOSITION.md)
    ↓
Visual Planning (INFRASTRUCTURE_VISUAL_SUMMARY.md)
    ↓
Terraform Development (9 .tf files)
    ↓
terraform init
    ↓
terraform plan
    ↓
terraform apply
    ↓
Configure kubectl
    ↓
Deploy Applications
    ↓
Setup CI/CD (Jenkins + ArgoCD)
    ↓
Enable Monitoring
    ↓
Production Ready!
```

---

## 📞 Quick Reference

### To Deploy Entire Infrastructure:
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### To View Generated Resources:
```bash
terraform output              # All outputs
terraform output -raw ecr_repository_urls
terraform state list          # List all resources
```

### To Update Configuration:
```bash
# Scale nodes
terraform apply -var="node_group_desired_size=3"

# Enable monitoring
terraform apply -var="enable_monitoring=true"

# Change to staging
terraform apply -var="environment=staging"
```

### To Destroy (Cleanup):
```bash
terraform destroy
```

---

## 📚 Related Documentation

- **INFRASTRUCTURE_COMPOSITION.md** - Detailed requirements (9 parts)
- **INFRASTRUCTURE_VISUAL_SUMMARY.md** - Visual diagrams and flows
- **terraform/README.md** - Terraform usage guide
- **terraform/QUICKSTART.md** - 5-minute quick start
- **TERRAFORM_DEPLOYMENT_GUIDE.md** - Deployment instructions

---

*This mapping document connects business requirements to technical implementation.*

*Last Updated: May 22, 2026*
