#!/bin/sh

# Function to print help and manage arguments
eval $(
    zz_args "Import a Docker Hub image into AWS ECR" $0 "$@" <<-help
        r region     region      AWS region (default is the AWS CLI configured region)
        a account    account     AWS account id (default is the current AWS CLI caller's account)
        n name       repository  ECR repository name (default is the Docker Hub image name)
        u user       dockerhub   Docker Hub username
        - image      image       Docker Hub image name
        - tag        tag         Docker Hub image tag (default is 'latest')
help
)

region="${region:-$(aws configure get region)}"
account="${account:-$(aws sts get-caller-identity --query Account --output text)}"
repository="${repository:-$image}"
tag="${tag:-latest}"
ecr_registry="$account.dkr.ecr.$region.amazonaws.com"

# Authenticate Docker to AWS ECR
zz_log i "Authenticating Docker to $ecr_registry"
aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$ecr_registry"

# Check if repository exists, if not, create it
if aws ecr describe-repositories --region "$region" --repository-names "$repository" >/dev/null 2>&1; then
    zz_log i "ECR repository already exists: $repository"
else
    zz_log i "Creating ECR repository: $repository"
    aws ecr create-repository --region "$region" --repository-name "$repository"
fi

# Pull Docker image from Docker Hub
zz_log i "Pulling $dockerhub/$image:$tag from Docker Hub"
docker pull "$dockerhub/$image:$tag"

# Tag Docker image for AWS ECR
ecr_image="$ecr_registry/$repository:$tag"
docker tag "$dockerhub/$image:$tag" "$ecr_image"

# Push Docker image to AWS ECR
zz_log i "Pushing $ecr_image to AWS ECR"
docker push "$ecr_image"

zz_log i "Docker image pushed to AWS ECR repository: $ecr_image"
