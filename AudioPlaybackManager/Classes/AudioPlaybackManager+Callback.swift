//
//  AudioPlaybackManager+Callback.swift
//
//  Created by LM on 2023/3/25.
//

import Foundation

// MARK: - Notification

extension AudioPlaybackManager {
    
    /// `setupItem(_:beginTime:)` seek to assigned time finished,
    /// call `play()` after receiving notification when `autoPlayWhenItemReady = false`.
    public static let readyToPlayNotification = Notification.Name(rawValue: "kReadyToPlayNotification")
    
    /// Play status did change.
    ///
    /// - userInfoKey: NotificationUserInfoKeys.playStatus
    public static let playStatusDidChangeNotification = Notification.Name(rawValue: "kPlayStatusDidChangeNotification")
    
    /// Play time variation.
    ///
    /// - userInfoKey: NotificationUserInfoKeys.playTime
    public static let playTimeNotification = Notification.Name(rawValue: "kPlayTimeNotification")
    
    /// Item duration.
    ///
    /// - userInfoKey: NotificationUserInfoKeys.duration
    public static let durationNotification = Notification.Name(rawValue: "kDurationNotification")
    
    /// Item loaded time ranges.
    ///
    /// - userInfoKey: NotificationUserInfoKeys.loadedTime
    public static let loadedTimeNotification = Notification.Name(rawValue: "kLoadedTimeNotification")
    
    /// Rate did change.
    ///
    /// - userInfoKey: NotificationUserInfoKeys.rate
    public static let rateDidChangeNotification = Notification.Name("kRateDidChangeNotification")
    
    /// Remote control previous track.
    public static let previousTrackNotification = Notification.Name(rawValue: "kPreviousTrackNotification")
    
    /// Remote control next track.
    public static let nextTrackNotification = Notification.Name(rawValue: "kNextTrackNotification")
    
    public struct NotificationUserInfoKeys {
        /// `PlayStatus`
        public static let playStatus = "playStatus"
        
        /// Float64
        public static let playTime = "playTime"
        /// Float64
        public static let duration = "duration"
        /// Float64
        public static let loadedTime = "loadedTime"
        
        /// Float
        public static let rate = "rate"
    }
}

// MARK: - Delegate

@objc
public protocol AudioPlaybackManagerDelegate {
    
    /// `setupItem(_:beginTime:)` seek to assigned time finished,
    /// call `play()` when `autoPlayWhenItemReady = false`.
    @objc
    optional func audioPlaybackManagerRreadyToPlay(_ manager: AudioPlaybackManager)
    
    /// Play status did change.
    @objc
    optional func audioPlaybackManage(_ manager: AudioPlaybackManager, playStatusDidChange playStatus: AudioPlaybackManager.PlayStatus)
    
    /// Play time variation.
    @objc
    optional func audioPlaybackManage(_ manager: AudioPlaybackManager, playTimeVariation playTime: Float64)
    
    /// Item duration.
    @objc
    optional func audioPlaybackManage(_ manager: AudioPlaybackManager, duration: Float64)
    
    /// Item loaded time ranges.
    @objc
    optional func audioPlaybackManage(_ manager: AudioPlaybackManager, loadedTime: Float64)
    
    /// Rate did change.
    @objc
    optional func audioPlaybackManage(_ manager: AudioPlaybackManager, rateDidChange rate: Float)
    
    /// Remote control previous track.
    @objc
    optional func audioPlaybackManagerPreviousTrack(_ manager: AudioPlaybackManager)
    
    /// Remote control next track.
    @objc
    optional func audioPlaybackManagerNextTrack(_ manager: AudioPlaybackManager)
}

extension AudioPlaybackManager {
    
    private struct AssociatedKeys {
        static var delegatesKey: Void?
    }
    
    // MARK: Private Properties
    
    private var delegates: NSHashTable<AnyObject> {
        if let delegates = objc_getAssociatedObject(self, &AssociatedKeys.delegatesKey) as? NSHashTable<AnyObject> {
            return delegates
        }
        
        let delegates = NSHashTable<AnyObject>(options: .weakMemory)
        objc_setAssociatedObject(self, &AssociatedKeys.delegatesKey, delegates, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return delegates
    }
    
    // MARK: Public Methods
    
    @objc
    public func addDelegate(_ delegate: AudioPlaybackManagerDelegate) {
        if !delegates.contains(delegate) {
            delegates.add(delegate)
        }
    }
    
    @objc
    public func removeDelegate(_ delegate: AudioPlaybackManagerDelegate) {
        if delegates.contains(delegate) {
            delegates.remove(delegate)
        }
    }
    
    @objc
    public func allDelegates() -> [AnyObject] {
        return delegates.allObjects
    }
    
    @objc
    public func removeAllDelegates() {
        if delegates.count > 0 {
            delegates.removeAllObjects()
        }
    }
}

// MARK: - Respond Callback Methods

extension AudioPlaybackManager {
    
    internal func respondReadyToPlayCallback() {
        let noti = Notification(
            name: AudioPlaybackManager.readyToPlayNotification,
            object: self,
            userInfo: nil
        )
        NotificationCenter.default.post(noti)
        
        allDelegates().forEach { delegate in
            if delegate.responds(to: #selector(delegate.audioPlaybackManagerRreadyToPlay(_:))) {
                delegate.audioPlaybackManagerRreadyToPlay(self)
            }
        }
    }
    
    internal func respondPlayStatusDidChangeCallback() {
        let userInfo: [String: Any] = [
            NotificationUserInfoKeys.playStatus: playStatus
        ]
        let noti = Notification(
            name: AudioPlaybackManager.playStatusDidChangeNotification,
            object: self,
            userInfo: userInfo
        )
        NotificationCenter.default.post(noti)
        
        allDelegates().forEach { delegate in
            if delegate.responds(to: #selector(delegate.audioPlaybackManage(_:playStatusDidChange:))) {
                delegate.audioPlaybackManage(self, playStatusDidChange: playStatus)
            }
        }
    }
    
    internal func respondPlayTimeVariationCallback(playTime: Float64) {
        let userInfo: [String: Any] = [
            NotificationUserInfoKeys.playTime: playTime
        ]
        let noti = Notification(
            name: AudioPlaybackManager.playTimeNotification,
            object: self,
            userInfo: userInfo
        )
        NotificationCenter.default.post(noti)
        
        allDelegates().forEach { delegate in
            if delegate.responds(to: #selector(delegate.audioPlaybackManage(_:playTimeVariation:))) {
                delegate.audioPlaybackManage(self, playTimeVariation: playTime)
            }
        }
    }
    
    internal func respondDurationCallback(duration: Float64) {
        let userInfo: [String: Any] = [
            NotificationUserInfoKeys.duration: duration
        ]
        let noti = Notification(
            name: AudioPlaybackManager.durationNotification,
            object: self,
            userInfo: userInfo
        )
        NotificationCenter.default.post(noti)
        
        allDelegates().forEach { delegate in
            if delegate.responds(to: #selector(delegate.audioPlaybackManage(_:duration:))) {
                delegate.audioPlaybackManage(self, duration: duration)
            }
        }
    }
    
    internal func respondLoadedTimeCallback(loadedTime: Float64) {
        let userInfo: [String: Any] = [
            NotificationUserInfoKeys.loadedTime: loadedTime
        ]
        let noti = Notification(
            name: AudioPlaybackManager.loadedTimeNotification,
            object: self,
            userInfo: userInfo
        )
        NotificationCenter.default.post(noti)
        
        allDelegates().forEach { delegate in
            if delegate.responds(to: #selector(delegate.audioPlaybackManage(_:loadedTime:))) {
                delegate.audioPlaybackManage(self, loadedTime: loadedTime)
            }
        }
    }
    
    internal func respondRateDidChangeCallback(rate: Float) {
        let userInfo: [String: Any] = [
            NotificationUserInfoKeys.rate: rate
        ]
        let noti = Notification(
            name: AudioPlaybackManager.rateDidChangeNotification,
            object: self,
            userInfo: userInfo
        )
        NotificationCenter.default.post(noti)
        
        allDelegates().forEach { delegate in
            if delegate.responds(to: #selector(delegate.audioPlaybackManage(_:rateDidChange:))) {
                delegate.audioPlaybackManage(self, rateDidChange: rate)
            }
        }
    }
    
    internal func respondPreviousTrackCallback() {
        let noti = Notification(
            name: AudioPlaybackManager.previousTrackNotification,
            object: self,
            userInfo: nil
        )
        NotificationCenter.default.post(noti)
        
        allDelegates().forEach { delegate in
            if delegate.responds(to: #selector(delegate.audioPlaybackManagerPreviousTrack(_:))) {
                delegate.audioPlaybackManagerPreviousTrack(self)
            }
        }
    }
    
    internal func respondNextTrackCallback() {
        let noti = Notification(
            name: AudioPlaybackManager.nextTrackNotification,
            object: self,
            userInfo: nil
        )
        NotificationCenter.default.post(noti)
        
        allDelegates().forEach { delegate in
            if delegate.responds(to: #selector(delegate.audioPlaybackManagerNextTrack(_:))) {
                delegate.audioPlaybackManagerNextTrack(self)
            }
        }
    }
}
