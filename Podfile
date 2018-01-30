# Uncomment the next line to define a global platform for your project
platform :ios, '9.3'

target 'books' do
  use_frameworks!

  # Pods for books
  pod 'DZNEmptyDataSet', '~> 1.8'
  pod 'SwiftyJSON', '~> 3.1'
  pod 'Eureka', '~> 4.0'
  pod 'ImageRow', :git => 'https://github.com/EurekaCommunity/ImageRow.git'
  pod 'SVProgressHUD', '~> 2.2'
  pod 'SimulatorStatusMagic', :configurations => ['Debug']
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'CHCSVParser', :git => 'https://github.com/davedelong/CHCSVParser.git'
  pod 'Firebase/Core'

  target 'books_UITests' do
    inherit! :complete
    # Pods for testing
  end

  target 'books_UnitTests' do
    inherit! :complete
    # Pods for testing
  end

  target 'ReadingListEarlGrey' do
    inherit! :complete
    pod 'EarlGrey'
  end

end
