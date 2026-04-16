#!/bin/bash

# Exit on error
set -e

echo "--- Starting Stanomer Production Build (V4 - Radical) ---"

# 1. Generate .env file from Vercel Environment Variables
echo "Generating .env file..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

# 2. Build Flutter Web for the /app sub-path
echo "Building Flutter Web..."
flutter build web --release --base-href /app/

# 3. Create deployment directory (dist)
echo "Preparing distribution directory..."
rm -rf dist
mkdir -p dist/app

# 4. Copy Landing Page to root (/)
if [ -d "landing" ]; then
  echo "Copying landing page..."
  cp -r landing/* dist/
fi

# 5. Copy Flutter App Assets to /app/ and entry point to root as app.html
echo "Copying Flutter files..."
# Copy all assets to /app folder (so base-href /app/ works)
cp -r build/web/* dist/app/
# Copy index.html to root as app.html to avoid folder conflict
cp build/web/index.html dist/app.html

# 6. Verify Directory Structure (Diagnostic)
echo "--- Verified Directory Structure ---"
ls -F dist/
ls -F dist/app/ | head -n 10

echo "--- Build Complete! ---"
echo "Root index.html: Landing Page"
echo "Root app.html: Flutter App Entry"
echo "Folder /app/: Flutter Assets"
