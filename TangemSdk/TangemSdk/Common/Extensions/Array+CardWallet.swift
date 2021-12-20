//
//  Array+CardWallet.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public extension Array where Element == Card.Wallet {
    subscript(walletIndex: WalletIndex) -> Element? {
        get {
            return first(where: { $0.index == walletIndex })
        }
        
        set(newValue) {
            let index = firstIndex(where: { $0.index == walletIndex })
            
            if let newValue = newValue {
                if let index = index {
                    self[index] = newValue
                } else {
                    self.append(newValue)
                }
            } else {
                if let index = index {
                    remove(at: index)
                }
            }
        }
    }
}

