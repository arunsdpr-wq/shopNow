# Helm Charts Installation

# Install NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "4.8.3"

  create_namespace = true

  values = [
    yamlencode({
      controller = {
        replicaCount = 2
        
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
          }
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "200Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }

        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [
                      {
                        key      = "app.kubernetes.io/name"
                        operator = "In"
                        values   = ["ingress-nginx"]
                      }
                    ]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }
            ]
          }
        }
      }

      defaultBackend = {
        enabled = true
      }
    })
  ]

  depends_on = [module.eks]
}

# Install Prometheus for monitoring (optional)
resource "helm_release" "prometheus" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "25.3.1"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "7d"
          resources = {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring
  ]
}

# Install Grafana for visualization (optional)
resource "helm_release" "grafana" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "7.0.8"

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.storageClassName"
    value = "gp3-ssd"
  }

  set {
    name  = "persistence.size"
    value = "5Gi"
  }

  values = [
    yamlencode({
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring,
    helm_release.prometheus
  ]
}

# Install Metrics Server for HPA
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.11.0"

  values = [
    yamlencode({
      args = [
        "--kubelet-insecure-tls",
        "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
      ]
    })
  ]

  depends_on = [module.eks]
}

# Install Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.34.1"

  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = module.eks.cluster_name
        enabled     = true
      }

      awsRegion = var.aws_region

      rbac = {
        serviceAccount = {
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler[0].arn
          }
        }
      }

      extraArgs = {
        "balance-similar-node-groups"   = true
        "skip-nodes-with-system-pods"   = false
      }

      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    aws_iam_role.cluster_autoscaler
  ]
}
