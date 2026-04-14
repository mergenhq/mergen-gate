#!/usr/bin/env bash
set -e

LOCK_FILE="image.lock"

if [ ! -f "$LOCK_FILE" ]; then
  echo "No image.lock found"
  exit 1
fi

DIGEST=$(cat $LOCK_FILE)

echo "Deploying locked image:"
echo $DIGEST

docker run --rm $DIGEST

