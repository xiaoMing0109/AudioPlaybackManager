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

class PlayAudioViewController: UIViewController {
    
// MARK: Public Property
    let viewModel: PlayAudioViewModel
    
// MARK: Private Property
    private let defaultPlayIndex: Int
    
    private let disposeBag = DisposeBag()
    
// MARK: ============== Life Cycle ==============
    init(viewModel: PlayAudioViewModel, defaultPlayIndex: Int) {
        self.viewModel = viewModel
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
        AudioPlaybackManager.shared.activeAllRemoteCommands(true)
        
        AudioPlaybackManager.shared.activeSession(true)
        
        viewModel.playAudio(at: defaultPlayIndex)
        
        viewModel.playIndex.subscribe(onNext: { [unowned self] index in
            guard let index = index else { return }
            
            let item = viewModel.items.value[index]
            if let url = item.artworkURL {
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url)
                    let image = UIImage(data: data ?? Data())
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.imageView.image = image
                    }
                }
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
            case .error:
                // 加载失败时弹错误弹窗, 关闭后允许手动再次播放。
                showErrorAlert()
            default: break
            }
        })
        .disposed(by: disposeBag)
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
        AudioPlaybackManager.shared.activeSession(false)
    }
    
// MARK: Setup Subviews
    private func setupSubviews() {
        view.backgroundColor = .white
        
        view.addSubview(imageView)
        view.addSubview(playControlView)
    }
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
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
            make.top.equalTo(20)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 300, height: 300))
        }
        
        playControlView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            } else {
                make.bottom.equalTo(-20)
            }
            make.height.equalTo(220)
        }
    }
}

// MARK: ============== Private ==============
extension PlayAudioViewController {
    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "Error", message: "加载音频失败, 请检查网络后重试", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
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
