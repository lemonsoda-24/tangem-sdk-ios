//
//  Handlers.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 21.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
class ScanHandler: JSONRPCHandler {
    var method: String { "SCAN" }
    var requiresCardId: Bool { false }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = ScanTask()
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SignHashesHandler: JSONRPCHandler {
    var method: String { "SIGN_HASHES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletIndex: WalletIndex = try parameters.value(for: "walletIndex")
        let hashes: [Data] = try parameters.value(for: "hashes")
        
        let derivationRawPath: String? = try parameters.value(for: "derivationPath")
        let derivationPath: DerivationPath? = try derivationRawPath.map{ try DerivationPath(rawPath: $0) }
        
        let command = SignHashesCommand(hashes: hashes,
                                        walletIndex: walletIndex,
                                        derivationPath: derivationPath)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SignHashHandler: JSONRPCHandler {
    var method: String { "SIGN_HASH" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletIndex: WalletIndex = try parameters.value(for: "walletIndex")
        let hash: Data = try parameters.value(for: "hash")
        
        let derivationRawPath: String? = try parameters.value(for: "derivationPath")
        let derivationPath: DerivationPath? = try derivationRawPath.map{ try DerivationPath(rawPath: $0) }
        
        let command = SignHashCommand(hash: hash,
                                      walletIndex: walletIndex,
                                      derivationPath: derivationPath)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class CreateWalletHandler: JSONRPCHandler {
    var method: String { "CREATE_WALLET" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let curve: EllipticCurve = try parameters.value(for: "curve")
        let command = CreateWalletTask(curve: curve)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class PurgeWalletHandler: JSONRPCHandler {
    var method: String { "PURGE_WALLET" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletIndex: WalletIndex = try parameters.value(for: "walletIndex")
        let command = PurgeWalletCommand(walletIndex: walletIndex)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class PersonalizeHandler: JSONRPCHandler {
    var method: String { "PERSONALIZE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let config: CardConfig = try parameters.value(for: "config")
        let issuer: Issuer = try parameters.value(for: "issuer")
        let manufacturer: Manufacturer = try parameters.value(for: "manufacturer")
        let acquirer: Acquirer = try parameters.value(for: "acquirer")
        
        let command = PersonalizeCommand(config: config,
                                         issuer: issuer,
                                         manufacturer: manufacturer,
                                         acquirer: acquirer)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class DepersonalizeHandler: JSONRPCHandler {
    var method: String { "DEPERSONALIZE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let command = DepersonalizeCommand()
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SetAccessCodeHandler: JSONRPCHandler {
    var method: String { "SET_ACCESSCODE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let accessCode: String? = try parameters.value(for: "accessCode")
        let command = SetUserCodeCommand(accessCode: accessCode)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class SetPasscodeHandler: JSONRPCHandler {
    var method: String { "SET_PASSCODE" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let passcode: String? = try parameters.value(for: "passcode")
        let command = SetUserCodeCommand(passcode: passcode)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class ResetUserCodesHandler: JSONRPCHandler {
    var method: String { "RESET_USERCODES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        return SetUserCodeCommand.resetUserCodes.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class ReadFilesHandler: JSONRPCHandler {
    var method: String { "READ_FILES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let readPrivateFiles: Bool? = try parameters.value(for: "readPrivateFiles")
        let fileName: String? = try parameters.value(for: "fileName")
        let walletIndex: WalletIndex? = try parameters.value(for: "walletIndex")
        
        let task = ReadFilesTask(fileName: fileName, walletIndex: walletIndex)
        readPrivateFiles.map { task.shouldReadPrivateFiles = $0 }
        
        return task.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class WriteFilesHandler: JSONRPCHandler {
    var method: String { "WRITE_FILES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let files: [FileToWrite] = try parameters.value(for: "files")
        let command = WriteFilesTask(files: files)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class DeleteFilesHandler: JSONRPCHandler {
    var method: String { "DELETE_FILES" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let indices: [Int]? = try parameters.value(for: "indices")
        let command = DeleteFilesTask(indices: indices)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class ChangeFileSettingsHandler: JSONRPCHandler {
    var method: String { "CHANGE_FILE_SETTINGS" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let changes: [Int: FileVisibility] = try parameters.value(for: "changes")
        let command = ChangeFileSettingsTask(changes: changes)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class DeriveWalletPublicKeyHandler: JSONRPCHandler {
    var method: String { "DERIVE_WALLET_PUBLIC_KEY" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletIndex: WalletIndex = try parameters.value(for: "walletIndex")
        let rawDerivationPath: String = try parameters.value(for: "derivationPath")
        let derivationPath: DerivationPath = try DerivationPath(rawPath: rawDerivationPath)
        
        let command = DeriveWalletPublicKeyTask(walletIndex: walletIndex,
                                                derivationPath: derivationPath)
        return command.eraseToAnyRunnable()
    }
}

@available(iOS 13.0, *)
class DeriveWalletPublicKeysHandler: JSONRPCHandler {
    var method: String { "DERIVE_WALLET_PUBLIC_KEYS" }
    
    func makeRunnable(from parameters: [String : Any]) throws -> AnyJSONRPCRunnable {
        let walletIndex: WalletIndex = try parameters.value(for: "walletIndex")
        let rawDerivationPaths: [String] = try parameters.value(for: "derivationPaths")
        let derivationPaths: [DerivationPath] = try rawDerivationPaths.map { try DerivationPath(rawPath: $0) }
        
        let command = DeriveWalletPublicKeysTask(walletIndex: walletIndex,
                                                 derivationPaths: derivationPaths)
        return command.eraseToAnyRunnable()
    }
}
