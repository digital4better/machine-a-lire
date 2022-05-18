#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_opencv.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name                    = 'native_opencv'
  s.version                 = '4.5.3'
  s.summary                 = 'Native OpenCV (Computer Vision) for iOS wrapper.'
  s.description             = <<-DESC
Wrapper around Native OpenCV (Computer Vision) library pod
                              DESC
  s.homepage                = "http://opencv.org"
  s.license                 = { :type => "Apache-2.0" }
  s.authors                 = "https://github.com/opencv/opencv/graphs/contributors"
  s.source                  = { :http => "https://github.com/opencv/opencv/releases/download/4.5.3/opencv-4.5.3-ios-framework.zip", :sha256 => "b85c23953e66f202a5e4b83484f90556ad4ea9df6fcb7934044d5d4decf2898f" }
  s.source_files            = 'Classes/**/*'
  s.ios.vendored_frameworks = "**/iOS/opencv2.framework"

  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
