Pod::Spec.new do |s|
  s.name         = 'BlueprintUICommonControls'
  s.version      = '0.20.0'
  s.summary      = 'UIKit-backed elements for Blueprint'
  s.homepage     = 'https://www.github.com/square/blueprint'
  s.license      = 'Apache License, Version 2.0'
  s.author       = 'Square'
  s.source       = { :git => 'https://github.com/square/blueprint.git', :tag => s.version }

  s.swift_version = '5.1'

  s.ios.deployment_target = '11.0'

  s.source_files = 'BlueprintUICommonControls/Sources/**/*.swift'

  s.dependency 'BlueprintUI'

  s.test_spec 'Tests' do |test_spec|
    test_spec.library = 'swiftsimd'
    test_spec.source_files = 'BlueprintUICommonControls/Tests/**/*.swift'
    test_spec.framework = 'XCTest'
  end
end
