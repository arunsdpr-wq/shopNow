# ShopNow Infrastructure Composition - Visual Summary

## 🎯 Project Overview at a Glance

```
PROJECT: ShopNow E-Commerce
TYPE: Full-stack MERN application
SCALE: Learning + Production-ready
DEPLOYMENT: AWS EKS Kubernetes
ENVIRONMENTS: Dev, Staging, Production
```

---

## 📊 Requirements Summary Matrix

```
┌──────────────────────┬──────────────────┬──────────────────┬──────────────────┐
│   Component          │   Dev            │   Staging        │   Production     │
├──────────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Kubernetes Version   │ 1.28             │ 1.28             │ 1.28 (LTS)       │
│ Node Type            │ t3.medium (2)    │ t3.large (3)     │ t3.xlarge (4+)   │
│ Total CPU            │ 4 vCPU           │ 6 vCPU           │ 16+ vCPU         │
│ Total Memory         │ 8GB              │ 12GB             │ 32+ GB           │
│ Auto-scaling         │ 1-4 nodes        │ 2-6 nodes        │ 3-10+ nodes      │
│ Database             │ MongoDB (1 node) │ MongoDB (3-node) │ MongoDB (HA)     │
│ Storage              │ 50GB EBS         │ 100GB EBS        │ 200GB+ EBS       │
│ Networking           │ Single VPC       │ Single VPC       │ Multi-AZ VPC     │
│ Monitoring           │ Prometheus       │ Prometheus       │ Enterprise suite │
│ Cost/Month           │ ~$189            │ ~$326            │ ~$811+           │
│ SLA                  │ 95%              │ 99%              │ 99.95%           │
└──────────────────────┴──────────────────┴──────────────────┴──────────────────┘
```

---

## 🏗️ Infrastructure Stack Layers

```
LAYER 1: User & Internet
├─ Users/Browsers
├─ Mobile Clients
├─ Admin Users
└─ API Consumers
        │
        │ HTTPS
        ▼
┌──────────────────────────────────────┐
│ LAYER 2: Edge & DNS                  │
├──────────────────────────────────────┤
│ ├─ AWS Route 53 (DNS)                │
│ ├─ CloudFront (CDN - optional)       │
│ └─ AWS Shield (DDoS Protection)      │
└──────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────┐
│ LAYER 3: Load Balancing              │
├──────────────────────────────────────┤
│ ├─ Network Load Balancer (NLB)       │
│ ├─ NGINX Ingress Controller          │
│ └─ Service Discovery (CoreDNS)       │
└──────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────┐
│ LAYER 4: Container Orchestration     │
├──────────────────────────────────────┤
│ ├─ Amazon EKS (Managed K8s)          │
│ ├─ Kubernetes Control Plane          │
│ ├─ Kubelet (Node Agent)              │
│ └─ Container Runtime (Docker/CRI)    │
└──────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────┐
│ LAYER 5: Workloads & Services        │
├──────────────────────────────────────┤
│ ├─ Frontend Pods (React)             │
│ ├─ Admin Pods (React)                │
│ ├─ Backend Pods (Node.js)            │
│ ├─ MongoDB StatefulSet               │
│ └─ System Pods (monitoring, etc)     │
└──────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────┐
│ LAYER 6: Storage & Data              │
├──────────────────────────────────────┤
│ ├─ EBS Volumes (Persistent)          │
│ ├─ ConfigMaps (Configuration)        │
│ ├─ Secrets (Encrypted Credentials)   │
│ └─ S3 Buckets (Backups)              │
└──────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────┐
│ LAYER 7: Observability               │
├──────────────────────────────────────┤
│ ├─ Prometheus (Metrics)              │
│ ├─ Grafana (Visualization)           │
│ ├─ CloudWatch (Logging)              │
│ └─ AlertManager (Alerting)           │
└──────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────┐
│ LAYER 8: Security & Access           │
├──────────────────────────────────────┤
│ ├─ IAM (Identity Management)         │
│ ├─ RBAC (Role-based Access Control)  │
│ ├─ Network Policies (Pod firewalls)  │
│ ├─ KMS (Encryption Keys)             │
│ └─ Secrets Manager (Credentials)     │
└──────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────┐
│ LAYER 9: Automation & GitOps         │
├──────────────────────────────────────┤
│ ├─ Jenkins (CI/CD Pipelines)         │
│ ├─ ArgoCD (GitOps Automation)        │
│ ├─ Terraform (IaC)                   │
│ └─ Helm (Package Management)         │
└──────────────────────────────────────┘
```

---

## 🔄 Data Flow Architecture

```
┌─────────────────┐
│   User Browser  │
└────────┬────────┘
         │ HTTP/HTTPS
         ▼
┌────────────────────────────┐
│  AWS Route 53 / CloudFront │
└────────┬───────────────────┘
         │ DNS Resolution
         ▼
┌────────────────────────────┐
│   Network Load Balancer    │
│   (Distributes Traffic)    │
└────────┬───────────────────┘
         │ Port 80/443
         ▼
┌────────────────────────────────────────┐
│   NGINX Ingress Controller             │
│   (Layer 7 Routing)                    │
└──┬────────────────┬────────────────────┘
   │ Route /        │ Route /api         │ Route /admin
   │                │                    │
   ▼                ▼                    ▼
┌────────────┐  ┌────────────┐  ┌──────────────┐
│ Frontend   │  │  Backend   │  │   Admin      │
│ Service    │  │  Service   │  │   Service    │
│ (Port 80)  │  │ (Port 5000)│  │  (Port 80)   │
└────┬───────┘  └────┬───────┘  └──────┬───────┘
     │               │                 │
     ▼               ▼                 ▼
 ┌───────┐      ┌────────┐       ┌──────────┐
 │Frontend│      │Backend │       │  Admin   │
 │ Pods   │      │ Pods   │       │   Pods   │
 └───────┘      └────┬───┘       └──────────┘
                     │
                     │ Connect
                     ▼
                ┌──────────────┐
                │   MongoDB    │
                │ StatefulSet  │
                │ (Port 27017) │
                └──────────────┘
                     │
                     │ Persist
                     ▼
                ┌──────────────┐
                │ EBS Volume   │
                │ (50-200GB)   │
                └──────────────┘
```

---

## 🎯 Component Communication Map

```
                           ┌─────────────┐
                           │   Users     │
                           └──────┬──────┘
                                  │
                   ┌──────────────┼──────────────┐
                   │              │              │
                   ▼              ▼              ▼
            ┌─────────────┐ ┌──────────┐ ┌─────────────┐
            │  Frontend   │ │ Admin    │ │   Mobile    │
            │  (Browser)  │ │(Browser) │ │   (REST)    │
            └──────┬──────┘ └────┬─────┘ └──────┬──────┘
                   │             │              │
                   └─────────────┼──────────────┘
                                 │ HTTP/HTTPS
                   ┌─────────────▼──────────────┐
                   │  Ingress Controller (L7)   │
                   │   - Route /               │
                   │   - Route /admin          │
                   │   - Route /api/*          │
                   └─────────────┬──────────────┘
                                 │
                   ┌─────────────┼──────────────┐
                   │             │              │
                   ▼             ▼              ▼
            ┌──────────────┐ ┌──────────┐ ┌──────────────┐
            │Frontend Pod  │ │ Admin    │ │   Backend    │
            │(3000)        │ │ Pod(3001)│ │   Pod(5000)  │
            │(nginx)       │ │(nginx)   │ │   (Node.js)  │
            └──────┬───────┘ └────┬─────┘ └───────┬──────┘
                   │              │              │
                   │ Internal DNS │              │
                   └──────────────┼──────────────┘
                                  │ MongoDB Service
                   ┌──────────────▼──────────────┐
                   │  MongoDB StatefulSet        │
                   │  - mongo-0 (Primary)        │
                   │  - mongo-1 (Secondary)      │
                   │  - mongo-2 (Secondary)      │
                   └──────────────┬──────────────┘
                                  │ Data Persistence
                   ┌──────────────▼──────────────┐
                   │  EBS Persistent Volumes     │
                   │  - mongo-pvc-0              │
                   │  - mongo-pvc-1              │
                   │  - mongo-pvc-2              │
                   └──────────────────────────────┘
```

---

## 🔄 CI/CD Workflow Pipeline

```
Developer Push
     │
     │ git push origin main
     │
     ▼
┌─────────────────────────────────────┐
│  GitHub Webhook Trigger             │
│  └─ Jenkins Pipeline starts         │
└────────────┬────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐  ┌──────────────────────┐
│ CI Pipeline (Build & Test)           │  │ For each component   │
├──────────────────────────────────────┤  │ - frontend           │
│ 1. Checkout code                     │  │ - backend            │
│ 2. Determine image tag (git commit)  │  │ - admin              │
│ 3. Build Docker image                │  │                      │
│ 4. Run unit tests                    │  └──────────────────────┘
│ 5. Scan image for vulnerabilities    │
│ 6. Push to ECR                       │
│ 7. Archive artifacts                 │
└────────────┬────────────────────────┘
             │ SUCCESS
             ▼
┌──────────────────────────────────────┐
│ CD Pipeline (Deploy)                 │
├──────────────────────────────────────┤
│ 1. Trigger (manual or auto)          │
│ 2. Checkout deployment manifests     │
│ 3. Update image tags in Helm values  │
│ 4. Deploy using Helm                 │
│ 5. Wait for rollout completion       │
│ 6. Run health checks                 │
│ 7. Update ArgoCD (optional)          │
└────────────┬────────────────────────┘
             │ DEPLOYED
             ▼
┌──────────────────────────────────────┐
│ ArgoCD Sync (GitOps)                 │
├──────────────────────────────────────┤
│ 1. Monitor Git repository            │
│ 2. Detect changes every 3 minutes    │
│ 3. Compare Git state vs K8s state    │
│ 4. Auto-sync or alert for approval   │
│ 5. Ensure desired state              │
└────────────┬────────────────────────┘
             │
             ▼
    Application Running
```

---

## 📈 Scaling Architecture

```
Application Scaling Hierarchy:

Vertical Scaling (per pod):
┌──────────────────────────────┐
│ Pod Resources (Requests)     │
│ ├─ Frontend: 100m CPU, 128Mi │
│ ├─ Backend:  100m CPU, 200Mi │
│ ├─ Admin:    100m CPU, 128Mi │
│ └─ MongoDB:  200m CPU, 512Mi │
└──────────────────────────────┘
          │
          │ Increase as needed
          ▼
┌──────────────────────────────┐
│ Pod Limits (Max resources)   │
│ ├─ Frontend: 500m CPU, 256Mi │
│ ├─ Backend:  500m CPU, 512Mi │
│ ├─ Admin:    500m CPU, 256Mi │
│ └─ MongoDB:  1000m CPU, 1Gi  │
└──────────────────────────────┘

Horizontal Scaling (more pods):
┌──────────────────────────────┐
│ HPA - Horizontal Pod         │
│ Autoscaler                   │
│ ├─ Metric: CPU/Memory/Custom │
│ ├─ Min replicas: 2-3         │
│ ├─ Max replicas: 5-10        │
│ └─ Target: 70-80% utilization│
└──────────────────────────────┘

Cluster Scaling (more nodes):
┌──────────────────────────────┐
│ Cluster Autoscaler           │
│ ├─ Monitor pod scheduling    │
│ ├─ Add nodes when needed      │
│ ├─ Min nodes: 1-2            │
│ ├─ Max nodes: 4-10+          │
│ └─ Instance types: t3.medium  │
│    to t3.xlarge              │
└──────────────────────────────┘
```

---

## 🔐 Security Zones

```
┌───────────────────────────────────────────────────────┐
│                    Internet                           │
└──────────────────────┬────────────────────────────────┘
                       │ AWS WAF / Shield
                       │ HTTPS only
                       ▼
      ┌────────────────────────────────────┐
      │  Public Zone (DMZ)                 │
      │  ├─ Internet Gateway               │
      │  ├─ NAT Gateways                   │
      │  ├─ Load Balancers                 │
      │  └─ Public Subnets                 │
      └────────────┬───────────────────────┘
                   │ Security Group
                   │ (Inbound: 80, 443)
                   ▼
      ┌────────────────────────────────────┐
      │  Application Zone                  │
      │  ├─ EKS Nodes                      │
      │  ├─ Application Pods               │
      │  ├─ Kubernetes Services            │
      │  ├─ Private Subnets                │
      │  ├─ Network Policies               │
      │  └─ RBAC Control                   │
      └────────────┬───────────────────────┘
                   │ Service SG
                   │ (Pod-to-pod communication)
                   ▼
      ┌────────────────────────────────────┐
      │  Data Zone                         │
      │  ├─ MongoDB Pods                   │
      │  ├─ EBS Volumes                    │
      │  ├─ Persistent Storage             │
      │  ├─ Database SG                    │
      │  └─ Encryption (KMS)               │
      └────────────────────────────────────┘
```

---

## 📊 Resource Allocation Example (Dev)

```
Physical Resources:
┌─────────────────────────────────────────┐
│  EKS Cluster (2 nodes × t3.medium)      │
│  Total: 4 vCPU, 8GB RAM, 100GB Storage  │
└──────────┬──────────────────────────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌─────────┐  ┌─────────┐
│ Node 1  │  │ Node 2  │
│ 2 vCPU  │  │ 2 vCPU  │
│ 4GB RAM │  │ 4GB RAM │
│ 50GB    │  │ 50GB    │
└────┬────┘  └────┬────┘
     │            │
     │ Schedulable Resources (after system allocation)
     │
     ├─ System pods: 10-15%
     ├─ Reserved: 5-10%
     └─ Available for user pods: ~75-80%

Pod Distribution (Example):
Node 1:
  ├─ frontend-1 (100m CPU, 128Mi RAM)
  ├─ backend-1 (100m CPU, 200Mi RAM)
  ├─ admin-1 (100m CPU, 128Mi RAM)
  └─ kube-system pods (shared)

Node 2:
  ├─ frontend-2 (100m CPU, 128Mi RAM)
  ├─ backend-2 (100m CPU, 200Mi RAM)
  ├─ mongo-0 (200m CPU, 512Mi RAM)
  └─ kube-system pods (shared)

Remaining Capacity: ~1.5-2 vCPU, 2-3GB RAM
Ready for: 10-15 additional small pods
```

---

## 💼 Cost Optimization Strategy

```
Cost Optimization Funnel:

Start: $189/month (Dev)
└─ Baseline Infrastructure
   │
   ├─ (Can't reduce further without affecting reliability)
   │
   ▼
Option 1: Use Reserved Instances
   └─ Savings: 30-40%
   └─ New Cost: $113-132/month

Option 2: Use Spot Instances (non-critical)
   └─ Savings: 60-70%
   └─ New Cost: $57-76/month
   └─ Risk: Interruption possible

Option 3: Right-size instances
   └─ Use t3.small instead of t3.medium
   └─ Savings: 40%
   └─ New Cost: $113/month
   └─ Risk: Performance impact

Combined Optimization:
   └─ Reserved t3.small for base + spot for burst
   └─ Total Savings: 50-60%
   └─ Final Cost: $76-95/month
```

---

## ✅ Implementation Phases

```
Phase 1: Foundation (Week 1)
├─ VPC & Network Setup
├─ Security Groups & Policies
├─ EKS Cluster Creation
└─ Node Groups Launch
Duration: 4-6 hours

Phase 2: Kubernetes (Week 2)
├─ Storage Classes Setup
├─ Namespaces Creation
├─ RBAC Configuration
└─ Network Policies
Duration: 2-3 hours

Phase 3: Container Registry (Week 2)
├─ ECR Repositories
├─ Image Scanning
├─ Lifecycle Policies
└─ Repository Policies
Duration: 1 hour

Phase 4: Applications (Week 3)
├─ Push Docker Images
├─ Deploy Backend
├─ Deploy Frontend
└─ Deploy Admin
Duration: 2-3 hours

Phase 5: Monitoring (Week 3)
├─ Prometheus Setup
├─ Grafana Dashboards
├─ CloudWatch Integration
└─ Alert Rules
Duration: 2-3 hours

Phase 6: CI/CD (Week 4)
├─ Jenkins Pipeline Setup
├─ GitHub Integration
├─ ArgoCD Configuration
└─ Test Deployments
Duration: 3-4 hours

Total Implementation Time: 2-4 weeks
```

---

## 📚 Key Takeaways

```
Infrastructure Characteristics:
✓ Cloud-native (AWS EKS)
✓ Containerized (Docker)
✓ Orchestrated (Kubernetes)
✓ Scalable (HPA + Cluster Autoscaler)
✓ Highly available (Multi-AZ)
✓ Secure (RBAC, Network Policies, Encryption)
✓ Observable (Prometheus, Grafana, CloudWatch)
✓ Automated (Jenkins, ArgoCD, Terraform)
✓ Cost-effective (Scaling on demand)
✓ Production-ready (With optimizations)

Learning Value:
→ Real-world cloud architecture patterns
→ Kubernetes at scale
→ Infrastructure as Code (Terraform)
→ CI/CD automation best practices
→ GitOps workflow implementation
→ Security in cloud-native applications
→ Cost optimization strategies
→ Operational excellence
```

---

*This infrastructure composition is designed to be scalable from learning environments*
*to production-grade deployments with enterprise features and reliability.*

*See INFRASTRUCTURE_COMPOSITION.md for detailed technical specifications.*
