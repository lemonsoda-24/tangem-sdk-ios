//
//  AccessCodeRepository.swift
//  TangemSdk
//
//  Created by Andrey Chukavin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import LocalAuthentication

public protocol AccessCodeRepository {
    func shouldAskForAuthentication(for cardId: String?) -> Bool
    func hasAccessToBiometricAuthentication() -> Bool
    func hasAccessCodes() -> Bool
    func hasAccessCode(for cardId: String) -> Bool

    func ignoringCard(with cardId: String) -> Bool
    func setIgnoreCards(with cardIds: [String], ignore: Bool)
    
    func prepareAuthentication(for cardId: String?, completion: @escaping () -> Void)
    func fetchAccessCode(for cardId: String, completion: @escaping (Result<String, AccessCodeRepositoryError>) -> Void)
    func saveAccessCode(_ accessCode: String, for cardIds: [String], completion: @escaping (Result<Void, AccessCodeRepositoryError>) -> Void)
    
    func removeAllAccessCodes()
}

public enum AccessCodeRepositoryError: Error {
    case noBiometricsAccess
    case noAccessCodeFound
    case cancelled
}

@available(iOS 13.0, *)
class DefaultAccessCodeRepository: AccessCodeRepository {
    private typealias CardIdList = Set<String>
    private typealias AccessCodeList = [String: String]
    
    private let storage = Storage()
    private let secureStorage = SecureStorage()
    private var context: LAContext?
    
    private let savedCardIdListKey = "card-id-list"
    private let accessCodeListKey = "access-code-list"
    private let ignoredCardIdListKey = "ignored-card-id-list"
    private let localizedReason: String
    private let onlyUseBiometrics: Bool
    private var authenticationPolicy: LAPolicy {
        onlyUseBiometrics ? .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication
    }
    
    init(authenticationReason: String, onlyUseBiometrics: Bool) {
        self.localizedReason = authenticationReason
        self.onlyUseBiometrics = onlyUseBiometrics
    }
    
    func shouldAskForAuthentication(for cardId: String?) -> Bool {
        guard askedForLocalAuthentication() else {
            return false
        }
        
        if let cardId = cardId {
            return hasAccessCode(for: cardId)
        } else {
            return hasAccessCodes()
        }
    }
    
    func hasAccessToBiometricAuthentication() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    func hasAccessCodes() -> Bool {
        do {
            let savedCardIds = try cardIds(key: savedCardIdListKey)
            return !savedCardIds.isEmpty
        } catch {
            print("Failed to get card ID list: \(error)")
            return false
        }
    }
    
    func hasAccessCode(for cardId: String) -> Bool {
        do {
            let savedCardIds = try cardIds(key: savedCardIdListKey)
            return savedCardIds.contains(cardId)
        } catch {
            print("Failed to get card ID list: \(error)")
            return false
        }
    }
    
    func ignoringCard(with cardId: String) -> Bool {
        do {
            let ignoredCardIds = try cardIds(key: ignoredCardIdListKey)
            return ignoredCardIds.contains(cardId)
        } catch {
            print("Failed to get ignored card ID list: \(error)")
            return false
        }
    }
    
    func setIgnoreCards(with cardIds: [String], ignore: Bool) {
        do {
            var ignoredCardIds = try self.cardIds(key: ignoredCardIdListKey)
            if ignore {
                ignoredCardIds.formUnion(cardIds)
            } else {
                ignoredCardIds.subtract(cardIds)
            }
            try saveCardIds(cardIds: ignoredCardIds, key: ignoredCardIdListKey)
        } catch {
            print("Failed to save ignored card ID list: \(error)")
        }
    }
    
    func prepareAuthentication(for cardId: String?, completion: @escaping () -> Void) {
        guard shouldAskForAuthentication(for: cardId) else {
            completion()
            return
        }
        
        authenticate(context: LAContext()) { result in
            switch result {
            case .failure(let error):
                print("Failed to authenticate", error)
            case .success(let authenticatedContext):
                self.context = authenticatedContext
            }
            completion()
        }
    }
    
    func fetchAccessCode(for cardId: String, completion: @escaping (Result<String, AccessCodeRepositoryError>) -> Void) {
        guard let context = self.context else {
            completion(.failure(AccessCodeRepositoryError.noBiometricsAccess))
            return
        }
        
        authenticate(context: context) { result in
            if case let .failure(error) = result {
                completion(.failure(error))
                return
            }
            
            do {
                let accessCodes = try self.accessCodes(context: context)
                
                if let accessCode = accessCodes[cardId] {
                    completion(.success(accessCode))
                } else {
                    completion(.failure(AccessCodeRepositoryError.noAccessCodeFound))
                }
            } catch {
                print(error)
                completion(.failure(.noAccessCodeFound))
            }
        }
    }
    
    func saveAccessCode(_ accessCode: String, for cardIds: [String], completion: @escaping (Result<Void, AccessCodeRepositoryError>) -> Void) {
        let context = LAContext()
        authenticate(context: context) { result in
            if case let .failure(error) = result {
                completion(.failure(error))
                return
            }
            
            do {
                var accessCodes = try self.accessCodes(context: context)
                for cardId in cardIds {
                    accessCodes[cardId] = accessCode
                }
                try self.saveAccessCodes(accessCodes: accessCodes, context: context)
                
                var savedCardIds = try self.cardIds(key: self.savedCardIdListKey)
                savedCardIds.formUnion(cardIds)
                try self.saveCardIds(cardIds: savedCardIds, key: self.savedCardIdListKey)
                
                self.setIgnoreCards(with: cardIds, ignore: false)
                
                completion(.success(()))
            } catch {
                print(error)
                completion(.failure(.noBiometricsAccess))
            }
        }
    }
    
    func removeAllAccessCodes() {
        // We don't NEED to authenticate, we do it just to confirm
        authenticate(context: LAContext()) { result in
            guard case .success = result else { return }

            do {
                let keys = [
                    self.savedCardIdListKey,
                    self.accessCodeListKey,
                    self.ignoredCardIdListKey,
                ]

                try keys.forEach {
                    try self.secureStorage.delete(account: $0)
                }
            } catch {
                print("Failed to remove access codes: \(error)")
            }
        }
    }
    
    private func authenticate(context: LAContext, completion: @escaping (Result<LAContext, AccessCodeRepositoryError>) -> Void) {
        context.localizedFallbackTitle = onlyUseBiometrics ? "" : nil
        
        var accessError: NSError?
        guard context.canEvaluatePolicy(authenticationPolicy, error: &accessError) else {
            if let accessError = accessError {
                print("No biometrics access", accessError)
            }
            completion(.failure(AccessCodeRepositoryError.noBiometricsAccess))
            return
        }

        storage.set(boolValue: true, forKey: .askedForLocalAuthentication)
        
        context.evaluatePolicy(authenticationPolicy, localizedReason: localizedReason) { _, error in
            if let error = error {
                print("Failed to authenticate", error)
                
                switch (error as? LAError)?.code {
                case .userCancel, .appCancel, .systemCancel:
                    completion(.failure(AccessCodeRepositoryError.cancelled))
                default:
                    completion(.failure(AccessCodeRepositoryError.noBiometricsAccess))
                }
                
                return
            }
            
            completion(.success(context))
        }
    }
    
    private func askedForLocalAuthentication() -> Bool {
        storage.bool(forKey: .askedForLocalAuthentication)
    }
    
    // MARK: Helper save/get methods
    
    private func cardIds(key: String) throws -> CardIdList {
        let data = try secureStorage.get(account: key) ?? Data()
        guard !data.isEmpty else {
            return CardIdList()
        }
        return try JSONDecoder().decode(CardIdList.self, from: data)
    }
    
    private func saveCardIds(cardIds: CardIdList, key: String) throws {
        let data = try JSONEncoder().encode(cardIds)
        try secureStorage.store(object: data, account: key, overwrite: true)
    }
    
    private func accessCodes(context: LAContext) throws -> AccessCodeList {
        let data = try secureStorage.get(account: accessCodeListKey, context: context) ?? Data()
        guard !data.isEmpty else {
            return AccessCodeList()
        }
        return try JSONDecoder().decode(AccessCodeList.self, from: data)
    }
    
    private func saveAccessCodes(accessCodes: AccessCodeList, context: LAContext) throws {
        let data = try JSONEncoder().encode(accessCodes)
        try secureStorage.store(object: data, account: accessCodeListKey, overwrite: true, context: context)
    }
}
