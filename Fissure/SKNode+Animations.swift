//
//  SKNode+Animations.swift
//  Fissure
//
//  Created by xiaoo_gan on 9/30/15.
//  Copyright © 2015 xiaoo_gan. All rights reserved.
//

import Foundation
import SpriteKit

extension SKNode {
    public func bounceInAfterDelay(delay: CGFloat, duration: CGFloat, bounces: Int
        ) {
            let stiffnessCoefficient: CGFloat = 0.01
            let startValue: CGFloat = 0.8
            let endValue: CGFloat = 1
            let diff = endValue - startValue
            let coeff = startValue - endValue
            var alpha = log2(stiffnessCoefficient / fabs(diff))
            
            if alpha > 0 {
                alpha = -1.0 * alpha
            }
            let numberOfPeriods = CGFloat(bounces / 2) + 0.5
            let omega: CGFloat = numberOfPeriods * 2 * CGFloat(M_PI)
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * CGFloat(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
                self.runAction(SKAction.customActionWithDuration(NSTimeInterval(duration), actionBlock: { (node: SKNode, elapseTime: CGFloat) -> Void in
                    let progress = elapseTime / duration
                    let oscillationComponent = cos(omega * progress)
                    let value = coeff * pow(CGFloat(M_E), alpha * progress) * oscillationComponent + endValue
                    node.setScale(value)
                }))
            }
    }
    public func bounceToPosition(point: CGPoint, scale: CGFloat, delay: CGFloat, duration: CGFloat, bounces: Int
        ) {
            let stiffnessCoefficient: CGFloat = 0.01
            
            let startScale = self.xScale
            let endScale = scale
            let diffScale = endScale - startScale
            let coeffScale = startScale - endScale
            
            let startX = position.x
            let endX = point.x
            let diffX = endX - startX
            let coeffX = startX - endX
            
            let startY = position.y
            let endY = point.y
            let diffY = endY - startY
            let coeffY = startY - endY
            
            let alphaScale = (diffScale == 0 ? 1: log2(stiffnessCoefficient / fabs(diffScale)))
            var alphaX = (diffX == 0) ? 1 : log2(stiffnessCoefficient / fabs(diffX))
            if alphaX > 0 {
                alphaX = -1.0 * alphaX
            }
            
            var alphaY = (diffY == 0) ? 1 : log2(stiffnessCoefficient / fabs(diffY))
            if alphaY > 0 {
                alphaY = -1.0 * alphaY
            }
            
            let numberOfPeriods: CGFloat = CGFloat(bounces / 2) + 0.5
            let omega: CGFloat = numberOfPeriods * 2 * CGFloat(M_PI)
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * CGFloat(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
                self.runAction(SKAction.customActionWithDuration(NSTimeInterval(duration), actionBlock: { (node: SKNode, elapseTime: CGFloat) -> Void in
                    let progress = elapseTime / duration
                    let oscillationComponent = cos(omega * progress)
                    let valueScale = coeffScale * pow(CGFloat(M_E), alphaScale * progress) * oscillationComponent + endScale
                    let valueX = coeffX * pow(CGFloat(M_E), alphaX * progress) * oscillationComponent + endX
                    let valueY = coeffY * pow(CGFloat(M_E), alphaY * progress) * oscillationComponent + endY
                    node.position = CGPoint(x: valueX, y: valueY)
                    node.setScale(valueScale)
                }))
            }
    }
    public func animationToAlpha(alpha: CGFloat, delay: CGFloat, duration: CGFloat) {
        let startAlpha = self.alpha
        let alphaDiff = alpha - startAlpha
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * CGFloat(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
            self.runAction(SKAction.customActionWithDuration(NSTimeInterval(duration), actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
                let progress = elapsedTime / duration
                let value = startAlpha + alphaDiff * progress
                node.alpha = value
            }))
        }
    }
    public func animationToScale(scale: CGFloat, delay: CGFloat, duration: CGFloat) {
        let startScale = self.xScale
        let scaleDiff = scale - startScale
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * CGFloat(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
            self.runAction(SKAction.customActionWithDuration(NSTimeInterval(duration), actionBlock: { (node: SKNode, elapsedTime: CGFloat) -> Void in
                let progress = elapsedTime / duration
                let value = startScale + scaleDiff * progress
                node.setScale(value)
            }))
        }
    }
}
