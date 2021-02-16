Pod::Spec.new do |spec|
  spec.name                  = 'SudoPasswordManager'
  spec.version               = '2.1.0'
  spec.author                = { 'Sudo Platform Engineering' => 'sudoplatform-engineering@anonyome.com' }
  spec.homepage              = 'https://sudoplatform.com'
  spec.summary               = 'Password manager SDK for the Sudo Platform by Anonyome Labs.'
  spec.license               = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  spec.source                = { :git => 'https://github.com/sudoplatform/sudo-password-manager-ios.git', :tag => "v#{spec.version}" }
  spec.source_files          = "SudoPasswordManager/**/*.swift"
  spec.ios.deployment_target = '13.0'
  spec.requires_arc          = true
  spec.swift_version         = '5.0'
  
  spec.resource              = 'Resources/SudoPasswordManager.bundle'
  spec.resources             = ['SudoPasswordManager/**/*.pdf']

  spec.dependency 'zxcvbn-ios', '~> 1.0'
  spec.dependency 'SudoLogging', '~> 0.3'
  spec.dependency 'SudoKeyManager', '~> 1.2'
  spec.dependency 'SudoUser', '>= 7.14', '< 11.0'
  spec.dependency 'SudoProfiles', '>= 5.6', '< 10.0'
  spec.dependency 'SudoSecureVault', '>= 2.0', '< 5.0'
  spec.dependency 'SudoEntitlements', '>= 1.1', '< 3.0'
end
