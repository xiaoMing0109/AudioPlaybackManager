#
# Be sure to run `pod lib lint AudioPlaybackManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AudioPlaybackManager'
  s.version          = '0.1.0'
  s.summary          = 'A audio playback manager.'
  s.homepage         = 'https://github.com/xiaoMing0109/AudioPlaybackManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LiuMing' => 'liuming_0109@163.com' }
  s.source           = { :git => 'https://github.com/xiaoMing0109/AudioPlaybackManager.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_version         = '5.0'
  s.requires_arc          = true
  
  s.source_files = 'AudioPlaybackManager/Classes/**/*'
  
  s.frameworks = 'UIKit', 'Foundation', 'AVFoundation', 'MediaPlayer'
  
  s.dependency 'VIMediaCache', '~> 0.4'
end
