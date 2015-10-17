//
//  Fissure.swift
//  Fissure
//
//  Created by xiaoo_gan on 9/23/15.
//  Copyright © 2015 xiaoo_gan. All rights reserved.
//

import SpriteKit

class Fissure: SKNode {
    internal var color: UIColor
    internal var fissureIndex: Int!
    
    init(data: JSON, screenSize: CGSize) {
        
        let offset: CGFloat = (screenSize.width > 481) ? 44 : 0
        let width: CGFloat = 480
        let height = screenSize.height
        let px = data["px"].floatValue.cgf
        let py = data["py"].floatValue.cgf
        color = UIColor(red: CGFloat(data["color"]["r"].floatValue / 255.0),
            green: CGFloat(data["color"]["g"].floatValue / 255.0),
            blue: CGFloat(data["color"]["b"].floatValue / 255.0),
            alpha: CGFloat(data["color"]["a"].floatValue))
        let radius = CGFloat(data["radius"].floatValue) * screenSize.width
        
        super.init()
        
        self.position = CGPoint(x: px * width + offset, y: py * height)
        
        
        self.zPosition = 1
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        self.physicsBody?.dynamic = true
        self.physicsBody?.categoryBitMask = Static.physCatFissure
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.contactTestBitMask = 0
        self.physicsBody?.friction = 0
        
        if let path = NSBundle.mainBundle().pathForResource("fissure", ofType: "sks") {
            if let emitter = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? SKEmitterNode {
                emitter.particleColorSequence = sequeneForColor(color)
                addChild(emitter)
            }
        }
    }

    private func sequeneForColor(color: UIColor) -> SKKeyframeSequence {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKKeyframeSequence(keyframeValues: [UIColor(red: r, green: g, blue: b, alpha: 0.5), UIColor(white: 0.4, alpha: 0.0)], times: [0, 1])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
