#!/bin/bash

# ShopNow Terraform Quick Start Script
# This script helps initialize and deploy the Terraform configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    print_success "Terraform $(terraform version -json | grep terraform_version | cut -d'"' -f4) found"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    print_success "AWS CLI found"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl found"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured"
        exit 1
    fi
    print_success "AWS credentials configured"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized"
}

# Validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    terraform validate
    print_success "Configuration is valid"
}

# Format Terraform files
format_terraform() {
    print_status "Formatting Terraform files..."
    terraform fmt -recursive .
    print_success "Files formatted"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_success "Plan created: tfplan"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    print_success "Infrastructure deployed successfully!"
}

# Configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl..."
    
    CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "")
    REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
    
    if [ -z "$CLUSTER_NAME" ]; then
        print_error "Could not get cluster name from outputs"
        return 1
    fi
    
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
    print_success "kubectl configured for cluster: $CLUSTER_NAME"
}

# Verify cluster access
verify_cluster() {
    print_status "Verifying cluster access..."
    
    if kubectl cluster-info &> /dev/null; then
        print_success "Successfully connected to EKS cluster"
        kubectl version --short
        kubectl get nodes
    else
        print_error "Failed to connect to EKS cluster"
        return 1
    fi
}

# Display useful information
display_outputs() {
    print_status "Terraform Outputs:"
    echo ""
    terraform output
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}=== ShopNow Terraform Deployment ===${NC}"
    echo ""
    echo "1. Check Prerequisites"
    echo "2. Initialize Terraform"
    echo "3. Validate Configuration"
    echo "4. Format Files"
    echo "5. Plan Deployment"
    echo "6. Apply Configuration"
    echo "7. Configure kubectl"
    echo "8. Verify Cluster Access"
    echo "9. Display Outputs"
    echo "10. Full Deployment (steps 1-8)"
    echo "11. Destroy Infrastructure"
    echo "0. Exit"
    echo ""
}

# Destroy infrastructure
destroy_terraform() {
    print_warning "Are you sure you want to destroy all infrastructure? (yes/no)"
    read -r response
    
    if [ "$response" = "yes" ]; then
        print_status "Destroying infrastructure..."
        terraform destroy
        print_success "Infrastructure destroyed"
    else
        print_status "Destroy cancelled"
    fi
}

# Main script
main() {
    while true; do
        show_menu
        read -rp "Enter your choice: " choice
        
        case $choice in
            1) check_prerequisites ;;
            2) init_terraform ;;
            3) validate_terraform ;;
            4) format_terraform ;;
            5) plan_terraform ;;
            6) apply_terraform ;;
            7) configure_kubectl ;;
            8) verify_cluster ;;
            9) display_outputs ;;
            10)
                check_prerequisites
                init_terraform
                validate_terraform
                format_terraform
                plan_terraform
                apply_terraform
                configure_kubectl
                verify_cluster
                display_outputs
                ;;
            11) destroy_terraform ;;
            0)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
    done
}

# Run main function
main
