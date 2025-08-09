# Sendbird CocoaPods Specifications

This repository contains CocoaPods specs, source code, and release files for Sendbird modules.

## 🎯 For Users: Use SendbirdAIAgentMessenger

**If you're integrating Sendbird AI Agent, use `SendbirdAIAgentMessenger` only!**

```ruby
pod 'SendbirdAIAgentMessenger', '~> 0.10.0'
```

## Repository Structure

```
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
```

## Modules

### 🎯 SendbirdAIAgentMessenger (v0.10.0) - **USE THIS!**
The main user interface for Sendbird AI Agent
- **Type**: Swift source code (easy to debug)
- **Purpose**: Primary integration point for users
- **Features**: AI conversation, Markdown, syntax highlighting, image loading
- **Dependencies**: All other modules automatically included

### 🤖 SendbirdAIAgentCore (v0.10.0) - **Internal Dependency**
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

```ruby
source 'https://github.com/sendbird/sendbird-cocoapods.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  
  # 🎯 Only integrate this - it includes everything!
  pod 'SendbirdAIAgentMessenger', '~> 0.10.0'
end
```

## Usage Example

```swift
import SendbirdAIAgentMessenger

let config = MessengerConfiguration(
    applicationId: "YOUR_APP_ID",
    apiKey: "YOUR_API_KEY"
)

SendbirdAIAgentMessenger.shared.initialize(with: config)

SendbirdAIAgentMessenger.shared.sendMessage("Hello!") { response in
    print("AI Response: \(response.message)")
}
```

## Architecture

```
📱 User App
└── 🎯 SendbirdAIAgentMessenger (Swift Sources)
    ├── 🤖 SendbirdAIAgentCore (XCFramework)
    ├── 📝 SendbirdMarkdownUI (Swift Sources)
    ├── ✨ SendbirdSplash (Swift Sources)
    └── 🖼️ SendbirdNetworkImage (Swift Sources)
```

## License

- **Internal Modules**: MIT License (see individual directories)
- **SendbirdAIAgentCore & SendbirdAIAgentMessenger**: Commercial License (Sendbird Inc.)
