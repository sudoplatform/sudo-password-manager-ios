//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

/// Global log level, so we can change it when it's too chatty.
var passwordManagerLogDriver: SudoLogging.LogDriverProtocol = {
    #if DEBUG
    return NSLogDriver(level: .debug)
    #else
    return NSLogDriver(level: .info)
    #endif
}()

/// Global shared logger so we don't have to pass references everywhere we want logging capabilities.
extension Logger {
    static var shared: Logger = {
        return Logger(identifier: "com.anonyome.sudoPlatform.PasswordManager", driver: passwordManagerLogDriver)
    }()
}

extension DefaultPasswordManagerClient {
    /// Get/Set the global log level.
    public static var logLevel: SudoLogging.LogLevel {
        get {
            return passwordManagerLogDriver.logLevel
        }
        set {
            passwordManagerLogDriver.logLevel = newValue
        }
    }
}
