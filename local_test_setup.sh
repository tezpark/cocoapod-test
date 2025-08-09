#!/bin/bash

# =============================================================================
# Local Testing Setup for Sendbird CocoaPods
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Create test iOS project
create_test_project() {
    log_info "Creating test iOS project..."
    
    mkdir -p LocalTest
    cd LocalTest
    
    # Create basic iOS project structure
    mkdir -p SendbirdAIAgentTest.xcodeproj
    mkdir -p SendbirdAIAgentTest
    
    # Create Podfile with local paths
    cat > Podfile << 'PODFILE_EOF'
# Local Testing Podfile for Sendbird AI Agent

# Use local CocoaPods repo (no remote sources needed)
# source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'
use_frameworks!
inhibit_all_warnings!

target 'SendbirdAIAgentTest' do
  
  # 🎯 LOCAL TESTING: Use local paths instead of remote specs
  
  # Internal modules (local paths)
  pod 'SendbirdNetworkImage', :path => '../repo/sendbird-cocoapods/Sources/NetworkImage'
  pod 'SendbirdSplash', :path => '../repo/sendbird-cocoapods/Sources/Splash'  
  pod 'SendbirdMarkdownUI', :path => '../repo/sendbird-cocoapods/Sources/MarkdownUI'
  
  # Main modules (local paths)
  # Note: SendbirdAIAgentCore needs special handling for XCFramework
  pod 'SendbirdAIAgentMessenger', :path => '../repo/sendbird-cocoapods/Sources/SendbirdAIAgentMessenger'
  
  # Public CocoaPods for external dependencies
  pod 'SendbirdUIMessageTemplate', '~> 3.30'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      
      # Allow warnings for local pods during testing
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
    end
  end
end
PODFILE_EOF

    # Create test ViewController
    cat > SendbirdAIAgentTest/ViewController.swift << 'VIEW_CONTROLLER_EOF'
import UIKit
import SendbirdAIAgentMessenger

class ViewController: UIViewController {
    
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var responseTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var capabilitiesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSendbirdAIAgent()
    }
    
    private func setupUI() {
        title = "Sendbird AI Agent Test"
        
        // Setup text views if they exist (for programmatic UI)
        if messageTextView == nil {
            createProgrammaticUI()
        }
        
        messageTextView?.text = """
        Hello AI! Test message with:
        
        ## Markdown Features
        - **Bold text**
        - *Italic text*
        - `code snippet`
        
        ```swift
        // Swift code highlighting test
        let greeting = "Hello, World!"
        print(greeting)
        
        func testFunction() {
            let numbers = [1, 2, 3, 4, 5]
            let doubled = numbers.map { $0 * 2 }
            print(doubled)
        }
        ```
        
        ### Image Loading Test
        ![Test Image](https://via.placeholder.com/150)
        
        What can you do for me?
        """
    }
    
    private func createProgrammaticUI() {
        view.backgroundColor = .systemBackground
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Capabilities label
        capabilitiesLabel = UILabel()
        capabilitiesLabel.numberOfLines = 0
        capabilitiesLabel.font = .systemFont(ofSize: 12)
        capabilitiesLabel.textColor = .systemBlue
        stackView.addArrangedSubview(capabilitiesLabel)
        
        // Message input
        messageTextView = UITextView()
        messageTextView.layer.borderColor = UIColor.systemGray.cgColor
        messageTextView.layer.borderWidth = 1
        messageTextView.layer.cornerRadius = 8
        messageTextView.font = .systemFont(ofSize: 14)
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        stackView.addArrangedSubview(messageTextView)
        
        // Send button
        sendButton = UIButton(type: .system)
        sendButton.setTitle("Send Message", for: .normal)
        sendButton.backgroundColor = .systemBlue
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 8
        sendButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        stackView.addArrangedSubview(sendButton)
        
        // Response display
        responseTextView = UITextView()
        responseTextView.layer.borderColor = UIColor.systemGray.cgColor
        responseTextView.layer.borderWidth = 1
        responseTextView.layer.cornerRadius = 8
        responseTextView.font = .systemFont(ofSize: 14)
        responseTextView.isEditable = false
        responseTextView.translatesAutoresizingMaskIntoConstraints = false
        responseTextView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        stackView.addArrangedSubview(responseTextView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupSendbirdAIAgent() {
        log("🚀 Setting up Sendbird AI Agent...")
        
        // Test configuration
        let config = MessengerConfiguration(
            applicationId: "TEST_APP_ID",
            apiKey: "TEST_API_KEY",
            debugMode: true,
            markdownEnabled: true,
            syntaxHighlightingEnabled: true,
            imageLoadingEnabled: true
        )
        
        // Initialize the messenger
        SendbirdAIAgentMessenger.shared.initialize(with: config)
        
        // Get capabilities
        let capabilities = SendbirdAIAgentMessenger.shared.getCapabilities()
        log("✅ Capabilities: \(capabilities)")
        
        DispatchQueue.main.async { [weak self] in
            self?.capabilitiesLabel.text = "Capabilities: \(capabilities.joined(separator: ", "))"
        }
        
        log("✅ Sendbird AI Agent initialized successfully!")
    }
    
    @objc private func sendButtonTapped() {
        guard let message = messageTextView.text, !message.isEmpty else {
            showAlert(title: "Error", message: "Please enter a message")
            return
        }
        
        log("📤 Sending message...")
        sendButton.isEnabled = false
        sendButton.setTitle("Sending...", for: .normal)
        
        SendbirdAIAgentMessenger.shared.sendMessage(message) { [weak self] response in
            DispatchQueue.main.async {
                self?.handleResponse(response)
                self?.sendButton.isEnabled = true
                self?.sendButton.setTitle("Send Message", for: .normal)
            }
        }
    }
    
    private func handleResponse(_ response: MessengerResponse) {
        log("📥 Response received")
        
        let responseText = """
        ═══════════════════════════════════════
        📅 Timestamp: \(DateFormatter.localizedString(from: response.timestamp, dateStyle: .short, timeStyle: .medium))
        ✅ Success: \(response.success)
        
        📝 Response:
        \(response.message)
        
        \(response.error != nil ? "❌ Error: \(response.error!.localizedDescription)" : "")
        ═══════════════════════════════════════
        
        \(responseTextView.text ?? "")
        """
        
        responseTextView.text = responseText
        
        if response.success {
            log("✅ Message sent successfully")
        } else {
            log("❌ Error: \(response.error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func log(_ message: String) {
        print("📱 [ViewController] \(message)")
    }
}

// MARK: - SwiftUI Preview Support
#if DEBUG && canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, *)
struct ViewController_Preview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}

@available(iOS 13.0, *)
struct ViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewController_Preview()
    }
}
#endif
VIEW_CONTROLLER_EOF

    # Create AppDelegate
    cat > SendbirdAIAgentTest/AppDelegate.swift << 'APP_DELEGATE_EOF'
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Create window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create and set root view controller
        let viewController = ViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        print("🚀 App launched successfully!")
        
        return true
    }
}
APP_DELEGATE_EOF

    # Create Info.plist
    cat > SendbirdAIAgentTest/Info.plist << 'INFO_PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>com.sendbird.aiagent.test</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
INFO_PLIST_EOF

    cd ..
    log_success "Test project created!"
}

# Handle XCFramework for local testing
setup_xcframework_for_local_testing() {
    log_info "Setting up XCFramework for local testing..."
    
    # Extract XCFramework to make it available for local podspec
    cd repo/sendbird-cocoapods/Releases/SendbirdAIAgentCore
    
    if [ -f "SendbirdAIAgentCore.xcframework.zip" ]; then
        log_info "Extracting XCFramework for local testing..."
        unzip -o SendbirdAIAgentCore.xcframework.zip
        
        # Move XCFramework to Sources directory for local path reference
        if [ -d "SendbirdAIAgentCore.xcframework" ]; then
            cp -r SendbirdAIAgentCore.xcframework ../../Sources/SendbirdAIAgentCore/
            log_success "XCFramework extracted and copied to Sources directory"
        else
            log_warn "XCFramework not found in zip file"
        fi
    else
        log_warn "XCFramework zip file not found"
    fi
    
    cd ../../../..
}

# Update podspecs for local testing
update_podspecs_for_local_testing() {
    log_info "Updating podspecs for local testing..."
    
    # Update SendbirdAIAgentCore.podspec for local XCFramework path
    cat > repo/sendbird-cocoapods/Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.podspec << 'CORE_PODSPEC_EOF'
Pod::Spec.new do |s|
  s.name = 'SendbirdAIAgentCore'
  s.version = '0.10.0'
  s.summary = 'Sendbird AI Agent Core Library'
  s.description = 'Core library for Sendbird AI Agent with advanced messaging features'
  s.homepage = 'https://github.com/sendbird/sendbird-cocoapods'
  s.license = { :type => 'Commercial', :file => 'LICENSE' }
  s.author = { 'Sendbird' => 'developer@sendbird.com' }
  
  # For local testing - use local XCFramework
  s.source = { :path => '.' }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.7'
  
  # XCFramework from local path
  s.ios.vendored_frameworks = 'SendbirdAIAgentCore.xcframework'
  
  # Public CocoaPods trunk dependency
  s.dependency 'SendbirdUIMessageTemplate', '~> 3.30'
end
CORE_PODSPEC_EOF

    log_success "Podspecs updated for local testing"
}

# Create local testing instructions
create_local_testing_instructions() {
    log_info "Creating local testing instructions..."
    
    cat > LocalTest/README.md << 'LOCAL_README_EOF'
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
LOCAL_README_EOF

    log_success "Local testing instructions created"
}

# Main execution for local testing setup
main() {
    log_info "Setting up local testing environment..."
    echo "========================================"
    
    # Check if main setup was run
    if [ ! -d "repo/sendbird-cocoapods" ]; then
        log_warn "Main setup not found. Please run the main setup script first:"
        echo "  ./setup_script.sh"
        exit 1
    fi
    
    setup_xcframework_for_local_testing
    update_podspecs_for_local_testing  
    create_test_project
    create_local_testing_instructions
    
    echo ""
    echo "========================================"
    log_success "Local testing environment ready!"
    echo ""
    echo "🧪 Next Steps:"
    echo "1. cd LocalTest"
    echo "2. pod install --verbose"
    echo "3. open SendbirdAIAgentTest.xcworkspace"
    echo "4. Build and run in Xcode"
    echo ""
    echo "📱 Test Project Features:"
    echo "   - Complete UI for testing"
    echo "   - All Sendbird modules integrated"  
    echo "   - Local path-based dependencies"
    echo "   - Comprehensive test messages"
    echo ""
    echo "📋 Test Checklist:"
    echo "   □ App launches successfully"
    echo "   □ Capabilities are displayed"
    echo "   □ Messages can be sent"
    echo "   □ Responses are received"
    echo "   □ Markdown rendering works"
    echo "   □ Syntax highlighting works"
    echo "   □ Image loading works"
    echo ""
    log_success "Ready for local testing! 🎉"
}

# Run main function
main "$@"