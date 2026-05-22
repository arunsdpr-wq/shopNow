.PHONY: help init validate fmt plan apply destroy clean output logs scale-up scale-down init-monitoring quick-setup

TERRAFORM := terraform
ENVIRONMENT ?= dev
REGION ?= us-east-1
NODES ?= 2

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Display this help message
	@echo "$(BLUE)ShopNow Terraform Makefile$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Usage Examples:$(NC)"
	@echo "  make init                    # Initialize Terraform"
	@echo "  make plan ENVIRONMENT=prod   # Plan for production"
	@echo "  make apply                   # Apply configuration"
	@echo "  make scale-up NODES=4        # Scale to 4 nodes"

init: ## Initialize Terraform
	@echo "$(BLUE)[INFO]$(NC) Initializing Terraform..."
	$(TERRAFORM) init
	@echo "$(GREEN)[SUCCESS]$(NC) Terraform initialized"

validate: ## Validate Terraform configuration
	@echo "$(BLUE)[INFO]$(NC) Validating Terraform configuration..."
	$(TERRAFORM) validate
	@echo "$(GREEN)[SUCCESS]$(NC) Configuration is valid"

fmt: ## Format Terraform files
	@echo "$(BLUE)[INFO]$(NC) Formatting Terraform files..."
	$(TERRAFORM) fmt -recursive .
	@echo "$(GREEN)[SUCCESS]$(NC) Files formatted"

clean-plan: ## Remove old plan file
	@echo "$(BLUE)[INFO]$(NC) Removing old plan file..."
	@rm -f tfplan
	@echo "$(GREEN)[SUCCESS]$(NC) Plan file removed"

plan: clean-plan validate ## Plan Terraform deployment
	@echo "$(BLUE)[INFO]$(NC) Planning Terraform deployment for $(ENVIRONMENT)..."
	$(TERRAFORM) plan \
		-var="environment=$(ENVIRONMENT)" \
		-out=tfplan
	@echo "$(GREEN)[SUCCESS]$(NC) Plan created: tfplan"

apply: ## Apply Terraform configuration
	@echo "$(BLUE)[INFO]$(NC) Applying Terraform configuration..."
	$(TERRAFORM) apply tfplan
	@echo "$(GREEN)[SUCCESS]$(NC) Infrastructure deployed successfully!"

destroy: ## Destroy all Terraform infrastructure
	@echo "$(RED)[WARNING]$(NC) This will destroy all infrastructure!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(RED)Destroying infrastructure...$(NC)"; \
		$(TERRAFORM) destroy -auto-approve; \
		echo "$(GREEN)[SUCCESS]$(NC) Infrastructure destroyed"; \
	else \
		echo "$(YELLOW)Destroy cancelled$(NC)"; \
	fi

output: ## Display Terraform outputs
	@echo "$(BLUE)Terraform Outputs:$(NC)"
	@$(TERRAFORM) output

cluster-name: ## Get EKS cluster name
	@$(TERRAFORM) output -raw eks_cluster_name

cluster-endpoint: ## Get EKS cluster endpoint
	@$(TERRAFORM) output -raw eks_cluster_endpoint

ecr-repos: ## Get ECR repository URLs
	@$(TERRAFORM) output -raw ecr_repository_urls

configure-kubectl: ## Configure kubectl for the cluster
	@echo "$(BLUE)[INFO]$(NC) Configuring kubectl..."
	@aws eks update-kubeconfig --region $(REGION) --name $(shell $(TERRAFORM) output -raw eks_cluster_name)
	@echo "$(GREEN)[SUCCESS]$(NC) kubectl configured"

verify-cluster: ## Verify cluster access
	@echo "$(BLUE)[INFO]$(NC) Verifying cluster access..."
	@kubectl cluster-info
	@echo ""
	@echo "$(BLUE)Nodes:$(NC)"
	@kubectl get nodes
	@echo ""
	@echo "$(BLUE)Pods:$(NC)"
	@kubectl get pods -A
	@echo "$(GREEN)[SUCCESS]$(NC) Cluster verified"

scale-up: ## Scale up node group
	@echo "$(YELLOW)[WARNING]$(NC) Scaling up to $(NODES) nodes..."
	$(TERRAFORM) apply -var="node_group_desired_size=$(NODES)" -auto-approve
	@echo "$(GREEN)[SUCCESS]$(NC) Scaled to $(NODES) nodes"

scale-down: ## Scale down node group
	@echo "$(YELLOW)[WARNING]$(NC) Scaling down to $(NODES) nodes..."
	$(TERRAFORM) apply -var="node_group_desired_size=$(NODES)" -auto-approve
	@echo "$(GREEN)[SUCCESS]$(NC) Scaled to $(NODES) nodes"

logs-eks: ## View EKS cluster logs
	@aws logs tail /aws/eks/$$($(TERRAFORM) output -raw eks_cluster_name) --follow

logs-nodes: ## View node logs
	@aws logs tail /aws/eks/$$($(TERRAFORM) output -raw eks_cluster_name)/nodes --follow

logs-monitoring: ## View monitoring logs
	@kubectl logs -f -n monitoring svc/prometheus-kube-prometheus-prometheus | head -100

grafana-port-forward: ## Port-forward to Grafana
	@echo "$(BLUE)[INFO]$(NC) Port-forwarding to Grafana..."
	@echo "$(GREEN)Access Grafana at: http://localhost:3000$(NC)"
	@echo "$(YELLOW)Default credentials: admin / prom-operator$(NC)"
	kubectl port-forward -n monitoring svc/grafana 3000:80

prometheus-port-forward: ## Port-forward to Prometheus
	@echo "$(BLUE)[INFO]$(NC) Port-forwarding to Prometheus..."
	@echo "$(GREEN)Access Prometheus at: http://localhost:9090$(NC)"
	kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

quick-setup: init validate fmt plan apply configure-kubectl verify-cluster ## Full quick setup
	@echo "$(GREEN)[SUCCESS]$(NC) Full setup complete!"

version: ## Show versions
	@echo "$(BLUE)Terraform Version:$(NC)"
	@$(TERRAFORM) version -json | grep terraform_version
	@echo "$(BLUE)Kubernetes Version:$(NC)"
	@kubectl version --short 2>/dev/null || echo "kubectl not configured yet"
	@echo "$(BLUE)AWS CLI Version:$(NC)"
	@aws --version

docs: ## Open documentation
	@echo "Opening README.md..."
	@which open > /dev/null && open README.md || (which xdg-open > /dev/null && xdg-open README.md) || echo "Please open README.md manually"

state-list: ## List Terraform state resources
	@$(TERRAFORM) state list

state-show: ## Show detailed state (requires RESOURCE variable)
	@$(TERRAFORM) state show $(RESOURCE)

refresh: ## Refresh Terraform state
	@echo "$(BLUE)[INFO]$(NC) Refreshing Terraform state..."
	@$(TERRAFORM) refresh
	@echo "$(GREEN)[SUCCESS]$(NC) State refreshed"

backup-state: ## Backup Terraform state
	@echo "$(BLUE)[INFO]$(NC) Backing up Terraform state..."
	@mkdir -p backups
	@cp terraform.tfstate backups/terraform.tfstate.$$(date +%Y%m%d_%H%M%S)
	@echo "$(GREEN)[SUCCESS]$(NC) State backed up"

.DEFAULT_GOAL := help
