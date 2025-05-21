//
//  VideoPlayerLayerView.swift
//
//  Created by LM on 2024/5/13.
//

import UIKit
import AVFoundation

@objc
open class VideoPlayerLayerView: UIView {
    
    public override static var layerClass: AnyClass { AVPlayerLayer.self }
    
    public var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    open var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            playerLayer.videoGravity = videoGravity
        }
    }
    
    private var playerLayer: AVPlayerLayer {
        let layer = layer as! AVPlayerLayer
        layer.videoGravity = videoGravity
        return layer
    }
}
