# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'books' do
  use_frameworks!

  # Pods for books
  pod 'DZNEmptyDataSet', '~> 1.8'
  pod 'SwiftyJSON', '~> 3.1'
  pod 'Eureka', :git => 'https://github.com/xmartlabs/Eureka.git', :branch => 'feature/Xcode9-Swift4'
  pod 'RxSwift', '~> 4.0.0-alpha'
  pod 'RxCocoa', '~> 4.0.0-alpha'
  pod 'SVProgressHUD', '~> 2.2'
  pod 'SimulatorStatusMagic', :configurations => ['Debug'], :git => 'https://github.com/shinydevelopment/SimulatorStatusMagic', :branch => 'master'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'CHCSVParser', :git => 'https://github.com/davedelong/CHCSVParser.git'

  target 'books_UITests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'books_UnitTests' do
    inherit! :search_paths
    # Pods for testing
  end

end
