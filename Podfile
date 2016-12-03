source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def all_pods
    pod 'AWSCore'
    #pod 'AWSAutoScaling'
    #pod 'AWSCloudWatch'
    #pod 'AWSCognito'
    #pod 'AWSCognitoIdentityProvider'
    pod 'AWSDynamoDB'
    #pod 'AWSEC2'
    #pod 'AWSElasticLoadBalancing'
    #pod 'AWSIoT'
    #pod 'AWSKinesis'
    #pod 'AWSLambda'
    #pod 'AWSMachineLearning'
    #pod 'AWSMobileAnalytics'
    pod 'AWSS3'
    #pod 'AWSSES'
    #pod 'AWSSimpleDB'
    #pod 'AWSSNS'
    #pod 'AWSSQS'
    pod 'Realm'
    pod 'RealmSwift'
    pod 'FontAwesome.swift', :git => 'https://github.com/thii/FontAwesome.swift.git', :branch => 'master'
    pod 'Eureka', :git => 'https://github.com/xmartlabs/Eureka.git', :branch => 'master'
    pod 'Arcane', :git => 'https://github.com/onmyway133/Arcane.git', :branch => 'master'
    pod 'TextAttributes'
    pod 'KDCircularProgress'
    pod 'ChameleonFramework/Swift'
    pod 'ReachabilitySwift'
    pod 'ActionSheetPicker-3.0'
    pod 'SwiftLocation'
    pod 'KeychainAccess'
    pod 'FileBrowser'
    pod 'ReactiveSwift', '= 1.0.0-alpha.4'
end

target :'iOS' do
    platform :ios, '9.0'
    all_pods
end

target :'tvOS' do
    # AWS does not support tvOS yet: https://github.com/aws/aws-sdk-ios/issues/280
    #platform :tvos, '9.0'
    #all_pods
end

target :'MacOS' do
    # AWS does not support MacOS yet
    #platform :osx, '9.2'
    #all_pods
end


target :'iOSTests' do
    all_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
