# ShopNow Infrastructure Composition Analysis

## Executive Summary

Based on a detailed analysis of the ShopNow e-commerce application, this document outlines the complete infrastructure requirements, architecture design, and resource composition needed to deploy and operate the application across different environments (development, staging, production).

---

## 📋 Part 1: Project Requirements Analysis

### 1.1 Application Components

#### Frontend Application
```
Component: React Customer Interface
├── Technology: React 18.2.0
├── Build Tool: Create React App (react-scripts 5.0.1)
├── Port: 3000
├── Runtime: nginx (alpine)
├── Proxy: http://localhost:5000 (backend)
├── Dependencies:
│   ├── react-dom
│   ├── lucide-react (UI icons)
│   └── react-scripts
└── Features:
    ├── Product browsing
    ├── Shopping cart
    ├── Order placement
    ├── User authentication
    └── Responsive UI
```

#### Admin Dashboard Application
```
Component: React Admin Interface
├── Technology: React 18.2.0
├── Build Tool: Create React App
├── Port: 3001
├── Runtime: nginx (alpine)
├── Proxy: /api/* to backend
├── Features:
    ├── Product management (CRUD)
    ├── Order management
    ├── User management
    ├── Analytics dashboard
    └── System configuration
```

#### Backend API Server
```
Component: Express.js REST API
├── Technology: Node.js 18 + Express 4.18.2
├── Port: 5000
├── Database: MongoDB (Mongoose 7.5.0)
├── Features:
│   ├── /api/products - Product operations
│   ├── /api/users - User authentication & management
│   ├── /api/orders - Order processing
│   ├── /api/health - Health check endpoint
│   └── CORS enabled
├── Dependencies:
│   ├── express
│   ├── mongoose (MongoDB ODM)
│   ├── cors
│   ├── dotenv
│   └── nodemon (dev)
└── Environment Variables:
    ├── MONGODB_URI
    ├── NODE_ENV
    ├── PORT
    └── API endpoints config
```

#### Database
```
Component: MongoDB
├── Type: NoSQL Document Database
├── Port: 27017
├── Version: 6.0
├── Storage: 50GB (development)
├── Replica Set: Yes (for production)
├── Backup: Daily snapshots
├── Collections:
│   ├── users
│   ├── products
│   ├── orders
│   └── inventory
└── Access Control:
    ├── Authentication enabled
    ├── Network isolation
    └── Role-based access
```

### 1.2 Containerization Requirements

```
Docker Images Required:
├── shopnow/frontend
│   ├── Build Stage: node:18-alpine (build React)
│   ├── Runtime Stage: nginx:alpine (serve static)
│   ├── Size: ~50-100MB
│   └── Registry: ECR (AWS)
│
├── shopnow/backend
│   ├── Base Image: node:18-alpine
│   ├── Exposed Ports: 5000
│   ├── Health Check: /api/health
│   ├── Size: ~200-300MB
│   └── Registry: ECR (AWS)
│
└── shopnow/admin
    ├── Build Stage: node:18-alpine
    ├── Runtime Stage: nginx:alpine
    ├── Size: ~50-100MB
    └── Registry: ECR (AWS)

Container Registry:
├── AWS ECR (Elastic Container Registry)
├── Repositories: 3 (frontend, backend, admin)
├── Encryption: KMS
├── Scanning: Vulnerability scanning on push
├── Retention: 30 days for untagged images
├── Replication: Regional backup
└── Access Control: IAM-based
```

### 1.3 Orchestration Requirements

```
Kubernetes Cluster:
├── Type: Amazon EKS (Managed Kubernetes)
├── Version: 1.28
├── Multi-AZ: Yes (2 or more AZs)
├── High Availability: Yes
├── Auto-scaling: Both cluster and pod level
│
├── Node Groups:
│   ├── General Purpose: t3.medium (dev), t3.large (prod)
│   ├── Size: 1-4 nodes (auto-scaling)
│   ├── Disk: 50GB EBS volumes
│   └── AMI: EKS-optimized
│
├── Networking:
│   ├── VPC: 10.0.0.0/16
│   ├── Public Subnets: 2x for NAT/Ingress
│   ├── Private Subnets: 2x for workloads
│   ├── Security Groups: 3 (cluster, nodes, database)
│   └── CIDR Allocation:
│       ├── Public: 10.0.101.0/24, 10.0.102.0/24
│       └── Private: 10.0.1.0/24, 10.0.2.0/24
│
├── Storage:
│   ├── Storage Classes: GP3 EBS (default)
│   ├── Persistent Volumes: For MongoDB
│   ├── ConfigMaps: Application configuration
│   └── Secrets: Credentials & API keys
│
└── Service Discovery:
    ├── DNS: CoreDNS (cluster-local)
    ├── Services: ClusterIP, LoadBalancer
    └── Endpoints: Pod auto-discovery
```

### 1.4 CI/CD Requirements

```
Jenkins (CI/CD Orchestration):
├── Purpose: Automation & build pipeline
├── Pipelines: 6 total (CI + CD for 3 components)
├── Triggers:
│   ├── CI: Git push to main/master
│   ├── CD: Manual or automated post-CI
│   └── Webhooks: GitHub integration
│
├── CI Pipeline (Build & Test):
│   ├── Checkout code from Git
│   ├── Build Docker image
│   ├── Run tests (optional)
│   ├── Push to ECR
│   └── Generate build artifacts
│
└── CD Pipeline (Deploy):
    ├── Pull deployment manifests
    ├── Update image tags
    ├── Deploy with Helm/kubectl
    ├── Run health checks
    └── Verify deployment
```

### 1.5 GitOps Requirements

```
ArgoCD (GitOps Controller):
├── Purpose: Continuous deployment from Git
├── Deployment Model: GitOps (Git is source of truth)
├── Repository: Git (any provider)
├── Application Definitions:
│   ├── Helm Charts in git
│   ├── Kustomize overlays
│   ├── Raw YAML manifests
│   └── Versioning: Git tags/branches
│
├── Sync Policies:
│   ├── Automatic: Enabled with pruning
│   ├── Manual: For sensitive changes
│   ├── Frequency: Every 3 minutes
│   └── Health Assessment: Real-time
│
└── Multi-environment Support:
    ├── Development: Auto-sync
    ├── Staging: Manual approval
    └── Production: Manual approval
```

### 1.6 Monitoring & Logging Requirements

```
Observability Stack:
├── Metrics Collection:
│   ├── Prometheus: Time-series metrics
│   ├── Collection Interval: 30 seconds
│   ├── Retention: 15 days
│   └── Exporters:
│       ├── Node Exporter (nodes)
│       ├── cAdvisor (containers)
│       ├── Kube State Metrics
│       └── Application metrics
│
├── Visualization:
│   ├── Grafana: Dashboards
│   ├── Pre-built dashboards: Kubernetes, applications
│   ├── Alerting: Rules & notifications
│   └── Data source: Prometheus
│
├── Logging:
│   ├── CloudWatch: EKS cluster logs
│   ├── Log Types: API, audit, authenticator, control
│   ├── Retention: 7 days (configurable)
│   ├── Forwarding: CloudWatch Logs Insights
│   └── Application logs: Via pod stdout/stderr
│
└── Distributed Tracing:
    ├── Optional: Jaeger or X-Ray
    ├── Purpose: Request flow tracking
    └── Sampling: 10% of requests
```

### 1.7 Security Requirements

```
Authentication & Authorization:
├── API Security:
│   ├── JWT tokens for user auth
│   ├── CORS configured
│   ├── HTTPS/TLS enforcement
│   └── API rate limiting
│
├── Kubernetes RBAC:
│   ├── Service accounts per component
│   ├── Role bindings (ClusterRole, Role)
│   ├── Network Policies (default deny)
│   └── Pod Security Standards
│
├── Data Encryption:
│   ├── At Rest: KMS encryption
│   │   ├── EKS secrets
│   │   ├── ECR repositories
│   │   ├── EBS volumes
│   │   └── RDS/DocumentDB
│   │
│   └── In Transit:
│       ├── TLS 1.3
│       ├── Service mesh (optional)
│       └── Mutual TLS between services
│
└── Identity & Access:
    ├── IAM Roles for Service Accounts (IRSA)
    ├── OIDC Provider: EKS integration
    ├── Secrets Management: AWS Secrets Manager
    └── Audit Logging: CloudTrail
```

### 1.8 Disaster Recovery & Backup Requirements

```
Backup Strategy:
├── Database Backups:
│   ├── Frequency: Daily automated
│   ├── Retention: 7-30 days
│   ├── Location: S3 (cross-region)
│   └── Type: Full + incremental
│
├── Configuration Backup:
│   ├── Git repositories (source of truth)
│   ├── Terraform state (S3 backend)
│   ├── Kubernetes manifests (versioned)
│   └── Helm charts (versioned)
│
└── Disaster Recovery:
    ├── RTO (Recovery Time Objective): 2 hours
    ├── RPO (Recovery Point Objective): 1 hour
    ├── Backup Regions: Multi-region capable
    └── Failover: Manual/automated (policy-dependent)
```

---

## 🏗️ Part 2: Infrastructure Architecture Design

### 2.1 Overall Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                       Internet                              │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTPS
┌─────────────────────▼───────────────────────────────────────┐
│                  AWS Route 53 (DNS)                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│            AWS CloudFront (CDN - Optional)                  │
│          (Caches static frontend assets)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              AWS Elastic Load Balancer                      │
│            (Network Load Balancer - NLB)                    │
│          (Distributes traffic to Ingress)                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                    AWS VPC (10.0.0.0/16)                    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │         Public Subnets (2 AZs)                      │  │
│  │  ┌──────────────────┐  ┌──────────────────┐        │  │
│  │  │  IGW             │  │  NAT Gateway     │        │  │
│  │  │                  │  │  (HA)            │        │  │
│  │  └──────────────────┘  └──────────────────┘        │  │
│  └─────────────────────────────────────────────────────┘  │
│              │                          │                 │
│  ┌───────────▼──────────────────────────▼──────────┐      │
│  │       NGINX Ingress Controller                  │      │
│  │    (Manages external traffic routing)          │      │
│  └──────────────────┬─────────────────────────────┘      │
│                     │                                     │
│  ┌──────────────────▼─────────────────────────────┐      │
│  │     Private Subnets (2 AZs)                    │      │
│  │                                                │      │
│  │  ┌──────────────────┐  ┌──────────────────┐  │      │
│  │  │  EKS Node 1      │  │  EKS Node 2      │  │      │
│  │  │  (t3.medium)     │  │  (t3.medium)     │  │      │
│  │  │                  │  │                  │  │      │
│  │  │  Pods:           │  │  Pods:           │  │      │
│  │  │  ├─ Frontend     │  │  ├─ Frontend     │  │      │
│  │  │  ├─ Backend      │  │  ├─ Backend      │  │      │
│  │  │  └─ Admin        │  │  └─ Admin        │  │      │
│  │  └──────────────────┘  └──────────────────┘  │      │
│  │                                                │      │
│  │  ┌──────────────────────────────────────────┐ │      │
│  │  │    Kubernetes Services                   │ │      │
│  │  │  ├─ frontend-svc (ClusterIP)            │ │      │
│  │  │  ├─ backend-svc (ClusterIP)             │ │      │
│  │  │  ├─ admin-svc (ClusterIP)               │ │      │
│  │  │  └─ mongo-svc (Headless)                │ │      │
│  │  └──────────────────────────────────────────┘ │      │
│  │                                                │      │
│  │  ┌──────────────────────────────────────────┐ │      │
│  │  │    MongoDB StatefulSet                   │ │      │
│  │  │  ├─ mongo-0 (leader)                    │ │      │
│  │  │  └─ Persistent Volumes (EBS GP3)        │ │      │
│  │  └──────────────────────────────────────────┘ │      │
│  │                                                │      │
│  │  ┌──────────────────────────────────────────┐ │      │
│  │  │    Storage                               │ │      │
│  │  │  ├─ ConfigMaps (app config)              │ │      │
│  │  │  ├─ Secrets (credentials)                │ │      │
│  │  │  └─ Persistent Volumes (databases)       │ │      │
│  │  └──────────────────────────────────────────┘ │      │
│  └──────────────────────────────────────────────┘      │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │    Monitoring Namespace                         │   │
│  │  ├─ Prometheus (metrics collection)             │   │
│  │  ├─ Grafana (dashboards)                        │   │
│  │  ├─ AlertManager                                │   │
│  │  └─ Metrics Server                              │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │    System Namespaces                            │   │
│  │  ├─ kube-system                                 │   │
│  │  ├─ kube-public                                 │   │
│  │  ├─ ingress-nginx                               │   │
│  │  └─ cert-manager (optional)                     │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

External Services:
├── AWS ECR: Container image registry
├── AWS CloudWatch: Logging & monitoring
├── AWS KMS: Encryption key management
├── AWS IAM: Identity & access management
├── Jenkins: CI/CD pipeline orchestration
├── ArgoCD: GitOps deployment automation
├── GitHub: Source code repository
└── AWS Secrets Manager: Credential storage
```

### 2.2 Network Architecture

```
Network Design: Hub-and-Spoke with Internet Gateway

VPC: 10.0.0.0/16
├── Public Subnets (for NAT and Ingress):
│   ├── AZ 1 (us-east-1a): 10.0.101.0/24
│   │   └── Internet Gateway
│   │   └── NAT Gateway
│   │   └── NGINX Ingress Controller (if nodeport exposed)
│   │
│   └── AZ 2 (us-east-1b): 10.0.102.0/24
│       └── Internet Gateway
│       └── NAT Gateway
│       └── NGINX Ingress Controller (if nodeport exposed)
│
├── Private Subnets (for worker nodes):
│   ├── AZ 1 (us-east-1a): 10.0.1.0/24
│   │   └── EKS Nodes
│   │   └── MongoDB Pods
│   │   └── Application Pods
│   │   └── Monitoring Stack
│   │
│   └── AZ 2 (us-east-1b): 10.0.2.0/24
│       └── EKS Nodes
│       └── MongoDB Pods
│       └── Application Pods
│       └── Monitoring Stack
│
├── Security Groups:
│   ├── EKS Cluster SG:
│   │   ├── Ingress: 443 (from nodes)
│   │   ├── Ingress: 80 (from anywhere)
│   │   ├── Ingress: 443 (from anywhere)
│   │   └── Egress: All traffic
│   │
│   ├── EKS Nodes SG:
│   │   ├── Ingress: 0-65535 TCP/UDP (from within VPC)
│   │   ├── Ingress: 443 (from cluster SG)
│   │   └── Egress: All traffic
│   │
│   └── Database SG:
│       ├── Ingress: 27017 (MongoDB, from nodes only)
│       ├── Egress: All traffic
│       └── Isolation: Requires node SG membership
│
└── Network Policies:
    ├── Deny all ingress by default
    ├── Allow from ingress controller
    ├── Allow inter-pod communication (same namespace)
    ├── Allow DNS (port 53)
    └── Allow egress to external services
```

### 2.3 Compute Resources

```
Kubernetes Cluster Compute:

Cluster: shopnow-dev-cluster (or environment-specific)
├── Master Nodes: Managed by AWS (EKS)
│   ├── High availability: Multi-AZ
│   ├── Auto-patched: AWS managed
│   └── Monitoring: Native EKS integration
│
├── Worker Nodes: EC2 Auto Scaling Group
│   ├── Instance Type: t3.medium (dev), t3.large (staging/prod)
│   ├── Root Disk: 50GB GP3 EBS
│   ├── Auto-scaling:
│   │   ├── Min: 1 node
│   │   ├── Desired: 2 nodes (dev), 3+ (prod)
│   │   └── Max: 4 nodes (auto-scaled by metrics)
│   │
│   ├── Node Configuration:
│   │   ├── AMI: EKS-optimized (Linux)
│   │   ├── IAM Role: EKS Node role
│   │   ├── Security Group: Node group SG
│   │   └── Monitoring: CloudWatch Container Insights
│   │
│   └── Scaling Policies:
│       ├── Cluster Autoscaler: Enabled
│       ├── Metrics: CPU, Memory, Pod density
│       ├── Scale-up: When pods can't be scheduled
│       └── Scale-down: After 10 minutes idle
│
├── Pod Resources:
│   ├── Frontend Pod:
│   │   ├── CPU Request: 100m | Limit: 500m
│   │   └── Memory Request: 128Mi | Limit: 256Mi
│   │
│   ├── Backend Pod:
│   │   ├── CPU Request: 100m | Limit: 500m
│   │   └── Memory Request: 200Mi | Limit: 512Mi
│   │
│   ├── Admin Pod:
│   │   ├── CPU Request: 100m | Limit: 500m
│   │   └── Memory Request: 128Mi | Limit: 256Mi
│   │
│   └── MongoDB Pod:
│       ├── CPU Request: 200m | Limit: 1000m
│       └── Memory Request: 512Mi | Limit: 1Gi
│
└── Total Cluster Resources:
    ├── Dev: 2 nodes × 2 vCPU = 4 vCPU, 8GB RAM
    ├── Staging: 3 nodes × 2 vCPU = 6 vCPU, 12GB RAM
    └── Prod: 4+ nodes × 4 vCPU = 16+ vCPU, 32+ GB RAM
```

### 2.4 Storage Architecture

```
Storage Components:

Persistent Storage:
├── MongoDB StatefulSet:
│   ├── Storage Class: gp3-ssd (AWS EBS)
│   ├── Volume Size: 50GB (dev), 100GB+ (prod)
│   ├── Access Mode: ReadWriteOnce
│   ├── Reclaim Policy: Retain (production)
│   ├── Snapshots: Automated daily
│   └── Backup: S3 via AWS Backup
│
├── Application ConfigMaps:
│   ├── backend-config (environment variables)
│   ├── frontend-config (app settings)
│   ├── admin-config (admin settings)
│   └── nginx-config (ingress routing)
│
└── Secrets (Encrypted):
    ├── mongodb-credentials
    ├── api-keys
    ├── jwt-secrets
    └── ecr-pull-credentials

Ephemeral Storage:
├── Container Logs: /var/log/containers/
├── Temp Files: /tmp/ (node ephemeral)
├── Build Cache: Docker layers (ECR)
└── Pod Temp Storage: tmpfs

Object Storage (S3):
├── Backup Buckets:
│   ├── MongoDB backups
│   ├── Application logs (long-term)
│   └── Build artifacts
│
├── Terraform State:
│   ├── S3 backend (encrypted)
│   ├── DynamoDB lock table
│   └── Versioning enabled
│
└── Content Delivery:
    ├── Static assets (if cached)
    └── CloudFront distribution
```

### 2.5 Disaster Recovery Architecture

```
Backup & Recovery Strategy:

Recovery Point Objective (RPO): 1 hour
Recovery Time Objective (RTO): 2-4 hours

Automated Backups:
├── Database (MongoDB):
│   ├── Frequency: Daily at 02:00 UTC
│   ├── Retention: 30 days (production)
│   ├── Location: S3 (cross-region)
│   ├── Method: AWS Backup integration
│   └── Testing: Weekly restore tests
│
├── Configuration:
│   ├── Terraform State: Versioned in S3
│   ├── Helm Charts: Git versioning
│   ├── Kubernetes Manifests: Git versioning
│   └── ArgoCD Config: Git versioning
│
└── Container Images:
    ├── Repository: ECR (automatic versioning)
    ├── Retention: Keep last 10 tagged versions
    ├── Cleanup: Auto-delete untagged after 30 days
    └── Cross-region: Optional replication

Disaster Scenarios & Recovery:

1. Node Failure:
   ├── Detection: Kubernetes detects within 5 minutes
   ├── Action: Pods auto-scheduled to healthy nodes
   ├── Recovery: Auto-replaced node via ASG
   └── Downtime: <5 minutes per node

2. Database Failure:
   ├── Detection: MongoDB replica set health check
   ├── Action: Automatic failover to secondary
   ├── Recovery: Replace failed replica
   └── Downtime: <30 seconds (transparent)

3. Cluster Failure:
   ├── Detection: API server unavailable
   ├── Action: Manual failover to secondary cluster
   ├── Recovery: Restore from backup
   └── Downtime: 30-60 minutes

4. Application Bug:
   ├── Detection: Health check failures
   ├── Action: Automatic rollback via Helm
   ├── Recovery: Helm rollback command
   └── Downtime: <5 minutes

Recovery Procedures:
├── Backup Restore:
│   └─ $ aws backup restore-job --backup-vault-name shopnow --recovery-point-arn <arn>
├── Git Revert:
│   └─ $ git revert <commit-hash> && git push
├── Helm Rollback:
│   └─ $ helm rollback <release> <revision>
└── Terraform Revert:
    └─ $ terraform apply -var-file=<previous.tfvars>
```

---

## 📊 Part 3: Environment-Specific Configurations

### 3.1 Development Environment

```yaml
Environment: Development
Purpose: Learning, experimentation, rapid development

Infrastructure:
  VPC:
    CIDR: 10.0.0.0/16
    AZs: 2 (us-east-1a, us-east-1b)
    
  EKS Cluster:
    Version: 1.28
    Nodes: 2 × t3.medium (2 vCPU, 4GB RAM)
    AutoScaling: Min 1, Max 4
    
  Storage:
    MongoDB: Single node (no replication)
    EBS: 50GB GP3
    Backup: Manual weekly
    
  Monitoring:
    Prometheus: Enabled
    Grafana: Enabled
    Log Retention: 7 days
    
  Cost/Month: ~$166 + data transfer

Configuration Values:
  enable_monitoring: true
  enable_autoscaling: true
  environment: dev
  cluster_version: 1.28
  node_group_desired_size: 2
  log_retention_days: 7
  backup_retention_days: 7
```

### 3.2 Staging Environment

```yaml
Environment: Staging
Purpose: Pre-production testing, load testing, staging deployments

Infrastructure:
  VPC:
    CIDR: 10.0.0.0/16
    AZs: 2 (us-east-1a, us-east-1b, optional: us-east-1c)
    
  EKS Cluster:
    Version: 1.28
    Nodes: 3 × t3.large (2 vCPU, 8GB RAM)
    AutoScaling: Min 2, Max 6
    
  Storage:
    MongoDB: Replica set (3 nodes)
    EBS: 100GB GP3 (encrypted)
    Backup: Daily automated
    
  Monitoring:
    Prometheus: Enabled with 15d retention
    Grafana: Enabled
    Alerts: Enabled
    
  Cost/Month: ~$350 + data transfer

Configuration Values:
  enable_monitoring: true
  enable_autoscaling: true
  environment: staging
  cluster_version: 1.28
  node_group_desired_size: 3
  node_instance_types: [t3.large]
  log_retention_days: 14
  backup_retention_days: 14
```

### 3.3 Production Environment

```yaml
Environment: Production
Purpose: Customer-facing, mission-critical, high availability

Infrastructure:
  VPC:
    CIDR: 10.0.0.0/16
    AZs: 3+ (multi-region capable)
    Private link: Enabled for AWS services
    
  EKS Cluster:
    Version: 1.28 (LTS)
    Nodes: 4-8 × t3.xlarge (4 vCPU, 16GB RAM)
    AutoScaling: Min 3, Max 10+
    HA: Multi-AZ with auto-replacement
    
  Storage:
    MongoDB: Replica set with sharding (3+ nodes)
    EBS: 200GB+ GP3 (encrypted, multi-AZ)
    Backup: Hourly incremental, daily full
    Cross-region: Enabled
    
  Monitoring:
    Prometheus: High-resolution (10s intervals)
    Grafana: Enterprise features
    Alerts: Critical, warning, info levels
    Audit Logging: CloudTrail enabled
    
  Security:
    Network Policy: Strict deny-by-default
    Pod Security: Enforced standards
    RBAC: Fine-grained access control
    Encryption: KMS for all data
    
  Cost/Month: ~$1000+ (varies with load)

Configuration Values:
  enable_monitoring: true
  enable_autoscaling: true
  enable_rds_mongodb: true (optional managed DB)
  environment: prod
  cluster_version: 1.28
  cluster_endpoint_public_access: false (private only)
  node_group_desired_size: 4
  node_group_max_size: 10
  node_instance_types: [t3.xlarge]
  log_retention_days: 90
  backup_retention_days: 30
```

---

## 🔄 Part 4: CI/CD & Deployment Pipeline

### 4.1 CI/CD Architecture

```
Source Control (GitHub)
        │
        ├─── Push to main
        │
        ▼
┌─────────────────────────────┐
│   Jenkins CI Pipeline       │
├─────────────────────────────┤
│ 1. Trigger (Webhook)        │
│ 2. Checkout Code            │
│ 3. Set Image Tag (commit)   │
│ 4. Build Docker Image       │
│ 5. Run Tests                │
│ 6. Push to ECR              │
│ 7. Generate Artifacts       │
└─────────────────────────────┘
        │
        ├─── Success
        │
        ▼
┌─────────────────────────────┐
│   Jenkins CD Pipeline       │
├─────────────────────────────┤
│ 1. Trigger (Manual/Auto)    │
│ 2. Get Image Tag            │
│ 3. Update Helm Values       │
│ 4. Deploy with Helm         │
│ 5. Run Health Checks        │
│ 6. Update ArgoCD (optional) │
└─────────────────────────────┘
        │
        ├─── Deployed
        │
        ▼
┌─────────────────────────────┐
│   ArgoCD Sync               │
├─────────────────────────────┤
│ 1. Monitor Git Repo         │
│ 2. Detect Changes           │
│ 3. Sync Kubernetes State    │
│ 4. Ensure Desired State     │
│ 5. Alert on Drift           │
└─────────────────────────────┘
        │
        │
        ▼
    Kubernetes Cluster
    (Applications Running)
```

### 4.2 GitOps Workflow

```
Git Repository (Source of Truth)
├── kubernetes/
│   ├── k8s-manifests/
│   │   ├── backend/
│   │   ├── frontend/
│   │   ├── admin/
│   │   └── database/
│   └── helm/
│       ├── charts/backend/
│       ├── charts/frontend/
│       ├── charts/admin/
│       └── values-{env}.yaml
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
│
└── .argocd/
    └── applications/
        ├── shopnow-backend.yaml
        ├── shopnow-frontend.yaml
        ├── shopnow-admin.yaml
        └── shopnow-database.yaml

ArgoCD Applications:
├── Dev Environment:
│   ├── Auto-sync: Enabled
│   ├── Values: values-dev.yaml
│   └── Namespace: shopnow-dev
│
├── Staging Environment:
│   ├── Auto-sync: Disabled (manual approval)
│   ├── Values: values-staging.yaml
│   └── Namespace: shopnow-staging
│
└── Production Environment:
    ├── Auto-sync: Disabled (manual approval)
    ├── Values: values-prod.yaml
    └── Namespace: shopnow-prod

Sync Strategy:
├── Automatic (Dev):
│   ├── Detect: Every 3 minutes
│   ├── Action: Auto-apply changes
│   ├── Pruning: Delete resources not in Git
│   └── Self-healing: Enabled
│
└── Manual (Staging/Prod):
    ├── Detect: Every 3 minutes
    ├── Action: Wait for manual approval
    ├── Dry-run: Available before sync
    └── Rollback: One-click to previous state
```

---

## 🔐 Part 5: Security Architecture

### 5.1 Security Layers

```
Layer 1: Network Security
├── VPC: Isolated network environment
├── Public/Private Subnets: Segregated traffic
├── Security Groups: Stateful firewall
├── Network Policies: Kubernetes level (pod-to-pod)
└── NLB: DDoS protection via AWS Shield

Layer 2: Identity & Access (IAM)
├── EKS Node Role: Permission to pull from ECR
├── Service Account IRSA: Pod-to-AWS service access
├── RBAC: Kubernetes role-based access
├── Pod Security Standards: Container restrictions
└── OIDC Provider: OpenID Connect integration

Layer 3: Data Encryption
├── At Rest:
│   ├── EKS Secrets: KMS encryption
│   ├── EBS Volumes: KMS encryption
│   ├── RDS/DocumentDB: KMS encryption
│   └── S3 Backups: KMS encryption
│
└── In Transit:
    ├── TLS 1.3: HTTPS/gRPC
    ├── Service Mesh: Optional mTLS
    └── VPN: For administrative access

Layer 4: Secrets Management
├── Kubernetes Secrets: Encrypted with KMS
├── AWS Secrets Manager: Long-term credentials
├── Environment Variables: Injected at runtime
└── Rotation: Automated where possible

Layer 5: Audit & Logging
├── CloudTrail: AWS API calls
├── CloudWatch Logs: Application logs
├── EKS Audit Log: Kubernetes API calls
├── VPC Flow Logs: Network traffic (optional)
└── Pod Logs: Via kubectl logs / CloudWatch
```

### 5.2 RBAC Configuration

```
Service Accounts & Roles:

Backend Service Account:
├── Permissions:
│   ├── Read MongoDB (Kubernetes secret)
│   ├── Write to ConfigMaps (app settings)
│   └── Access CloudWatch for metrics
├── AWS Permissions:
│   ├── Pull from ECR (shopnow/backend)
│   ├── Write CloudWatch logs
│   └── Access Secrets Manager (optional)

Frontend Service Account:
├── Permissions:
│   ├── Read ConfigMaps
│   └── Read Secrets (if needed)
├── AWS Permissions:
│   ├── Pull from ECR (shopnow/frontend)
│   └── Write CloudWatch logs

Cluster Admin Role:
├── Permissions: Full (restricted to ops team)
├── Duration: Time-limited sessions
└── Audit: All actions logged

Read-Only Developer Role:
├── Permissions: View-only access
├── Resources: Can view pods, logs, services
├── Restrictions: Cannot modify or delete
```

---

## 📈 Part 6: Scaling & Performance

### 6.1 Horizontal Pod Autoscaling (HPA)

```
Backend API Autoscaling:
├── Metric: CPU utilization
├── Target: 70% CPU usage
├── Min Replicas: 2
├── Max Replicas: 10
├── Scale-up: Add 1 pod per minute (max 4 at once)
├── Scale-down: Remove 1 pod every 5 minutes
└── Cooldown: 3 minutes

Frontend App Autoscaling:
├── Metric: CPU + Request count
├── Target: 80% CPU or 1000 req/s per pod
├── Min Replicas: 2
├── Max Replicas: 5
└── Scale-up: Add 1 pod per 2 minutes

Admin Dashboard Autoscaling:
├── Metric: Memory utilization
├── Target: 80% memory
├── Min Replicas: 1
├── Max Replicas: 3
└── Scale-down: Every 10 minutes
```

### 6.2 Vertical Pod Autoscaling (VPA)

```
Optional (Recommender Mode):
├── Backend:
│   ├── Current: 100m CPU, 200Mi Memory
│   ├── Recommended: 150m CPU, 300Mi Memory
│   └── Action: Manual approval before scaling
│
├── Frontend:
│   ├── Current: 100m CPU, 128Mi Memory
│   ├── Recommended: 120m CPU, 200Mi Memory
│   └── Action: Auto-scale (low risk)
│
└── MongoDB:
    ├── Current: 200m CPU, 512Mi Memory
    ├── Recommended: 300m CPU, 1Gi Memory
    └── Action: Manual approval (stateful)
```

### 6.3 Cluster Autoscaling

```
Node Scaling Policies:

Scale-Up Triggers:
├── Pod pending (cannot schedule): Immediately
├── Available node capacity < 10%: Within 1 minute
└── Node CPU util > 90%: Within 5 minutes

Scale-Down Triggers:
├── Node CPU util < 50% for 10 min: Mark for deletion
├── Node memory util < 50%: Mark for deletion
├── All pods can be rescheduled: Delete node
└── Node has system pods: Don't delete

Auto Scaling Group Limits:
├── Minimum: 1 node (dev), 2 nodes (prod)
├── Maximum: 4 nodes (dev), 10+ nodes (prod)
├── Desired: 2 nodes (dev), 3-4 nodes (prod)
└── Update Strategy: Rolling (max 1 node at a time)
```

---

## 💰 Part 7: Cost Analysis & Optimization

### 7.1 Cost Breakdown (Monthly)

```
Development Environment:
├── EKS Control Plane: $0.10/hour = $73/month
├── EC2 Nodes (2 × t3.medium): $0.0416/hour = $61/month
├── NAT Gateways (2): $0.045/hour = $32/month
├── EBS Volumes: $0.10/GB = $5/month (50GB)
├── ECR Storage: ~$0.10/GB = $3/month
├── CloudWatch Logs: ~$10/month (7 days retention)
├── Data Transfer: ~$5/month (minimal)
└── Total: ~$189/month

Staging Environment:
├── EKS Control Plane: $73/month
├── EC2 Nodes (3 × t3.large): $0.0832/hour = $183/month
├── NAT Gateways (2): $32/month
├── EBS Volumes: $0.10/GB = $10/month (100GB)
├── ECR Storage: $3/month
├── CloudWatch: $15/month (14 days retention)
├── Data Transfer: $10/month
└── Total: ~$326/month

Production Environment:
├── EKS Control Plane: $73/month
├── EC2 Nodes (4 × t3.xlarge): $0.1664/hour = $489/month
├── NAT Gateways (3): $48/month
├── NLB Load Balancer: $16/month
├── EBS Volumes: $0.10/GB = $20/month (200GB)
├── ECR Storage: $5/month
├── CloudWatch: $30/month (90 days retention)
├── Data Transfer: $30/month (variable)
├── RDS/DocumentDB (optional): $100-300/month
└── Total: ~$811/month (without RDS)

Grand Total (All Environments): ~$1,326/month
```

### 7.2 Cost Optimization Strategies

```
Short-term Optimizations:
├── Use Reserved Instances: 30-40% savings
├── Use Spot Instances: 70% savings (non-critical)
├── Right-size instances: Monitor utilization
├── Consolidate workloads: Reduce nodes
└── Delete unused resources: Regular cleanup

Medium-term Optimizations:
├── Use ARM instances (Graviton2): 20% cheaper
├── Enable auto-scaling: Pay for what you use
├── Implement resource quotas: Prevent overspend
├── Use managed services: Reduce operational overhead
└── Optimize container images: Smaller = faster deploys

Long-term Optimizations:
├── Multi-region deployment: Cheaper regions
├── Infrastructure as Code: Standardization
├── Cost monitoring: CloudWatch billing alerts
├── Capacity planning: Right-size infrastructure
└── Vendor negotiation: Volume discounts

Estimated Savings Potential: 40-60% with optimizations
```

---

## 📋 Part 8: Implementation Checklist

### 8.1 Pre-Deployment Checklist

```
☐ AWS Account Setup
  ☐ Account created and verified
  ☐ Billing alerts configured
  ☐ IAM user with appropriate permissions
  ☐ AWS CLI configured locally
  ☐ MFA enabled for root account

☐ Developer Environment
  ☐ Terraform installed (>= 1.0)
  ☐ kubectl installed (>= 1.24)
  ☐ Helm installed (>= 3.0)
  ☐ Docker installed (for local testing)
  ☐ Git configured

☐ Repository Setup
  ☐ Git repository cloned
  ☐ Terraform code reviewed
  ☐ Kubernetes manifests reviewed
  ☐ Jenkins pipeline code reviewed
  ☐ ArgoCD configuration prepared

☐ AWS Quotas
  ☐ EC2 instance quota: Min 10 (for scaling)
  ☐ VPC quota: Min 5
  ☐ EBS volume quota: Min 20
  ☐ ECR repository quota: Min 3
  ☐ NAT Gateway quota: Min 3
```

### 8.2 Deployment Checklist

```
☐ Phase 1: Network Infrastructure
  ☐ VPC created with correct CIDR
  ☐ Public subnets created (2 AZs)
  ☐ Private subnets created (2 AZs)
  ☐ Internet Gateway attached
  ☐ NAT Gateways created
  ☐ Route tables configured
  ☐ Security groups created

☐ Phase 2: Kubernetes Cluster
  ☐ EKS cluster created
  ☐ IAM roles created (cluster + nodes)
  ☐ Node groups created and healthy
  ☐ Add-ons installed (VPC CNI, CoreDNS, etc)
  ☐ Storage classes created
  ☐ OIDC provider configured

☐ Phase 3: Container Registry
  ☐ ECR repositories created (frontend, backend, admin)
  ☐ Repository policies configured
  ☐ Image scanning enabled
  ☐ Lifecycle policies configured
  ☐ KMS encryption enabled

☐ Phase 4: Kubernetes Applications
  ☐ Namespaces created
  ☐ ConfigMaps created
  ☐ Secrets created
  ☐ Service accounts created (IRSA)
  ☐ Network policies created
  ☐ RBAC roles configured

☐ Phase 5: Monitoring & Logging
  ☐ Prometheus installed
  ☐ Grafana installed
  ☐ CloudWatch logs configured
  ☐ Dashboards created
  ☐ Alerting rules configured

☐ Phase 6: CI/CD Setup
  ☐ Jenkins installed/configured
  ☐ Pipelines created (CI for each component)
  ☐ ECR push permissions enabled
  ☐ Kubernetes deploy permissions enabled
  ☐ GitHub webhooks configured
  ☐ ArgoCD installed (optional)
```

### 8.3 Post-Deployment Validation

```
☐ Infrastructure Validation
  ☐ kubectl get nodes: All nodes running
  ☐ kubectl get pods -A: All pods healthy
  ☐ kubectl get svc -A: All services created
  ☐ kubectl get ingress: Ingress configured
  ☐ Security groups verified
  ☐ Network policies tested

☐ Application Deployment
  ☐ Frontend pod running
  ☐ Backend pod running
  ☐ Admin pod running
  ☐ MongoDB pod running
  ☐ All replicas healthy

☐ Connectivity Testing
  ☐ Frontend → Backend API (via proxy)
  ☐ Backend → MongoDB (via service)
  ☐ External → Frontend (via Ingress)
  ☐ Health check endpoints responding
  ☐ Prometheus scraping metrics

☐ Security Testing
  ☐ Network policies working
  ☐ RBAC enforced
  ☐ Secrets encrypted
  ☐ Images scanned
  ☐ Audit logging active

☐ Backup & Recovery
  ☐ Database backups scheduled
  ☐ Backup restore tested
  ☐ Terraform state backed up
  ☐ Git history available
  ☐ Recovery procedures documented

☐ Monitoring & Alerting
  ☐ Grafana dashboards created
  ☐ Alerts configured (critical items)
  ☐ Log aggregation working
  ☐ Metrics collection active
  ☐ Team notification channels set up
```

---

## 📚 Part 9: References & Resources

### 9.1 Official Documentation

- **AWS EKS**: https://docs.aws.amazon.com/eks/
- **Kubernetes**: https://kubernetes.io/docs/
- **Terraform AWS**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Helm**: https://helm.sh/docs/
- **Jenkins**: https://www.jenkins.io/doc/
- **ArgoCD**: https://argo-cd.readthedocs.io/

### 9.2 Key Technologies

| Technology | Version | Purpose |
|-----------|---------|---------|
| Kubernetes | 1.28 | Container orchestration |
| Docker | 20.10+ | Container runtime |
| Helm | 3.0+ | Package manager for K8s |
| Terraform | 1.0+ | Infrastructure as Code |
| AWS EKS | Latest | Managed Kubernetes |
| MongoDB | 6.0 | NoSQL database |
| Node.js | 18 | Backend runtime |
| React | 18.2.0 | Frontend framework |
| Jenkins | 2.4+ | CI/CD orchestration |
| ArgoCD | 2.8+ | GitOps automation |
| Prometheus | 2.40+ | Metrics collection |
| Grafana | 9.0+ | Visualization |

---

## ✅ Summary

This infrastructure composition analysis provides:

1. **Comprehensive Requirements Analysis**: Understanding of every component and its needs
2. **Detailed Architecture Design**: Network, compute, storage, security, and operational layers
3. **Environment-Specific Configs**: Dev, staging, and production configurations
4. **CI/CD Pipeline Design**: Jenkins and ArgoCD integration
5. **Security Architecture**: Multi-layer security approach
6. **Scaling Strategy**: Horizontal and vertical autoscaling
7. **Cost Analysis**: Transparent cost breakdown and optimization
8. **Implementation Checklist**: Step-by-step deployment guide
9. **Validation Procedures**: Post-deployment verification

**This forms the foundation for the Terraform infrastructure already generated.**

---

*Document prepared based on ShopNow e-commerce application requirements*
*Last updated: May 22, 2026*
