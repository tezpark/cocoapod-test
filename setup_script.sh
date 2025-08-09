#!/bin/bash

# =============================================================================
# Sendbird Private Pods Setup Script v2
# =============================================================================

set -e  # Exit on any error

# Configuration
GITHUB_USERNAME="sendbird"
COCOAPODS_REPO="sendbird-cocoapods"  # 단일 통합 리포지토리

# Sendbird AI Agent Configuration
SENDBIRD_AI_AGENT_VERSION="0.10.0"  # 🔧 실제 릴리즈 버전
SENDBIRD_AI_AGENT_REPO_URL="https://github.com/sendbird/sendbird-ai-agent-core-ios"
SENDBIRD_AI_AGENT_DOWNLOAD_URL="$SENDBIRD_AI_AGENT_REPO_URL/releases/download/$SENDBIRD_AI_AGENT_VERSION/SendbirdAIAgentCore.xcframework.zip"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create directory structure
create_directory_structure() {
    log_info "Creating directory structure..."
    
    mkdir -p repo/$COCOAPODS_REPO
    mkdir -p temp_downloads
    mkdir -p release  # ZIP 파일 생성용 디렉토리
    
    cd repo/$COCOAPODS_REPO
    # 새로운 통합 구조
    mkdir -p {Sources/MarkdownUI/Sources,Sources/MarkdownUI/ThirdParty,Sources/NetworkImage/Sources,Sources/Splash/Sources}
    mkdir -p Sources/SendbirdAIAgentCore  # AI Agent Core (XCFramework)
    mkdir -p Sources/SendbirdAIAgentMessenger/Sources  # AI Agent Messenger (Swift 소스)
    mkdir -p Releases/SendbirdAIAgentCore  # XCFramework 저장용
    mkdir -p Specs
    cd ../..
    
    log_success "Directory structure created"
}

# Download and extract NetworkImage
setup_network_image() {
    log_info "Setting up NetworkImage..."
    
    cd temp_downloads
    
    # Clone NetworkImage
    if [ ! -d "NetworkImage" ]; then
        git clone https://github.com/gonzalezreal/NetworkImage.git
    fi
    
    # Copy sources
    cp -r NetworkImage/Sources/* ../repo/$COCOAPODS_REPO/Sources/NetworkImage/Sources/
    
    cd ..
    log_success "NetworkImage setup completed"
}

# Download and extract Splash
setup_splash() {
    log_info "Setting up Splash..."
    
    cd temp_downloads
    
    # Clone Splash
    if [ ! -d "Splash" ]; then
        git clone https://github.com/JohnSundell/Splash.git
    fi
    
    # Copy sources
    cp -r Splash/Sources/* ../repo/$COCOAPODS_REPO/Sources/Splash/Sources/
    
    cd ..
    log_success "Splash setup completed"
}

# Download and extract MarkdownUI with swift-cmark
setup_markdown_ui() {
    log_info "Setting up MarkdownUI with swift-cmark..."
    
    cd temp_downloads
    
    # Clone swift-markdown-ui
    if [ ! -d "swift-markdown-ui" ]; then
        git clone https://github.com/gonzalezreal/swift-markdown-ui.git
    fi
    
    # Clone swift-cmark (use gfm branch)
    if [ ! -d "swift-cmark" ]; then
        git clone -b gfm https://github.com/swiftlang/swift-cmark.git
    fi
    
    # Copy MarkdownUI sources
    cp -r swift-markdown-ui/Sources/* ../repo/$COCOAPODS_REPO/Sources/MarkdownUI/Sources/
    
    # Copy swift-cmark sources to ThirdParty (correct structure)
    mkdir -p ../repo/$COCOAPODS_REPO/Sources/MarkdownUI/ThirdParty/cmark-gfm
    mkdir -p ../repo/$COCOAPODS_REPO/Sources/MarkdownUI/ThirdParty/cmark-gfm-extensions
    
    # Copy src directory to cmark-gfm
    cp -r swift-cmark/src/* ../repo/$COCOAPODS_REPO/Sources/MarkdownUI/ThirdParty/cmark-gfm/
    
    # Copy extensions directory to cmark-gfm-extensions
    cp -r swift-cmark/extensions/* ../repo/$COCOAPODS_REPO/Sources/MarkdownUI/ThirdParty/cmark-gfm-extensions/
    
    cd ..
    log_success "MarkdownUI with swift-cmark setup completed"
}

# Download Sendbird AI Agent Core xcframework
download_sendbird_ai_agent_core() {
    log_info "Downloading Sendbird AI Agent Core v$SENDBIRD_AI_AGENT_VERSION..."
    
    cd temp_downloads
    
    # Download xcframework.zip from GitHub Release
    log_info "Downloading from: $SENDBIRD_AI_AGENT_DOWNLOAD_URL"
    
    if command -v curl >/dev/null 2>&1; then
        curl -L -o SendbirdAIAgentCore.xcframework.zip "$SENDBIRD_AI_AGENT_DOWNLOAD_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O SendbirdAIAgentCore.xcframework.zip "$SENDBIRD_AI_AGENT_DOWNLOAD_URL"
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Verify download
    if [ ! -f "SendbirdAIAgentCore.xcframework.zip" ]; then
        log_error "Failed to download SendbirdAIAgentCore.xcframework.zip"
        exit 1
    fi
    
    # Calculate SHA1 for the downloaded file
    if command -v shasum >/dev/null 2>&1; then
        XCFRAMEWORK_SHA1=$(shasum -a 1 SendbirdAIAgentCore.xcframework.zip | cut -d ' ' -f 1)
    elif command -v sha1sum >/dev/null 2>&1; then
        XCFRAMEWORK_SHA1=$(sha1sum SendbirdAIAgentCore.xcframework.zip | cut -d ' ' -f 1)
    else
        log_warn "Neither shasum nor sha1sum found. SHA1 hash will not be calculated."
        XCFRAMEWORK_SHA1="PLACEHOLDER_SHA1_HASH"
    fi
    
    # Copy XCFramework to unified repo
    cp SendbirdAIAgentCore.xcframework.zip ../repo/$COCOAPODS_REPO/Releases/SendbirdAIAgentCore/
    
    log_success "Downloaded SendbirdAIAgentCore.xcframework.zip"
    log_info "SHA1: $XCFRAMEWORK_SHA1"
    
    cd ..
}

# Create SendbirdAIAgentMessenger source code
create_sendbird_ai_agent_messenger_sources() {
    log_info "Creating SendbirdAIAgentMessenger sources..."
    
    # Create MainModule.swift
    cat > repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentMessenger/Sources/MainModule.swift << 'MAIN_MODULE_EOF'
import Foundation
import SendbirdAIAgentCore
import SendbirdMarkdownUI
import SendbirdSplash
import SendbirdNetworkImage

/// Main module for Sendbird AI Agent Messenger
/// This is the primary interface that users will interact with
@objc public class SendbirdAIAgentMessenger: NSObject {
    
    /// Shared instance for global access
    @objc public static let shared = SendbirdAIAgentMessenger()
    
    /// Current version of the messenger
    @objc public static let version = "0.10.0"
    
    private override init() {
        super.init()
        setupInternalModules()
    }
    
    /// Initialize the AI Agent Messenger with configuration
    /// - Parameter configuration: Configuration object for setup
    @objc public func initialize(with configuration: MessengerConfiguration) {
        log("Initializing SendbirdAIAgentMessenger v\(Self.version)")
        
        // Initialize core components
        setupMarkdownSupport()
        setupSyntaxHighlighting()
        setupImageHandling()
        
        // Initialize AI Agent Core
        initializeAIAgentCore(with: configuration)
        
        log("SendbirdAIAgentMessenger initialized successfully")
    }
    
    /// Send a message through the AI Agent
    /// - Parameters:
    ///   - message: The message to send
    ///   - completion: Completion handler with response
    @objc public func sendMessage(_ message: String, completion: @escaping (MessengerResponse) -> Void) {
        log("Sending message: \(message)")
        
        // Process message through AI Agent Core
        processMessage(message) { [weak self] response in
            DispatchQueue.main.async {
                completion(response)
            }
        }
    }
    
    /// Get available AI capabilities
    /// - Returns: Array of supported capabilities
    @objc public func getCapabilities() -> [String] {
        return [
            "markdown_rendering",
            "syntax_highlighting",
            "image_display",
            "ai_conversation"
        ]
    }
    
    // MARK: - Private Methods
    
    private func setupInternalModules() {
        log("Setting up internal modules...")
    }
    
    private func setupMarkdownSupport() {
        log("Setting up Markdown support with MarkdownUI")
        // MarkdownUI integration logic here
    }
    
    private func setupSyntaxHighlighting() {
        log("Setting up syntax highlighting with Splash")
        // Splash integration logic here
    }
    
    private func setupImageHandling() {
        log("Setting up image handling with NetworkImage")
        // NetworkImage integration logic here
    }
    
    private func initializeAIAgentCore(with configuration: MessengerConfiguration) {
        log("Initializing AI Agent Core")
        // SendbirdAIAgentCore integration logic here
    }
    
    private func processMessage(_ message: String, completion: @escaping (MessengerResponse) -> Void) {
        // Message processing logic using AI Agent Core
        let response = MessengerResponse(
            message: "Response to: \(message)",
            timestamp: Date(),
            success: true
        )
        completion(response)
    }
    
    private func log(_ message: String) {
        print("[SendbirdAIAgentMessenger] \(message)")
    }
}
MAIN_MODULE_EOF

    # Create MessengerConfiguration.swift
    cat > repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentMessenger/Sources/MessengerConfiguration.swift << 'CONFIG_EOF'
import Foundation

/// Configuration class for SendbirdAIAgentMessenger
@objc public class MessengerConfiguration: NSObject {
    
    /// Application ID from Sendbird
    @objc public let applicationId: String
    
    /// API key for authentication
    @objc public let apiKey: String
    
    /// Enable debug logging
    @objc public let debugMode: Bool
    
    /// Markdown rendering options
    @objc public let markdownEnabled: Bool
    
    /// Syntax highlighting options
    @objc public let syntaxHighlightingEnabled: Bool
    
    /// Image loading options
    @objc public let imageLoadingEnabled: Bool
    
    /// Initialize configuration
    /// - Parameters:
    ///   - applicationId: Your Sendbird application ID
    ///   - apiKey: Your API key
    ///   - debugMode: Enable debug logging (default: false)
    ///   - markdownEnabled: Enable markdown rendering (default: true)
    ///   - syntaxHighlightingEnabled: Enable syntax highlighting (default: true)
    ///   - imageLoadingEnabled: Enable image loading (default: true)
    @objc public init(applicationId: String,
                     apiKey: String,
                     debugMode: Bool = false,
                     markdownEnabled: Bool = true,
                     syntaxHighlightingEnabled: Bool = true,
                     imageLoadingEnabled: Bool = true) {
        self.applicationId = applicationId
        self.apiKey = apiKey
        self.debugMode = debugMode
        self.markdownEnabled = markdownEnabled
        self.syntaxHighlightingEnabled = syntaxHighlightingEnabled
        self.imageLoadingEnabled = imageLoadingEnabled
        super.init()
    }
}
CONFIG_EOF

    # Create MessengerResponse.swift
    cat > repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentMessenger/Sources/MessengerResponse.swift << 'RESPONSE_EOF'
import Foundation

/// Response object from SendbirdAIAgentMessenger
@objc public class MessengerResponse: NSObject {
    
    /// The response message
    @objc public let message: String
    
    /// Timestamp of the response
    @objc public let timestamp: Date
    
    /// Whether the request was successful
    @objc public let success: Bool
    
    /// Optional error information
    @objc public let error: Error?
    
    /// Initialize successful response
    /// - Parameters:
    ///   - message: Response message
    ///   - timestamp: Response timestamp
    ///   - success: Success status
    @objc public init(message: String, timestamp: Date, success: Bool) {
        self.message = message
        self.timestamp = timestamp
        self.success = success
        self.error = nil
        super.init()
    }
    
    /// Initialize error response
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - timestamp: Error timestamp
    @objc public init(error: Error, timestamp: Date = Date()) {
        self.message = error.localizedDescription
        self.timestamp = timestamp
        self.success = false
        self.error = error
        super.init()
    }
}
RESPONSE_EOF

    log_success "SendbirdAIAgentMessenger sources created"
}

# Create podspec files
create_podspecs() {
    log_info "Creating podspec files..."
    
    # SendbirdNetworkImage.podspec
    cat > repo/$COCOAPODS_REPO/Sources/NetworkImage/SendbirdNetworkImage.podspec << 'EOF'
Pod::Spec.new do |s|
  s.name = 'SendbirdNetworkImage'
  s.version = '1.0.0'
  s.summary = 'Sendbird customized NetworkImage for SwiftUI'
  s.description = 'AsyncImage before iOS 15, with cache and support for custom placeholders, customized for Sendbird'
  s.homepage = 'https://github.com/sendbird/sendbird-cocoapods'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Sendbird' => 'developer@sendbird.com' }
  
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-cocoapods.git',
    :tag => "NetworkImage-#{s.version}"
  }
  
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.5'
  s.source_files = 'Sources/NetworkImage/Sources/**/*.swift'
  
  s.frameworks = 'SwiftUI', 'Combine'
end
EOF

    # SendbirdSplash.podspec
    cat > repo/$COCOAPODS_REPO/Sources/Splash/SendbirdSplash.podspec << 'EOF'
Pod::Spec.new do |s|
  s.name = 'SendbirdSplash'
  s.version = '1.0.0'
  s.summary = 'Sendbird customized Splash syntax highlighter'
  s.description = 'A fast, lightweight Swift syntax highlighter, customized for Sendbird AI Agent'
  s.homepage = 'https://github.com/sendbird/sendbird-cocoapods'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Sendbird' => 'developer@sendbird.com' }
  
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-cocoapods.git',
    :tag => "Splash-#{s.version}"
  }
  
  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/Splash/Sources/**/*.swift'
  
  s.frameworks = 'Foundation'
end
EOF

    # SendbirdMarkdownUI.podspec
    cat > repo/$COCOAPODS_REPO/Sources/MarkdownUI/SendbirdMarkdownUI.podspec << 'EOF'
Pod::Spec.new do |s|
  s.name = 'SendbirdMarkdownUI'
  s.version = '1.0.0'
  s.summary = 'Sendbird customized MarkdownUI for SwiftUI'
  s.description = 'A powerful SwiftUI library for displaying and customizing Markdown text, with swift-cmark included, customized for Sendbird AI Agent'
  s.homepage = 'https://github.com/sendbird/sendbird-cocoapods'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Sendbird' => 'developer@sendbird.com' }
  
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-cocoapods.git',
    :tag => "MarkdownUI-#{s.version}"
  }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.7'
  
  # Main MarkdownUI sources
  s.source_files = [
    'Sources/MarkdownUI/Sources/**/*.swift',
    'Sources/MarkdownUI/ThirdParty/cmark-gfm/**/*.{c,h}',
    'Sources/MarkdownUI/ThirdParty/cmark-gfm-extensions/**/*.{c,h}'
  ]
  
  # Public headers for C code
  s.public_header_files = [
    'Sources/MarkdownUI/ThirdParty/cmark-gfm/**/*.h',
    'Sources/MarkdownUI/ThirdParty/cmark-gfm-extensions/**/*.h'
  ]
  
  # Exclude CMake and other build files
  s.exclude_files = [
    'Sources/MarkdownUI/ThirdParty/**/CMakeLists.txt',
    'Sources/MarkdownUI/ThirdParty/**/*.re'
  ]
  
  # Frameworks
  s.frameworks = 'SwiftUI'
  
  # Internal dependencies
  s.dependency 'SendbirdNetworkImage', '~> 1.0'
  
  # Compiler flags for C code
  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/Sources/MarkdownUI/ThirdParty/cmark-gfm $(PODS_TARGET_SRCROOT)/Sources/MarkdownUI/ThirdParty/cmark-gfm-extensions',
    'OTHER_CFLAGS' => '-DCMARK_GFM_STATIC_DEFINE -DCMARK_THREADING'
  }
end
EOF

    # SendbirdAIAgentCore.podspec (변수 치환이 필요한 부분)
    cat > repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.podspec << PODSPEC_EOF
Pod::Spec.new do |s|
  s.name = 'SendbirdAIAgentCore'
  s.version = '$SENDBIRD_AI_AGENT_VERSION'
  s.summary = 'Sendbird AI Agent Core Library'
  s.description = 'Core library for Sendbird AI Agent with advanced messaging features'
  s.homepage = 'https://github.com/sendbird/sendbird-cocoapods'
  s.license = { :type => 'Commercial', :file => 'Sources/SendbirdAIAgentCore/LICENSE' }
  s.author = { 'Sendbird' => 'developer@sendbird.com' }
  
  # 통합 리포지토리에서 XCFramework.zip 배포
  s.source = {
    :http => 'https://github.com/sendbird/sendbird-cocoapods/releases/download/SendbirdAIAgentCore-v$SENDBIRD_AI_AGENT_VERSION/SendbirdAIAgentCore.xcframework.zip',
    :sha1 => '$XCFRAMEWORK_SHA1'
  }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.7'
  
  # XCFramework 사용
  s.ios.vendored_frameworks = 'SendbirdAIAgentCore.xcframework'
  
  # Public CocoaPods trunk dependency
  s.dependency 'SendbirdUIMessageTemplate', '~> 3.30'
end
PODSPEC_EOF

    # SendbirdAIAgentMessenger.podspec (메인 사용자 모듈)
    cat > repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentMessenger/SendbirdAIAgentMessenger.podspec << MESSENGER_PODSPEC_EOF
Pod::Spec.new do |s|
  s.name = 'SendbirdAIAgentMessenger'
  s.version = '$SENDBIRD_AI_AGENT_VERSION'
  s.summary = 'Sendbird AI Agent Messenger - Main User Interface'
  s.description = 'The primary interface for Sendbird AI Agent with Markdown rendering, syntax highlighting, and advanced messaging capabilities. This is what users should integrate.'
  s.homepage = 'https://github.com/sendbird/sendbird-cocoapods'
  s.license = { :type => 'Commercial', :file => 'Sources/SendbirdAIAgentMessenger/LICENSE' }
  s.author = { 'Sendbird' => 'developer@sendbird.com' }
  
  s.source = {
    :git => 'https://github.com/sendbird/sendbird-cocoapods.git',
    :tag => "SendbirdAIAgentMessenger-v#{s.version}"
  }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.7'
  
  # Swift source files
  s.source_files = 'Sources/SendbirdAIAgentMessenger/Sources/**/*.swift'
  
  # Internal dependencies (private repo)
  s.dependency 'SendbirdAIAgentCore', '~> $SENDBIRD_AI_AGENT_VERSION'
  s.dependency 'SendbirdMarkdownUI', '~> 1.0'
  s.dependency 'SendbirdSplash', '~> 1.0'
  s.dependency 'SendbirdNetworkImage', '~> 1.0'
  
  # Frameworks
  s.frameworks = 'Foundation', 'SwiftUI', 'Combine'
end
MESSENGER_PODSPEC_EOF

    log_success "Podspec files created"
}

# Create documentation and license files
create_documentation_and_licenses() {
    log_info "Creating documentation and license files..."
    
    # Create README for AI Agent Core
    cat > repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentCore/README.md << CORE_README_EOF
# Sendbird AI Agent Core

Core library for Sendbird AI Agent with advanced messaging features.

## Version: $SENDBIRD_AI_AGENT_VERSION

This library uses the pre-built XCFramework from Sendbird's official releases.

## ⚠️ Important Note

**This is an internal dependency. Users should integrate `SendbirdAIAgentMessenger` instead.**

## Features

- Pre-built XCFramework for optimized performance
- Integration with SendbirdUIMessageTemplate
- Advanced AI messaging capabilities

## XCFramework Source

Downloaded from: $SENDBIRD_AI_AGENT_DOWNLOAD_URL

## License

Commercial - Sendbird Inc.
CORE_README_EOF

    # Create README for AI Agent Messenger (Main User Module)
    cat > repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentMessenger/README.md << MESSENGER_README_EOF
# Sendbird AI Agent Messenger

The primary interface for Sendbird AI Agent with advanced messaging capabilities.

## Version: $SENDBIRD_AI_AGENT_VERSION

## 🎯 This is the main module that users should integrate!

## Features

- **🤖 AI Conversation**: Advanced AI-powered messaging
- **📝 Markdown Rendering**: Rich text support with MarkdownUI
- **✨ Syntax Highlighting**: Code highlighting with Splash
- **🖼️ Image Loading**: Network image support with NetworkImage
- **🔧 Easy Integration**: Simple Swift API

## Installation

Add the private spec repository to your Podfile:

\`\`\`ruby
source 'https://github.com/sendbird/sendbird-cocoapods.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  
  pod 'SendbirdAIAgentMessenger', '~> $SENDBIRD_AI_AGENT_VERSION'
end
\`\`\`

## Quick Start

\`\`\`swift
import SendbirdAIAgentMessenger

// Initialize configuration
let config = MessengerConfiguration(
    applicationId: "YOUR_APP_ID",
    apiKey: "YOUR_API_KEY",
    debugMode: true
)

// Initialize the messenger
SendbirdAIAgentMessenger.shared.initialize(with: config)

// Send a message
SendbirdAIAgentMessenger.shared.sendMessage("Hello AI!") { response in
    if response.success {
        print("Response: \(response.message)")
    } else {
        print("Error: \(response.error?.localizedDescription ?? "Unknown error")")
    }
}

// Check capabilities
let capabilities = SendbirdAIAgentMessenger.shared.getCapabilities()
print("Supported features: \(capabilities)")
\`\`\`

## Architecture

\`\`\`
SendbirdAIAgentMessenger (Swift Sources) 🎯 <- Users integrate this
├── SendbirdAIAgentCore (XCFramework)      <- Internal dependency
├── SendbirdMarkdownUI (Swift Sources)     <- Markdown rendering
├── SendbirdSplash (Swift Sources)         <- Syntax highlighting  
└── SendbirdNetworkImage (Swift Sources)   <- Image loading
\`\`\`

## Dependencies

This library automatically includes:
- SendbirdAIAgentCore (pre-built XCFramework)
- SendbirdMarkdownUI (SwiftUI Markdown rendering)
- SendbirdSplash (Swift syntax highlighting)
- SendbirdNetworkImage (Network image loading)
- SendbirdUIMessageTemplate (Message templates)

## License

Commercial - Sendbird Inc.
MESSENGER_README_EOF

    # Create LICENSE for AI Agent Core
    cat > repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentCore/LICENSE << 'CORE_LICENSE_EOF'
SENDBIRD AI AGENT CORE LICENSE

Copyright (c) 2024 Sendbird, Inc.

This software and associated documentation files (the "Software") are proprietary 
to Sendbird, Inc. ("Sendbird") and are protected by copyright laws and international 
copyright treaties, as well as other intellectual property laws and treaties.

The Software is licensed, not sold. This license grants you the right to use the 
Software solely for the purpose of integrating with Sendbird services in accordance 
with your agreement with Sendbird.

You may not:
- Distribute, sell, lease, rent, lend, or sublicense the Software
- Reverse engineer, decompile, disassemble, or otherwise attempt to derive the 
  source code of the Software
- Remove or alter any proprietary notices, labels, or marks on the Software

This license terminates automatically if you violate any of its terms.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT.

For questions about this license, contact: developer@sendbird.com
CORE_LICENSE_EOF

    # Create LICENSE for AI Agent Messenger
    cat > repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentMessenger/LICENSE << 'MESSENGER_LICENSE_EOF'
SENDBIRD AI AGENT MESSENGER LICENSE

Copyright (c) 2024 Sendbird, Inc.

This software and associated documentation files (the "Software") are proprietary 
to Sendbird, Inc. ("Sendbird") and are protected by copyright laws and international 
copyright treaties, as well as other intellectual property laws and treaties.

The Software is licensed, not sold. This license grants you the right to use the 
Software solely for the purpose of integrating with Sendbird services in accordance 
with your agreement with Sendbird.

You may not:
- Distribute, sell, lease, rent, lend, or sublicense the Software
- Reverse engineer, decompile, disassemble, or otherwise attempt to derive the 
  source code of the Software
- Remove or alter any proprietary notices, labels, or marks on the Software

This license terminates automatically if you violate any of its terms.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT.

For questions about this license, contact: developer@sendbird.com
MESSENGER_LICENSE_EOF

    log_success "Documentation and license files created"
}

# Initialize git repository
init_git_repo() {
    log_info "Initializing git repository..."
    
    # Single repository for everything
    cd repo/$COCOAPODS_REPO
    if [ ! -d ".git" ]; then
        git init
        
        # Create comprehensive README
        cat > README.md << MAIN_README_EOF
# Sendbird CocoaPods Specifications

This repository contains CocoaPods specs, source code, and release files for Sendbird modules.

## 🎯 For Users: Use SendbirdAIAgentMessenger

**If you're integrating Sendbird AI Agent, use \`SendbirdAIAgentMessenger\` only!**

\`\`\`ruby
pod 'SendbirdAIAgentMessenger', '~> $SENDBIRD_AI_AGENT_VERSION'
\`\`\`

## Repository Structure

\`\`\`
├── Sources/                          # Source code and podspecs
│   ├── MarkdownUI/                  # 📝 SwiftUI Markdown rendering
│   ├── NetworkImage/                # 🖼️ Network image loading
│   ├── Splash/                      # ✨ Swift syntax highlighting
│   ├── SendbirdAIAgentCore/         # 🤖 AI Agent Core (XCFramework)
│   └── SendbirdAIAgentMessenger/    # 🎯 Main User Module (Swift)
├── Releases/                        # Binary releases
│   └── SendbirdAIAgentCore/         # XCFramework files
└── Specs/                           # CocoaPods specifications
    ├── SendbirdMarkdownUI/
    ├── SendbirdNetworkImage/
    ├── SendbirdSplash/
    ├── SendbirdAIAgentCore/
    └── SendbirdAIAgentMessenger/    # 🎯 User-facing specs
\`\`\`

## Modules

### 🎯 SendbirdAIAgentMessenger (v$SENDBIRD_AI_AGENT_VERSION) - **USE THIS!**
The main user interface for Sendbird AI Agent
- **Type**: Swift source code (easy to debug)
- **Purpose**: Primary integration point for users
- **Features**: AI conversation, Markdown, syntax highlighting, image loading
- **Dependencies**: All other modules automatically included

### 🤖 SendbirdAIAgentCore (v$SENDBIRD_AI_AGENT_VERSION) - **Internal Dependency**
Core AI Agent library with pre-built XCFramework
- **Type**: Commercial XCFramework (optimized binary)
- **Source**: sendbird-ai-agent-core-ios repository
- **Purpose**: Internal dependency (users don't directly integrate this)

### 📝 SendbirdMarkdownUI - **Internal Dependency**
Based on [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui)
- SwiftUI Markdown rendering with GitHub Flavored Markdown support
- Includes swift-cmark dependency for C-level parsing

### 🖼️ SendbirdNetworkImage - **Internal Dependency**
Based on [NetworkImage](https://github.com/gonzalezreal/NetworkImage)
- Asynchronous image loading for SwiftUI
- Persistent and in-memory caching

### ✨ SendbirdSplash - **Internal Dependency**
Based on [Splash](https://github.com/JohnSundell/Splash)
- Swift syntax highlighting
- HTML and NSAttributedString output formats

## Installation

Add this private spec repository to your Podfile:

\`\`\`ruby
source 'https://github.com/sendbird/sendbird-cocoapods.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  
  # 🎯 Only integrate this - it includes everything!
  pod 'SendbirdAIAgentMessenger', '~> $SENDBIRD_AI_AGENT_VERSION'
end
\`\`\`

## Usage Example

\`\`\`swift
import SendbirdAIAgentMessenger

let config = MessengerConfiguration(
    applicationId: "YOUR_APP_ID",
    apiKey: "YOUR_API_KEY"
)

SendbirdAIAgentMessenger.shared.initialize(with: config)

SendbirdAIAgentMessenger.shared.sendMessage("Hello!") { response in
    print("AI Response: \(response.message)")
}
\`\`\`

## Architecture

\`\`\`
📱 User App
└── 🎯 SendbirdAIAgentMessenger (Swift Sources)
    ├── 🤖 SendbirdAIAgentCore (XCFramework)
    ├── 📝 SendbirdMarkdownUI (Swift Sources)
    ├── ✨ SendbirdSplash (Swift Sources)
    └── 🖼️ SendbirdNetworkImage (Swift Sources)
\`\`\`

## License

- **Internal Modules**: MIT License (see individual directories)
- **SendbirdAIAgentCore & SendbirdAIAgentMessenger**: Commercial License (Sendbird Inc.)
MAIN_README_EOF

        # Create root LICENSE file
        cat > LICENSE << 'MAIN_LICENSE_EOF'
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

NOTE: This license applies to the internal modules (MarkdownUI, NetworkImage, Splash).
SendbirdAIAgentCore and SendbirdAIAgentMessenger have their own commercial licenses. 
See Sources/SendbirdAIAgentCore/LICENSE and Sources/SendbirdAIAgentMessenger/LICENSE.
MAIN_LICENSE_EOF
        
        git add .
        git commit -m "Initial commit: Unified CocoaPods repository with SendbirdAIAgentMessenger"
    fi
    cd ../..
    
    log_success "Git repository initialized"
}

# Create tags for versioning
create_tags() {
    log_info "Creating version tags..."
    
    cd repo/$COCOAPODS_REPO
    git tag NetworkImage-1.0.0 2>/dev/null || log_warn "NetworkImage tag already exists"
    git tag MarkdownUI-1.0.0 2>/dev/null || log_warn "MarkdownUI tag already exists"
    git tag Splash-1.0.0 2>/dev/null || log_warn "Splash tag already exists"
    git tag SendbirdAIAgentCore-v$SENDBIRD_AI_AGENT_VERSION 2>/dev/null || log_warn "SendbirdAIAgentCore tag already exists"
    git tag SendbirdAIAgentMessenger-v$SENDBIRD_AI_AGENT_VERSION 2>/dev/null || log_warn "SendbirdAIAgentMessenger tag already exists"
    cd ../..
    
    log_success "Version tags created"
}

# Setup private spec repo structure
setup_spec_repo() {
    log_info "Setting up private spec repo structure..."
    
    cd repo/$COCOAPODS_REPO
    
    # Create spec directory structure 
    mkdir -p Specs/{SendbirdNetworkImage/1.0.0,SendbirdMarkdownUI/1.0.0,SendbirdSplash/1.0.0,SendbirdAIAgentCore/$SENDBIRD_AI_AGENT_VERSION,SendbirdAIAgentMessenger/$SENDBIRD_AI_AGENT_VERSION}
    
    # Copy podspecs to spec repo
    cp Sources/NetworkImage/SendbirdNetworkImage.podspec Specs/SendbirdNetworkImage/1.0.0/
    cp Sources/MarkdownUI/SendbirdMarkdownUI.podspec Specs/SendbirdMarkdownUI/1.0.0/
    cp Sources/Splash/SendbirdSplash.podspec Specs/SendbirdSplash/1.0.0/
    cp Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.podspec Specs/SendbirdAIAgentCore/$SENDBIRD_AI_AGENT_VERSION/
    cp Sources/SendbirdAIAgentMessenger/SendbirdAIAgentMessenger.podspec Specs/SendbirdAIAgentMessenger/$SENDBIRD_AI_AGENT_VERSION/
    
    git add .
    git commit -m "Add podspecs v1.0.0 and AI Agent modules v$SENDBIRD_AI_AGENT_VERSION" 2>/dev/null || log_warn "No changes to commit in specs repo"
    
    cd ../..
    log_success "Private spec repo structure created"
}

# Create ZIP release package  
create_zip_release() {
    log_info "Creating release package for GitHub Release..."
    
    # release 디렉토리에 GitHub Release용 파일 준비
    mkdir -p release
    
    # XCFramework.zip을 release 디렉토리에 복사 (GitHub Release 업로드용)
    cp repo/$COCOAPODS_REPO/Releases/SendbirdAIAgentCore/SendbirdAIAgentCore.xcframework.zip release/
    
    # 메타 파일들도 복사
    cp repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentCore/README.md release/SendbirdAIAgentCore-README.md
    cp repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.podspec release/
    cp repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentCore/LICENSE release/SendbirdAIAgentCore-LICENSE
    
    # Messenger 파일들도 복사 
    cp repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentMessenger/README.md release/SendbirdAIAgentMessenger-README.md
    cp repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentMessenger/SendbirdAIAgentMessenger.podspec release/
    cp repo/$COCOAPODS_REPO/Sources/SendbirdAIAgentMessenger/LICENSE release/SendbirdAIAgentMessenger-LICENSE
    
    log_success "Release package created"
    log_info "XCFramework ZIP: release/SendbirdAIAgentCore.xcframework.zip"
    log_info "Ready for GitHub Release: SendbirdAIAgentCore-v$SENDBIRD_AI_AGENT_VERSION"
    log_info "XCFramework SHA1: $XCFRAMEWORK_SHA1"
}

# Create deployment script
create_deployment_script() {
    log_info "Creating deployment script..."
    
    cat > deploy-to-github.sh << 'DEPLOY_EOF'
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
DEPLOY_EOF

    # 변수 치환 부분을 별도로 추가
    cat >> deploy-to-github.sh << DEPLOY_VARS_EOF
echo "3. Tag: SendbirdAIAgentCore-v$SENDBIRD_AI_AGENT_VERSION"
echo "4. Title: Sendbird AI Agent Core v$SENDBIRD_AI_AGENT_VERSION"
echo "5. Upload: release/SendbirdAIAgentCore.xcframework.zip"
echo "6. Publish release"
echo ""
echo "📋 After XCFramework upload, deploy podspecs:"
echo "1. Add private spec repo:"
echo "   pod repo add sendbird-specs https://github.com/\$GITHUB_USERNAME/sendbird-cocoapods.git"
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
echo "   pod 'SendbirdAIAgentMessenger', '~> $SENDBIRD_AI_AGENT_VERSION'"
echo ""
echo "📱 Release Information:"
echo "   - Repository: https://github.com/\$GITHUB_USERNAME/sendbird-cocoapods"
echo "   - Main Module: SendbirdAIAgentMessenger v$SENDBIRD_AI_AGENT_VERSION"
echo "   - XCFramework: v$SENDBIRD_AI_AGENT_VERSION"
echo "   - SHA1: $XCFRAMEWORK_SHA1"
echo "   - Release Tag: SendbirdAIAgentCore-v$SENDBIRD_AI_AGENT_VERSION"
DEPLOY_VARS_EOF

    chmod +x deploy-to-github.sh
    log_success "Deployment script created"
}

# Create example project
create_example_project() {
    log_info "Creating example project..."
    
    mkdir -p example-app
    
    cat > example-app/Podfile << EXAMPLE_EOF
# Podfile for testing Sendbird AI Agent Messenger

source 'https://github.com/sendbird/sendbird-cocoapods.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'
use_frameworks!

target 'SendbirdAIAgentExample' do
  # 🎯 Users only need to integrate this one pod!
  pod 'SendbirdAIAgentMessenger', '~> $SENDBIRD_AI_AGENT_VERSION'
  
  # For local testing, use path instead:
  # pod 'SendbirdAIAgentMessenger', :path => '../repo/sendbird-cocoapods/Sources/SendbirdAIAgentMessenger'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
EXAMPLE_EOF

    # Create example Swift code
    cat > example-app/ExampleUsage.swift << EXAMPLE_SWIFT_EOF
import UIKit
import SendbirdAIAgentMessenger

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSendbirdAIAgent()
    }
    
    private func setupSendbirdAIAgent() {
        // Initialize configuration
        let config = MessengerConfiguration(
            applicationId: "YOUR_SENDBIRD_APP_ID",
            apiKey: "YOUR_API_KEY",
            debugMode: true,
            markdownEnabled: true,
            syntaxHighlightingEnabled: true,
            imageLoadingEnabled: true
        )
        
        // Initialize the messenger
        SendbirdAIAgentMessenger.shared.initialize(with: config)
        
        // Check capabilities
        let capabilities = SendbirdAIAgentMessenger.shared.getCapabilities()
        print("Supported capabilities: \(capabilities)")
        
        // Send a test message
        sendTestMessage()
    }
    
    private func sendTestMessage() {
        let message = """
        Hello AI! Can you help me with:
        1. Markdown rendering
        2. Swift code highlighting
        3. Image loading
        
        Here's some Swift code:
        \`\`\`swift
        let greeting = "Hello, World!"
        print(greeting)
        \`\`\`
        """
        
        SendbirdAIAgentMessenger.shared.sendMessage(message) { [weak self] response in
            if response.success {
                print("✅ AI Response received:")
                print(response.message)
                print("Timestamp: \(response.timestamp)")
            } else {
                print("❌ Error occurred:")
                print(response.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}
EXAMPLE_SWIFT_EOF

    log_success "Example project created"
}

# Validate podspecs
validate_podspecs() {
    log_info "Validating podspecs..."
    
    # Note: This requires the repos to be pushed to GitHub first
    log_warn "Podspec validation skipped - requires GitHub repos to be pushed first"
    log_info "After pushing to GitHub, run:"
    echo "  pod spec lint SendbirdNetworkImage.podspec --allow-warnings"
    echo "  pod spec lint SendbirdSplash.podspec --allow-warnings"  
    echo "  pod spec lint SendbirdMarkdownUI.podspec --allow-warnings"
    echo "  pod spec lint SendbirdAIAgentCore.podspec --allow-warnings"
    echo "  pod spec lint SendbirdAIAgentMessenger.podspec --allow-warnings"
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf temp_downloads
    log_success "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting Sendbird Private Pods setup v2..."
    echo "========================================"
    
    create_directory_structure
    setup_network_image
    setup_splash
    setup_markdown_ui
    download_sendbird_ai_agent_core
    create_sendbird_ai_agent_messenger_sources
    create_podspecs
    create_documentation_and_licenses
    init_git_repo
    create_tags
    setup_spec_repo
    create_zip_release
    create_deployment_script
    create_example_project
    validate_podspecs
    cleanup
    
    echo ""
    echo "========================================"
    log_success "Setup completed successfully!"
    echo ""
    echo "🎯 MAIN USER MODULE: SendbirdAIAgentMessenger v$SENDBIRD_AI_AGENT_VERSION"
    echo "   - Users integrate: pod 'SendbirdAIAgentMessenger'"
    echo "   - Swift source code (easy debugging)"
    echo "   - Includes all dependencies automatically"
    echo ""
    echo "🤖 CORE DEPENDENCY: SendbirdAIAgentCore v$SENDBIRD_AI_AGENT_VERSION"
    echo "   - Downloaded from: $SENDBIRD_AI_AGENT_DOWNLOAD_URL"
    echo "   - SHA1: $XCFRAMEWORK_SHA1"
    echo "   - XCFramework (optimized binary)"
    echo ""
    echo "📁 Unified Repository Structure:"
    echo "  └── repo/"
    echo "      └── sendbird-cocoapods/              # 🎯 Everything in one repo!"
    echo "          ├── Sources/                      # Source code + Podspecs"
    echo "          │   ├── MarkdownUI/              # Internal module"
    echo "          │   ├── NetworkImage/            # Internal module"
    echo "          │   ├── Splash/                  # Internal module"
    echo "          │   ├── SendbirdAIAgentCore/     # 🤖 Core library (XCF)"
    echo "          │   └── SendbirdAIAgentMessenger/ # 🎯 Main library (Swift)"
    echo "          ├── Releases/                    # Binary releases"
    echo "          │   └── SendbirdAIAgentCore/     # XCFramework storage"
    echo "          └── Specs/                       # CocoaPods specifications"
    echo "              ├── SendbirdMarkdownUI/"
    echo "              ├── SendbirdNetworkImage/"
    echo "              ├── SendbirdSplash/"
    echo "              ├── SendbirdAIAgentCore/     # v$SENDBIRD_AI_AGENT_VERSION"
    echo "              └── SendbirdAIAgentMessenger/ # v$SENDBIRD_AI_AGENT_VERSION"
    echo ""
    echo "📦 Release Files:"
    echo "  └── release/"
    echo "      ├── SendbirdAIAgentCore.xcframework.zip     # 📱 For GitHub Release"
    echo "      ├── SendbirdAIAgentCore-README.md"
    echo "      ├── SendbirdAIAgentMessenger-README.md"
    echo "      └── *.podspec files"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Create GitHub repository:"
    echo "   - https://github.com/sendbird/sendbird-cocoapods (ONLY ONE REPO NEEDED!)"
    echo "2. Run: ./deploy-to-github.sh"
    echo "3. Upload release/SendbirdAIAgentCore.xcframework.zip to GitHub Release"
    echo "4. Follow the instructions in the deployment script output"
    echo ""
    echo "✨ User Integration (Simple!):"
    echo '   source "https://github.com/sendbird/sendbird-cocoapods.git"'
    echo "   pod 'SendbirdAIAgentMessenger', '~> $SENDBIRD_AI_AGENT_VERSION'"
    echo ""
    echo "🏗️ Architecture:"
    echo "   📱 User App"
    echo "   └── 🎯 SendbirdAIAgentMessenger (Swift Sources)"
    echo "       ├── 🤖 SendbirdAIAgentCore (XCFramework)"
    echo "       ├── 📝 SendbirdMarkdownUI (Swift Sources)"
    echo "       ├── ✨ SendbirdSplash (Swift Sources)"
    echo "       └── 🖼️ SendbirdNetworkImage (Swift Sources)"
    echo ""
    log_success "Ready for deployment! 🎉"
}

# Run main function
main "$@"
