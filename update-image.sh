#!/bin/bash
# File: update-image.sh

set -e

# Check parameters
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <app-name> <version>"
    exit 1
fi

APP_NAME=$1
VERSION=$2

echo "Updating $APP_NAME to version $VERSION"

# Update base deployment
sed -i "s|image: ghcr.io/yourorg/$APP_NAME:.*|image: ghcr.io/yourorg/$APP_NAME:$VERSION|g" apps/$APP_NAME/base/deployment.yaml

# Commit the changes
git add apps/$APP_NAME/base/deployment.yaml
git commit -m "Update $APP_NAME image to $VERSION"
git push

echo "Updated $APP_NAME to version $VERSION and pushed changes!"