//
//  PlayAudioProgressView.swift
//  PulseM-iOS
//
//  Created by LM on 2023/2/22.
//

import UIKit

class PlayAudioProgressView: UIView {
    
// MARK: Public Property
    
    
// MARK: Private Property
    private var progress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
// MARK: ============== Life Cycle ==============
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        makeConstraints()
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
        maskLayer.lineWidth = bounds.height
    }
    
    deinit {}
    
    override func draw(_ rect: CGRect) {
        let y = bounds.height * 0.5
        let beginPoint = CGPoint(x: 0, y: y)
        let endPoint = CGPoint(x: bounds.width * progress, y: y)
        
        let path = UIBezierPath()
        path.move(to: beginPoint)
        path.addLine(to: endPoint)
        maskLayer.path = path.cgPath
    }
    
// MARK: Setup Subviews
    private func setupSubviews() {
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
    }
    
    private lazy var backgroundLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor(hexString: "#33A6B9", alpha: 0.2).cgColor
        layer.lineCap = .round
        return layer
    }()
    
    private lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor(hexString: "#33A6B9").cgColor
        layer.lineCap = .round
        layer.mask = maskLayer
        return layer
    }()
    
    private lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor(hexString: "#33A6B9").cgColor
        return layer
    }()
    
// MARK: Make Constraints
    private func makeConstraints() {}
}

// MARK: ============== Private ==============
extension PlayAudioProgressView {}

// MARK: ============== Public ==============
extension PlayAudioProgressView {
    
    func fillData(lineWidth: CGFloat, path: CGPath) {
        backgroundLayer.lineWidth = lineWidth
        progressLayer.lineWidth = lineWidth
        
        backgroundLayer.path = path
        progressLayer.path = path
    }
    
    func update(progress: CGFloat) {
        self.progress = progress
    }
}

// MARK: ============== Network ==============
extension PlayAudioProgressView {}

// MARK: ============== Action ==============
extension PlayAudioProgressView {}

// MARK: ============== Delegate ==============
extension PlayAudioProgressView {}

// MARK: ============== Observer ==============
extension PlayAudioProgressView {}

// MARK: ============== Notification ==============
extension PlayAudioProgressView {}
