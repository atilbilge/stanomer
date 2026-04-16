#!/bin/bash

# Exit on error
set -e

echo "--- Starting Stanomer Production Build ---"

# 1. Generate .env file from Vercel Environment Variables
echo "Generating .env file..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
echo ".env file generated successfully."

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
else
  echo "Warning: landing directory not found!"
fi

# 5. Copy Flutter App to /app
echo "Copying Flutter web build to /app..."
cp -r build/web/* dist/app/

# 6. Verify Directory Structure (Diagnostic)
echo "--- Verified Directory Structure ---"
ls -R dist

echo "--- Build Complete! ---"
echo "Deployment directory: dist"
