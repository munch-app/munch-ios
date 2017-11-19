platform :ios, '9.0'

target 'Munch' do
  use_frameworks!

  # Core Pods for Munch
  pod 'RealmSwift', '~> 3.0'
  pod 'Alamofire', '~> 4.5'
  pod 'SwiftyJSON', '~> 4.0'
  pod 'SwiftLocation', '~> 3.0.1-beta'
  pod 'Kingfisher', '~> 4.2'
  pod 'SnapKit', '~> 4.0'
  pod 'SwiftRichString', '~> 1.0'

  # Service Library
  pod 'Auth0', '~> 1.9'
  pod 'Lock', '~> 2.4.2'

  # Transition Library
  pod 'KMNavigationBarTransition', '~> 1.1'

  # UI Components Library
  pod 'TPKeyboardAvoiding', '~> 1.3'
  pod 'NVActivityIndicatorView', '~> 4.0'
  pod 'ESTabBarController-swift', '~> 2.5'
  pod 'Shimmer', '~> 1.0'
  pod 'TTGTagCollectionView', '~> 1.7'
  pod 'SKPhotoBrowser', '~> 5.0'
  pod 'Cosmos', '~> 12.0'
  pod 'BEMCheckBox', '~> 1.4'

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
  targetSwift32 = ['Lock']

  installer.pods_project.targets.each do |target|
    if targetSwift32.include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '3.2'
      end
    end
  end
end