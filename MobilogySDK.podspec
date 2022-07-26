
Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '12.0'
s.name = "MobilogySDK"
s.summary = "MobilogySDK pod."
s.requires_arc = true

# 2
s.version = "0.6.9-qa"

# 3

# 4 - Replace with your name and e-mail address
s.author = { "-" => "-" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar)
s.homepage = "https://github.com/trilogy-group/mobilogytrans-ios-public.git"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/trilogy-group/mobilogytrans-ios-public.git",
             :tag => "#{s.version}" }

# 7
s.framework = "UIKit"
s.dependency 'Amplify'
s.dependency 'AmplifyPlugins/AWSCognitoAuthPlugin'
s.dependency 'AmplifyPlugins/AWSS3StoragePlugin'
s.dependency 'AmplifyPlugins/AWSPinpointAnalyticsPlugin'
s.dependency 'AmplifyPlugins/AWSAPIPlugin'
s.dependency 'CryptoSwift'
s.dependency 'AWSMobileClient'
s.dependency 'AWSS3'
s.dependency 'AWSAppSync'


# 8
s.vendored_frameworks = "MobilogySDK.xcframework"


# 9
#s.resources = "MobilogySDK/**/*.{png,jpeg,jpg,storyboard,xib,xcassets,xcdatamodeld}"

# 10
s.swift_version = "5.4"

end
