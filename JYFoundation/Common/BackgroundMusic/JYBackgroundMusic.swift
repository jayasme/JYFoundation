//
//  BackgroundMusic.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/4/12.
//  Copyright © 2018年 jayasme All rights reserved.
//

import Foundation
import AVFoundation
import PromiseKit

public enum JYBackgroundMusicState: Int {
    case none = 0
    case loading = 1
    case loaded = 2
    case ready = 3
    case stopped = 4
    case error = 5
    case playing = 6
    case paused = 7
    case interrupted = 8
}

extension NSNotification.Name {
    
    public static let JYBackgroundMusicStateChanged: NSNotification.Name =
        NSNotification.Name(rawValue: "JYBackgroundMusicStateChanged")
    
    public static let JYBackgroundTimer: NSNotification.Name =
        NSNotification.Name(rawValue: "JYBackgroundTimer")
}

public class JYBackgroundMusic: NSObject, AVAudioPlayerDelegate {
    
    public static var shared: JYBackgroundMusic = JYBackgroundMusic()
    
    private var httpClient = JYHttpClient(timeoutInterval: 60)
    
    private let mapFileName = "map.conf"
    
    public var cachePath: URL? = nil {
        didSet {
            // Check out the cache directory
            guard let cachePath = cachePath else {
                return
            }
            
            do {
                if !FileManager.default.fileExists(atPath: cachePath.absoluteString) {
                    try FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true, attributes: nil)
                }
            } catch let error {
                // error
                print("Set caceh path error: " + error.localizedDescription)
            }
            
            do {
                // Load cache map file
                let mapFile = cachePath.appendingPathComponent(mapFileName)
                let data = try Data(contentsOf: mapFile)
                if let dict = try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0)) as? [String: String] {
                    cacheMap = dict
                } else {
                    cacheMap = [:]
                }
            }
            catch let error {
                print("Read cache map file error: " + error.localizedDescription)
                cacheMap = [:]
            }
        }
    }
    
    private var cacheMap: [String: String]?

    private(set) public var state: JYBackgroundMusicState = .none {
        didSet {
            NotificationCenter.default.post(name: NSNotification.Name.JYBackgroundMusicStateChanged, object: self, userInfo: ["state" : state])
        }
    }
    
    private var avPlayer: AVAudioPlayer? = nil
    
    public var userInfo: [String: Any?] = [:]
    
    public var duration: TimeInterval? {
        get {
            guard let avPlayer = avPlayer, state == .playing || state == .ready || state == .stopped else {
                return nil
            }
            
            return avPlayer.duration
        }
    }
    
    public var currentTime: TimeInterval? {
        get {
            guard let avPlayer = avPlayer, state == .playing else {
                return nil
            }
            
            return avPlayer.currentTime
        }
    }
    
    public var volumn: Float {
        get {
            guard let avPlayer = avPlayer, state == .playing || state == .ready || state == .paused || state == .interrupted else {
                return -1
            }
            return avPlayer.volume
        }
        set(value) {
            guard let avPlayer = avPlayer, state == .playing || state == .ready || state == .paused || state == .interrupted else {
                return
            }
            avPlayer.volume = value
        }
    }
    
    public func prepare(url: String, key: String?, header: [String: String]? = nil) {
        guard state == .none || state == .error else {
            return
        }
        
        state = .loading
        dataWithURL(url, key: key, header: header)
        .done{[weak self] data in
            guard self?.state == .loading else {
                return
            }
            self?.state = .loaded
            self?.prepare(data: data)
        }.catch {[weak self] _ in
            self?.state = .error
        }
    }
    
    public func prepare(contentsOf url: URL) {
        guard state == .none || state == .error else {
            return
        }
        
        guard let data = try? Data(contentsOf: url) else {
            state = .error
            return
        }
        
        prepare(data: data)
    }
    
    private func cacheWithKey(key: String) -> Data? {
        guard let file = cacheMap?[key] else {
            return nil
        }
        guard let cachePath = cachePath else {
            return nil
        }
        let data = try? Data(contentsOf: cachePath.appendingPathComponent(file))
        return data
    }
    
    @discardableResult
    private func dataWithURL(_ url: String, key: String?, header: [String: String]? = nil) -> Promise<Data> {
        if let key = key, let cacheData = cacheWithKey(key: key) {
            return Promise<Data>.value(cacheData)
        }
        
        return self.httpClient.fetchData(url, method: .get, header: header)
        .map { data in
            // cache the data
            if let key = key {
                self.cacheData(data: data, with: key)
            }
            
            return data
        }
    }
    
    private func cacheData(data: Data, with key: String) {
        do {
            let fileName = UUID().uuidString
            guard let cachePath = self.cachePath else {
                return
            }
            guard cacheMap != nil else {
                return
            }
            let fileURL = cachePath.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            cacheMap![key] = fileName
            // save to disk
            let jsonData = try JSONSerialization.data(withJSONObject: cacheMap!, options: .init(rawValue: 0))
            // save map file
            let mapFile = cachePath.appendingPathComponent(mapFileName)
            try jsonData.write(to: mapFile)
        } catch let error {
            print("save cache error for: " + error.localizedDescription)
        }
    }
    
    public func prepare(data: Data) {
        guard state == .none || state == .error || state == .loaded else {
            return
        }
        
        avPlayer = try? AVAudioPlayer(data: data)
        if avPlayer != nil {
            avPlayer!.delegate = self
            state = .ready
        } else {
            state = .error
        }
    }
    
    
    public func play() {
        play(atTime: 0)
    }
    
    public func play(atTime time: TimeInterval) {
        if state == .ready || state == .stopped {
            guard let avPlayer = self.avPlayer else {
                return
            }
            // new playing
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
            avPlayer.play()
            avPlayer.currentTime = time
            self.state = .playing
            // add interuption observer
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(audioPlayeInterrupted(notification:)),
                                                   name: NSNotification.Name.AVAudioSessionInterruption,
                                                   object: nil)
            
            // begin timing
            ONPollManager.shared.addPoll(target: self, selector: #selector(MusicTiming), interval: 0.1, immediateFire: true)
        } else if state == .paused || state == .interrupted {
            // resume playing
            guard let avPlayer = self.avPlayer else {
                return
            }
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
            avPlayer.play()
            self.state = .playing
            
            // begin timing
            ONPollManager.shared.addPoll(target: self, selector: #selector(MusicTiming), interval: 0.1, immediateFire: true)
        }
    }
    
    public func pause() {
        guard let avPlayer = avPlayer else {
            return
        }
        
        guard state == .playing else {
            return
        }
        
        avPlayer.pause()
        state = .paused
        
        ONPollManager.shared.removePoll(target: self, selector: #selector(MusicTiming))
    }
    
    private func interrupt() {
        guard let avPlayer = avPlayer else {
            return
        }
        
        guard state == .playing else {
            return
        }
        
        avPlayer.pause()
        state = .interrupted
        
        ONPollManager.shared.removePoll(target: self, selector: #selector(MusicTiming))
    }
    
    public func stop() {
        guard state == .playing || state == .paused || state == .loading || state == .interrupted else {
            return
        }
        
        avPlayer?.stop()
        state = .stopped
        
        ONPollManager.shared.removePoll(target: self, selector: #selector(MusicTiming))
        // remove interuption observer
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
    }
    
    public func clear() {
        stop()
        state = .none
        avPlayer = nil
    }
    
    
    
    // MARK: AVAudioPlayerDelegate
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        state = .stopped
    }
    
    @objc public func audioPlayeInterrupted(notification: Notification) {
        if let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt {
            if type == AVAudioSessionInterruptionType.began.rawValue {
                interrupt()
            } else if type == AVAudioSessionInterruptionType.ended.rawValue && state == .interrupted {
                self.play()
            }
        }
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        state = .error
    }
    
    // MARK: Action
    
    @objc public func MusicTiming() {
        guard let avPlayer = avPlayer else {
            return
        }
        
        NotificationCenter.default.post(name: NSNotification.Name.JYBackgroundTimer,
                                        object: self,
                                        userInfo: ["currentTime": avPlayer.currentTime,
                                                   "duration": avPlayer.duration]
        )
    }
}
