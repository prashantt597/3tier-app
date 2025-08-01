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

# Output for EKS cluster security group ID
output "cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = module.eks.cluster_security_group_id
}

# Output the IAM role ARN
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}