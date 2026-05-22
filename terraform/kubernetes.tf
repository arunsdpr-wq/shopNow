# Kubernetes namespace for ShopNow application
resource "kubernetes_namespace" "shopnow" {
  depends_on = [module.eks]

  metadata {
    name = "shopnow"
    labels = {
      name        = "shopnow"
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# Kubernetes namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  depends_on = [module.eks]

  metadata {
    name = "monitoring"
    labels = {
      name       = "monitoring"
      managed-by = "terraform"
    }
  }
}

# RBAC - Create service account for ShopNow backend
resource "kubernetes_service_account" "shopnow_backend" {
  depends_on = [kubernetes_namespace.shopnow]

  metadata {
    name      = "shopnow-backend"
    namespace = kubernetes_namespace.shopnow.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.oidc_provider_role.arn
    }
  }
}

# Create a namespace for cert-manager (optional, for HTTPS)
resource "kubernetes_namespace" "cert_manager" {
  depends_on = [module.eks]

  metadata {
    name = "cert-manager"
    labels = {
      name       = "cert-manager"
      managed-by = "terraform"
    }
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "shopnow_config" {
  depends_on = [kubernetes_namespace.shopnow]

  metadata {
    name      = "shopnow-config"
    namespace = kubernetes_namespace.shopnow.metadata[0].name
  }

  data = {
    ENVIRONMENT         = var.environment
    PROJECT_NAME        = var.project_name
    AWS_REGION          = var.aws_region
    AWS_ACCOUNT_ID      = data.aws_caller_identity.current.account_id
    ECR_REGISTRY        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  }
}

# Secret for ECR credentials (created for service account)
resource "kubernetes_secret" "ecr_credentials" {
  depends_on = [kubernetes_namespace.shopnow]

  metadata {
    name      = "ecr-credentials"
    namespace = kubernetes_namespace.shopnow.metadata[0].name
  }

  type = "kubernetes.io/dockercfg"

  data = {
    ".dockercfg" = jsonencode({
      "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com" = {
        auth = base64encode("AWS:${data.aws_ecr_authorization_token.token.authorization_token}")
      }
    })
  }
}

# Get ECR authorization token
data "aws_ecr_authorization_token" "token" {}

# Default NetworkPolicy (restrict ingress by default)
resource "kubernetes_network_policy" "default_deny" {
  depends_on = [kubernetes_namespace.shopnow]

  metadata {
    name      = "default-deny-ingress"
    namespace = kubernetes_namespace.shopnow.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

# Allow ingress from ingress controller
resource "kubernetes_network_policy" "allow_ingress" {
  depends_on = [kubernetes_namespace.shopnow]

  metadata {
    name      = "allow-ingress"
    namespace = kubernetes_namespace.shopnow.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        "allow-ingress" = "true"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "name" = "ingress-nginx"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

# Pod Disruption Budget for Backend
resource "kubernetes_pod_disruption_budget_v1" "backend_pdb" {
  depends_on = [kubernetes_namespace.shopnow]

  metadata {
    name      = "backend-pdb"
    namespace = kubernetes_namespace.shopnow.metadata[0].name
  }

  spec {
    min_available = 1
    selector {
      match_labels = {
        app = "backend"
      }
    }
  }
}

# Pod Disruption Budget for Frontend
resource "kubernetes_pod_disruption_budget_v1" "frontend_pdb" {
  depends_on = [kubernetes_namespace.shopnow]

  metadata {
    name      = "frontend-pdb"
    namespace = kubernetes_namespace.shopnow.metadata[0].name
  }

  spec {
    min_available = 1
    selector {
      match_labels = {
        app = "frontend"
      }
    }
  }
}

# Resource Quota for the namespace
resource "kubernetes_resource_quota" "shopnow" {
  depends_on = [kubernetes_namespace.shopnow]

  metadata {
    name      = "shopnow-quota"
    namespace = kubernetes_namespace.shopnow.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"              = "10"
      "requests.memory"           = "20Gi"
      "limits.cpu"                = "20"
      "limits.memory"             = "40Gi"
      "persistentvolumeclaims"    = "10"
      "pods"                      = "100"
      "services"                  = "10"
      "services.loadbalancers"    = "2"
    }

    scope_selector {
      match_expression {
        operator       = "In"
        scope_name     = "PriorityClass"
        values         = ["high", "medium"]
      }
    }
  }
}

# Network Policy for inter-pod communication
resource "kubernetes_network_policy" "allow_inter_pod" {
  depends_on = [kubernetes_namespace.shopnow]

  metadata {
    name      = "allow-inter-pod"
    namespace = kubernetes_namespace.shopnow.metadata[0].name
  }

  spec {
    pod_selector {}

    ingress {
      from {
        pod_selector {}
      }
    }

    policy_types = ["Ingress"]
  }
}
