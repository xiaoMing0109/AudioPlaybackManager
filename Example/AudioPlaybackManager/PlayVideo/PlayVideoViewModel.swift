//
//  PlayVideoViewModel.swift
//  AudioPlaybackManager_Example
//
//  Created by LM on 2024/5/30.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import AudioPlaybackManager

class PlayVideoViewModel: NSObject {
    
// MARK: Public Property
    
    private(set) var videos: [Audio]
    let playbackManager: AudioPlaybackManager
    
    /// items
    private(set) var items = BehaviorRelay<[Audio]>(value: [])
    
    /// 当前播放 index
    let playIndex = BehaviorRelay<Int?>(value: nil)
    let playStatus = BehaviorRelay<AudioPlaybackManager.PlayStatus?>(value: nil)
    let playTime = BehaviorRelay<Float64>(value: 0)
    let itemDuration = BehaviorRelay<Float64>(value: 0)
    let loadedTime = BehaviorRelay<Float64>(value: 0)
    
    var isPlaying: Bool {
        guard let playStatus = playStatus.value else {
            return false
        }
        return playStatus == .prepare || playStatus == .playing
    }
    
// MARK: Private Property
    
    /// 拖动播放进度条时会暂停 playTime 回调
    private var isTracking = false
    
    /// 用于记录 `.prepare` 阶段记录用户手动点击 播放/暂停.
    private var isForcePause = false
    
// MARK: ============== Life Cycle ==============
    init(videos: [Audio], playbackManager: AudioPlaybackManager) {
        self.videos = videos
        self.playbackManager = playbackManager
        super.init()
        self.items.accept(videos)
        addNotiObserver()
        addKeyValueObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        playbackManager.removeObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.playStatus))
        playbackManager.removeObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.playTime))
        playbackManager.removeObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.duration))
        playbackManager.removeObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.loadedTime))
    }
}

// MARK: ============== Private ==============
extension PlayVideoViewModel {
    
    private func resetPlayTime() {
        self.playTime.accept(0)
    }
    
    private func resetDuration() {
        self.itemDuration.accept(0)
    }
    
    private func resetLoadedTime() {
        loadedTime.accept(0)
    }
}

// MARK: ============== Public ==============
extension PlayVideoViewModel {
    
    /// 当前播放结束, 查询下一条需要播放条目
    ///
    /// 按照 current index + 1 查询, 若下面没有未播放条目则返回 nil。
    func fetchWillPlayNextIndex() -> Int? {
        let items = items.value
        guard !items.isEmpty else {
            return nil
        }
        
        guard let currentIndex = playIndex.value else {
            return nil
        }
        
        let findIndex = currentIndex + 1
        guard isValidIndex(findIndex) else {
            return nil
        }
        
        return findIndex
    }
    
    func isValidIndex(_ index: Int) -> Bool {
        guard index >= 0, index < items.value.count else {
            return false
        }
        return true
    }

    /// 播放
    func playAudio(at index: Int) {
        guard isValidIndex(index) else {
            return
        }
        
        isForcePause = false

        /// Update play time, duration, loadedTime and index.
        playIndex.accept(index)
        resetPlayTime()
        resetDuration()
        resetLoadedTime()

        // play
        let items = items.value
        playbackManager.setupItem(items[index], beginTime: playTime.value)
    }
    
    /// 暂停或继续播放.
    ///
    /// 针对当前 index.
    func pauseOrResume() {
        guard let playStatus = playStatus.value else {
            // 当前 item 已设置 & 非自动播放时, 主动播放
            if let _ = playIndex.value {
                isForcePause = false
                playbackManager.play()
            }
            return
        }

        switch playStatus {
        case .prepare:
            isForcePause.toggle()
            if isForcePause {
                self.playStatus.accept(.paused)
            } else {
                self.playStatus.accept(.prepare)
            }
        case .playing:
            playbackManager.pause()
        case .paused:
            playbackManager.play()
        case .playCompleted:
            playbackManager.seekToProgress(0)
            playbackManager.play()
        case .stop, .error:
            guard let index = playIndex.value else {
                break
            }
            
            playAudio(at: index)
        }
    }
    
    /// 切歌
    func switchAudio(isNext: Bool) {
        guard let index = playIndex.value else {
            return
        }
        
        if isNext {
            switchAudio(at: index + 1)
        } else {
            switchAudio(at: index - 1)
        }
    }
    
    /// 切歌
    func switchAudio(at index: Int) {
        guard isValidIndex(index) else {
            return
        }
        
        isForcePause = false
        
        /// Update play time, duration, loadedTime and index.
        playIndex.accept(index)
        resetPlayTime()
        resetDuration()
        resetLoadedTime()
        
        // play
        let items = items.value
        playbackManager.setupItem(items[index], beginTime: 0)
    }
    
    func stopPlay() {
        playbackManager.stop()
    }
    
    func setIsTracking(_ isTracking: Bool, value: Float?) {
        defer { self.isTracking = isTracking }
        
        if !isTracking, let value = value {
            playbackManager.seekToProgress(value)
        }
    }
    
    func skipForward(_ timeInterval: TimeInterval) {
        playbackManager.skipForward(timeInterval)
    }
    
    func skipBackward(_ timeInterval: TimeInterval) {
        playbackManager.skipBackward(timeInterval)
    }
}

// MARK: ============== Network ==============
extension PlayVideoViewModel {}

// MARK: ============== Delegate ==============
extension PlayVideoViewModel {}

// MARK: ============== Observer ==============
extension PlayVideoViewModel {
    
    private func addKeyValueObserver() {
        playbackManager.addObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.playStatus), options: [.old, .new], context: nil)
        playbackManager.addObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.playTime), options: [.new], context: nil)
        playbackManager.addObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.duration), options: [.new], context: nil)
        playbackManager.addObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.loadedTime), options: [.new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AudioPlaybackManager.playStatus) {
            let oldKey = NSKeyValueChangeKey.oldKey
            let newKey = NSKeyValueChangeKey.newKey
            
            if let oldStatus = change?[oldKey] as? Int,
               let newStatus = change?[newKey] as? Int,
               newStatus != oldStatus {
                /// 切换状态
                ///
                /// 控制器监听到 finished 状态后, 若自动进行切歌操作, 就会触发即将播放音乐的 prepare 状态,
                /// 此时会被 RX 判定为 sequence 中的上一个 event 未结束, 又添加进了新的 event,
                /// 怀疑可能进入了循环, 而 log 警告。
                /// 为避免产生警告, 这里统一处理为异步执行。
                DispatchQueue.main.async {
                    self.playStatus.accept(AudioPlaybackManager.PlayStatus(rawValue: newStatus))
                }
            }
        } else if keyPath == #keyPath(AudioPlaybackManager.playTime) {
            if !isTracking {
                playTime.accept(playbackManager.playTime)
            }
        } else if keyPath == #keyPath(AudioPlaybackManager.duration) {
            itemDuration.accept(playbackManager.duration)
        } else if keyPath == #keyPath(AudioPlaybackManager.loadedTime) {
            loadedTime.accept(playbackManager.loadedTime)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: ============== Notification ==============
extension PlayVideoViewModel {
    
    private func addNotiObserver() {
        // Ready to play noti.
        NotificationCenter.default.addObserver(forName: AudioPlaybackManager.readyToPlayNotification, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else { return }

            if !self.isForcePause {
                playbackManager.play()
            }
        }
    }
}
