Pod::Spec.new do |s|
  s.name         = "BringgTracking"
  s.version      = "1.17.0"
  s.summary      = "BringgTracking SDK"
  s.homepage     = "http://www.bringg.com"
  s.author       = "Bringg Ltd."
  s.ios.deployment_target = "8.0"
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                  allows building customer experience apps based on the popular on demand delivery platform 'Bringg'
                   DESC

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = "MIT"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/bringg/customer-sdk-ios.git", :tag => "#{s.version}" }
  s.source_files  = "sources", "sources/**/*.{h,m}"
  s.requires_arc = true
  s.dependency "Socket.IO-Client-Swift", '~> 8.3.3'
  s.xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
end
