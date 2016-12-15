Pod::Spec.new do |s|
  s.name         = "BringgTracking"
  s.version      = "1.10.5"
  s.summary      = "BringgTracking SDK"
  s.homepage     = "http://www.bringg.com"
  s.author       = "Bringg Ltd."
  s.ios.deployment_target = "8.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/bringg/customer-sdk-ios.git", :tag => "#{s.version}" }
  s.source_files  = "sources", "sources/**/*.{h,m}"
  s.requires_arc = true
  s.dependency "Socket.IO-Client-Swift", '~> 8.1.2'
  s.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
end
