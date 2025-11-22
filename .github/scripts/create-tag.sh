#!/bin/bash
# Create and push a git tag
# Usage: create-tag.sh <tag-name> [message]

set -e

TAG_NAME="${1}"
TAG_MESSAGE="${2:-Release $TAG_NAME - Automated release after successful tests}"

if [ -z "$TAG_NAME" ]; then
  echo "Error: Tag name is required"
  exit 1
fi

# Configure git
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

# Create and push tag
git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"
git push origin "$TAG_NAME"

echo "Created and pushed tag: $TAG_NAME"

