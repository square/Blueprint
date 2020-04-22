Pod::Spec.new do |s|
  s.name         = 'BlueprintUIDebugging'
  s.version      = '0.9.1'
  s.summary      = 'A debugging toolkit for BlueprintUI to make it easier to examine and debug elements.'
  s.homepage     = 'https://www.github.com/square/blueprint'
  s.license      = 'Apache License, Version 2.0'
  s.author       = 'Square'
  s.source       = { :git => 'https://github.com/square/blueprint.git', :tag => s.version }

  s.swift_version = '5.1'

  s.ios.deployment_target = '10.0'

  s.source_files = 'BlueprintUIDebugging/Sources/**/*.swift'

  s.dependency 'BlueprintUI'
  s.dependency 'BlueprintUICommonControls'

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'BlueprintUIDebugging/Tests/**/*.swift'
    test_spec.framework = 'XCTest'
  end
end
