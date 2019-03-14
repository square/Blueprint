Pod::Spec.new do |s|
  s.name         = 'BlueprintCommonControls'
  s.version      = '0.1.0'
  s.summary      = 'UIKit-backed elements for Blueprint'
  s.homepage     = 'https://www.github.com/square/blueprint'
  s.license      = 'Apache License, Version 2.0'
  s.author       = 'Square'
  s.source       = { :git => 'https://github.com/square/blueprint.git', :tag => s.version }

  s.swift_version = '4.2'

  s.ios.deployment_target = '9.3'

  s.source_files = 'BlueprintCommonControls/Sources/**/*.swift'

  s.dependency 'Blueprint'

  s.test_spec 'SnapshotTests' do |test_spec|
    
    test_spec.ios.deployment_target = '10.0'

    test_spec.source_files = 'BlueprintCommonControls/Tests/Sources/*.swift'
    test_spec.resources = 'BlueprintCommonControls/Tests/Resources/**/*'
    test_spec.framework = 'XCTest'

    test_spec.dependency 'SnapshotTesting', '~> 1.3'
  end
end
