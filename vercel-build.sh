#!/bin/bash

# Exit on error
set -e

echo "--- VERCEL BUILD START (FLUTTER SDK INJECTION) ---"

# 1. Environment Check
echo "Step 1: Checking Environment Variables..."
if [ -z "$SUPABASE_URL" ]; then
  echo "Error: SUPABASE_URL is not set! Please add it to Vercel Environment Variables."
  exit 1
fi

# 2. FLUTTER SDK INSTALLATION (The Game Changer)
echo "Step 2: Installing Flutter SDK..."
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter stable branch..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter SDK already exists, skipping clone."
fi

# Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

echo "Verifying Flutter installation..."
flutter --version

# 3. Configure Flutter for Web
echo "Step 3: Configuring Flutter for Web..."
flutter config --enable-web

# 4. Generate .env file
echo "Step 4: Generating .env file..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
echo ".env file generated."

# 5. Build Flutter Web
echo "Step 5: Building Flutter Web for /app sub-path..."
flutter build web --release --base-href /app/

# 6. Prepare Public Directory (Standard Vercel Output)
echo "Step 6: Preparing public directory..."
rm -rf public
mkdir -p public/app

# 7. Distribute Files
echo "Step 7: Copying Landing Page to root..."
if [ -d "landing" ]; then
  cp -r landing/* public/
else
  echo "Error: landing directory not found!"
  exit 1
fi

echo "Step 8: Copying Flutter App to /app folder..."
if [ -d "build/web" ]; then
  cp -r build/web/* public/app/
else
  echo "Error: build/web directory not found after build!"
  exit 1
fi

# 8. Final Diagnostic Listing
echo "Step 9: Verifying Final Directory Structure..."
ls -F public/
ls -F public/app/ | head -n 10

echo "--- VERCEL BUILD END ---"
