//
//  JSONStringConvertible.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// The basic protocol for command response
public protocol JSONStringConvertible: Encodable {
    var json: String {get}
}

extension JSONStringConvertible {
    public var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        encoder.dataEncodingStrategy = .custom{ data, encoder in
            var container = encoder.singleValueContainer()
            return try container.encode(data.hexString)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        let data = (try? encoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }
}