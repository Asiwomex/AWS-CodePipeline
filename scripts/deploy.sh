#!/bin/bash


# Define variables from environment
AWS_DEFAULT_REGION="us-east-2"
AWS_ACCOUNT_ID="001526952227"
IMAGE_REPO_NAME="expert" # Adjust to your ECR repository name, use private repo
IMAGE_TAG="latest"
CONTAINER_NAME="my-app"
IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"

# Log in to ECR
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com

# Pull the latest image
docker pull $IMAGE_URI

# Stop and remove the old container if it exists
if [ "$(docker ps -a -q -f name=$CONTAINER_NAME)" ]; then
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME
fi

# Run the new container
docker run -d --name $CONTAINER_NAME -p 8000:8000 $IMAGE_URI



