Pod::Spec.new do |s|
  s.name             = 'KindeSDK'
  s.version          = '1.1'
  s.swift_version    = '5.6.1'
  s.summary          = 'Kinde SDK for Swift iOS.'
  s.description      = <<-DESC
                       Kinde SDK for authentication on iOS.
                       DESC

  s.homepage         = 'https://github.com/kinde-oss/kinde-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Kinde' => 'engineering@kinde.com' }
  s.source           = { :git => 'https://github.com/kinde-oss/kinde-sdk-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.preserve_paths = ['KindeSDK/Classes/KindeManagementAPI/README.md', 'KindeSDK/Classes/KindeManagementAPI/docs/*.md']
  
  s.source_files = ['KindeSDK/Classes/*.swift', 'KindeSDK/Classes/KindeManagementAPI/OpenAPIClient/**/*']
  
  s.dependency 'AppAuth'
  s.dependency 'SwiftKeychainWrapper'
end
