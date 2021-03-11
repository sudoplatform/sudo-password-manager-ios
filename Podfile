# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'SudoPasswordManager' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SudoPasswordManager
  podspec :name => 'SudoPasswordManager'

  target 'SudoPasswordManagerTests' do
    # Pods for testing
    podspec :name => 'SudoPasswordManager'
  end


# supress warnings for pods
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
            config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = "YES"
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        end
    end
end

end

