#!/bin/bash

# Exit on error
set -e

echo "--- VERCEL PATH PRIORITY BUILD START ---"

# Skip root check and optimize for CI
export BOT=true
export FLUTTER_ROOT_CHECK=false

# 1. Environment Check
echo "Step 1: Checking Environment Variables..."
if [ -z "$SUPABASE_URL" ]; then
  echo "Error: SUPABASE_URL is not set!"
  exit 1
fi

# 2. FLUTTER SDK INSTALLATION
echo "Step 2: Ensuring Flutter SDK..."
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter stable branch..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter SDK exists."
fi

# PREPEND PATH to ensure our version is used over system defaults
export PATH="$(pwd)/flutter/bin:$PATH"

# Diagnostic check
echo "Flutter Binary Location: $(which flutter)"
flutter --version

# 3. Environment Cleanup (Critical for low memory builds)
echo "Step 3: Cleaning Environment..."
flutter clean
rm -rf build/

# 4. Configure Flutter for Web
echo "Step 4: Configuring Flutter for Web..."
flutter config --enable-web

# 5. Build Flutter Web (STABILIZED CLI)
echo "Step 5: Building Flutter Web (Verified Path mode)..."
flutter build web --web-renderer html --release --base-href /app/

# 6. Prepare Public Directory
echo "Step 6: Preparing public directory..."
rm -rf public
mkdir -p public/app

# 7. Final Distribution
echo "Step 7: Copying Assets..."
cp -r landing/* public/
cp -r build/web/* public/app/

echo "--- VERCEL PATH PRIORITY BUILD COMPLETE! ---"
