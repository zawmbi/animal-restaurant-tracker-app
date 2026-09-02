#!/bin/bash
# First iOS release build -> build/ios/ipa/*.ipa
# Expect 5-10 min on the first run while CocoaPods compiles.

set -e
cd /Users/linda/Coding/animal-restaurant-tracker-app

echo "==> Flutter version"
flutter --version

echo
echo "==> Fetching packages"
flutter pub get

echo
echo "==> Building IPA (release)"
flutter build ipa --release --build-name=1.0.0 --build-number=1

echo
echo "==> Done. Output:"
ls -lh build/ios/ipa/*.ipa
