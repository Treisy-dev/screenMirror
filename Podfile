platform :ios, '16.0'

def app_pods
    #pod 'ConnectSDK/Core', :git => 'https://github.com/ConnectSDK/Connect-SDK-iOS.git', :branch => 'master', :submodules => true
    #pod 'GCDWebServer'
    pod 'google-cast-sdk', '~> 4.8.3'
end

target 'TestFFMPEG' do
  use_frameworks!
  app_pods

    post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
        end
      end
    end
end