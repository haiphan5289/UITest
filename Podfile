# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'GooDic' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for GooDic
  
  # Rx
  pod 'RxSwift', '~> 5'
  pod 'RxCocoa', '~> 5'
  pod 'RxFirebase/Firestore'
  
  # Firebase Services
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/InAppMessaging'
  pod 'Firebase/Messaging'
  pod 'Firebase/Firestore'
  pod 'FirebaseFirestoreSwift' # Optionally, include the Swift extensions if you're using Swift.
  pod 'Firebase/Auth'
  pod 'Firebase/Performance'
  
  # required by GooID SDK
  pod 'GoogleSignIn'
  pod 'FBSDKLoginKit'
  
  # AppsFlyer
  pod 'AppsFlyerFramework' , '6.5.2'

  target 'GooDicTests' do
    inherit! :search_paths
    # Pods for testing
#    pod 'RxBlocking', '~> 5'
#    pod 'RxTest', '~> 5'
  end

  target 'GooDicUITests' do
    # Pods for testing
  end

end

post_install do | installer |
  installer.pods_project.targets.each do |target|
    if target.name == 'RxSwift'
      target.build_configurations.each do |config|
        if config.name == 'Debug (Development)'
          config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['-D', 'TRACE_RESOURCES']
        end
      end
    end
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
    end
  end
  
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-GooDic/Pods-GooDic-acknowledgements.plist', 'GooDic/Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
  installer.aggregate_targets.each do |aggregate_target|
    aggregate_target.xcconfigs.each do |config_name, config_file|
      xcconfig_path = aggregate_target.xcconfig_path(config_name)
      config_file.save_as(xcconfig_path)
    end
  end
end
