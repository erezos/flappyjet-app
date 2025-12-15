#!/bin/bash

# 🔧 Fix gcloud PATH Script
# 
# Adds gcloud to PATH for current session

export PATH="/Users/erezk/Projects/FlappyJet/y/google-cloud-sdk/bin:$PATH"

echo "✅ gcloud added to PATH"
echo ""
echo "Now you can run:"
echo "  gcloud auth login"
echo "  gcloud init"
echo ""
echo "Or restart your terminal to make it permanent"

