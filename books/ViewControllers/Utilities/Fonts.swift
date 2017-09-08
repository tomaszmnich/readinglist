//
//  Fonts.swift
//  books
//
//  Created by Andrew Bennet on 02/09/2017.
//  Copyright © 2017 Andrew Bennet. All rights reserved.
//

import Foundation
import UIKit

class Fonts {
    private static let gillSansFont = UIFont(name: "GillSans", size: 12)!
    private static let gillSansSemiBoldFont = UIFont(name: "GillSans-Semibold", size: 12)!
    
    static func gillSans(ofSize: CGFloat) -> UIFont {
        return gillSansFont.withSize(ofSize)
    }
    
    static func gillSans(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        return scaledFont(gillSansFont, forTextStyle: textStyle)
    }
    
    static func gillSansSemiBold(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        return scaledFont(gillSansSemiBoldFont, forTextStyle: textStyle)
    }
    
    static func scaledFont(_ font: UIFont, forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        let fontSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        return font.withSize(fontSize)
    }
}
