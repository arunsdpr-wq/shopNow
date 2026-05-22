# ShopNow Terraform - Quick Start Guide

Quick reference for getting started with the ShopNow Terraform deployment.

## ⚡ 5-Minute Quick Start

### 1. Prerequisites
```bash
# Check installed versions
terraform --version        # >= 1.0
aws --version             # >= 2.0
kubectl version --short   # >= 1.24
helm version              # >= 3.0
```

### 2. Configure AWS
```bash
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region (us-east-1), Output format (json)
```

### 3. Deploy Infrastructure
```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Apply configuration (this takes ~20-30 minutes)
terraform apply tfplan
```

### 4. Access Cluster
```bash
# Get cluster access command
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
REGION=$(terraform output -raw aws_region)

aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Verify access
kubectl get nodes
```

## 🔧 Configuration

### Development (Default)
```bash
# terraform.tfvars already configured for dev
terraform apply tfplan
```

### Staging
```bash
terraform apply -var="environment=staging" -var="node_group_desired_size=3" tfplan
```

### Production
```bash
terraform apply -var="environment=prod" -var="node_group_desired_size=4" \
                 -var="cluster_endpoint_private_access=true" tfplan
```

## 📊 Important Outputs

```bash
# View all outputs
terraform output

# Specific outputs
terraform output eks_cluster_name
terraform output ecr_repository_urls
terraform output configure_kubectl
```

## 🐳 Deploy Applications

### Push Docker Images
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $(terraform output -raw aws_account_id).dkr.ecr.us-east-1.amazonaws.com

# Build and push frontend
cd frontend
docker build -t shopnow-frontend:latest .
docker tag shopnow-frontend:latest \
  $(terraform output -raw aws_account_id).dkr.ecr.us-east-1.amazonaws.com/shopnow/frontend:v1.0
docker push $(terraform output -raw aws_account_id).dkr.ecr.us-east-1.amazonaws.com/shopnow/frontend:v1.0
```

### Deploy with Kubernetes
```bash
# Create namespace
kubectl create namespace shopnow

# Deploy backend
kubectl apply -f ../kubernetes/k8s-manifests/backend/ -n shopnow

# Deploy frontend
kubectl apply -f ../kubernetes/k8s-manifests/frontend/ -n shopnow

# Deploy admin
kubectl apply -f ../kubernetes/k8s-manifests/admin/ -n shopnow
```

### Or Deploy with Helm
```bash
# Update image URLs in helm values
helm upgrade --install backend ../kubernetes/helm/charts/backend -n shopnow \
  --set image.repository=$(terraform output -raw aws_account_id).dkr.ecr.us-east-1.amazonaws.com/shopnow/backend

helm upgrade --install frontend ../kubernetes/helm/charts/frontend -n shopnow \
  --set image.repository=$(terraform output -raw aws_account_id).dkr.ecr.us-east-1.amazonaws.com/shopnow/frontend
```

## 🔍 Verification

```bash
# Check nodes
kubectl get nodes

# Check namespaces
kubectl get ns

# Check pods
kubectl get pods -A

# Check services
kubectl get svc -A

# Check ingress
kubectl get ingress -A

# Check storage classes
kubectl get storageclass
```

## 📈 Monitoring

### Access Grafana Dashboard
```bash
# Port-forward to Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# Open http://localhost:3000
# Default credentials: admin / prom-operator
```

### Check Prometheus
```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Open http://localhost:9090
```

## 🔐 Security Considerations

1. **Update Default Passwords**
   - Change Grafana default password
   - Update DocumentDB password if using RDS

2. **Network Access**
   - Restrict security group ingress rules
   - Use private subnets for nodes
   - Enable Network Policies

3. **IAM Permissions**
   - Review IAM policies
   - Use least privilege principle
   - Enable CloudTrail for audit

4. **Encryption**
   - Enable KMS encryption (already done)
   - Use encrypted EBS volumes
   - Enable S3 backend encryption for state

## 🗑️ Cleanup

```bash
# Delete all Kubernetes deployments
kubectl delete ns shopnow monitoring cert-manager

# Delete Terraform resources (requires Ctrl+C confirmation)
terraform destroy
```

## 🆘 Common Commands

```bash
# Troubleshooting
kubectl describe node <node-name>
kubectl logs -n kube-system <pod-name>
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Scaling
kubectl scale deployment backend -n shopnow --replicas=3
terraform apply -var="node_group_desired_size=3"

# View events
kubectl get events -n shopnow --sort-by='.lastTimestamp'

# Get resource usage
kubectl top nodes
kubectl top pod -A
```

## 📚 Documentation Links

- [Full README](README.md)
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md)
- [AWS EKS Docs](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## ⏱️ Estimated Timing

| Step | Time |
|------|------|
| Prerequisites check | 2-3 min |
| Terraform init | 1-2 min |
| Terraform plan | 2-3 min |
| Infrastructure creation | 20-30 min |
| kubectl configuration | < 1 min |
| **Total** | **30-40 min** |

## 💡 Pro Tips

1. Use `terraform fmt` to keep code clean
2. Use `terraform validate` before every plan
3. Use `-var` flag for quick overrides
4. Store state in S3 backend for team collaboration
5. Use `terraform import` for existing resources
6. Create separate tfvars files for each environment
7. Use workspaces for multiple environments

## 🎯 Next Steps

1. ✅ Run `terraform init`
2. ✅ Run `terraform plan`
3. ✅ Review the plan output
4. ✅ Run `terraform apply`
5. ✅ Wait for cluster creation
6. ✅ Configure kubectl
7. ✅ Push Docker images
8. ✅ Deploy applications
9. ✅ Monitor the deployment

## 📞 Support

For detailed information, see [README.md](README.md) or reach out to your team.
