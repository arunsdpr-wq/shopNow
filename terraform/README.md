# ShopNow - Terraform Infrastructure Configuration

Complete Terraform configuration for deploying the ShopNow e-commerce application on AWS EKS (Elastic Kubernetes Service).

## 📋 Project Structure

```
terraform/
├── versions.tf              # Terraform and provider versions
├── variables.tf             # Variable definitions
├── main.tf                  # Main configuration and data sources
├── vpc.tf                   # VPC, subnets, NAT, and security groups
├── iam.tf                   # IAM roles and policies
├── eks.tf                   # EKS cluster and add-ons
├── ecr.tf                   # ECR repositories and policies
├── database.tf              # Optional DocumentDB (MongoDB) configuration
├── kubernetes.tf            # Kubernetes namespaces, RBAC, and policies
├── helm.tf                  # Helm chart installations
├── outputs.tf               # Output definitions
├── terraform.tfvars         # Terraform variable values
└── README.md                # This file
```

## 🎯 What This Configuration Creates

### AWS Infrastructure
- **VPC**: Custom VPC with public and private subnets across multiple AZs
- **NAT Gateways**: For outbound internet access from private subnets
- **Internet Gateway**: For public internet access
- **Security Groups**: Configured for EKS cluster, nodes, and database
- **KMS Keys**: For encryption of EKS and ECR

### EKS Cluster
- **Kubernetes Cluster**: Production-grade EKS cluster
- **Managed Node Groups**: Auto-scaling worker nodes
- **EKS Add-ons**: VPC CNI, CoreDNS, kube-proxy, EBS CSI Driver
- **OIDC Provider**: For IAM roles for service accounts (IRSA)
- **Storage Classes**: GP3 EBS storage for persistent volumes
- **CloudWatch Logging**: Cluster logs exported to CloudWatch

### Container Registry
- **ECR Repositories**: For frontend, backend, and admin applications
- **Image Scanning**: Automatic vulnerability scanning on push
- **Lifecycle Policies**: Automatic cleanup of old images
- **Repository Policies**: Restrict access to EKS nodes

### Kubernetes Components
- **Namespaces**: Isolated environments for applications
- **Service Accounts**: With IAM role bindings
- **RBAC**: Role-based access control policies
- **Network Policies**: Ingress/egress traffic control
- **Resource Quotas**: CPU and memory limits per namespace
- **Pod Disruption Budgets**: For high availability

### Helm Charts
- **NGINX Ingress Controller**: For external traffic routing
- **Prometheus & Grafana**: For monitoring and visualization
- **Metrics Server**: For horizontal pod autoscaling
- **Cluster Autoscaler**: For automatic node scaling

### Optional Database
- **DocumentDB**: MongoDB-compatible managed database (optional)
- **AWS Secrets Manager**: For secure credential storage
- **CloudWatch Logs**: For audit and error logging

## 🚀 Prerequisites

### Required Tools
- Terraform >= 1.0
- AWS CLI v2
- kubectl >= 1.24
- helm >= 3.0

### AWS Setup
```bash
# Configure AWS credentials
aws configure
# Or set environment variables:
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-east-1
```

### Install Required Tools
```bash
# Install Terraform
curl https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 🔧 Configuration

### 1. Update Variables
Edit `terraform.tfvars` to match your requirements:

```hcl
aws_region    = "us-east-1"
project_name  = "shopnow"
environment   = "dev"              # dev, staging, prod

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]

# EKS Configuration
cluster_version        = "1.28"
node_group_desired_size = 2        # Number of worker nodes

# ECR Configuration
ecr_repositories = ["frontend", "backend", "admin"]

# Enable optional features
enable_monitoring     = true       # Enable Prometheus/Grafana
enable_rds_mongodb    = false      # Enable DocumentDB (optional)
```

### 2. Environment-Specific Values

Create environment-specific variable files:

```bash
# For staging
cp terraform.tfvars terraform-staging.tfvars
# Edit terraform-staging.tfvars and apply with:
terraform apply -var-file="terraform-staging.tfvars"

# For production
cp terraform.tfvars terraform-prod.tfvars
# Edit terraform-prod.tfvars and apply with:
terraform apply -var-file="terraform-prod.tfvars"
```

## 📦 Deployment

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Validate Configuration
```bash
terraform validate
terraform fmt -recursive .
```

### 3. Plan Deployment
```bash
terraform plan -out=tfplan
```

### 4. Apply Configuration
```bash
terraform apply tfplan
```

This will:
- Create VPC and networking infrastructure
- Provision EKS cluster with managed node groups
- Setup ECR repositories
- Configure Kubernetes namespaces and RBAC
- Install Helm charts for ingress and monitoring

### 5. Configure kubectl
```bash
# Get the command from outputs or run:
aws eks update-kubeconfig --region us-east-1 --name shopnow-dev-cluster

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

## 📊 Key Outputs

After deployment, get important information from outputs:

```bash
# View all outputs
terraform output

# Specific outputs
terraform output eks_cluster_name
terraform output ecr_repository_urls
terraform output configure_kubectl
```

## 🐳 Push Docker Images to ECR

Once ECR repositories are created:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS --password-stdin $(terraform output -raw aws_account_id).dkr.ecr.us-east-1.amazonaws.com

# Build and push frontend
cd frontend
docker build -t shopnow-frontend:latest .
docker tag shopnow-frontend:latest $(terraform output -raw aws_account_id).dkr.ecr.us-east-1.amazonaws.com/shopnow/frontend:latest
docker push $(terraform output -raw aws_account_id).dkr.ecr.us-east-1.amazonaws.com/shopnow/frontend:latest

# Repeat for backend and admin
```

## 📝 Managing Resources

### Scale Node Groups
```bash
terraform apply -var="node_group_desired_size=3"
```

### Update Kubernetes Version
```bash
terraform apply -var="cluster_version=1.29"
```

### Enable Monitoring
```bash
terraform apply -var="enable_monitoring=true"
```

### Enable DocumentDB
```bash
terraform apply -var="enable_rds_mongodb=true"
```

## 🔍 Common Operations

### Check EKS Cluster Status
```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

### View Logs
```bash
# Cluster logs
aws logs tail /aws/eks/shopnow-dev-cluster/cluster --follow

# ECR logs
aws logs tail /aws/ecr/shopnow-dev-ecr --follow
```

### Access Grafana Dashboard
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# Access http://localhost:3000
```

### SSH into Nodes
```bash
# List nodes
aws ec2 describe-instances --filters "Name=tag:aws:eks:cluster-name,Values=shopnow-dev-cluster"

# Connect via Systems Manager Session Manager
aws ssm start-session --target <instance-id>
```

## 🗑️ Cleanup

### Destroy All Resources
```bash
# Verify what will be deleted
terraform plan -destroy

# Delete all resources
terraform destroy
```

⚠️ **Warning**: This will delete all resources including:
- EKS cluster
- ECR repositories (use `terraform destroy -var="ecr_force_delete=true"` to delete non-empty ECR repos)
- VPC and networking
- DocumentDB (if enabled) and backups

## 🔐 Security Best Practices

1. **Enable State Encryption**: Uncomment the S3 backend in `versions.tf` and use encrypted S3 bucket
2. **Restrict Public Access**: Set `cluster_endpoint_public_access = false` for production
3. **Enable Network Policies**: Already configured in `kubernetes.tf`
4. **Use IRSA**: All pods should use IAM roles for service accounts
5. **Enable Pod Security Standards**: Implement PSP in production
6. **Rotate Credentials**: Update DocumentDB password regularly
7. **Monitor Access**: Enable CloudTrail for audit logging

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes on AWS](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
- [Helm Documentation](https://helm.sh/docs/)

## 🤝 Support and Troubleshooting

### Common Issues

1. **Nodes not ready**
   ```bash
   kubectl describe node <node-name>
   kubectl logs -n kube-system <pod-name>
   ```

2. **ECR Authentication Failed**
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
   ```

3. **Storage Class Issues**
   ```bash
   kubectl describe storageclass gp3-ssd
   kubectl get pvc -A
   ```

## 📄 License

This Terraform configuration is part of the ShopNow project. See LICENSE file for details.
