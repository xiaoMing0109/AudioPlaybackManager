//
//  PlayVideoViewController.swift
//  AudioPlaybackManager_Example
//
//  Created by LM on 2024/5/30.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import AudioPlaybackManager

class PlayVideoViewController: UIViewController {
    
    // MARK: Public Properties
    
    
    // MARK: Private Properties
    
    private let videoURL: URL
    
    private(set) lazy var playbackManager: AudioPlaybackManager = {
        let manager = AudioPlaybackManager()
        // Cache enable for network url.
        manager.cacheEnabled = true
        
        // Allow show playing info in the background.
        manager.allowSetNowPlayingInfo = true
        
        // Log enable.
        manager.logEnabled = true
        manager.logLevel = .info
        
        return manager
    }()
    
    // MARK: Life Cycle
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        makeConstraints()
        netRequest()
        
        // 设备静音模式 可播放
        playbackManager.setActiveSession(true, mode: .moviePlayback)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        playbackManager.stop()
        playbackManager.setActiveSession(false)
    }
    
    // MARK: Setup Subviews
    
    private func setupSubviews() {
        view.backgroundColor = .white
        view.addSubview(playVideoView)
    }
    
    private lazy var playVideoView: PlayVideoView = {
        let items = [videoURL].map { url in
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
        
        let view = PlayVideoView(videos: items, playbackManager: playbackManager)
        return view
    }()
    
    // MARK: Make Constraints
    
    private func makeConstraints() {
        playVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Private

extension PlayVideoViewController {}

// MARK: - Public

extension PlayVideoViewController {}

// MARK: - Action

extension PlayVideoViewController {}

// MARK: - Network

extension PlayVideoViewController {
    
    private func netRequest() {}
}

// MARK: - Delegate

extension PlayVideoViewController {}

// MARK: - Notification

extension PlayVideoViewController {}

// MARK: - Observer

extension PlayVideoViewController {}
