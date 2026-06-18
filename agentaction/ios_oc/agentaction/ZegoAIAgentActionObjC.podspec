Pod::Spec.new do |s|
  s.name         = 'ZegoAIAgentActionObjC'
  s.version      = '0.1.0'
  s.summary      = 'ZEGO AI Agent Action Objective-C client'
  s.description  = 'Objective-C client for ZEGO AI Agent Action room-channel signaling control with generated protobuf models.'
  s.homepage     = 'https://zego.im'
  s.license      = { :type => 'MIT' }
  s.author       = { 'ZEGO' => 'opensource@zego.im' }
  s.platform     = :ios, '12.0'
  s.source       = { :path => '.' }
  s.source_files = 'Sources/ZegoAIAgentActionObjC/**/*.{h,m}'
  s.public_header_files = [
    'Sources/ZegoAIAgentActionObjC/include/**/*.h',
    'Sources/ZegoAIAgentActionObjC/Generated/**/*.h'
  ]
  s.requires_arc = true
end
