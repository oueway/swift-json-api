#!/bin/bash
# Check if a tag already exists locally or remotely
# Usage: check-tag-exists.sh <tag-name>
# Exit code: 0 if exists, 1 if not exists
# Also sets GITHUB_OUTPUT with tag_exists=true/false

TAG_NAME="${1}"

if [ -z "$TAG_NAME" ]; then
  echo "Error: Tag name is required" >&2
  exit 1
fi

# Check if tag exists locally or remotely
if git rev-parse "$TAG_NAME" >/dev/null 2>&1 || \
   git ls-remote --tags origin "$TAG_NAME" 2>/dev/null | grep -q "$TAG_NAME"; then
  echo "Tag $TAG_NAME already exists"
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "tag_exists=true" >> "$GITHUB_OUTPUT"
  fi
  exit 0
else
  echo "Tag $TAG_NAME does not exist"
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "tag_exists=false" >> "$GITHUB_OUTPUT"
  fi
  exit 1
fi

