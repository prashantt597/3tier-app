region      = "ap-south-1"
vpc_cidr    = "10.0.0.0/16"
cluster_name = "3tier-eks"
node_count  = 2
account_id  = "765455500374" # Replace with your AWS account ID
image_repository = "docker.io/${{ secrets.DOCKERHUB_USERNAME }}/3tier-app"
image_tag   = "latest"