Pod::Spec.new do |s|
  s.name             = 'KindeAuthSwift'
  s.version          = '0.1.0'
  s.swift_version    = '5.6.1'
  s.summary          = 'Kinde SDK for Swift iOS.'
  s.description      = <<-DESC
                       Kinde SDK for authentication on iOS.
                       DESC

  s.homepage         = 'https://github.com/todo/KindeAuthSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'todo' => 'todo@adapptor.com.au' }
  s.source           = { :git => 'https://github.com/todo/KindeAuthSwift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TODO>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'KindeAuthSwift/Classes/**/*'
  
  s.dependency 'AppAuth'
  s.dependency 'SwiftKeychainWrapper'
end
