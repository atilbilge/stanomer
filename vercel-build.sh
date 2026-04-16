#!/bin/bash

# Exit on error
set -e

echo "--- VERCEL FINAL DEPLOYMENT START ---"

# 1. Environment Check
echo "Step 1: Checking Environment Variables..."
if [ -z "$SUPABASE_URL" ]; then
  echo "Error: SUPABASE_URL is not set!"
  exit 1
fi

# 2. FLUTTER SDK INSTALLATION
echo "Step 2: Installing Flutter SDK..."
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi
export PATH="$PATH:$(pwd)/flutter/bin"
flutter --version

# 3. Configure Flutter for Web
echo "Step 3: Configuring Flutter for Web..."
flutter config --enable-web

# 4. Generate .env file
echo "Step 4: Generating .env file..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

# 5. Build Flutter Web
echo "Step 5: Building Flutter Web for /app sub-path..."
flutter build web --release --base-href /app/

# 6. Prepare Public Directory
echo "Step 6: Preparing public directory..."
rm -rf public
mkdir -p public/app

# 7. Final Distribution
echo "Step 7: Copying Landing Page to root..."
cp -r landing/* public/

echo "Step 8: Copying Flutter App to /app folder..."
cp -r build/web/* public/app/

# 8. Diagnostic Listing
echo "Step 9: Final Directory Structure..."
ls -F public/
ls -F public/app/ | head -n 5

echo "--- VERCEL FINAL DEPLOYMENT COMPLETE! ---"
