//
//  PlayAudioControlView.swift
//  PulseG-iOS
//
//  Created by LM on 2022/6/21.
//

import UIKit
import RxSwift
import MediaPlayer
import QQCorner
import SnapKit

class PlayAudioControlView: UIView {
    
// MARK: Public Property
    
    
// MARK: Private Property
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var controlButtonsStackViewConstraintBottom: NSLayoutConstraint!
    @IBOutlet weak var controlButtonsStackViewConstraintTop: NSLayoutConstraint!
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playtimeLabel: UILabel!
    
    @IBOutlet weak var volumeStackView: UIStackView!
    
    @IBOutlet weak var progressBackgroundView: UIView!
    
    private var viewModel: PlayAudioViewModel!
    
// MARK: ============== Life Cycle ==============
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSubviews()
        makeConstraints()
    }
    
    override func updateConstraints() {
        
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
        setupControlButtons()
        setupVolumeSlider()
        setupProgressView()
    }
    
    private func setupControlButtons() {
        playButton.setImage(UIImage(named: "meditation_player_play"), for: .normal)
        playButton.setImage(UIImage(named: "meditation_player_play"), for: .highlighted)
        playButton.setImage(UIImage(named: "meditation_player_pause"), for: .selected)
        playButton.setImage(UIImage(named: "meditation_player_pause"), for: [.selected, .highlighted])
        
        addSubview(loadingButton)
        startLoadingAnimation()
    }
    
    private lazy var loadingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "meditation_player_loading"), for: .normal)
        button.isUserInteractionEnabled = false
        button.isHidden = true// Default hidden.
        return button
    }()
    
    private func setupVolumeSlider() {
        volumeStackView.addArrangedSubview(volumeDownImageView)
        volumeStackView.addArrangedSubview(volumeView)
        volumeStackView.addArrangedSubview(volumeUpImageView)
    }
    
    private lazy var volumeDownImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "meditation_player_volume.down")
        return view
    }()
    
    private lazy var volumeUpImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "meditation_player_volume.up")
        return view
    }()
    
    private lazy var volumeView: PLMVolumeView = {
        let view = PLMVolumeView()
        view.showsRouteButton = false
        view.showsVolumeSlider = true
        view.setVolumeThumbImage(volumeSliderThumbImage, for: .normal)
        view.setVolumeThumbImage(volumeSliderThumbImage, for: .highlighted)
        var minimumTrackImage: UIImage? {
            var image = UIImage(color: UIColor(hexString: "#33A6B9"),
                                size: CGSize(width: 6, height: 6),
                                cornerRadius: QQRadiusMakeSame(3))
            image = image?.resizableImage(
                withCapInsets: .init(top: 3, left: 3, bottom: 3, right: 3),
                resizingMode: .stretch
            )
            return image
        }
        view.setMinimumVolumeSliderImage(minimumTrackImage, for: .normal)
        var maximumTrackImage: UIImage? {
            var image = UIImage(color: UIColor(hexString: "#33A6B9", alpha: 0.2),
                                size: CGSize(width: 6, height: 6),
                                cornerRadius: QQRadiusMakeSame(3))
            image = image?.resizableImage(
                withCapInsets: .init(top: 3, left: 3, bottom: 3, right: 3),
                resizingMode: .stretch
            )
            return image
        }
        view.setMaximumVolumeSliderImage(maximumTrackImage, for: .normal)
        return view
    }()
    
    private lazy var volumeSliderThumbImage: UIImage? = {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 16, height: 16)))
        view.backgroundColor = UIColor("#33A6B9")
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        return view.toImage
    }()
    
    private func setupProgressView() {
        progressBackgroundView.addSubview(progressView)
    }
    
    private lazy var progressView: PlayAudioProgressView = {
        let view = PlayAudioProgressView()
        return view
    }()
    
// MARK: Make Constraints
    private func makeConstraints() {
        loadingButton.snp.makeConstraints { make in
            make.edges.equalTo(playButton)
        }
        
        volumeDownImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

        volumeUpImageView.snp.makeConstraints { make in
            make.size.equalTo(volumeDownImageView)
        }
        
        progressView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: ============== Private ==============
extension PlayAudioControlView {
    
    private func fillData() {
        handlePlayButtonStatus()
        handleAudioDuration()
        updatePlayTimeAndProgress()
    }
    
    private func handlePlayButtonStatus() {
        switch viewModel.playStatus.value {
        case .prepare, .playing:
            playButton.isSelected = true
        default:
            playButton.isSelected = false
        }
    }
    
    private func handleAudioDuration() {
        let loadedTime = viewModel.loadedTime.value
        // 未加载到缓冲前不展示时长(时长为通过 `AVPlayerItem` 获取)
        if loadedTime <= 0 {
            durationLabel.isHidden = true
        } else {
            durationLabel.isHidden = false
         
            let duration = viewModel.itemDuration.value
            let second = Int(duration) % 60
            let min = Int(duration) / 60
            durationLabel.text = String(format: "%02d : %02d", min, second)
        }
    }
    
    /// value != nil, 为拖动进度条
    private func updatePlayTimeAndProgress(value: Float? = nil) {
        let duration = viewModel.itemDuration.value
        var playTime: Float64
        if let value = value {
            playTime = Float64(value) * duration
        } else {
            playTime = viewModel.playTime.value
        }
        
        do {
            let loadedTime = viewModel.loadedTime.value
            if playTime <= loadedTime, loadedTime > 0 {
                let second = Int(playTime) % 60
                let min = Int(playTime) / 60
                playtimeLabel.text = String(format: "%02d : %02d", min, second)
            } else {
                playtimeLabel.text = "Loading..."
            }
        }
        
        do {
            let progress: CGFloat = {
                if duration == 0 {
                    return 0
                } else {
                    return CGFloat(playTime / duration)
                }
            }()
            progressView.update(progress: progress)
        }
    }
    
    private func updateLoadedTimeProgress(with loadedTime: Float64) {}
    
    /// Loading animation.
    private func startLoadingAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = Double.pi * 2
        animation.duration = 1.5
        animation.repeatCount = .greatestFiniteMagnitude
        animation.isRemovedOnCompletion = false
        loadingButton.layer.add(animation, forKey: "loading.rotate")
    }
}

// MARK: ============== Public ==============
extension PlayAudioControlView {
    
    func bindViewModel(_ viewModel: PlayAudioViewModel, disposeBag: DisposeBag) {
        self.viewModel = viewModel
        fillData()
        
        viewModel.playStatus.subscribe(onNext: { [unowned self] status in
            if let status = status {
                switch status {
                case .prepare:
                    loadingButton.isHidden = false
                default:
                    loadingButton.isHidden = true
                }
            }
            
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
        
        viewModel.loadedTime.subscribe(onNext: { [unowned self] value in
            updateLoadedTimeProgress(with: value)
            handleAudioDuration()
        })
        .disposed(by: disposeBag)
        
        viewModel.playIndex.subscribe(onNext: { [unowned self] index in
            if let index = index {
                let count = viewModel.items.value.count
                if index == 0 {
                    previousButton.isEnabled = false
                    nextButton.isEnabled = true
                } else if index == count - 1 {
                    previousButton.isEnabled = true
                    nextButton.isEnabled = false
                } else {
                    previousButton.isEnabled = true
                    nextButton.isEnabled = true
                }
                
                progressView.fillData(
                    lineWidth: viewModel.progressViewLineWidth,
                    path: viewModel.fetchProgressViewPath(at: index)
                )
            }
        })
        .disposed(by: disposeBag)
    }
}

// MARK: ============== Network ==============
extension PlayAudioControlView {}

// MARK: ============== Action ==============
extension PlayAudioControlView {
    
    @IBAction func sliderTouchDownAction(_ sender: UISlider) {
        viewModel.setIsTracking(true, value: nil)
    }
    
    @IBAction func sliderTouchCancelAction(_ sender: UISlider) {
        viewModel.setIsTracking(false, value: nil)
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        viewModel.setIsTracking(sender.isTracking, value: sender.value)
        updatePlayTimeAndProgress(value: sender.value)
    }
    
    @IBAction func onClickedButtonAction(_ sender: UIButton) {
        guard let index = viewModel.playIndex.value else {
            return
        }
        
        switch sender {
        case playButton:
            viewModel.pauseOrResume()
        case previousButton:
            let willPlayIndex = index - 1
            if viewModel.isValidIndex(willPlayIndex) {
                viewModel.switchAudio(isNext: false)
            }
        case nextButton:
            let willPlayIndex = index + 1
            if viewModel.isValidIndex(willPlayIndex) {
                viewModel.switchAudio(isNext: true)
            }
        case backwardButton:
            let duration = viewModel.itemDuration.value
            guard duration > 0 else { return }
            
            let playTime = viewModel.playTime.value
            guard playTime > 0 else { return }
            
            let step: TimeInterval = -15
            var target: TimeInterval = playTime + step
            if target <= 0 { target = 0 }
            viewModel.setIsTracking(false, value: Float(target / duration))
        case forwardButton:
            let duration = viewModel.itemDuration.value
            guard duration > 0 else { return }
            
            let playTime = viewModel.playTime.value
            let step: TimeInterval = 30
            var target: TimeInterval = playTime + step
            if target >= duration { target = duration }
            viewModel.setIsTracking(false, value: Float(target / duration))
        default: break
        }
    }
}

// MARK: ============== Delegate ==============
extension PlayAudioControlView {}

// MARK: ============== Observer ==============
extension PlayAudioControlView {}

// MARK: ============== Notification ==============
extension PlayAudioControlView {}

// MARK: MPVolumeView

class PLMVolumeView: MPVolumeView {

    override func volumeSliderRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.origin.x,
            y: (bounds.height - 6) / 2,
            width: bounds.width,
            height: 6
        )
    }
}
