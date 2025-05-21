//
//  PlayVideoView.swift
//  AudioPlaybackManager_Example
//
//  Created by LM on 2024/5/30.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import AudioPlaybackManager
import RxSwift

class PlayVideoView: UIView {
    
    // MARK: Public Properties
    
    private(set) var videos: [Audio] = []
    private var playbackManager: AudioPlaybackManager!
    
    // MARK: Private Properties
    
    private var viewModel: PlayVideoViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: Life Cycle
    
    convenience init(videos: [Audio], playbackManager: AudioPlaybackManager) {
        self.init(frame: .zero, videos: videos, playbackManager: playbackManager)
    }
    
    convenience init(frame: CGRect, videos: [Audio], playbackManager: AudioPlaybackManager) {
        self.init(frame: frame)
        self.videos = videos
        self.playbackManager = playbackManager
        self.viewModel = PlayVideoViewModel(videos: videos, playbackManager: playbackManager)
        
        setupSubviews()
        makeConstraints()
        addNotiObserve()
        
        // Play
        viewModel.playAudio(at: 0)
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        super.updateConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != .zero else { return }
    }
    
    deinit {
        removeNotiObserve()
    }
    
    // MARK: Setup Subviews
    
    private func setupSubviews() {
        addSubview(playerLayerView)
        addSubview(playControlView)
    }
    
    /// The player view.
    private lazy var playerLayerView: VideoPlayerLayerView = {
        let view = VideoPlayerLayerView()
        view.player = playbackManager.player
        view.videoGravity = .resizeAspect
        return view
    }()
    
    private lazy var playControlView: PlayVideoControlView = {
        let view = PlayVideoControlView()
        view.bindViewModel(viewModel, disposeBag: disposeBag)
        return view
    }()
    
    // MARK: Make Constraints
    
    private func makeConstraints() {
        playerLayerView.snp.makeConstraints { make in
            make.centerY.leading.trailing.equalToSuperview()
            make.height.equalTo(playerLayerView.snp.width)
        }
        
        playControlView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Private

extension PlayVideoView {}

// MARK: - Public

extension PlayVideoView {
    
    func appendVideos(_ videos: [Audio]) {
        self.videos.append(contentsOf: videos)
    }
    
    func removeAllVideos(_ videos: [Audio]) {
        self.videos = []
    }
}

// MARK: - Action

extension PlayVideoView {}

// MARK: - Delegate

extension PlayVideoView {}

// MARK: - Notification

extension PlayVideoView {
    
    private func addNotiObserve() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            
        }
    }
    
    private func removeNotiObserve() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Observer

extension PlayVideoView {}
