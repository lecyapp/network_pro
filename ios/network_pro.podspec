#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint network_pro.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'network_pro'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for getting DNS and VPN information.'
  s.description      = <<-DESC
A Flutter plugin that provides DNS configuration and VPN connection status information on iOS and Android devices.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'network_pro/Sources/network_pro/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

