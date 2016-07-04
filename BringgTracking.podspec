Pod::Spec.new do |spec|
    spec.name = "BringgTracking"
    spec.version = "1.9.0"
    spec.summary = "Bringg Customer SDK. allows tracking of orders via Bringg platform"
    spec.homepage = "https://github.com/bringg/customer-sdk-ios"
    spec.license = { type: 'MIT', file: 'LICENSE' }
    spec.authors = { "Matan Poreh" => 'matan@bringg.com' }

    spec.platform = :ios, "8.0"
    spec.requires_arc = true
    spec.source = { git: "https://github.com/bringg/customer-sdk-ios.git", tag: "v#{spec.version}", submodules: false }
    spec.source_files = "RGB/**/*.{h,swift}"

    spec.dependency 'AFNetworking', '2.6.3'
    spec.dependency 'Socket.IO-Client-Swift', '~> 6.1.4'
end