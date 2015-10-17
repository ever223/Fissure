//
//  GameView.swift
//  Fissure
//
//  Created by xiaoo_gan on 10/17/15.
//  Copyright © 2015 xiaoo_gan. All rights reserved.
//

import SpriteKit

class GameView: UIView {
    let menuSizeRatio: CGFloat = 0.85
    let menuButtonVertInsert: CGFloat = 10
    let menuButtonHorzInsert: CGFloat = 10
    let numOfLevels = 36
    let numOfRows = 6
    let numOfCols = 6
    
    var sceneView: SKView!
    var scene: GameScene!
    
    let menuButton = UIButton(type: .Custom)
    let restartButton = UIButton(type: .Custom)
    let closeMenuButton = UIButton(type: .Custom)
    
    let snapButton = UIButton()
    let nextButton = UIButton()
    
    var levelMenuView: UIView!
    var levelButtons = [UIButton]()
    var starImageViews = [UIImageView]()
    var titleImage: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
        
        sceneView = SKView(frame: bounds)
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        sceneView.showsDrawCount = true
        addSubview(sceneView)
        
        scene = GameScene(size: bounds.size)
        sceneView.presentScene(scene)
        
        menuButton.frame = CGRect(x: bounds.size.width - 40, y: 0, width: 40, height: 40)
        let mImage = UIImageView(image: UIImage(named: "icon_menu"))
        mImage.frame = CGRect(x: 15, y: 5, width: 20, height: 20)
        mImage.alpha = 1.0
        menuButton.addSubview(mImage)
        addSubview(menuButton)
        
        restartButton.frame = CGRect(x: bounds.size.width - 40, y: bounds.size.height - 40, width: 40, height: 40)
        let rImage = UIImageView(image: UIImage(named: "icon_restart"))
        rImage.frame = CGRect(x: 15, y: 15, width: 20, height: 20)
        rImage.alpha = 1.0
        restartButton.addSubview(rImage)
        addSubview(restartButton)
        
        levelMenuView = UIView(frame: bounds)
        levelMenuView.alpha = 0
        levelMenuView.backgroundColor = UIColor(white: 1, alpha: 1)
        
        titleImage = UIImageView(image: UIImage(named: "title"))
        titleImage.center = CGPoint(x: bounds.size.width / 2, y: 29)
        levelMenuView.addSubview(titleImage)
        
        closeMenuButton.frame = levelMenuView.bounds
        levelMenuView.addSubview(closeMenuButton)
        
        addSubview(levelMenuView)
        
        loadLevelButtons()
    }
    private func loadLevelButtons() {
        let menuWidth = bounds.size.width * menuSizeRatio
        let menuHeight = bounds.size.height * menuSizeRatio
        let initalXOffset = ((bounds.size.width - menuWidth) / 2)
        let initalYOffset = ((bounds.size.height - menuHeight) / 2)
        
        let buttonWidth = (menuWidth - (numOfCols + 1).cgf * menuButtonHorzInsert) / numOfCols.cgf
        let buttonHeight = (menuHeight - (numOfRows + 1).cgf * menuButtonVertInsert) / numOfRows.cgf
        let buttonOffsetX = buttonWidth + menuButtonHorzInsert
        let buttonOffsetY = buttonHeight + menuButtonVertInsert
        
        var levelIndex = 0
        for i in 0..<numOfRows {
            for j in 0..<numOfCols {
                let levelButton = UIButton(type: .Custom)
                levelButton.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0)
                levelButton.frame = CGRect(x: CGFloat(j) * buttonOffsetX + menuButtonHorzInsert + initalXOffset, y: CGFloat(i) * buttonOffsetY + menuButtonVertInsert + initalYOffset, width: buttonWidth, height: buttonHeight)
                let levelTitle = LevelManager.shareInstance().levelIdAtPosition(levelIndex)
                let bImage = UIImage(named: levelTitle)
                levelButton.setImage(bImage, forState: .Normal)
                levelButton.tag = levelIndex
                levelButton.layer.shadowColor = UIColor.blackColor().CGColor
                levelButton.layer.shadowOffset = CGSize(width: 0, height: 0)
                levelButton.layer.shadowOpacity = 0.5
                levelButton.layer.shadowRadius = 2
                levelButton.layer.shouldRasterize = true
                levelButton.layer.rasterizationScale = UIScreen.mainScreen().scale

                levelMenuView.addSubview(levelButton)
                levelButtons.append(levelButton)
                levelIndex++
                
                let star = UIImageView(image: UIImage(named: "star-mini"))
                star.center = CGPoint(x: buttonWidth - 2, y: buttonHeight - 3)
                levelButton.addSubview(star)
                starImageViews.append(star)
            }
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
