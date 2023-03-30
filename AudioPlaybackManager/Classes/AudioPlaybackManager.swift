//
//  AudioPlaybackManager.swift
//
//  Created by LM on 2022/6/20.
//

import UIKit
import MediaPlayer

@objc
public class AudioPlaybackManager: NSObject {
    
    /// An enumeration of possible playback status.
    @objc
    public enum PlayStatus: Int {
        case prepare, playing, paused, stop, playCompleted, error
    }
    
    // MARK: Public Properties
    
    @objc
    public static let shared = AudioPlaybackManager()
    
    /// If true, auto play when item status is `readyToPlay`,
    /// otherwise, you can call `play()` when received noti
    /// `readyToPlay`.
    @objc
    public var autoPlayWhenItemReady = false
    
    /// If the playback is forcibly interrupted during audio playback,
    /// whether to continue playing automatically after the interruption ends.
    ///
    /// Whether it can be resumed depends on the interrupted app is set ... when the audio session is not active
    /// ```
    /// session.setActive(false, options: .notifyOthersOnDeactivation)
    /// ```
    /// if set, you can pass
    /// ```
    /// AVAudioSession.InterruptionOptions
    /// ```
    /// get the `shouldResume` notification.
    ///
    /// Otherwise, can not resume automatically.
    ///
    /// - Note: Forced interruption includes incoming calls, alarm clocks, other players playing...,
    ///  the system app will generally send a corresponding notification when the audio session ends,
    /// and some third apps may not take the initiative to notify.
    @objc
    public var shouldResumeWhenInterruptEnded = true
    
    @objc
    public var isMuted: Bool {
        get { return player.isMuted }
        set { player.isMuted = newValue }
    }
    
    @objc
    public var volume: Float {
        get { return player.volume }
        set { player.volume = newValue }
    }
    
    /// The `playStatus` that the internal `AVPlayer` is in.
    @objc
    public private(set) var playStatus: PlayStatus = .prepare {
        didSet {
            guard playStatus != oldValue else { return }
            
            respondPlayStatusDidChangeCallback()
        }
    }
    
    /// The current play time in seconds.
    /// This is marked as `dynamic` so that this property can be observed using KVO.
    @objc dynamic
    public private(set) var playTime: Float64 = 0
    
    /// The total duration in seconds.
    /// This is marked as `dynamic` so that this property can be observed using KVO.
    @objc dynamic
    public private(set) var duration: Float64 = 0
    
    /// The loaded time ranges in seconds.
    /// This is marked as `dynamic` so that this property can be observed using KVO.
    @objc dynamic
    public private(set) var loadedTime: Float64 = 0
    
    /// The progress for the playback.
    /// This is marked as `dynamic` so that this property can be observed using KVO.
    @objc dynamic
    public private(set) var progress: Float = 0
    
    /// The rate for the player.
    /// This is marked as `dynamic` so that this property can be observed using KVO.
    @objc dynamic
    public private(set) var rate: Float = 0
    
    // MARK: Internal Properties
    
    internal let player = AVPlayer()
    
    internal private(set) var playerItem: AVPlayerItem? {
        willSet {
            guard let playerItem = playerItem else { return }
            
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), context: nil)
            
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        didSet {
            // reset
            playTime = 0; duration = 0; loadedTime = 0; progress = 0
            
            guard let playerItem = playerItem else { return }
            
            // AVPlayerItem status.
            playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
            // AVPlayerItem loadedTimeRanges.
            playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: [.new], context: nil)
            
            // Did play to end time.
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
    }
    
    /// Audio.
    internal var audio: Audio?
    
    // MARK: Private Properties
    
    private var timeObserver: Any?
    private let timeInterval = CMTime(seconds: 1.0 / 60, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    
    /// Record `setupItem(_:beginTime:)` beginTime.
    private var beginTime: TimeInterval = 0
    
// MARK: - Life Cycle
    
    private override init() {
        super.init()
        setupPlayer()
        addNotiObserver()
    }
    
    deinit {
        if let playerItem = playerItem {
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))
            self.playerItem = nil
        }
        
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem), context: nil)
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: nil)
        
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Playback Control Methods.

extension AudioPlaybackManager {
    
    @objc
    public func setupItem(_ audio: Audio, beginTime: TimeInterval = 0.0) {
        self.audio = audio
        self.beginTime = beginTime
        
        let url = audio.audioURL
        if cacheEnabled {
            playerItem = generateCachePlayerItem(withURL: url)
        } else {
            playerItem = AVPlayerItem(url: url)
        }
        player.replaceCurrentItem(with: playerItem)
        
        playStatus = .prepare
    }
    
    @objc
    public func play() {
        guard playerItem != nil else { return }
        
        player.play()
        playStatus = .playing
    }
    
    @objc
    public func pause() {
        guard playerItem != nil else { return }
        
        player.pause()
        playStatus = .paused
    }
    
    @objc
    public func togglePlayPause() {
        guard playerItem != nil else { return }
        
        if player.rate == 0 {
            play()
        } else {
            pause()
        }
    }
    
    @objc
    public func stop() {
        guard playerItem != nil else { return }
        
        player.pause()
        player.replaceCurrentItem(with: nil)
        
        playStatus = .stop
    }
    
    @objc
    public func skipForward(_ timeInterval: TimeInterval) {
        guard playerItem != nil else { return }
        
        let currentTime = player.currentTime()
        let offset = CMTime(seconds: timeInterval, preferredTimescale: 1)
        
        let newTime = CMTimeAdd(currentTime, offset)
        seek(to: newTime)
    }
    
    @objc
    public func skipBackward(_ timeInterval: TimeInterval) {
        guard playerItem != nil else { return }
        
        let currentTime = player.currentTime()
        let offset = CMTime(seconds: timeInterval, preferredTimescale: 1)
        
        let newTime = CMTimeSubtract(currentTime, offset)
        seek(to: newTime)
    }
    
    @objc
    public func seekToPositionTime(_ positionTime: TimeInterval) {
        guard playerItem != nil else { return }
        
        let newTime = CMTime(seconds: positionTime, preferredTimescale: 1)
        seek(to: newTime)
    }
    
    @objc
    public func seekToProgress(_ value: Float) {
        guard value >= 0, value <= 1 else { return }
        guard let item = playerItem else { return }

        let duration = CMTimeGetSeconds(item.duration)
        let positionTime = duration * Double(value)
        seekToPositionTime(positionTime)
    }
    
    @objc
    public func beginRewind(rate: Float = -2.0) {
        guard playerItem != nil else { return }
        
        player.rate = rate
    }
    
    @objc
    public func beginFastForward(rate: Float = 2.0) {
        guard playerItem != nil else { return }
        
        player.rate = rate
    }
    
    @objc
    public func endRewindFastForward() {
        guard playerItem != nil else { return }
        
        player.rate = 1.0
    }
    
    internal func nextTrack() {
        guard playerItem != nil else { return }
        
        respondNextTrackCallback()
    }
    
    internal func previousTrack() {
        guard playerItem != nil else { return }
        
        respondPreviousTrackCallback()
    }
}

// MARK: - Private Methods

extension AudioPlaybackManager {
    
    private func setupPlayer() {
        // Add a periodic time observer to keep `playTime` and `progress` up to date.
        timeObserver = player.addPeriodicTimeObserver(forInterval: timeInterval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let playTime = CMTimeGetSeconds(time)
            var progress: Float {
                if self.duration == 0 {
                    return 0
                }
                return Float(playTime / self.duration)
            }
            self.playTime = playTime
            self.progress = progress
            
            self.respondPlayTimeVariationCallback(playTime: playTime)
        }
        
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem), options: [.new], context: nil)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.new], context: nil)
    }
    
    private func seekToBeginTimeWhenItemReady() {
        guard let item = playerItem else { return }
        
        let time = CMTime(seconds: beginTime, preferredTimescale: item.duration.timescale)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self = self else { return }
            self.respondReadyToPlayCallback()
            
            if self.autoPlayWhenItemReady {
                self.play()
            } else {
                // Wait for call `play()`.
            }
        }
    }
    
    private func seek(to time: CMTime) {
        guard player.currentItem != nil else { return }
        
        guard time.isValid, time.isNumeric else {
            #if DEBUG
            print("Seek time: \(time) is invalid or infinity!!!")
            #endif
            return
        }
        
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self = self else { return }
            self.updatePlaybackMetadata()
        }
    }
}

// MARK: - Key-Value Observing Method

extension AudioPlaybackManager {
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayer.currentItem) {
            let currentItem = player.currentItem
            #if DEBUG
            print("Observe player item: \(String(describing: currentItem))")
            #endif
            
            if currentItem == nil {
                playerItem = nil
            }
            
            setNowPlayingInfo()
        } else if keyPath == #keyPath(AVPlayer.rate) {
            let rate = player.rate
            #if DEBUG
            print("Observe player rate: \(rate)")
            #endif
            
            self.rate = rate
            respondRateDidChangeCallback(rate: rate)
            
            updatePlaybackMetadata()
        } else if keyPath == #keyPath(AVPlayerItem.status) {
            guard let playerItem = object as? AVPlayerItem else { return }
            
            let status = playerItem.status
            let duration = CMTimeGetSeconds(playerItem.duration)
            #if DEBUG
            print("Observe player item status: \(status), duration: \(duration)")
            #endif
            
            switch status {
            case .unknown: break
            case .readyToPlay:
                self.duration = duration
                respondDurationCallback(duration: duration)
                
                seekToBeginTimeWhenItemReady()
            case .failed:
                playStatus = .error
            @unknown default:
                fatalError()
            }
        } else if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            guard let playerItem = object as? AVPlayerItem else { return }
            
            let loadedTime = calculateLoadedTime(for: playerItem)
            #if DEBUG
            print("Observe player item loaded time: \(loadedTime)")
            #endif
            
            self.loadedTime = loadedTime
            respondLoadedTimeCallback(loadedTime: loadedTime)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func calculateLoadedTime(for playerItem: AVPlayerItem) -> Float64 {
        let loadedTimeRanges = playerItem.loadedTimeRanges
        guard let timeRangeValue = loadedTimeRanges.first?.timeRangeValue else {
            return 0
        }
        
        let start = CMTimeGetSeconds(timeRangeValue.start)
        let duration = CMTimeGetSeconds(timeRangeValue.duration)
        let result = start + duration
        return result
    }
}

// MARK: - Notification Observing Methods

extension AudioPlaybackManager {
    
    private func addNotiObserver() {
        // interruption
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        // Route changed.
        NotificationCenter.default.addObserver(self, selector: #selector(routeChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    @objc private func playerItemDidPlayToEndTime(_ noti: NSNotification) {
        guard let playerItem = noti.object as? AVPlayerItem else { return }
        
        #if DEBUG
        print("Player item did play to end time noti: \(noti)")
        #endif
        
        let duration = CMTimeGetSeconds(playerItem.duration)
        playTime = duration
        respondPlayTimeVariationCallback(playTime: duration)
        
        playStatus = .playCompleted
    }
    
    @objc private func sessionInterruption(_ noti: NSNotification) {
        guard let userInfo = noti.userInfo else { return }
        
        #if DEBUG
        print("Audio interruption noti: \(noti)")
        #endif
        
        if let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? NSNumber,
           let type = AVAudioSession.InterruptionType(rawValue: typeValue.uintValue) {
            switch type {
            case .began:
                pause()
            case .ended:
                if shouldResumeWhenInterruptEnded,
                   let optionValue = userInfo[AVAudioSessionInterruptionOptionKey] as? NSNumber {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionValue.uintValue)
                    if options.contains(.shouldResume) {
                        play()
                    }
                }
            @unknown default:
                fatalError()
            }
        }
    }
    
    @objc private func routeChange(_ noti: NSNotification) {
        guard let userInfo = noti.userInfo else { return }
        
        #if DEBUG
        print("Route change noti: \(noti)")
        #endif
        
        guard let value = userInfo[AVAudioSessionRouteChangeReasonKey] as? NSNumber,
              let reason = AVAudioSession.RouteChangeReason(rawValue: value.uintValue)
        else { return }
        
        switch reason {
        case .newDeviceAvailable:
            play()
        case .oldDeviceUnavailable:
            pause()
        default: break
        }
    }
}
