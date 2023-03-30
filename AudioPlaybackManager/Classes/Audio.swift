//
//  Audio.swift
//
//  Created by LM on 2023/3/27.
//

import Foundation

@objcMembers
public class Audio: NSObject {
    
    /// Audio url.
    public var audioURL: URL
    
    /// -------------- `MPNowPlayingInfoCenter` --------------
    
    /// Set `nowPlayingInfo` using audio metadata.
    ///
    /// Default is `true`.
    public var useAudioMetadata: Bool = true
    
    /// If `useAudioMetadata` is set to false, then you can set it through the following properties.
    
    /// Audio name.
    public var title: String?
    /// Album name.
    public var albumName: String?
    /// Artist.
    public var artist: String?
    
    /// Artwork.
    public var artworkImage: UIImage?
    public var artworkURL: URL?
    
    public init(audioURL: URL) {
        self.audioURL = audioURL
    }
}
