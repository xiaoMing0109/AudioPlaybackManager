//
//  AudioPlaybackManager+NowPlayingInfo.swift
//
//  Created by 刘铭 on 2023/3/25.
//

import Foundation
import MediaPlayer

extension AudioPlaybackManager {
    
    private struct AssociatedKeys {
        static var nowPlayingInfoCenterKey: Void?
        static var allowSetNowPlayingInfoKey: Void?
        static var resizedImageSizeKey: Void?
    }
    
    // MARK: Public Properties
    
    /// Allows to set background playback display information.
    ///
    /// Default is `true`.
    @objc
    open var allowSetNowPlayingInfo: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.allowSetNowPlayingInfoKey) as? Bool ?? true
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.allowSetNowPlayingInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Set the artwork size, recommended ratio is 1:1.
    ///
    /// Default is { 640, 640 }.
    @objc
    open var artworkImageSize: CGSize {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.resizedImageSizeKey) as? CGSize ?? CGSize(width: 640, height: 640)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.resizedImageSizeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    // MARK: Private Properties
    
    /// The instance of `MPNowPlayingInfoCenter`.
    private var nowPlayingInfoCenter: MPNowPlayingInfoCenter {
        if let center = objc_getAssociatedObject(self, &AssociatedKeys.nowPlayingInfoCenterKey) as? MPNowPlayingInfoCenter {
            return center
        }
        
        let center = MPNowPlayingInfoCenter.default()
        objc_setAssociatedObject(self, &AssociatedKeys.nowPlayingInfoCenterKey, center, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return center
    }
}

extension AudioPlaybackManager {
    
    internal func setNowPlayingInfo() {
        guard allowSetNowPlayingInfo,
              let audio = audio,
              let item = player.currentItem
        else {
            nowPlayingInfoCenter.nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        
        if audio.useAudioMetadata {
            let asset = item.asset
            
            let titleKey = AVMetadataKey.commonKeyTitle
            let albumNameKey = AVMetadataKey.commonKeyAlbumName
            let artistKey = AVMetadataKey.commonKeyArtist
            
            if #available(iOS 15.0, *) {
                asset.loadMetadata(for: .iTunesMetadata) { [weak self] metadataItems, error in
                    guard let self = self, let metadataItems = metadataItems else { return }
                    
                    let title = self.acquireMetadataItem(from: metadataItems, withKey: titleKey) as? String
                    let album = self.acquireMetadataItem(from: metadataItems, withKey: albumNameKey) as? String
                    let artist = self.acquireMetadataItem(from: metadataItems, withKey: artistKey) as? String
                    
                    nowPlayingInfo[MPMediaItemPropertyTitle] = title
                    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
                    nowPlayingInfo[MPMediaItemPropertyArtist] = artist
                    
                    self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
                }
            } else {
                let metadataItems = asset.commonMetadata
                
                let title = self.acquireMetadataItem(from: metadataItems, withKey: titleKey) as? String
                let album = self.acquireMetadataItem(from: metadataItems, withKey: albumNameKey) as? String
                let artist = self.acquireMetadataItem(from: metadataItems, withKey: artistKey) as? String
                
                nowPlayingInfo[MPMediaItemPropertyTitle] = title
                nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
                nowPlayingInfo[MPMediaItemPropertyArtist] = artist
                
                nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
            }
        } else {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = audio.albumName
            nowPlayingInfo[MPMediaItemPropertyArtist] = audio.artist
            nowPlayingInfo[MPMediaItemPropertyTitle] = audio.title
            
            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
        
        appendArtwork()
    }
    
    private func appendArtwork() {
        var nowPlayingInfo = self.nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        
        guard let audio = audio,
              let item = player.currentItem
        else {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
            return
        }
        
        if audio.useAudioMetadata {
            let asset = item.asset
            
            let artworkKey = AVMetadataKey.commonKeyArtwork
            
            if #available(iOS 15.0, *) {
                asset.loadMetadata(for: .iTunesMetadata) { [weak self] metadataItems, error in
                    guard let self = self, let metadataItems = metadataItems else { return }
                    
                    DispatchQueue.global().async {
                        var artwork: MPMediaItemArtwork? {
                            if let artworkData = self.acquireMetadataItem(from: metadataItems, withKey: artworkKey) as? Data,
                               let image = UIImage(data: artworkData) {
                                return MPMediaItemArtwork(boundsSize: self.artworkImageSize) { size in
                                    return image.resize(withSize: size)
                                }
                            } else {
                                return nil
                            }
                        }
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                        
                        DispatchQueue.main.async {
                            self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
                        }
                    }
                }
            } else {
                let metadataItems = asset.commonMetadata
                
                DispatchQueue.global().async {
                    var artwork: MPMediaItemArtwork? {
                        if let artworkData = self.acquireMetadataItem(from: metadataItems, withKey: artworkKey) as? Data,
                           let image = UIImage(data: artworkData) {
                            return MPMediaItemArtwork(boundsSize: self.artworkImageSize) { size in
                                return image.resize(withSize: size)
                            }
                        } else {
                            return nil
                        }
                    }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    
                    DispatchQueue.main.async {
                        self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
                    }
                }
            }
        } else {
            if let image = audio.artworkImage {
                let artwork = MPMediaItemArtwork(boundsSize: artworkImageSize) { size in
                    return image.resize(withSize: size)
                }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                
                nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
            } else if let url = audio.artworkURL {
                if url.isFileURL {
                    var path: String {
                        if #available(iOS 16.0, *) {
                            return url.path()
                        } else {
                            return url.path
                        }
                    }
                    var artwork: MPMediaItemArtwork? {
                        if let image = UIImage(contentsOfFile: path) {
                            return MPMediaItemArtwork(boundsSize: artworkImageSize) { size in
                                return image.resize(withSize: size)
                            }
                        } else {
                            return nil
                        }
                    }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    
                    nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
                } else {
                    DispatchQueue.global().async {
                        var artwork: MPMediaItemArtwork? {
                            if let data = try? Data(contentsOf: url, options: .mappedIfSafe),
                               let image = UIImage(data: data) {
                                return MPMediaItemArtwork(boundsSize: self.artworkImageSize) { size in
                                    return image.resize(withSize: size)
                                }
                            } else {
                                return nil
                            }
                        }
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                        
                        DispatchQueue.main.async {
                            self.nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
                        }
                    }
                }
            } else {
                nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
                
                nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    
    private func acquireMetadataItem(from metadataItems: [AVMetadataItem], withKey key: Any?, keySpace: AVMetadataKeySpace? = .common) -> (NSCopying & NSObjectProtocol)? {
        let value = AVMetadataItem.metadataItems(from: metadataItems, withKey: key, keySpace: keySpace).first?.value
        return value
    }
    
    internal func updatePlaybackMetadata() {
        guard allowSetNowPlayingInfo else {
            nowPlayingInfoCenter.nowPlayingInfo = nil
            return
        }
        
        guard let item = player.currentItem else {
            nowPlayingInfoCenter.nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(item.duration)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(item.currentTime())
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = rate
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: - UIImage + Resize

fileprivate extension UIImage {

    func resize(withSize size: CGSize, contentMode: UIView.ContentMode = .scaleAspectFill) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { _ in
            let drawRect = cgRectFit(
                in: CGRect(origin: .zero, size: size),
                size: self.size,
                contentMode: contentMode
            )
            draw(in: drawRect)
        }
        return image
    }

    private func cgRectFit(in rect: CGRect, size: CGSize, contentMode: UIView.ContentMode) -> CGRect {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var fitRect: CGRect = .zero
        switch contentMode {
        case .scaleAspectFit, .scaleAspectFill:
            if rect.width < 0.01 || rect.height < 0.01 ||
               size.width < 0.01 || size.height < 0.01 {
                fitRect.origin = center
            } else {
                let scale: CGFloat
                if contentMode == .scaleAspectFit {
                    if size.width / size.height < rect.size.width / rect.size.height {
                        scale = rect.size.height / size.height
                    } else {
                        scale = rect.size.width / size.width
                    }
                } else {
                    if size.width / size.height < rect.size.width / rect.size.height {
                        scale = rect.size.width / size.width
                    } else {
                        scale = rect.size.height / size.height
                    }
                }
                fitRect.size.width = size.width * scale
                fitRect.size.height = size.height * scale
                fitRect.origin = CGPoint(
                    x: center.x - rect.width * 0.5,
                    y: center.y - rect.height * 0.5
                )
            }
        default:
            fitRect = rect
        }
        return fitRect
    }
}
