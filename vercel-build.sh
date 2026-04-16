#!/bin/bash

# Exit on error
set -e

echo "--- VERCEL DIAGNOSTIC BUILD START ---"
echo "Bypassing Flutter build to isolate 404 issues..."

# 1. Prepare Public Directory (Standard Vercel Output)
echo "Preparing public directory..."
rm -rf public
mkdir -p public

# 2. Copy ONLY Landing Page
if [ -d "landing" ]; then
  echo "Copying Landing Page to public root..."
  cp -v -r landing/* public/
else
  echo "Critical Error: landing directory not found!"
  exit 1
fi

# 3. Create a test file to verify server access
echo "Stanomer Diagnostics Active" > public/status.txt

# 4. Diagnostic Listing
echo "--- FINAL DIRECTORY STRUCTURE ---"
ls -R public

echo "--- VERCEL DIAGNOSTIC BUILD END ---"
