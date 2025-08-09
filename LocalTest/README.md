# Local Testing for Sendbird AI Agent

This directory contains a test iOS project for local CocoaPods testing.

## 📁 Structure

```
LocalTest/
├── Podfile                           # Local path-based dependencies
├── SendbirdAIAgentTest/             # Test iOS app
│   ├── AppDelegate.swift            # App entry point
│   ├── ViewController.swift         # Test UI with all features
│   └── Info.plist                   # App configuration
└── README.md                        # This file
```

## 🚀 How to Test

### 1. Install Dependencies
```bash
cd LocalTest
pod install --verbose
```

### 2. Open Xcode Project  
```bash
open SendbirdAIAgentTest.xcworkspace
```

### 3. Build and Run
- Select iOS Simulator (iPhone 15 or later)
- Press Cmd+R to build and run

## 🧪 Test Features

The test app includes:

### ✅ SendbirdAIAgentMessenger Integration
- Initialization with test configuration
- Capabilities detection
- Message sending with response handling

### ✅ UI Testing
- Text input for messages
- Send button with loading state
- Response display with formatting
- Capabilities label

### ✅ Dependency Testing
- **SendbirdMarkdownUI**: Markdown rendering support
- **SendbirdSplash**: Swift syntax highlighting  
- **SendbirdNetworkImage**: Image loading capabilities
- **SendbirdAIAgentCore**: Core XCFramework functionality

## 📝 Test Messages

Try these test messages in the app:

### Basic Test
```
Hello AI! How are you?
```

### Markdown Test
```markdown
## Markdown Test

- **Bold text**
- *Italic text* 
- `inline code`

```swift
// Code block test
let greeting = "Hello!"
print(greeting)
```
```

### Capabilities Test
```
What capabilities do you have?
```

## 🔧 Troubleshooting

### Pod Install Issues
```bash
# Clear CocoaPods cache
pod cache clean --all
rm -rf ~/Library/Caches/CocoaPods
rm -rf Pods/ Podfile.lock

# Reinstall
pod install --repo-update --verbose
```

### Build Issues
- Make sure iOS Deployment Target is 15.0+
- Check that all dependencies are properly linked
- Verify XCFramework is extracted in Sources/SendbirdAIAgentCore/

### XCFramework Issues
```bash
# Re-extract XCFramework
cd ../repo/sendbird-cocoapods/Releases/SendbirdAIAgentCore
unzip -o SendbirdAIAgentCore.xcframework.zip
cp -r SendbirdAIAgentCore.xcframework ../../Sources/SendbirdAIAgentCore/
```

## 📊 Expected Results

### ✅ Successful Integration
- App launches without crashes
- Capabilities are displayed
- Messages can be sent
- Responses are received and displayed

### ✅ Module Testing
- All dependencies load correctly
- No missing symbols or linking errors
- Core functionality works as expected

## 🔄 Testing Workflow

1. **Local Development**: Test with `:path =>` references
2. **Integration Testing**: Validate all modules work together  
3. **Functionality Testing**: Test core features like messaging
4. **UI Testing**: Verify user interface responds correctly
5. **Error Handling**: Test error scenarios and edge cases

## 📱 Device Requirements

- iOS 15.0+
- iPhone or iPad simulator
- Xcode 14.0+
- Swift 5.7+

Happy testing! 🎉
