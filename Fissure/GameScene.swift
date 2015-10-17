//
//  GameScene.swift
//  Fissure
//
//  Created by xiaoo_gan on 9/23/15.
//  Copyright (c) 2015 xiaoo_gan. All rights reserved.
//

import SpriteKit

public protocol GameSceneDelegate {
    func sceneAllTargetsLit()
    func sceneReadyToTransition()
}

class GameScene: SKScene {
    
    let scaleRadiusWidth: CGFloat = 20
    
    private var lastFrameTime: CFTimeInterval = 0.0
    private var projectileParticleLayerNode: SKNode
    private var projectileLayerNode: SKNode
    
    private var draggedControl: Control?
    private var draggedOffset = CGPoint()
    
    private var scalingControl: Control?
    private var scalingOffset: CGFloat = 0.0
    private var canTriggerFull = false
    private var shouldSpawnProjectile = false
    
    private var spawnPoints = [SpawnPoint]()
    private var controls = [Control]()
    private var targets = [Target]()
    private var fissures = [Fissure]()
    
    internal var sceneDelegate: GameSceneDelegate?
    
    override init(size: CGSize) {
        projectileParticleLayerNode = SKNode()
        projectileLayerNode = SKNode()
        
        super.init(size: size)
        backgroundColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRectInset(frame, -150, -100))
        self.physicsBody?.categoryBitMask = Static.physCatEdge
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadLevelData(data: JSON) {
        let screenSize = size
        projectileParticleLayerNode.position = CGPoint(x: 50, y: 200)
        projectileParticleLayerNode.alpha = 1.0
        addChild(projectileParticleLayerNode)
        
        projectileLayerNode.zPosition = 0.5
        projectileLayerNode.alpha = 1.0
        addChild(projectileLayerNode)
    
        // 延时一秒，设置发射源可发射
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.shouldSpawnProjectile = true
        }

        setBackgroundColor(data["scene"][0])
        
        // Load Spawns
        for (index, spawnData) in data["spawns"].arrayValue.enumerate() {
            let spawn = SpawnPoint(data: spawnData, size: screenSize)
            spawnPoints.append(spawn)
            addChild(spawn.node)
            print(String(format: "在点（%.2f, %.2f）加载发射点 %d", spawn.node.position.x, spawn.position.y, index + 1))
            let delay = 0.1 + index.cgf * 0.25
            spawn.node.alpha = 0
            
            spawn.node.bounceInAfterDelay(delay, duration: 0.9, bounces: 5)
            spawn.node.animationToAlpha(0.1, delay: delay, duration: 0.4)
        }
        var warps = [Control]()
        
        // Load Controls
        for (index, controlData) in data["controls"].arrayValue.enumerate() {
            if controlData["ignore"].boolValue {
                continue
            }
            let control = Control(data: controlData, screenSize: screenSize)
            control.scene = self
            
            controls.append(control)
            
            addChild(control.node)
            if let icon = control.icon {
                addChild(icon)
            }
            if let shape = control.shape {
                addChild(shape)
            }
            if control.type == ControlType.Warp {
                warps.append(control)
            }
            control.node.alpha = 0
            control.icon?.alpha = 0
            control.shape?.alpha = 0
            
            let delay = 0.1 + index.cgf * 0.1
            control.node.bounceInAfterDelay(delay, duration: 0.9, bounces: 5)
            
            if control.type != ControlType.Shape {
                control.node.animationToAlpha(0.5, delay: delay, duration: 0.4)
            }
            control.icon?.bounceInAfterDelay(delay, duration: 0.9, bounces: 5)
            control.icon?.animationToAlpha(0.8, delay: delay, duration: 0.4)
            control.shape?.bounceInAfterDelay(delay, duration: 0.9, bounces: 5)
            control.shape?.animationToAlpha(1, delay: delay, duration: 0.4)
        }
        
        // Load Fissure
        for (index, fissureData) in data["fissures"].arrayValue.enumerate() {
            let fissure = Fissure(data: fissureData, screenSize: screenSize)
            fissure.fissureIndex = index + 1
            fissures.append(fissure)
            print(String(format: "在点（%.2f, %.2f）加载粒子源 %d", fissure.position.x, fissure.position.y, index + 1))
            addChild(fissure)
            let delay = (fissure.fissureIndex + 1).cgf * 0.25
            fissure.alpha = 0
            fissure.animationToAlpha(1, delay: delay, duration: 1.5)
        }
        
        // Load targets
        for (index, targetData) in data["targets"].arrayValue.enumerate() {
            let target = Target(data: targetData, screenSize: screenSize)
            if target.matchedFissure > 0 {
                target.color = fissures[target.matchedFissure - 1].color
            } else {
                target.color = spawnPoints[0].color
            }
            
            targets.append(target)
            addChild(target.node)
            
            let delay = 0.1 + index.cgf * 0.15
            target.node.alpha = 0
            target.node.bounceInAfterDelay(delay, duration: 0.9, bounces: 5)
            target.node.animationToAlpha(1, delay: delay, duration: 0.4)
        }
        
        // Load Warps
        if warps.count == 0 {
            print("没有虫洞区域！")
        } else if warps.count % 2 == 0{
            for var i = 0; i < warps.count; i+=2 {
                let w1 = warps[i]
                let w2 = warps[i+1]
                w1.connectedWarp = w2
                w2.connectedWarp = w1
            }
        } else {
            print("虫洞个数无效：\(warps.count)")
        }
        canTriggerFull = true
    }
    
    private func setBackgroundColor(data: JSON) {
        let r = CGFloat(data["r"].floatValue / 255.0)
        let g = CGFloat(data["g"].floatValue / 255.0)
        let b = CGFloat(data["b"].floatValue / 255.0)
        backgroundColor = SKColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    func removeNodeFromAllControlsNotInRange(node: SKNode) {
        for control in controls {
            if control.type == .Warp {
                continue
            }
            let dx = node.position.x - control.position.x
            let dy = node.position.y - control.position.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist > control.radius {
                if let pos = control.affectedProjectiles.indexOf(node) {
                    control.affectedProjectiles.removeAtIndex(pos)
                }
            }
        }
    }
    
    func resetControlsToInitalPositions() {
        for control in controls {
            control.node.bounceToPosition(control.initalPosition, scale: 1, delay: 0, duration: 1.1, bounces: 5)
            control.icon?.bounceToPosition(control.initalPosition, scale: 1, delay: 0, duration: 1.1, bounces: 5)
            control.shape?.bounceToPosition(control.initalPosition, scale: 1, delay: 0, duration: 1.1, bounces: 5)
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.2 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
                control.position = control.initalPosition
                control.radius = control.initalRadius
            }
        }
    }
    internal func forceWin() {
        allTargetsFull()
    }
    private func allTargetsFull() {
        if !canTriggerFull {
            return
        }
        canTriggerFull = false
        sceneDelegate?.sceneAllTargetsLit()
        levelOverStageOne()
    }
    
    
    override func update(currentTime: NSTimeInterval) {
        let elapsedTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        if elapsedTime > 1 {
            return
        }
        spawnProjectiles()
        
        for control in controls {
            control.updateAffectedProjectilesForDuration(elapsedTime)
        }
        
        var allFull = true
        for target in targets {
            target.updateForDuration(elapsedTime)
            if target.timeFull < (target.hysteresis + 0.25) {
                allFull = false
            }
        }
        if allFull {
            allTargetsFull()
        }
        
        for node in projectileLayerNode.children {
            let dx = node.physicsBody?.velocity.dx
            let dy = node.physicsBody?.velocity.dy
            
            if fabs(dx!) < 10 && fabs(dy!) < 10 {
                var found = false
                for control in controls {
                    if let pos = control.affectedProjectiles.indexOf(node) {
                        control.affectedProjectiles.removeAtIndex(pos)
                        found = true
                        break
                    }
                }
                if !found {
                    node.removeFromParent()
                }
            }
        }
    }
    
    private func spawnProjectiles() {
        if !shouldSpawnProjectile {
            return
        }
        for point in spawnPoints {
            if !point.shouldSpawnThisFrame() {
                continue
            }
            let projectile = Projectile(point: point)
            projectileLayerNode.addChild(projectile.node)
            projectile.emitter.targetNode = projectileParticleLayerNode
        }
    }
    private func resetTargetTimers() {
        for target in targets {
            target.controlMoved()
        }
    }
    
    private func levelOverStageOne() {
        for (index, control) in controls.enumerate() {
            let delay: CGFloat = 0.5 + index.cgf * 0.15
            control.node.bounceInAfterDelay(delay - 0.25, duration: 0.9, bounces: 2)
            control.icon?.bounceInAfterDelay(delay - 0.25, duration: 0.9, bounces: 2)
            control.shape?.bounceInAfterDelay(delay - 0.25, duration: 0.9, bounces: 2)
            control.node.animationToAlpha(0, delay: delay, duration: 0.5)
            control.icon?.animationToAlpha(0, delay: delay, duration: 0.5)
            control.shape?.animationToAlpha(0, delay: delay, duration: 0.5)
        }
        
        projectileLayerNode.animationToAlpha(0, delay: 0, duration: 0.75)
        projectileParticleLayerNode.animationToAlpha(0, delay: 0, duration: 0.75)
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC))
        dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
            self.shouldSpawnProjectile = false
        }
        
        for (index, target) in targets.enumerate() {
            let delay = 1 + index.cgf * 0.15
            target.node.animationToAlpha(0, delay: delay, duration: 0.5)
            target.node.animationToScale(0.5, delay: delay, duration: 0.5)
        }
        for (index, spawn) in spawnPoints.enumerate() {
            let delay = 1 + index.cgf * 0.15
            spawn.node.animationToAlpha(0, delay: delay, duration: 0.5)
            spawn.node.animationToScale(0.5, delay: delay, duration: 0.5)
        }
        performSelector("levelOverStageTwo", withObject: nil, afterDelay: 2)
    }
    
    func levelOverStageTwo() {
        for control in controls {
            control.node.removeFromParent()
            control.icon?.removeFromParent()
            control.shape?.removeFromParent()
        }
        controls.removeAll()
        
        for fissure in fissures {
            fissure.removeFromParent()
        }
        fissures.removeAll()
        
        for spawnPoint in spawnPoints {
            spawnPoint.node.removeFromParent()
        }
        spawnPoints.removeAll()
        
        for target in targets {
            target.node.removeFromParent()
        }
        targets.removeAll()
        
        projectileLayerNode.removeAllChildren()
        projectileParticleLayerNode.removeAllChildren()
        
        projectileLayerNode.removeFromParent()
        projectileParticleLayerNode.removeFromParent()
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) { () -> Void in
            self.levelOverStageThree()
        }
    }
    
    private func levelOverStageThree() {
        sceneDelegate?.sceneReadyToTransition()
    }
    
    // MARK: - Touch Controls
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if touches.count == 1 {
            let touchPoint = (touches as NSSet).anyObject()!.locationInNode(self)
            let touchedNodes = nodesAtPoint(touchPoint)
            var touchedControls = [Control]()
            for tNode in touchedNodes {
                if let userData = tNode.userData {
                    if let isControl = userData["isControl"] as? Bool{
                        if !isControl {
                            continue
                        }
                    }
                    if let control = userData["control"] as? Control {
                        if !control.canMove && !control.canScale {
                            continue
                        }
                        touchedControls.append(control)
                    }
                }
            }
            if touchedControls.count == 0 {
                return
            }
            draggedControl = nil
            var minDist: CGFloat = 1000000
            for control in touchedControls {
                let offset = CGPoint(x: control.position.x - touchPoint.x, y: control.position.y - touchPoint.y)
                let dist: CGFloat = sqrt(offset.x * offset.x + offset.y * offset.y)
                
                if dist < minDist {
                    minDist = dist
                    draggedControl = control
                    draggedOffset = offset
                }
            }
            if let control = draggedControl {
                if !(control.canScale) {
                    return
                }
                if minDist > (control.radius - scaleRadiusWidth) {
                    scalingControl = control
                    draggedControl = nil
                    scalingOffset = control.radius - minDist
                } else if !(control.canMove) {
                    draggedControl = nil
                }
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if touches.count > 1 {
            return
        }
        let touchPoint = (touches as NSSet).anyObject()!.locationInNode(self)
        if let control = draggedControl {
            control.position = CGPoint(x: touchPoint.x + draggedOffset.x, y: touchPoint.y + draggedOffset.y)
            resetTargetTimers()
        } else if let control = scalingControl {
            let offset = CGPoint(x: touchPoint.x - control.position.x, y: touchPoint.y - control.position.y)
            
            let dist: CGFloat = sqrt(offset.x * offset.x + offset.y * offset.y)
            let radius = dist + scalingOffset
            control.checkRadius(radius)
            resetTargetTimers()
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        scalingControl = nil
        draggedControl = nil
    }
}

// MARK: - Contact Checks
extension GameScene: SKPhysicsContactDelegate {
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody, secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & Static.physCatEdge) == Static.physCatEdge && (secondBody.categoryBitMask & Static.physCatProj) == Static.physCatProj {
            if let node = secondBody.node {
                projectileLayerNode.removeChildrenInArray([node])
            }
            return
        }
        if (firstBody.categoryBitMask & Static.physCatProj) == Static.physCatProj {
            if (secondBody.categoryBitMask & Static.physCatControlTrans) == Static.physCatControlTrans {
                if let control = secondBody.node?.userData?["control"] as? Control {
                    control.affectedProjectiles.append(firstBody.node!)
                }
                return
            }
            if (secondBody.categoryBitMask & Static.physCatTarget) == Static.physCatTarget {
                if let target = secondBody.node?.userData?["target"] as? Target {
                    if let proj = firstBody.node as? SKSpriteNode {
                        if let i = proj.userData?["fissureIndex"] as? Int{
                            if target.matchedFissure == i {
                                target.hitByProjectile()
                            }
                        } else if target.matchedFissure == 0{
                            target.hitByProjectile()
                        }
                    }
                }
                return
            }
            if (secondBody.categoryBitMask & Static.physCatControlColl) == Static.physCatControlColl {
                let proj = firstBody.node as! SKSpriteNode
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW,Int64(UInt64(0.0001) * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                    proj.zRotation = atan2(proj.physicsBody!.velocity.dy, proj.physicsBody!.velocity.dx)
                    return
                })
            }
        }
    }
    func didEndContact(contact: SKPhysicsContact) {
        var firstBody, secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & Static.physCatProj) == Static.physCatProj {
            if (secondBody.categoryBitMask & Static.physCatControlTrans) == Static.physCatControlTrans {
                if let control = secondBody.node?.userData?["control"] as? Control {
                    if let pos = control.affectedProjectiles.indexOf(firstBody.node!) {
                        control.affectedProjectiles.removeAtIndex(pos)
                    }
                    if control.type == .Warp {
                        firstBody.node?.userData?.removeObjectForKey("warped")
                    }
                }
                return
            }
            if (secondBody.categoryBitMask & Static.physCatFissure) == Static.physCatFissure {
                let fissure = secondBody.node as! Fissure
                let proj = firstBody.node as! SKSpriteNode
                proj.color = fissure.color
                proj.colorBlendFactor = 0.95
                proj.userData?["fissureIndex"] = fissure.fissureIndex
                if let emitter = proj.userData?["emitter"] as? SKEmitterNode {
                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    fissure.color.getRed(&r, green: &g, blue: &b, alpha: &a)
                    emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [UIColor(red: r, green: g, blue: b, alpha: 0.15), UIColor(red: r, green: g, blue: b, alpha: 0)], times: [0, 1])
                }
                return
            }
        }
    }
}

