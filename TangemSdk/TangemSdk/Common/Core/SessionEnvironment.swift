//
//  SessionEnvironment.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// All available encryption modes
public enum EncryptionMode: String, Codable {
    case none
    case fast
    case strong
    
    var byteValue: Byte {
        switch self {
        case .none:
            return 0x00
        case .fast:
            return 0x01
        case .strong:
            return 0x02
        }
    }
}


/// Pair of private and public key
public struct KeyPair: Equatable, Codable {
    public let privateKey: Data
    public let publicKey: Data
}

/// Contains information about pin code
public struct PinCode {
    static let defaultPin1 = "000000"
    static let defaultPin2 = "000"
    
    public enum PinType {
        case pin1
        case pin2
    }
    
    let type: PinType
    let value: Data?
    
    var isDefault: Bool {
        switch type {
        case .pin1:
            return PinCode.defaultPin1.sha256() == value
        case .pin2:
            return PinCode.defaultPin2.sha256() == value
        }
    }

    internal init(_ type: PinType) {
        switch type {
        case .pin1:
            self.value = PinCode.defaultPin1.sha256()
        case .pin2:
            self.value = PinCode.defaultPin2.sha256()
        }
        self.type = type
    }
    
    internal init(_ type: PinType, stringValue: String) {
        self.value = stringValue.sha256()
        self.type = type
    }
    
    internal init(_ type: PinType, value: Data?) {
        self.value = value
        self.type = type
    }
}

/// Contains data relating to a Tangem card. It is used in constructing all the commands,
/// and commands can return modified `SessionEnvironment`.
public struct SessionEnvironment {
    /// Current card, read by preflight `Read` command
    public internal(set) var card: Card? = nil
    
    let config: Config
    
    weak var terminalKeysService: TerminalKeysService?
    
    var encryptionMode: EncryptionMode = .none
    
    var encryptionKey: Data? = nil
    
    var cvc: Data? = nil //todo: remove
    
    var pin1: PinCode = PinCode(.pin1)
    
    var pin2: PinCode = PinCode(.pin2)
    
    var legacyMode: Bool { config.legacyMode ?? NfcUtils.isPoorNfcQualityDevice }
    
    /// Keys for Linked Terminal feature
    var terminalKeys: KeyPair? {
        if config.linkedTerminal ?? !NfcUtils.isPoorNfcQualityDevice {
            return terminalKeysService?.keys
        }
        
        return nil
    }
}
