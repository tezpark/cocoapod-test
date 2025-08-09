Pod::Spec.new do |s|
  s.name = 'SendbirdAIAgentCore'
  s.version = '0.10.0'
  s.summary = 'Sendbird AI Agent Core Library'
  s.description = 'Core library for Sendbird AI Agent with advanced messaging features'
  s.homepage = 'https://github.com/sendbird/sendbird-cocoapods'
  s.license = { :type => 'Commercial', :file => 'Sources/SendbirdAIAgentCore/LICENSE' }
  s.author = { 'Sendbird' => 'developer@sendbird.com' }
  
  # 통합 리포지토리에서 XCFramework.zip 배포
  s.source = {
    :http => 'https://github.com/sendbird/sendbird-cocoapods/releases/download/SendbirdAIAgentCore-v0.10.0/SendbirdAIAgentCore.xcframework.zip',
    :sha1 => '0b56b290c7cfb362249f3738bd3c10977931d5f5'
  }
  
  s.ios.deployment_target = '15.0'
  s.swift_version = '5.7'
  
  # XCFramework 사용
  s.ios.vendored_frameworks = 'SendbirdAIAgentCore.xcframework'
  
  # Public CocoaPods trunk dependency
  s.dependency 'SendbirdUIMessageTemplate', '~> 3.30'
end
