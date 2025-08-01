output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}

# Temporarily comment out if ALB is not fully configured yet
# output "alb_dns" {
#   value = aws_lb.alb.dns_name
# }

# Add s3_prefix output
output "s3_prefix" {
  value = random_string.s3_prefix.result
}