#
#  Be sure to run `pod spec lint BringgTracking.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "BringgTracking"
  s.version      = "1.9.8"
  s.summary      = "BringgTracking SDK"
  s.homepage     = "http://EXAMPLE/BringgTracking"
  s.author       = "Bringg Ltd."
  # s.social_media_url   = ""
  s.ios.deployment_target = "8.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/bringg/customer-sdk-ios.git", :tag => "#{s.version}" }
  s.source_files  = "sources", "sources/**/*.{h,m}"
  s.requires_arc = true
  s.dependency "Socket.IO-Client-Swift", '~> 7.0.3'

end
