#!/bin/bash

# Script to setup CocoaPods and initialize the Flutter project for macOS

echo "Installing CocoaPods..."
sudo gem install cocoapods

echo ""
echo "Initializing CocoaPods for the project..."
cd "$(dirname "$0")/macos"
pod install

echo ""
echo "Setup complete! You can now run: flutter run -d macos --dart-define=ANALYZE_API_URL=https://mockapi.example.com/analyze"
