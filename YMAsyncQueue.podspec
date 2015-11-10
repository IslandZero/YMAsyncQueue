Pod::Spec.new do |s|
  s.name         = 'YMAsyncQueue'
  s.version      = '0.1.0'
  s.summary      = 'YMAsyncQueue is a util class to execute block-based async methods serially.'
  s.homepage     = 'https://github.com/IslandZero/YMAsyncQueue'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Ryan Guo' => 'ryan@islandzero.net' }
  s.source       = { :git => 'https://github.com/IslandZero/YMAsyncQueue.git', :tag => "v#{s.version}" }
  s.requires_arc = true
  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'
  s.source_files = 'YMAsyncQueue/*.{h,m}'
end
