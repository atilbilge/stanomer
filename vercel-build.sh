#!/bin/bash

# Exit on error
set -e

echo "--- VERCEL DUAL BUILD START (/app & /dev-app) ---"

# Skip root check and optimize for CI
export BOT=true
export FLUTTER_ROOT_CHECK=false

# 1. Environment Check & Setup
echo "Step 1: Checking Environment Configuration Files..."

# Only overwrite .env.prod if VERCEL_PROD_SUPABASE_URL is specifically provided
if [ -n "$VERCEL_PROD_SUPABASE_URL" ]; then
  echo "Overwriting .env.prod with Vercel Production Environment Variables..."
  echo "ENVIRONMENT=prod" > .env.prod
  echo "SUPABASE_URL=$VERCEL_PROD_SUPABASE_URL" >> .env.prod
  echo "SUPABASE_ANON_KEY=$VERCEL_PROD_SUPABASE_ANON_KEY" >> .env.prod
fi

# Only overwrite .env.dev if VERCEL_DEV_SUPABASE_URL is specifically provided
if [ -n "$VERCEL_DEV_SUPABASE_URL" ]; then
  echo "Overwriting .env.dev with Vercel Dev Environment Variables..."
  echo "ENVIRONMENT=dev" > .env.dev
  echo "SUPABASE_URL=$VERCEL_DEV_SUPABASE_URL" >> .env.dev
  echo "SUPABASE_ANON_KEY=$VERCEL_DEV_SUPABASE_ANON_KEY" >> .env.dev
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

# 3. Configure Flutter for Web & Resolve Dependencies
echo "Step 3: Configuring Web & Resolving Dependencies..."
flutter config --enable-web
flutter pub get

# 4. Build Production Flutter Web (/app/)
echo "Step 4: Building PRODUCTION Flutter Web (--base-href /app/)..."
flutter clean
rm -rf build/
cp .env.prod .env
flutter build web --release -t lib/main.dart --base-href /app/ --dart-define-from-file=.env.prod
mkdir -p build/web_prod
cp -r build/web/* build/web_prod/

# 5. Build Dev Flutter Web (/dev-app/)
echo "Step 5: Building DEV Flutter Web (--base-href /dev-app/)..."
rm -rf build/web
cp .env.dev .env
flutter build web --release -t lib/main_dev.dart --base-href /dev-app/ --dart-define-from-file=.env.dev
mkdir -p build/web_dev
cp -r build/web/* build/web_dev/

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
mkdir -p public/dev-app

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

# Copy Production Flutter web build
if [ -d "build/web_prod" ]; then
  cp -r build/web_prod/* public/app/
else
  echo "Error: Production Flutter web build not found!"
  exit 1
fi

# Copy Dev Flutter web build
if [ -d "build/web_dev" ]; then
  cp -r build/web_dev/* public/dev-app/
else
  echo "Error: Dev Flutter web build not found!"
  exit 1
fi

echo "--- VERCEL DUAL BUILD COMPLETE! (/app = PROD | /dev-app = DEV) ---"
