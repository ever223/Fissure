//
//  SpawnPoint.swift
//  Fissure
//
//  Created by xiaoo_gan on 9/23/15.
//  Copyright © 2015 xiaoo_gan. All rights reserved.
//

import Foundation
import SpriteKit

public class SpawnPoint: NSObject {
    var position: CGPoint
    var positionJitter: CGSize
    var initalVelocity: CGVector
    var friction: CGFloat
    var frameInterval: Int
    var node: SKSpriteNode
    var color: UIColor
    var frameCount: Int
    
    init(data: JSON, size: CGSize) {

        let offset: CGFloat = (size.width > 481) ? 44 : 0
        let width: CGFloat = 480
        let height = size.height
        
        let px: CGFloat = data["px"].floatValue.cgf
        let py: CGFloat = data["py"].floatValue.cgf
        position = CGPoint(x: px * width + offset, y: py * height)
        
        let jx: CGFloat = data["jx"].floatValue.cgf
        let jy: CGFloat = data["jy"].floatValue.cgf
        positionJitter = CGSize(width: jx * width, height: jy * height)
        
        friction = data["friction"].floatValue.cgf
        frameInterval = data["frameInterval"].intValue
        
        let angle = data["angle"].floatValue.cgf
        let speed = data["speed"].floatValue.cgf * width
        initalVelocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
        color = UIColor(red: (data["color"]["r"].floatValue / 255.0).cgf,
                        green: (data["color"]["g"].floatValue / 255.0).cgf,
                        blue: (data["color"]["b"].floatValue / 255.0).cgf,
                        alpha: (data["color"]["a"].floatValue).cgf)
        
        node = SKSpriteNode(imageNamed: "disc")
        node.alpha = 0.1
        node.color = color
        node.position = position
        node.colorBlendFactor = 1
        node.size = CGSize(width: max(positionJitter.width, positionJitter.height) + 5, height: max(positionJitter.width, positionJitter.height) + 5)
        frameCount = 1
        super.init()
    }
    
    internal func shouldSpawnThisFrame()-> Bool {
        frameCount++
        if frameCount > frameInterval {
            frameCount = 1
            return true
        }
        return false
    }
}
