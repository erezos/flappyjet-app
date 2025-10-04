#!/bin/bash

# FlappyJet Release Environment Setup Script
# This script sets up secure environment variables for release builds

echo "🔐 Setting up FlappyJet release environment..."

# Check if keystore exists
KEYSTORE_PATH="$HOME/.android/keystores/flappyjet-release-key.jks"
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "❌ Error: Keystore not found at $KEYSTORE_PATH"
    echo "Please ensure the keystore is properly placed in the secure location."
    exit 1
fi

# Prompt for keystore passwords (these will be stored in environment for this session)
echo "🔑 Please enter your keystore passwords:"
read -s -p "Store Password: " STORE_PASSWORD
echo
read -s -p "Key Password: " KEY_PASSWORD
echo

# Export environment variables for this session
export STORE_PASSWORD="$STORE_PASSWORD"
export KEY_PASSWORD="$KEY_PASSWORD"

echo "✅ Environment variables set for this session"
echo "📝 To make these permanent, add to your shell profile:"
echo "   export STORE_PASSWORD='your_store_password'"
echo "   export KEY_PASSWORD='your_key_password'"
echo ""
echo "🚀 You can now run: flutter build apk --release"