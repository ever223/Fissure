//
//  Projectile.swift
//  Fissure
//
//  Created by xiaoo_gan on 9/23/15.
//  Copyright © 2015 xiaoo_gan. All rights reserved.
//

import SpriteKit

public class Projectile: NSObject {
    var emitter: SKEmitterNode
    var node: SKSpriteNode
    var color: UIColor
    
    init(point: SpawnPoint) {
        let width = MathHelper.floatBetween(-point.positionJitter.width, high: point.positionJitter.width)
        let height = MathHelper.floatBetween(-point.positionJitter.height, high: point.positionJitter.height)
        
        node = SKSpriteNode(imageNamed: "line5x1")
        node.position = CGPoint(x: point.position.x + width, y: point.position.y + height)
        
        color = point.color
        node.color = color
        node.colorBlendFactor = 1
        node.physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(Static.projecticlePhysRadius))
        node.physicsBody?.velocity = point.initalVelocity
        node.physicsBody?.friction = CGFloat(point.friction)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.allowsRotation = true
        node.physicsBody?.linearDamping = CGFloat(point.friction)
        node.physicsBody?.restitution = 1
        node.zRotation = atan2((node.physicsBody?.velocity.dy)!, (node.physicsBody?.velocity.dx)!)
        node.physicsBody?.categoryBitMask = Static.physCatProj
        node.physicsBody?.collisionBitMask = Static.physCatControlColl
        node.physicsBody?.contactTestBitMask = Static.physCatEdge
                                                | Static.physCatControlTrans
                                                | Static.physCatTarget
                                                | Static.physCatFissure
                                                | Static.physCatControlColl
        node.userData = ["fissureIndex": 0]
        
        emitter = SKEmitterNode()
        super.init()
        if let path = NSBundle.mainBundle().pathForResource("projectile_trail", ofType: "sks") {
            if let e = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? SKEmitterNode {
                emitter = e
                emitter.particleColorSequence = sequeneForColor(point.color)
                node.addChild(emitter)
                node.userData = ["emitter": emitter]
            }
        }
    }
    private func sequeneForColor(color: UIColor) -> SKKeyframeSequence {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let color1 = UIColor(red: r, green: g, blue: b, alpha: 0.15)
        let color2 = UIColor(red: r, green: g, blue: b, alpha: 0.0)
        return SKKeyframeSequence(keyframeValues: [color1, color2], times: [0, 1])
    }
}

