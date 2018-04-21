platform :ios, '9.0'

target 'Munch' do
  use_frameworks!

  # Core Pods for Munch
  pod 'RealmSwift', '~> 3.0'
  pod 'Alamofire', '~> 4.5'
  pod 'SwiftyJSON', '~> 4.0'
  pod 'SwiftLocation', '~> 3.1'
  pod 'Kingfisher', '~> 4.2'
  pod 'SnapKit', '~> 4.0'
  pod 'SwiftRichString', '~> 1.0'
  pod 'Cache'

  # Firebase
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Performance'
  pod 'Firebase/Auth'
  pod 'FirebaseUI/Facebook'
  pod 'GoogleSignIn'
  pod 'Fabric', '~> 1.7.2'
  pod 'Crashlytics', '~> 3.10.0'

  # Transition Library
  pod 'KMNavigationBarTransition', '~> 1.1'

  # UI Components Library
  pod 'Charts'
  pod 'TPKeyboardAvoiding', '~> 1.3'
  pod 'NVActivityIndicatorView', '~> 4.0'
  pod 'ESTabBarController-swift', '2.5'
  pod 'Shimmer', '~> 1.0'
  pod 'TTGTagCollectionView', :git=> 'https://github.com/Fuxingloh/TTGTagCollectionView.git', :branch => 'master'
  pod 'NativePopup', :git => 'https://github.com/Fuxingloh/NativePopup.git', :branch => 'master'

  pod 'SKPhotoBrowser', '~> 5.0'
  pod 'Cosmos', '~> 13.0'
  pod 'BEMCheckBox', '~> 1.4'
  pod 'RangeSeekSlider', '~> 1.7'

  # pod 'MVCarouselCollectionView'

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
