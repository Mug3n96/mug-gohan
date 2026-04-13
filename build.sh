#!/bin/bash
set -e

echo "Building Flutter web..."
cd frontend
flutter build web --release

echo "Copying web build to backend/public/..."
cp -r build/web/* ../backend/public/

echo "Building and starting Docker containers..."
cd ..
docker compose up -d --build

echo "Done! Open http://localhost:3000"
