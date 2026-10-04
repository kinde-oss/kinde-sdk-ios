Pod::Spec.new do |s|
  s.name = 'KindeSDK'
  s.ios.deployment_target = '15.0'
  s.version = '1.7.0'
  s.swift_version = '5.0.0'
  s.source = { :git => 'https://github.com/kinde-oss/kinde-sdk-ios.git', :tag => s.version.to_s }
  s.authors = { 'Kinde' => 'engineering@kinde.com' }
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage = 'https://github.com/kinde-oss/kinde-sdk-ios'
  s.summary = 'Kinde SDK for Swift iOS.'
  s.source_files = 'Sources/KindeSDK/**/*'
  s.preserve_paths = ['Sources/KindeSDK/README.md', 'Sources/docs/*.md']
  s.dependency 'AppAuth', '~> 3.0'
end
