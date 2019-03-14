platform :ios, '12.0'
inhibit_all_warnings!

project 'SampleApp/SampleApp.xcodeproj'

def blueprint_pods
  pod 'Blueprint', :path => './Blueprint.podspec', :testspecs => ['Tests'] 
  pod 'BlueprintCommonControls', :path => './BlueprintCommonControls.podspec', :testspecs => ['SnapshotTests'] 
end

target 'SampleApp' do
  blueprint_pods
end

target 'Tutorial 1' do
  blueprint_pods
end

target 'Tutorial 1 (Completed)' do
  blueprint_pods
end

target 'Tutorial 2' do
  blueprint_pods
end

target 'Tutorial 2 (Completed)' do
  blueprint_pods
end
