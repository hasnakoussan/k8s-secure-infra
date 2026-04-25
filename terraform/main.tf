terraform {
  required_version = ">= 1.0"
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "main" {
  name            = var.cluster_name
  wait_for_ready  = true
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        <<-EOT
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        EOT
      ]
      extra_port_mappings {
        container_port = 80
        host_port      = 8080
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 8443
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = kind_cluster.main.endpoint
    client_certificate     = kind_cluster.main.client_certificate
    client_key             = kind_cluster.main.client_key
    cluster_ca_certificate = kind_cluster.main.cluster_ca_certificate
  }
}
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.3.11"
  namespace        = "argocd"
  create_namespace = true
  wait             = true

  values = [
    file("${path.module}/../helm/values/argocd-values.yaml")
  ]

  depends_on = [kind_cluster.main]
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.1"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = true

  values = [
    <<-EOT
    controller:
      hostNetwork: true
      kind: DaemonSet
      service:
        type: NodePort
      nodeSelector:
        ingress-ready: "true"
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          operator: Equal
          effect: NoSchedule
      resources:
        requests:
          cpu: 50m
          memory: 64Mi
    EOT
  ]

  depends_on = [kind_cluster.main]
}

resource "helm_release" "falco" {
  name             = "falco"
  repository       = "https://falcosecurity.github.io/charts"
  chart            = "falco"
  version          = "8.0.2"
  namespace        = "falco"
  create_namespace = true
  wait             = false
  timeout          = 600

  values = [
    file("${path.module}/../helm/values/falco-values.yaml")
  ]

  depends_on = [kind_cluster.main]
}
