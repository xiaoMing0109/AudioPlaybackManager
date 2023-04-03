//
//  PlayAudioViewModel.swift
//  PulseG-iOS
//
//  Created by LM on 2022/6/20.
//

import UIKit
import RxCocoa
import RxSwift
import AudioPlaybackManager

class PlayAudioViewModel: NSObject {
    
// MARK: Public Property
    
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
    init(audioURLs: [URL]) {
        super.init()
        initializeItemsData(with: audioURLs)
        addNotiObserver()
        addKeyValueObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        AudioPlaybackManager.shared.removeObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.playTime))
        AudioPlaybackManager.shared.removeObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.duration))
        AudioPlaybackManager.shared.removeObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.loadedTime))
    }
}

// MARK: ============== Private ==============
extension PlayAudioViewModel {
    
    private func initializeItemsData(with audioURLs: [URL]) {
        let items = audioURLs.map { url in
            let audio = Audio(audioURL: url)
            audio.useAudioMetadata = false
            audio.albumName = "专辑名称"
            audio.artist = "作者"
            audio.title = url.lastPathComponent
            if let path = Bundle.main.path(forResource: "artwork", ofType: "jpg") {
                audio.artworkURL = URL(fileURLWithPath: path)
            }
            return audio
        }
        self.items.accept(items)
    }
    
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
extension PlayAudioViewModel {
    
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
        AudioPlaybackManager.shared.setupItem(items[index], beginTime: playTime.value)
    }
    
    /// 暂停或继续播放.
    ///
    /// 针对当前 index.
    func pauseOrResume() {
        guard let playStatus = playStatus.value else {
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
            AudioPlaybackManager.shared.pause()
        case .paused:
            AudioPlaybackManager.shared.play()
        case .playCompleted:
            AudioPlaybackManager.shared.seekToProgress(0)
            AudioPlaybackManager.shared.play()
        case .stop, .error:
            guard let index = playIndex.value, isValidIndex(index) else {
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
        AudioPlaybackManager.shared.setupItem(items[index], beginTime: 0)
    }
    
    func stopPlay() {
        AudioPlaybackManager.shared.stop()
    }
    
    func setIsTracking(_ isTracking: Bool, value: Float?) {
        defer { self.isTracking = isTracking }
        
        if !isTracking, let value = value {
            AudioPlaybackManager.shared.seekToProgress(value)
        }
    }
    
    func skipForward(_ timeInterval: TimeInterval) {
        AudioPlaybackManager.shared.skipForward(timeInterval)
    }
    
    func skipBackward(_ timeInterval: TimeInterval) {
        AudioPlaybackManager.shared.skipBackward(timeInterval)
    }
}

// MARK: ============== Network ==============
extension PlayAudioViewModel {}

// MARK: ============== Delegate ==============
extension PlayAudioViewModel {}

// MARK: ============== Observer ==============
extension PlayAudioViewModel {
    
    private func addKeyValueObserver() {
        AudioPlaybackManager.shared.addObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.playTime), options: NSKeyValueObservingOptions.new, context: nil)
        AudioPlaybackManager.shared.addObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.duration), options: NSKeyValueObservingOptions.new, context: nil)
        AudioPlaybackManager.shared.addObserver(self, forKeyPath: #keyPath(AudioPlaybackManager.loadedTime), options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AudioPlaybackManager.playTime) {
            if !isTracking {
                playTime.accept(AudioPlaybackManager.shared.playTime)
            }
        } else if keyPath == #keyPath(AudioPlaybackManager.duration) {
            itemDuration.accept(AudioPlaybackManager.shared.duration)
        } else if keyPath == #keyPath(AudioPlaybackManager.loadedTime) {
            loadedTime.accept(AudioPlaybackManager.shared.loadedTime)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: ============== Notification ==============
extension PlayAudioViewModel {
    
    private func addNotiObserver() {
        // Ready to play noti.
        NotificationCenter.default.addObserver(forName: AudioPlaybackManager.readyToPlayNotification, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else { return }

            if !self.isForcePause {
                AudioPlaybackManager.shared.play()
            }
        }
        
        // Play status did change noti.
        NotificationCenter.default.addObserver(forName: AudioPlaybackManager.playStatusDidChangeNotification, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else { return }

            /// 切换状态
            ///
            /// 控制器监听到 finished 状态后, 自动进行切歌操作, 就会触发即将播放音乐的 prepare 状态,
            /// 会 被 RX 判定为 sequence 中的上一个 event 未结束, 又添加进了新的 event,
            /// 怀疑可能进入了循环, 而 log 警告。为避免产生警告, 因此这里统一处理为异步执行。
            DispatchQueue.main.async {
                self.playStatus.accept(AudioPlaybackManager.shared.playStatus)
            }
        }
        
        // Remote control previous track noti.
        NotificationCenter.default.addObserver(forName: AudioPlaybackManager.previousTrackNotification, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else { return }

            self.switchAudio(isNext: false)
        }
        
        // Remote control next track noti.
        NotificationCenter.default.addObserver(forName: AudioPlaybackManager.nextTrackNotification, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else { return }

            self.switchAudio(isNext: true)
        }
    }
}
