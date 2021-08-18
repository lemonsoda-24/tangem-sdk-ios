//
//  TangemSdkStyle.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public class TangemSdkStyle: ObservableObject {
    public var colors: Colors = .default
    public var textSizes: TextSizes = .default
    public var indicatorWidth: Float = 12
    
    public static var `default`: TangemSdkStyle = .init()
}

@available(iOS 13.0, *)
public extension TangemSdkStyle {
    struct Colors {
        public var tint: Color = Color.blue
        
        public var disabledButton: Color = Color.gray
        
        public var errorTint: Color = Color.red
        
        public var indicatorBackground: Color = .adaptiveColor(dark: .darkGray, light: UIColor.LightPalette.indicatorBackground)
        
        public var nfcSmallCircle: Color = .adaptiveColor(dark: .darkGray, light: UIColor.LightPalette.smallCircleColor)
        
        public var nfcBigCircle: Color = .adaptiveColor(dark: .gray, light: UIColor.LightPalette.bigCircleColor)
        
        public var phoneBackground: Color = .adaptiveColor(dark: .black, light: .white)
        
        public var phoneStroke: Color = .adaptiveColor(dark: .white, light: .black)
        
        public var cardColor: Color = .adaptiveColor(dark: UIColor.DarkPalette.cardColor, light: UIColor.LightPalette.cardColor)
        
        public static var `default`: Colors = .init()
    }
}

@available(iOS 13.0, *)
public extension TangemSdkStyle {
    struct TextSizes {
        public var indicatorLabel: CGFloat = 50
        
        public static var `default`: TextSizes = .init()
    }
}