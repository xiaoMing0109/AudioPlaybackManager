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

class PlayAudioViewModel {
    
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
    
    /// 模拟音频音轨 path
    ///
    /// 统一创建, 避免来回切换音频时产生同一首音频 path 不一致。
    private(set) lazy var progressViewPaths: [Int: CGPath] = [:]
    let progressViewLineWidth: CGFloat = 3
    
// MARK: Private Property
    
    /// 拖动播放进度条时会暂停 playTime 回调
    private var isTracking = false
    
    /// 用于记录 `.prepare` 阶段记录用户手动点击 播放/暂停.
    private var isForcePause = false
    
// MARK: ============== Life Cycle ==============
    init() {
        initializeItemsData()
        addNotiObserver()
    }
    
    private func initializeItemsData() {
        guard let enumerator = FileManager.default.enumerator(at: Bundle.main.bundleURL, includingPropertiesForKeys: nil, options: [], errorHandler: nil) else {
            return
        }
        var items: [Audio] = enumerator.compactMap { element in
            guard let url = element as? URL, url.pathExtension == "m4a" else {
                return nil
            }
            
            var audio = Audio(audioURL: url)
            audio.albumName = "专辑名称"
            audio.artist = "作者"
            audio.title = url.lastPathComponent
            if let path = Bundle.main.path(forResource: "artwork", ofType: "jpg") {
                audio.artworkURL = URL(string: path)
            }
            return audio
        }
        
        let onlinePaths = [
            "https://tyst.migu.cn/public/ringmaker01/n15/2016/07/2016%E5%B9%B407%E6%9C%8818%E6%97%A515%E7%82%B955%E5%88%86%E7%B4%A7%E6%80%A5%E5%86%85%E5%AE%B9%E5%87%86%E5%85%A5SONY406%E9%A6%96/%E6%AD%8C%E6%9B%B2%E4%B8%8B%E8%BD%BD/MP3_128_16_Stero/%E6%88%91%E7%88%B1%E8%BF%87%E4%BD%A0-Eric%20%E5%91%A8%E5%85%B4%E5%93%B2.mp3",
            "https://m801.music.126.net/20230319210223/d966542b15ce82527cd207e3a6532f6b/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/23382221099/30f1/8bd8/a054/fdd3ec2af8a78a3e8225aec7d6c131f0.mp3",
            "https://m804.music.126.net/20230319210337/1347b6d85489bd7902e5422219b64a66/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/14096410131/63dd/2e55/78b2/45827f3a78775ad8e9ae256e28adfa7a.mp3?_authSecret=00000186f9e0fd401cda0aaba0c291a9",
            "https://m804.music.126.net/20230319210707/c7917e318c90c91124cd23eeeb84ab36/jdymusic/obj/wo3DlMOGwrbDjj7DisKw/14096523020/ebf6/daf7/f9f6/8e622c75c825823b8eba4cf67830527b.mp3?_authSecret=00000186f9e433c718690aaba60f167c"
        ]
        for path in onlinePaths {
            guard let url = URL(string: path) else {
                continue
            }
            var audio = Audio(audioURL: url)
            audio.albumName = "专辑名称"
            audio.artist = "作者"
            audio.title = url.lastPathComponent
            if let path = Bundle.main.path(forResource: "artwork", ofType: "jpg") {
                audio.artworkURL = URL(string: path)
            }
            items.append(audio)
        }
        self.items.accept(items)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: ============== Private ==============
extension PlayAudioViewModel {
    
    private func addNotiObserver() {
        let userInfoKeys = AudioPlaybackManager.NotificationUserInfoKeys.self
        
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

            guard let userInfo = noti.userInfo,
                  let status = userInfo[userInfoKeys.playStatus] as? AudioPlaybackManager.PlayStatus
            else { return }

            /// 切换状态
            ///
            /// 控制器监听到 finished 状态后, 自动进行切歌操作, 就会触发 prepare 状态,
            /// RX 会判定为 sequence 中的上一个 event 未结束, 又添加进了新的 event,
            /// 怀疑可能进入了循环, 而 log 警告。
            /// 为避免产生警告, 因此这里统一处理为异步执行。
            DispatchQueue.main.async {
                self.playStatus.accept(status)
            }
        }
        
        // Play time variation noti.
        NotificationCenter.default.addObserver(forName: AudioPlaybackManager.playTimeNotification, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else { return }

            guard let userInfo = noti.userInfo,
                  let playTime = userInfo[userInfoKeys.playTime] as? Float64
            else { return }

            if !self.isTracking {
                self.playTime.accept(playTime)
            }
        }
        
        // Duration noti.
        NotificationCenter.default.addObserver(forName: AudioPlaybackManager.durationNotification, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else { return }

            guard let userInfo = noti.userInfo,
                  let duration = userInfo[userInfoKeys.duration] as? Float64
            else { return }

            self.itemDuration.accept(duration)
        }
        
        // Loaded time ranges noti.
        NotificationCenter.default.addObserver(forName: AudioPlaybackManager.loadedTimeNotification, object: nil, queue: .main) { [weak self] noti in
            guard let self = self else { return }

            guard let userInfo = noti.userInfo,
                  let loadedTime = userInfo[userInfoKeys.loadedTime] as? Float64
            else { return }

            self.loadedTime.accept(loadedTime)
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
    
    /// 设置初始 playTime.
    /// - Parameters:
    ///   - playTime: 播放第一首时需要查询上次播放进度, 传入 nil 即可, 则从本地获取;
    ///               切歌时传入 0, 从头开始。
    ///   - index: Item index.
    private func setupInitialPlayTime(_ playTime: Float64?, at index: Int) {
        guard let playTime = playTime else {
            self.playTime.accept(0)
            return
        }
        self.playTime.accept(playTime)
    }
    
    /// 设置初始音频时长, 本地查询
    private func setupInitialDuration(at index: Int) {
        self.itemDuration.accept(0)
    }
    
    /// 重置缓存进度
    private func resetInitialLoadedTime() {
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
        setupInitialPlayTime(nil, at: index)
        setupInitialDuration(at: index)
        resetInitialLoadedTime()

        // play
        let items = items.value
        AudioPlaybackManager.shared.setupItem(items[index], beginTime: playTime.value)
    }
    
    /// 暂停或继续播放.
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
    
    /// 用于记录 `.prepare` 阶段用户手动点击 播放/暂停.
    func forcePause() {
        isForcePause = true
        
        AudioPlaybackManager.shared.pause()
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
        setupInitialPlayTime(0, at: index)
        setupInitialDuration(at: index)
        resetInitialLoadedTime()
        
        // play
        let items = items.value
        AudioPlaybackManager.shared.setupItem(items[index], beginTime: 0)
    }
    
    func stopPlay() {
        AudioPlaybackManager.shared.stop()
    }
    
    func setIsTracking(_ isTracking: Bool, value: Float?) {
        self.isTracking = isTracking
        if !isTracking, let value = value {
            AudioPlaybackManager.shared.seekToProgress(value)
        }
    }
}

// MARK: ============== Network ==============
extension PlayAudioViewModel {}

// MARK: ============== Delegate ==============
extension PlayAudioViewModel {}

// MARK: ============== Observer ==============
extension PlayAudioViewModel {}

// MARK: ============== Notification ==============
extension PlayAudioViewModel {}

// MARK: - Audio ProgressView Path

extension PlayAudioViewModel {
    
    func fetchProgressViewPath(at index: Int) -> CGPath {
        if let path = progressViewPaths[index] {
            return path
        }
        
        let path = generateProgressViewPath()
        progressViewPaths[index] = path
        return path
    }
    
    private func generateProgressViewPath() -> CGPath {
        let canvasSize = CGSize(width: SCREEN_WIDTH - 50 * 2, height: 32)
        let drawMargin: CGFloat = 3
        let drawLineWidth = progressViewLineWidth
        let drawLineMinHeight: CGFloat = 4
        // `layer.lineCap` 会在原有 `lineWidth` 范围外生成, 避免尖部被裁切掉这里提前减去
        let drawLineMaxHeight: CGFloat = canvasSize.height - drawLineWidth
        
        let path = UIBezierPath()
        var x: CGFloat = 0.0
        while x + drawLineWidth <= canvasSize.width {
            x += drawLineWidth / 2
            
            let randomHeight = CGFloat.random(in: drawLineMinHeight ... drawLineMaxHeight)
            let beginY = drawLineWidth * 0.5 + (drawLineMaxHeight - randomHeight) * 0.5
            let endY = beginY + randomHeight
            
            path.move(to: CGPoint(x: x, y: beginY))
            path.addLine(to: CGPoint(x: x, y: endY))
            
            x += (drawLineWidth / 2) + drawMargin
        }
        return path.cgPath
    }
}
