Pod::Spec.new do |s|
  s.name = 'SendbirdAIAgentCore'
  s.version = '0.10.0'
  s.summary = 'Sendbird AI Agent Core Library'
  s.description = 'Core library for Sendbird AI Agent with advanced messaging features'
  s.homepage = 'https://github.com/tezpark/cocoapod-test'
  s.license = { :type => 'Commercial', :file => 'Sources/SendbirdAIAgentCore/LICENSE' }
  s.author = { 'Sendbird' => 'developer@sendbird.com' }
  
  # GitHub source with XCFramework download
  s.source = {
    :git => 'https://github.com/tezpark/cocoapod-test.git',
    :tag => "SendbirdAIAgentCore-v#{s.version}"
  }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.7'
  
  # XCFramework from local path (will be available after git clone)
  s.ios.vendored_frameworks = 'Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.xcframework'
  
  # Public CocoaPods trunk dependency
  s.dependency 'SendbirdUIMessageTemplate', '~> 3.30'
  
  # XCFramework is already included in the repository
end
