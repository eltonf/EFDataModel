#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = "EFDataModel"
  s.version          = "0.1.0"
  s.summary          = "A short description of EFDataModel."
  s.description      = "Easily save and retrieve Objective-C objects using sqlite + FMDB"
  s.homepage         = "http://EXAMPLE/NAME"
  s.screenshots      = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Elton Faggett" => "eltonf@290design.com" }
  s.source           = { :git => "http://EXAMPLE/NAME.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/EXAMPLE'

  # s.platform     = :ios, '5.0'
  s.ios.deployment_target = '6.0'
  # s.osx.deployment_target = '10.7'
  s.requires_arc = true

  s.source_files = 'EFDataModel'
  s.resources = 'Assets/*.png'

  s.ios.exclude_files = 'EFDataModel/osx'
  s.osx.exclude_files = 'EFDataModel/ios'
  s.public_header_files = 'EFDataModel/**/*.h'
  # s.frameworks = 'SomeFramework', 'AnotherFramework'
  s.dependency 'FMDB', '~> 2.2'
end
