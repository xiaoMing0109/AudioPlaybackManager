//
//  AudioPlaybackManager+AudioSession.swift
//
//  Created by LM on 2023/3/28.
//

import Foundation
import AVFoundation

// MARK: - Active Session

extension AudioPlaybackManager {
    
    /// Set the audio session as active/inactive.
    ///
    /// When set to active, other players will be notified that the audio session is interrupted.
    ///
    /// On the contrary, it will notify other players that the audio session is interrupted and can resume playback.
    ///
    /// - Note: It is recommended to turn it on before starting to play, and turn it off when you don't need to play at all.
    @objc
    public func activeSession(_ enabled: Bool) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(enabled, options: .notifyOthersOnDeactivation)
        } catch {
            #if DEBUG
            print(error)
            #endif
        }
    }
}
