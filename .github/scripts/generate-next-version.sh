#!/bin/bash
# Generate the next version tag based on the latest tag
# Usage: generate-next-version.sh <latest-tag>
# Output: Prints the new tag to stdout and sets GITHUB_OUTPUT

set -e

LATEST_TAG="${1:-v0.0.0}"

# Remove 'v' prefix if present
VERSION="${LATEST_TAG#v}"

# Split version into major.minor.patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# If version parsing failed, default to 0.0.0
if [ -z "$MAJOR" ]; then
  MAJOR=0
  MINOR=0
  PATCH=0
fi

# Increment patch version
PATCH=$((PATCH + 1))

# Create new tag
NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"

# Output for GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
  echo "new_tag=$NEW_TAG" >> "$GITHUB_OUTPUT"
fi

echo "$NEW_TAG"

