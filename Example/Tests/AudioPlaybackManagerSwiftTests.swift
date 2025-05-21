//
//  AudioPlaybackManagerSwiftTests.swift
//  AudioPlaybackManager_Tests
//
//  Created by 怦然心动-LM on 2024/11/29.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Testing
@testable import AudioPlaybackManager
import AVFoundation

struct AudioPlaybackManagerSwiftTests {
    
    let sut = AudioPlaybackManager.shared
    
    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func testMute() {
        #expect(!sut.isMuted)
        
        sut.isMuted = true
        #expect(sut.isMuted)
    }
    
    @Test func testVolume() {
        #expect(sut.volume == 1.0)
        
        sut.volume = 0
        #expect(sut.volume == sut.player.volume)
    }
    
    @Test func testSetupLocalItem() {
        let audio = disable_generateLocalItem()
        
        sut.setupItem(audio, beginTime: 0)
        #expect(sut.audio != nil)
        
        #expect(sut.playerItem != nil)
        
        let itemURL = (sut.playerItem?.asset as? AVURLAsset)?.url
        #expect(itemURL?.isFileURL == true)
        #expect(itemURL == audio.audioURL)
        
        #expect(sut.playStatus == .prepare)
    }
}

// MARK: Disable

extension AudioPlaybackManagerSwiftTests {
    
    func disable_generateLocalItem() -> Audio {
        guard let path = Bundle.main.path(forResource: "Song 1", ofType: "m4a") else {
            fatalError()
        }
        
        let audioURL = URL(fileURLWithPath: path)
        let audio = Audio(audioURL: audioURL)
        return audio
    }
}
