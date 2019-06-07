Pod::Spec.new do |s|
  s.name         = 'BlueprintUICommonControls'
  s.version      = '0.2.2'
  s.summary      = 'UIKit-backed elements for Blueprint'
  s.homepage     = 'https://www.github.com/square/blueprint'
  s.license      = 'Apache License, Version 2.0'
  s.author       = 'Square'
  s.source       = { :git => 'https://github.com/square/blueprint.git', :tag => s.version }

  s.swift_version = '4.2'

  s.ios.deployment_target = '9.3'

  s.source_files = 'BlueprintUICommonControls/Sources/**/*.swift'

  s.dependency 'BlueprintUI'

  s.test_spec 'SnapshotTests' do |test_spec|
    test_spec.source_files = 'BlueprintUICommonControls/Tests/Sources/**/*.swift'
    test_spec.resources = ['BlueprintUICommonControls/Tests/Sources/ReferenceImages/**/*.png', 'BlueprintUICommonControls/Tests/Resources/**/*.jpg']
    test_spec.framework = 'XCTest'
  end
end
