#
# Be sure to run `pod lib lint SLSensorTag.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SLSensorTag'
  s.version          = '0.1.0'
  s.summary          = 'The SLSensorTag framework allows iOS devices to connect to TI SensorTags and receive data from its sensors and buttons'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
The SLSensorTag framework allows iOS devices to connect to TI SensorTags and receive data from its sensors and buttons. SLSensorTag abstracts the complexity of converting low-level data obtained from the SensorTag and provides easy to use delegate methods. This library was built to work with TI SimpleLink SensorTag CC2650STK.
                       DESC

  s.homepage         = 'https://bitbucket.org/AydanBedingham/slsensortag'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'AydanBedingham' => 'aydan.bedingham@gmail.com' }
  s.source           = { :git => 'https://bitbucket.org/AydanBedingham/slsensortag.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Sources/**/*'
  
  # s.resource_bundles = {
  #   'SLSensorTag' => ['SLSensorTag/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
