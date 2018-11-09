//
//  JYPollRequest.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/4.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation


internal class JYPollTask {
    weak var target: AnyObject?
    var selector: Selector
    var interval: TimeInterval
    var currentTick: TimeInterval

    init(target: AnyObject?, selector: Selector, interval: TimeInterval, currentTick: TimeInterval) {
        self.target = target
        self.selector = selector
        self.interval = interval
        self.currentTick = currentTick
    }
}


public class JYPollManager {
    
    static public var shared: ONPollManager = ONPollManager()
    
    
    private var entityMap: [String : ONPollTask] = [:]
    
    private var timer: Timer? = nil
    
    private let minInterval: TimeInterval = 0.1
    
    init() {
    }
    
    
    public func addPoll(target: AnyObject?, selector: Selector, interval: TimeInterval, immediateFire: Bool) {
        guard let targetHash = target?.hashValue else { return }
        
        let name = String(format: "%d_%d", targetHash, selector.hashValue)
        let entity = ONPollTask(target: target, selector: selector, interval: interval, currentTick: immediateFire ? interval : 0)
        
        entityMap[name] = entity
        if entityMap.count > 0 {
            startTimer()
        }
    }
    
    public func removePoll(target: AnyObject?, selector: Selector) {
        guard let targetHash = target?.hashValue else { return }
        
        let name = String(format: "%d_%d", targetHash, selector.hashValue)
        
        entityMap[name] = nil
        if entityMap.count == 0 {
            stopTimer()
        }
    }
    
    // MARK: Timer handler
    
    internal func startTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(timeInterval: minInterval, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)
        timer!.fire()
    }
    
    internal func stopTimer() {
        guard let timer = timer else { return }
        
        timer.invalidate()
        self.timer = nil
    }
    
    @objc internal func handleTimer() {
        for (name, entity) in entityMap {
            if let target = entity.target {
                if entity.currentTick >= entity.interval {
                    target.perform(entity.selector, with: nil)
                    entity.currentTick -= entity.interval
                } else {
                    entity.currentTick += minInterval
                }
            } else {
                entityMap[name] = nil
                if entityMap.count == 0 {
                    stopTimer()
                }
            }
        }
    }
}
