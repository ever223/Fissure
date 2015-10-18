//
//  LevelManager.swift
//  Fissure
//
//  Created by xiaoo_gan on 9/29/15.
//  Copyright © 2015 xiaoo_gan. All rights reserved.
//

import Foundation

public class LevelManager: NSObject {
    private var levels = [String: JSON]()
    private var orders = [AnyObject]()
    public var currentLevelId: String  {
        set {
            Defaults[.currentId] = newValue
        }
        get  {
            if let id = Defaults[.currentId] {
                return id
            } else {
                Defaults[.currentId] = "level-1"
                return Defaults[.currentId]!
            }
        }
    }
    public var maxId: Int  {
        set {
            Defaults[.maxId] = newValue
        }
        get  {
            return Defaults[.maxId]
        }
    }
    // singleton
    class func shareInstance()-> LevelManager {
        struct Singleton {
            static var onceToken: dispatch_once_t = 0
            static var instance: LevelManager?
        }
        dispatch_once(&Singleton.onceToken) { () -> Void in
            Singleton.instance = LevelManager()
        }
        return Singleton.instance!
    }
    
    public override init() {
        let path = NSBundle.mainBundle().pathForResource("level_info", ofType: "json")
        let url = NSURL(fileURLWithPath: path!)
        let data = NSData(contentsOfURL: url)
        let jsonData = JSON(data: data!)
        levels = jsonData["levels"].dictionaryValue
        orders = jsonData["level_order"].arrayObject!
    }
    
    // 根据关卡名称获取关卡id
    public func levelNumForId(levelId: String) -> Int {
        for (index, levelName) in orders.enumerate() {
            if levelId.isEqual(levelName) {
                return index
            }
        }
        return -1
    }
    
    // 根据关卡名称获得关卡地图字典
    public func levelDataForId(levelId: String) -> JSON {
        return levels[levelId]!
    }
    // 根据关卡ID获取关卡名称
    public func levelIdAtPosition(position: Int) -> String {
        return orders[position] as! String
    }
    // 关卡个数
    public func levelCount() -> Int {
        return orders.count
    }
}

extension DefaultsKeys {
    static let currentId = DefaultsKey<String?>("currentId")
    static let maxId = DefaultsKey<Int>("maxId")
}
