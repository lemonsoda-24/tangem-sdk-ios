//
//  AttestCardKeyCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `AttestCardKeyCommand`.
@available(iOS 13.0, *)
public struct AttestCardKeyResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Random salt generated by the card
    public let salt: Data
    /// Hashed concatenated Challenge and Salt: SHA256(Challenge | Salt) signed with Card_PrivateKey
    public let cardSignature: Data
    /// Random challenge generated by host application
    public let challenge: Data
    /// Card's public keys of linked cards if "full" attestationMode was selected. COS v6+.
    public let linkedCardPublicKeys: [Data]
    
    public func verify(with cardPublicKey: Data) throws -> Bool {
        var message = challenge + salt

        if !linkedCardPublicKeys.isEmpty {
            message += Constants.linkedCardsPrefix.data(using: .utf8)! + linkedCardPublicKeys.joined()
        }

        return try CryptoUtils.verify(curve: .secp256k1,
                                      publicKey: cardPublicKey,
                                      message: message,
                                      signature: cardSignature)
    }
}

@available(iOS 13.0, *)
public class AttestCardKeyCommand: Command {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private var challenge: Data?
    private let mode: Mode

    /// Default initializer
    /// - Parameters:
    ///   - mode: Full attestation available only for COS v6+. Usefull to getting all public keys of linked cards.
    ///   - challenge: Optional challenge. If nil, it will be created automatically and returned in command response
    public init(mode: AttestCardKeyCommand.Mode = .default, challenge: Data? = nil) {
        self.challenge = challenge
        self.mode = mode
    }
    
    deinit {
        Log.debug("AttestCardKeyCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if case .full = mode, card.firmwareVersion < .keysImportAvailable {
            return .notSupportedFirmwareVersion
        }

        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<AttestCardKeyResponse>) {
        if challenge == nil {
            do {
                challenge = try CryptoUtils.generateRandomBytes(count: 16)
            } catch {
                completion(.failure(error.toTangemSdkError()))
            }
        }
        
        guard let cardPublicKey = session.environment.card?.cardPublicKey else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                do {
                    let verified = try response.verify(with: cardPublicKey)
                    if !verified {
                        completion(.failure(.cardVerificationFailed))
                        return
                    }
                    
                    completion(.success(response))
                } catch {
                    completion(.failure(error.toTangemSdkError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.challenge, value: challenge)

      //  if let backupStatus = card.backupStatus, backupStatus.isActive,
      //     let attestationMode = mode.rawMode {
        try tlvBuilder.append(.interactionMode, value: Mode.full.rawMode)
      //  }

        return CommandApdu(.attestCardKey, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> AttestCardKeyResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)

        return AttestCardKeyResponse(
            cardId: try decoder.decode(.cardId),
            salt: try decoder.decode(.salt),
            cardSignature: try decoder.decode(.cardSignature),
            challenge: self.challenge!,
            linkedCardPublicKeys: try decodeLinkedCardPublicKeys(from: tlv))
    }

    private func decodeLinkedCardPublicKeys(from tlv: [Tlv]) throws -> [Data] {
        let linkedCardPublicKeysTlv = tlv.filter { $0.tag == .backupCardPublicKey }

        let linkedCardPublicKeys = try linkedCardPublicKeysTlv.map { tlv in
            let decoder = TlvDecoder(tlv: [tlv])
            let linkedCardPublicKey: Data = try decoder.decode(.backupCardPublicKey)
            return linkedCardPublicKey
        }

        return linkedCardPublicKeys
    }
}

@available(iOS 13.0, *)
public extension AttestCardKeyCommand {
    enum Mode: String, StringCodable {
        /// Attest only current card
        case `default`
        /// Attest linked cards
        case full

        fileprivate var rawMode: RawMode? {
            switch self {
            case .default:
                return nil
            case .full:
                return .full
            }
        }
    }
}

@available(iOS 13.0, *)
public extension AttestCardKeyResponse {
    enum Constants {
        static let linkedCardsPrefix = "BACKUP_CARDS"
    }
}

@available(iOS 13.0, *)
private extension AttestCardKeyCommand.Mode {
    enum RawMode: Byte, InteractionMode {
        case full = 0x01
    }
}
