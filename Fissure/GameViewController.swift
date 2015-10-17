//
//  GameViewController.swift
//  Fissure
//
//  Created by xiaoo_gan on 9/23/15.
//  Copyright (c) 2015 xiaoo_gan. All rights reserved.
//

import SpriteKit

class GameViewController: UIViewController {
    
    private var gameView: GameView! {
        return self.view as! GameView
    }
    
    var currentLevelId = ""
    var menuToLevelId: String?
    
    // singleton
    class func shareInstance()-> GameViewController {
        struct Singleton {
            static var onceToken: dispatch_once_t = 0
            static var instance: GameViewController?
        }
        dispatch_once(&Singleton.onceToken) { () -> Void in
            Singleton.instance = GameViewController()
        }
        return Singleton.instance!
    }
    
    
    // MARK: -  view life cycle
    
    override func loadView() {
        view = GameView(frame: CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.size.width, height: UIScreen.mainScreen().bounds.size.height))
        view.backgroundColor = UIColor.clearColor()
    }
    
    override func viewDidLoad() {
        gameView.scene.sceneDelegate = self
        gameView.menuButton.addTarget(self, action: "pressedMenu", forControlEvents: .TouchUpInside)
        gameView.restartButton.addTarget(self, action: "reset", forControlEvents: .TouchUpInside)
        gameView.closeMenuButton.addTarget(self, action: "pressedCloseMenu", forControlEvents: .TouchUpInside)
        for levelButton in gameView.levelButtons {
            levelButton.addTarget(self, action: "pressedLevelButton:", forControlEvents: .TouchUpInside)
        }
        loadData(LevelManager.shareInstance().currentLevelId)
    }
    
    private func loadData(levelId: String) {
        currentLevelId = levelId
        let levelData = LevelManager.shareInstance().levelDataForId(currentLevelId)
        gameView.scene.loadLevelData(levelData)
        LevelManager.shareInstance().currentLevelId = levelId
    }
    
    private func updateStars() {
        for (index, star) in gameView.starImageViews.enumerate() {
            let levelId = LevelManager.shareInstance().levelIdAtPosition(index)
            if LevelManager.shareInstance().isComplete(levelId) {
                star.alpha = 1
            } else {
                star.alpha = 0
            }
        }
    }
    
    // MARK: - pressed button actions
    func pressedMenu() {
        updateStars()
        gameView.titleImage.alpha = 0
        UIView.animateWithDuration(NSTimeInterval(0.5), delay: NSTimeInterval(0.2), options: .CurveEaseInOut, animations: { () -> Void in
            self.gameView.titleImage.alpha = 1
            }) { (finish: Bool) -> Void in
                self.showLevelButtons()
        }
        UIView.animateWithDuration(NSTimeInterval(0.25), delay: NSTimeInterval(0), options: .CurveEaseInOut, animations: { () -> Void in
            self.gameView.levelMenuView.alpha = 1
            }, completion: nil)
        
    }
    
    private func showLevelButtons() {
        for button in gameView.levelButtons {
            button.alpha = 0
            let delay = 0.2 + MathHelper.floatBetween(0.f, high: 0.25.f)
            UIView.animateWithDuration(NSTimeInterval(0.25), delay: NSTimeInterval(delay), options: .CurveEaseInOut, animations: { () -> Void in
                button.alpha = 1
                }, completion: nil)
        }
    }
    
    func reset() {
        gameView.scene.resetControlsToInitalPositions()
    }
    
    func pressedLevelButton(button: UIButton) {
        menuToLevelId = LevelManager.shareInstance().levelIdAtPosition(button.tag)
        gameView.scene.forceWin()
        pressedCloseMenu()
    }
    func pressedCloseMenu() {
        UIView.animateWithDuration(NSTimeInterval(0.25), delay: NSTimeInterval(0), options: .CurveEaseInOut, animations: { () -> Void in
            self.gameView.levelMenuView.alpha = 0
            }, completion: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
// MARK: - GameSceneDelegate
extension GameViewController: GameSceneDelegate {
    func sceneAllTargetsLit() {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        if menuToLevelId != nil {
            LevelManager.shareInstance().setComplete(currentLevelId)
            self.updateStars()
        }
    }
    func sceneReadyToTransition() {
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
        if let levelId =  menuToLevelId {
            self.loadData(levelId)
            menuToLevelId = nil
        } else {
            var currentLevelNum = LevelManager.shareInstance().levelNumForId(currentLevelId)
            currentLevelNum = (currentLevelNum + 1) % LevelManager.shareInstance().levelCount()
            loadData(LevelManager.shareInstance().levelIdAtPosition(currentLevelNum))
        }
    }
}
