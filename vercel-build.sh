#!/bin/bash

# Exit on error
set -e

echo "--- VERCEL DUAL BUILD START (/app & /dev-app) ---"

# Skip root check and optimize for CI
export BOT=true
export FLUTTER_ROOT_CHECK=false

# 1. Environment Setup
echo "Step 1: Creating Environment Configuration Files..."

PROD_URL="${VERCEL_PROD_SUPABASE_URL:-https://ustcsvvkzsmsgzbptvpm.supabase.co}"
PROD_KEY="${VERCEL_PROD_SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzdGNzdnZrenNtc2d6YnB0dnBtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMzY1NjIsImV4cCI6MjA5MDkxMjU2Mn0.g1A1GfLrebJ3MnQUaCmr45JGPPAPLU77XtUKP6doA4g}"

DEV_URL="${VERCEL_DEV_SUPABASE_URL:-https://thvbpifahvasyzmngpzp.supabase.co}"
DEV_KEY="${VERCEL_DEV_SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRodmJwaWZhaHZhc3l6bW5ncHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUyNjAxNzcsImV4cCI6MjEwMDgzNjE3N30.dNSz66kJcoSjflgCCrS7qw55efuDxF61TEMoYc3r4qU}"

echo "ENVIRONMENT=prod" > .env.prod
echo "SUPABASE_URL=$PROD_URL" >> .env.prod
echo "SUPABASE_ANON_KEY=$PROD_KEY" >> .env.prod

echo "ENVIRONMENT=dev" > .env.dev
echo "SUPABASE_URL=$DEV_URL" >> .env.dev
echo "SUPABASE_ANON_KEY=$DEV_KEY" >> .env.dev

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
flutter build web --release -t lib/main_prod.dart --base-href /app/ --dart-define=ENVIRONMENT=prod --dart-define=SUPABASE_URL=$PROD_URL --dart-define=SUPABASE_ANON_KEY=$PROD_KEY --dart-define-from-file=.env.prod
mkdir -p build/web_prod
cp -r build/web/* build/web_prod/

# 5. Build Dev Flutter Web (/dev-app/)
echo "Step 5: Building DEV Flutter Web (--base-href /dev-app/)..."
rm -rf build/web
cp .env.dev .env
flutter build web --release -t lib/main_dev.dart --base-href /dev-app/ --dart-define=ENVIRONMENT=dev --dart-define=SUPABASE_URL=$DEV_URL --dart-define=SUPABASE_ANON_KEY=$DEV_KEY --dart-define-from-file=.env.dev
mkdir -p build/web_dev
cp -r build/web/* build/web_dev/

# Copy Flutter web builds into website/public/ for Next.js serving
mkdir -p website/public/app
mkdir -p website/public/dev-app
cp -rf build/web_prod/* website/public/app/
cp -rf build/web_dev/* website/public/dev-app/

# 6. Build Next.js Website & API Routes
echo "Step 6: Building Next.js Website..."
cd website
npm install
NEXT_PUBLIC_SUPABASE_URL="$PROD_URL" NEXT_PUBLIC_SUPABASE_ANON_KEY="$PROD_KEY" npm run build
cd ..

# 7. Prepare Public Directory & Final Distribution
echo "Step 7: Preparing public directory..."
rm -rf public
mkdir -p public/app
mkdir -p public/dev-app
mkdir -p public/assets

# Copy images/media assets
if [ -d "landing/assets" ]; then
  cp -rf landing/assets/* public/assets/
fi

# Copy Production Flutter web build to public/app/
if [ -d "build/web_prod" ]; then
  cp -rf build/web_prod/* public/app/
fi

# Copy Dev Flutter web build to public/dev-app/
if [ -d "build/web_dev" ]; then
  cp -rf build/web_dev/* public/dev-app/
fi

# Copy other website public files (excluding symlinked assets to avoid overwrite conflict)
if [ -d "website/public" ]; then
  for item in website/public/*; do
    name=$(basename "$item")
    if [ "$name" != "assets" ] && [ "$name" != "app" ] && [ "$name" != "dev-app" ]; then
      cp -rf "$item" public/
    fi
  done
fi

echo "--- VERCEL DUAL BUILD COMPLETE! (/app = PROD | /dev-app = DEV) ---"
