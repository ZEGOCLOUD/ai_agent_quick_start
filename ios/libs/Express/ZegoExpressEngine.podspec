Pod::Spec.new do |s|
  s.name             = 'ZegoExpressEngine'
  s.version          = '3.19.0'
  s.summary          = 'Zego Express Engine Framework'
  s.description      = 'Zego Express Engine Framework for iOS'
  
  s.homepage         = 'https://www.zego.im'
  s.license          = { :type => 'Copyright', :text => 'Copyright © 2024 ZEGO. All Rights Reserved.\n' }
  s.author           = { 'ZEGO' => 'https://www.zego.im' }
  
  s.ios.deployment_target = '11.0'
  
  s.source           = { :path => '.' }
  # 修改 vendored_frameworks 路径
  s.vendored_frameworks = 'Library/ZegoExpressEngine.xcframework'
end 