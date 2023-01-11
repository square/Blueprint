# frozen_string_literal: true

require_relative 'version'

Pod::Spec.new do |s|
  s.name         = 'BlueprintUI'
  s.version      = BLUEPRINT_VERSION
  s.summary      = 'Swift library for declarative UI construction'
  s.homepage     = 'https://www.github.com/square/blueprint'
  s.license      = 'Apache License, Version 2.0'
  s.author       = 'Square'
  s.source       = { git: 'https://github.com/square/blueprint.git', tag: s.version }

  s.swift_version = SWIFT_VERSION

  s.ios.deployment_target = '14.0'

  s.source_files = 'BlueprintUI/Sources/**/*.swift'

  s.weak_framework = 'SwiftUI'

  s.pod_target_xcconfig = {
    'APPLICATION_EXTENSION_API_ONLY' => EXTENSION_API_ONLY,
  }

  s.test_spec 'Tests' do |test_spec|
    test_spec.library = 'swiftsimd'
    test_spec.source_files = 'BlueprintUI/Tests/**/*.swift'
    test_spec.framework = 'XCTest'
  end
end
