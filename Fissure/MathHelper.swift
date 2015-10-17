//
//  MathHelper.swift
//  Fissure
//
//  Created by xiaoo_gan on 9/30/15.
//  Copyright © 2015 xiaoo_gan. All rights reserved.
//

import Foundation
import UIKit

public struct MathHelper {
    static func floatBetween(low: CGFloat, high: CGFloat) -> CGFloat {
        let norm = CGFloat( rand() % 65536 ) / 65536.0
        return low + (high - low) * norm
    }
    static func floatBetween(low: Float, high: Float) -> Float {
        let norm = Float(rand() % 65536 ) / 65536.0
        return low + (high - low) * norm
    }
}
