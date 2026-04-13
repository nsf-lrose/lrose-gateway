#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

usage() {
    echo "Usage: $0 <image-name> --tag <tag> [--push]"
    echo "  <image-name>  Name of the Docker image to build"
    echo "  --tag <tag>   Tag for the Docker image to build"
    echo "  --push        Optionally push the Docker image to DockerHub"
    exit 1
}

if [ -z "$1" ]; then
    echo "Error: No image name provided."
    usage
fi

IMAGE_NAME=$1
PUSH_IMAGE=false

shift

while [[ $# > 0 ]]
do
    key="$1"
    case $key in
        --tag)
            TAG="$2"
            shift # past argument
            ;;
        --push)
            PUSH_IMAGE="true"
            ;;
    esac
    shift # past argument or value
done

FULL_TAG="nfslrose/$IMAGE_NAME:$TAG"

# Build the Docker image
echo "Building Docker image with tag: $FULL_TAG"
docker build --no-cache --pull --tag "$FULL_TAG" .

echo "Docker image built successfully: $FULL_TAG"

if $PUSH_IMAGE; then
    echo "Pushing Docker image to DockerHub: $FULL_TAG"
    docker push "$FULL_TAG"
    echo "Docker image pushed successfully: $FULL_TAG"
else
    echo "Skipping Docker image push. Use '--push' to push the image."
fi

exit 0
