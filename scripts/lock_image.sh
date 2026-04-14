#!/usr/bin/env bash
set -e

IMAGE_NAME="mergen-core:1.0.0"
LOCK_FILE="image.lock"

echo "Building image..."
docker build --platform linux/amd64 -t $IMAGE_NAME .

echo "Extracting digest..."

DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $IMAGE_NAME)

if [ -z "$DIGEST" ]; then
  echo "Digest extraction failed"
  exit 1
fi

echo "Locked image:"
echo $DIGEST

echo $DIGEST > $LOCK_FILE

echo "Image digest locked in $LOCK_FILE"

