source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

def all_pods
    pod 'AWSCore'
    pod 'AWSDynamoDB'
    pod 'AWSS3'
    pod 'Realm'
    pod 'RealmSwift'
    pod 'FontAwesome.swift'
    pod 'Eureka', :git => 'https://github.com/xmartlabs/Eureka.git', :branch => 'master'
    pod 'Arcane', :git => 'https://github.com/onmyway133/Arcane.git', :branch => 'master'
    pod 'KDCircularProgress', :git => 'https://github.com/kaandedeoglu/KDCircularProgress.git', :branch => 'master'
    pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
    pod 'ReachabilitySwift'
    pod 'ActionSheetPicker-3.0'
    pod 'SwiftLocation'
    pod 'FileBrowser'
    pod 'KeychainAccess'
    pod 'ReactiveSwift'
end

target :'iOS' do
    platform :ios, '9.0'
    all_pods
end

#target :'tvOS' do
    # AWS does not support tvOS yet: https://github.com/aws/aws-sdk-ios/issues/280
    #platform :tvos, '9.0'
    #all_pods
#end

#target :'MacOS' do
    # AWS does not support MacOS yet
    #platform :osx, '9.2'
    #all_pods
#end


#target :'iOSTests' do
#    all_pods
#end

#post_install do |installer|
#    installer.pods_project.targets.each do |target|
#        target.build_configurations.each do |config|
#            config.build_settings['SWIFT_VERSION'] = '3.0'
#        end
#    end
#end
