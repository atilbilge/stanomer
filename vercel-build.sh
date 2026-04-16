#!/bin/bash

# Exit on error
set -e

echo "--- VERCEL BUILD START (V5 - Ultimate) ---"

# 1. Environment Check
echo "Step 1: Checking Environment Variables..."
if [ -z "$SUPABASE_URL" ]; then
  echo "Error: SUPABASE_URL is not set!"
  exit 1
fi
echo "Environment check passed."

# 2. Generate .env file
echo "Step 2: Generating .env file..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
echo ".env file generated."

# 3. Build Flutter Web
echo "Step 3: Building Flutter Web for /app..."
flutter build web --release --base-href /app/

# 4. Prepare Public Directory (Standard Vercel Output)
echo "Step 4: Preparing public directory..."
rm -rf public
mkdir -p public/app

# 5. Distribute Files
echo "Step 5: Copying Landing Page to root..."
if [ -d "landing" ]; then
  cp -v -r landing/* public/
else
  echo "Critical Error: landing directory not found!"
  exit 1
fi

echo "Step 6: Copying Flutter App to /app folder..."
if [ -d "build/web" ]; then
  cp -v -r build/web/* public/app/
else
  echo "Critical Error: build/web directory not found!"
  exit 1
fi

# 6. Final Diagnostic Listing
echo "Step 7: Verifying Final Directory Structure..."
echo "--- PUBLIC ROOT ---"
ls -F public/
echo "--- PUBLIC APP FOLDER ---"
ls -F public/app/ | head -n 10

echo "--- VERCEL BUILD END ---"
echo "Output Directory: public"
