# frozen_string_literal: true

BLUEPRINT_VERSION ||= '5.1.0'

SWIFT_VERSION ||= File.read(File.join(__dir__, '.swift-version'))

BLUEPRINT_IOS_DEPLOYMENT_TARGET ||= '15.0'
