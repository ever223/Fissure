//
//  Control.swift
//  Fissure
//
//  Created by xiaoo_gan on 10/1/15.
//  Copyright © 2015 xiaoo_gan. All rights reserved.
//

import SpriteKit

public enum ControlType: String {
    case Push = "push"
    case Gravity = "gravity"
    case Repel = "repel"
    case Propel = "propel"
    case Slow = "slow"
    case Warp = "warp"
    case Shape = "shape"
}

class Control: NSObject {
    let warpNodeRadiusUnit: CGFloat = 28.4
    var type: ControlType = .Push
    var angle: CGFloat
    var minRadius: CGFloat
    var maxRadius: CGFloat
    var power: CGFloat
    var powerVector: CGVector
    var canScale = true
    var canRotate = false
    var canMove = true
    var node: SKSpriteNode
    var icon: SKSpriteNode?
    var shape: SKShapeNode?
    var affectedProjectiles: [SKNode]
    
    var initalPosition: CGPoint
    var initalRadius: CGFloat
    var connectedWarp: Control?
    var scene: GameScene?
    var radius: CGFloat

    var position: CGPoint {
        didSet {
            node.position = self.position
            shape?.position = self.position
            icon?.position = self.position
        }
    }
    
    func checkRadius(var r: CGFloat) {
        if r < minRadius {
            r = minRadius
        }
        if r > maxRadius {
            r = maxRadius
        }
        if radius == r {
            return
        }
        radius = r
        node.setScale(radius / initalRadius)
    }
    
    init(data: JSON, screenSize: CGSize) {
        
        let offset: CGFloat = (screenSize.width > 481) ? 44 : 0
        let ScreenWidth: CGFloat = 480
        let ScreenHeight = screenSize.height
        if let temp = ControlType(rawValue: data["type"].string!) {
            type = temp
        }
        angle = data["angle"].floatValue.cgf
        let px = data["px"].floatValue.cgf
        let py = data["py"].floatValue.cgf
        position = CGPoint(x: px * ScreenWidth + offset, y: py * ScreenHeight)
        radius = data["radius"].floatValue.cgf * ScreenWidth
        minRadius = data["minRadiusScale"].floatValue.cgf * radius
        maxRadius = data["maxRadiusScale"].floatValue.cgf * radius
        canMove = data["canMove"].boolValue
        canScale = data["canScale"].boolValue
        canRotate = data["canRotate"].boolValue
        power = data["power"].floatValue.cgf
        powerVector = CGVector(dx: power * ScreenWidth * cos(angle), dy: power * ScreenWidth * sin(angle))
        initalRadius = radius
        initalPosition = position
        affectedProjectiles = []
        
        node = SKSpriteNode(imageNamed: "disc")
        
        super.init()
        
        node.position = position
        node.alpha = 1.0
        node.color = UIColor.whiteColor()
        node.colorBlendFactor = 1
        node.size = CGSize(width: radius * 2, height: radius * 2)
        node.userData = ["isControl": true, "control": self]
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        node.physicsBody?.friction = 0
        node.physicsBody?.dynamic = true
        node.physicsBody?.categoryBitMask = Static.physCatControlTrans
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.contactTestBitMask = Static.physCatProj
        
        switch type {
        case .Push:
            icon = SKSpriteNode(imageNamed: "disc_push")
            icon?.color = UIColor(red: 255.0 / 255.0, green: 102.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0)
            icon?.zRotation = angle - (M_PI / 2).cgf
            node.color = UIColor(red: 255.0 / 255.0, green: 102.0 / 255.0, blue: 102.0 / 255.0, alpha: 0.5)
        case .Propel:
            icon = SKSpriteNode(imageNamed: "disc_propel")
            icon?.color = UIColor(red: 0.0 / 255.0, green: 0.0 / 255.0, blue: 180.0 / 255.0, alpha: 1.0)
            node.color = UIColor(red: 0.0 / 255.0, green: 102.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.5)
        case .Slow:
            icon = SKSpriteNode(imageNamed: "disc_slow")
            icon?.color = UIColor(red: 255.0 / 255.0, green: 0.0 / 255.0, blue: 51.0 / 255.0, alpha: 1.0)
            node.color = UIColor(red: 255.0 / 255.0, green: 0.0 / 255.0, blue: 51.0 / 255.0, alpha: 0.7)
        case .Gravity:
            icon = SKSpriteNode(imageNamed: "disc_attract")
            icon?.color = UIColor(red: 255.0 / 255.0, green: 255.0 / 255.0, blue: 153.0 / 255.0, alpha: 1.0)
            icon?.zRotation = angle - (M_PI / 2).cgf
            node.color = UIColor(red: 255.0 / 255.0, green: 128.0 / 255.0, blue: 0.0 / 255.0, alpha: 0.5)
        case .Repel:
            icon = SKSpriteNode(imageNamed: "disc_repel")
            icon?.color = UIColor(red: 255.0 / 255.0, green: 102.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0)
            icon?.zRotation = (M_PI / 2).cgf
            node.color = UIColor(red: 255.0 / 255.0, green: 102.0 / 255.0, blue: 255.0 / 255.0, alpha: 0.5)
        case .Warp:
            node.color = UIColor.clearColor()
            if let path = NSBundle.mainBundle().pathForResource("warp", ofType: "sks") {
                if let emitter = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? SKEmitterNode {
                    emitter.particleScale *= (radius / warpNodeRadiusUnit)
                    emitter.particleScaleSpeed *= (radius / warpNodeRadiusUnit)
                    emitter.particleSpeedRange *= (radius / warpNodeRadiusUnit)
                    node.addChild(emitter)
                }
        }
        case .Shape:
            node.alpha = 0
            shape = SKShapeNode()
            let points = data["points"].arrayValue
            if points.count == 0 {
                shape?.path = UIBezierPath(ovalInRect: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)).CGPath
                shape?.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            } else {
                var first = true
                let path = UIBezierPath()
                for point in points {
                    let mAngle = point["angle"].floatValue.cgf
                    let mRadius = point["radius"].floatValue.cgf
                    let px = cos(mAngle) * mRadius * radius
                    let py = sin(mAngle) * mRadius * radius
                    if first {
                        path.moveToPoint(CGPoint(x: px, y: py))
                        first = false
                    } else {
                        path.addLineToPoint(CGPoint(x: px, y: py))
                    }
                }
                path.closePath()
                shape?.path = path.CGPath
                shape?.physicsBody = SKPhysicsBody(polygonFromPath: path.CGPath)
            }
            shape?.zRotation = angle
            shape?.antialiased = true
            shape?.fillColor = UIColor(white: 0.5, alpha: 0.7)
            shape?.strokeColor = UIColor(white: 0.5, alpha: 0.7)
            shape?.lineWidth = 1
            shape?.position = position
            
            shape?.physicsBody?.friction = 0
            shape?.physicsBody?.dynamic = true
            shape?.physicsBody?.categoryBitMask = Static.physCatControlColl
            shape?.physicsBody?.contactTestBitMask = 0
            shape?.physicsBody?.collisionBitMask = 0
            
            node.physicsBody?.collisionBitMask = 0
            node.physicsBody?.contactTestBitMask = 0
            node.physicsBody?.collisionBitMask = 0
        }
        
        if let ico = icon {
            ico.colorBlendFactor = 1
            ico.position = position
        }
    }
    
    func updateAffectedProjectilesForDuration(durationTime: CFTimeInterval) {
        let duration = CGFloat(durationTime)
        switch type {
        case .Push:
            let xmag = powerVector.dx * duration
            let ymag = powerVector.dy * duration
            var toRemove = [SKNode]()
            for node in affectedProjectiles {
                if node.parent == nil {
                    toRemove.append(node)
                    continue
                }
                node.physicsBody?.velocity = CGVector(dx:(node.physicsBody?.velocity.dx)! + xmag, dy: (node.physicsBody?.velocity.dy)! + ymag)
                node.zRotation = atan2((node.physicsBody?.velocity.dy)!, (node.physicsBody?.velocity.dx)!)
            }
            for node in toRemove {
                if let pos = affectedProjectiles.indexOf(node) {
                    affectedProjectiles.removeAtIndex(pos)
                    node.removeFromParent()
                }
            }
        case .Propel:
            let multiplier = 1 + power * duration
            for node in affectedProjectiles {
                node.physicsBody?.velocity = CGVector(dx:(node.physicsBody?.velocity.dx)! * multiplier, dy: (node.physicsBody?.velocity.dy)! * multiplier)
            }
        case .Slow:
            let multiplier = 1 - power * duration
            var toRemove = [SKNode]()
            for node in affectedProjectiles {
                node.physicsBody?.velocity = CGVector(dx:(node.physicsBody?.velocity.dx)! * multiplier, dy: (node.physicsBody?.velocity.dy)! * multiplier)
                if fabs((node.physicsBody?.velocity.dx)!) < 3 && fabs((node.physicsBody?.velocity.dy)!) < 3 {
                    toRemove.append(node)
                }
            }
            for node in toRemove {
                if let pos = affectedProjectiles.indexOf(node) {
                    affectedProjectiles.removeAtIndex(pos)
                    node.removeFromParent()
                }
            }
        case .Gravity:
            let multiplier = power * duration
            let drag = 1 - 0.5 * duration
            var toRemove = [SKNode]()
            for node in affectedProjectiles {
                if node.parent == nil {
                    toRemove.append(node)
                    continue
                }
                let dx = self.node.position.x - node.position.x
                let dy = self.node.position.y - node.position.y
                
                let dist = sqrt(dx * dx + dy * dy) + radius / 2
                let force = multiplier * 50000 / (dist * dist)
                node.physicsBody?.velocity = CGVector(dx:((node.physicsBody?.velocity.dx)! + dx * force) * drag, dy: ((node.physicsBody?.velocity.dy)! + dy * force) * drag)
                
                let vx = (node.physicsBody?.velocity.dx)!
                let vy = (node.physicsBody?.velocity.dy)!
                node.zRotation = atan2(vy, vx)
                var remove = (fabs(vx) < 3 && fabs(vy) < 3)
                remove = remove || (fabs(dx) < 6 && fabs(dy) < 6 && fabs(vx) < 40 && fabs(vy) < 40)
                if remove {
                    toRemove.append(node)
                }
            }
            for node in toRemove {
                if let pos = affectedProjectiles.indexOf(node) {
                    affectedProjectiles.removeAtIndex(pos)
                    node.removeFromParent()
                }
            }
        case .Repel:
            let multiplier = power * duration
            for node in affectedProjectiles {
                let dx = node.position.x - self.node.position.x
                let dy = node.position.y - self.node.position.y
                let dist = sqrt(dx * dx + dy * dy) + radius / 4
                let force = multiplier * 50000 / (dist * dist)
                node.physicsBody?.velocity = CGVector(dx:((node.physicsBody?.velocity.dx)! + dx * force), dy: ((node.physicsBody?.velocity.dy)! + dy * force))
                node.zRotation = atan2((node.physicsBody?.velocity.dy)!, (node.physicsBody?.velocity.dx)!)
            }
        case .Warp:
            for node in affectedProjectiles {
                if let _ = node.userData?["warped"] {
                    node.userData?.removeObjectForKey("warped")
                    continue
                }
                let dx = node.position.x - self.node.position.x
                let dy = node.position.y - self.node.position.y
                node.userData?["warped"] = true
                node.position = CGPoint(x: connectedWarp!.position.x + dx, y: connectedWarp!.position.y + dy)
                scene?.removeNodeFromAllControlsNotInRange(node)
            }
            affectedProjectiles.removeAll()
        default:
            break
        }
    }
}
