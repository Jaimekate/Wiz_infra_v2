module "alb_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = ">= 5.0"

  name                                  = "${var.name}-alb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Name = "${var.name}-alb-controller"
  }
}

# Temporarily disabled - deploy after nodes are ready
# resource "helm_release" "alb_controller" {
#   ...
# }

resource "kubernetes_namespace_v1" "tasky" {
  metadata {
    name = "tasky"
  }
}

resource "kubernetes_secret_v1" "tasky_env" {
  metadata {
    name      = "tasky-env"
    namespace = kubernetes_namespace_v1.tasky.metadata[0].name
  }
  data = {
    MONGODB_URI = "mongodb://${var.mongo_username}:${var.mongo_password}@${aws_instance.mongo.private_ip}:27017/admin?authSource=admin"
    SECRET_KEY  = var.jwt_secret_key
  }
}

resource "kubernetes_service_account_v1" "tasky_sa" {
  metadata {
    name      = "tasky-sa"
    namespace = kubernetes_namespace_v1.tasky.metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding_v1" "tasky_cluster_admin" {
  metadata {
    name = "tasky-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.tasky_sa.metadata[0].name
    namespace = kubernetes_namespace_v1.tasky.metadata[0].name
  }
}

resource "kubernetes_deployment_v1" "tasky" {
  metadata {
    name      = "tasky"
    namespace = kubernetes_namespace_v1.tasky.metadata[0].name
    labels = {
      app = "tasky"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "tasky"
      }
    }
    template {
      metadata {
        labels = {
          app = "tasky"
        }
      }
      spec {
        service_account_name = kubernetes_service_account_v1.tasky_sa.metadata[0].name
        container {
          name  = "tasky"
          image = var.app_image
          port {
            container_port = 8080
          }

          env {
            name = "MONGODB_URI"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.tasky_env.metadata[0].name
                key  = "MONGODB_URI"
              }
            }
          }

          env {
            name = "SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.tasky_env.metadata[0].name
                key  = "SECRET_KEY"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [module.eks_blueprints_addons]
}

resource "kubernetes_service_v1" "tasky" {
  metadata {
    name      = "tasky-svc"
    namespace = kubernetes_namespace_v1.tasky.metadata[0].name
  }
  spec {
    selector = {
      app = "tasky"
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "tasky" {
  metadata {
    name      = "tasky-ingress"
    namespace = kubernetes_namespace_v1.tasky.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.tasky.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [module.eks_blueprints_addons]
}