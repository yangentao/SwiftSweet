Pod::Spec.new do |s|
  s.name             = 'SwiftSweet'
  s.version          = '1.0.0'
  s.summary          = 'SwiftSweet is a library writen by entaoyang'
  s.homepage         = 'https://github.com/yangentao/SwiftSweet'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yangentao' => 'entaoyang@163.com' }
  s.source           = { :git => 'https://github.com/yangentao/SwiftSweet.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.12'
  s.source_files = 'SwiftSweet/Classes/**/*'
  
end
