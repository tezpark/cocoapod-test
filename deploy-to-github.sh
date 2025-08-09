#!/bin/bash

# Deployment script for Sendbird Private Pods
# Run this script after creating GitHub repository

set -e

GITHUB_USERNAME="sendbird"

echo "🚀 Deploying to GitHub..."

# Deploy unified CocoaPods repo (contains everything!)
cd repo/sendbird-cocoapods
git remote add origin https://github.com/$GITHUB_USERNAME/sendbird-cocoapods.git 2>/dev/null || true
git push -u origin main
git push origin --tags

cd ../..

echo "✅ GitHub repository deployed!"
echo ""
echo "📦 Next: Upload XCFramework to GitHub Release"
echo "1. Go to: https://github.com/$GITHUB_USERNAME/sendbird-cocoapods/releases"
echo "2. Click 'Create a new release'"
echo "3. Tag: SendbirdAIAgentCore-v0.10.0"
echo "4. Title: Sendbird AI Agent Core v0.10.0"
echo "5. Upload: release/SendbirdAIAgentCore.xcframework.zip"
echo "6. Publish release"
echo ""
echo "📋 After XCFramework upload, deploy podspecs:"
echo "1. Add private spec repo:"
echo "   pod repo add sendbird-specs https://github.com/$GITHUB_USERNAME/sendbird-cocoapods.git"
echo ""
echo "2. Validate podspecs:"
echo "   pod spec lint repo/sendbird-cocoapods/Sources/NetworkImage/SendbirdNetworkImage.podspec --allow-warnings"
echo "   pod spec lint repo/sendbird-cocoapods/Sources/Splash/SendbirdSplash.podspec --allow-warnings"
echo "   pod spec lint repo/sendbird-cocoapods/Sources/MarkdownUI/SendbirdMarkdownUI.podspec --allow-warnings"  
echo "   pod spec lint repo/sendbird-cocoapods/Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.podspec --allow-warnings"
echo "   pod spec lint repo/sendbird-cocoapods/Sources/SendbirdAIAgentMessenger/SendbirdAIAgentMessenger.podspec --allow-warnings"
echo ""
echo "3. Deploy to private spec repo:"
echo "   pod repo push sendbird-specs repo/sendbird-cocoapods/Sources/NetworkImage/SendbirdNetworkImage.podspec --allow-warnings"
echo "   pod repo push sendbird-specs repo/sendbird-cocoapods/Sources/Splash/SendbirdSplash.podspec --allow-warnings"
echo "   pod repo push sendbird-specs repo/sendbird-cocoapods/Sources/MarkdownUI/SendbirdMarkdownUI.podspec --allow-warnings"
echo "   pod repo push sendbird-specs repo/sendbird-cocoapods/Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.podspec --allow-warnings"
echo "   pod repo push sendbird-specs repo/sendbird-cocoapods/Sources/SendbirdAIAgentMessenger/SendbirdAIAgentMessenger.podspec --allow-warnings"
echo ""
echo "🎉 All done! Your unified private CocoaPods repository is ready!"
echo ""
echo "📱 User Integration (ONLY THIS!):"
echo "   pod 'SendbirdAIAgentMessenger', '~> 0.10.0'"
echo ""
echo "📱 Release Information:"
echo "   - Repository: https://github.com/$GITHUB_USERNAME/sendbird-cocoapods"
echo "   - Main Module: SendbirdAIAgentMessenger v0.10.0"
echo "   - XCFramework: v0.10.0"
echo "   - SHA1: 0b56b290c7cfb362249f3738bd3c10977931d5f5"
echo "   - Release Tag: SendbirdAIAgentCore-v0.10.0"
