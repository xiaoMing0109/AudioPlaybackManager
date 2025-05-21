//
//  PlayVideoControlView.swift
//  AudioPlaybackManager_Example
//
//  Created by LM on 2024/5/30.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import AudioPlaybackManager
import RxSwift

class PlayVideoControlView: UIView {
    
    // MARK: Public Properties
    
    
    // MARK: Private Properties
    
    private var viewModel: PlayVideoViewModel!
    
    private var sliderBufferTrackViewProgressWidth: CGFloat = 0
    private var sliderMinTrackViewProgressWidth: CGFloat = 0
    
    /// The instance of `DateComponentsFormatter` used for formatting times displayed in `playtimeLabel` and `durationLabel`.
    private let dateComponentsFormatter: DateComponentsFormatter = {
        // Configure the `DateComponentsFormatter` for formatting strings in a "0:00" format.
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
    
    // MARK: Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
        makeConstraints()
    }
    
    override func updateConstraints() {
        sliderMinTrackView.snp.updateConstraints { make in
            make.width.equalTo(sliderMinTrackViewProgressWidth)
        }
        
        sliderBufferTrackView.snp.updateConstraints { make in
            make.width.equalTo(sliderBufferTrackViewProgressWidth)
        }
        
        super.updateConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != .zero else { return }
    }
    
    deinit {
        print(#function)
    }
    
    // MARK: Setup Subviews
    
    private func setupSubviews() {
        addSubview(playButton)
        addSubview(progressSlider)
        addSubview(durationLabel)
        addSubview(playtimeLabel)
    }
    
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "player_play"), for: .normal)
        button.setImage(UIImage(named: "player_play"), for: .highlighted)
        button.setImage(UIImage(named: "player_pause"), for: .selected)
        button.setImage(UIImage(named: "player_pause"), for: [.selected, .highlighted])
        button.addTarget(self, action: #selector(onClickedButtonAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var progressSlider: UISlider = {
        let sliderThumbImage: UIImage? = {
            let view = UIView()
            view.frame = CGRect(origin: .zero, size: CGSize(width: 16, height: 16))
            view.backgroundColor = UIColor("#33A6B9")
            view.layer.cornerRadius = 8
            view.layer.masksToBounds = true
            view.layer.borderWidth = 2
            view.layer.borderColor = UIColor.white.cgColor
            return view.toImage
        }()
        
        let view = UISlider()
        view.setThumbImage(sliderThumbImage, for: .normal)
        view.setThumbImage(sliderThumbImage, for: .highlighted)
        view.addTarget(self, action: #selector(sliderTouchDownAction(_:)), for: .touchDown)
        view.addTarget(self, action: #selector(sliderTouchCancelAction(_:)), for: .touchCancel)
        view.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        view.insertSubview(sliderMaxTrackView, at: 0)
        view.insertSubview(sliderBufferTrackView, aboveSubview: sliderMaxTrackView)
        view.insertSubview(sliderMinTrackView, aboveSubview: sliderBufferTrackView)
        
        return view
    }()
    
    private lazy var sliderMaxTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "#33A6B9", alpha: 0.15)
        view.layer.cornerRadius = 3
        return view
    }()
    
    private lazy var sliderBufferTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "#33A6B9", alpha: 0.15)
        view.layer.cornerRadius = 3
        return view
    }()
    
    private lazy var sliderMinTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "#33A6B9", alpha: 1)
        view.layer.cornerRadius = 3
        return view
    }()
    
    private lazy var durationLabel: UILabel = {
        let view = UILabel()
        view.text = ""
        view.textColor = #colorLiteral(red: 0.2, green: 0.6509803922, blue: 0.7254901961, alpha: 1)
        view.font = .systemFont(ofSize: 14, weight: .regular)
        view.numberOfLines = 1
        return view
    }()
    
    private lazy var playtimeLabel: UILabel = {
        let view = UILabel()
        view.text = ""
        view.textColor = #colorLiteral(red: 0.2, green: 0.6509803922, blue: 0.7254901961, alpha: 1)
        view.font = .systemFont(ofSize: 14, weight: .regular)
        view.numberOfLines = 1
        return view
    }()
    
    // MARK: Make Constraints
    
    private func makeConstraints() {
        playButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        progressSlider.snp.makeConstraints { make in
            var maxLeadingTrailingInset: CGFloat {
                max(safeAreaInsets.left, safeAreaInsets.right)
            }
            make.leading.trailing.equalToSuperview().inset(50)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(progressSlider.snp.trailing).offset(10)
            make.centerY.equalTo(progressSlider)
        }
        
        playtimeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(progressSlider.snp.leading).offset(-10)
            make.centerY.equalTo(durationLabel)
        }
    }
}

// MARK: - Private

extension PlayVideoControlView {
    
    private func handlePlayButtonStatus() {
        switch viewModel.playStatus.value {
        case .prepare, .playing:
            playButton.isSelected = true
        default:
            playButton.isSelected = false
        }
    }
    
    private func handleAudioDuration() {
        let duration = viewModel.itemDuration.value
        durationLabel.text = dateComponentsFormatter.string(from: duration)
    }
    
    /// value != nil, 为拖动进度条
    private func updatePlayTimeAndProgress(value: Float? = nil) {
        let duration = viewModel.itemDuration.value
        let playTime: Float64 = {
            if let value = value {
                return Float64(value) * duration
            } else {
                return viewModel.playTime.value
            }
        }()
        
        do {
            playtimeLabel.text = dateComponentsFormatter.string(from: playTime)
        }
        
        do {
            let progress: Float = {
                if duration == 0 {
                    return 0
                } else {
                    return Float(playTime / duration)
                }
            }()
            progressSlider.setValue(progress, animated: false)
            
            var width: CGFloat {
                return CGFloat(progress) * sliderMaxTrackView.bounds.width
            }
            sliderMinTrackViewProgressWidth = width
            setNeedsUpdateConstraints()
        }
    }
    
    private func updateLoadedTimeProgress() {
        let loadedTime = viewModel.loadedTime.value
        let duration = viewModel.itemDuration.value
        
        var width: CGFloat {
            if duration == 0 {
                return 0
            }
            return CGFloat(loadedTime / duration) * sliderMaxTrackView.bounds.width
        }
        sliderBufferTrackViewProgressWidth = width
        setNeedsUpdateConstraints()
    }
}

// MARK: - Public

extension PlayVideoControlView {
    
    func bindViewModel(_ viewModel: PlayVideoViewModel, disposeBag: DisposeBag) {
        self.viewModel = viewModel
        
        viewModel.playStatus.subscribe(onNext: { [unowned self] _ in
            handlePlayButtonStatus()
        })
        .disposed(by: disposeBag)
        
        viewModel.playTime.subscribe(onNext: { [unowned self] _ in
            updatePlayTimeAndProgress()
        })
        .disposed(by: disposeBag)
        
        viewModel.itemDuration.subscribe(onNext: { [unowned self] _ in
            handleAudioDuration()
        })
        .disposed(by: disposeBag)
        
        viewModel.loadedTime.subscribe(onNext: { [unowned self] _ in
            updateLoadedTimeProgress()
        })
        .disposed(by: disposeBag)
    }
}

// MARK: - Action

extension PlayVideoControlView {
    
    @objc private func sliderTouchDownAction(_ sender: UISlider) {
        viewModel.setIsTracking(true, value: nil)
    }
    
    @objc private func sliderTouchCancelAction(_ sender: UISlider) {
        viewModel.setIsTracking(false, value: nil)
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        viewModel.setIsTracking(sender.isTracking, value: sender.value)
        updatePlayTimeAndProgress(value: sender.value)
    }
    
    @objc private func onClickedButtonAction(_ sender: UIButton) {
        switch sender {
        case playButton:
            viewModel.pauseOrResume()
        default: break
        }
    }
}

// MARK: - Delegate

extension PlayVideoControlView {}

// MARK: - Notification

extension PlayVideoControlView {}

// MARK: - Observer

extension PlayVideoControlView {}
