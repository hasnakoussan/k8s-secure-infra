variable "cluster_name" {
  description = "Nom du cluster kind"
  type        = string
  default     = "secure-cluster"
}

variable "environment" {
  description = "Environnement (local / staging / prod)"
  type        = string
  default     = "local"
}
