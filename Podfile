platform :ios, '9.3'
use_frameworks!

target 'Instabeat' do
    pod 'SVProgressHUD', '~> 2.1'
    pod 'Alamofire', '~> 4.2'
    pod 'NAExpandableTableController', :git => 'https://github.com/narciero/NAExpandableTableController.git', :branch => 'master'
    pod 'JTAppleCalendar', '~> 6.1'
    pod 'Fabric', '~> 1.6'
    pod 'Crashlytics', '~> 3.8'
    pod 'SwiftGen', '~> 4.0'
    pod 'STZPopupView', '~> 1.1'
    pod 'SwiftKeychainWrapper', '~> 3.0'
    pod 'FacebookLogin', '~> 0.2'
    pod 'RealmSwift', '~> 2.1'
    pod 'AlamofireObjectMapper', '~> 4.0'
    pod 'ObjectMapper+Realm', '~> 0.2'
    pod 'Google/SignIn'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
            config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            config.build_settings['SWIFT_VERSION'] = '3.0'
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
    end
end
