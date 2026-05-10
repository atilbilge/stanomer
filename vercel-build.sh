#!/bin/bash

# Exit on error
set -e

echo "--- VERCEL DIAGNOSTIC BUILD START ---"

# Skip root check and optimize for CI
export BOT=true
export FLUTTER_ROOT_CHECK=false

# 1. Environment Check
echo "Step 1: Checking Environment Variables..."
if [ -z "$SUPABASE_URL" ]; then
  echo "Error: SUPABASE_URL is not set!"
  exit 1
fi

# Create .env from Vercel climate variables (Critical for bundling)
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

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

# 4. Configure Flutter for Web & Resolve Dependencies
echo "Step 4: Configuring Web & Resolving Dependencies..."
flutter config --enable-web
flutter pub get

# 5. Build Flutter Web (DIAGNOSTIC MODE)
echo "Step 5: Inspecting Build Options..."
flutter build web -h

echo "Step 6: Building Flutter Web (Basic Release mode)..."
# Temporarily removing --web-renderer to check for baseline success
flutter build web --release --base-href /app/

# 6. Build Next.js Website (Legal Pages)
echo "Step 6: Building Next.js Website..."
cd website
npm install
npm run build
cd ..

# 7. Prepare Public Directory
echo "Step 7: Preparing public directory..."
rm -rf public
mkdir -p public/app

# 8. Final Distribution
echo "Step 8: Copying Assets..."

# Copy landing page files
if [ -d "landing" ]; then
  cp -r landing/* public/
fi

# Copy Next.js static files (privacy, terms, etc.)
if [ -d "website/out" ]; then
  cp -r website/out/* public/
else
  echo "Error: website/out directory not found! Check Next.js build."
  exit 1
fi

# Copy Flutter web build
if [ -d "build/web" ]; then
  cp -r build/web/* public/app/
else
  echo "Error: Flutter web build not found!"
  exit 1
fi

echo "--- VERCEL DIAGNOSTIC BUILD COMPLETE! ---"
