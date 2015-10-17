//
//  Target.swift
//  Fissure
//
//  Created by xiaoo_gan on 9/23/15.
//  Copyright © 2015 xiaoo_gan. All rights reserved.
//

import SpriteKit

public class Target: NSObject {
    
    let targetRadius: CGFloat = 20
    let dialsPerTarget = 7
    let numDialImages = 7

    let hysteresis = 1.0
    let progressPerHit = 0.5
    let lossPerTime = 0.6
    
    var progress = 0.0
    var position: CGPoint
    var currentTime: CFTimeInterval = 0.0
    var lastHitTime: CFTimeInterval = 0.0
    var accelToTime: CFTimeInterval = 0.0
    var timeFull: CFTimeInterval = 0.0
    var dials: [SKSpriteNode]
    var node: SKNode
    var matchedFissure: Int
    
    public var color: UIColor! {
        willSet {
            for dial in self.dials {
                dial.color = newValue
                dial.alpha = 0.4
            }
        }
    }
    
    
    init(data:JSON, screenSize: CGSize) {
        let offset: CGFloat = (screenSize.width > 481) ? 44 : 0
        
        let width: CGFloat = 480
        let height = screenSize.height
    
        let px = data["px"].floatValue.cgf
        let py = data["py"].floatValue.cgf
        
        position = CGPoint(x: px * width + offset, y: py * height)
        matchedFissure = data["matchedFissure"].intValue
        node = SKNode()
        dials = []
        
        super.init()
        node.position = position
        node.userData = ["isTarget": true, "target": self]
        node.physicsBody = SKPhysicsBody(circleOfRadius: targetRadius)
        node.physicsBody?.dynamic = true
        node.physicsBody?.categoryBitMask = Static.physCatTarget
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.contactTestBitMask = 0
        node.physicsBody?.friction = 0
        
        let dialFactor = [1, 0.8, 1, 0.4, 1, 0.6, 1]
        
        for i in 0..<dialsPerTarget {
            let dial = SKSpriteNode(imageNamed: String(format: "activity_disc_%d", i))
            dial.position = CGPointZero
            dial.color = UIColor.blackColor()
            dial.colorBlendFactor = 1
            dial.alpha = 0.15
            let radius = targetRadius.d * 2 * dialFactor[i]
            dial.size = CGSize(width: radius, height: radius)
            dial.zRotation = CGFloat(Double(rand()) % 1000 / 1000.0 * 2 * M_PI)
            dial.physicsBody = SKPhysicsBody(circleOfRadius: targetRadius)
            
            dial.physicsBody?.dynamic = true
            dial.physicsBody?.categoryBitMask = 0
            dial.physicsBody?.collisionBitMask = 0
            dial.physicsBody?.contactTestBitMask = 0
            dial.physicsBody?.angularVelocity = 0
            dial.physicsBody?.affectedByGravity = false
            dial.physicsBody?.friction = 0
            dial.physicsBody?.angularDamping = 0
            
            node.addChild(dial)
            dials.append(dial)
        }
       
    }
    
    func hitByProjectile() {
        accelToTime = currentTime + 0.1
    }
    
    func controlMoved() {
        timeFull = 0
    }
    func updateForDuration(duration: CFTimeInterval) {
        currentTime += duration
        if currentTime < accelToTime {
            lastHitTime = currentTime
            if progress < 1 {
                progress += progressPerHit * duration
                if progress > 1 {
                    progress = 1
                }
            }
        }
        if progress >= 1 {
            timeFull += duration
        } else {
            timeFull = 0
        }
        
        if progress <= 0 {
            progress = 0
            return
        }
        let sinceLastHit = currentTime - lastHitTime
        if sinceLastHit > hysteresis {
            progress -= duration * lossPerTime
        }
        updateDialSpeed()
    }
    func updateDialSpeed() {
        for (index, dial) in dials.enumerate() {
            let clockwise = (index < 3) ? 1 : -1
            let v = (4 * clockwise * (index + 2) / dialsPerTarget).d * progress
            dial.physicsBody?.angularVelocity = CGFloat(v)
        }
    }
}