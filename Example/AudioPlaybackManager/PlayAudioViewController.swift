//
//  PlayAudioViewController.swift
//  AudioPlaybackManager_Example
//
//  Created by 刘铭 on 2023/2/25.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import AudioPlaybackManager
import RxSwift
import CoreMedia

class PlayAudioViewController: UIViewController {
    
// MARK: Public Property
    
    
// MARK: Private Property
    private let viewModel: PlayAudioViewModel
    private let defaultPlayIndex: Int
    
    private let disposeBag = DisposeBag()
    
// MARK: ============== Life Cycle ==============
    init(audioURLs: [URL], defaultPlayIndex: Int) {
        self.viewModel = PlayAudioViewModel(audioURLs: audioURLs)
        self.defaultPlayIndex = defaultPlayIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        makeConstraints()
        addSubscribe()
        
        // 后台 + 设备静音模式 可播放
        AudioPlaybackManager.shared.setActiveSession(true, activeOptions: [.notifyOthersOnDeactivation])
        
        // Cache enable for network url.
        AudioPlaybackManager.shared.cacheEnabled = true
        
        // Allow show playing info in the background.
        AudioPlaybackManager.shared.allowSetNowPlayingInfo = true
        
        // Remote control commands.
        AudioPlaybackManager.shared.activatePlaybackCommands(true)
        AudioPlaybackManager.shared.activatePreviousTrackCommand(true)
        AudioPlaybackManager.shared.activateNextTrackCommand(true)
        AudioPlaybackManager.shared.activateSeekBackwardCommand(true)
        AudioPlaybackManager.shared.activateSeekForwardCommand(true)
        AudioPlaybackManager.shared.activateChangePlaybackPositionCommand(true)
        
        // Log enable.
        AudioPlaybackManager.shared.logEnabled = true
        AudioPlaybackManager.shared.logLevel = .info
        
        viewModel.playAudio(at: defaultPlayIndex)
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
        viewModel.stopPlay()
        AudioPlaybackManager.shared.deactivateAllRemoteCommands()
        AudioPlaybackManager.shared.setActiveSession(false, activeOptions: [.notifyOthersOnDeactivation])
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }
    
// MARK: Setup Subviews
    private func setupSubviews() {
        view.backgroundColor = .white
        
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(playControlView)
    }
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = ""
        view.textColor = .systemPink
        view.textAlignment = .center
        view.font = .systemFont(ofSize: 18)
        view.numberOfLines = 0
        return view
    }()
    
    private lazy var playControlView: PlayAudioControlView = {
        let view = PlayAudioControlView.loadFromNib()
        view.bindViewModel(viewModel, disposeBag: disposeBag)
        return view
    }()
    
// MARK: Make Constraints
    private func makeConstraints() {
        imageView.snp.makeConstraints { make in
            make.top.equalTo(100)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 300, height: 300))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(imageView.snp.bottom).offset(30)
        }
        
        playControlView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            } else {
                make.bottom.equalTo(-20)
            }
            make.height.equalTo(210)
        }
    }
}

// MARK: ============== Private ==============
extension PlayAudioViewController {
    
    private func addSubscribe() {
        viewModel.playIndex.subscribe(onNext: { [unowned self] index in
            guard let index = index else { return }
            
            let item = viewModel.items.value[index]
            
            if let image = item.artworkImage {
                imageView.image = image
            } else if let url = item.artworkURL {
                if url.isFileURL {
                    var path: String {
                        if #available(iOS 16.0, *) {
                            return url.path()
                        } else {
                            return url.path
                        }
                    }
                    imageView.image = UIImage(contentsOfFile: path)
                } else {
                    DispatchQueue.global().async {
                        let data = try? Data(contentsOf: url)
                        let image = UIImage(data: data ?? Data())
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.imageView.image = image
                        }
                    }
                }
                
                titleLabel.text = item.title
            } else {
                imageView.image = nil
            }
        })
        .disposed(by: disposeBag)
        
        viewModel.playStatus.subscribe(onNext: { [unowned self] status in
            guard let status = status else { return }
            
            switch status {
            case .playCompleted:
                if let index = viewModel.fetchWillPlayNextIndex() {
                    viewModel.switchAudio(at: index)
                } else {
                    backAction()
                }
            default: break
            }
        })
        .disposed(by: disposeBag)
    }
}

// MARK: ============== Public ==============
extension PlayAudioViewController {}

// MARK: ============== Network ==============
extension PlayAudioViewController {
    
    private func netRequest() {}
}

// MARK: ============== Action ==============
extension PlayAudioViewController {
    
    private func backAction() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: ============== Delegate ==============
extension PlayAudioViewController {}

// MARK: ============== Observer ==============
extension PlayAudioViewController {}

// MARK: ============== Notification ==============
extension PlayAudioViewController {}
