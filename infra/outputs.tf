# Output for EKS cluster endpoint
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

# Output for EKS cluster name
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}