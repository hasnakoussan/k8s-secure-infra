output "cluster_name" {
  value = kind_cluster.main.name
}

output "cluster_endpoint" {
  value = kind_cluster.main.endpoint
}

output "kubeconfig_path" {
  value = kind_cluster.main.kubeconfig_path
}
