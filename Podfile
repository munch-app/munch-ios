platform :ios, '10.0'

target 'Munch' do
  use_frameworks!

  # Core Frameworks
  pod 'SnapKit', '~> 4.2'
  pod 'RxSwift', '~> 4.4'
  pod 'RxCocoa', '~> 4.4'
  pod 'Moya', '~> 12.0'
  pod 'Moya/RxSwift', '~> 12.0'
  pod 'RealmSwift', '~> 3.12.0'

  # Core Helpers
  pod 'SwiftLocation', '~> 3.2'
  pod 'Kingfisher', '~> 4.10'
  pod 'SwiftRichString', '~> 2.0.5'
  pod 'Cache'
  pod 'Localize-Swift'

  # Firebase (Auth/Analytics)
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Performance'
  pod 'Firebase/Auth'
  pod 'FirebaseUI/Facebook'
  pod 'Fabric', '~> 1.9.0'
  pod 'Crashlytics', '~> 3.12.0'

  # UI Components Library
  pod 'KMNavigationBarTransition', '~> 1.1'
  pod 'Shimmer'
  pod 'Toast-Swift', '~> 4.0.1'
  pod 'NVActivityIndicatorView', '~> 4.0'
  pod 'BEMCheckBox', '~> 1.4'
  pod 'RangeSeekSlider', '~> 1.7'
  pod 'PullToDismiss', '~> 2.1'
  pod 'MaterialComponents/BottomSheet'
  pod 'PinCodeView'

  # Deprecation:
  pod 'Alamofire', '~> 4.5'
  pod 'SwiftyJSON', '~> 4.0'

  # Pods for Testing
  target 'MunchTests' do
    inherit! :search_paths
  end

  target 'MunchUITests' do
    inherit! :search_paths
  end
end


post_install do |installer|
  # List of Pods to use as Swift 3.2
  targetSwift32 = ['RangeSeekSlider']

  installer.pods_project.targets.each do |target|
    if targetSwift32.include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '3.2'
      end
    end
  end
end
