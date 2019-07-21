Pod::Spec.new do |s|
  s.name         = "BringgTracking"
  s.version      = "1.20.0"
  s.summary      = "BringgTracking SDK"
  s.homepage     = "http://www.bringg.com"
  s.author       = "Bringg Ltd."
  s.ios.deployment_target = "9.0"
  s.description  = <<-DESC
                  allows building customer experience apps based on the popular on demand delivery platform 'Bringg'
                   DESC
  s.license      = "MIT"
  s.source       = { :git => "https://github.com/bringg/customer-sdk-ios.git", :tag => "#{s.version}" }
  s.source_files  = "sources", "sources/**/*.{h,m}"
  s.requires_arc = true
  s.dependency "Socket.IO-Client-Swift", '~> 15.1.0'
  s.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
end
