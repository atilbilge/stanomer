#!/bin/bash

# Exit on error
set -e

echo "--- Installing dependencies ---"
yum install -y xz git

echo "--- Downloading Flutter ---"
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PATH:`pwd`/flutter/bin"

echo "--- Flutter Build Web App ---"
# Build with base-href /app/ to allow hosting in sub-directory
flutter build web --release --base-href /app/

echo "--- Preparing Deployment Directory ---"
mkdir -p dist/app

# 1. Copy Landing Page to root
cp -r landing/* dist/

# 2. Copy Flutter App to /app
cp -r build/web/* dist/app/

echo "--- Build Complete ---"
