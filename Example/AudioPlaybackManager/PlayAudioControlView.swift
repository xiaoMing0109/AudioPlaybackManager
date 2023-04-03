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
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playtimeLabel: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    
    @IBOutlet weak var volumeStackView: UIStackView!
    
    private var viewModel: PlayAudioViewModel!
    
    private var sliderBufferTrackViewProgressWidth: CGFloat = 0
    private var sliderMinTrackViewProgressWidth: CGFloat = 0
    
// MARK: ============== Life Cycle ==============
    override func awakeFromNib() {
        super.awakeFromNib()
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
        setupControlButtons()
        setupVolumeSlider()
        setupProgressSlider()
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
    
    private lazy var volumeView: VolumeView = {
        let view = VolumeView()
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
    
    private func setupProgressSlider() {
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
        
        progressSlider.setThumbImage(sliderThumbImage, for: .normal)
        progressSlider.setThumbImage(sliderThumbImage, for: .highlighted)
        
        progressSlider.insertSubview(sliderMaxTrackView, at: 0)
        progressSlider.insertSubview(sliderBufferTrackView, aboveSubview: sliderMaxTrackView)
        progressSlider.insertSubview(sliderMinTrackView, aboveSubview: sliderBufferTrackView)
    }
    
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
        
        sliderMaxTrackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(6)
        }
        
        sliderBufferTrackView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(6)
            make.width.equalTo(0)// Will update.
        }
        
        sliderMinTrackView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(6)
            make.width.equalTo(0)// Will update.
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
            durationLabel.text = "-- : --"
        } else {
            let duration = viewModel.itemDuration.value
            let second = Int(duration) % 60
            let min = Int(duration) / 60
            durationLabel.text = String(format: "%02d : %02d", min, second)
        }
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
            let second = Int(playTime) % 60
            let min = Int(playTime) / 60
            playtimeLabel.text = String(format: "%02d : %02d", min, second)
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
    
    private func updateLoadedTimeProgress(with loadedTime: Float64) {
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
            viewModel.skipBackward(15)
        case forwardButton:
            viewModel.skipForward(30)
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

// MARK: - MPVolumeView

class VolumeView: MPVolumeView {

    override func volumeSliderRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.origin.x,
            y: (bounds.height - 6) / 2,
            width: bounds.width,
            height: 6
        )
    }
}
